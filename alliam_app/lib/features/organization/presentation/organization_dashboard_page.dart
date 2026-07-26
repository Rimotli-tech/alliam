import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_page.dart';
import '../../auth/data/account_repository.dart';
import '../../auth/domain/account_session.dart';
import '../data/organization_repository.dart';
import '../data/organization_management_repository.dart';

class OrganizationDashboardPage extends StatelessWidget {
  const OrganizationDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const AlliamPage(
        title: 'Organisation',
        child: Center(child: Text('Sign in to continue.')),
      );
    }
    return FutureBuilder<
      ({AccountSession session, OrganizationAccess? access})
    >(
      future: _load(user),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AlliamPage(
            title: 'Organisation',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final session = snapshot.data?.session;
        if (session?.role != AccountRole.organization) {
          return const AlliamPage(
            title: 'Organisation',
            child: Center(child: Text('Organisation access is required.')),
          );
        }
        final access = snapshot.data?.access;
        if (access == null) {
          return const AlliamPage(
            title: 'Organisation',
            child: Center(child: Text('Organisation membership is required.')),
          );
        }
        return AlliamPage(
          title: session!.organizationName.isEmpty
              ? 'Organisation dashboard'
              : session.organizationName,
          subtitle: 'Competition organisation · ${access.role}',
          showBack: false,
          child: _DashboardContent(
            organizationId: access.organizationId,
            access: access,
          ),
        );
      },
    );
  }

  static const _destinations = [
    (
      Icons.school_outlined,
      'Learners',
      'Create and manage the organisation roster.',
      'learners',
      'manageLearners',
    ),
    (
      Icons.groups_outlined,
      'Teams',
      'Group learners for training and competition.',
      'teams',
      'manageTeams',
    ),
    (
      Icons.emoji_events_outlined,
      'Competitions',
      'Create fixtures, rooms, and competition formats.',
      'competitions',
      'manageCompetitions',
    ),
    (
      Icons.mail_outline_rounded,
      'Invitations',
      'Invite learners, coaches, and participating organisations.',
      'invitations',
      'manageMembers',
    ),
    (
      Icons.settings_outlined,
      'Staff & permissions',
      'Invite staff and manage role-based access.',
      'staff',
      'manageMembers',
    ),
  ];

  Future<({AccountSession session, OrganizationAccess? access})> _load(
    User user,
  ) async {
    final firestore = FirebaseFirestore.instance;
    final session = await AccountRepository(firestore).load(user);
    final organizationId = session.organizationId ?? user.uid;
    final access = await OrganizationRepository(
      firestore,
    ).loadAccess(user: user, organizationId: organizationId);
    return (session: session, access: access);
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.organizationId, required this.access});

  final String organizationId;
  final OrganizationAccess access;

  @override
  Widget build(BuildContext context) {
    final repository = OrganizationManagementRepository(
      FirebaseFirestore.instance,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _Metric(
              label: 'Learners',
              stream: repository
                  .watchLearners(organizationId)
                  .map((items) => items.length),
            ),
            _Metric(
              label: 'Teams',
              stream: repository
                  .watchTeams(organizationId)
                  .map((items) => items.length),
            ),
            _Metric(
              label: 'Competitions',
              stream: repository
                  .watchCompetitions(organizationId)
                  .map((items) => items.length),
            ),
            _Metric(
              label: 'Invitations',
              stream: repository
                  .watchInvitations(organizationId)
                  .map((items) => items.length),
            ),
          ],
        ),
        const SizedBox(height: 22),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth > 760
                ? (constraints.maxWidth - 16) / 2
                : constraints.maxWidth;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final destination
                    in OrganizationDashboardPage._destinations)
                  SizedBox(
                    width: width,
                    child: _OrganizationDestination(
                      icon: destination.$1,
                      title: destination.$2,
                      body: destination.$3,
                      enabled: access.can(destination.$5),
                      onTap: () =>
                          context.go('/organization/${destination.$4}'),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 22),
        Text('Recent activity', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        StreamBuilder<List<OrganizationActivity>>(
          stream: repository.watchActivity(organizationId),
          builder: (context, snapshot) {
            final items = snapshot.data ?? const <OrganizationActivity>[];
            return Card(
              child: items.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Activity will appear here as work begins.'),
                    )
                  : Column(
                      children: [
                        for (final item in items)
                          ListTile(
                            leading: const Icon(Icons.history_rounded),
                            title: Text(item.message),
                            subtitle: item.createdAt == null
                                ? null
                                : Text(
                                    '${item.createdAt!.day}/${item.createdAt!.month}/${item.createdAt!.year}',
                                  ),
                          ),
                      ],
                    ),
            );
          },
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.stream});

  final String label;
  final Stream<int> stream;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 160,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            StreamBuilder<int>(
              stream: stream,
              builder: (context, snapshot) => Text(
                '${snapshot.data ?? 0}',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class _OrganizationDestination extends StatelessWidget {
  const _OrganizationDestination({
    required this.icon,
    required this.title,
    required this.body,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : 0.5,
    child: Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: AlliamColors.coralSoft,
                foregroundColor: AlliamColors.coral,
                child: Icon(icon),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 5),
                    Text(body),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    ),
  );
}
