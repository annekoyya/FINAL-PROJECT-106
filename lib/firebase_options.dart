import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        throw UnsupportedError('DefaultFirebaseOptions not configured for android');
      case TargetPlatform.iOS:
        throw UnsupportedError('DefaultFirebaseOptions not configured for ios');
      default:
        throw UnsupportedError('DefaultFirebaseOptions not supported for this platform');
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyD3W1JqzWH1n7RwVay5NGIn2Ri00CFWaoo",
    authDomain: "wordie-3b644.firebaseapp.com",
    projectId: "wordie-3b644",
    storageBucket: "wordie-3b644.firebasestorage.app",
    messagingSenderId: "59126472840",
    appId: "1:59126472840:web:86970379d6c7b977383f3d",
    measurementId: "G-B1CDJX2LQ8",
  );
}