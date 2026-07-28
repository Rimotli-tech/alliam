import 'training_mode.dart';

class PathwayStage {
  const PathwayStage({
    required this.id,
    required this.label,
    required this.wordLevel,
    required this.sessionsRequired,
    required this.accuracyRequired,
  });

  final String id;
  final String label;
  final String wordLevel;
  final int sessionsRequired;
  final int accuracyRequired;
}

enum PathwayNodeKind { learn, practice, mastery, competition }

class PathwayNode {
  const PathwayNode({
    required this.id,
    required this.label,
    required this.description,
    required this.kind,
    required this.mode,
    required this.introducedRequired,
    required this.masteredRequired,
  });

  final String id;
  final String label;
  final String description;
  final PathwayNodeKind kind;
  final TrainingMode mode;
  final int introducedRequired;
  final int masteredRequired;
}

class PathwayUnit {
  const PathwayUnit({
    required this.id,
    required this.label,
    required this.description,
    required this.masteryTarget,
    required this.nodes,
  });

  final String id;
  final String label;
  final String description;
  final int masteryTarget;
  final List<PathwayNode> nodes;
}

class LearnerPathwayPosition {
  const LearnerPathwayPosition({
    required this.stageId,
    required this.unitId,
    required this.nodeId,
  });

  final String stageId;
  final String unitId;
  final String nodeId;
}

abstract final class LearnerPathway {
  static const stages = [
    PathwayStage(
      id: 'foundation',
      label: 'Foundation',
      wordLevel: 'Foundation',
      sessionsRequired: 5,
      accuracyRequired: 80,
    ),
    PathwayStage(
      id: 'builder',
      label: 'Builder',
      wordLevel: 'Builder',
      sessionsRequired: 8,
      accuracyRequired: 85,
    ),
    PathwayStage(
      id: 'champion',
      label: 'Champion',
      wordLevel: 'Championship',
      sessionsRequired: 10,
      accuracyRequired: 90,
    ),
  ];

  static PathwayStage stage(String? id) => stages.firstWhere(
    (stage) => stage.id == id?.toLowerCase(),
    orElse: () => stages.first,
  );

  static PathwayStage? next(String? id) {
    final current = stage(id);
    final index = stages.indexOf(current);
    return index >= stages.length - 1 ? null : stages[index + 1];
  }

  static final foundationUnits = [
    _foundationUnit(
      id: 'first-words',
      label: 'First words',
      description: 'Hear, recognise and confidently spell your first set.',
      introducedStart: 0,
      introducedTarget: 8,
      masteryStart: 0,
      masteryTarget: 8,
    ),
    _foundationUnit(
      id: 'letter-sounds',
      label: 'Letter sounds',
      description: 'Connect the sounds you hear with their written letters.',
      introducedStart: 8,
      introducedTarget: 20,
      masteryStart: 8,
      masteryTarget: 20,
    ),
    _foundationUnit(
      id: 'short-vowels',
      label: 'Short vowels',
      description: 'Hear and spell common short-vowel word patterns.',
      introducedStart: 20,
      introducedTarget: 40,
      masteryStart: 20,
      masteryTarget: 40,
    ),
    _foundationUnit(
      id: 'common-words',
      label: 'Common words',
      description: 'Build automatic recall for everyday vocabulary.',
      introducedStart: 40,
      introducedTarget: 70,
      masteryStart: 40,
      masteryTarget: 70,
    ),
    _foundationUnit(
      id: 'daily-vocabulary',
      label: 'Daily vocabulary',
      description: 'Grow a useful bank of words for reading and writing.',
      introducedStart: 70,
      introducedTarget: 100,
      masteryStart: 70,
      masteryTarget: 100,
    ),
    _foundationUnit(
      id: 'foundation-review',
      label: 'Foundation review',
      description: 'Secure earlier vocabulary before the next stage.',
      introducedStart: 100,
      introducedTarget: 120,
      masteryStart: 100,
      masteryTarget: 120,
    ),
  ];

