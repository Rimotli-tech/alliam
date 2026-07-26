import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/alliam_app.dart';
import 'firebase_options.dart';
import 'core/firebase/firebase_emulators.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  connectFirebaseEmulators();
  runApp(const ProviderScope(child: AlliamApp()));
}
