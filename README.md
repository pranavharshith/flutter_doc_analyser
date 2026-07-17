# Vortex

Flutter app for **student document verification**. Students upload Aadhaar, Voter ID, and marksheets; on-device OCR extracts text; admins review, verify, or reject.

**Backend:** Firebase Auth, Firestore, Storage — no paid verification APIs.  
**Workspace:** develop only in `D:\vortex\flutter_doc_analyser` (not OneDrive copies).

---

## Features

| Role | Capabilities |
|------|----------------|
| **Student** | Auth, profile, upload 4 doc types (camera/gallery/files), OCR match, notifications, re-upload, trash, FAQ, light/dark theme |
| **Admin** (`@admin.vortexapp.com`) | Dashboard, OCR preview, verify/reject, documents list, reports, notifications, trash, settings |

### Verification pipeline

```
Pick image → sharpness check → ML Kit OCR → field compare
  → Verified or Pending → Storage + Firestore (hashes + quality metadata)
```

On-device helpers in `lib/utils/document_validators.dart`:

| API | Role |
|-----|------|
| `validateAadhaar` | Verhoeff check-digit |
| `hashDocumentNumber` | SHA-256 for duplicate detection (no plaintext IDs) |
| `extractVoterId` / `isValidVoterIdFormat` | Multi-state EPIC formats |
| `calculateSharpness` / `qualityFromScore` | Blur gate before OCR |

---

## Layout

```
lib/
├── main.dart
├── components/auth_ui.dart
├── ui/                          shared kit (scaffold, cards, forms, …)
├── screens/{auth,student,admin}
├── services/storage_service.dart
├── providers/theme_controller.dart
├── utils/                       validators, theme, constants, snackbar, …
└── widgets/                     splash, profile image, theme toggle

firestore.rules · storage.rules · firestore.indexes.json
tools/run_android.bat · tools/clean_locks.ps1
```

---

## Run

```powershell
$env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
$env:PATH = "$env:JAVA_HOME\bin;C:\src\flutter\bin;" + $env:PATH
cd D:\vortex\flutter_doc_analyser
flutter pub get
flutter run
```

Or: `tools\run_android.bat`

### Deploy rules & indexes (required for production)

Local `firestore.rules` / `firestore.indexes.json` / `storage.rules` apply only after:

```bash
firebase deploy --only firestore:rules,firestore:indexes,storage --project fire-setup-33812
```

Needed for Storage uploads, admin collectionGroup queries, and document-hash indexes.

### Tests

```bash
flutter test
```

---

## Platforms

| Target | Status |
|--------|--------|
| **Android** | Primary — fully supported |
| **iOS** | Supported once Firebase iOS config / provisioning is set |
| **Web** | **Not supported** — stub only (folder kept for a future port). Running on web shows a “use the mobile app” screen. |

OCR uses Google ML Kit on-device (mobile). Do not use `flutter run -d chrome` for product testing.

---

## Optional follow-ups

- Enable Firebase Storage in Console, then deploy storage rules  
- Formal accessibility (TalkBack) pass  
- Commit/push if local redesign is not yet on remote  
