import 'package:alliam_app/features/settings/data/settings_repository.dart';
import 'package:alliam_app/features/train/domain/learner_pathway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('learner pathway', () {
    test('uses the ordered Grade 1 foundation ladder', () {
      expect(LearnerPathway.stages.map((stage) => stage.label), [
        'Foundation',
        'Builder',
        'Champion',
      ]);
      expect(LearnerPathway.next('foundation')?.id, 'builder');
      expect(LearnerPathway.next('builder')?.id, 'champion');
      expect(LearnerPathway.next('champion'), isNull);
    });

    test('outcome progress is bounded by the stage requirement', () {
      final outcome = TrainingSessionOutcome(
        scoreEarned: 500,
        totalScore: 1200,
        stage: LearnerPathway.stage('foundation'),
        promoted: false,
        stageSessions: 12,
        stageAccuracy: 90,
      );
      expect(outcome.progress, 1);
    });
  });

  group('audio setting migration', () {
    test('legacy sound off disables all three audio channels', () {
      final settings = AlliamSettings.fromMap({'sound': false});
      expect(settings.music, isFalse);
      expect(settings.voice, isFalse);
      expect(settings.effects, isFalse);
    });

    test('new channel settings retain independent values', () {
      final settings = AlliamSettings.fromMap({
        'sound': true,
        'music': false,
        'voice': true,
        'effects': false,
        'voiceVolume': 0.45,
      });
      expect(settings.music, isFalse);
      expect(settings.voice, isTrue);
      expect(settings.effects, isFalse);
      expect(settings.voiceVolume, 0.45);
    });
  });

  group('pathway setting migration', () {
    test('automatic remains default while manual level is retained', () {
      final defaults = AlliamSettings.fromMap(const {});
      expect(defaults.automaticPathway, isTrue);

      final manual = AlliamSettings.fromMap(const {
        'automaticPathway': false,
        'level': 'Builder',
      });
      expect(manual.automaticPathway, isFalse);
      expect(manual.level, 'Builder');
    });
  });
}
