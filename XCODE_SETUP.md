# TaskOS — Xcode 26 Setup Guide (Steps 5–14)

> Verified for **Xcode 26.2** · Swift 6.2 · iOS 17+ · iPhone 12 Mini

---

## Where You Are

- ✅ Steps 1–4 done: project created, source files imported, AccentColor set
- ▶️ You are here: **Step 5 — Set deployment target**

---

## Step 5 — Set iOS Deployment Target

> Same location as older Xcode. No change in Xcode 26.

1. In the left sidebar (**Project Navigator**), click the **blue TaskOS icon** at the very top
2. The project editor opens. In the **left pane of that editor** you'll see two sections:
   - A **PROJECT** row (blue document icon)
   - A **TARGETS** row with TaskOS under it
3. Click **TaskOS** under TARGETS (not the project)
4. Click the **General** tab at the top of the right pane
5. Scroll down to the **"Minimum Deployments"** section
6. Click the iOS dropdown → select **iOS 17.0**

---

## Step 6 — Add Notification Permission

> Xcode 26 can auto-detect missing privacy keys at runtime, but add it manually now to avoid a crash on first run.

1. Still on the same screen (TaskOS target selected)
2. Click the **Info** tab (next to General)
3. Hover over any row in the list → a **`+`** button appears at the end of the row — click it
4. A dropdown appears — type `notification` to filter
5. Select **"Privacy - User Notifications Usage Description"**
6. In the value column, type:
   ```
   TaskOS reminds you about tasks when they're due.
   ```
7. Press **Return**

---

## Step 7 — Add Sign in with Apple Capability

> Xcode 26 note: Signing & Capabilities tab is identical to Xcode 15/16. Usage descriptions are now also editable directly in this tab.

1. Still with the TaskOS **target** selected
2. Click **Signing & Capabilities** tab
3. Under the "Signing" section, make sure:
   - ✅ **Automatically manage signing** is checked
   - **Team** is set to your Apple ID (click the dropdown → "Add an Account" if needed)
4. Click the **`+ Capability`** button in the top-left of this tab
5. A search sheet slides down — type `apple`
6. Double-click **"Sign in with Apple"**
7. It appears as a new section. That's it — no further config needed.

**If you see a signing error** (red warning):
- Xcode → **Settings** (⌘,) → **Accounts** tab → click `+` → **Apple ID** → sign in
- Come back to Signing & Capabilities → select your Team from the dropdown

---

## Step 8 — Build & Run in Simulator

1. In the Xcode **toolbar** (center-top), click the device name (shows something like "iPhone 16")

   > In Xcode 26 the toolbar uses a Liquid Glass design — it floats above the editor. The device selector is still in the same center position.

2. From the dropdown select **iPhone 16** (or any iOS 17+ simulator)
   - If no simulators appear: **Xcode menu → Settings → Platforms → iOS** → click download button next to iOS 17 or 18
3. Press **⌘R** (or click the **▶ Play button**)
4. First build: ~45–90 seconds. Progress shows in the top bar.

**The app should launch and show the TaskOS Auth screen.**

### Build errors and fixes

| Error message | What to do |
|---|---|
| `Cannot find type 'Task' in scope` | Rename our `Task` model — see box below |
| `No such module 'SwiftData'` | Deployment target not set to iOS 17.0 — redo Step 5 |
| `Cannot find 'DS' in scope` | `DesignSystem.swift` wasn't imported — re-drag the DesignSystem folder |
| `Value of type 'X' has no member 'Y'` | A source file is missing — check all folders are in Navigator |
| Signing: "No profiles for X found" | Set your Team in Step 7 first |
| `@Observable` macro error | Deployment target below iOS 17 — redo Step 5 |

> **Fix for `Cannot find type 'Task' in scope`**
> Swift has a built-in `Task` type for async work. If Xcode gets confused:
> In Xcode: **Edit → Find → Find and Replace in Project**
> - Search: `final class Task {`
> - Replace: `final class TaskItem {`
> Then update all references — or add `typealias TaskItem = Task` at the top of `Task.swift`.
> *Only do this if the error actually appears.*

---

## Step 9 — Connect iPhone 12 Mini

1. Use a **Lightning cable** to connect iPhone 12 Mini to your Mac
2. Unlock your iPhone
3. A popup appears on iPhone: **"Trust This Computer?"** → tap **Trust** → enter your passcode
4. In the Xcode toolbar, click the device selector (where the simulator name is)
5. Under **"Physical Devices"** or **"iOS Devices"** your iPhone 12 Mini should appear
6. Select it

**If iPhone doesn't appear:**
- Try a different USB port or cable
- Open **Window → Devices and Simulators** (⌘⇧2) — if it shows there but not in toolbar, restart Xcode
- Make sure iPhone is unlocked when connecting

---

