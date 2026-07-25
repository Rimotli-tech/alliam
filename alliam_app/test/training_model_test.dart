import 'package:alliam_app/features/train/domain/spelling_word.dart';
import 'package:alliam_app/features/train/domain/training_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Firestore words retain metadata and Storage paths', () {
    final word = SpellingWord.fromFirestore('journey', {
      'level': 'Foundation',
      'definition': 'An act of travelling.',
      'sentence': 'The journey took three days.',
      'origin': 'Old French',
      'part': 'noun',
      'approved': true,
      'approvalCollection': 'core-60-v1',
      'audio': {
        'pronunciation': {'storagePath': 'audio/v1/journey/pronunciation.mp3'},
      },
    });

    expect(word.word, 'journey');
    expect(word.level, 'Foundation');
    expect(word.approved, isTrue);
    expect(word.approvalCollection, 'core-60-v1');
    expect(
      word.pronunciation?.storagePath,
      'audio/v1/journey/pronunciation.mp3',
    );
  });

  test('Implemented training slugs map to the correct modes', () {
    for (final mode in TrainingMode.values) {
      expect(TrainingModeDetails.fromSlug(mode.slug), mode);
      expect(mode.isImplemented, isTrue);
    }
  });
}
