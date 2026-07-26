import 'dart:io';

import 'package:alliam_app/features/train/data/bundled_alphabet_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bundled alphabet maps exactly A through Z to non-empty MP3 files', () {
    expect(
      BundledAlphabetManifest.assets.keys.join(),
      'abcdefghijklmnopqrstuvwxyz',
    );
    expect(BundledAlphabetManifest.assets, hasLength(26));

    for (final path in BundledAlphabetManifest.assets.values) {
      final file = File(path);
      expect(file.existsSync(), isTrue, reason: 'Missing $path');
      expect(file.lengthSync(), greaterThan(0), reason: 'Empty $path');
      final header = file.readAsBytesSync().take(3).toList();
      final hasId3 =
          header.length == 3 &&
          header[0] == 0x49 &&
          header[1] == 0x44 &&
          header[2] == 0x33;
      final hasFrameSync =
          header.length >= 2 && header[0] == 0xff && (header[1] & 0xe0) == 0xe0;
      expect(
        hasId3 || hasFrameSync,
        isTrue,
        reason: '$path does not have an MP3 header',
      );
    }
  });

  test('bundled source wins when its source version remains current', () {
    expect(
      BundledAlphabetManifest.sourceFor(
        letter: 'a',
        remoteVersionRequired: false,
        missingBundledLetters: const {},
        remoteLetters: const {'a'},
      ),
      AlphabetPlaybackSource.bundled,
    );
  });

  test('remote source is used for obsolete or missing bundled audio', () {
    expect(
      BundledAlphabetManifest.sourceFor(
        letter: 'a',
        remoteVersionRequired: true,
        missingBundledLetters: const {},
        remoteLetters: const {'a'},
      ),
      AlphabetPlaybackSource.remote,
    );
    expect(
      BundledAlphabetManifest.sourceFor(
        letter: 'b',
        remoteVersionRequired: false,
        missingBundledLetters: const {'b'},
        remoteLetters: const {'b'},
      ),
      AlphabetPlaybackSource.remote,
    );
  });

  test('missing local and remote recordings fail closed', () {
    expect(
      BundledAlphabetManifest.sourceFor(
        letter: 'z',
        remoteVersionRequired: false,
        missingBundledLetters: const {'z'},
        remoteLetters: const {},
      ),
      AlphabetPlaybackSource.unavailable,
    );
  });
}
