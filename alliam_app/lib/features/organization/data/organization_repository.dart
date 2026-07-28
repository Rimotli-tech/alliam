import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrganizationAccess {
  const OrganizationAccess({
    required this.organizationId,
    required this.role,
    required this.permissions,
  });

  final String organizationId;
  final String role;
  final Map<String, bool> permissions;

  bool can(String permission) => permissions[permission] == true;
}

class OrganizationRepository {
  const OrganizationRepository(this.firestore);

  final FirebaseFirestore firestore;

  Future<OrganizationAccess?> loadAccess({
    required User user,
    required String organizationId,
  }) async {
    final member = await firestore
        .doc('organizations/$organizationId/members/${user.uid}')
        .get();
    final data = member.data();
    if (data == null || data['status'] != 'active') return null;
    final rawPermissions = data['permissions'];
    final permissions = <String, bool>{};
    if (rawPermissions is Map) {
      for (final entry in rawPermissions.entries) {
        permissions[entry.key.toString()] = entry.value == true;
      }
    }
    return OrganizationAccess(
      organizationId: organizationId,
      role: data['role']?.toString() ?? 'member',
      permissions: permissions,
    );
  }

  Future<void> ensureOwnerFoundation({
    required User user,
    required String organizationId,
    required String name,
    required String country,
  }) async {
    final organization = firestore.doc('organizations/$organizationId');
    final member = organization.collection('members').doc(user.uid);
    // Do not read first: a partially created organization has no record yet,
    // and security rules intentionally deny reads of a missing private record.
    // These merge writes make setup safe to resume after closing the browser.
    await organization.set({
      'id': organizationId,
      'name': name,
      'country': country,
      'ownerUid': user.uid,
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await member.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName ?? name,
      'role': 'owner',
      'permissions': {
        'manageLearners': true,
        'manageTeams': true,
        'manageCompetitions': true,
        'manageMembers': true,
        'manageOrganization': true,
      },
      'status': 'active',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> syncAccountLearners({
    required String organizationId,
    required String accountId,
    required List<Map<String, dynamic>> learners,
  }) async {
    if (learners.isEmpty) return;
    final batch = firestore.batch();
    for (final learner in learners) {
      final learnerId = learner['id']?.toString();
      if (learnerId == null || learnerId.isEmpty) continue;
      batch.set(
        firestore.doc('organizations/$organizationId/learners/$learnerId'),
        {
          ...learner,
          'sourceAccountId': accountId,
          'sourceLearnerId': learnerId,
          'status': 'active',
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }
}
