import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../audio/sound_effects_service.dart';
import '../theme/alliam_colors.dart';
import 'alliam_background.dart';
import 'alliam_logo.dart';

class AlliamPage extends StatelessWidget {
  const AlliamPage({
    required this.title,
    required this.child,
    this.subtitle,
    this.showBack = true,
    this.backLocation,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;
  final String? backLocation;

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    return Scaffold(
      body: AlliamBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final desktopNavigation = constraints.maxWidth >= 900;
              return _PageContent(
                title: title,
                subtitle: subtitle,
                showBack: showBack,
                backLocation: backLocation,
                desktopNavigation: desktopNavigation,
                path: path,
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PageContent extends StatelessWidget {
  const _PageContent({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.showBack,
    required this.backLocation,
    required this.desktopNavigation,
    required this.path,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;
  final String? backLocation;
  final bool desktopNavigation;
  final String path;

  bool get _topLevel => const {
    '/pathway',
    '/train',
    '/compete',
    '/rankings',
    '/social',
    '/profile',
    '/settings',
  }.contains(path);

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        child: Row(
          children: [
            if (showBack && !(desktopNavigation && _topLevel))
              IconButton(
                tooltip: 'Back',
                onPressed: () {
                  unawaited(SoundEffectsService.instance.back());
                  if (backLocation != null) {
                    context.go(backLocation!);
                  } else {
                    context.canPop() ? context.pop() : context.go('/home');
                  }
                },
                icon: const Icon(Icons.arrow_back_rounded),
              )
            else if (!desktopNavigation && !showBack)
              const AlliamLogo(width: 104),
            const Spacer(),
            if (!desktopNavigation)
              PopupMenuButton<String>(
                tooltip: 'Account',
                icon: const Icon(Icons.person_outline_rounded),
                onSelected: (value) async {
                  if (value == 'profile') context.go('/profile');
                  if (value == 'settings') context.go('/settings');
                  if (value == 'signout') {
                    await FirebaseAuth.instance.signOut();
                    if (context.mounted) context.go('/');
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'profile', child: Text('Profile')),
                  PopupMenuItem(value: 'settings', child: Text('Settings')),
                  PopupMenuItem(value: 'signout', child: Text('Sign out')),
                ],
              ),
          ],
        ),
      ),
      Expanded(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            desktopNavigation ? 14 : 24,
            desktopNavigation ? 20 : 30,
            desktopNavigation ? 34 : 24,
            64,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AlliamColors.coral,
                      fontSize: 40,
                      height: 1.15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 18),
                    ),
                  ],
                  const SizedBox(height: 34),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    ],
  );
}
