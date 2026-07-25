import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../audio/sound_effects_service.dart';
import '../theme/alliam_colors.dart';
import 'alliam_background.dart';

class AlliamPage extends StatelessWidget {
  const AlliamPage({
    required this.title,
    required this.child,
    this.subtitle,
    this.showBack = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AlliamBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    if (showBack)
                      IconButton(
                        tooltip: 'Back',
                        onPressed: () {
                          unawaited(SoundEffectsService.instance.back());
                          context.canPop()
                              ? context.pop()
                              : context.go('/home');
                        },
                        icon: const Icon(Icons.arrow_back_rounded),
                      )
                    else
                      Text(
                        'Alliam',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AlliamColors.coral,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    const Spacer(),
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
                        PopupMenuItem(
                          value: 'settings',
                          child: Text('Settings'),
                        ),
                        PopupMenuItem(
                          value: 'signout',
                          child: Text('Sign out'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 30, 24, 64),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: Column(
                        children: [
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
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
          ),
        ),
      ),
    );
  }
}
