import 'package:alliam_app/features/train/domain/spelling_word.dart';
import 'package:alliam_app/features/train/domain/learner_pathway.dart';
import 'package:alliam_app/features/train/domain/training_mode.dart';
import 'package:alliam_app/features/train/data/learner_word_progress_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('word mastery requires repeated accurate recall across sessions', () {
    expect(
      WordMasteryRules.isMastered(
        correct: true,
        flashCorrect: 3,
        flashSessions: 2,
        flashAccuracy: 100,
        consecutiveFlashCorrect: 2,
      ),
      isTrue,
    );
    expect(
      WordMasteryRules.isMastered(
        correct: true,
        flashCorrect: 3,
        flashSessions: 1,
        flashAccuracy: 100,
        consecutiveFlashCorrect: 3,
      ),
      isFalse,
    );
  });
  test('learning sessions alternate Hear & Spell and Word Flash', () {
    expect(
      TrainingMode.hearAndSpell.nextLearningSession,
      TrainingMode.wordFlash,
    );
    expect(
      TrainingMode.wordFlash.nextLearningSession,
      TrainingMode.hearAndSpell,
    );
    expect(
      TrainingMode.timedDrill.nextLearningSession,
      TrainingMode.timedDrill,
    );
  });

  test('Foundation path advances from learning to mastery nodes', () {
    final unit = LearnerPathway.currentFoundationUnit;

    expect(unit.nodes.map((node) => node.kind), [
      PathwayNodeKind.learn,
      PathwayNodeKind.learn,
      PathwayNodeKind.practice,
      PathwayNodeKind.mastery,
    ]);
    expect(
      LearnerPathway.currentNodeIndex(unit: unit, introduced: 0, mastered: 0),
      0,
    );
    expect(
      LearnerPathway.currentNodeIndex(unit: unit, introduced: 5, mastered: 0),
      1,
    );
    expect(
      LearnerPathway.currentNodeIndex(unit: unit, introduced: 5, mastered: 3),
      2,
    );
    expect(
      LearnerPathway.currentNodeIndex(unit: unit, introduced: 8, mastered: 8),
      unit.nodes.length - 1,
    );
  });

  test('Foundation curriculum advances into the next persisted unit', () {
    expect(
      LearnerPathway.foundationUnits.map((unit) => unit.id),
      containsAllInOrder([
        'first-words',
        'letter-sounds',
        'short-vowels',
        'common-words',
        'daily-vocabulary',
        'foundation-review',
      ]),
    );

    final firstPosition = LearnerPathway.position(introduced: 0, mastered: 0);
    expect(firstPosition.unitId, 'first-words');
    expect(firstPosition.nodeId, 'first-words-introduction');

    final secondUnitPosition = LearnerPathway.position(
      introduced: 8,
      mastered: 8,
    );
    expect(secondUnitPosition.unitId, 'letter-sounds');
    expect(secondUnitPosition.nodeId, 'letter-sounds-introduction');
  });
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
