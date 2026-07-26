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

class AdminOverview {
  const AdminOverview({required this.words, required this.learners});

  final List<AdminWordAudio> words;
  final List<AdminLearner> learners;
}

class AdminService {
  AdminService()
    : _functions = FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFunctions _functions;

  Future<AdminOverview> loadOverview() async {
    final result = await _functions
        .httpsCallable('getAdminOverview')
        .call<Map<dynamic, dynamic>>()
        .timeout(const Duration(seconds: 30));
    final data = Map<String, dynamic>.from(result.data);
    final words = (data['words'] as List<dynamic>? ?? const []).map((value) {
      final item = Map<String, dynamic>.from(value as Map);
      return AdminWordAudio(
        id: item['id']?.toString() ?? '',
        word: item['word']?.toString() ?? '',
        level: item['level']?.toString() ?? 'Unassigned',
        storagePath: item['storagePath']?.toString() ?? '',
        approved: item['approved'] == true,
      );
    }).toList()..sort((a, b) => a.word.compareTo(b.word));
    final learners = (data['learners'] as List<dynamic>? ?? const []).map((
      value,
    ) {
      final item = Map<String, dynamic>.from(value as Map);
      return AdminLearner(
        accountId: item['accountId']?.toString() ?? '',
        id: item['id']?.toString() ?? '',
        name: item['name']?.toString() ?? 'Speller',
        grade: item['grade']?.toString() ?? 'Grade 1',
      );
    }).toList()..sort((a, b) => a.name.compareTo(b.name));
    return AdminOverview(words: words, learners: learners);
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
