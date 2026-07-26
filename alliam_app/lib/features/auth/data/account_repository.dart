import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/account_session.dart';

class AccountRepository {
  AccountRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _account(String uid) =>
      _firestore.doc('accounts/$uid');

  DocumentReference<Map<String, dynamic>> _state(String uid) =>
      _firestore.doc('accounts/$uid/data/app-state');

  Future<AccountSession> load(User user) async {
    final results = await Future.wait([
      _account(user.uid).get(),
      _state(user.uid).get(),
      _firestore.collection('accounts/${user.uid}/learners').get(),
    ]);
    final accountData =
        (results[0] as DocumentSnapshot<Map<String, dynamic>>).data() ??
        const <String, dynamic>{};
    final stateData =
        (results[1] as DocumentSnapshot<Map<String, dynamic>>).data() ??
        const <String, dynamic>{};
    final learnerDocuments = results[2] as QuerySnapshot<Map<String, dynamic>>;
    final value = _map(stateData['value']);

    final accountRole = _role(accountData['role']);
    final legacyRole = _role(value['accountType']);
    final role =
        accountRole == AccountRole.pending && legacyRole != AccountRole.pending
        ? legacyRole
        : accountRole;
    final owner = _map(value['accountOwner']);
    final school = _map(value['schoolAccount']);
    final learnersById = <String, LearnerProfile>{};
    for (final profile in _list(
      value['profiles'],
    ).map(LearnerProfile.fromMap).where((profile) => profile.id.isNotEmpty)) {
      learnersById[profile.id] = profile;
    }
    for (final document in learnerDocuments.docs) {
      final profile = LearnerProfile.fromMap({
        ...document.data(),
        'id': document.id,
      });
      if (profile.id.isNotEmpty) learnersById[profile.id] = profile;
    }
    final learners = learnersById.values.toList();

    final session = AccountSession(
      role: role,
      ownerName: _ownerName(owner, school, accountData, user),
      ownerCountry: (owner['country'] ?? school['country'] ?? 'Nigeria')
          .toString(),
      schoolName: (school['name'] ?? accountData['schoolName'] ?? '')
          .toString(),
      activeLearnerId:
          (accountData['activeLearnerId'] ?? value['activeProfileId'])
              ?.toString(),
      learners: learners,
    );
    final legacyProfileCount = _list(value['profiles']).length;
    if (session.onboardingComplete &&
        ((accountData['schemaVersion'] as num?)?.round() != 2 ||
            legacyProfileCount != learners.length)) {
      await _migrateLegacy(user, session);
    }
    return session;
  }

