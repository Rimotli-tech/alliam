import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../../features/train/data/training_audio_service.dart';
import '../../features/settings/data/settings_repository.dart';
import 'background_music_service.dart';
import 'sound_effects_service.dart';

class AudioPreparationHost extends StatefulWidget {
  const AudioPreparationHost({required this.child, super.key});

  final Widget child;

  @override
  State<AudioPreparationHost> createState() => _AudioPreparationHostState();
}

class _AudioPreparationHostState extends State<AudioPreparationHost> {
  late final TrainingAudioService _audio;
  StreamSubscription<User?>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _audio = TrainingAudioService.shared(
      FirebaseStorage.instance,
      FirebaseFirestore.instance,
    );
    unawaited(_audio.prepareAppAudio());
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen(
      (_) => unawaited(_applySoundPreference()),
    );
  }

  Future<void> _applySoundPreference() async {
    if (FirebaseAuth.instance.currentUser == null) {
      SoundEffectsService.instance.setEnabled(true);
      await BackgroundMusicService.instance.setEnabled(true);
      return;
    }
    final settings = await SettingsRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    ).load();
    SoundEffectsService.instance.setEnabled(settings.sound);
    await BackgroundMusicService.instance.setEnabled(settings.sound);
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    unawaited(_audio.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
