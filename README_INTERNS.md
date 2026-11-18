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

Luồng này chỉ dùng Firebase Authentication và Firestore, không dùng Cloud
Functions. App dùng Firebase Auth app phụ để tạo user mới mà không làm đăng
xuất Admin hiện tại, rồi Admin ghi hồ sơ `users/{uid}` theo Firestore Rules.
Manager gửi đề xuất không kèm mật khẩu. Khi duyệt, Admin nhập mật khẩu ban đầu;
app tạo tài khoản Authentication và ghi hồ sơ Staff cùng trạng thái duyệt.
Admin cần chuyển mật khẩu cho nhân viên qua kênh an toàn; nhân viên có thể dùng
chức năng quên mật khẩu để tự đổi. Đề xuất bị từ chối không tạo tài khoản.
Hãy bật Email/Password trong Firebase Authentication và cấu hình email reset.
Auth và Firestore không hỗ trợ giao dịch chung: nếu dọn tài khoản Authentication
thất bại sau lỗi ghi Firestore, Admin phải kiểm tra Firebase Console.

## Not implemented as live cloud operations

- Verified QR transfer and real bank refunds.
- Real salary disbursement and official tax/payroll close.
- Background expiration jobs. Hold and QR expiration is checked on app read.
- Secure shared-project POS/stock/ledger writes; emulator-only demonstration.

## Acceptance status

Source migration static check passed. Flutter compilation, Firebase Rules
Emulator E2E, concurrency and real Firebase integration were **not run** here.
Refer to `docs/FIRESTORE_MIGRATION_QA.md` for exact evidence.
