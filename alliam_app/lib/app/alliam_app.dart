import 'package:flutter/material.dart';

import '../core/audio/background_music_service.dart';
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
      builder: (context, child) =>
          BackgroundMusicHost(child: child ?? const SizedBox.shrink()),
    );
  }
}
