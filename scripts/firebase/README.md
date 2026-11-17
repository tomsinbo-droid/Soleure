# Soléure Firestore Seed & Cleanup (DEV ONLY)

Install dependencies once: `cd scripts/firebase && npm install`, then return to the project root.

Preview without connecting:

```powershell
node scripts/firebase/seed_firestore.js --project soleure-demo-local --dry-run --with-users
```

Use Local Emulator Suite (Auth 9099 + Firestore 8080):

```powershell
$env:FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080'
$env:FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9099'
node scripts/firebase/seed_firestore.js --project soleure-demo-local --apply --confirm-project soleure-demo-local --with-users
```

To seed an explicitly separate DEV project, unset the emulator environment variables and set `GOOGLE_APPLICATION_CREDENTIALS` to a local private credential file OUTSIDE this project. Never commit the key.

Cleanup is dry-run unless passed `--apply --confirm-project`, plus the exact `--seed-source` and `--seed-batch`. Cleanup **does not delete Firebase Auth accounts or users**, and never removes untagged data.

Do not seed a production project or migrate real transactions using this demo workflow.
