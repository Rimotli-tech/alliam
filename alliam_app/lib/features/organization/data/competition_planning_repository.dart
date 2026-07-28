import 'package:cloud_firestore/cloud_firestore.dart';

class CompetitionPlan {
  const CompetitionPlan({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.template,
    required this.year,
    required this.capacity,
    required this.registrationMode,
    required this.approvalRequired,
    required this.eligibilityNotes,
    required this.currency,
    required this.budgetLimit,
    this.registrationOpensAt,
    this.registrationClosesAt,
    this.startDate,
    this.endDate,
  });

  final String id;
  final String name;
  final String description;
  final String status;
  final String template;
  final int year;
  final int capacity;
  final String registrationMode;
  final bool approvalRequired;
  final String eligibilityNotes;
  final String currency;
  final double budgetLimit;
  final DateTime? registrationOpensAt;
  final DateTime? registrationClosesAt;
  final DateTime? startDate;
  final DateTime? endDate;

  factory CompetitionPlan.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final registration = _map(data['registration']);
    final eligibility = _map(data['eligibility']);
    final budget = _map(data['budget']);
    return CompetitionPlan(
      id: document.id,
      name: data['name']?.toString() ?? 'Competition',
      description: data['description']?.toString() ?? '',
      status: data['status']?.toString() ?? 'draft',
      template: data['template']?.toString() ?? 'spellingBee',
      year: (data['year'] as num?)?.round() ?? DateTime.now().year,
      capacity: (registration['capacity'] as num?)?.round() ?? 0,
      registrationMode: registration['mode']?.toString() ?? 'organization',
      approvalRequired: registration['approvalRequired'] != false,
      eligibilityNotes: eligibility['notes']?.toString() ?? '',
      currency: budget['currency']?.toString() ?? 'NGN',
      budgetLimit: (budget['limit'] as num?)?.toDouble() ?? 0,
      registrationOpensAt: (registration['opensAt'] as Timestamp?)?.toDate(),
      registrationClosesAt: (registration['closesAt'] as Timestamp?)?.toDate(),
      startDate: (data['startDate'] as Timestamp?)?.toDate(),
      endDate: (data['endDate'] as Timestamp?)?.toDate(),
    );
  }
}

class CompetitionDivision {
  const CompetitionDivision({
    required this.id,
    required this.name,
    required this.minimumAge,
    required this.maximumAge,
    required this.capacity,
  });

  final String id;
  final String name;
  final int minimumAge;
  final int maximumAge;
  final int capacity;

  factory CompetitionDivision.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return CompetitionDivision(
      id: document.id,
      name: data['name']?.toString() ?? 'Division',
      minimumAge: (data['minimumAge'] as num?)?.round() ?? 0,
      maximumAge: (data['maximumAge'] as num?)?.round() ?? 0,
      capacity: (data['capacity'] as num?)?.round() ?? 0,
    );
  }
}

class CompetitionMilestone {
  const CompetitionMilestone({
    required this.id,
    required this.title,
    required this.complete,
    this.dueDate,
  });

  final String id;
  final String title;
  final bool complete;
  final DateTime? dueDate;

  factory CompetitionMilestone.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return CompetitionMilestone(
      id: document.id,
      title: data['title']?.toString() ?? 'Milestone',
      complete: data['complete'] == true,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
    );
  }
}

class CompetitionBudgetItem {
  const CompetitionBudgetItem({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.confirmed,
  });

  final String id;
  final String name;
  final String category;
  final double amount;
  final bool confirmed;

  factory CompetitionBudgetItem.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return CompetitionBudgetItem(
      id: document.id,
      name: data['name']?.toString() ?? 'Budget item',
      category: data['category']?.toString() ?? 'Operations',
      amount: (data['amount'] as num?)?.toDouble() ?? 0,
      confirmed: data['confirmed'] == true,
    );
  }
}

