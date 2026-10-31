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
