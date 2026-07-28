import 'package:cloud_firestore/cloud_firestore.dart';

class OrganizationMember {
  const OrganizationMember({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.permissions,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String status;
  final Map<String, bool> permissions;

  factory OrganizationMember.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return OrganizationMember(
      id: document.id,
      name: data['displayName']?.toString() ?? '',
      email: data['email']?.toString() ?? '',
      role: data['role']?.toString() ?? 'staff',
      status: data['status']?.toString() ?? 'active',
      permissions: _permissions(data['permissions']),
    );
  }
}

class OrganizationLearner {
  const OrganizationLearner({
    required this.id,
    required this.name,
    required this.grade,
    required this.status,
    required this.journey,
  });

  final String id;
  final String name;
  final String grade;
  final String status;
  final Map<String, dynamic> journey;

  int get sessions => _integer(journey['sessions']);
  int get wordsAttempted => _integer(journey['wordsPractised']);
  int get accuracy => _integer(journey['accuracy']);
  int get currentStreak => _integer(journey['currentStreak']);
  int get competitionCount => _integer(journey['matches']);
  int get trainingSeconds => _integer(journey['trainingSeconds']);
  DateTime? get lastActive =>
      DateTime.tryParse(journey['lastCompletedAt']?.toString() ?? '');

  int get readinessScore {
    final activity = sessions.clamp(0, 20) * 2;
    final accuracyScore = (accuracy * 0.5).round();
    final recency = lastActive == null
        ? 0
        : DateTime.now().difference(lastActive!).inDays <= 2
        ? 10
        : DateTime.now().difference(lastActive!).inDays <= 7
        ? 6
        : 0;
    return (activity + accuracyScore + recency).clamp(0, 100);
  }

  String get readinessLabel => switch (readinessScore) {
    >= 85 => 'Excellent',
    >= 70 => 'Good',
    >= 50 => 'Fair',
    _ => 'Needs practice',
  };

  factory OrganizationLearner.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return OrganizationLearner(
      id: document.id,
      name: data['name']?.toString() ?? 'Learner',
      grade: data['grade']?.toString() ?? '',
      status: data['status']?.toString() ?? 'active',
      journey: _map(data['journey']),
    );
  }
}

class OrganizationTeam {
  const OrganizationTeam({
    required this.id,
    required this.name,
    required this.learnerIds,
  });

  final String id;
  final String name;
  final List<String> learnerIds;

  factory OrganizationTeam.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return OrganizationTeam(
      id: document.id,
      name: data['name']?.toString() ?? 'Team',
      learnerIds: (data['learnerIds'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(),
    );
  }
}

class OrganizationCompetition {
  const OrganizationCompetition({
    required this.id,
    required this.name,
    required this.status,
    required this.template,
    required this.year,
    required this.participantOrganizationIds,
  });

  final String id;
  final String name;
  final String status;
  final String template;
  final int year;
  final List<String> participantOrganizationIds;

  factory OrganizationCompetition.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return OrganizationCompetition(
      id: document.id,
      name: data['name']?.toString() ?? 'Competition',
      status: data['status']?.toString() ?? 'draft',
      template: data['template']?.toString() ?? 'spellingBee',
      year: (data['year'] as num?)?.round() ?? DateTime.now().year,
      participantOrganizationIds:
          (data['participantOrganizationIds'] as List? ?? const [])
              .map((value) => value.toString())
              .toList(),
    );
  }
}

class OrganizationInvitation {
  const OrganizationInvitation({
    required this.id,
    required this.email,
    required this.kind,
    required this.status,
  });

  final String id;
  final String email;
  final String kind;
  final String status;

  factory OrganizationInvitation.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return OrganizationInvitation(
      id: document.id,
      email: data['email']?.toString() ?? '',
      kind: data['kind']?.toString() ?? 'staff',
      status: data['status']?.toString() ?? 'pending',
    );
  }
}

class OrganizationActivity {
  const OrganizationActivity({required this.message, required this.createdAt});

  final String message;
  final DateTime? createdAt;

  factory OrganizationActivity.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return OrganizationActivity(
      message: data['message']?.toString() ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class OrganizationManagementRepository {
  const OrganizationManagementRepository(this.firestore);

  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> _collection(
    String organizationId,
    String name,
  ) => firestore.collection('organizations/$organizationId/$name');

  Stream<List<OrganizationMember>> watchMembers(String organizationId) =>
      _collection(organizationId, 'members').snapshots().map(
        (snapshot) =>
            snapshot.docs.map(OrganizationMember.fromDocument).toList(),
      );

  Stream<List<OrganizationLearner>> watchLearners(String organizationId) =>
      _collection(organizationId, 'learners')
          .orderBy('name')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(OrganizationLearner.fromDocument).toList(),
          );

  Stream<List<OrganizationTeam>> watchTeams(String organizationId) =>
      _collection(organizationId, 'teams')
          .orderBy('name')
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(OrganizationTeam.fromDocument).toList(),
          );

