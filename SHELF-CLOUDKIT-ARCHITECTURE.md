# Shelf + Connections: CloudKit Architecture

> Planning document for Imprint's social features. No code yet — this captures the data model, flows, and technical decisions.

## Overview

The **Shelf** is a curated subset of a user's logged items that they choose to make visible to their connections. The full log stays local and private. Social features are entirely opt-in — users who don't enable them see zero CloudKit activity.

---

## 1. Database Strategy

Imprint uses a **hybrid approach**: SwiftData stays local for the log, CloudKit handles social features directly via its SDK.

| Database | Purpose | Record Types |
|----------|---------|--------------|
| **SwiftData (local)** | User's log and queue — unchanged | `Record` (existing) |
| **CloudKit Public** | User directory for handle lookup | `UserProfile`, `UserHandle` |
| **CloudKit Private** (custom `ShelfZone`) | Shelf data, connections | `Shelf`, `ShelfItem`, `Connection`, `ConnectionRequest` |

**Why not SwiftData's built-in CloudKit sync?** It only supports private zones and automatic mirroring. We need public handle discovery and custom access control for shelves, which requires the CloudKit SDK directly.

---

## 2. CloudKit Record Types

### UserProfile (Public DB)

```
recordID:              CKRecord.ID ("user_<ckUserID>")
ckUserID:              String        // from CKContainer.fetchUserRecordID()
signInWithAppleToken:  String        // opaque ID from ASAuthorizationAppleIDCredential
displayName:           String?       // optional, from Sign in with Apple
primaryHandle:         CKReference   // → UserHandle
createdAt:             Date
isActive:              Bool
```

### UserHandle (Public DB)

```
recordID:     CKRecord.ID ("handle_olvr")
handle:       String        // unique, lowercase, alphanumeric + hyphens
userProfile:  CKReference   // → UserProfile
createdAt:    Date
isActive:     Bool
```

Index required on `handle` for fast lookups. Uniqueness enforced at the application level (check-before-write) since CloudKit has no unique constraint.

### Connection (Private DB, ShelfZone)

```
recordID:     CKRecord.ID
initiatorID:  CKReference   // → UserProfile (who sent the request)
recipientID:  CKReference   // → UserProfile (who receives)
status:       String         // "pending" | "accepted" | "blocked" | "removed"
direction:    String         // "outgoing" | "incoming" (denormalized for query efficiency)
initiatedAt:  Date
respondedAt:  Date?
```

**Why two Connection records per pair (one per user)?** Each user can independently revoke or block without affecting the other's view. Simplifies queries: "show me all my accepted connections" is a single predicate.

### ConnectionRequest (Private DB, ShelfZone)

```
recordID:        CKRecord.ID
initiator:       CKReference   // → UserProfile
recipientHandle: String         // denormalized for lookup
message:         String?        // optional personal message
requestedAt:     Date
expiresAt:       Date           // auto-expire after 30 days
status:          String         // "pending" | "accepted" | "declined"
```

### Shelf (Private DB, ShelfZone)

```
recordID:      CKRecord.ID     // one per user
owner:         CKReference     // → UserProfile
lastModified:  Date
```

### ShelfItem (Private DB, ShelfZone)

```
recordID:          CKRecord.ID
shelf:             CKReference   // → Shelf
logItemType:       String         // "film" | "tv" | "book" | "music"
externalLogItemID: UUID           // references local SwiftData Record.id (NOT a CKReference)
title:             String         // denormalized from local log for offline display
creator:           String?        // director, author, etc.
posterPath:        String?        // TMDB poster path for image reconstruction
rating:            Int?           // user's rating, if they choose to share it
userNotes:         String?        // shelf-specific note (separate from log notes)
addedToShelfAt:    Date
order:             Int            // for shelf ordering
```

**Why UUID bridging instead of CKReference?** The log lives in SwiftData, not CloudKit. CKReference requires both records to exist in CloudKit. UUID is a stable, portable link between the two systems.

---

## 3. User Identity: Sign in with Apple + CloudKit

Sign in with Apple's user ID and CloudKit's user ID are **not linked**. We map them explicitly.

### First sign-in flow

1. User taps "Sign in with Apple" → receive `ASAuthorizationAppleIDCredential`
2. Call `CKContainer.fetchUserRecordID()` → receive CloudKit user ID
3. Create `UserProfile` in public DB (linking both IDs)
4. User chooses a handle → create `UserHandle` in public DB
5. Create custom `ShelfZone` in private DB
6. Store CloudKit user ID in Keychain (not SwiftData) for offline access

### Subsequent sign-ins

1. Sign in with Apple → verify stored Apple UID matches
2. Fetch `UserProfile` by `ckUserID`
3. Load handle, shelf, and connections

---

## 4. Connection Flow

### Sending a request

