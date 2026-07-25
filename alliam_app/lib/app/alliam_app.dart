import 'package:flutter/material.dart';

import '../core/theme/alliam_theme.dart';
import 'router.dart';

class AlliamApp extends StatelessWidget {
  const AlliamApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Alliam',
      debugShowCheckedModeBanner: false,
      theme: AlliamTheme.light,
      routerConfig: alliamRouter,
    );
  }
}
