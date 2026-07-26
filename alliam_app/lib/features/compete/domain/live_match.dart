class MatchPlayer {
  const MatchPlayer({
    required this.uid,
    required this.name,
    required this.avatar,
  });

  final String uid;
  final String name;
  final String avatar;
}

class LiveMatch {
  const LiveMatch({
    required this.id,
    required this.mode,
    required this.status,
    required this.players,
    required this.playerProfiles,
    required this.currentRound,
    required this.totalRounds,
    required this.wordIds,
    required this.scores,
    required this.submissions,
    required this.winnerUid,
    required this.completionReason,
    required this.forfeitedBy,
    required this.presence,
  });

  final String id;
  final String mode;
  final String status;
  final List<String> players;
  final Map<String, MatchPlayer> playerProfiles;
  final int currentRound;
  final int totalRounds;
  final List<String> wordIds;
  final Map<String, int> scores;
  final Map<String, Map<String, dynamic>> submissions;
  final String? winnerUid;
  final String? completionReason;
  final String? forfeitedBy;
  final Map<String, MatchPresence> presence;

  String get currentWord => wordIds[currentRound.clamp(0, wordIds.length - 1)];

  String? opponentUid(String uid) {
    for (final player in players) {
      if (player != uid) return player;
    }
    return null;
  }

  Map<String, dynamic>? submission(int round, String uid) =>
      submissions['${round}_$uid'];

  bool opponentAppearsDisconnected(String uid, DateTime now) {
    final opponent = opponentUid(uid);
    final lastSeen = presence[opponent]?.lastSeenAt;
    return lastSeen == null ||
        now.difference(lastSeen) > const Duration(seconds: 45);
  }

  factory LiveMatch.fromMap(String id, Map<String, dynamic> value) {
    final profiles = <String, MatchPlayer>{};
    final rawProfiles = value['playerProfiles'];
    if (rawProfiles is Map) {
      for (final entry in rawProfiles.entries) {
        final profile = entry.value is Map
            ? Map<String, dynamic>.from(entry.value as Map)
            : const <String, dynamic>{};
        final name =
            (profile['nickname'] ?? profile['displayName'] ?? 'Opponent')
                .toString();
        profiles[entry.key.toString()] = MatchPlayer(
          uid: entry.key.toString(),
          name: name,
          avatar:
              profile['avatar']?.toString() ??
              (name.isEmpty ? 'S' : name[0].toUpperCase()),
        );
      }
    }
    return LiveMatch(
      id: id,
      mode: value['mode']?.toString() ?? 'Casual 1v1',
      status: value['status']?.toString() ?? 'active',
      players: _strings(value['players']),
      playerProfiles: profiles,
      currentRound: (value['currentRound'] as num?)?.round() ?? 0,
      totalRounds: (value['totalRounds'] as num?)?.round() ?? 5,
      wordIds: _strings(value['wordIds']),
      scores: _intMap(value['scores']),
      submissions: _submissionMap(value['submissions']),
      winnerUid: value['winnerUid']?.toString(),
      completionReason: value['completionReason']?.toString(),
      forfeitedBy: value['forfeitedBy']?.toString(),
      presence: _presenceMap(value['presence']),
    );
  }

  static List<String> _strings(Object? value) =>
      value is List ? value.map((item) => item.toString()).toList() : [];

  static Map<String, int> _intMap(Object? value) {
    if (value is! Map) return {};
    return value.map(
      (key, item) => MapEntry(key.toString(), (item as num?)?.round() ?? 0),
    );
  }

  static Map<String, Map<String, dynamic>> _submissionMap(Object? value) {
    if (value is! Map) return {};
    return value.map(
      (key, item) => MapEntry(
        key.toString(),
        item is Map ? Map<String, dynamic>.from(item) : <String, dynamic>{},
      ),
    );
  }

  static Map<String, MatchPresence> _presenceMap(Object? value) {
    if (value is! Map) return {};
    return value.map((key, item) {
      final data = item is Map
          ? Map<String, dynamic>.from(item)
          : const <String, dynamic>{};
      return MapEntry(
        key.toString(),
        MatchPresence(
          state: data['state']?.toString() ?? 'online',
          lastSeenAt: DateTime.fromMillisecondsSinceEpoch(
            (data['lastSeenAt'] as num?)?.round() ?? 0,
          ),
        ),
      );
    });
  }
}

class MatchPresence {
  const MatchPresence({required this.state, required this.lastSeenAt});
  final String state;
  final DateTime lastSeenAt;
}