1. User A enters `@olvr` (User B's handle)
2. Query `UserHandle` in public DB → fetch User B's `UserProfile`
3. Create `ConnectionRequest` in A's private zone with status `"pending"`
4. User B receives push notification via `CKQuerySubscription`

### Accepting a request

1. User B opens app, sees pending request
2. User B taps "Accept"
3. Update `ConnectionRequest` status to `"accepted"`
4. Create `Connection` record for both users (one `"outgoing"`, one `"incoming"`)
5. Both users can now see each other's shelves

### Blocking / removing

- Setting `Connection.status = "blocked"` hides the shelf from that user
- The blocked user sees the connection silently disappear (no notification)

---

## 5. Shelf Visibility Logic

### Who sees what

| Viewer | Sees |
|--------|------|
| **Owner** | All their ShelfItems (full edit access) |
| **Connected user** | ShelfItems where Connection status is `"accepted"` |
| **Unconnected user** | Nothing (query returns empty) |

### Shelving an item

When a user taps "Add to Shelf" on a logged record:

1. Create a `ShelfItem` in CloudKit with a snapshot of the record's public fields (title, creator, poster path, media type)
2. Store the local `Record.id` as `externalLogItemID` for back-linking
3. User optionally adds a shelf-specific note

### Unshelving

User can remove items from their shelf at any time. The local log entry is unaffected.

### Frozen snapshots

ShelfItems are **snapshots**, not live mirrors. If the user edits their local log entry's notes, the shelf note doesn't auto-update. This is intentional — the shelf note is a separate, public-facing thought.

---

## 6. Syncing Strategy

### Connection requests → CKQuerySubscription (push)

High urgency. Use `CKQuerySubscription` with a predicate matching the current user's handle. Delivers APNs push immediately.

### Shelf updates → Manual fetch (poll)

Lower urgency. Fetch connected users' shelves on app foreground and via `BGAppRefreshTaskRequest` every few hours. Cache results locally.

**Why not subscribe to shelf changes?** CloudKit has a 200 subscription limit per container. With many connections, you'd exhaust it quickly. Shelves change infrequently enough that polling is fine.

---

## 7. Privacy and Access Control

### Custom ACL via Connection records (not CKShare)

`CKShare` is designed for collaborative editing. Imprint's shelf is read-only sharing, so a simpler model works better: check `Connection.status == "accepted"` before returning shelf data.

### CloudKit Dashboard permissions

| Record Type | World | Authenticated | Creator |
|-------------|-------|---------------|---------|
| `UserProfile` | None | Read | Read + Write |
| `UserHandle` | Read | Read | Read + Write |
| Private zone records | N/A | N/A | Owner only (automatic) |

---

## 8. Migration Path

### Phase 1: Infrastructure

- Enable CloudKit capability in Xcode
- Add container: `iCloud.com.imprint`
- Enable Push Notifications + Background Modes: Remote Notifications
- Deploy schema to CloudKit Dashboard
- **Existing users are completely unaffected** — no CloudKit activity unless they opt in

### Phase 2: Opt-in social features

- New toggle in settings: "Enable Shelf & Connections"
- On enable: Sign in with Apple → create profile → choose handle
- Lazy-initialize CloudKit containers only when social is enabled

### Phase 3: Shelf UI

- "Add to Shelf" action on logged items
- Shelf tab or section in profile view
- Connection management screen
- Connected users' shelves browsable from a social/friends view

---

## 9. Limitations and Gotchas

### CloudKit

| Limit | Impact | Workaround |
|-------|--------|-----------|
| 1 MB per record | Large poster assets | Use CKAsset or store TMDB path and reconstruct URL |
| 250 items per query | Large shelves | Paginate with cursor |
| 40 req/sec per private DB | Burst fetches | Batch operations |
| 200 subscriptions per container | Can't subscribe to everything | Subscribe to connections only; poll shelves |
| No unique constraint | Duplicate handles possible | Check-before-write at app level |
| No cascading delete | Orphaned records | Custom cleanup logic |

### Sign in with Apple

| Issue | Solution |
|-------|----------|
| Email not provided on re-auth | Store Apple UID in Keychain on first sign-in |
| User can hide email | Don't rely on email; use Apple UID only |
| Token expires on password change | Re-authenticate on each sign-in; don't cache tokens |

### SwiftData + CloudKit coexistence

| Issue | Solution |
|-------|----------|
| `@Attribute(.unique)` not supported with CloudKit | Use CloudKit-only records for unique constraints |
| All properties must be optional or have defaults | Design models accordingly |
| Custom zones not supported by automatic sync | Manage shelf/connection records via CloudKit SDK directly |

---

## 10. Implementation Checklist

### Before coding

- [ ] Enable CloudKit capability in Xcode
- [ ] Add CloudKit container in project settings
- [ ] Enable Push Notifications capability
- [ ] Add Background Modes: Remote Notifications
- [ ] Create `ShelfZone` in CloudKit Dashboard

### Phase 1: User Identity

- [ ] Implement Sign in with Apple flow
- [ ] Store CloudKit user ID in Keychain
- [ ] Create `UserProfile` record type
- [ ] Create `UserHandle` record type with index
- [ ] Handle lookup function

### Phase 2: Connections

- [ ] `Connection` record type
- [ ] `ConnectionRequest` record type
- [ ] Send connection request flow
- [ ] Accept connection request flow
- [ ] `CKQuerySubscription` for incoming requests
- [ ] Push notification handling

### Phase 3: Shelf

- [ ] `Shelf` record type
- [ ] `ShelfItem` record type
- [ ] "Add to Shelf" flow (snapshot from local Record)
- [ ] "Remove from Shelf" flow
- [ ] Fetch connected user's shelf
- [ ] Cache shelf data locally for offline viewing

### Phase 4: Testing

- [ ] Test with multiple iCloud accounts via CloudKit Dashboard
- [ ] Verify schema deployment to production
- [ ] Test push notifications for connection requests
- [ ] Test offline behavior (queued operations)
- [ ] Verify local-only users see zero CloudKit activity
