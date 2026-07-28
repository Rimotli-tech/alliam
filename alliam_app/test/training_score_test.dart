import 'package:alliam_app/features/train/domain/training_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrainingScore', () {
    test('awards the maximum for a fast correct answer', () {
      expect(
        TrainingScore.wordPoints(
          correct: true,
          responseTime: const Duration(seconds: 3),
        ),
        150,
      );
    });

    test('reduces the speed bonus as response time increases', () {
      expect(
        TrainingScore.wordPoints(
          correct: true,
          responseTime: const Duration(seconds: 9),
        ),
        125,
      );
      expect(
        TrainingScore.wordPoints(
          correct: true,
          responseTime: const Duration(seconds: 15),
        ),
        100,
      );
    });

    test('applies helper penalties', () {
      expect(
        TrainingScore.wordPoints(
          correct: true,
          responseTime: const Duration(seconds: 2),
          usedFlash: true,
          repeatUses: 2,
        ),
        115,
      );
    });

    test('awards no points for an incorrect answer', () {
      expect(
        TrainingScore.wordPoints(
          correct: false,
          responseTime: const Duration(seconds: 1),
        ),
        0,
      );
    });
  });
}
