import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../auth/domain/account_session.dart';
import '../domain/live_match.dart';

class QueueTicket {
  const QueueTicket({required this.matchId, required this.previousAssignment});
  final String? matchId;
  final String? previousAssignment;
}

class CompetitionService {
  CompetitionService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  User get user => _auth.currentUser!;

  Future<String?> activeMatchId() async {
    final current = _auth.currentUser;
    if (current == null || current.isAnonymous) return null;
    final assignment = await _firestore
        .doc('matchAssignments/${current.uid}')
        .get();
    final matchId = assignment.data()?['matchId']?.toString();
    if (assignment.data()?['status'] != 'active' ||
        matchId == null ||
        matchId.isEmpty) {
      return null;
    }
    final match = await _firestore.doc('matches/$matchId').get();
    final data = match.data();
    return match.exists &&
            data?['status'] == 'active' &&
            (data?['players'] as List?)?.contains(current.uid) == true
        ? matchId
        : null;
  }

  Future<void> bootstrap(AccountSession session) async {
    final learner = session.activeLearner;
    if (learner == null) {
      throw StateError('Choose a learner profile before competing.');
    }
    await _call('bootstrapPlayer', {
      'profile': {
        'displayName': learner.name,
        'nickname': learner.name,
        'grade': learner.grade,
        'country': learner.country,
        'school': learner.school,
        'avatar': learner.avatar,
      },
    });
  }

  Future<QueueTicket> joinQueue(String mode) async {
    final assignment = await _firestore
        .doc('matchAssignments/${user.uid}')
        .get();
    final previous = assignment.data()?['matchId']?.toString();
    if (assignment.data()?['status'] == 'active' &&
        previous != null &&
        previous.isNotEmpty) {
      final existing = await _firestore.doc('matches/$previous').get();
      final data = existing.data();
      if (existing.exists &&
          data?['status'] == 'active' &&
          (data?['players'] as List?)?.contains(user.uid) == true) {
        return QueueTicket(matchId: previous, previousAssignment: previous);
      }
    }
    final result = await _call('joinMatchQueue', {'mode': mode});
    return QueueTicket(
      matchId: result['matchId']?.toString(),
      previousAssignment: previous,
    );
  }

  Stream<String?> watchAssignment({String? ignoreMatchId}) {
    return _firestore.doc('matchAssignments/${user.uid}').snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data();
      if (data?['status'] != 'active') return null;
      final matchId = data?['matchId']?.toString();
      return matchId == ignoreMatchId ? null : matchId;
    });
  }

  Stream<LiveMatch?> watchMatch(String matchId) => _firestore
      .doc('matches/$matchId')
      .snapshots()
      .map(
        (snapshot) => snapshot.exists
            ? LiveMatch.fromMap(snapshot.id, snapshot.data()!)
            : null,
      );

  Future<void> cancelQueue() async => _call('cancelMatchQueue');

  Future<void> cancelPrivateRoom(String code) async =>
      _call('cancelPrivateRoom', {'code': code});

  Future<void> submitRound(String matchId, String attempt) async =>
      _call('submitMatchRound', {'matchId': matchId, 'attempt': attempt});

  Future<void> forfeit(String matchId) async =>
      _call('forfeitMatch', {'matchId': matchId});

  Future<void> touchPresence(String matchId, {bool away = false}) async =>
      _call('touchMatchPresence', {
        'matchId': matchId,
        'state': away ? 'away' : 'online',
      });

  Future<void> claimDisconnectedMatch(String matchId) async =>
      _call('claimDisconnectedMatch', {'matchId': matchId});

  Future<String> createPrivateRoom() async {
    final result = await _call('createPrivateRoom');
    return result['code']?.toString() ?? '';
  }

  Stream<String?> watchPrivateRoom(String code) => _firestore
      .doc('privateRooms/$code')
      .snapshots()
      .map((snapshot) => snapshot.data()?['matchId']?.toString());

  Future<String> joinPrivateRoom(String code) async {
    final result = await _call('joinPrivateRoom', {
      'code': code.trim().toUpperCase(),
    });
    return result['matchId']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> _call(
    String name, [
    Map<String, dynamic>? data,
  ]) async {
    try {
      final result = await _functions.httpsCallable(name).call(data);
      return result.data is Map
          ? Map<String, dynamic>.from(result.data as Map)
          : {};
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Competition service unavailable.');
    }
  }
}