  Future<void> _migrateLegacy(User user, AccountSession session) async {
    final batch = _firestore.batch();
    batch.set(_account(user.uid), {
      'uid': user.uid,
      'email': user.email,
      'displayName': session.ownerName,
      'role': session.role.name,
      'schemaVersion': 2,
      'activeLearnerId': session.activeLearnerId,
      'schoolName': session.schoolName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    for (final learner in session.learners) {
      batch.set(
        _firestore.doc('accounts/${user.uid}/learners/${learner.id}'),
        {
          ...learner.toMap(),
          'accountId': user.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    }
    batch.set(_state(user.uid), {
      'value.profiles': session.learners
          .map((learner) => learner.toMap())
          .toList(),
      'value.activeProfileId': session.activeLearnerId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<void> completeStudent({
    required User user,
    required String name,
    required String grade,
    required String country,
    required String school,
  }) async {
    final learner = _learner(name, grade, country, school);
    await _saveSetup(
      user: user,
      role: AccountRole.student,
      ownerName: name,
      country: country,
      profiles: [learner],
      activeProfileId: learner.id,
    );
  }

  Future<void> completeParent({
    required User user,
    required String parentName,
    required String country,
    required String learnerName,
    required String grade,
    required String school,
  }) async {
    final learner = _learner(learnerName, grade, country, school);
    await _saveSetup(
      user: user,
      role: AccountRole.parent,
      ownerName: parentName,
      country: country,
      profiles: [learner],
      activeProfileId: learner.id,
      accountOwner: {'name': parentName, 'country': country},
    );
  }

  Future<void> completeSchool({
    required User user,
    required String schoolName,
    required String administratorName,
    required String country,
  }) async {
    await _saveSetup(
      user: user,
      role: AccountRole.school,
      ownerName: administratorName,
      country: country,
      profiles: const [],
      activeProfileId: null,
      schoolAccount: {
        'name': schoolName,
        'adminName': administratorName,
        'country': country,
      },
      schoolName: schoolName,
    );
  }

  Future<void> createDemo(User user) => completeStudent(
    user: user,
    name: 'Ada',
    grade: 'Grade 1',
    country: 'Nigeria',
    school: 'Demo Primary School',
  );

  Future<void> setActiveLearner(User user, String learnerId) async {
    final batch = _firestore.batch();
    batch.set(_account(user.uid), {
      'activeLearnerId': learnerId,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_state(user.uid), {
      'value': {'activeProfileId': learnerId},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  Future<LearnerProfile> addLearner({
    required User user,
    required AccountSession session,
    required String name,
    required String grade,
    required String country,
    required String school,
  }) async {
    final learner = _learner(name, grade, country, school);
    final profiles = [...session.learners, learner];
    await _state(user.uid).set({
      'value': {
        'profiles': profiles.map((profile) => profile.toMap()).toList(),
        'activeProfileId': learner.id,
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _firestore.doc('accounts/${user.uid}/learners/${learner.id}').set({
      ...learner.toMap(),
      'accountId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return learner;
  }

  Future<void> updateOwner({
    required User user,
    required String name,
    required String country,
    String? schoolName,
  }) async {
    await user.updateDisplayName(name);
    await _account(user.uid).set({
      'displayName': name,
      'schoolName': schoolName,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    final session = await load(user);
    await _state(user.uid).set({
      'value': {
        if (session.role == AccountRole.school)
          'schoolAccount': {
            'name': schoolName ?? session.schoolName,
            'adminName': name,
            'country': country,
          }
        else
          'accountOwner': {'name': name, 'country': country},
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> recordMatch({
    required User user,
    required String matchId,
    required String opponent,
    required String mode,
    required int myScore,
    required int opponentScore,
    required bool won,
    required int ratingDelta,
  }) async {
    final reference = _state(user.uid);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(reference);
      final document = snapshot.data() ?? const <String, dynamic>{};
      final value = _map(document['value']);
      final profiles = _list(value['profiles']);
      final activeId = value['activeProfileId']?.toString();
      for (var index = 0; index < profiles.length; index++) {
        if (profiles[index]['id']?.toString() != activeId) continue;
        final profile = Map<String, dynamic>.from(profiles[index]);
        final journey = _map(profile['journey']);
        profile['journey'] = {
          ...journey,
          'matches': ((journey['matches'] as num?)?.round() ?? 0) + 1,
          'bestStreak': (journey['bestStreak'] as num?)?.round() ?? 0,
        };
        profiles[index] = profile;
      }
      final matches = _list(value['matches']);
      if (!matches.any((match) => match['id']?.toString() == matchId)) {
        matches.insert(0, {
          'id': matchId,
          'opponent': opponent,
          'result': won ? 'Won' : 'Lost',
          'mode': mode,
          'score': '$myScore-$opponentScore',
          'rating': ratingDelta,
          'date': DateTime.now().toUtc().toIso8601String(),
        });
      }
      transaction.set(reference, {
        'value': {...value, 'profiles': profiles, 'matches': matches},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  Future<void> _saveSetup({
    required User user,
    required AccountRole role,
    required String ownerName,
    required String country,
    required List<LearnerProfile> profiles,
    required String? activeProfileId,
    Map<String, dynamic>? accountOwner,
    Map<String, dynamic>? schoolAccount,
    String? schoolName,
  }) async {
    final roleName = role.name;
    final batch = _firestore.batch();
    batch.set(_account(user.uid), {
      'uid': user.uid,
      'email': user.email,
      'displayName': ownerName,
      'role': roleName,
      'schemaVersion': 2,
      'activeLearnerId': activeProfileId,
      'schoolName': schoolName,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(_state(user.uid), {
      'value': {
        'initialized': true,
        'accountType': roleName,
        'profiles': profiles.map((profile) => profile.toMap()).toList(),
        'activeProfileId': activeProfileId,
        'accountOwner': accountOwner,
        'schoolAccount': schoolAccount,
        'settings': {
          'learnerLevel': 'Foundation',
          'voice': 'Alliam One',
          'speed': 'Normal',
          'volume': 90,
          'locale': 'en-NG',
          'effects': true,
          'reducedMotion': false,
          'highContrast': false,
        },
      },
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    for (final learner in profiles) {
      batch.set(_firestore.doc('accounts/${user.uid}/learners/${learner.id}'), {
        ...learner.toMap(),
        'accountId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
    await user.updateDisplayName(ownerName);
  }

  static LearnerProfile _learner(
    String name,
    String grade,
    String country,
    String school,
  ) {
    final cleanName = name.trim().isEmpty ? 'Speller' : name.trim();
    return LearnerProfile(
      id: 'p-${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      grade: grade,
      country: country,
      school: school.trim(),
      avatar: cleanName[0].toUpperCase(),
    );
  }

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};

  static List<Map<String, dynamic>> _list(Object? value) => value is List
      ? value.whereType<Map>().map(Map<String, dynamic>.from).toList()
      : [];

  static AccountRole _role(Object? value) {
    return switch (value?.toString().toLowerCase()) {
      'student' || 'learner' => AccountRole.student,
      'parent' => AccountRole.parent,
      'school' || 'coach' => AccountRole.school,
      _ => AccountRole.pending,
    };
  }

  static String _ownerName(
    Map<String, dynamic> owner,
    Map<String, dynamic> school,
    Map<String, dynamic> account,
    User user,
  ) {
    return (owner['name'] ??
            school['adminName'] ??
            account['displayName'] ??
            user.displayName ??
            user.email?.split('@').first ??
            'Speller')
        .toString();
  }
}
