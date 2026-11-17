# Soléure — Quick Start for Intern (Windows PowerShell)

## 0. Requirements
- Flutter SDK supporting declared Dart `^3.10.7`.
- Node.js and Firebase CLI (`npm install -g firebase-tools`).
- Java for Firestore emulator.
- Keep `firebase_options.dart` project ID consistent with the ID passed to the emulator CLI.
- Isolated local emulator strongly recommended; do not test cash/QR/stock approval on live project.

## 1. Check source

```powershell
flutter doctor
flutter pub get
flutter analyze
flutter test
flutter build web
node scripts/firebase/migration_safety_test.js
```

## 2. Start local Firebase Emulator (Terminal A)

Look at `projectId` in `lib/firebase_options.dart` (currently `soleure-c1554`).
Using that ID in the emulator does **not** contact the production database as
long as all operations use `useAuthEmulator` and `useFirestoreEmulator`.

```powershell
firebase emulators:start --only auth,firestore --config firebase.emulator.json --project soleure-c1554
```

Use the local Firebase Emulator UI at `http://127.0.0.1:4000`.
Do NOT use the normal `firebase.json` rules to run this demo.

## 3. Seed test accounts and data (Terminal B)

```powershell
cd scripts/firebase
npm install
cd ../..
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'
node scripts/firebase/seed_firestore.js --project soleure-c1554 --dry-run --with-users
node scripts/firebase/seed_firestore.js --project soleure-c1554 --apply --confirm-project soleure-c1554 --with-users
```

Account email/password pairs appear only in `scripts/firebase/.seed-credentials.<project>.json` on your own PC (Git ignored). Four users: Admin, Manager, Staff A, Staff B.

## 4. Run Flutter (Terminal C)

```powershell
flutter run -d chrome --dart-define=SOLEURE_FIRESTORE_EMULATOR=true
```

Android Emulator uses `10.0.2.2` for local Firebase. Windows/Chrome use `127.0.0.1`.

## 5. Suggested demo sequence

1. Admin login and review seeded Dashboard and the pending receipt.
2. Manager create supplier/product/receipt; Admin approves in Emulator.
3. Staff A add customer, create Hold, cancel, then sell cash *demo* product.
4. Compare `products.stock`, `orders`, `commission_events` and `customers` in Emulator UI.
5. Manager create/approve a future shift; Staff A check in/out within allowed window.
6. Staff A asks for shift swap, Staff B accepts, Manager approves.
7. Manager reviews attendance; Admin checks payroll *estimate* and Finance.
8. Create Pending QR for demo; Manager can run emulator-only simulated confirmation. This is NOT evidence of bank transfer.

## 6. Cleanup (safe preview)

```powershell
node scripts/firebase/cleanup_demo.js --project soleure-c1554 --seed-source soleure-intern-seed-v1 --seed-batch soleure-firestore-intern-v1
```

Cleanup is *not* performed automatically. It requires explicit `--apply --confirm-project`, refuses production names outside emulator, and excludes Firebase Auth user deletion.

## 7. Warnings
- Never deploy `firestore.emulator.rules` to a real project.
- `flutter run` **without** the emulator flag can connect to the real configured Firebase project. Sensitive operations are intentionally blocked by Rules, but read-only operations may still access remote data. Reconfigure Firebase to an isolated DEV project before online tests.
- No private key JSON is included. Rotate keys found in the original uploaded ZIP.
- This delivered version has NOT been tested with a real Flutter build or Emulator session in the assistant environment.
