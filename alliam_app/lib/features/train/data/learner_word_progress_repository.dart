import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/spelling_word.dart';
import '../domain/training_mode.dart';

class LearnerWordProgress {
  const LearnerWordProgress({
    required this.word,
    required this.state,
    required this.lastAttemptedAt,
  });

  final String word;
  final String state;
  final DateTime? lastAttemptedAt;

  factory LearnerWordProgress.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return LearnerWordProgress(
      word: data['word']?.toString() ?? document.id,
      state: data['state']?.toString() ?? 'learning',
      lastAttemptedAt: (data['lastAttemptedAt'] as Timestamp?)?.toDate(),
    );
  }
}

class LearnerMasterySummary {
  const LearnerMasterySummary({
    required this.introduced,
    required this.learning,
    required this.familiar,
    required this.practising,
    required this.mastered,
  });

  static const empty = LearnerMasterySummary(
    introduced: 0,
    learning: 0,
    familiar: 0,
    practising: 0,
    mastered: 0,
  );

  final int introduced;
  final int learning;
  final int familiar;
  final int practising;
  final int mastered;

  int get needsPractice => learning + familiar + practising;
}

class WordMasteryChange {
  const WordMasteryChange({
    required this.previousState,
    required this.currentState,
  });

  final String previousState;
  final String currentState;

  bool get becameMastered =>
      previousState != 'mastered' && currentState == 'mastered';
}

class LearnerWordProgressRepository {
  const LearnerWordProgressRepository(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _words(
    String accountId,
    String learnerId,
  ) => firestore.collection('accounts/$accountId/learners/$learnerId/words');

  Future<LearnerMasterySummary> loadSummary({
    required String accountId,
    required String learnerId,
  }) async {
    final snapshot = await _words(accountId, learnerId).get();
    var learning = 0;
    var familiar = 0;
    var practising = 0;
    var mastered = 0;
    for (final document in snapshot.docs) {
      switch (_normalizedState(document.data()['state']?.toString())) {
        case 'mastered':
          mastered++;
        case 'practising':
          practising++;
        case 'familiar':
          familiar++;
        default:
          learning++;
      }
    }
    return LearnerMasterySummary(
      introduced: snapshot.docs.length,
      learning: learning,
      familiar: familiar,
      practising: practising,
      mastered: mastered,
    );
  }

  Future<List<String>> loadReviewQueue({
    required String accountId,
    required String learnerId,
    required int count,
  }) async {
    final snapshot = await _words(accountId, learnerId).get();
    final progress =
        snapshot.docs
            .map(LearnerWordProgress.fromDocument)
            .where((item) => item.state != 'mastered')
            .toList()
          ..sort((a, b) {
            final aPriority = _priority(_normalizedState(a.state));
            final bPriority = _priority(_normalizedState(b.state));
            if (aPriority != bPriority) return aPriority.compareTo(bPriority);
            final aTime =
                a.lastAttemptedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.lastAttemptedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return aTime.compareTo(bTime);
          });
    return progress.take(count).map((item) => item.word).toList();
  }

  Future<WordMasteryChange?> recordAttempt({
    required String accountId,
    required String learnerId,
    required SpellingWord word,
    required TrainingMode mode,
    required bool correct,
    required String sessionId,
  }) async {
    final reference = _words(accountId, learnerId).doc(word.word.toLowerCase());
    WordMasteryChange? change;
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final data = snapshot.data() ?? const <String, dynamic>{};
      final totalAttempts = _integer(data['totalAttempts']) + 1;
      final totalCorrect = _integer(data['totalCorrect']) + (correct ? 1 : 0);
      final previousState = _normalizedState(data['state']?.toString());
      var state = previousState;
      var flashAttempts = _integer(data['flashAttempts']);
      var flashCorrect = _integer(data['flashCorrect']);
      var flashSessions = _integer(data['flashSessions']);
      var consecutiveFlashCorrect = _integer(data['consecutiveFlashCorrect']);
      final lastPracticeSessionId =
          data['lastPracticeSessionId']?.toString() ??
          data['lastFlashSessionId']?.toString();

      if (mode == TrainingMode.hearAndSpell) {
        state = correct ? 'familiar' : 'learning';
      } else {
        flashAttempts++;
        if (correct) {
          flashCorrect++;
          consecutiveFlashCorrect++;
          if (lastPracticeSessionId != sessionId) flashSessions++;
        } else {
          consecutiveFlashCorrect = 0;
          state = 'learning';
        }
        final flashAccuracy = flashAttempts == 0
            ? 0
            : (flashCorrect / flashAttempts * 100).round();
        final mastered = WordMasteryRules.isMastered(
          correct: correct,
          flashCorrect: flashCorrect,
          flashSessions: flashSessions,
          flashAccuracy: flashAccuracy,
          consecutiveFlashCorrect: consecutiveFlashCorrect,
        );
        if (mastered) {
          state = 'mastered';
        } else if (correct) {
          state = 'practising';
        }
      }
      change = WordMasteryChange(
        previousState: previousState,
        currentState: state,
      );

      transaction.set(reference, {
        'word': word.word,
        'level': word.level,
        'state': state,
        'totalAttempts': totalAttempts,
        'totalCorrect': totalCorrect,
        'hearAndSpellAttempts':
            _integer(data['hearAndSpellAttempts']) +
            (mode == TrainingMode.hearAndSpell ? 1 : 0),
        'hearAndSpellCorrect':
            _integer(data['hearAndSpellCorrect']) +
            (mode == TrainingMode.hearAndSpell && correct ? 1 : 0),
        'flashAttempts': flashAttempts,
        'flashCorrect': flashCorrect,
        'flashSessions': flashSessions,
        'consecutiveFlashCorrect': consecutiveFlashCorrect,
        if (mode != TrainingMode.hearAndSpell) ...{
          'lastPracticeSessionId': sessionId,
          if (mode == TrainingMode.wordFlash) 'lastFlashSessionId': sessionId,
        },
        'lastResultCorrect': correct,
        'lastMode': mode.slug,
        'lastAttemptedAt': FieldValue.serverTimestamp(),
        'firstIntroducedAt':
            data['firstIntroducedAt'] ?? FieldValue.serverTimestamp(),
        if (state == 'mastered' && previousState != 'mastered')
          'masteredAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
    return change;
  }

  static int _priority(String state) => switch (state) {
    'learning' => 0,
    'familiar' => 1,
    'practising' => 2,
    _ => 3,
  };

  static String _normalizedState(String? state) => switch (state) {
    'mastered' => 'mastered',
    'practising' || 'reviewDue' => 'practising',
    'familiar' => 'familiar',
    'learning' || 'relearning' || 'new' || null => 'learning',
    _ => 'learning',
  };

  static int _integer(Object? value) =>
      value is num ? value.round() : int.tryParse('$value') ?? 0;
}

class WordMasteryRules {
  const WordMasteryRules._();

  static bool isMastered({
    required bool correct,
    required int flashCorrect,
    required int flashSessions,
    required int flashAccuracy,
    required int consecutiveFlashCorrect,
  }) =>
      correct &&
      flashCorrect >= 3 &&
      flashSessions >= 2 &&
      flashAccuracy >= 80 &&
      consecutiveFlashCorrect >= 2;
}