class CompetitionRegistration {
  const CompetitionRegistration({
    required this.id,
    required this.applicantName,
    required this.applicantType,
    required this.contactEmail,
    required this.entryType,
    required this.entryName,
    required this.divisionId,
    required this.divisionName,
    required this.status,
    required this.eligible,
    required this.eligibilityNotes,
  });

  final String id;
  final String applicantName;
  final String applicantType;
  final String contactEmail;
  final String entryType;
  final String entryName;
  final String divisionId;
  final String divisionName;
  final String status;
  final bool? eligible;
  final String eligibilityNotes;

  factory CompetitionRegistration.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    return CompetitionRegistration(
      id: document.id,
      applicantName: data['applicantName']?.toString() ?? '',
      applicantType: data['applicantType']?.toString() ?? 'organization',
      contactEmail: data['contactEmail']?.toString() ?? '',
      entryType: data['entryType']?.toString() ?? 'learner',
      entryName: data['entryName']?.toString() ?? 'Entry',
      divisionId: data['divisionId']?.toString() ?? '',
      divisionName: data['divisionName']?.toString() ?? 'Unassigned',
      status: data['status']?.toString() ?? 'pending',
      eligible: data['eligible'] as bool?,
      eligibilityNotes: data['eligibilityNotes']?.toString() ?? '',
    );
  }
}

class CompetitionPlanningRepository {
  const CompetitionPlanningRepository(this.firestore);

  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> _competition(
    String organizationId,
    String competitionId,
  ) => firestore.doc(
    'organizations/$organizationId/competitions/$competitionId',
  );

  Stream<CompetitionPlan?> watchPlan(
    String organizationId,
    String competitionId,
  ) => _competition(organizationId, competitionId).snapshots().map(
    (document) =>
        document.exists ? CompetitionPlan.fromDocument(document) : null,
  );

