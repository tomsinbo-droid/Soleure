# Firestore migration QA — Evidence

| Test / evidence | Status |
|---|---|
| `node scripts/firebase/migration_safety_test.js` | PASS (static check only) |
| `node scripts/firebase/seed_firestore.js --project soleure-demo-local --dry-run --with-users` | PASS (no Firebase calls) |
| `node scripts/firebase/cleanup_demo.js --project ... --seed-source ... --seed-batch ...` | PASS (preview without credentials, does not query remote) |
| `npm run check`, `npm test`, `npm run seed:test` in **original** `functions/` baseline | PASS (legacy code only; does NOT test new Dart migrations) |
| Internal Dart import paths exist | PASS (static filesystem check) |
| `lib/views`, theme, assets unchanged compared with uploaded archive | PASS (byte comparison) |
| `flutter pub get`, `flutter analyze`, `flutter test`, `flutter build web` | NOT RUN — Flutter/Dart SDK unavailable here |
| Firestore Emulator rules tests | NOT RUN — Firebase CLI/Emulator unavailable here |
| Flutter Firebase DEV E2E | NOT RUN — no connected/test Firebase DEV credentials |
| Transaction concurrency tests | NOT RUN — needs Emulator + Flutter harness |
| Seed APPLY, Cleanup APPLY | NOT RUN — no authorized Firebase write |

Result: **Code-migrated demo candidate**; not accepted as secure/fully working until Flutter builds and the Emulator E2E tests pass.
