import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AdminWordAudio {
  const AdminWordAudio({
    required this.id,
    required this.word,
    required this.level,
    required this.storagePath,
    required this.approved,
  });

  final String id;
  final String word;
  final String level;
  final String storagePath;
  final bool approved;
}

class AdminLearner {
  const AdminLearner({
    required this.accountId,
    required this.id,
    required this.name,
    required this.grade,
  });

  final String accountId;
  final String id;
  final String name;
  final String grade;
}

class AdminService {
  AdminService()
    : _firestore = FirebaseFirestore.instance,
      _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  Future<List<AdminWordAudio>> loadWords() async {
    final snapshot = await _firestore.collection('words').get();
    final words = snapshot.docs.map((document) {
      final data = document.data();
      final audio = data['audio'] is Map
          ? Map<String, dynamic>.from(data['audio'] as Map)
          : const <String, dynamic>{};
      final pronunciation = audio['pronunciation'] is Map
          ? Map<String, dynamic>.from(audio['pronunciation'] as Map)
          : const <String, dynamic>{};
      return AdminWordAudio(
        id: document.id,
        word: data['word']?.toString() ?? document.id,
        level: data['level']?.toString() ?? 'Unassigned',
        storagePath: pronunciation['storagePath']?.toString() ?? '',
        approved: data['approved'] == true,
      );
    }).toList()..sort((a, b) => a.word.compareTo(b.word));
    return words;
  }

  Future<List<AdminLearner>> loadLearners() async {
    final snapshot = await _firestore.collectionGroup('learners').get();
    final learners = snapshot.docs.map((document) {
      final data = document.data();
      return AdminLearner(
        accountId:
            data['accountId']?.toString() ?? document.reference.parent.parent!.id,
        id: document.id,
        name:
            (data['nickname'] ?? data['displayName'] ?? data['name'] ?? 'Speller')
                .toString(),
        grade: data['grade']?.toString() ?? 'Grade 1',
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    return learners;
  }

  Future<String> audioUrl(String storagePath) =>
      FirebaseStorage.instance.ref(storagePath).getDownloadURL();

  Future<void> approveWord(String wordId) async {
    await _functions.httpsCallable('approveWordAudio').call<void>({
      'wordId': wordId,
    });
  }

  Future<void> resetLearner(AdminLearner learner) async {
    await _functions.httpsCallable('resetLearnerProgress').call<void>({
      'accountId': learner.accountId,
      'learnerId': learner.id,
    });
  }
}
