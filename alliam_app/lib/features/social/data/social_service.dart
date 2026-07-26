import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SocialService {
  SocialService({
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

  String get uid => _auth.currentUser!.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> friendships() => _firestore
      .collection('friendships')
      .where('memberUids', arrayContains: uid)
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> requests() => _firestore
      .collection('friendRequests')
      .where('recipientUid', isEqualTo: uid)
      .where('status', isEqualTo: 'pending')
      .snapshots();

  Stream<QuerySnapshot<Map<String, dynamic>>> teams() => _firestore
      .collection('teams')
      .where('memberUids', arrayContains: uid)
      .snapshots();

  Future<void> sendRequest(String identifier) =>
      _call('sendFriendRequest', {'identifier': identifier.trim()});

  Future<void> respond(String requestId, bool accept) =>
      _call('respondFriendRequest', {'requestId': requestId, 'accept': accept});

  Future<void> createTeam(String name) =>
      _call('createTeam', {'name': name.trim()});

  Future<void> _call(String name, Map<String, dynamic> data) async {
    try {
      await _functions.httpsCallable(name).call(data);
    } on FirebaseFunctionsException catch (error) {
      throw StateError(error.message ?? 'Social service unavailable.');
    }
  }
}
