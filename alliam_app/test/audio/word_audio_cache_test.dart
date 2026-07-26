import 'dart:async';

import 'package:alliam_app/features/train/data/word_audio_cache.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('URL resolution and preload are deduplicated in flight', () async {
    var resolves = 0;
    var preloads = 0;
    final release = Completer<void>();
    final preloadStarted = Completer<void>();
    final cache = WordAudioCache(
      resolveUrl: (path) async {
        resolves++;
        return 'https://audio.test/$path';
      },
      preloadUrl: (path, url) async {
        preloads++;
        preloadStarted.complete();
        await release.future;
      },
    );

    final first = cache.prepare('audio/v1/word/pronunciation.mp3');
    final second = cache.prepare('audio/v1/word/pronunciation.mp3');
    await preloadStarted.future;
    expect(resolves, 1);
    expect(preloads, 1);

    release.complete();
    expect(await first, await second);
    expect(cache.isPrepared('audio/v1/word/pronunciation.mp3'), isTrue);
  });

  test('prepared audio is reused without another network operation', () async {
    var resolves = 0;
    var preloads = 0;
    final cache = WordAudioCache(
      resolveUrl: (path) async {
        resolves++;
        return 'https://audio.test/$path';
      },
      preloadUrl: (path, url) async => preloads++,
    );

    await cache.prepare('audio/v1/word/pronunciation.mp3');
    await cache.prepare('audio/v1/word/pronunciation.mp3');

    expect(resolves, 1);
    expect(preloads, 1);
  });

  test('empty Storage paths fail without a lookup', () async {
    final cache = WordAudioCache(
      resolveUrl: (_) async => throw UnimplementedError(),
      preloadUrl: (_, _) async {},
    );
    await expectLater(cache.prepare(''), throwsStateError);
  });
}
