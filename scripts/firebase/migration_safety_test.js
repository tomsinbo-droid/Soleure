#!/usr/bin/env node
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const walk = dir => fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>{
  const full=path.join(dir,e.name);return e.isDirectory()?walk(full):[full];
});
const dart = walk(path.join(root,'lib')).filter(f=>f.endsWith('.dart'));
const src = dart.map(f=>fs.readFileSync(f,'utf8')).join('\n');
assert(!/FirebaseFunctions|httpsCallable|FirebaseCallable|package:cloud_functions|SOLEURE_DEMO/.test(src),
  'Legacy functions/demo state leaked into runtime');
const pubspec = fs.readFileSync(path.join(root,'pubspec.yaml'),'utf8');
assert(!pubspec.includes('cloud_functions:'),'pubspec still needs Cloud Functions');
assert(!pubspec.includes('firebase_storage:'),'pubspec still needs storage');
const rules=fs.readFileSync(path.join(root,'firestore.rules'),'utf8');
const localRules=fs.readFileSync(path.join(root,'firestore.emulator.rules'),'utf8');
assert(rules.includes('allow write: if false;'),'Production rules missing hard deny');
assert(!rules.includes('allow read, write: if true'),'Unprotected production rules');
assert(!localRules.includes('allow read, write: if true'),'Unprotected demo rules');
const guard=fs.readFileSync(path.join(root,'lib/services/firestore_demo_guard.dart'),'utf8');
assert(guard.includes('SOLEURE_FIRESTORE_EMULATOR'),'Missing emulator gating');
const highRisk=['inventory','hold','pos','payment','return','shift','attendance','payroll'];
for(const name of highRisk) {
  const file=fs.readFileSync(path.join(root,`lib/services/${name}_service.dart`),'utf8');
  assert(file.includes('requireEmulator('),`${name} can mutate ledger outside emulator gate`);
  assert(file.includes('runTransaction('),`${name} needs Firestore transaction`);
}
console.log(`MIGRATION STATIC QA PASS: ${dart.length} Dart files; 8/8 critical services guarded and transactional`);
console.log('NOT TESTED: Dart compilation, emulator rules evaluation, real Firestore concurrency, UI E2E');
