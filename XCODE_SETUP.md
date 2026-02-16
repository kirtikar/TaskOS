# TaskOS — Xcode Setup & iPhone Install Guide

> Xcode 26.2 · Swift 6.2 · iOS 17+ · iPhone 12 Mini

---

## Part 1 — Create the Xcode Project

### Step 1 — Open Xcode and create a new project

1. Open **Xcode** from `/Applications/Xcode.app`
2. At the welcome screen click **"Create New Project..."**
   *(or menu: File → New → Project)*
3. Select template: **iOS → App** → click **Next**

4. Fill in the project options exactly:

   | Field | Value |
   |---|---|
   | Product Name | `TaskOS` |
   | Team | Sign in with your Apple ID (free is fine for device testing) |
   | Organization Identifier | `com.yourname` (e.g. `com.kirtikar`) |
   | Bundle Identifier | auto-filled as `com.kirtikar.TaskOS` |
   | Interface | **SwiftUI** |
   | Language | **Swift** |
   | Storage | **None** |
   | Include Tests | ✅ checked |

5. Click **Next** → save the project **inside this folder:**
   ```
   /Users/kirtikar/Documents/Codes/iosTasks/
   ```
   Xcode will create `iosTasks/TaskOS/TaskOS.xcodeproj`

---

## Part 2 — Add the Source Files

### Step 2 — Delete the default generated files

In the Xcode Project Navigator (left sidebar), find and delete these files
**(right-click → Delete → Move to Trash):**

- `TaskOS/ContentView.swift`
- `TaskOS/TaskOSApp.swift`
- `TaskOS/Assets.xcassets` — **keep this one**, just expand and edit it

### Step 3 — Add our source files to Xcode

In **Finder**, open:
```
/Users/kirtikar/Documents/Codes/iosTasks/TaskOS/
```

You'll see these folders: `App`, `Models`, `DesignSystem`, `ViewModels`, `Views`, `Services`

**Drag all of them** into the Xcode Project Navigator, dropping on the `TaskOS` group (blue folder icon).

When the dialog appears:
- ✅ **Copy items if needed**
- ✅ **Create groups** (not folder references)
- Target membership: ✅ **TaskOS**

Click **Finish**.

### Step 4 — Configure AccentColor in Assets

1. In Project Navigator, open `Assets.xcassets`
2. The `AccentColor` color set should already exist — if not, right-click → **New Color Set** → name it `AccentColor`
3. Click the `AccentColor` set → in Attributes Inspector (right panel):
   - Set **Any Appearance** to: `#007AFF` (hex input)
   - Set **Dark** to: `#0A84FF` (slightly brighter for dark mode)
4. Optionally add `AccentSoft` color set as `#007AFF` at 20% opacity

---

## Part 3 — Configure the Project

### Step 5 — Set iOS deployment target

1. Click the **TaskOS project** (top of Navigator, blue icon)
2. Select **TaskOS target** → **General** tab
3. Under **Minimum Deployments** → set to **iOS 17.0**

### Step 6 — Add notification permission to Info.plist

1. Still in the target, go to the **Info** tab
2. Click the `+` at the end of any existing row
3. Add:
   - Key: `Privacy - User Notifications Usage Description`
   - Value: `TaskOS reminds you about tasks when they're due.`

### Step 7 — Enable Sign in with Apple capability

1. Go to **Signing & Capabilities** tab
2. Click **+ Capability** (top left of that tab)
3. Search for and add: **Sign in with Apple**
4. Make sure **Automatically manage signing** is checked
5. Set your **Team** to your Apple ID

---

## Part 4 — Build & Run in Simulator

### Step 8 — Select a simulator and run

1. In the Xcode toolbar at the top, click the **device selector** (shows "iPhone 16" or similar)
2. Choose **iPhone 16** simulator (or any iOS 17+ simulator)
3. Press **⌘R** (or click the ▶ Play button)
4. First build takes ~45–90 seconds — watch the progress bar at top

**Expected result:** Simulator opens, app launches to the Auth screen.

### Common build errors and fixes

