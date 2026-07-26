import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_page.dart';
import '../../auth/data/account_repository.dart';
import '../../auth/domain/account_session.dart';
import '../../train/domain/learner_pathway.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<AccountSession> _session;
  String? _selectedLearnerId;
  String? _switchingLearnerId;

  User get _user => FirebaseAuth.instance.currentUser!;
  AccountRepository get _repository =>
      AccountRepository(FirebaseFirestore.instance);

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _session = _repository.load(_user);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AccountSession>(
      future: _session,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AlliamPage(
            title: 'Profile',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.data!;
        final title = switch (session.role) {
          AccountRole.parent => 'Family profile',
          AccountRole.school => 'School profile',
          _ => 'Your profile',
        };
        return AlliamPage(
          title: title,
          subtitle: session.role == AccountRole.student
              ? 'Your spelling journey'
              : 'Account and learner management',
          child: Column(
            children: [
              _OwnerCard(
                session: session,
                user: _user,
                onEdit: () => _editOwner(session),
              ),
              const SizedBox(height: 22),
              if (session.role == AccountRole.parent)
                _LearnersCard(
                  session: session,
                  activeLearnerId:
                      _selectedLearnerId ?? session.activeLearnerId,
                  switchingLearnerId: _switchingLearnerId,
                  onAdd: () => _addLearner(session),
                  onView: (learner) =>
                      context.go('/profile/learner/${learner.id}'),
                  onSwitch: (learner) => _switchLearner(learner),
                )
              else if (session.role == AccountRole.school)
                _SchoolSummary(session: session)
              else if (session.activeLearner != null)
                _JourneySummary(learner: session.activeLearner!),
            ],
          ),
        );
      },
    );
  }

  Future<void> _switchLearner(LearnerProfile learner) async {
    final previousId = _selectedLearnerId;
    setState(() {
      _selectedLearnerId = learner.id;
      _switchingLearnerId = learner.id;
    });
    try {
      await _repository.setActiveLearner(_user, learner.id);
      if (!mounted) return;
      setState(() {
        _switchingLearnerId = null;
        _reload();
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${learner.name} is now active.')));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _selectedLearnerId = previousId;
        _switchingLearnerId = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Learner could not be switched. Try again.')),
      );
    }
  }

  Future<void> _addLearner(AccountSession session) async {
    final result = await showDialog<_LearnerInput>(
      context: context,
      builder: (context) => const _AddLearnerDialog(),
    );
    if (result == null) return;
    await _repository.addLearner(
      user: _user,
      session: session,
      name: result.name,
      grade: result.grade,
      country: session.ownerCountry,
      school: result.school,
    );
    if (mounted) setState(() => _reload());
  }

  Future<void> _editOwner(AccountSession session) async {
    final name = TextEditingController(text: session.ownerName);
    final country = TextEditingController(text: session.ownerCountry);
    final school = TextEditingController(text: session.schoolName);
    final save = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit account profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: country,
              decoration: const InputDecoration(labelText: 'Country'),
            ),
            if (session.role == AccountRole.school) ...[
              const SizedBox(height: 14),
              TextField(
                controller: school,
                decoration: const InputDecoration(labelText: 'School'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (save == true && name.text.trim().isNotEmpty) {
      await _repository.updateOwner(
        user: _user,
        name: name.text.trim(),
        country: country.text.trim(),
        schoolName: session.role == AccountRole.school
            ? school.text.trim()
            : null,
      );
      if (mounted) setState(() => _reload());
    }
    name.dispose();
    country.dispose();
    school.dispose();
  }
}

class LearnerProfilePage extends StatelessWidget {
  const LearnerProfilePage({required this.learnerId, super.key});

  final String learnerId;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return FutureBuilder<AccountSession>(
      future: AccountRepository(FirebaseFirestore.instance).load(user),
      builder: (context, snapshot) {
        final session = snapshot.data;
        LearnerProfile? learner;
        for (final item in session?.learners ?? const <LearnerProfile>[]) {
          if (item.id == learnerId) learner = item;
        }
        if (snapshot.connectionState != ConnectionState.done) {
          return const AlliamPage(
            title: 'Learner profile',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (learner == null) {
          return AlliamPage(
            title: 'Learner not found',
            child: FilledButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Back to profile'),
            ),
          );
        }
        return AlliamPage(
          title: learner.name,
          subtitle: '${learner.grade} · ${learner.country}',
          backLocation: '/profile',
          child: Column(
            children: [
              _JourneySummary(learner: learner),
              const SizedBox(height: 22),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Learning journey',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const SizedBox(height: 14),
              _LearningPath(learner: learner),
            ],
          ),
        );
      },
    );
  }
}

class _OwnerCard extends StatelessWidget {
  const _OwnerCard({
    required this.session,
    required this.user,
    required this.onEdit,
  });

  final AccountSession session;
  final User user;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return _ProfileSurface(
      child: Row(
        children: [
          CircleAvatar(
            radius: 31,
            backgroundColor: AlliamColors.coralSoft,
            foregroundColor: AlliamColors.coral,
            child: Text(
              session.ownerName.characters.first.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 22),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.ownerName,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 5),
                Text(user.email ?? 'Demo account'),
                const SizedBox(height: 5),
                Text(switch (session.role) {
                  AccountRole.parent => 'Parent account',
                  AccountRole.school => session.schoolName,
                  _ => 'Learner account',
                }, style: const TextStyle(color: AlliamColors.coral)),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 17),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _LearnersCard extends StatelessWidget {
  const _LearnersCard({
    required this.session,
    required this.activeLearnerId,
    required this.switchingLearnerId,
    required this.onAdd,
    required this.onView,
    required this.onSwitch,
  });

  final AccountSession session;
  final String? activeLearnerId;
  final String? switchingLearnerId;
  final VoidCallback onAdd;
  final ValueChanged<LearnerProfile> onView;
  final ValueChanged<LearnerProfile> onSwitch;

  @override
  Widget build(BuildContext context) {
    return _ProfileSurface(
      child: Column(
        children: [
          Row(
            children: [
              Text('Learners', style: Theme.of(context).textTheme.titleLarge),
              const Spacer(),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add learner'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final learner in session.learners) ...[
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AlliamColors.surfaceStrong,
                    child: Text(learner.avatar),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          learner.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(learner.grade),
                      ],
                    ),
                  ),
                  if (activeLearnerId == learner.id)
                    Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Chip(
                        avatar: switchingLearnerId == learner.id
                            ? const SizedBox.square(
                                dimension: 13,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_rounded, size: 15),
                        label: Text(
                          switchingLearnerId == learner.id
                              ? 'Switching'
                              : 'Active',
                        ),
                      ),
                    )
                  else
                    TextButton(
                      onPressed: () => onSwitch(learner),
                      child: const Text('Switch'),
                    ),
                  OutlinedButton(
                    onPressed: () => onView(learner),
                    child: const Text('View learner'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JourneySummary extends StatelessWidget {
  const _JourneySummary({required this.learner});

  final LearnerProfile learner;

  int _int(String key) => (learner.journey[key] as num?)?.round() ?? 0;

  @override
  Widget build(BuildContext context) {
    final stats = [
      ('Accuracy', '${_int('accuracy')}%'),
      ('Sessions', '${_int('sessions')}'),
      ('Words practised', '${_int('wordsPractised')}'),
      ('Best streak', '${_int('bestStreak')}'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) => Wrap(
        spacing: 14,
        runSpacing: 14,
        children: [
          for (final stat in stats)
            SizedBox(
              width: constraints.maxWidth > 700
                  ? (constraints.maxWidth - 42) / 4
                  : (constraints.maxWidth - 14) / 2,
              child: _ProfileSurface(
                compact: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(stat.$1),
                    const SizedBox(height: 7),
                    Text(
                      stat.$2,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LearningPath extends StatelessWidget {
  const _LearningPath({required this.learner});

  final LearnerProfile learner;

  @override
  Widget build(BuildContext context) {
    final lastMode = learner.journey['lastMode']?.toString() ?? 'Hear & Spell';
    final stage = LearnerPathway.stage(learner.journey['stage']?.toString());
    final stageSessions =
        (learner.journey['stageSessions'] as num?)?.round() ?? 0;
    final progress = stage.sessionsRequired == 0
        ? 1.0
        : (stageSessions / stage.sessionsRequired).clamp(0.0, 1.0);
    final review = learner.journey['reviewWords'] is List
        ? List<String>.from(learner.journey['reviewWords'] as List)
        : const <String>[];
    return _ProfileSurface(
      child: Column(
        children: [
          _PathRow(
            icon: Icons.route_outlined,
            title: '${learner.grade} · ${stage.label}',
            body:
                '$stageSessions of ${stage.sessionsRequired} pathway sessions',
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              color: AlliamColors.coral,
              backgroundColor: AlliamColors.line,
            ),
          ),
          const Divider(height: 30),
          _PathRow(
            icon: Icons.fitness_center_rounded,
            title: 'Current focus',
            body: lastMode,
          ),
          const Divider(),
          const _PathRow(
            icon: Icons.check_rounded,
            title: 'Learn the word',
            body: 'Pronunciation, spelling, and meaning',
          ),
          const Divider(),
          const _PathRow(
            icon: Icons.trending_up_rounded,
            title: 'Build reliable recall',
            body: 'Spell with fewer visual prompts',
          ),
          if (review.isNotEmpty) ...[
            const Divider(),
            _PathRow(
              icon: Icons.replay_rounded,
              title: 'Needs attention',
              body: review.take(5).join(' · '),
            ),
          ],
        ],
      ),
    );
  }
}

class _SchoolSummary extends StatelessWidget {
  const _SchoolSummary({required this.session});

  final AccountSession session;

  @override
  Widget build(BuildContext context) => _ProfileSurface(
    child: Column(
      children: [
        const Icon(Icons.school_outlined, color: AlliamColors.coral, size: 44),
        const SizedBox(height: 14),
        Text(session.schoolName, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        const Text('Roster and staff management will live in the School hub.'),
      ],
    ),
  );
}

class _PathRow extends StatelessWidget {
  const _PathRow({required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(
      children: [
        Icon(icon, color: AlliamColors.coral),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(body),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileSurface extends StatelessWidget {
  const _ProfileSurface({required this.child, this.compact = false});

  final Widget child;
  final bool compact;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(compact ? 22 : 28),
    decoration: BoxDecoration(
      color: AlliamColors.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AlliamColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x35D7B69B),
          blurRadius: 26,
          offset: Offset(8, 14),
        ),
      ],
    ),
    child: child,
  );
}

class _LearnerInput {
  const _LearnerInput(this.name, this.grade, this.school);
  final String name;
  final String grade;
  final String school;
}

class _AddLearnerDialog extends StatefulWidget {
  const _AddLearnerDialog();

  @override
  State<_AddLearnerDialog> createState() => _AddLearnerDialogState();
}

class _AddLearnerDialogState extends State<_AddLearnerDialog> {
  final name = TextEditingController();
  final school = TextEditingController();
  String grade = 'Grade 1';

  @override
  void dispose() {
    name.dispose();
    school.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add learner'),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Name or nickname'),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: grade,
          decoration: const InputDecoration(labelText: 'Grade'),
          items: [
            for (var index = 1; index <= 12; index++)
              DropdownMenuItem(
                value: 'Grade $index',
                child: Text('Grade $index'),
              ),
          ],
          onChanged: (value) => setState(() => grade = value ?? grade),
        ),
        const SizedBox(height: 14),
        TextField(
          controller: school,
          decoration: const InputDecoration(labelText: 'School (optional)'),
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () {
          if (name.text.trim().isEmpty) return;
          Navigator.pop(
            context,
            _LearnerInput(name.text.trim(), grade, school.text.trim()),
          );
        },
        child: const Text('Add learner'),
      ),
    ],
  );
}
