import 'package:alliam_app/features/train/data/session_audio_manifest.dart';
import 'package:alliam_app/features/train/domain/spelling_word.dart';
import 'package:flutter_test/flutter_test.dart';

SpellingWord word(String value) => SpellingWord(
  word: value,
  level: 'Foundation',
  definition: '',
  sentence: '',
  origin: '',
  partOfSpeech: '',
  audio: {
    'pronunciation': AudioAsset(
      storagePath: 'audio/version/$value/pronunciation.mp3',
    ),
  },
  approved: true,
  approvalCollection: 'grade-1-2-200-v1',
);

void main() {
  test('compact session manifest preserves the selected word order', () {
    final manifest = SessionAudioManifest.fromWords([
      word('necessary'),
      word('treasure'),
      word('whisper'),
      word('calendar'),
      word('journey'),
    ]);

    expect(manifest.entries.map((entry) => entry.wordId), [
      'necessary',
      'treasure',
      'whisper',
      'calendar',
      'journey',
    ]);
    expect(manifest.first?.wordId, 'necessary');
    expect(manifest.nextTwo.map((entry) => entry.wordId), [
      'treasure',
      'whisper',
    ]);
    expect(manifest.background.map((entry) => entry.wordId), [
      'calendar',
      'journey',
    ]);
  });

  test('manifest records a missing pronunciation without inventing a path', () {
    final missing = SpellingWord(
      word: 'missing',
      level: 'Foundation',
      definition: '',
      sentence: '',
      origin: '',
      partOfSpeech: '',
      audio: const {},
      approved: true,
      approvalCollection: 'grade-1-2-200-v1',
    );
    expect(
      SessionAudioManifest.fromWords([
        missing,
      ]).entries.single.pronunciationPath,
      isEmpty,
    );
  });
}
