class AudioAsset {
  const AudioAsset({required this.storagePath});

  final String storagePath;

  factory AudioAsset.from(Object? value) {
    if (value is String) return AudioAsset(storagePath: value);
    if (value is Map && value['storagePath'] is String) {
      return AudioAsset(storagePath: value['storagePath'] as String);
    }
    return const AudioAsset(storagePath: '');
  }
}

class SpellingWord {
  const SpellingWord({
    required this.word,
    required this.level,
    required this.definition,
    required this.sentence,
    required this.origin,
    required this.partOfSpeech,
    required this.audio,
    required this.approved,
    required this.approvalCollection,
  });

  final String word;
  final String level;
  final String definition;
  final String sentence;
  final String origin;
  final String partOfSpeech;
  final Map<String, AudioAsset> audio;
  final bool approved;
  final String approvalCollection;

  AudioAsset? get pronunciation => audio['pronunciation'];
  AudioAsset? get spelling => audio['spelling'];

  factory SpellingWord.fromFirestore(String id, Map<String, dynamic> data) {
    final rawAudio = data['audio'];
    final audio = <String, AudioAsset>{};
    if (rawAudio is Map) {
      for (final entry in rawAudio.entries) {
        final asset = AudioAsset.from(entry.value);
        if (asset.storagePath.isNotEmpty) audio[entry.key.toString()] = asset;
      }
    }
    return SpellingWord(
      word: (data['word'] ?? id).toString().toLowerCase(),
      level: (data['level'] ?? 'Foundation').toString(),
      definition: (data['definition'] ?? '').toString(),
      sentence: (data['sentence'] ?? '').toString(),
      origin: (data['origin'] ?? '').toString(),
      partOfSpeech: (data['part'] ?? data['partOfSpeech'] ?? '').toString(),
      audio: audio,
      approved: data['approved'] == true,
      approvalCollection: (data['approvalCollection'] ?? '').toString(),
    );
  }
}
