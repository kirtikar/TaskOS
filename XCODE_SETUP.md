# TaskOS — Xcode Setup Guide

## Step 1: Create the Xcode Project

1. Open **Xcode** → "Create New Project"
2. Choose **iOS → App**
3. Fill in:
   | Field | Value |
   |---|---|
   | Product Name | `TaskOS` |
   | Team | Your Apple Developer account (or Personal Team for testing) |
   | Organization ID | `com.yourname` (e.g. `com.kirtikar`) |
   | Bundle ID | `com.yourname.TaskOS` |
   | Interface | **SwiftUI** |
   | Language | **Swift** |
   | Storage | **None** (we use SwiftData manually) |
   | Include Tests | ✅ Yes |

4. Save the project inside:
   `/Users/kirtikar/Documents/Codes/iosTasks/`

---

## Step 2: Copy Source Files

After Xcode creates the default project, **delete** these auto-generated files from Xcode (Move to Trash):
- `ContentView.swift` (we have ours)
- `TaskOSApp.swift` (we have ours — check the App folder)

Then in Finder, drag ALL folders from:
```
/Users/kirtikar/Documents/Codes/iosTasks/TaskOS/
```
Into the Xcode project navigator, dropping them on the **TaskOS** group.

When prompted: ✅ **Copy items if needed**, ✅ **Create groups**

---

## Step 3: Add AccentColor to Assets.xcassets

1. Open `Assets.xcassets` in Xcode
2. Right-click → **New Color Set** → name it `AccentColor`
3. Set color to `#007AFF` (iOS blue) for both light and dark
4. Optionally add `AccentSoft` color set as a lighter variant

---

## Step 4: Configure Info.plist

Add these keys to `Info.plist`:

| Key | Value |
|---|---|
| `NSUserNotificationsUsageDescription` | "TaskOS uses notifications to remind you about due tasks." |

In Xcode 15+: Open `Info.plist` → click `+` → add the key above.

---

## Step 5: Set Deployment Target

1. Click the **TaskOS** target → **General** tab
2. Set **Minimum Deployments** → **iOS 17.0**

---

## Step 6: Build & Run

1. Select an iPhone 17 simulator (or your device)
2. Press **⌘R** to build and run

**Expected first build**: ~30-60 seconds. If you see errors, see Troubleshooting below.

---

## Troubleshooting Common Errors

### `Cannot find type 'Task' in scope`
Swift has a built-in `Task` type for concurrency. Our SwiftData model is also named `Task`.
**Fix**: Rename our model to `TOTask` or use module-qualified names.
Actually in context of SwiftData `@Model` classes the compiler resolves this correctly — if you still see issues, rename to `TaskItem`.

### `No exact matches in call to instance method 'insert'`
Make sure `modelContext` is imported via `@Environment(\.modelContext)`.

### `@Observable` macro not found
Ensure deployment target is iOS 17+. `@Observable` requires the Observation framework (iOS 17).

### Previews not working
Add `.modelContainer(for: [...], inMemory: true)` to every `#Preview` block (already done in our files).

---

## Project Structure Reference

```
TaskOS/
├── App/
│   └── TaskOSApp.swift           ← @main entry point
├── Models/
│   ├── Task.swift                ← SwiftData Task model
│   ├── Project.swift             ← SwiftData Project model
│   └── Tag.swift                 ← SwiftData Tag model
├── DesignSystem/
│   ├── DesignSystem.swift        ← All design tokens (DS namespace)
│   ├── AppTheme.swift            ← ThemeManager + dark/light
│   └── Components/
│       ├── TaskRow.swift         ← Core reusable task cell
│       └── TagChip.swift         ← Tag, Priority, Empty state, Section header
├── ViewModels/
│   ├── TodayViewModel.swift
│   ├── InboxViewModel.swift
│   ├── ProjectsViewModel.swift
│   └── TaskDetailViewModel.swift
├── Views/
│   ├── ContentView.swift         ← Tab bar + FAB
│   ├── Today/TodayView.swift
│   ├── Inbox/InboxView.swift
│   ├── Projects/
│   │   ├── ProjectsView.swift
│   │   └── ProjectDetailView.swift
│   ├── TaskDetail/TaskDetailView.swift
│   ├── QuickAdd/QuickAddView.swift
│   ├── Search/SearchView.swift
│   ├── Onboarding/OnboardingView.swift
│   └── Settings/SettingsView.swift
└── Services/
    └── NotificationService.swift
```

---

## Next Steps After First Build

- [ ] Add app icon (1024×1024 PNG) to Assets.xcassets → AppIcon
- [ ] Add launch screen in `LaunchScreen.storyboard` or `Info.plist`
- [ ] Set up WidgetKit extension (home screen widgets)
- [ ] Add iCloud sync via `ModelConfiguration` with CloudKit
- [ ] Integrate StoreKit for premium features
- [ ] Write unit tests for ViewModels
- [ ] TestFlight distribution
