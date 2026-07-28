import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/alliam_page.dart';
import '../../auth/data/account_repository.dart';
import '../data/organization_management_repository.dart';
import '../data/organization_repository.dart';

class OrganizationManagementPage extends StatelessWidget {
  const OrganizationManagementPage({required this.section, super.key});

  final String section;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final firestore = FirebaseFirestore.instance;
    return FutureBuilder<({String organizationId, OrganizationAccess? access})>(
      future: _load(user, firestore),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return AlliamPage(
            title: _title,
            backLocation: '/organization',
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        final data = snapshot.data!;
        final permission = _permission;
        if (data.access == null ||
            (permission != null && !data.access!.can(permission))) {
          return AlliamPage(
            title: _title,
            backLocation: '/organization',
            child: const Center(
              child: Text('You do not have permission to manage this area.'),
            ),
          );
        }
        final repository = OrganizationManagementRepository(firestore);
        final content = switch (section) {
          'learners' => _LearnersSection(
            organizationId: data.organizationId,
            repository: repository,
            userId: user.uid,
          ),
          'teams' => _TeamsSection(
            organizationId: data.organizationId,
            repository: repository,
            userId: user.uid,
          ),
          'competitions' => _CompetitionsSection(
            organizationId: data.organizationId,
            repository: repository,
            userId: user.uid,
          ),
          'invitations' => _InvitationsSection(
            organizationId: data.organizationId,
            repository: repository,
            userId: user.uid,
          ),
          _ => const Center(child: Text('This area is not available.')),
        };
        return AlliamPage(
          title: _title,
          subtitle: 'Organisation management',
          backLocation: '/organization',
          child: content,
        );
      },
    );
  }

  String get _title => switch (section) {
    'learners' => 'Learners',
    'teams' => 'Teams',
    'competitions' => 'Competitions',
    'invitations' => 'Invitations',
    _ => 'Organisation',
  };

  String? get _permission => switch (section) {
    'learners' => 'manageLearners',
    'teams' => 'manageTeams',
    'competitions' => 'manageCompetitions',
    'invitations' => 'manageMembers',
    _ => null,
  };

  Future<({String organizationId, OrganizationAccess? access})> _load(
    User user,
    FirebaseFirestore firestore,
  ) async {
    final session = await AccountRepository(firestore).load(user);
    final organizationId = session.organizationId ?? user.uid;
    final access = await OrganizationRepository(
      firestore,
    ).loadAccess(user: user, organizationId: organizationId);
    return (organizationId: organizationId, access: access);
  }
}

class _LearnersSection extends StatelessWidget {
  const _LearnersSection({
    required this.organizationId,
    required this.repository,
    required this.userId,
  });

  final String organizationId;
  final OrganizationManagementRepository repository;
  final String userId;

  @override
  Widget build(BuildContext context) => _ResourceSection<OrganizationLearner>(
    stream: repository.watchLearners(organizationId),
    empty: 'No learners have been added yet.',
    actionLabel: 'Add learner',
    onAction: () async {
      final values = await _twoFieldDialog(
        context,
        title: 'Add learner',
        firstLabel: 'Learner name',
        secondLabel: 'Grade',
      );
      if (values == null) return;
      await repository.addLearner(
        organizationId: organizationId,
        name: values.$1,
        grade: values.$2,
        actorUid: userId,
      );
    },
    itemBuilder: (context, learner) => ListTile(
      leading: CircleAvatar(child: Text(learner.name[0].toUpperCase())),
      title: Text(learner.name),
      subtitle: Text(
        '${learner.grade} · ${_trainingTime(learner.trainingSeconds)} training · '
        '${learner.sessions} sessions · ${learner.accuracy}% accuracy\n'
        '${learner.wordsAttempted} words · streak ${learner.currentStreak} · '
        '${_lastActive(learner.lastActive)} · '
        '${learner.competitionCount} competitions',
      ),
      isThreeLine: true,
      trailing: Wrap(
        spacing: 5,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(label: Text(learner.readinessLabel)),
          PopupMenuButton<String>(
            onSelected: (status) => repository.setLearnerStatus(
              organizationId: organizationId,
              learnerId: learner.id,
              status: status,
            ),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'active', child: Text('Mark active')),
              PopupMenuItem(value: 'inactive', child: Text('Mark inactive')),
            ],
          ),
        ],
      ),
    ),
  );
}

