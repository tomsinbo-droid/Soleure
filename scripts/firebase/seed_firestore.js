#!/usr/bin/env node
'use strict';

// Chạy từ máy dev có Firebase Admin SDK. Mặc định chỉ preview, không ghi.
// BẮT BUỘC chỉ dùng với Firebase DEV/TEST/DEMO hoặc cả hai emulator.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {seedSource, users, products, customers, suppliers, settings} = require('./seed_data');

const flags = process.argv.slice(2);
function flag(name) {
  const i = flags.indexOf(name);
  return i < 0 ? null : flags[i + 1];
}
function die(message) { console.error(`LỖI: ${message}`); process.exitCode = 1; }

async function main() {
  if (flags.includes('--help')) {
    console.log('node scripts/firebase/seed_firestore.js --project <project-id> [--dry-run]');
    console.log('node scripts/firebase/seed_firestore.js --project <project-id> --apply --confirm-project <project-id> --with-users');
    return;
  }
  const projectId = flag('--project');
  const apply = flags.includes('--apply');
  const dryRun = flags.includes('--dry-run');
  const withUsers = flags.includes('--with-users');
  if (!projectId || !/^[a-z][a-z0-9-]{4,40}$/.test(projectId)) {
    throw Error('Phải cung cấp --project <firebase-dev-project-id> hợp lệ.');
  }
  if (apply && dryRun) throw Error('Chọn --apply hoặc --dry-run, không dùng đồng thời.');
  const firestoreEmu = Boolean(process.env.FIRESTORE_EMULATOR_HOST);
  const authEmu = Boolean(process.env.FIREBASE_AUTH_EMULATOR_HOST);
  if (firestoreEmu !== authEmu) throw Error('Phải dùng đồng thời FIRESTORE_EMULATOR_HOST và FIREBASE_AUTH_EMULATOR_HOST hoặc không dùng cả hai.');
  const emulator = firestoreEmu && authEmu;
  const devNamed = /(^|[-_])(dev|test|demo)([-_]|$)/i.test(projectId);
  if (!emulator && !devNamed) {
    throw Error('TỪ CHỐI: chỉ seed DEV/TEST/DEMO, không có bypass cho project production.');
  }
  if (apply && !withUsers) throw Error('Cần --with-users để tạo đủ hồ sơ và tài khoản demo.');
  if (apply && flag('--confirm-project') !== projectId) {
    throw Error('Cần --confirm-project khớp chính xác với --project trước khi ghi.');
  }
  console.log(`PROJECT = ${projectId} | ${emulator ? 'EMULATOR' : 'DEV FIREBASE'} | ${apply ? 'APPLY' : 'DRY RUN'}`);
  console.log(`Dữ liệu dự kiến: ${products.length} products, ${customers.length} customers, ${suppliers.length} suppliers, 1 settings, ${products.length} opening ledgers, 1 receipt, 1 stocktake, 1 unit, 1 damage report, 1 pending promotion, 1 pending shift, 1 pending Staff request, 2 demo expenses${withUsers ? `, ${users.length} Auth users + profiles` : ''}.`);
  if (!apply) {
    console.log('DRY RUN hoàn tất: KHÔNG kết nối và KHÔNG ghi Firebase.');
    return;
  }

  // Firebase Admin bypasses Firestore Rules: không được đóng gói secret trong Flutter.
  const {initializeApp, applicationDefault} = require('firebase-admin/app');
  const {getAuth} = require('firebase-admin/auth');
  const {getFirestore, FieldValue, Timestamp} = require('firebase-admin/firestore');
  initializeApp(emulator ? {projectId} : {credential: applicationDefault(), projectId});
  const db = getFirestore();
  const auth = getAuth();
  const now = FieldValue.serverTimestamp();
  let created = 0, skipped = 0;
  const context = {seedSource, seedBatchId: 'soleure-firestore-intern-v1', isDemo: true, seededAt: now};

  async function createOnly(ref, data) {
    const didCreate = await db.runTransaction(async tx => {
      const doc = await tx.get(ref);
      if (doc.exists) {
        if (doc.get('seedSource') === seedSource) return false;
        throw Error(`ID ${ref.path} đã có dữ liệu khác; KHÔNG ghi đè.`);
      }
      tx.create(ref, {...data, ...context});
      return true;
    });
    if (didCreate) created++; else skipped++;
  }

  const output = path.join(__dirname, `.seed-credentials.${projectId}.json`);
  const passwords = fs.existsSync(output) ? JSON.parse(fs.readFileSync(output, 'utf8')) : {};
  function saveCredentials() {
    // Lưu NGAY sau khi tạo mỗi tài khoản: nếu seed bị ngắt, mật khẩu không thất lạc.
    fs.writeFileSync(output, JSON.stringify(passwords, null, 2) + '\n', {mode: 0o600});
    fs.chmodSync(output, 0o600);
  }
  if (withUsers) {
    // Thông tin user (tên, email, role, lương giờ) lưu trong 1 users/{uid}.
    for (const user of users) {
      let exists = false;
      try {
        const current = await auth.getUser(user.uid);
        if (current.email?.toLowerCase() !== user.email) {
          throw Error(`Auth UID ${user.uid} đã được dùng bởi email khác.`);
        }
        exists = true;
      } catch (error) {
        if (error.code !== 'auth/user-not-found') throw error;
      }
      if (!exists) {
        try {
          const sameEmail = await auth.getUserByEmail(user.email);
          throw Error(`Email ${user.email} đã tồn tại tại UID ${sameEmail.uid}.`);
        } catch (error) {
          if (error.code !== 'auth/user-not-found') throw error;
        }
        const password = crypto.randomBytes(24).toString('base64url');
        await auth.createUser({uid: user.uid, email: user.email, displayName: user.displayName,
          password, disabled: false});
        passwords[user.email] = password;
        saveCredentials();
        console.log(`Tạo Firebase Auth: ${user.email}`);
      } else {
        console.log(`Bỏ qua Firebase Auth đã tồn tại: ${user.email}`);
      }
      await createOnly(db.collection('users').doc(user.uid), user);
    }
  }

  // Tạo product + opening ledger cùng giao dịch: không thể có tồn kho thiếu nguồn gốc.
  for (const p of products) {
    const productRef = db.collection('products').doc(p.sku);
    const movementRef = db.collection('stock_movements').doc(`SEED_OPEN_${p.sku}`);
    const didCreate = await db.runTransaction(async tx => {
      const [product, movement] = await Promise.all([tx.get(productRef), tx.get(movementRef)]);
      if (product.exists || movement.exists) {
        if (product.exists && movement.exists &&
            product.get('seedSource') === seedSource && movement.get('seedSource') === seedSource) {
          return false;
        }
        throw Error(`Product hoặc opening ledger ${p.sku} đã tồn tại/chưa nhất quán, dừng để tránh sửa tồn.`);
      }
      tx.create(productRef, {...p, heldStock: 0, openingBalanceId: movementRef.id,
        createdBy: users[0].uid, createdAt: now, ...context});
      tx.create(movementRef, {sku: p.sku, type: 'OPENING', quantity: p.stock,
        unitCost: p.cost, stockBefore: 0, stockAfter: p.stock,
        createdBy: users[0].uid, createdAt: now, ...context});
      return true;
    });
    if (didCreate) created += 2; else skipped += 2;
  }
  for (const c of customers) {
    const {id, ...detail} = c;
    await createOnly(db.collection('customers').doc(id),
      {...detail, totalSpend: 0, lastPurchase: '-'});
  }
  for (const s of suppliers) {
    const {id, ...detail} = s;
    await createOnly(db.collection('suppliers').doc(id),
      {...detail, createdBy: users[1].uid, createdAt: now});
  }
  // Settings chung không có seedSource vì Firestore Rules admin chỉ cho phép 4 khóa.
  const settingsRef = db.collection('system_settings').doc('store');
  const newSettings = await db.runTransaction(async tx => {
    const existing = await tx.get(settingsRef);
    if (existing.exists) return false;
    tx.create(settingsRef, settings);
    return true;
  });
  if (newSettings) created++; else skipped++;

  // Chứng từ mẫu ở trạng thái Pending. Tự duyệt qua UI để thực hành workflow.
  await createOnly(db.collection('purchase_receipts').doc('SEED_RECEIPT_01'), {
    supplierId: suppliers[0].id, supplierName: suppliers[0].name,
    lines: [{sku: products[0].sku, quantity: 2, unitCost: 350000}],
    note: 'Phiếu nhập mẫu - chờ Admin duyệt', status: 'Pending',
    createdBy: users[1].uid, createdAt: now,
  });
  await createOnly(db.collection('stocktakes').doc('SEED_STOCKTAKE_01'), {
    lines: [{sku: products[3].sku, counted: products[3].stock, note: 'Kiểm kê mẫu',
      expected: products[3].stock, heldAtCount: 0, difference: 0}],
    status: 'Pending', createdBy: users[1].uid, createdAt: now,
  });
  // Một hồ sơ xe đi kèm khóa mã định danh theo đúng hash của Cloud Functions.
  const unit = {sku: products[0].sku, unitCode: 'MGT-SEED-001', condition: 'Good',
    location: products[0].location, note: 'Xe mẫu có hộp đẹp',
    trackingStatus: 'Available', createdBy: users[1].uid, createdAt: now};
  const unitRef = db.collection('inventory_units').doc('SEED_UNIT_01');
  const fingerprint = crypto.createHash('sha256')
    .update(JSON.stringify([unit.sku, unit.unitCode])).digest('hex');
  const codeRef = db.collection('inventory_unit_codes').doc(fingerprint);
  const unitCreated = await db.runTransaction(async tx => {
    const [unitSnap, codeSnap] = await Promise.all([tx.get(unitRef), tx.get(codeRef)]);
    if (unitSnap.exists || codeSnap.exists) {
      if (unitSnap.exists && codeSnap.exists &&
          unitSnap.get('seedSource') === seedSource && codeSnap.get('unitId') === unitRef.id) {
        return false;
      }
      throw Error('Mã xe mẫu đã được sử dụng hoặc mất khóa định danh; không sửa tự động.');
    }
    tx.create(unitRef, {...unit, ...context});
    tx.create(codeRef, {unitId: unitRef.id, sku: unit.sku, unitCode: unit.unitCode});
    return true;
  });
  if (unitCreated) created += 2; else skipped += 2;
  await createOnly(db.collection('damage_reports').doc('SEED_DAMAGE_01'), {
    sku: products[4].sku, reason: 'Hộp móp (biên bản mẫu)',
    quantity: 1, loss: 290000, status: 'Pending',
    reportedBy: users[1].uid, createdAt: now,
  });

  await createOnly(db.collection('promotion_proposals').doc('SEED_PROMO_01'), {
    name: 'Giảm 5% dòng Mini GT (Demo)', scope: 'MGT-00125,MGT-00190', discount: 5,
    startAt: Timestamp.fromDate(new Date(Date.now() - 3600000)),
    endAt: Timestamp.fromDate(new Date(Date.now() + 7 * 86400000)),
    proposerUid: users[1].uid, status: 'Pending', createdAt: now,
  });
  // Shift near now lets intern approve and check in during the same demo session.
  await createOnly(db.collection('shifts').doc('SEED_SPRINT5_SHIFT_01'), {
    staffUid: users[2].uid, staffName: users[2].displayName,
    startAt: Timestamp.fromDate(new Date(Date.now() + 20 * 60000)),
    endAt: Timestamp.fromDate(new Date(Date.now() + 20 * 60000 + 4 * 3600000)),
    status: 'Pending', createdAt: now,
  });

  await createOnly(db.collection('staff_requests').doc('SEED_SPRINT5_STAFF_REQUEST_01'), {
    name: 'Ứng viên Staff thử nghiệm', email: 'soleure.pending.staff@example.com',
    phone: '0000000015', hourlyRate: 30000, requestedBy: users[1].uid,
    status: 'Pending', createdAt: now,
  });

  // Sprint 6: chỉ seed CHI PHÍ DEMO, không giả lập doanh thu đã thanh toán.
  // Nếu muốn xem doanh thu hãy dùng POS ở Firebase DEV để tạo giao dịch thật.
  await createOnly(db.collection('expenses').doc('SEED_EXPENSE_ELECTRICITY_01'), {
    name: 'DEMO - Tiền điện cửa hàng', category: 'Định phí', amount: 250000,
    createdBy: users[0].uid, createdAt: now,
  });
  await createOnly(db.collection('expenses').doc('SEED_EXPENSE_WIFI_01'), {
    name: 'DEMO - Internet cửa hàng', category: 'Định phí', amount: 150000,
    createdBy: users[0].uid, createdAt: now,
  });

  // Ca đã duyệt trong tương lai để thực hành đổi ca giữa hai Staff.
  const tomorrow = new Date(Date.now() + 24 * 3600000);
  const past = new Date(Date.now() - 24 * 3600000);
  await createOnly(db.collection('shifts').doc('SEED_SHIFT_APPROVED_01'), {
    staffUid: users[2].uid, staffName: users[2].displayName,
    startAt: Timestamp.fromDate(tomorrow),
    endAt: Timestamp.fromDate(new Date(tomorrow.getTime() + 3 * 3600000)),
    status: 'Approved', createdAt: now,
  });
  await createOnly(db.collection('shifts').doc('SEED_SHIFT_PAST_01'), {
    staffUid: users[2].uid, staffName: users[2].displayName,
    startAt: Timestamp.fromDate(past),
    endAt: Timestamp.fromDate(new Date(past.getTime() + 4 * 3600000)),
    status: 'Approved', createdAt: now,
  });
  await createOnly(db.collection('attendance').doc('SEED_SHIFT_PAST_01'), {
    shiftId: 'SEED_SHIFT_PAST_01', staffUid: users[2].uid,
    checkInAt: Timestamp.fromDate(past),
    checkOutAt: Timestamp.fromDate(new Date(past.getTime() + 4 * 3600000)),
    workStatus: 'Approved', approvedMinutes: 240,
    hourlyRateAtCheckIn: users[2].hourlyRate,
    hourlyRateAtApproval: users[2].hourlyRate,
    createdAt: now, reviewedBy: users[1].uid,
  });
  await createOnly(db.collection('shift_swaps').doc('SEED_SHIFT_APPROVED_01'), {
    shiftId: 'SEED_SHIFT_APPROVED_01', requesterUid: users[2].uid,
    replacementUid: users[3].uid, reason: 'Đổi ca demo cho intern',
    status: 'PENDING', createdAt: now,
  });
  const period = new Date().toISOString().slice(0, 7);
  await createOnly(db.collection('payroll_adjustments').doc('SEED_PAYROLL_ADJ_01'), {
    staffUid: users[2].uid, period, amount: 10000,
    reason: 'Điều chỉnh công demo', status: 'Pending',
    createdBy: users[1].uid, createdAt: now,
  });

  // Firestore-only demo: đồng bộ khóa lịch cho ca seeded. Nếu chưa có
  // shift_schedule thì approve/đổi ca sau này vẫn được serialize bằng transaction.
  const seededIds = ['SEED_SPRINT5_SHIFT_01', 'SEED_SHIFT_APPROVED_01', 'SEED_SHIFT_PAST_01'];
  const seededSlots = [];
  for (const shiftId of seededIds) {
    const shifted = await db.collection('shifts').doc(shiftId).get();
    if (shifted.exists) seededSlots.push({id:shifted.id,
      startMs:shifted.get('startAt').toMillis(),
      endMs:shifted.get('endAt').toMillis()});
  }
  await createOnly(db.collection('shift_schedule').doc(users[2].uid), {slots:seededSlots});

  // Dữ liệu đọc hiển thị trong các màn hình nhưng không tạo giao dịch Paid giả.
  await createOnly(db.collection('order_drafts').doc('SEED_DRAFT_01'), {
    staffUid: users[2].uid, customerId: customers[0].id,
    status: 'draft', items: [{sku: products[0].sku, name: products[0].name,
      quantity: 1, unitPricePreview: products[0].price}],
    totalPreview: products[0].price, createdAt: now,
  });
  await createOnly(db.collection('notifications').doc('SEED_NOTIFY_ADMIN_01'), {
    recipientUid: users[0].uid, title: 'Duyệt phiếu nhập mẫu',
    message: 'Phiếu SEED_RECEIPT_01 đang chờ duyệt',
    category: 'inventory', action: 'inventory', createdAt: now, readAt: null,
  });
  await createOnly(db.collection('notifications').doc('SEED_NOTIFY_MANAGER_01'), {
    recipientUid: users[1].uid, title: 'Kiểm tra ca làm mẫu',
    message: 'Có một ca mẫu Pending',
    category: 'shift', action: 'shifts', createdAt: now, readAt: null,
  });

  if (Object.keys(passwords).length) {
    console.log(`Mật khẩu mới được lưu cục bộ tại: ${output}`);
    console.log('KHÔNG commit/upload file credentials này.');
  }
  console.log(`HOÀN TẤT: tạo ${created}, bỏ qua ${skipped}; không cập nhật hoặc xóa dữ liệu cũ.`);
}

main().catch(error => die(error.message));
