# Monta PDF

iOS document scanner. Scan paper, convert images and Word files to PDF, and keep everything in one place, synced with iCloud.

## Features (MVP)
- Sign in with Apple
- Multi-page scan with automatic crop and perspective correction (VisionKit)
- Import images (JPG, PNG, HEIC), Word (.docx, .doc) and PDF, from the app or the iOS share sheet
- Document library with automatic naming ("Document 1", "Document 2", ...)
- View, rename, delete and share the PDF file
- iCloud sync (SwiftData + CloudKit), works offline
- Localized: English (base), Portuguese (Brazil), Spanish (Latin America)

## Tech stack
| Layer | Technology |
| --- | --- |
| UI | SwiftUI, iOS 17+ |
| Auth | Sign in with Apple |
| Data | SwiftData + CloudKit (private database) |
| Scan | VisionKit |
| PDF | PDFKit |
| Word to PDF | WebKit, behind the `DocumentConverter` protocol |
| Import | Share Extension + App Group |
| Quality | SonarQube Cloud |

## Project structure
```
MontaPDF/
├── App/          # Entry point and configuration
├── Features/     # Login, Documents, Scanner, Import, Viewer, Account
├── Core/         # Models, Storage, DocumentConverter, Naming
└── Resources/    # Assets, String Catalogs
ShareExtension/
```

## Workflow
- `main`: always stable, protected, changes only through pull requests
- One branch per feature: `feature/<name>`, `fix/<name>`, `chore/<name>`
- Commits follow [Conventional Commits](https://www.conventionalcommits.org): `feat:`, `fix:`, `chore:`, `refactor:`, `test:`, `docs:`
- Every pull request uses the template and must pass the SonarQube Cloud quality gate before merge (squash merge)

## Requirements
- Xcode 26+
- Apple Developer account with Sign in with Apple, iCloud (CloudKit) and App Groups capabilities

## CI/CD (GitHub Actions)
- **CI** (`.github/workflows/ci.yml`): on every pull request and push to `main`, builds the app and runs the unit tests on an iPhone simulator.
- **Release** (`.github/workflows/release.yml`): run it manually or push a tag like `v1.0.0` to archive the app and upload it to TestFlight. The build number is the workflow run number.
- Release secrets (Settings > Secrets and variables > Actions): `ASC_KEY_ID`, `ASC_ISSUER_ID` and `ASC_KEY_P8` (contents of the App Store Connect API key `.p8` file, Admin role).