## Step 10 — Enable Developer Mode on iPhone 12 Mini

> Required on iOS 16 and above before Xcode can install apps.

**On the iPhone:**
1. **Settings → Privacy & Security**
2. Scroll to the bottom → tap **Developer Mode**
3. Toggle it **On**
4. Tap **Restart** → iPhone reboots
5. After restart, a system prompt appears → tap **Enable**
6. Enter your passcode

> If **Developer Mode** doesn't appear in Settings, connect the iPhone to Xcode first (Step 9), let Xcode detect it for a few seconds — then check Settings again.

---

## Step 11 — Install on iPhone 12 Mini

1. In Xcode toolbar, confirm **your iPhone 12 Mini** is selected (not a simulator)
2. Press **⌘R**
3. Xcode builds and installs — the app launches on your iPhone

**First time only — trust the developer certificate on iPhone:**
1. The app may show "Untrusted Developer" error and refuse to open
2. Go to iPhone: **Settings → General → VPN & Device Management**
3. Under **"Developer App"** → tap your Apple ID email
4. Tap **"Trust [your email]"** → tap **Trust** again to confirm
5. Open the app — it works now

---

## Step 12 — Go Wireless (No Cable After This)

1. Make sure iPhone and Mac are on the **same WiFi network**
2. In Xcode: **Window → Devices and Simulators** (⌘⇧2)
3. Select your iPhone 12 Mini
4. Check **"Connect via network"** ✅
5. A globe icon appears next to your device — cable can be removed
6. From now on: just have iPhone nearby on WiFi → press ⌘R to install

---

## Step 13 — Add Firebase (Unlocks Google + Email Sign-In)

### Add the package

1. **File → Add Package Dependencies...**
2. In the search bar (top right) paste:
   ```
   https://github.com/firebase/firebase-ios-sdk
   ```
3. Press **Return** → wait for Xcode to resolve it (~30 seconds)
4. Under "Add to Target: TaskOS", select these products:
   - ✅ **FirebaseAuth**
   - ✅ **FirebaseFirestore** *(optional — for cloud sync later)*
   - Leave everything else unchecked
5. Click **Add Package**

### Set up Firebase Console

1. Go to **[console.firebase.google.com](https://console.firebase.google.com)**
2. Click **"Create a project"** → name it `TaskOS` → Continue
3. Disable Google Analytics (optional) → **Create project**
4. Click the **iOS icon** to add an iOS app
5. Bundle ID: enter exactly **`com.kirtikar.TaskOS`** *(must match Xcode)*
6. Click **Register App** → **Download GoogleService-Info.plist**
7. Drag `GoogleService-Info.plist` into Xcode's Project Navigator → drop on the `TaskOS` group
   - ✅ Copy items if needed
   - ✅ Target: TaskOS
8. Click **Finish** in the Firebase Console wizard

### Enable sign-in methods in Firebase Console

1. Left sidebar → **Authentication** → **Get started**
2. **Sign-in method** tab → enable each:
   - **Apple** → Enable → Save
   - **Google** → Enable → enter support email → Save
   - **Email/Password** → Enable → Save

### Activate Firebase in the app

Open [TaskOSApp.swift](TaskOS/TaskOS/TaskOS/App/TaskOSApp.swift) and make these two edits:

**At the top, add:**
```swift
import FirebaseCore
```

**Inside `TaskOSApp`, add an `init`:**
```swift
init() {
    FirebaseApp.configure()
}
```

Then open [AuthenticationService.swift](TaskOS/TaskOS/TaskOS/Services/AuthenticationService.swift) and uncomment every block marked:
```
// ── Uncomment after adding firebase-ios-sdk ──
```
There are 4 such blocks: `signInWithGoogle`, `signInWithEmail`, `createAccount`, and `sendPasswordReset`.

---

## Step 14 — Commit & Push After Each Session

Any time you make changes in Xcode, push them to GitHub:

```bash
cd /Users/kirtikar/Documents/Codes/iosTasks
git add .
git commit -m "your message here"
git push
```

---

## Quick Reference

| Action | Shortcut |
|---|---|
| Build & Run | ⌘R |
| Stop running app | ⌘. |
| Clean build folder | ⌘⇧K |
| Open Devices window | ⌘⇧2 |
| Show/hide Navigator | ⌘0 |
| Open file by name | ⌘⇧O |
| Find in project | ⌘⇧F |
| Toggle dark/light preview | Canvas → Variants |

---

## App Flow Right Now (No Firebase Required)

```
Launch
 └── Auth screen
      ├── "Sign in with Apple"  ✅ works immediately
      └── Google / Email        ⏳ works after Step 13
           └── Onboarding (first launch only)
                └── Main App
                     ├── Today tab
                     ├── Inbox tab
                     ├── Projects tab
                     ├── Search tab
                     └── Settings tab
```
