import 'package:flutter/services.dart';

enum AlphabetPlaybackSource { bundled, remote, unavailable }

class BundledAlphabetManifest {
  const BundledAlphabetManifest._();

  static const firestoreVersionId = 'alliam-alphabet-v2';
  static const sourceVersion = 'alliam-alphabet-manual-v1';
  static const bundleVersion = 'alliam-alphabet-bundle-v1';

  static const assets = <String, String>{
    'a': 'assets/audio/letters/a.mp3',
    'b': 'assets/audio/letters/b.mp3',
    'c': 'assets/audio/letters/c.mp3',
    'd': 'assets/audio/letters/d.mp3',
    'e': 'assets/audio/letters/e.mp3',
    'f': 'assets/audio/letters/f.mp3',
    'g': 'assets/audio/letters/g.mp3',
    'h': 'assets/audio/letters/h.mp3',
    'i': 'assets/audio/letters/i.mp3',
    'j': 'assets/audio/letters/j.mp3',
    'k': 'assets/audio/letters/k.mp3',
    'l': 'assets/audio/letters/l.mp3',
    'm': 'assets/audio/letters/m.mp3',
    'n': 'assets/audio/letters/n.mp3',
    'o': 'assets/audio/letters/o.mp3',
    'p': 'assets/audio/letters/p.mp3',
    'q': 'assets/audio/letters/q.mp3',
    'r': 'assets/audio/letters/r.mp3',
    's': 'assets/audio/letters/s.mp3',
    't': 'assets/audio/letters/t.mp3',
    'u': 'assets/audio/letters/u.mp3',
    'v': 'assets/audio/letters/v.mp3',
    'w': 'assets/audio/letters/w.mp3',
    'x': 'assets/audio/letters/x.mp3',
    'y': 'assets/audio/letters/y.mp3',
    'z': 'assets/audio/letters/z.mp3',
  };

  static Future<Set<String>> validate(AssetBundle bundle) async {
    final missing = <String>{};
    for (final entry in assets.entries) {
      try {
        final bytes = await bundle.load(entry.value);
        if (bytes.lengthInBytes == 0) missing.add(entry.key);
      } catch (_) {
        missing.add(entry.key);
      }
    }
    return missing;
  }

  static AlphabetPlaybackSource sourceFor({
    required String letter,
    required bool remoteVersionRequired,
    required Set<String> missingBundledLetters,
    required Set<String> remoteLetters,
  }) {
    if (!remoteVersionRequired &&
        assets.containsKey(letter) &&
        !missingBundledLetters.contains(letter)) {
      return AlphabetPlaybackSource.bundled;
    }
    if (remoteLetters.contains(letter)) {
      return AlphabetPlaybackSource.remote;
    }
    return AlphabetPlaybackSource.unavailable;
  }
}
