'use strict';

const crypto = require('node:crypto');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {HttpsError, onCall} = require('firebase-functions/v2/https');

initializeApp();

const db = getFirestore();
const auth = getAuth();
const allowedRoles = new Set(['manager', 'staff']);

function requireString(value, field, {email = false} = {}) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new HttpsError('invalid-argument', `${field} là bắt buộc.`);
  }
  const result = value.trim();
  if (email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(result)) {
    throw new HttpsError('invalid-argument', 'Email không hợp lệ.');
  }
  return result;
}

function requireAccountInput(data) {
  const name = requireString(data.name, 'Họ tên');
  const email = requireString(data.email, 'Email', {email: true}).toLowerCase();
  const phone = typeof data.phone === 'string' ? data.phone.trim() : '';
  const role = data.role;
  const hourlyRate = data.hourlyRate;
  if (!allowedRoles.has(role)) {
    throw new HttpsError('invalid-argument', 'Vai trò phải là manager hoặc staff.');
  }
  if (!Number.isInteger(hourlyRate) || hourlyRate < 0 || hourlyRate > 1000000) {
    throw new HttpsError('invalid-argument', 'Lương giờ không hợp lệ.');
  }
  return {name, email, phone, role, hourlyRate};
}

async function requireAdmin(uid) {
  const profile = await db.collection('users').doc(uid).get();
  if (!profile.exists || profile.get('role') !== 'admin' ||
      profile.get('active') === false) {
    throw new HttpsError('permission-denied', 'Chỉ Admin đang hoạt động được quản lý tài khoản.');
  }
}

exports.createStaffAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Bạn chưa đăng nhập.');
  }
  await requireAdmin(request.auth.uid);
  const input = requireAccountInput(request.data || {});

  try {
    await auth.getUserByEmail(input.email);
    throw new HttpsError('already-exists', 'Email này đã có tài khoản.');
  } catch (error) {
    if (error instanceof HttpsError || error.code !== 'auth/user-not-found') {
      throw error;
    }
  }

  const user = await auth.createUser({
    email: input.email,
    displayName: input.name,
    password: crypto.randomBytes(32).toString('base64url'),
    disabled: false,
  });

  try {
    await db.collection('users').doc(user.uid).create({
      uid: user.uid,
      displayName: input.name,
      email: input.email,
      phone: input.phone,
      role: input.role,
      hourlyRate: input.hourlyRate,
      active: true,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  } catch (error) {
    await auth.deleteUser(user.uid);
    throw new HttpsError('internal', 'Không thể tạo hồ sơ tài khoản.');
  }

  return {uid: user.uid, email: input.email};
});

exports.updateStaffAccount = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Bạn chưa đăng nhập.');
  }
  await requireAdmin(request.auth.uid);
  const data = request.data || {};
  const uid = requireString(data.uid, 'Mã tài khoản');
  const name = requireString(data.name, 'Họ tên');
  const phone = typeof data.phone === 'string' ? data.phone.trim() : '';
  const role = data.role;
  const hourlyRate = data.hourlyRate;
  const active = data.active;
  if (!allowedRoles.has(role) || !Number.isInteger(hourlyRate) ||
      hourlyRate < 0 || hourlyRate > 1000000 || typeof active !== 'boolean') {
    throw new HttpsError('invalid-argument', 'Dữ liệu tài khoản không hợp lệ.');
  }

  const profile = await db.collection('users').doc(uid).get();
  if (!profile.exists || !allowedRoles.has(profile.get('role'))) {
    throw new HttpsError('not-found', 'Không tìm thấy tài khoản Staff/Manager.');
  }

  await auth.updateUser(uid, {displayName: name, disabled: !active});
  await profile.ref.update({
    displayName: name,
    phone,
    role,
    hourlyRate,
    active,
    updatedAt: FieldValue.serverTimestamp(),
  });
  return {uid};
});
