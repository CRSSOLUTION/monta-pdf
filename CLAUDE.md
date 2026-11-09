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
