import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/training_mode.dart';
import '../domain/learner_pathway.dart';

class TrainingProgressRepository {
  TrainingProgressRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<TrainingSessionOutcome?> recordSession({
    required TrainingMode mode,
    required int correct,
    required int attempted,
    required Set<String> incorrectWords,
  }) async {
    final user = _auth.currentUser;
    if (user == null || attempted == 0) return null;
    final reference = _firestore.doc('accounts/${user.uid}/data/app-state');
    String? activeLearnerId;
    Map<String, dynamic>? normalizedJourney;
    TrainingSessionOutcome? outcome;

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) return;
      final document = snapshot.data() ?? const <String, dynamic>{};
      final value = _map(document['value']);
      final activeProfileId = value['activeProfileId']?.toString();
      activeLearnerId = activeProfileId;
      final profiles = _list(value['profiles']);
      final reviewWords = {
        ..._strings(value['reviewWords']),
        ...incorrectWords,
      };
      final accuracy = (correct / attempted * 100).round();
      final scoreEarned = correct * 100;

      for (var index = 0; index < profiles.length; index++) {
        if (profiles[index]['id']?.toString() != activeProfileId) continue;
        final profile = Map<String, dynamic>.from(profiles[index]);
        final journey = _map(profile['journey']);
        final sessions = _integer(journey['sessions']) + 1;
        final previousAccuracy = _integer(journey['accuracy']);
        final currentStage = LearnerPathway.stage(journey['stage']?.toString());
        var stageSessions = _integer(journey['stageSessions']) + 1;
        final previousStageAccuracy = _integer(journey['stageAccuracy']);
        var stageAccuracy =
            (((previousStageAccuracy * (stageSessions - 1)) + accuracy) /
                    stageSessions)
                .round();
        final nextStage = LearnerPathway.next(currentStage.id);
        final promoted =
            nextStage != null &&
            stageSessions >= currentStage.sessionsRequired &&
            stageAccuracy >= currentStage.accuracyRequired;
        final resolvedStage = promoted ? nextStage : currentStage;
        if (promoted) {
          stageSessions = 0;
          stageAccuracy = 0;
        }
        final totalScore = _integer(journey['totalScore']) + scoreEarned;
        profile['journey'] = {
          ...journey,
          'sessions': sessions,
          'wordsPractised': _integer(journey['wordsPractised']) + attempted,
          'accuracy':
              (((previousAccuracy * (sessions - 1)) + accuracy) / sessions)
                  .round(),
          'reviewWords': reviewWords.toList(),
          'lastMode': mode.label,
          'grade': profile['grade']?.toString() ?? 'Grade 1',
          'stage': resolvedStage.id,
          'stageLabel': resolvedStage.label,
          'stageSessions': stageSessions,
          'stageAccuracy': stageAccuracy,
          'totalScore': totalScore,
          'lastCompletedAt': DateTime.now().toUtc().toIso8601String(),
        };
        normalizedJourney = Map<String, dynamic>.from(
          profile['journey'] as Map,
        );
        profiles[index] = profile;
        outcome = TrainingSessionOutcome(
          scoreEarned: scoreEarned,
          totalScore: totalScore,
          stage: resolvedStage,
          promoted: promoted,
          stageSessions: stageSessions,
          stageAccuracy: stageAccuracy,
        );
        break;
      }

      value['profiles'] = profiles;
      value['reviewWords'] = reviewWords.toList();
      value['trainingSessions'] = _integer(value['trainingSessions']) + 1;
      value['score'] = _integer(value['score']) + scoreEarned;
      transaction.set(reference, {
        'value': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });

    final learnerId = activeLearnerId;
    if (learnerId == null) return outcome;
    final session = _firestore
        .collection('accounts/${user.uid}/learners/$learnerId/sessions')
        .doc();
    final batch = _firestore.batch();
    batch.set(session, {
      'mode': mode.slug,
      'correct': correct,
      'attempted': attempted,
      'incorrectWords': incorrectWords.toList(),
      'accuracy': (correct / attempted * 100).round(),
      'scoreEarned': correct * 100,
      'stage': outcome?.stage.id ?? 'foundation',
      'promoted': outcome?.promoted ?? false,
      'completedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _firestore.doc('accounts/${user.uid}/learners/$learnerId'),
      {
        'journey': normalizedJourney ?? const <String, dynamic>{},
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
    return outcome;
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};

  static List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : [];

  static List<String> _strings(Object? value) =>
      value is List ? value.map((item) => item.toString()).toList() : [];

  static int _integer(Object? value) =>
      value is num ? value.toInt() : int.tryParse('$value') ?? 0;
}