| Error | Fix |
|---|---|
| `Cannot find 'Task' in scope` | Swift has a built-in `Task` type. In Xcode: Edit → Find → Find in Project → replace `Task(` with `TaskItem(` in models only if it persists |
| `No such module 'SwiftData'` | Check deployment target is iOS 17.0, not lower |
| `@Observable macro not found` | Same — needs iOS 17 target |
| Missing file errors | Re-do Step 3, make sure all subfolders were dragged in |
| Signing error | Xcode → Preferences → Accounts → add your Apple ID |

---

## Part 5 — Install on iPhone 12 Mini

### Step 9 — Connect your iPhone

1. Connect iPhone 12 Mini to your Mac with a **USB-C or Lightning cable**
2. On the iPhone: tap **"Trust"** when the "Trust This Computer?" dialog appears → enter your iPhone passcode
3. In Xcode toolbar: click the device selector → your **iPhone 12 Mini** should appear under *Physical Devices*
4. Select it

### Step 10 — Trust your developer certificate on iPhone

**First time only — do this on the iPhone:**

1. Go to **Settings → General → VPN & Device Management**
2. Under "Developer App" you'll see your Apple ID email
3. Tap it → tap **"Trust [your email]"** → tap Trust again to confirm

*(This only appears after the first install attempt. You may need to do step 11 first, then come back here.)*

### Step 11 — Build and install on device

1. In Xcode: make sure your **iPhone 12 Mini** is selected in the toolbar
2. Press **⌘R**
3. Xcode will compile and wirelessly (or via cable) install the app
4. The app will launch automatically on your iPhone

**If you see "Developer Mode" prompt on iPhone:**
- Settings → Privacy & Security → Developer Mode → turn it On → restart iPhone → then re-run ⌘R

---

## Part 6 — Optional: Wireless Install (no cable needed after first time)

1. Connect iPhone via cable once and run the app successfully
2. In Xcode: **Window → Devices and Simulators**
3. Select your iPhone → check **"Connect via network"**
4. From now on, keep iPhone on the same WiFi as your Mac — no cable needed for ⌘R

---

## Part 7 — Enable Firebase (Google + Email Sign-In)

Once the app runs, to unlock Google and Email auth:

### Step 12 — Add Firebase package

In Xcode:
1. **File → Add Package Dependencies...**
2. Paste URL: `https://github.com/firebase/firebase-ios-sdk`
3. Click **Add Package**
4. Select these products:
   - ✅ `FirebaseAuth`
   - ✅ `FirebaseFirestore` *(optional, for cloud sync later)*
5. Click **Add Package**

### Step 13 — Set up Firebase Console

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. **Create a project** → name it `TaskOS`
3. Add an **iOS app**:
   - Bundle ID: `com.kirtikar.TaskOS` *(must match exactly)*
4. Download `GoogleService-Info.plist`
5. Drag `GoogleService-Info.plist` into Xcode project root
   - ✅ Copy items if needed → target: TaskOS

6. In Firebase Console → **Authentication → Sign-in method**, enable:
   - ✅ Apple
   - ✅ Google
   - ✅ Email/Password

### Step 14 — Activate Firebase in the app

In `TaskOSApp.swift`, add at the top:
```swift
import FirebaseCore
```
Add in the `App` struct initializer:
```swift
init() {
    FirebaseApp.configure()
}
```

Then in `AuthenticationService.swift`, uncomment all the blocks marked:
```
// ── Uncomment after adding firebase-ios-sdk ──
```

---

## Quick Reference

| Action | Shortcut |
|---|---|
| Build & Run | ⌘R |
| Stop | ⌘. |
| Clean build | ⌘⇧K |
| Open simulator | ⌘⇧2 |
| Show/hide Navigator | ⌘0 |
| Open file quickly | ⌘⇧O |
| Device list | ⌘⇧2 |

---

## What the App Does Right Now (no Firebase needed)

- Sign in with Apple works out of the box
- Today, Inbox, Projects, Task Detail, Quick Add, Search, Settings all functional
- Tasks persist locally via SwiftData
- Notifications work once permission is granted
- Dark/light mode works automatically