  Stream<List<CompetitionDivision>> watchDivisions(
    String organizationId,
    String competitionId,
  ) => _competition(organizationId, competitionId)
      .collection('divisions')
      .orderBy('name')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(CompetitionDivision.fromDocument).toList(),
      );

  Stream<List<CompetitionMilestone>> watchMilestones(
    String organizationId,
    String competitionId,
  ) => _competition(organizationId, competitionId)
      .collection('milestones')
      .orderBy('dueDate')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(CompetitionMilestone.fromDocument).toList(),
      );

  Stream<List<CompetitionBudgetItem>> watchBudgetItems(
    String organizationId,
    String competitionId,
  ) => _competition(organizationId, competitionId)
      .collection('budgetItems')
      .orderBy('createdAt')
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(CompetitionBudgetItem.fromDocument).toList(),
      );

  Stream<List<CompetitionRegistration>> watchRegistrations(
    String organizationId,
    String competitionId,
  ) => _competition(organizationId, competitionId)
      .collection('registrations')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map(CompetitionRegistration.fromDocument).toList(),
      );

  Future<void> updateOverview({
    required String organizationId,
    required String competitionId,
    required String name,
    required String description,
    required int year,
    DateTime? startDate,
    DateTime? endDate,
  }) => _competition(organizationId, competitionId).update({
    'name': name.trim(),
    'description': description.trim(),
    'year': year,
    'startDate': startDate == null ? null : Timestamp.fromDate(startDate),
    'endDate': endDate == null ? null : Timestamp.fromDate(endDate),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateEligibility({
    required String organizationId,
    required String competitionId,
    required String notes,
  }) => _competition(organizationId, competitionId).update({
    'eligibility': {'notes': notes.trim()},
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> updateRegistration({
    required String organizationId,
    required String competitionId,
    required int capacity,
    required String mode,
    required bool approvalRequired,
    DateTime? opensAt,
    DateTime? closesAt,
  }) => _competition(organizationId, competitionId).update({
    'registration': {
      'capacity': capacity,
      'mode': mode,
      'approvalRequired': approvalRequired,
      'waitlistEnabled': true,
      'opensAt': opensAt == null ? null : Timestamp.fromDate(opensAt),
      'closesAt': closesAt == null ? null : Timestamp.fromDate(closesAt),
    },
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> setCompetitionStatus({
    required String organizationId,
    required String competitionId,
    required String status,
  }) => _competition(
    organizationId,
    competitionId,
  ).update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});

  Future<void> updateBudget({
    required String organizationId,
    required String competitionId,
    required String currency,
    required double limit,
  }) => _competition(organizationId, competitionId).update({
    'budget': {'currency': currency, 'limit': limit},
    'updatedAt': FieldValue.serverTimestamp(),
  });

  Future<void> addDivision({
    required String organizationId,
    required String competitionId,
    required String name,
    required int minimumAge,
    required int maximumAge,
    required int capacity,
  }) =>
      _competition(organizationId, competitionId).collection('divisions').add({
        'name': name.trim(),
        'minimumAge': minimumAge,
        'maximumAge': maximumAge,
        'capacity': capacity,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<void> addMilestone({
    required String organizationId,
    required String competitionId,
    required String title,
    DateTime? dueDate,
  }) =>
      _competition(organizationId, competitionId).collection('milestones').add({
        'title': title.trim(),
        'dueDate': dueDate == null ? null : Timestamp.fromDate(dueDate),
        'complete': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> setMilestoneComplete({
    required String organizationId,
    required String competitionId,
    required String milestoneId,
    required bool complete,
  }) => _competition(
    organizationId,
    competitionId,
  ).collection('milestones').doc(milestoneId).update({'complete': complete});

  Future<void> addBudgetItem({
    required String organizationId,
    required String competitionId,
    required String name,
    required String category,
    required double amount,
  }) => _competition(organizationId, competitionId)
      .collection('budgetItems')
      .add({
        'name': name.trim(),
        'category': category,
        'amount': amount,
        'confirmed': false,
        'createdAt': FieldValue.serverTimestamp(),
      });

  Future<void> addRegistration({
    required String organizationId,
    required String competitionId,
    required String applicantName,
    required String applicantType,
    required String contactEmail,
    required String entryType,
    required String entryName,
    required String divisionId,
    required String divisionName,
    bool approved = false,
  }) async {
    await _competition(
      organizationId,
      competitionId,
    ).collection('registrations').add({
      'applicantName': applicantName.trim(),
      'applicantType': applicantType,
      'contactEmail': contactEmail.trim().toLowerCase(),
      'entryType': entryType,
      'entryName': entryName.trim(),
      'divisionId': divisionId,
      'divisionName': divisionName,
      'status': approved ? 'approved' : 'pending',
      'eligible': approved ? true : null,
      'eligibilityNotes': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _activity(
      organizationId,
      'New competition registration received from ${applicantName.trim()}.',
    );
  }

  Future<void> reviewEligibility({
    required String organizationId,
    required String competitionId,
    required String registrationId,
    required bool eligible,
    required String notes,
  }) => _competition(organizationId, competitionId)
      .collection('registrations')
      .doc(registrationId)
      .update({
        'eligible': eligible,
        'eligibilityNotes': notes.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

  Future<String> setRegistrationStatus({
    required String organizationId,
    required String competitionId,
    required String registrationId,
    required String requestedStatus,
    required int capacity,
    required int approvedCount,
  }) async {
    final status =
        requestedStatus == 'approved' &&
            capacity > 0 &&
            approvedCount >= capacity
        ? 'waitlisted'
        : requestedStatus;
    await _competition(organizationId, competitionId)
        .collection('registrations')
        .doc(registrationId)
        .update({'status': status, 'updatedAt': FieldValue.serverTimestamp()});
    await _activity(
      organizationId,
      status == 'waitlisted'
          ? 'Competition reached capacity; an entry was waitlisted.'
          : 'Competition registration moved to $status.',
    );
    return status;
  }

  Future<void> _activity(String organizationId, String message) => firestore
      .collection('organizations/$organizationId/activity')
      .add({'message': message, 'createdAt': FieldValue.serverTimestamp()});
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : {};
