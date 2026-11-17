#!/usr/bin/env node
'use strict';
// Cleanup is intentionally conservative. No collection wipes, no production.
const flags = process.argv.slice(2);
function arg(name) { const i = flags.indexOf(name); return i < 0 ? null : flags[i+1]; }
const projectId = arg('--project');
const seedSource = arg('--seed-source');
const batch = arg('--seed-batch');
const apply = flags.includes('--apply');
const emulator = Boolean(process.env.FIRESTORE_EMULATOR_HOST) && Boolean(process.env.FIREBASE_AUTH_EMULATOR_HOST);
const collections = [
  'products','stock_movements','customers','suppliers','purchase_receipts',
  'stocktakes','inventory_units','damage_reports','promotion_proposals',
  'shifts','shift_schedule','shift_swaps','attendance','attendance_corrections',
  'payroll_adjustments','payroll_periods','payroll_records','orders',
  'order_drafts','holds','return_requests','commission_events','expenses',
  'notifications','staff_requests','users',
];
async function main() {
  if (flags.includes('--help')) {
    console.log('node scripts/firebase/cleanup_demo.js --project soleure-dev --seed-source soleure-intern-seed-v1 --seed-batch soleure-firestore-intern-v1 [--apply --confirm-project soleure-dev]');
    return;
  }
  if (!projectId || !/^[-a-z0-9]{6,50}$/.test(projectId) || !seedSource || !batch) {
    throw Error('Cần --project, --seed-source và --seed-batch rõ ràng.');
  }
  if (!emulator && !/(^|[-_])(dev|demo|test)([-_]|$)/i.test(projectId)) {
    throw Error('TỪ CHỐI project không phải DEV/TEST/DEMO.');
  }
  if (apply && arg('--confirm-project') !== projectId) {
    throw Error('Phải xác nhận --confirm-project khớp chính xác.');
  }
  console.log(`CLEANUP ${apply?'APPLY':'DRY-RUN'} | ${projectId} | ${seedSource} | ${batch}`);
  // For dry-run without credentials, show intent rather than pretending to query.
  if (!apply && !emulator && !process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.log('DRY-RUN (không credentials): chưa truy vấn Firebase, không thể liệt kê ID.');
    return;
  }
  const {initializeApp,applicationDefault} = require('firebase-admin/app');
  const {getFirestore} = require('firebase-admin/firestore');
  initializeApp(emulator ? {projectId} : {credential:applicationDefault(),projectId});
  const db = getFirestore();
  const doomed = [];
  for (const c of collections) {
    const rows = await db.collection(c).where('seedSource','==',seedSource).get();
    for (const doc of rows.docs) {
      if (doc.get('seedBatchId') !== batch || doc.get('isDemo') !== true) continue;
      doomed.push({path:doc.ref.path,ref:doc.ref,collection:c,doc});
    }
  }
  doomed.sort((a,b)=>a.path.localeCompare(b.path));
  doomed.forEach(row=>console.log(`TARGET ${row.path}`));
  console.log(`Total ${doomed.length} tagged documents; no untagged docs will be deleted.`);
  if (!apply) return;
  // Stop if non-seed orders/holds/receipts refer to demo product/user records.
  const productIds = new Set(doomed.filter(d=>d.collection==='products').map(d=>d.doc.id));
  const userIds = new Set(doomed.filter(d=>d.collection==='users').map(d=>d.doc.id));
  const protectedCollections = ['orders','holds','purchase_receipts','stocktakes','attendance','return_requests','commission_events'];
  for (const name of protectedCollections) {
    const result = await db.collection(name).limit(1001).get();
    if (result.size > 1000) throw Error(`${name} vượt 1000 record; cleanup không thể kiểm tra đủ.`);
    for (const row of result.docs) {
      if (doomed.some(d=>d.path===row.ref.path)) continue;
      const text = JSON.stringify(row.data());
      if ([...productIds,...userIds].some(id=>text.includes(id))) {
        throw Error(`NON-SEED REFERENCE ${row.ref.path}: từ chối xóa dữ liệu đang được dùng.`);
      }
    }
  }
  // Cleanup is ordered by dependency: users last. Does not delete Auth accounts
  // automatically; remove seeded Auth users separately with verified Admin tooling.
  for (const row of doomed.filter(d=>d.collection!=='users')) await row.ref.delete();
  console.log('Dữ liệu seeded (ngoại trừ users/Auth) đã xóa.');
  console.log('users/Auth giữ nguyên để tránh xóa tài khoản đang được sử dụng.');
}
main().catch(e=>{ console.error('CLEANUP FAILED:',e.message); process.exitCode=1; });