class _TeamsSection extends StatelessWidget {
  const _TeamsSection({
    required this.organizationId,
    required this.repository,
    required this.userId,
  });

  final String organizationId;
  final OrganizationManagementRepository repository;
  final String userId;

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<List<OrganizationLearner>>(
    stream: repository.watchLearners(organizationId),
    builder: (context, learnerSnapshot) {
      final learners = learnerSnapshot.data ?? const <OrganizationLearner>[];
      return _ResourceSection<OrganizationTeam>(
        stream: repository.watchTeams(organizationId),
        empty: 'No teams have been created yet.',
        actionLabel: 'Create team',
        onAction: () async {
          final result = await _teamDialog(context, learners: learners);
          if (result == null) return;
          await repository.createTeam(
            organizationId: organizationId,
            name: result.$1,
            learnerIds: result.$2,
            actorUid: userId,
          );
        },
        itemBuilder: (context, team) {
          final members = learners
              .where((learner) => team.learnerIds.contains(learner.id))
              .toList();
          final totalSeconds = members.fold<int>(
            0,
            (total, learner) => total + learner.trainingSeconds,
          );
          final averageAccuracy = members.isEmpty
              ? 0
              : (members.fold<int>(
                          0,
                          (total, learner) => total + learner.accuracy,
                        ) /
                        members.length)
                    .round();
          final readiness = _teamReadiness(members, averageAccuracy);
          return ListTile(
            leading: const CircleAvatar(child: Icon(Icons.groups_outlined)),
            title: Text(team.name),
            subtitle: Text(
              '${members.length} members · ${_trainingTime(totalSeconds)} training · '
              '$averageAccuracy% average accuracy',
            ),
            trailing: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Chip(label: Text(readiness)),
                IconButton(
                  tooltip: 'Assign learners',
                  icon: const Icon(Icons.group_add_outlined),
                  onPressed: () async {
                    final result = await _teamDialog(
                      context,
                      learners: learners,
                      name: team.name,
                      selected: team.learnerIds,
                    );
                    if (result == null) return;
                    await repository.updateTeamLearners(
                      organizationId: organizationId,
                      teamId: team.id,
                      learnerIds: result.$2,
                    );
                  },
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _CompetitionsSection extends StatelessWidget {
  const _CompetitionsSection({
    required this.organizationId,
    required this.repository,
    required this.userId,
  });

  final String organizationId;
  final OrganizationManagementRepository repository;
  final String userId;

  @override
  Widget build(
    BuildContext context,
  ) => _ResourceSection<OrganizationCompetition>(
    stream: repository.watchCompetitions(organizationId),
    empty: 'No competitions have been created yet.',
    actionLabel: 'Create competition',
    onAction: () async {
      final result = await _competitionDialog(context);
      if (result == null) return;
      final id = await repository.createCompetition(
        organizationId: organizationId,
        name: result.$1,
        actorUid: userId,
        template: result.$2,
        year: result.$3,
        capacity: result.$4,
      );
      if (context.mounted) {
        context.go('/organization/competitions/$id');
      }
    },
    itemBuilder: (context, competition) => ListTile(
      leading: const CircleAvatar(child: Icon(Icons.emoji_events_outlined)),
      title: Text('${competition.name} · ${competition.year}'),
      subtitle: Text(
        '${competition.status} · ${_managementLabel(competition.template)} · '
        '${competition.participantOrganizationIds.length} participating organisation(s)',
      ),
      onTap: () => context.go('/organization/competitions/${competition.id}'),
      trailing: Wrap(
        children: [
          IconButton(
            tooltip: 'Add participating organisation',
            icon: const Icon(Icons.add_business_outlined),
            onPressed: () async {
              final participantId = await _oneFieldDialog(
                context,
                title: 'Add participating organisation',
                label: 'Organisation ID',
              );
              if (participantId == null) return;
              await repository.addParticipatingOrganization(
                organizationId: organizationId,
                competitionId: competition.id,
                participantOrganizationId: participantId,
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'duplicate') {
                final id = await repository.duplicateCompetition(
                  organizationId: organizationId,
                  source: competition,
                  actorUid: userId,
                );
                if (context.mounted) {
                  context.go('/organization/competitions/$id');
                }
                return;
              }
              await repository.setCompetitionStatus(
                organizationId: organizationId,
                competitionId: competition.id,
                status: value,
              );
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'duplicate',
                child: Text('Duplicate for next year'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(value: 'draft', child: Text('Move to draft')),
              PopupMenuItem(
                value: 'registration',
                child: Text('Open registration'),
              ),
              PopupMenuItem(value: 'active', child: Text('Start competition')),
              PopupMenuItem(value: 'completed', child: Text('Complete')),
              PopupMenuItem(value: 'cancelled', child: Text('Cancel')),
            ],
          ),
        ],
      ),
    ),
  );
}

class _InvitationsSection extends StatelessWidget {
  const _InvitationsSection({
    required this.organizationId,
    required this.repository,
    required this.userId,
  });

  final String organizationId;
  final OrganizationManagementRepository repository;
  final String userId;

  @override
  Widget build(BuildContext context) =>
      _ResourceSection<OrganizationInvitation>(
        stream: repository.watchInvitations(organizationId),
        empty: 'No invitations have been created yet.',
        actionLabel: 'Create invitation',
        onAction: () async {
          final result = await _invitationDialog(context);
          if (result == null) return;
          await repository.invite(
            organizationId: organizationId,
            email: result.$1,
            kind: result.$2,
            role: result.$3,
            actorUid: userId,
          );
        },
        itemBuilder: (context, invitation) => ListTile(
          leading: const CircleAvatar(child: Icon(Icons.mail_outline)),
          title: Text(invitation.email),
          subtitle: Text('${invitation.kind} · ${invitation.status}'),
          trailing: invitation.status == 'pending'
              ? TextButton(
                  onPressed: () => repository.setInvitationStatus(
                    organizationId: organizationId,
                    invitationId: invitation.id,
                    status: 'cancelled',
                  ),
                  child: const Text('Cancel'),
                )
              : null,
        ),
      );
}

// Retained for a later permissions slice; intentionally not exposed.
// ignore: unused_element
class _StaffSection extends StatelessWidget {
  const _StaffSection({
    required this.organizationId,
    required this.repository,
    required this.currentUserId,
  });

  final String organizationId;
  final OrganizationManagementRepository repository;
  final String currentUserId;

  @override
  Widget build(BuildContext context) => _ResourceSection<OrganizationMember>(
    stream: repository.watchMembers(organizationId),
    empty: 'No active staff members.',
    actionLabel: 'Invite staff',
    onAction: () async {
      final result = await _invitationDialog(context, staffOnly: true);
      if (result == null) return;
      await repository.invite(
        organizationId: organizationId,
        email: result.$1,
        kind: 'staff',
        role: result.$3,
        actorUid: currentUserId,
      );
    },
    itemBuilder: (context, member) => ListTile(
      leading: CircleAvatar(
        child: Text(
          (member.name.isEmpty ? member.email : member.name)[0].toUpperCase(),
        ),
      ),
      title: Text(member.name.isEmpty ? member.email : member.name),
      subtitle: Text('${member.role} · ${member.status}'),
      trailing: member.role == 'owner'
          ? const Chip(label: Text('Owner'))
          : IconButton(
              tooltip: 'Edit permissions',
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () async {
                final result = await _permissionDialog(context, member);
                if (result == null) return;
                await repository.updateMember(
                  organizationId: organizationId,
                  memberId: member.id,
                  role: result.$1,
                  permissions: result.$2,
                );
              },
            ),
    ),
  );
}

class _ResourceSection<T> extends StatelessWidget {
  const _ResourceSection({
    required this.stream,
    required this.empty,
    required this.actionLabel,
    required this.onAction,
    required this.itemBuilder,
  });

  final Stream<List<T>> stream;
  final String empty;
  final String actionLabel;
  final Future<void> Function() onAction;
  final Widget Function(BuildContext, T) itemBuilder;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: FilledButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add_rounded),
          label: Text(actionLabel),
        ),
      ),
      const SizedBox(height: 18),
      StreamBuilder<List<T>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('This information could not be loaded.'),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Center(child: Text(empty)),
              ),
            );
          }
          return Card(
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  itemBuilder(context, items[index]),
            ),
          );
        },
      ),
    ],
  );
}

