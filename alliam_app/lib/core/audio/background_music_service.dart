import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

class BackgroundMusicService {
  BackgroundMusicService._();

  static final instance = BackgroundMusicService._();

  static const _normalVolume = 0.065;
  static const _duckedVolume = 0.0125;

  final AudioPlayer _player = AudioPlayer();
  bool _prepared = false;
  bool _active = true;
  bool _enabled = true;
  bool _exerciseActive = false;
  int _duckCount = 0;
  int _pauseCount = 0;

  double get _restingVolume => _exerciseActive ? _duckedVolume : _normalVolume;

  Future<void> start() async {
    if (!_enabled) return;
    if (!_prepared) {
      await _player.setAsset('assets/audio/alliam-background.mp3');
      await _player.setLoopMode(LoopMode.one);
      await _player.setVolume(_restingVolume);
      _prepared = true;
    }
    if (_active && _pauseCount == 0 && !_player.playing) {
      unawaited(_player.play());
    }
  }

  Future<void> pauseForCountdown() async {
    _exerciseActive = true;
    _pauseCount++;
    if (_prepared && _player.playing) await _player.pause();
  }

  Future<void> resumeAfterCountdown() async {
    if (_pauseCount > 0) _pauseCount--;
    if (_pauseCount == 0 && _active) {
      await start();
      await _player.setVolume(_restingVolume);
    }
  }

  Future<void> duck() async {
    _duckCount++;
    if (!_prepared) return;
    await _player.setVolume(_duckedVolume);
  }

  Future<void> restore() async {
    if (_duckCount > 0) _duckCount--;
    if (!_prepared || _duckCount > 0) return;
    await _player.setVolume(_restingVolume);
  }

  Future<void> leaveExercise() async {
    _exerciseActive = false;
    _duckCount = 0;
    _pauseCount = 0;
    if (!_prepared) return;
    await _player.setVolume(_normalVolume);
    if (_active && !_player.playing) unawaited(_player.play());
  }

  Future<void> setAppActive(bool active) async {
    _active = active;
    if (!_prepared) return;
    if (active) {
      await start();
    } else {
      await _player.pause();
    }
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      if (_prepared) await _player.pause();
      return;
    }
    await start();
    if (_prepared) await _player.setVolume(_restingVolume);
  }

  Future<void> dispose() => _player.dispose();
}

class BackgroundMusicHost extends StatefulWidget {
  const BackgroundMusicHost({required this.child, super.key});

  final Widget child;

  @override
  State<BackgroundMusicHost> createState() => _BackgroundMusicHostState();
}

class _BackgroundMusicHostState extends State<BackgroundMusicHost>
    with WidgetsBindingObserver {
  final _music = BackgroundMusicService.instance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_music.start());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(
      _music.setAppActive(
        state == AppLifecycleState.resumed ||
            state == AppLifecycleState.inactive,
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_music.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => unawaited(_music.start()),
      child: widget.child,
    );
  }
}
