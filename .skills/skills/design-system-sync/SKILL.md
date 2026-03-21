---
name: design-system-sync
description: "Sync the Imprint iOS app's design system from Figma to code. Use this skill whenever the user mentions syncing design tokens, checking Figma for updates, updating colors/typography/spacing from Figma, comparing design vs code, generating Swift from tokens, or anything related to keeping the Figma design system and Swift codebase in sync. Also trigger when the user says things like 'pull latest from Figma', 'update the design system', 'check for design changes', 'sync tokens', or 'what changed in Figma'."
---

# Design System Sync

Keeps the Imprint iOS app's design tokens and component specs in sync with its Figma design system.

## How It Works

The sync flows in one direction: **Figma → Token files → Swift code**.

1. **Pull** — Read variables, styles, and component metadata from Figma
2. **Diff** — Compare against the canonical token files in `Imprint/DesignSystem/`
3. **Update tokens** — Write changes to the JSON token files
4. **Generate Swift** — Regenerate `ImprintColors`, `ImprintFonts`, spacing constants, and `ColorDerivation` from the token files
5. **Report** — Summarize what changed so the user can review

## Step-by-Step

### 1. Pull from Figma

Use the `figma_get_design_system_kit` tool to fetch the full design system in one call:

```
mcp__figma-console__figma_get_design_system_kit(
  include: ["tokens", "components", "styles"],
  format: "full"
)
```

If the response is too large, use `format: "summary"` first, then fetch specific collections with `figma_get_variables` using the `collection` filter.

For incremental checks (user asks "what changed?"), use `figma_get_design_changes` first to see if anything was modified, then pull only the affected data.

### 2. Read Existing Tokens

Read the canonical token files from the project:

- `Imprint/Imprint/DesignSystem/colors.json` — Color tokens (primitives + semantic aliases, light/dark modes)
- `Imprint/Imprint/DesignSystem/typography.json` — Font families, sizes, weights, line heights
- `Imprint/Imprint/DesignSystem/spacing.json` — Padding, margins, radii, sizing
- `Imprint/Imprint/DesignSystem/components.json` — Component metadata (names, properties, variants)

These files follow the schema documented in `references/token-schema.md`. Read that file for the exact JSON structure.

### 3. Diff and Update

Compare the Figma data against the existing token files. For each token category:

- Identify **added** tokens (in Figma but not in the file)
- Identify **changed** tokens (different value in Figma vs the file)
- Identify **removed** tokens (in the file but not in Figma)

Update the JSON files with the new values. Preserve the file structure and formatting.

Always present the diff to the user before writing, so they can review. Format it clearly:

```
Colors:
  + Added: color/accent/green (Light: #6BBD6E, Dark: #4A9E4D)
  ~ Changed: color/base/paper (Light: #FFFCF0 → #FFFDF2)
  - Removed: color/legacy/filmSubtle

Typography:
  ~ Changed: heading/page-title fontSize (32 → 34)
```

### 4. Generate Swift Code

After updating token files, regenerate the Swift source files. The mapping is:

| Token file | Swift file | What it generates |
|---|---|---|
| `colors.json` | `Utilities/Theme.swift` → `ImprintColors` | Static `Color` properties, appearance-aware resolvers |
| `typography.json` | `Utilities/Theme.swift` → `ImprintFonts` | Font helper methods, semantic shortcuts |
| `spacing.json` | `Utilities/Theme.swift` → `ImprintSpacing` (new enum) | Static spacing/radius constants |
| `colors.json` | `Utilities/ColorDerivation.swift` | Update derivation logic if base algorithm changes |

When generating Swift from tokens:

- Color tokens become `static let` properties on `ImprintColors` using the `Color(hex:)` initializer
- Multi-mode colors (light/dark) become appearance-aware resolver methods: `static func tokenName(_ isDark: Bool) -> Color`
- Typography tokens become font methods on `ImprintFonts`
- Spacing tokens become `static let` on a new `ImprintSpacing` enum

Read the existing Swift files first to understand the current patterns, then edit surgically rather than rewriting whole files. Preserve any hand-written code that isn't token-derived.

### 5. Report

After syncing, give the user a concise summary:

- How many tokens were added/changed/removed per category
- Which Swift files were updated
- Any warnings (e.g., token referenced in code but removed from Figma)

## Design Parity Checks

When the user asks to check if a specific view matches the Figma design, use `figma_check_design_parity`:

1. Read the Swift view file to extract its visual properties (colors, spacing, typography, layout)
2. Call `figma_check_design_parity` with the Figma node ID and the extracted `codeSpec`
3. Report discrepancies and offer to fix them

This is useful for spot-checking individual components against their Figma source.

## Token File Location

All token files live in: `Imprint/Imprint/DesignSystem/`

This directory is inside the Xcode project so the files are visible in the project navigator, but the JSON files themselves aren't compiled — they serve as the canonical record that drives Swift code generation.

## Important Notes

- Figma is always the source of truth. Never push code changes back to Figma through this skill.
- When the user hasn't set up their Figma design system yet, offer to scaffold the token files from the existing Swift code (reverse-engineer `ImprintColors` and `ImprintFonts` into the JSON format). This gives them a starting point.
- Category-specific colors (the user-chosen `colorHex` on each Category entity) are NOT part of the design system. Those are user data. The design system covers the app's chrome, not per-category theming.
- The `ColorDerivation` utility derives variants (bold, subtle, etc.) programmatically from any hex color. Its algorithm might be informed by the design system, but the input colors come from user data.
