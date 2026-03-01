# Imprint — Xcode Setup Instructions

The Swift source files are ready in the `Imprint/` folder. Since Xcode project files (`.xcodeproj`) need to be created by Xcode itself, follow these steps to wire everything up. It takes about 2 minutes.

## Step 1: Create the Xcode Project

1. Open Xcode.
2. Go to **File → New → Project**.
3. Choose **App** under the iOS tab. Click **Next**.
4. Fill in the settings:
   - **Product Name:** `Imprint`
   - **Organization Identifier:** something like `com.yourname` (e.g., `com.olvr`)
   - **Interface:** SwiftUI
   - **Storage:** SwiftData ← important!
   - **Language:** Swift
5. Click **Next**, then choose your `imprint/` repo folder as the save location.
   - **Important:** Xcode will create an `Imprint/` subfolder inside the repo. Since this folder already exists with our source files, Xcode may ask about replacing files — **allow it to merge/replace**.

## Step 2: Replace the Generated Files

Xcode generates placeholder files (`ContentView.swift`, `Item.swift`, `ImprintApp.swift`). Replace them with ours:

1. In Xcode's Project Navigator (left sidebar), **delete** these generated files:
   - `Item.swift` (Xcode's placeholder model — we have `Record.swift`)
   - `ContentView.swift` (we have our own version)
   - `ImprintApp.swift` (we have our own version)
   - When prompted, choose **Move to Trash**.

2. **Add our source files** to the project:
   - Right-click the `Imprint` folder in the Project Navigator.
   - Choose **Add Files to "Imprint"…**
   - Navigate into the `Imprint/` folder and select all subfolders: `App/`, `Models/`, `Views/`, `Utilities/`
   - Make sure **"Copy items if needed"** is **unchecked** (the files are already in the project folder).
   - Make sure **"Create groups"** is selected.
   - Click **Add**.

## Step 3: Build & Run

1. Select an iPhone simulator from the device menu (e.g., iPhone 16).
2. Press **⌘R** to build and run.
3. The app should launch showing the empty "Logged" view with a + button.

## Project Structure

```
Imprint/
├── App/
│   └── ImprintApp.swift          # App entry point
├── Models/
│   └── Record.swift              # SwiftData model
├── Views/
│   ├── ContentView.swift         # Root view (tabs + list)
│   ├── RecordListView.swift      # Filtered record list
│   ├── RecordFormView.swift      # Create/edit form
│   ├── RecordDetailView.swift    # Record detail view
│   └── Components/
│       ├── MediaFilterBar.swift  # Filter chip row
│       └── RecordRowView.swift   # List row component
├── Utilities/
│   └── Enums.swift               # RecordType, MediaType
└── Resources/
    └── (Assets.xcassets — created by Xcode)
```

## Minimum Requirements

- Xcode 15.0+
- iOS 17.0+ deployment target (for SwiftData)
- macOS Sonoma 14.0+ (to run Xcode 15)
