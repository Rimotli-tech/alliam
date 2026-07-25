import 'package:just_audio/just_audio.dart';

class SoundEffectsService {
  SoundEffectsService._();

  static final instance = SoundEffectsService._();
  int _keyIndex = 0;

  Future<void> startModule() =>
      _play('assets/audio/start-module.mp3', volume: 0.096);

  Future<void> correct() =>
      _play('assets/audio/correct-sound.mp3', volume: 0.24);

  Future<void> back() => _play('assets/audio/back.mp3', volume: 0.15);

  Future<void> countdown() =>
      _play('assets/audio/countdown-beep.mp3', volume: 0.18);

  Future<void> key() {
    _keyIndex = (_keyIndex % 3) + 1;
    return _play('assets/audio/key-$_keyIndex.mp3', volume: 0.12);
  }

  Future<void> wrongAnswer() =>
      _play('assets/audio/wrong-answer.mp3', volume: 0.22);

  Future<void> wordEntry() =>
      _play('assets/audio/word-entry.mp3', volume: 0.13);

  Future<void> nextWord() =>
      _play('assets/audio/next-word.mp3', volume: 0.14);

  Future<void> _play(String asset, {required double volume}) async {
    final player = AudioPlayer();
    try {
      await player.setAsset(asset);
      await player.setVolume(volume);
      await player.play();
    } finally {
      await player.dispose();
    }
  }
}