  Stream<List<OrganizationCompetition>> watchCompetitions(
    String organizationId,
  ) => _collection(organizationId, 'competitions')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(OrganizationCompetition.fromDocument).toList(),
      );

  Stream<List<OrganizationInvitation>> watchInvitations(
    String organizationId,
  ) => _collection(organizationId, 'invitations')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(OrganizationInvitation.fromDocument).toList(),
      );

  Stream<List<OrganizationActivity>> watchActivity(String organizationId) =>
      _collection(organizationId, 'activity')
          .orderBy('createdAt', descending: true)
          .limit(12)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(OrganizationActivity.fromDocument).toList(),
          );

  Future<void> addLearner({
    required String organizationId,
    required String name,
    required String grade,
    required String actorUid,
  }) async {
    final document = _collection(organizationId, 'learners').doc();
    await document.set({
      'id': document.id,
      'name': name.trim(),
      'grade': grade.trim(),
      'status': 'active',
      'createdBy': actorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _activity(organizationId, '$name was added to the learner roster.');
  }

  Future<void> setLearnerStatus({
    required String organizationId,
    required String learnerId,
    required String status,
  }) => _collection(organizationId, 'learners').doc(learnerId).update({
    'status': status,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> createTeam({
    required String organizationId,
    required String name,
    required List<String> learnerIds,
    required String actorUid,
  }) async {
    final document = _collection(organizationId, 'teams').doc();
    await document.set({
      'id': document.id,
      'name': name.trim(),
      'learnerIds': learnerIds,
      'createdBy': actorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _activity(organizationId, 'Team $name was created.');
  }

  Future<void> updateTeamLearners({
    required String organizationId,
    required String teamId,
    required List<String> learnerIds,
  }) => _collection(organizationId, 'teams').doc(teamId).update({
    'learnerIds': learnerIds,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> invite({
    required String organizationId,
    required String email,
    required String kind,
    required String role,
    required String actorUid,
  }) async {
    final document = _collection(organizationId, 'invitations').doc();
    await document.set({
      'id': document.id,
      'email': email.trim().toLowerCase(),
      'kind': kind,
      'role': role,
      'status': 'pending',
      'organizationId': organizationId,
      'invitedBy': actorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _activity(organizationId, 'Invitation sent to ${email.trim()}.');
  }

  Future<String> createCompetition({
    required String organizationId,
    required String name,
    required String actorUid,
    String template = 'spellingBee',
    int? year,
    int capacity = 0,
  }) async {
    final document = _collection(organizationId, 'competitions').doc();
    await document.set({
      'id': document.id,
      'name': name.trim(),
      'description': '',
      'status': 'draft',
      'template': template,
      'year': year ?? DateTime.now().year,
      'hostOrganizationId': organizationId,
      'participantOrganizationIds': [organizationId],
      'registration': {
        'capacity': capacity,
        'mode': 'organization',
        'approvalRequired': true,
        'waitlistEnabled': true,
      },
      'eligibility': {'notes': ''},
      'budget': {'currency': 'NGN', 'limit': 0},
      'createdBy': actorUid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _activity(organizationId, 'Competition $name was created.');
    return document.id;
  }

  Future<String> duplicateCompetition({
    required String organizationId,
    required OrganizationCompetition source,
    required String actorUid,
  }) => createCompetition(
    organizationId: organizationId,
    name: '${source.name} ${DateTime.now().year + 1}',
    actorUid: actorUid,
    template: source.template,
    year: DateTime.now().year + 1,
  );

  Future<void> setCompetitionStatus({
    required String organizationId,
    required String competitionId,
    required String status,
  }) async {
    await _collection(organizationId, 'competitions').doc(competitionId).update(
      {'status': status, 'updatedAt': FieldValue.serverTimestamp()},
    );
    await _activity(organizationId, 'Competition moved to $status.');
  }

  Future<void> addParticipatingOrganization({
    required String organizationId,
    required String competitionId,
    required String participantOrganizationId,
  }) async {
    await _collection(organizationId, 'competitions').doc(competitionId).update(
      {
        'participantOrganizationIds': FieldValue.arrayUnion([
          participantOrganizationId.trim(),
        ]),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    );
    await _activity(
      organizationId,
      'A participating organisation was added to a competition.',
    );
  }

  Future<void> setInvitationStatus({
    required String organizationId,
    required String invitationId,
    required String status,
  }) => _collection(organizationId, 'invitations').doc(invitationId).update({
    'status': status,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateMember({
    required String organizationId,
    required String memberId,
    required String role,
    required Map<String, bool> permissions,
  }) => _collection(organizationId, 'members').doc(memberId).update({
    'role': role,
    'permissions': permissions,
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> _activity(String organizationId, String message) => _collection(
    organizationId,
    'activity',
  ).add({'message': message, 'createdAt': FieldValue.serverTimestamp()});
}

Map<String, bool> _permissions(Object? value) {
  if (value is! Map) return const {};
  return {
    for (final entry in value.entries)
      entry.key.toString(): entry.value == true,
  };
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};

int _integer(Object? value) =>
    value is num ? value.round() : int.tryParse('$value') ?? 0;
