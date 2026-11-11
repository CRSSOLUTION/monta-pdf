# Monta PDF

iOS document scanner. Scan paper, convert images and Word files to PDF, and keep everything in one place, synced with iCloud.

## Features (1.0)
- Sign in with Apple (any Apple ID works, including Gmail addresses)
- Multi-page scan with automatic crop and perspective correction (VisionKit), plus page cleanup (shadows, folds, white paper)
- Import photos (JPG, PNG, HEIC) into one PDF, and Word (.docx, .doc) and PDF files, several at once (one document per file)
- Document library with automatic naming ("Document 1", "Document 2", ...)
- View, rename, delete and share the PDF (for Word imports, share the PDF or the original)
- Account screen: document count, space used, sign out, and delete account (revokes the Sign in with Apple token)
- iCloud sync (SwiftData + CloudKit), works offline; falls back to a local store if CloudKit can't open
- Localized: English (base), Portuguese (Brazil), Spanish (Latin America)

## Tech stack
| Layer | Technology |
| --- | --- |
| UI | SwiftUI, iOS 17.6+, MVVM with dependencies wired in `AppContainer` |
| Auth | Sign in with Apple, session kept in the Keychain |
| Data | SwiftData + CloudKit (private database) |
| Scan | VisionKit + Core Image cleanup |
| PDF | PDFKit |
| Word to PDF | WebKit, behind the `DocumentConverter` protocol |
| Import | `fileImporter` and `PhotosPicker` |
| Account deletion | Cloudflare Worker that revokes the Apple token (`server/apple-revoke`) |
| Tests | Swift Testing (unit), XCTest (UI) |
| Quality | SonarQube Cloud |

## Project structure
```
MontaPDF/
├── MontaPDF/
│   ├── App/          # Entry point, AppContainer (dependencies), LaunchOptions
│   ├── Features/     # Login, Documents, Scanner, Import, Viewer, Account
│   ├── Core/         # Config, Models, Repositories, Services, UI
│   └── Resources/    # Assets, String Catalogs, Info.plist, entitlements
├── MontaPDFTests/    # Unit tests
└── MontaPDFUITests/  # UI tests
ci/                   # CI helper scripts (simulator lookup, coverage for Sonar, export options)
server/apple-revoke/  # Cloudflare Worker for Sign in with Apple token revocation
docs/                 # Website on GitHub Pages: landing, privacy policy, terms of use
store/                # App Store listing texts (en, pt-BR, es)
design/               # App icon sources
CLAUDE.md             # Project context for Claude Code sessions
```

## Workflow
- `main`: always stable, protected, changes only through pull requests
- One branch per feature: `feature/<name>`, `fix/<name>`, `chore/<name>`
- Commits follow [Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`, `ci:`
- Every pull request uses the template and must pass the SonarQube Cloud quality gate before merge (squash merge)

## Requirements
- Xcode 26+
- Apple Developer account with Sign in with Apple and iCloud (CloudKit) capabilities

## Tests
- **Unit tests** (`MontaPDFTests`): run with `⌘U` or `xcodebuild test -only-testing:MontaPDFTests`.
- **UI tests** (`MontaPDFUITests`): run on the simulator or on a real iPhone, one at a time (`-parallel-testing-enabled NO`). The app is launched with `-ui-testing`: in-memory store, Scan saves sample pages instead of opening the camera, and no Apple ID check. On a personal iPhone, turn on Do Not Disturb so notifications don't cover the app.

## CI/CD (GitHub Actions)
- **CI** (`.github/workflows/ci.yml`): on every pull request and push to `main`, builds the app, runs the unit tests, sends coverage to SonarQube Cloud, then runs the UI tests on an iPhone simulator.
- **Release** (`.github/workflows/release.yml`): run it manually (Actions > Release to TestFlight > Run workflow) or push a tag like `v1.0.0` to archive the app and upload it to TestFlight. The build number is the workflow run number.
- Release secrets (Settings > Secrets and variables > Actions): `ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_P8` (contents of the App Store Connect API key `.p8` file, Admin role).
