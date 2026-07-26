import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/audio/background_music_service.dart';
import '../../../core/audio/sound_effects_service.dart';
import '../domain/spelling_word.dart';
import 'bundled_alphabet_manifest.dart';
import 'sequential_letter_playback.dart';
import 'session_audio_manifest.dart';
import 'word_audio_cache.dart';

class TrainingAudioService {
  static TrainingAudioService? _sharedInstance;

  static TrainingAudioService shared(
    FirebaseStorage storage,
    FirebaseFirestore firestore,
  ) {
    return _sharedInstance ??= TrainingAudioService(storage, firestore);
  }

  TrainingAudioService(
    this._storage,
    this._firestore, {
    AssetBundle? assetBundle,
    AudioPlayer? wordPlayer,
    AudioPlayer? letterPlayer,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _wordPlayer = wordPlayer ?? AudioPlayer(),
       _letterPlayer = letterPlayer ?? AudioPlayer() {
    _wordCache = WordAudioCache(
      resolveUrl: _resolveStorageUrl,
      preloadUrl: _preloadUrl,
    );
  }

  final FirebaseStorage _storage;
  final FirebaseFirestore _firestore;
  final AssetBundle _assetBundle;
  final AudioPlayer _wordPlayer;
  final AudioPlayer _letterPlayer;
  final _preparationController =
      StreamController<SessionAudioPreparation>.broadcast();
  final Map<String, AudioAsset> _remoteAlphabet = {};
  final Map<String, AudioSource> _nativePreparedSources = {};
  final Set<String> _missingBundledLetters = {};

  late final WordAudioCache _wordCache;
  Future<void>? _appPreparation;
  SessionAudioManifest _sessionManifest = const SessionAudioManifest([]);
  SessionAudioPreparation _sessionPreparation = const SessionAudioPreparation(
    total: 0,
    ready: 0,
    failedWordIds: {},
    firstWordReady: false,
    complete: true,
  );
  Set<String> _readyWordIds = {};
  Set<String> _failedWordIds = {};
  bool _remoteAlphabetRequired = false;
  DateTime? _lastRemoteAlphabetCheck;
  int _sessionGeneration = 0;
  bool _disposed = false;

  Stream<SessionAudioPreparation> get preparation =>
      _preparationController.stream;

  SessionAudioPreparation get currentPreparation => _sessionPreparation;

  SessionAudioManifest get currentManifest => _sessionManifest;

  Future<void> prepareAppAudio({bool refreshRemoteVersion = false}) {
    if (refreshRemoteVersion) {
      return (_appPreparation ??= _prepareAppAudio()).then(
        (_) => _refreshRemoteAlphabetVersion(),
      );
    }
    return _appPreparation ??= _prepareAppAudio();
  }

  Future<void> _prepareAppAudio() async {
    final validation = await BundledAlphabetManifest.validate(_assetBundle);
    _missingBundledLetters
      ..clear()
      ..addAll(validation);

    await _refreshRemoteAlphabetVersion();

    if (_missingBundledLetters.length == 26 && _remoteAlphabet.length != 26) {
      throw StateError('No complete recorded alphabet library is available.');
    }

    final firstBundled = BundledAlphabetManifest.assets['a'];
    if (!_remoteAlphabetRequired &&
        !_missingBundledLetters.contains('a') &&
        firstBundled != null) {
      await _letterPlayer.setAsset(firstBundled);
      await _letterPlayer.stop();
    }
  }

  Future<void> _refreshRemoteAlphabetVersion() async {
    final lastCheck = _lastRemoteAlphabetCheck;
    if (lastCheck != null &&
        DateTime.now().difference(lastCheck) < const Duration(minutes: 15)) {
      return;
    }
    try {
      final snapshot = await _firestore
          .doc(
            'audioVersions/'
            '${BundledAlphabetManifest.firestoreVersionId}',
          )
          .get();
      final data = snapshot.data();
      final sourceVersion = data?['sourceVersion']?.toString();
      _remoteAlphabetRequired =
          sourceVersion != null &&
          sourceVersion.isNotEmpty &&
          sourceVersion != BundledAlphabetManifest.sourceVersion;
      _readRemoteAlphabet(data?['alphabet']);
      _lastRemoteAlphabetCheck = DateTime.now();
    } catch (_) {
      // The approved bundled set remains usable offline. A failed unauthenticated
      // startup check is deliberately retried after session selection.
    }
  }

  void _readRemoteAlphabet(Object? raw) {
    _remoteAlphabet.clear();
    if (raw is! Map) return;
    for (final entry in raw.entries) {
      final asset = AudioAsset.from(entry.value);
      if (asset.storagePath.isNotEmpty) {
        _remoteAlphabet[entry.key.toString().toLowerCase()] = asset;
      }
    }
  }

  Future<SessionAudioManifest> prepareSession(
    List<SpellingWord> words, {
    Duration firstWordTimeout = const Duration(seconds: 8),
  }) async {
    final generation = ++_sessionGeneration;
    try {
      await prepareAppAudio(
        refreshRemoteVersion: true,
      ).timeout(const Duration(seconds: 2));
    } catch (_) {
      // Offline/version-check failures must not hold module entry.
    }
    if (!_isCurrent(generation)) return const SessionAudioManifest([]);
    _sessionManifest = SessionAudioManifest.fromWords(words);
    _readyWordIds = {};
    _failedWordIds = {};
    _publishPreparation(complete: words.isEmpty);

    if (words.isEmpty) return _sessionManifest;

    await _prepareEntry(
      _sessionManifest.entries.first,
      generation,
    ).timeout(firstWordTimeout, onTimeout: () => false);

    if (generation == _sessionGeneration && !_disposed) {
      unawaited(_prepareRemaining(generation));
    }
    return _sessionManifest;
  }

  Future<void> _prepareRemaining(int generation) async {
    await Future.wait([
      for (final entry in _sessionManifest.nextTwo)
        _prepareEntry(entry, generation),
    ]);
    if (!_isCurrent(generation)) return;

    final background = _sessionManifest.background;
    var next = 0;
    Future<void> worker() async {
      while (_isCurrent(generation) && next < background.length) {
        final entry = background[next++];
        await _prepareEntry(entry, generation);
      }
    }

    await Future.wait([worker(), worker()]);
    if (_isCurrent(generation)) _publishPreparation(complete: true);
  }

  Future<bool> _prepareEntry(SessionAudioEntry entry, int generation) async {
    if (!_isCurrent(generation)) return false;
    if (entry.pronunciationPath.isEmpty) {
      _failedWordIds.add(entry.wordId);
      _publishPreparation();
      return false;
    }
    try {
      await _wordCache.prepare(entry.pronunciationPath);
      if (!_isCurrent(generation)) return false;
      _readyWordIds.add(entry.wordId);
      _failedWordIds.remove(entry.wordId);
      _publishPreparation();
      return true;
    } catch (_) {
      if (!_isCurrent(generation)) return false;
      _failedWordIds.add(entry.wordId);
      _publishPreparation();
      return false;
    }
  }

  void _publishPreparation({bool complete = false}) {
    final firstWordId = _sessionManifest.entries.isEmpty
        ? null
        : _sessionManifest.entries.first.wordId;
    _sessionPreparation = SessionAudioPreparation(
      total: _sessionManifest.entries.length,
      ready: _readyWordIds.length,
      failedWordIds: Set.unmodifiable(_failedWordIds),
      firstWordReady:
          firstWordId != null && _readyWordIds.contains(firstWordId),
      complete:
          complete ||
          _readyWordIds.length + _failedWordIds.length >=
              _sessionManifest.entries.length,
    );
    if (!_preparationController.isClosed) {
      _preparationController.add(_sessionPreparation);
    }
  }

  Future<void> play(AudioAsset? asset) async {
    if (!SoundEffectsService.instance.enabled ||
        asset == null ||
        asset.storagePath.isEmpty ||
        _disposed) {
      return;
    }
    await _wordPlayer.stop();
    await BackgroundMusicService.instance.duck();
    try {
      await _setWordSource(asset.storagePath);
      await _wordPlayer.seek(Duration.zero);
      await _wordPlayer.play();
    } finally {
      await BackgroundMusicService.instance.restore();
    }
  }

  Future<void> _setWordSource(String storagePath) async {
    try {
      await _wordCache.prepare(storagePath);
    } catch (_) {
      // Preparation failure is recoverable: direct streaming is attempted.
    }
    if (!kIsWeb) {
      final source = _nativePreparedSources[storagePath];
      if (source != null) {
        await _wordPlayer.setAudioSource(source);
        return;
      }
    }
    final url = await _wordCache.resolve(storagePath);
    await _wordPlayer.setUrl(url);
  }

  Future<void> spell(
    String word, {
    required void Function(int index) onLetter,
  }) async {
    if (!SoundEffectsService.instance.enabled) return;
    await prepareAppAudio();
    final generation = _sessionGeneration;
    await BackgroundMusicService.instance.duck();
    try {
      await playSequentialLetters(
        word,
        playLetter: _playLetter,
        onLetter: onLetter,
        isCancelled: () => _disposed || generation != _sessionGeneration,
      );
    } finally {
      await BackgroundMusicService.instance.restore();
    }
  }

  Future<void> _playLetter(String letter) async {
    await _letterPlayer.stop();
    final source = BundledAlphabetManifest.sourceFor(
      letter: letter,
      remoteVersionRequired: _remoteAlphabetRequired,
      missingBundledLetters: _missingBundledLetters,
      remoteLetters: _remoteAlphabet.keys.toSet(),
    );
    if (source == AlphabetPlaybackSource.bundled) {
      await _letterPlayer.setAsset(BundledAlphabetManifest.assets[letter]!);
    } else if (source == AlphabetPlaybackSource.remote) {
      final remote = _remoteAlphabet[letter];
      if (remote == null) throw StateError('Missing remote alphabet metadata.');
      final url = await _wordCache.resolve(remote.storagePath);
      await _letterPlayer.setUrl(url);
    } else {
      throw StateError(
        'Recorded alphabet audio is unavailable for ${letter.toUpperCase()}.',
      );
    }
    await _letterPlayer.seek(Duration.zero);
    await _letterPlayer.play();
  }

  Future<String> _resolveStorageUrl(String storagePath) =>
      _storage.ref(storagePath).getDownloadURL();

  Future<void> _preloadUrl(String storagePath, String resolvedUrl) async {
    final player = AudioPlayer();
    try {
      if (kIsWeb) {
        await player.setUrl(resolvedUrl);
        return;
      }
      final cachingSource = LockCachingAudioSource(Uri.parse(resolvedUrl));
      final downloadComplete = cachingSource.downloadProgressStream
          .firstWhere((progress) => progress >= 1)
          .timeout(const Duration(seconds: 20));
      await player.setAudioSource(await cachingSource.resolve());
      try {
        await downloadComplete;
      } on TimeoutException {
        // The source is buffered and playable even if persistent completion
        // could not be confirmed within the preparation window.
      }
      _nativePreparedSources[storagePath] = await cachingSource.resolve();
    } finally {
      await player.dispose();
    }
  }

  bool _isCurrent(int generation) =>
      !_disposed && generation == _sessionGeneration;

  Future<void> stop() async {
    _sessionGeneration++;
    await _wordPlayer.stop();
    await _letterPlayer.stop();
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _sessionGeneration++;
    await _wordPlayer.dispose();
    await _letterPlayer.dispose();
    await _preparationController.close();
    if (identical(_sharedInstance, this)) _sharedInstance = null;
  }
}
