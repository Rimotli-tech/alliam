import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_page.dart';
import '../../auth/data/account_repository.dart';
import '../../auth/domain/account_session.dart';
import '../data/organization_repository.dart';

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 760
                  ? (constraints.maxWidth - 16) / 2
                  : constraints.maxWidth;
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  for (final destination in _destinations)
                    SizedBox(
                      width: width,
                      child: _OrganizationDestination(
                        icon: destination.$1,
                        title: destination.$2,
                        body: destination.$3,
                        count: destination.$2 == 'Learners'
                            ? session.learners.length
                            : null,
                        enabled: switch (destination.$2) {
                          'Learners' => access.can('manageLearners'),
                          'Teams' => access.can('manageTeams'),
                          'Competitions' => access.can('manageCompetitions'),
                          'Organisation settings' => access.can(
                            'manageOrganization',
                          ),
                          _ => true,
                        },
                      ),
                    ),
                ],
              );
            },
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
    ),
    (
      Icons.groups_outlined,
      'Teams',
      'Group learners for training and competition.',
    ),
    (
      Icons.emoji_events_outlined,
      'Competitions',
      'Create fixtures, rooms, and competition formats.',
    ),
    (
      Icons.mail_outline_rounded,
      'Invitations',
      'Invite learners, coaches, and participating organisations.',
    ),
    (
      Icons.settings_outlined,
      'Organisation settings',
      'Manage identity, staff access, and competition defaults.',
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

class _OrganizationDestination extends StatelessWidget {
  const _OrganizationDestination({
    required this.icon,
    required this.title,
    required this.body,
    this.count,
    required this.enabled,
  });

  final IconData icon;
  final String title;
  final String body;
  final int? count;
  final bool enabled;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: enabled ? 1 : 0.5,
    child: Card(
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
            if (count != null) Chip(label: Text('$count')),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    ),
  );
}
