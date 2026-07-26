import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/alliam_colors.dart';
import '../auth/session_sign_out.dart';

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
          await signOutAlliamSession();
          if (context.mounted) context.go('/');
        }
      },
      itemBuilder: (_) => [
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
        const PopupMenuDivider(),
        const PopupMenuItem(
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
