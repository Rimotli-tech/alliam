enum TrainingMode {
  hearAndSpell,
  wordFlash,
  timedDrill,
  listenAndSpell,
  missingLetters,
  patternDrill,
  similarWords,
  buildTheWord,
  mockBee,
  survivalRun,
  streakChallenge,
  recallLadder,
  dailyChallenge,
  themeChallenge,
  reverseSpell,
  missedWords,
}

extension TrainingModeDetails on TrainingMode {
  String get slug => switch (this) {
    TrainingMode.hearAndSpell => 'hear-and-spell',
    TrainingMode.wordFlash => 'word-flash',
    TrainingMode.timedDrill => 'timed-drill',
    TrainingMode.listenAndSpell => 'listen-and-spell',
    TrainingMode.missingLetters => 'missing-letters',
    TrainingMode.patternDrill => 'pattern-drill',
    TrainingMode.similarWords => 'similar-words',
    TrainingMode.buildTheWord => 'build-the-word',
    TrainingMode.mockBee => 'mock-bee',
    TrainingMode.survivalRun => 'survival-run',
    TrainingMode.streakChallenge => 'streak-challenge',
    TrainingMode.recallLadder => 'recall-ladder',
    TrainingMode.dailyChallenge => 'daily-challenge',
    TrainingMode.themeChallenge => 'theme-challenge',
    TrainingMode.reverseSpell => 'reverse-spell',
    TrainingMode.missedWords => 'missed-words',
  };

  String get label => switch (this) {
    TrainingMode.hearAndSpell => 'Hear & Spell',
    TrainingMode.wordFlash => 'Word Flash',
    TrainingMode.timedDrill => 'Timed Drill',
    TrainingMode.listenAndSpell => 'Listen & Spell',
    TrainingMode.missingLetters => 'Missing Letters',
    TrainingMode.patternDrill => 'Pattern Drill',
    TrainingMode.similarWords => 'Similar Words',
    TrainingMode.buildTheWord => 'Build the Word',
    TrainingMode.mockBee => 'Mock Bee',
    TrainingMode.survivalRun => 'Survival Run',
    TrainingMode.streakChallenge => 'Streak Challenge',
    TrainingMode.recallLadder => 'Recall Ladder',
    TrainingMode.dailyChallenge => 'Daily Challenge',
    TrainingMode.themeChallenge => 'Theme Challenge',
    TrainingMode.reverseSpell => 'Reverse Spell',
    TrainingMode.missedWords => 'Missed Words',
  };

  String get subtitle => switch (this) {
    TrainingMode.hearAndSpell => 'Learn the word, then spell',
    TrainingMode.wordFlash => 'See briefly, then recall',
    TrainingMode.timedDrill => 'Build accuracy against the clock',
    TrainingMode.listenAndSpell => 'Hear only, then recall',
    TrainingMode.missingLetters => 'Complete the hidden letters',
    TrainingMode.patternDrill => 'Master recurring structures',
    TrainingMode.similarWords => 'Separate confusing spellings',
    TrainingMode.buildTheWord => 'Construct words from pieces',
    TrainingMode.mockBee => 'Practise competition rules',
    TrainingMode.survivalRun => 'Keep spelling while lives remain',
    TrainingMode.streakChallenge => 'Protect your longest streak',
    TrainingMode.recallLadder => 'Advance through mastery stages',
    TrainingMode.dailyChallenge => 'One shared set every day',
    TrainingMode.themeChallenge => 'Practise a focused collection',
    TrainingMode.reverseSpell => 'Hear letters, identify the word',
    TrainingMode.missedWords => 'Return to words you missed',
  };

  bool get isImplemented => true;

  TrainingMode get nextLearningSession => switch (this) {
    TrainingMode.hearAndSpell => TrainingMode.wordFlash,
    TrainingMode.wordFlash => TrainingMode.hearAndSpell,
    _ => this,
  };

  bool get isTimed => {
    TrainingMode.timedDrill,
    TrainingMode.mockBee,
    TrainingMode.survivalRun,
    TrainingMode.recallLadder,
  }.contains(this);

  static TrainingMode fromSlug(String slug) {
    return TrainingMode.values.firstWhere(
      (mode) => mode.slug == slug,
      orElse: () => TrainingMode.hearAndSpell,
    );
  }
}
