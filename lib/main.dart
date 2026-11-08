import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'app/app.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase across supported platforms (Web, Android, iOS)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization notice: $e');
    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  runApp(const NestoraApp());
}
