import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

const _firestoreCacheSizeBytes = 50 * 1024 * 1024;

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: const FirebaseOptions(
            apiKey: "AIzaSyBljhPBH4sMSQXVJMSP-qRadQTiwrC4BRg",
            authDomain: "choloto-6aa5b.firebaseapp.com",
            projectId: "choloto-6aa5b",
            storageBucket: "choloto-6aa5b.firebasestorage.app",
            messagingSenderId: "934080509989",
            appId: "1:934080509989:web:3c903c43f4894c904f27cc",
            measurementId: "G-NGFR8XSQJ5"));
  } else {
    await Firebase.initializeApp();
  }

  // This must be configured before the first Firestore read. Persistence is
  // enabled explicitly on every platform (including web) so repeat visits can
  // reuse the local cache instead of downloading the same documents again.
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: _firestoreCacheSizeBytes,
  );
}
