import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool sound = true;
  bool motion = true;
  bool notifications = true;
  String level = 'Foundation';

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return AlliamPage(
      title: 'Settings',
      subtitle: 'Make Alliam yours',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth > 760;
          final cards = [
            _SettingsSurface(
              title: 'Training',
              icon: Icons.fitness_center_rounded,
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: const InputDecoration(
                      labelText: 'Learner pathway',
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Foundation',
                        child: Text('Foundation'),
                      ),
                      DropdownMenuItem(
                        value: 'Builder',
                        child: Text('Builder'),
                      ),
                      DropdownMenuItem(
                        value: 'Championship',
                        child: Text('Championship'),
                      ),
                    ],
                    onChanged: (value) =>
                        setState(() => level = value ?? level),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: sound,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => sound = value),
                    title: const Text('Sound'),
                    subtitle: const Text('Pronunciation and feedback'),
                  ),
                  const Divider(),
                  SwitchListTile(
                    value: motion,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) => setState(() => motion = value),
                    title: const Text('Motion'),
                    subtitle: const Text('Animations and visual payoff'),
                  ),
                ],
              ),
            ),
            _SettingsSurface(
              title: 'Account',
              icon: Icons.person_outline_rounded,
              child: Column(
                children: [
                  _AccountRow(
                    title: user?.email ?? 'Demo profile',
                    body: user?.isAnonymous == true
                        ? 'Temporary account'
                        : user?.emailVerified == true
                        ? 'Email verified'
                        : 'Email not verified',
                    action: user?.isAnonymous == true
                        ? null
                        : user?.emailVerified == true
                        ? null
                        : TextButton(
                            onPressed: _sendVerification,
                            child: const Text('Verify'),
                          ),
                  ),
                  const Divider(),
                  _AccountRow(
                    title: 'Password',
                    body: 'Send a secure reset link',
                    action: user?.email == null
                        ? null
                        : TextButton(
                            onPressed: _sendPasswordReset,
                            child: const Text('Reset'),
                          ),
                  ),
                  const Divider(),
                  _AccountRow(
                    title: 'Profile',
                    body: 'Account owner and learners',
                    action: TextButton(
                      onPressed: () => context.go('/profile'),
                      child: const Text('Open'),
                    ),
                  ),
                  const Divider(),
                  _AccountRow(
                    title: 'Sign out',
                    body: 'Return to account access',
                    action: OutlinedButton(
                      onPressed: _signOut,
                      child: const Text('Sign out'),
                    ),
                  ),
                ],
              ),
            ),
            _SettingsSurface(
              title: 'Notifications',
              icon: Icons.notifications_none_rounded,
              child: SwitchListTile(
                value: notifications,
                contentPadding: EdgeInsets.zero,
                onChanged: (value) => setState(() => notifications = value),
                title: const Text('Activity alerts'),
                subtitle: const Text('Matches, invitations, and rankings'),
              ),
            ),
            const _SettingsSurface(
              title: 'Privacy & safety',
              icon: Icons.shield_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SafetyRow(
                    icon: Icons.mic_none_rounded,
                    title: 'Voice features',
                    body: 'Guardian consent applies to child accounts.',
                  ),
                  Divider(),
                  _SafetyRow(
                    icon: Icons.lock_outline_rounded,
                    title: 'Learner identity',
                    body: 'Only competition nicknames are shown publicly.',
                  ),
                ],
              ),
            ),
          ];

          return GridView.count(
            crossAxisCount: wide ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 18,
            mainAxisSpacing: 18,
            childAspectRatio: wide ? 1.28 : 1.4,
            children: cards,
          );
        },
      ),
    );
  }

  Future<void> _sendPasswordReset() async {
    final email = user?.email;
    if (email == null) return;
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    _notice('Password reset email sent.');
  }

  Future<void> _sendVerification() async {
    await user?.sendEmailVerification();
    _notice('Verification email sent.');
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) context.go('/');
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SettingsSurface extends StatelessWidget {
  const _SettingsSurface({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(26),
    decoration: BoxDecoration(
      color: AlliamColors.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AlliamColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x35D7B69B),
          blurRadius: 26,
          offset: Offset(8, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AlliamColors.coral),
            const SizedBox(width: 10),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        const SizedBox(height: 20),
        Expanded(child: SingleChildScrollView(child: child)),
      ],
    ),
  );
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.title,
    required this.body,
    required this.action,
  });

  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(body),
            ],
          ),
        ),
        ?action,
      ],
    ),
  );
}

class _SafetyRow extends StatelessWidget {
  const _SafetyRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      children: [
        Icon(icon, color: AlliamColors.coral),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(body),
            ],
          ),
        ),
      ],
    ),
  );
}
