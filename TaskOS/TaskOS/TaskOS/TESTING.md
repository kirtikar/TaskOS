# taskOS – Testing Guide

This document explains the test suite structure, how to run tests locally, and how CI is configured.

---

## Test Target Setup (One-time Xcode step)

> The test files are ready — you just need to wire them into Xcode once.

1. **Open** `taskOS.xcodeproj` in Xcode.
2. **Add the test target:**
   - `File → New → Target → Unit Testing Bundle`
   - Product Name: `taskOSTests`
   - Ensure "Target to be Tested" is set to `taskOS`
3. **Add the test files** to the `taskOSTests` target:
   - `taskOSTests/TaskModelTests.swift`
   - `taskOSTests/TaskDetailViewModelTests.swift`
   - `taskOSTests/AuthenticationTests.swift`
   - `taskOSTests/NotificationServiceTests.swift`
   - `taskOSTests/ThemeAndDesignSystemTests.swift`
   - `taskOSTests/SwiftDataIntegrationTests.swift`
4. **Add the test plan:**
   - Select the `taskOS` scheme → Edit Scheme → Test → "+" → Add `taskOS.xctestplan`
5. **Enable code coverage:**
   - In the scheme's Test action → check "Gather coverage for: taskOS"

---

## Test Suite Overview

| File | Suite(s) | Tests |
|------|----------|-------|
| `TaskModelTests.swift` | `Task Model`, `Priority`, `RepeatFrequency`, `Subtask` | 20 |
| `TaskDetailViewModelTests.swift` | `TaskDetailViewModel` | 17 |
| `AuthenticationTests.swift` | `AuthenticationService`, `AppUser`, `AuthError`, `AuthProvider` | 22 |
| `NotificationServiceTests.swift` | `NotificationService` | 6 |
| `ThemeAndDesignSystemTests.swift` | `ThemeManager`, `DesignSystem`, `Project Enums`, `Color Hex Extension` | 18 |
| `SwiftDataIntegrationTests.swift` | `Task`, `Project`, `Tag`, `Subtask` persistence | 15 |
| **Total** | | **~98 tests** |

---

## Running Tests Locally

### In Xcode
- **All tests:** `⌘U`
- **Single suite:** Click the diamond ◆ next to a `@Suite` or `@Test`
- **Test Navigator:** `⌘6` to see full tree

### From the terminal
```bash
xcodebuild test \
  -scheme taskOS \
  -project taskOS.xcodeproj \
  -destination 'platform=iOS Simulator,name=iPhone 16,OS=latest' \
  CODE_SIGNING_ALLOWED=NO \
  | xcpretty
```

Install `xcpretty` if needed:
```bash
gem install xcpretty
```

---

## CI / GitHub Actions

The workflow lives at `.github/workflows/ci.yml` and runs on:

- Every **push** to `main` or `develop`
- Every **pull request** targeting `main` or `develop`

### What the workflow does

| Step | Description |
|------|-------------|
| Checkout | Fetches the repo |
| Xcode 16 | Selects the correct toolchain on `macos-15` |
| Resolve packages | Runs `xcodebuild -resolvePackageDependencies` |
| Build | Compiles `taskOS` for the iPhone 16 simulator |
| Test | Runs all tests, produces `TestResults.xcresult` + JUnit XML |
| Upload artifacts | Stores `.xcresult` and JUnit XML for 14 days |
| Test summary | Posts pass/fail counts as a PR check |

---

## What Is and Isn't Tested

### ✅ Covered
- All model computed properties (`isOverdue`, `isDueToday`, `progress`, `initials`, etc.)
- `TaskDetailViewModel` label formatters, subtask CRUD, date clearing
- `AuthenticationService` session persistence, sign-out, stub error paths
- `AppUser` / `AuthError` / `AuthProvider` correctness
- `NotificationService` cancel / no-crash paths for all frequencies
- `ThemeManager` UserDefaults persistence
- `AccentOption`, `ProjectColor`, `ProjectIcon` enum correctness
- `Color(hex:)` parsing
- SwiftData insert / fetch / update / delete for all four models
- Project `nullify` delete rule (tasks survive project deletion)

### ⏳ Not yet covered (future work)
- Firebase-backed auth flows (requires live Firebase project / mock)
- SwiftUI view rendering / snapshot tests (`taskOSUITests` target)
- Push notification deep-link handling
- Widget / extension targets (if added later)

---

## Code Coverage

After running tests in Xcode, open the **Report Navigator (`⌘9`) → Coverage** tab to see per-file coverage. The CI workflow also collects coverage data in the uploaded `.xcresult` bundle.

Target coverage goals:

| Layer | Goal |
|-------|------|
| Models | ≥ 90% |
| View Models | ≥ 85% |
| Services | ≥ 75% |
| Views | Best-effort |
