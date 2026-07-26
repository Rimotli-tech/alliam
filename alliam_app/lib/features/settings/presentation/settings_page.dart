import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/session_sign_out.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/audio/background_music_service.dart';
import '../../../core/audio/sound_effects_service.dart';
import '../../train/data/training_audio_service.dart';
import '../../../core/widgets/alliam_page.dart';
import '../data/settings_repository.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool music = true;
  bool voice = true;
  bool effects = true;
  double musicVolume = 1;
  double voiceVolume = 1;
  double effectsVolume = 1;
  bool motion = true;
  bool notifications = true;
  String level = 'Foundation';
  bool automaticPathway = true;
  Map<String, Map<String, dynamic>> _modules = const {};
  bool _loading = true;
  late final SettingsRepository _repository;

  User? get user => FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _repository = SettingsRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.load();
    if (!mounted) return;
    setState(() {
      level = settings.level;
      automaticPathway = settings.automaticPathway;
      music = settings.music;
      voice = settings.voice;
      effects = settings.effects;
      musicVolume = settings.musicVolume;
      voiceVolume = settings.voiceVolume;
      effectsVolume = settings.effectsVolume;
      motion = settings.motion;
      notifications = settings.notifications;
      _modules = settings.modules;
      _loading = false;
    });
    _applyAudio();
  }

  Future<void> _save() => _repository.save(
    AlliamSettings(
      level: level,
      automaticPathway: automaticPathway,
      music: music,
      voice: voice,
      effects: effects,
      musicVolume: musicVolume,
      voiceVolume: voiceVolume,
      effectsVolume: effectsVolume,
      motion: motion,
      notifications: notifications,
      modules: _modules,
    ),
  );

  void _applyAudio() {
    SoundEffectsService.instance
      ..setEnabled(effects)
      ..setVolume(effectsVolume);
    unawaited(
      TrainingAudioService.configureVoice(enabled: voice, volume: voiceVolume),
    );
    unawaited(BackgroundMusicService.instance.setVolume(musicVolume));
    unawaited(BackgroundMusicService.instance.setEnabled(music));
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
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
                  SwitchListTile(
                    value: automaticPathway,
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.route_outlined),
                    title: const Text('Automatic progression'),
                    subtitle: const Text(
                      'Progresses from Foundation to Builder and Champion',
                    ),
                    onChanged: (value) {
                      setState(() => automaticPathway = value);
                      _save();
                    },
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: automaticPathway
                        ? const SizedBox.shrink()
                        : Padding(
                            key: const ValueKey('manual-pathway'),
                            padding: const EdgeInsets.only(bottom: 10),
                            child: DropdownButtonFormField<String>(
                              initialValue: level,
                              decoration: const InputDecoration(
                                labelText: 'Manual level',
                                prefixIcon: Icon(Icons.tune_rounded),
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
                                  child: Text('Champion'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => level = value);
                                _save();
                              },
                            ),
                          ),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: motion,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (value) {
                      setState(() => motion = value);
                      _save();
                    },
                    title: const Text('Motion'),
                    subtitle: const Text('Animations and visual payoff'),
                  ),
                ],
              ),
            ),
            _SettingsSurface(
              title: 'Audio',
              icon: Icons.graphic_eq_rounded,
              child: Column(
                children: [
                  _AudioControl(
                    label: 'Music',
                    enabled: music,
                    volume: musicVolume,
                    onEnabled: (value) {
                      setState(() => music = value);
                      _applyAudio();
                      _save();
                    },
                    onVolume: (value) {
                      setState(() => musicVolume = value);
                      _applyAudio();
                      _save();
                    },
                  ),
                  const Divider(),
                  _AudioControl(
                    label: 'Voice',
                    enabled: voice,
                    volume: voiceVolume,
                    onEnabled: (value) {
                      setState(() => voice = value);
                      _applyAudio();
                      _save();
                    },
                    onVolume: (value) {
                      setState(() => voiceVolume = value);
                      _applyAudio();
                      _save();
                    },
                  ),
                  const Divider(),
                  _AudioControl(
                    label: 'Effects',
                    enabled: effects,
                    volume: effectsVolume,
                    onEnabled: (value) {
                      setState(() => effects = value);
                      _applyAudio();
                      _save();
                    },
                    onVolume: (value) {
                      setState(() => effectsVolume = value);
                      _applyAudio();
                      _save();
                    },
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
                onChanged: (value) {
                  setState(() => notifications = value);
                  _save();
                },
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
    await signOutAlliamSession();
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

class _AudioControl extends StatelessWidget {
  const _AudioControl({
    required this.label,
    required this.enabled,
    required this.volume,
    required this.onEnabled,
    required this.onVolume,
  });

  final String label;
  final bool enabled;
  final double volume;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<double> onVolume;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SwitchListTile(
        value: enabled,
        contentPadding: EdgeInsets.zero,
        title: Text(label),
        onChanged: onEnabled,
      ),
      Row(
        children: [
          const Icon(Icons.volume_down_outlined, size: 18),
          Expanded(
            child: Slider(value: volume, onChanged: enabled ? onVolume : null),
          ),
          Text('${(volume * 100).round()}%'),
        ],
      ),
    ],
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
