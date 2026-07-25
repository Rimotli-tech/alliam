import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/training_mode.dart';

class TrainingProgressRepository {
  TrainingProgressRepository(this._firestore, this._auth);

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> recordSession({
    required TrainingMode mode,
    required int correct,
    required int attempted,
    required Set<String> incorrectWords,
  }) async {
    final user = _auth.currentUser;
    if (user == null || attempted == 0) return;
    final reference = _firestore.doc('accounts/${user.uid}/data/app-state');

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      if (!snapshot.exists) return;
      final document = snapshot.data() ?? const <String, dynamic>{};
      final value = _map(document['value']);
      final activeProfileId = value['activeProfileId']?.toString();
      final profiles = _list(value['profiles']);
      final reviewWords = {
        ..._strings(value['reviewWords']),
        ...incorrectWords,
      };
      final accuracy = (correct / attempted * 100).round();

      for (var index = 0; index < profiles.length; index++) {
        if (profiles[index]['id']?.toString() != activeProfileId) continue;
        final profile = Map<String, dynamic>.from(profiles[index]);
        final journey = _map(profile['journey']);
        final sessions = _integer(journey['sessions']) + 1;
        final previousAccuracy = _integer(journey['accuracy']);
        profile['journey'] = {
          ...journey,
          'sessions': sessions,
          'wordsPractised': _integer(journey['wordsPractised']) + attempted,
          'accuracy':
              (((previousAccuracy * (sessions - 1)) + accuracy) / sessions)
                  .round(),
          'reviewWords': reviewWords.toList(),
          'lastMode': mode.label,
        };
        profiles[index] = profile;
        break;
      }

      value['profiles'] = profiles;
      value['reviewWords'] = reviewWords.toList();
      value['trainingSessions'] = _integer(value['trainingSessions']) + 1;
      value['score'] = _integer(value['score']) + correct * 10;
      transaction.set(reference, {
        'value': value,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
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
