import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';   // ← Added this
import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Optional: Enable offline persistence (recommended)
    FirebaseDatabase.instance.setPersistenceEnabled(true);

    print("✅ Firebase Initialized Successfully!");
    print("✅ Realtime Database Ready!");
  } catch (e) {
    print("❌ Firebase Initialization Failed: $e");
    // You can show an error screen here later if needed
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}