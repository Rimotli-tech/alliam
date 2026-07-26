enum AccountRole { pending, student, parent, organization, admin }

class LearnerProfile {
  const LearnerProfile({
    required this.id,
    required this.name,
    required this.grade,
    required this.country,
    required this.school,
    required this.avatar,
    this.journey = const {},
  });

  final String id;
  final String name;
  final String grade;
  final String country;
  final String school;
  final String avatar;
  final Map<String, dynamic> journey;

  factory LearnerProfile.fromMap(Map<String, dynamic> value) {
    final name = (value['nickname'] ?? value['name'] ?? value['firstName'])
        ?.toString()
        .trim();
    final resolvedName = name?.isNotEmpty == true ? name! : 'Speller';
    return LearnerProfile(
      id: value['id']?.toString() ?? '',
      name: resolvedName,
      grade: value['grade']?.toString() ?? 'Grade 1',
      country: value['country']?.toString() ?? 'Nigeria',
      school: value['school']?.toString() ?? '',
      avatar: value['avatar']?.toString() ?? resolvedName[0].toUpperCase(),
      journey: _map(value['journey']),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'nickname': name,
    'displayName': name,
    'grade': grade,
    'country': country,
    'school': school,
    'avatar': avatar,
    'journey': journey,
  };

  static Map<String, dynamic> _map(Object? value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};
}

class AccountSession {
  const AccountSession({
    required this.role,
    required this.ownerName,
    required this.ownerCountry,
    required this.schoolName,
    required this.activeLearnerId,
    required this.learners,
    this.organizationId,
  });

  final AccountRole role;
  final String ownerName;
  final String ownerCountry;
  final String schoolName;
  final String? activeLearnerId;
  final List<LearnerProfile> learners;
  final String? organizationId;

  String get organizationName => schoolName;
  bool get managesLearners =>
      role == AccountRole.parent || role == AccountRole.organization;

  String get entryLocation => switch (role) {
    AccountRole.admin => '/admin',
    AccountRole.organization => '/organization',
    _ => '/pathway',
  };

  LearnerProfile? get activeLearner {
    if (role == AccountRole.admin) return null;
    for (final learner in learners) {
      if (learner.id == activeLearnerId) return learner;
    }
    return learners.firstOrNull;
  }

  String get activeLearnerName => activeLearner?.name ?? ownerName;

  String get firstName {
    final source = activeLearnerName.isNotEmpty ? activeLearnerName : ownerName;
    return source.trim().split(RegExp(r'\s+')).firstOrNull ?? 'Speller';
  }

  bool get onboardingComplete => role != AccountRole.pending;

  factory AccountSession.fallback(String email) {
    final name = email.split('@').first;
    return AccountSession(
      role: AccountRole.pending,
      ownerName: name,
      ownerCountry: 'Nigeria',
      schoolName: '',
      activeLearnerId: null,
      learners: const [],
      organizationId: null,
    );
  }
}
