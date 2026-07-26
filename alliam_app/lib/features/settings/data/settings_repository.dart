import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AlliamSettings {
  const AlliamSettings({
    this.level = 'Foundation',
    this.sound = true,
    this.motion = true,
    this.notifications = true,
    this.modules = const {},
  });

  final String level;
  final bool sound;
  final bool motion;
  final bool notifications;
  final Map<String, Map<String, dynamic>> modules;

  AlliamSettings copyWith({
    String? level,
    bool? sound,
    bool? motion,
    bool? notifications,
    Map<String, Map<String, dynamic>>? modules,
  }) => AlliamSettings(
    level: level ?? this.level,
    sound: sound ?? this.sound,
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
      sound: value?['sound'] != false,
      motion: value?['motion'] != false,
      notifications: value?['notifications'] != false,
      modules: modules,
    );
  }

  Map<String, dynamic> toMap() => {
    'level': level,
    'sound': sound,
    'motion': motion,
    'notifications': notifications,
    'modules': modules,
    'updatedAt': FieldValue.serverTimestamp(),
  };
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
