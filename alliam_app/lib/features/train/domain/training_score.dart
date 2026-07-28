class TrainingScore {
  const TrainingScore._();

  static int wordPoints({
    required bool correct,
    required Duration responseTime,
    bool usedFlash = false,
    int repeatUses = 0,
  }) {
    if (!correct) return 0;

    final milliseconds = responseTime.inMilliseconds;
    final speedBonus = switch (milliseconds) {
      <= 3000 => 50,
      >= 15000 => 0,
      _ => (50 * (15000 - milliseconds) / 12000).round(),
    };
    final repeatPenalty = (repeatUses * 5).clamp(0, 20);
    final helperPenalty = (usedFlash ? 25 : 0) + repeatPenalty;

    return (100 + speedBonus - helperPenalty).clamp(50, 150);
  }
}
