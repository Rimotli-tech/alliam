import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/alliam_colors.dart';

class AccountMenuButton extends StatelessWidget {
  const AccountMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Account',
      icon: const Icon(Icons.person_outline_rounded),
      color: AlliamColors.surfaceStrong,
      surfaceTintColor: Colors.transparent,
      position: PopupMenuPosition.under,
      onSelected: (value) async {
        if (value == 'home') context.go('/home');
        if (value == 'profile') context.go('/profile');
        if (value == 'settings') context.go('/settings');
        if (value == 'signout') {
          await FirebaseAuth.instance.signOut();
          if (context.mounted) context.go('/');
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'home',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.grid_view_rounded),
            title: Text('Explore'),
          ),
        ),
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.person_outline_rounded),
            title: Text('Profile'),
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: 'signout',
          child: ListTile(
            dense: true,
            leading: Icon(Icons.logout_rounded),
            title: Text('Sign out'),
          ),
        ),
      ],
    );
  }
}
