import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/learner_pathway.dart';

class LearnerPathwayProgressRepository {
  const LearnerPathwayProgressRepository(this.firestore);

  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> _position(
    String accountId,
    String learnerId,
  ) => firestore.doc('accounts/$accountId/learners/$learnerId/pathway/current');

  Future<LearnerPathwayPosition> syncPosition({
    required String accountId,
    required String learnerId,
    required int introduced,
    required int mastered,
  }) async {
    final resolved = LearnerPathway.position(
      introduced: introduced,
      mastered: mastered,
    );
    final reference = _position(accountId, learnerId);
    try {
      final snapshot = await reference.get();
      final data = snapshot.data() ?? const <String, dynamic>{};
      if (data['stageId']?.toString() != resolved.stageId ||
          data['unitId']?.toString() != resolved.unitId ||
          data['nodeId']?.toString() != resolved.nodeId ||
          (data['schemaVersion'] as num?)?.round() != 1) {
        await reference.set({
          'schemaVersion': 1,
          'stageId': resolved.stageId,
          'unitId': resolved.unitId,
          'nodeId': resolved.nodeId,
          'introducedSnapshot': introduced,
          'masteredSnapshot': mastered,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } on FirebaseException {
      // The derived position still keeps the path usable while offline.
    }
    return resolved;
  }
}
