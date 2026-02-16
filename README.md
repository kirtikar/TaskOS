# TaskOS

A production-ready iOS task manager app built with SwiftUI, SwiftData, and modern Apple frameworks.

Inspired by Things 3, Todoist, and TickTick — designed with a clean, minimal aesthetic supporting both light and dark mode.

---

## Features

- **Today** — Daily overview with overdue/upcoming grouping and progress tracking
- **Inbox** — Fast capture with sort, search, and swipe actions
- **Projects** — Visual grid with color/icon customization and progress bars
- **Task Detail** — Due dates, reminders, priority, subtasks, tags, and repeat rules
- **Quick Add** — Bottom sheet for friction-free task capture with attribute pills
- **Search** — Full-text search across tasks and projects
- **Authentication** — Sign in with Apple, Google, and Email
- **Notifications** — Scheduled reminders via UserNotifications
- **Theming** — System/Light/Dark modes with custom accent colors

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Data | SwiftData (iOS 17+) |
| Auth | Sign in with Apple + Firebase Auth (Google/Email) |
| Architecture | MVVM + `@Observable` |
| Notifications | UserNotifications framework |
| Minimum iOS | iOS 17.0 |

---

## Getting Started

### Prerequisites
- Xcode 16+
- iOS 17+ device or simulator
- Apple Developer account (for Sign in with Apple)
- Firebase project (for Google Sign-In)

### Setup

1. Clone the repo
   ```bash
   git clone https://github.com/kirtikar/TaskOS.git
   cd TaskOS
   ```

2. Open `TaskOS.xcodeproj` in Xcode

3. Add `GoogleService-Info.plist` from your Firebase Console to the project root
   > ⚠️ This file is gitignored — never commit it

4. In Firebase Console:
   - Enable **Sign in with Apple**
   - Enable **Google Sign-In**
   - Enable **Email/Password**

5. Add Swift packages in Xcode:
   - `https://github.com/firebase/firebase-ios-sdk` → `FirebaseAuth`, `FirebaseFirestore`

6. Set your Team and Bundle ID in Xcode → Signing & Capabilities

7. Run on simulator or device: **⌘R**

---

## Project Structure

```
TaskOS/
├── App/                    # Entry point, app container
├── Models/                 # SwiftData models
├── DesignSystem/           # Design tokens, components
├── ViewModels/             # Business logic (@Observable)
├── Views/                  # All screens
│   ├── Auth/               # Login, signup, forgot password
│   ├── Today/
│   ├── Inbox/
│   ├── Projects/
│   ├── TaskDetail/
│   ├── QuickAdd/
│   ├── Search/
│   ├── Onboarding/
│   └── Settings/
└── Services/               # Auth, Notifications
```

---

## Screenshots

> Coming soon

---

## License

MIT — see [LICENSE](LICENSE)

---

Built with Claude Code · [Anthropic](https://anthropic.com)
