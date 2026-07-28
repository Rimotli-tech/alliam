import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/spelling_word.dart';

class WordRepository {
  WordRepository(this._firestore);

  static const approvedCollections = {'core-60-v1', 'grade-1-2-200-v1'};
  final FirebaseFirestore _firestore;

  Future<List<SpellingWord>> load({
    String level = 'Foundation',
    int count = 5,
  }) async {
    final snapshot = await _firestore
        .collection('words')
        .where('approved', isEqualTo: true)
        .get();
    final words =
        snapshot.docs
            .map((doc) => SpellingWord.fromFirestore(doc.id, doc.data()))
            .where(
              (word) =>
                  word.approved &&
                  approvedCollections.contains(word.approvalCollection) &&
                  word.level == level &&
                  word.pronunciation?.storagePath.isNotEmpty == true,
            )
            .toList()
          ..shuffle(Random());
    if (words.isEmpty) {
      throw StateError('No $level words are currently available.');
    }
    return words.take(count.clamp(1, words.length)).toList();
  }

  Future<SpellingWord> loadWord(String word) async {
    final direct = await _firestore.doc('words/${word.toLowerCase()}').get();
    if (direct.exists) {
      return SpellingWord.fromFirestore(direct.id, direct.data()!);
    }
    final query = await _firestore
        .collection('words')
        .where('word', isEqualTo: word.toLowerCase())
        .limit(1)
        .get();
    if (query.docs.isEmpty) {
      throw StateError('The competition word could not be loaded.');
    }
    final document = query.docs.first;
    return SpellingWord.fromFirestore(document.id, document.data());
  }

  Future<List<SpellingWord>> loadWords(Iterable<String> words) async {
    final unique = words.map((word) => word.toLowerCase()).toSet().toList();
    final loaded = await Future.wait(unique.map(loadWord));
    return loaded
        .where(
          (word) =>
              word.approved &&
              approvedCollections.contains(word.approvalCollection) &&
              word.pronunciation?.storagePath.isNotEmpty == true,
        )
        .toList();
  }
}
