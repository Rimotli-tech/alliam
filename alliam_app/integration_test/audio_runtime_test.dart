import 'package:alliam_app/features/train/data/bundled_alphabet_manifest.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:just_audio/just_audio.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Android decodes every bundled letter with one dedicated player',
    (_) async {
      final player = AudioPlayer();
      try {
        for (final entry in BundledAlphabetManifest.assets.entries) {
          final duration = await player.setAsset(entry.value);
          expect(
            duration,
            isNotNull,
            reason: '${entry.key.toUpperCase()} could not be decoded',
          );
          expect(duration, greaterThan(Duration.zero));
          await player.stop();
        }

        for (final letter in const ['a', 'e', 'z']) {
          await player.setAsset(BundledAlphabetManifest.assets[letter]!);
          await player.seek(Duration.zero);
          await player.play();
        }
      } finally {
        await player.dispose();
      }
    },
  );
}
