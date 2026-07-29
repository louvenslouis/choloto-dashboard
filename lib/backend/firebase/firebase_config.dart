import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

Future initFirebase() async {
  if (kIsWeb) {
    await Firebase.initializeApp(
        options: FirebaseOptions(
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
}
