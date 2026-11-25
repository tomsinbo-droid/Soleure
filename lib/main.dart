// Công dụng tệp: Khởi động ứng dụng và cấu hình Firebase.

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'firebase_options.dart';

/// Khởi động chương trình và thực hiện các bước chuẩn bị ban đầu.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (const bool.fromEnvironment('SOLEURE_FIRESTORE_EMULATOR')) {
      FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
      FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
    }
    runApp(const SoleureApp());
  } catch (error) {
    runApp(SoleureApp(setupError: error.toString()));
  }
}
