import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlliamSettings {
  const AlliamSettings({
    this.level = 'Foundation',
    this.automaticPathway = true,
    this.music = true,
    this.voice = true,
    this.effects = true,
    this.musicVolume = 1,
    this.voiceVolume = 1,
    this.effectsVolume = 1,
    this.motion = true,
    this.notifications = true,
    this.modules = const {},
  });

  final String level;
  final bool automaticPathway;
  final bool music;
  final bool voice;
  final bool effects;
  final double musicVolume;
  final double voiceVolume;
  final double effectsVolume;
  bool get sound => music || voice || effects;
  final bool motion;
  final bool notifications;
  final Map<String, Map<String, dynamic>> modules;

  AlliamSettings copyWith({
    String? level,
    bool? automaticPathway,
    bool? music,
    bool? voice,
    bool? effects,
    double? musicVolume,
    double? voiceVolume,
    double? effectsVolume,
    bool? motion,
    bool? notifications,
    Map<String, Map<String, dynamic>>? modules,
  }) => AlliamSettings(
    level: level ?? this.level,
    automaticPathway: automaticPathway ?? this.automaticPathway,
    music: music ?? this.music,
    voice: voice ?? this.voice,
    effects: effects ?? this.effects,
    musicVolume: musicVolume ?? this.musicVolume,
    voiceVolume: voiceVolume ?? this.voiceVolume,
    effectsVolume: effectsVolume ?? this.effectsVolume,
    motion: motion ?? this.motion,
    notifications: notifications ?? this.notifications,
    modules: modules ?? this.modules,
  );

  Map<String, dynamic> module(String slug) => modules[slug] ?? const {};

  factory AlliamSettings.fromMap(Map<String, dynamic>? value) {
    final rawModules = value?['modules'];
    final modules = <String, Map<String, dynamic>>{};
    if (rawModules is Map) {
      for (final entry in rawModules.entries) {
        if (entry.value is Map) {
          modules[entry.key.toString()] = Map<String, dynamic>.from(
            entry.value as Map,
          );
        }
      }
    }
    return AlliamSettings(
      level: value?['level']?.toString() ?? 'Foundation',
      automaticPathway: value?['automaticPathway'] != false,
      music: value?['music'] ?? value?['sound'] != false,
      voice: value?['voice'] ?? value?['sound'] != false,
      effects: value?['effects'] ?? value?['sound'] != false,
      musicVolume: _volume(value?['musicVolume']),
      voiceVolume: _volume(value?['voiceVolume']),
      effectsVolume: _volume(value?['effectsVolume']),
      motion: value?['motion'] != false,
      notifications: value?['notifications'] != false,
      modules: modules,
    );
  }

  Map<String, dynamic> toMap() => {
    'level': level,
    'automaticPathway': automaticPathway,
    'sound': sound,
    'music': music,
    'voice': voice,
    'effects': effects,
    'musicVolume': musicVolume,
    'voiceVolume': voiceVolume,
    'effectsVolume': effectsVolume,
    'motion': motion,
    'notifications': notifications,
    'modules': modules,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  static double _volume(Object? value) =>
      ((value as num?)?.toDouble() ?? 1).clamp(0, 1);
}

class SettingsRepository {
  SettingsRepository(this.firestore, this.auth);
  final FirebaseFirestore firestore;
  final FirebaseAuth auth;

  DocumentReference<Map<String, dynamic>> get _ref =>
      firestore.doc('accounts/${auth.currentUser!.uid}/settings/preferences');

  Future<AlliamSettings> load() async =>
      AlliamSettings.fromMap((await _ref.get()).data());

  Future<void> save(AlliamSettings settings) =>
      _ref.set(settings.toMap(), SetOptions(merge: true));

  Future<void> saveModule(String slug, Map<String, dynamic> module) =>
      _ref.set({
        'modules': {slug: module},
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
}
