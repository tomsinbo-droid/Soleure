// Công dụng tệp: Cấu hình kết nối Firebase theo nền tảng.

// File được cấu hình cho Firebase project "soleure-c1554".
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
          'Firebase hiện chỉ được cấu hình cho Android. '
          'Chạy flutterfire configure để thêm platform này.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBoFpJZjLkGtQizCUeaAGL1e6HSJtD7F2w',
    appId: '1:133708453802:android:17622f5d2ed30c6c14bdd3',
    messagingSenderId: '133708453802',
    projectId: 'soleure-c1554',
    storageBucket: 'soleure-c1554.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyB-_YHX_fskVcjBYxn60faG8YhGgHYxtlM',
    appId: '1:133708453802:web:cb8baa688f819a4f14bdd3',
    messagingSenderId: '133708453802',
    projectId: 'soleure-c1554',
    authDomain: 'soleure-c1554.firebaseapp.com',
    storageBucket: 'soleure-c1554.firebasestorage.app',
    measurementId: 'G-6BQT5BD4XQ',
  );
}
