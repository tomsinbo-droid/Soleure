# SOLÉURE — FLUTTER MVVM + FIRESTORE ONLY (INTERN DEMO)

> **DEMO ONLY — NOT FOR PRODUCTION**
>
> UI Soléure is unchanged. Data is loaded from Firestore; no runtime mock/demo data.
> Privileged stock, POS, shift and payroll writes are **Emulator only** because
> Firestore Rules cannot guarantee all server-side business invariants.

## Source structure

- `lib/views/` — unchanged UI widgets.
- `lib/view_models/` — ordinary classes; no Provider/Bloc/Riverpod.
- `lib/services/` — split by business module; all use `cloud_firestore` or `firebase_auth`.
- `lib/models/` — data objects.
- `scripts/firebase/` — isolated Firebase Admin SDK seed and cleanup scripts.
- `firestore.rules` — conservative real Firebase permissions.
- `firestore.emulator.rules` — local-only demonstration permissions, **do not deploy**.

## Getting started

1. Read `docs/INTERN_FIRESTORE_DEMO_GUIDE.md`.
2. Install Flutter, Node.js, Java and Firebase CLI.
3. Run `flutter pub get && flutter analyze && flutter test`.
4. Start Auth + Firestore Emulator using `firebase.emulator.json`.
5. Preview and apply the seed to **Emulator** with `scripts/firebase/seed_firestore.js`.
6. Launch with `flutter run -d chrome --dart-define=SOLEURE_FIRESTORE_EMULATOR=true`.

## Tạo tài khoản Staff / Manager

Nút tạo tài khoản gọi Callable Cloud Functions (`createStaffAccount`) để
Firebase Admin SDK tạo đồng thời Firebase Authentication và `users/{uid}`.
Điều này giữ role, lương và trạng thái khóa ngoài quyền của Flutter client.

1. Cài dependencies: `cd functions; npm install`.
2. Khi chạy local, Emulator Suite sẽ tự nạp Functions ở cổng `5001`.
3. Khi dùng Firebase DEV thật, deploy: `firebase deploy --only functions`.

Admin đang hoạt động mới có thể tạo hoặc chỉnh sửa Staff/Manager. Sau khi tạo,
app gửi email đặt lại mật khẩu để người dùng tự đặt mật khẩu lần đầu. Hãy bật
Email/Password trong Firebase Authentication và cấu hình mẫu email reset.

## Not implemented as live cloud operations

- Verified QR transfer and real bank refunds.
- Real salary disbursement and official tax/payroll close.
- Background expiration jobs. Hold and QR expiration is checked on app read.
- Secure shared-project POS/stock/ledger writes; emulator-only demonstration.

## Acceptance status

Source migration static check passed. Flutter compilation, Firebase Rules
Emulator E2E, concurrency and real Firebase integration were **not run** here.
Refer to `docs/FIRESTORE_MIGRATION_QA.md` for exact evidence.
