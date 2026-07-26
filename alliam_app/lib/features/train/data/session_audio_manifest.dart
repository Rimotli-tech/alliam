import '../domain/spelling_word.dart';

class SessionAudioEntry {
  const SessionAudioEntry({
    required this.wordId,
    required this.pronunciationPath,
  });

  final String wordId;
  final String pronunciationPath;

  String get cacheKey => pronunciationPath;
}

class SessionAudioManifest {
  const SessionAudioManifest(this.entries);

  final List<SessionAudioEntry> entries;

  factory SessionAudioManifest.fromWords(List<SpellingWord> words) {
    return SessionAudioManifest([
      for (final word in words)
        SessionAudioEntry(
          wordId: word.word,
          pronunciationPath: word.pronunciation?.storagePath ?? '',
        ),
    ]);
  }

  SessionAudioEntry? get first => entries.isEmpty ? null : entries.first;

  List<SessionAudioEntry> get nextTwo =>
      entries.skip(1).take(2).toList(growable: false);

  List<SessionAudioEntry> get background =>
      entries.skip(3).toList(growable: false);
}

class SessionAudioPreparation {
  const SessionAudioPreparation({
    required this.total,
    required this.ready,
    required this.failedWordIds,
    required this.firstWordReady,
    required this.complete,
  });

  final int total;
  final int ready;
  final Set<String> failedWordIds;
  final bool firstWordReady;
  final bool complete;

  double get progress => total == 0 ? 1 : ready / total;
}