  static PathwayUnit get currentFoundationUnit => foundationUnits.first;

  static PathwayUnit unit(String? id) => foundationUnits.firstWhere(
    (unit) => unit.id == id,
    orElse: () => foundationUnits.first,
  );

  static LearnerPathwayPosition position({
    required int introduced,
    required int mastered,
  }) {
    for (final unit in foundationUnits) {
      final nodeIndex = currentNodeIndex(
        unit: unit,
        introduced: introduced,
        mastered: mastered,
      );
      final node = unit.nodes[nodeIndex];
      final nodeComplete =
          introduced >= node.introducedRequired &&
          mastered >= node.masteredRequired;
      if (!nodeComplete || unit == foundationUnits.last) {
        return LearnerPathwayPosition(
          stageId: 'foundation',
          unitId: unit.id,
          nodeId: node.id,
        );
      }
    }
    final finalUnit = foundationUnits.last;
    return LearnerPathwayPosition(
      stageId: 'foundation',
      unitId: finalUnit.id,
      nodeId: finalUnit.nodes.last.id,
    );
  }

  static int currentNodeIndex({
    required PathwayUnit unit,
    required int introduced,
    required int mastered,
  }) {
    for (var index = 0; index < unit.nodes.length; index++) {
      final node = unit.nodes[index];
      if (introduced < node.introducedRequired ||
          mastered < node.masteredRequired) {
        return index;
      }
    }
    return unit.nodes.length - 1;
  }

  static PathwayUnit _foundationUnit({
    required String id,
    required String label,
    required String description,
    required int introducedStart,
    required int introducedTarget,
    required int masteryStart,
    required int masteryTarget,
  }) {
    final introducedStep = introducedStart + 5;
    final firstMasteryStep =
        masteryStart + ((masteryTarget - masteryStart) / 3).ceil();
    final secondMasteryStep =
        masteryStart + ((masteryTarget - masteryStart) * 2 / 3).ceil();
    return PathwayUnit(
      id: id,
      label: label,
      description: description,
      masteryTarget: masteryTarget,
      nodes: [
        PathwayNode(
          id: '$id-introduction',
          label: 'Meet the words',
          description: 'Listen and build each spelling.',
          kind: PathwayNodeKind.learn,
          mode: TrainingMode.hearAndSpell,
          introducedRequired: introducedStep.clamp(
            introducedStart,
            introducedTarget,
          ),
          masteredRequired: masteryStart,
        ),
        PathwayNode(
          id: '$id-flash',
          label: 'See and recall',
          description: 'Strengthen the exact words you just met.',
          kind: PathwayNodeKind.learn,
          mode: TrainingMode.wordFlash,
          introducedRequired: introducedStep.clamp(
            introducedStart,
            introducedTarget,
          ),
          masteredRequired: firstMasteryStep,
        ),
        PathwayNode(
          id: '$id-review',
          label: 'Mixed review',
          description: 'Bring weaker words back before they fade.',
          kind: PathwayNodeKind.practice,
          mode: TrainingMode.missedWords,
          introducedRequired: introducedTarget,
          masteredRequired: secondMasteryStep,
        ),
        PathwayNode(
          id: '$id-checkpoint',
          label: '$label checkpoint',
          description: 'Show that these words are secure.',
          kind: PathwayNodeKind.mastery,
          mode: TrainingMode.mockBee,
          introducedRequired: introducedTarget,
          masteredRequired: masteryTarget,
        ),
      ],
    );
  }
}

class TrainingSessionOutcome {
  const TrainingSessionOutcome({
    required this.scoreEarned,
    required this.totalScore,
    required this.stage,
    required this.promoted,
    required this.stageSessions,
    required this.stageAccuracy,
  });

  final int scoreEarned;
  final int totalScore;
  final PathwayStage stage;
  final bool promoted;
  final int stageSessions;
  final int stageAccuracy;

  double get progress => stage.sessionsRequired == 0
      ? 1
      : (stageSessions / stage.sessionsRequired).clamp(0, 1);
}
