# CLAUDE.md

Project context for Claude Code sessions on **Monta PDF**.

## What it is
iOS document scanner (SwiftUI, iOS 17+). Scan paper, convert images and Word files to PDF, keep everything synced with iCloud. See `README.md` for the full feature list.

## Owner
- Communicate in Portuguese (Brazil) by default; the owner is building English skills, so short English explanations are welcome when useful.
- Owner background: former Product Manager, now an Android developer. When explaining iOS/Swift concepts, comparing them with Android/Kotlin equivalents helps (e.g. SwiftUI ↔ Jetpack Compose, SwiftData ↔ Room).

## Layout
```
MontaPDF/MontaPDF/        # App: App/, Features/, Core/, Resources/
MontaPDF/MontaPDFTests/   # Unit tests
MontaPDF/MontaPDFUITests/ # UI tests
ci/                       # CI helper scripts (simulator lookup, coverage for Sonar, export options)
server/apple-revoke/      # Cloudflare Worker for Sign in with Apple token revocation
docs/                     # Public site: landing, privacy, terms
store/                    # App Store texts
design/                   # App icon sources
```

## Conventions
- `main` is protected; work on a branch and open a pull request (squash merge).
- Branch names: `feature/<name>`, `fix/<name>`, `chore/<name>`.
- Commits: Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`, `ci:`).
- Pull requests follow `.github/pull_request_template.md` and must pass the SonarQube Cloud quality gate.
- Every user-facing string goes in the String Catalog with **en**, **pt-BR** and **es-419**.
- Word-to-PDF conversion stays behind the `DocumentConverter` protocol.

## Build and test
Requires macOS with Xcode 26+; these cannot run in a Linux container. CI (`.github/workflows/ci.yml`) builds and runs unit and UI tests on an iPhone simulator for every pull request. Releases go to TestFlight via `.github/workflows/release.yml`.

## Running UI tests locally
- UI tests need a **Debug** build on the **simulator**: the Scan button only creates the fake "Sample page" document under `#if DEBUG && targetEnvironment(simulator)` (`ScannerViewModel.scanTapped()`). Any other build just shows the "Scanner unavailable" alert.
- Use a clean simulator with no personal accounts; system notifications (e.g. WhatsApp) can cover the app and break a test.
- Run them serially (`-parallel-testing-enabled NO`), as CI does.
- Status (2026-11-09): all 6 UI tests pass on CI for `main` @ `b4dd4c3`. Earlier local failures (Scan flow and `deleteAccountButton`) point to the local setup, not the code.