Future<String?> _oneFieldDialog(
  BuildContext context, {
  required String title,
  required String label,
}) async {
  final controller = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (controller.text.trim().isNotEmpty) {
              Navigator.pop(context, controller.text.trim());
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<(String, String)?> _twoFieldDialog(
  BuildContext context, {
  required String title,
  required String firstLabel,
  required String secondLabel,
}) async {
  final first = TextEditingController();
  final second = TextEditingController();
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: first,
            autofocus: true,
            decoration: InputDecoration(labelText: firstLabel),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: second,
            decoration: InputDecoration(labelText: secondLabel),
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
            if (first.text.trim().isNotEmpty) {
              Navigator.pop(context, (first.text.trim(), second.text.trim()));
            }
          },
          child: const Text('Save'),
        ),
      ],
    ),
  );
  first.dispose();
  second.dispose();
  return result;
}

Future<(String, List<String>)?> _teamDialog(
  BuildContext context, {
  required List<OrganizationLearner> learners,
  String name = '',
  List<String> selected = const [],
}) async {
  final controller = TextEditingController(text: name);
  final chosen = selected.toSet();
  final result = await showDialog<(String, List<String>)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(name.isEmpty ? 'Create team' : 'Assign learners'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Team name'),
              ),
              const SizedBox(height: 12),
              for (final learner in learners)
                CheckboxListTile(
                  value: chosen.contains(learner.id),
                  title: Text(learner.name),
                  subtitle: Text(learner.grade),
                  onChanged: (value) => setDialogState(
                    () => value == true
                        ? chosen.add(learner.id)
                        : chosen.remove(learner.id),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                Navigator.pop(context, (
                  controller.text.trim(),
                  chosen.toList(),
                ));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  controller.dispose();
  return result;
}

Future<(String, String, String)?> _invitationDialog(
  BuildContext context, {
  bool staffOnly = false,
}) async {
  final email = TextEditingController();
  var kind = staffOnly ? 'staff' : 'organization';
  var role = 'coach';
  final result = await showDialog<(String, String, String)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Create invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            if (!staffOnly) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: kind,
                decoration: const InputDecoration(labelText: 'Invitation type'),
                items: const [
                  DropdownMenuItem(
                    value: 'organization',
                    child: Text('Participating organisation'),
                  ),
                  DropdownMenuItem(value: 'learner', child: Text('Learner')),
                ],
                onChanged: (value) =>
                    setDialogState(() => kind = value ?? kind),
              ),
            ],
            if (staffOnly) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Staff role'),
                items: const [
                  DropdownMenuItem(value: 'coach', child: Text('Coach')),
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  DropdownMenuItem(
                    value: 'organizationAdmin',
                    child: Text('Organisation admin'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => role = value ?? role),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = email.text.trim();
              if (value.contains('@')) {
                Navigator.pop(context, (value, kind, role));
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
  email.dispose();
  return result;
}

Future<(String, Map<String, bool>)?> _permissionDialog(
  BuildContext context,
  OrganizationMember member,
) async {
  var role = member.role;
  final permissions = {
    'manageLearners': member.permissions['manageLearners'] == true,
    'manageTeams': member.permissions['manageTeams'] == true,
    'manageCompetitions': member.permissions['manageCompetitions'] == true,
    'manageMembers': member.permissions['manageMembers'] == true,
    'manageOrganization': member.permissions['manageOrganization'] == true,
  };
  return showDialog<(String, Map<String, bool>)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Staff permissions'),
        content: SizedBox(
          width: 420,
          child: ListView(
            shrinkWrap: true,
            children: [
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'coach', child: Text('Coach')),
                  DropdownMenuItem(value: 'staff', child: Text('Staff')),
                  DropdownMenuItem(
                    value: 'organizationAdmin',
                    child: Text('Organisation admin'),
                  ),
                ],
                onChanged: (value) =>
                    setDialogState(() => role = value ?? role),
              ),
              for (final permission in permissions.keys)
                CheckboxListTile(
                  value: permissions[permission],
                  title: Text(_permissionLabel(permission)),
                  onChanged: (value) => setDialogState(
                    () => permissions[permission] = value == true,
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, (role, permissions)),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

String _permissionLabel(String permission) => switch (permission) {
  'manageLearners' => 'Manage learners',
  'manageTeams' => 'Manage teams',
  'manageCompetitions' => 'Manage competitions',
  'manageMembers' => 'Manage staff and invitations',
  'manageOrganization' => 'Manage organisation settings',
  _ => permission,
};

Future<(String, String, int, int)?> _competitionDialog(
  BuildContext context,
) async {
  final name = TextEditingController();
  final year = TextEditingController(text: '${DateTime.now().year}');
  final capacity = TextEditingController(text: '100');
  var template = 'spellingBee';
  final result = await showDialog<(String, String, int, int)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Create competition'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Competition name'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: template,
              decoration: const InputDecoration(labelText: 'Template'),
              items: const [
                DropdownMenuItem(
                  value: 'spellingBee',
                  child: Text('Spelling bee'),
                ),
                DropdownMenuItem(
                  value: 'interSchool',
                  child: Text('Inter-school competition'),
                ),
                DropdownMenuItem(
                  value: 'knockout',
                  child: Text('Knockout tournament'),
                ),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text('Custom competition'),
                ),
              ],
              onChanged: (value) =>
                  setDialogState(() => template = value ?? template),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: year,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Year'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: capacity,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Capacity'),
                  ),
                ),
              ],
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
              Navigator.pop(context, (
                name.text.trim(),
                template,
                int.tryParse(year.text) ?? DateTime.now().year,
                int.tryParse(capacity.text) ?? 0,
              ));
            },
            child: const Text('Create'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  year.dispose();
  capacity.dispose();
  return result;
}

String _managementLabel(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced.isEmpty
      ? spaced
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _trainingTime(int seconds) {
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
}

String _lastActive(DateTime? value) {
  if (value == null) return 'Never active';
  final days = DateTime.now().difference(value).inDays;
  return switch (days) {
    <= 0 => 'Active today',
    1 => 'Active yesterday',
    _ => 'Active $days days ago',
  };
}

String _teamReadiness(List<OrganizationLearner> members, int averageAccuracy) {
  if (members.isEmpty) return 'Needs practice';
  final averageScore =
      members.fold<int>(
        0,
        (total, learner) => total + learner.readinessScore,
      ) ~/
      members.length;
  final score = ((averageScore + averageAccuracy) / 2).round();
  return switch (score) {
    >= 85 => 'Excellent',
    >= 70 => 'Good',
    >= 50 => 'Fair',
    _ => 'Needs practice',
  };
}
