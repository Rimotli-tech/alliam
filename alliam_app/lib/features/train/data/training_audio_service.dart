import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/audio/background_music_service.dart';
import '../domain/spelling_word.dart';

class TrainingAudioService {
  TrainingAudioService(this._storage, this._firestore);

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final Map<String, String> _urlCache = {};
  Map<String, AudioAsset>? _alphabet;
  AudioPlayer? _wordPlayer;
  AudioPlayer? _letterPlayer;

  Future<void> play(AudioAsset? asset) async {
    if (asset == null || asset.storagePath.isEmpty) return;
    final url = await _resolve(asset.storagePath);
    await _wordPlayer?.stop();
    final player = AudioPlayer();
    _wordPlayer = player;
    await BackgroundMusicService.instance.duck();
    try {
      await player.setUrl(url);
      await player.seek(Duration.zero);
      await player.play();
    } finally {
      if (identical(_wordPlayer, player)) _wordPlayer = null;
      await player.dispose();
      await BackgroundMusicService.instance.restore();
    }
  }

  Future<void> spell(
    String word, {
    required void Function(int index) onLetter,
  }) async {
    final alphabet = await _loadAlphabet();
    await BackgroundMusicService.instance.duck();
    try {
      for (var index = 0; index < word.length; index++) {
        final letter = word[index].toLowerCase();
        final asset = alphabet[letter];
        if (asset == null || asset.storagePath.isEmpty) {
          onLetter(-1);
          throw StateError(
            'Recorded alphabet audio is unavailable for ${letter.toUpperCase()}.',
          );
        }
        onLetter(index);
        await _playLetter(asset);
        await Future<void>.delayed(const Duration(milliseconds: 260));
      }
    } finally {
      onLetter(-1);
      await BackgroundMusicService.instance.restore();
    }
  }

  Future<void> _playLetter(AudioAsset asset) async {
    final url = await _resolve(asset.storagePath);
    final player = AudioPlayer();
    _letterPlayer = player;
    try {
      await player.setUrl(url);
      await player.play();
    } finally {
      if (identical(_letterPlayer, player)) _letterPlayer = null;
      await player.dispose();
    }
  }

  Future<String> _resolve(String path) async {
    return _urlCache[path] ??= await _storage.ref(path).getDownloadURL();
  }

  Future<Map<String, AudioAsset>> _loadAlphabet() async {
    if (_alphabet != null) return _alphabet!;
    final snapshot = await _firestore
        .doc('audioVersions/alliam-alphabet-v2')
        .get();
    final raw = snapshot.data()?['alphabet'];
    final result = <String, AudioAsset>{};
    if (raw is Map) {
      for (final entry in raw.entries) {
        final asset = AudioAsset.from(entry.value);
        if (asset.storagePath.isNotEmpty) {
          result[entry.key.toString().toLowerCase()] = asset;
        }
      }
    }
    final missing = 'abcdefghijklmnopqrstuvwxyz'
        .split('')
        .where((letter) => !result.containsKey(letter))
        .toList(growable: false);
    if (missing.isNotEmpty) {
      throw StateError(
        'Recorded alphabet library is incomplete: '
        '${missing.map((letter) => letter.toUpperCase()).join(', ')}.',
      );
    }
    _alphabet = result;
    return result;
  }

  Future<void> stop() async {
    await _wordPlayer?.stop();
    await _letterPlayer?.stop();
  }

  Future<void> dispose() async {
    await stop();
  }
}
