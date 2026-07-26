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
