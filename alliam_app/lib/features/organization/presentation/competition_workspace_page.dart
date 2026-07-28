import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_page.dart';
import '../../auth/data/account_repository.dart';
import '../data/competition_planning_repository.dart';
import '../data/organization_repository.dart';

enum _PlanningArea {
  overview,
  divisions,
  timeline,
  eligibility,
  registration,
  participants,
  budget,
}

class CompetitionWorkspacePage extends StatefulWidget {
  const CompetitionWorkspacePage({required this.competitionId, super.key});

  final String competitionId;

  @override
  State<CompetitionWorkspacePage> createState() =>
      _CompetitionWorkspacePageState();
}

class _CompetitionWorkspacePageState extends State<CompetitionWorkspacePage> {
  _PlanningArea _area = _PlanningArea.overview;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final firestore = FirebaseFirestore.instance;
    return FutureBuilder<({String organizationId, OrganizationAccess? access})>(
      future: _load(user, firestore),
      builder: (context, accessSnapshot) {
        if (!accessSnapshot.hasData) {
          return const AlliamPage(
            title: 'Competition',
            backLocation: '/organization/competitions',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final setup = accessSnapshot.data!;
        if (setup.access?.can('manageCompetitions') != true) {
          return const AlliamPage(
            title: 'Competition',
            backLocation: '/organization/competitions',
            child: Center(
              child: Text('Competition management permission is required.'),
            ),
          );
        }
        final repository = CompetitionPlanningRepository(firestore);
        return StreamBuilder<CompetitionPlan?>(
          stream: repository.watchPlan(
            setup.organizationId,
            widget.competitionId,
          ),
          builder: (context, planSnapshot) {
            final plan = planSnapshot.data;
            if (plan == null) {
              return const AlliamPage(
                title: 'Competition',
                backLocation: '/organization/competitions',
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return AlliamPage(
              title: plan.name,
              subtitle: '${plan.year} · ${_label(plan.status)}',
              backLocation: '/organization/competitions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final area in const [
                        _PlanningArea.overview,
                        _PlanningArea.registration,
                        _PlanningArea.participants,
                      ])
                        ChoiceChip(
                          selected: _area == area,
                          label: Text(_label(area.name)),
                          onSelected: (_) => setState(() => _area = area),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Spacer(),
                      if (plan.status == 'draft' ||
                          plan.status == 'registration')
                        FilledButton.icon(
                          onPressed: () => repository.setCompetitionStatus(
                            organizationId: setup.organizationId,
                            competitionId: plan.id,
                            status: 'active',
                          ),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Start competition'),
                        ),
                      if (plan.status == 'active')
                        FilledButton.icon(
                          onPressed: () => repository.setCompetitionStatus(
                            organizationId: setup.organizationId,
                            competitionId: plan.id,
                            status: 'completed',
                          ),
                          icon: const Icon(Icons.publish_rounded),
                          label: const Text('Publish results'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  switch (_area) {
                    _PlanningArea.overview => _Overview(
                      plan: plan,
                      repository: repository,
                      organizationId: setup.organizationId,
                    ),
                    _PlanningArea.divisions => _Divisions(
                      repository: repository,
                      organizationId: setup.organizationId,
                      competitionId: plan.id,
                    ),
                    _PlanningArea.timeline => _Timeline(
                      repository: repository,
                      organizationId: setup.organizationId,
                      competitionId: plan.id,
                    ),
                    _PlanningArea.eligibility => _Eligibility(
                      plan: plan,
                      repository: repository,
                      organizationId: setup.organizationId,
                    ),
                    _PlanningArea.registration => _Registration(
                      plan: plan,
                      repository: repository,
                      organizationId: setup.organizationId,
                    ),
                    _PlanningArea.participants => _Participants(
                      plan: plan,
                      repository: repository,
                      organizationId: setup.organizationId,
                    ),
                    _PlanningArea.budget => _Budget(
                      plan: plan,
                      repository: repository,
                      organizationId: setup.organizationId,
                    ),
                  },
                ],
              ),
            );
          },
        );
      },
    );
  }

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

class _Overview extends StatelessWidget {
  const _Overview({
    required this.plan,
    required this.repository,
    required this.organizationId,
  });

  final CompetitionPlan plan;
  final CompetitionPlanningRepository repository;
  final String organizationId;

  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Competition overview',
    action: TextButton.icon(
      onPressed: () async {
        final result = await _overviewDialog(context, plan);
        if (result == null) return;
        await repository.updateOverview(
          organizationId: organizationId,
          competitionId: plan.id,
          name: result.$1,
          description: result.$2,
          year: result.$3,
          startDate: result.$4,
          endDate: result.$5,
        );
      },
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Edit'),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          plan.description.isEmpty
              ? 'Add a description for organizers and participants.'
              : plan.description,
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _InfoChip(
              icon: Icons.category_outlined,
              text: _label(plan.template),
            ),
            _InfoChip(
              icon: Icons.calendar_today_outlined,
              text: _dateRange(plan.startDate, plan.endDate),
            ),
            _InfoChip(
              icon: Icons.how_to_reg_outlined,
              text: '${plan.capacity} registration capacity',
            ),
          ],
        ),
      ],
    ),
  );
}

class _Divisions extends StatelessWidget {
  const _Divisions({
    required this.repository,
    required this.organizationId,
    required this.competitionId,
  });

  final CompetitionPlanningRepository repository;
  final String organizationId;
  final String competitionId;

  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Divisions',
    action: FilledButton.icon(
      onPressed: () async {
        final result = await _divisionDialog(context);
        if (result == null) return;
        await repository.addDivision(
          organizationId: organizationId,
          competitionId: competitionId,
          name: result.$1,
          minimumAge: result.$2,
          maximumAge: result.$3,
          capacity: result.$4,
        );
      },
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add division'),
    ),
    child: StreamBuilder<List<CompetitionDivision>>(
      stream: repository.watchDivisions(organizationId, competitionId),
      builder: (context, snapshot) {
        final divisions = snapshot.data ?? const <CompetitionDivision>[];
        if (divisions.isEmpty) {
          return const Text(
            'Create age groups or competitive divisions to organize eligibility.',
          );
        }
        return Column(
          children: [
            for (final division in divisions)
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.layers_outlined)),
                title: Text(division.name),
                subtitle: Text(
                  'Ages ${division.minimumAge}–${division.maximumAge}',
                ),
                trailing: Chip(label: Text('Capacity ${division.capacity}')),
              ),
          ],
        );
      },
    ),
  );
}

class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.repository,
    required this.organizationId,
    required this.competitionId,
  });

  final CompetitionPlanningRepository repository;
  final String organizationId;
  final String competitionId;

  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Timeline & milestones',
    action: FilledButton.icon(
      onPressed: () async {
        final result = await _milestoneDialog(context);
        if (result == null) return;
        await repository.addMilestone(
          organizationId: organizationId,
          competitionId: competitionId,
          title: result.$1,
          dueDate: result.$2,
        );
      },
      icon: const Icon(Icons.add_rounded),
      label: const Text('Add milestone'),
    ),
    child: StreamBuilder<List<CompetitionMilestone>>(
      stream: repository.watchMilestones(organizationId, competitionId),
      builder: (context, snapshot) {
        final milestones = snapshot.data ?? const <CompetitionMilestone>[];
        if (milestones.isEmpty) {
          return const Text(
            'Add registration, outreach, venue, and tournament milestones.',
          );
        }
        return Column(
          children: [
            for (final milestone in milestones)
              CheckboxListTile(
                value: milestone.complete,
                title: Text(milestone.title),
                subtitle: Text(_shortDate(milestone.dueDate)),
                onChanged: (value) => repository.setMilestoneComplete(
                  organizationId: organizationId,
                  competitionId: competitionId,
                  milestoneId: milestone.id,
                  complete: value == true,
                ),
              ),
          ],
        );
      },
    ),
  );
}

class _Eligibility extends StatelessWidget {
  const _Eligibility({
    required this.plan,
    required this.repository,
    required this.organizationId,
  });

  final CompetitionPlan plan;
  final CompetitionPlanningRepository repository;
  final String organizationId;

  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Rules & eligibility',
    action: TextButton.icon(
      onPressed: () async {
        final notes = await _textDialog(
          context,
          title: 'Rules & eligibility',
          label: 'Eligibility rules',
          initial: plan.eligibilityNotes,
          lines: 6,
        );
        if (notes == null) return;
        await repository.updateEligibility(
          organizationId: organizationId,
          competitionId: plan.id,
          notes: notes,
        );
      },
      icon: const Icon(Icons.edit_outlined),
      label: const Text('Edit rules'),
    ),
    child: Text(
      plan.eligibilityNotes.isEmpty
          ? 'Document age, school, division, qualification, and participation rules.'
          : plan.eligibilityNotes,
    ),
  );
}

class _Registration extends StatelessWidget {
  const _Registration({
    required this.plan,
    required this.repository,
    required this.organizationId,
  });

  final CompetitionPlan plan;
  final CompetitionPlanningRepository repository;
  final String organizationId;

  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Registration & approval',
    action: TextButton.icon(
      onPressed: () async {
        final result = await _registrationDialog(context, plan);
        if (result == null) return;
        await repository.updateRegistration(
          organizationId: organizationId,
          competitionId: plan.id,
          capacity: result.$1,
          mode: result.$2,
          approvalRequired: result.$3,
          opensAt: result.$4,
          closesAt: result.$5,
        );
      },
      icon: const Icon(Icons.tune_rounded),
      label: const Text('Configure'),
    ),
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _InfoChip(
          icon: Icons.people_outline,
          text: 'Capacity ${plan.capacity}',
        ),
        _InfoChip(
          icon: Icons.app_registration_outlined,
          text: _label(plan.registrationMode),
        ),
        _InfoChip(
          icon: Icons.approval_outlined,
          text: plan.approvalRequired ? 'Approval required' : 'Auto-approved',
        ),
        const _InfoChip(
          icon: Icons.format_list_numbered_rounded,
          text: 'Waitlist enabled',
        ),
        _InfoChip(
          icon: Icons.date_range_outlined,
          text:
              '${_shortDate(plan.registrationOpensAt)} – '
              '${_shortDate(plan.registrationClosesAt)}',
        ),
      ],
    ),
  );
}

class _Budget extends StatelessWidget {
  const _Budget({
    required this.plan,
    required this.repository,
    required this.organizationId,
  });

  final CompetitionPlan plan;
  final CompetitionPlanningRepository repository;
  final String organizationId;

  @override
  Widget build(BuildContext context) => _Panel(
    title: 'Budget',
    action: Wrap(
      spacing: 8,
      children: [
        TextButton(
          onPressed: () async {
            final result = await _budgetLimitDialog(context, plan);
            if (result == null) return;
            await repository.updateBudget(
              organizationId: organizationId,
              competitionId: plan.id,
              currency: result.$1,
              limit: result.$2,
            );
          },
          child: const Text('Set budget'),
        ),
        FilledButton.icon(
          onPressed: () async {
            final result = await _budgetItemDialog(context);
            if (result == null) return;
            await repository.addBudgetItem(
              organizationId: organizationId,
              competitionId: plan.id,
              name: result.$1,
              category: result.$2,
              amount: result.$3,
            );
          },
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add item'),
        ),
      ],
    ),
    child: StreamBuilder<List<CompetitionBudgetItem>>(
      stream: repository.watchBudgetItems(organizationId, plan.id),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <CompetitionBudgetItem>[];
        final committed = items.fold<double>(
          0,
          (total, item) => total + item.amount,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${plan.currency} ${committed.toStringAsFixed(0)} committed of '
              '${plan.currency} ${plan.budgetLimit.toStringAsFixed(0)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('Add venue, prizes, staffing, media, and logistics.')
            else
              for (final item in items)
                ListTile(
                  title: Text(item.name),
                  subtitle: Text(item.category),
                  trailing: Text(
                    '${plan.currency} ${item.amount.toStringAsFixed(0)}',
                  ),
                ),
          ],
        );
      },
    ),
  );
}

class _Participants extends StatelessWidget {
  const _Participants({
    required this.plan,
    required this.repository,
    required this.organizationId,
  });

  final CompetitionPlan plan;
  final CompetitionPlanningRepository repository;
  final String organizationId;

  @override
  Widget build(
    BuildContext context,
  ) => StreamBuilder<List<CompetitionDivision>>(
    stream: repository.watchDivisions(organizationId, plan.id),
    builder: (context, divisionSnapshot) {
      final divisions = divisionSnapshot.data ?? const <CompetitionDivision>[];
      return StreamBuilder<List<CompetitionRegistration>>(
        stream: repository.watchRegistrations(organizationId, plan.id),
        builder: (context, registrationSnapshot) {
          final registrations =
              registrationSnapshot.data ?? const <CompetitionRegistration>[];
          final approved = registrations
              .where((item) => item.status == 'approved')
              .length;
          final pending = registrations
              .where((item) => item.status == 'pending')
              .length;
          final waitlisted = registrations
              .where((item) => item.status == 'waitlisted')
              .length;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _RegistrationMetric(
                    label: 'Approved',
                    value: '$approved/${plan.capacity}',
                  ),
                  _RegistrationMetric(label: 'Pending', value: '$pending'),
                  _RegistrationMetric(
                    label: 'Waitlisted',
                    value: '$waitlisted',
                  ),
                  _RegistrationMetric(
                    label: 'Total entries',
                    value: '${registrations.length}',
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _Panel(
                title: 'Approved participants',
                action: FilledButton.icon(
                  onPressed: () async {
                    final result = await _registrationEntryDialog(
                      context,
                      divisions,
                    );
                    if (result == null) return;
                    await repository.addRegistration(
                      organizationId: organizationId,
                      competitionId: plan.id,
                      applicantName: result.$1,
                      applicantType: result.$2,
                      contactEmail: result.$3,
                      entryType: result.$4,
                      entryName: result.$5,
                      divisionId: result.$6,
                      divisionName: result.$7,
                      approved: true,
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add participant'),
                ),
                child: registrations.isEmpty
                    ? const Text(
                        'Add approved individual participants and teams.',
                      )
                    : Column(
                        children: [
                          for (final registration in registrations)
                            _RegistrationTile(
                              registration: registration,
                              onEligibility: () async {
                                final result = await _eligibilityReviewDialog(
                                  context,
                                  registration,
                                );
                                if (result == null) return;
                                await repository.reviewEligibility(
                                  organizationId: organizationId,
                                  competitionId: plan.id,
                                  registrationId: registration.id,
                                  eligible: result.$1,
                                  notes: result.$2,
                                );
                              },
                              onStatus: (status) async {
                                if (status == 'approved' &&
                                    registration.eligible != true) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Confirm eligibility before approval.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final applied = await repository
                                    .setRegistrationStatus(
                                      organizationId: organizationId,
                                      competitionId: plan.id,
                                      registrationId: registration.id,
                                      requestedStatus: status,
                                      capacity: plan.capacity,
                                      approvedCount: approved,
                                    );
                                if (context.mounted &&
                                    applied == 'waitlisted') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Capacity reached; entry added to the waitlist.',
                                      ),
                                    ),
                                  );
                                }
                              },
                            ),
                        ],
                      ),
              ),
            ],
          );
        },
      );
    },
  );
}

class _RegistrationMetric extends StatelessWidget {
  const _RegistrationMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 150,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            Text(label),
          ],
        ),
      ),
    ),
  );
}

class _RegistrationTile extends StatelessWidget {
  const _RegistrationTile({
    required this.registration,
    required this.onEligibility,
    required this.onStatus,
  });

  final CompetitionRegistration registration;
  final VoidCallback onEligibility;
  final ValueChanged<String> onStatus;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: CircleAvatar(
      child: Icon(
        registration.entryType == 'team'
            ? Icons.groups_outlined
            : Icons.person_outline_rounded,
      ),
    ),
    title: Text(registration.entryName),
    subtitle: Text(
      '${registration.applicantName} · ${registration.divisionName}\n'
      '${_label(registration.status)} · '
      '${registration.eligible == null
          ? 'Eligibility unreviewed'
          : registration.eligible!
          ? 'Eligible'
          : 'Ineligible'}',
    ),
    isThreeLine: true,
    trailing: Wrap(
      spacing: 4,
      children: [
        IconButton(
          tooltip: 'Review eligibility',
          onPressed: onEligibility,
          icon: const Icon(Icons.fact_check_outlined),
        ),
        PopupMenuButton<String>(
          onSelected: onStatus,
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'approved', child: Text('Approve')),
            PopupMenuItem(value: 'waitlisted', child: Text('Waitlist')),
            PopupMenuItem(value: 'rejected', child: Text('Reject')),
            PopupMenuItem(value: 'pending', child: Text('Return to pending')),
          ],
        ),
      ],
    ),
  );
}

class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.action,
    required this.child,
  });

  final String title;
  final Widget action;
  final Widget child;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              action,
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Chip(
    avatar: Icon(icon, size: 17, color: AlliamColors.coral),
    label: Text(text),
  );
}

Future<(String, String, int, DateTime?, DateTime?)?> _overviewDialog(
  BuildContext context,
  CompetitionPlan plan,
) async {
  final name = TextEditingController(text: plan.name);
  final description = TextEditingController(text: plan.description);
  final year = TextEditingController(text: '${plan.year}');
  DateTime? start = plan.startDate;
  DateTime? end = plan.endDate;
  final result = await showDialog<(String, String, int, DateTime?, DateTime?)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Competition overview'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: description,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: year,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final value = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: start ?? DateTime.now(),
                        );
                        if (value != null) {
                          setDialogState(() => start = value);
                        }
                      },
                      child: Text('Start: ${_shortDate(start)}'),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () async {
                        final value = await showDatePicker(
                          context: context,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2100),
                          initialDate: end ?? start ?? DateTime.now(),
                        );
                        if (value != null) setDialogState(() => end = value);
                      },
                      child: Text('End: ${_shortDate(end)}'),
                    ),
                  ),
                ],
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
            onPressed: () => Navigator.pop(context, (
              name.text.trim(),
              description.text.trim(),
              int.tryParse(year.text) ?? DateTime.now().year,
              start,
              end,
            )),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  description.dispose();
  year.dispose();
  return result;
}

Future<(String, int, int, int)?> _divisionDialog(BuildContext context) async {
  final name = TextEditingController();
  final minimum = TextEditingController();
  final maximum = TextEditingController();
  final capacity = TextEditingController();
  final result = await showDialog<(String, int, int, int)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add division'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Division name'),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: minimum,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Minimum age'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: maximum,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Maximum age'),
                ),
              ),
            ],
          ),
          TextField(
            controller: capacity,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Capacity'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            name.text.trim(),
            int.tryParse(minimum.text) ?? 0,
            int.tryParse(maximum.text) ?? 0,
            int.tryParse(capacity.text) ?? 0,
          )),
          child: const Text('Add'),
        ),
      ],
    ),
  );
  name.dispose();
  minimum.dispose();
  maximum.dispose();
  capacity.dispose();
  return result;
}

Future<(String, DateTime?)?> _milestoneDialog(BuildContext context) async {
  final title = TextEditingController();
  DateTime? dueDate;
  final result = await showDialog<(String, DateTime?)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Add milestone'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              decoration: const InputDecoration(labelText: 'Milestone'),
            ),
            TextButton(
              onPressed: () async {
                final value = await showDatePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                  initialDate: DateTime.now(),
                );
                if (value != null) setDialogState(() => dueDate = value);
              },
              child: Text('Due: ${_shortDate(dueDate)}'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (title.text.trim(), dueDate)),
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
  title.dispose();
  return result;
}

Future<String?> _textDialog(
  BuildContext context, {
  required String title,
  required String label,
  required String initial,
  int lines = 1,
}) async {
  final controller = TextEditingController(text: initial);
  final result = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 460,
        child: TextField(
          controller: controller,
          maxLines: lines,
          decoration: InputDecoration(labelText: label),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  controller.dispose();
  return result;
}

Future<(int, String, bool, DateTime?, DateTime?)?> _registrationDialog(
  BuildContext context,
  CompetitionPlan plan,
) async {
  final capacity = TextEditingController(text: '${plan.capacity}');
  var mode = plan.registrationMode;
  var approval = plan.approvalRequired;
  DateTime? opensAt = plan.registrationOpensAt;
  DateTime? closesAt = plan.registrationClosesAt;
  final result = await showDialog<(int, String, bool, DateTime?, DateTime?)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Registration settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: capacity,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Capacity'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: mode,
              decoration: const InputDecoration(labelText: 'Registration by'),
              items: const [
                DropdownMenuItem(
                  value: 'organization',
                  child: Text('Organisation'),
                ),
                DropdownMenuItem(value: 'school', child: Text('School')),
                DropdownMenuItem(
                  value: 'individual',
                  child: Text('Individual learner'),
                ),
              ],
              onChanged: (value) => setDialogState(() => mode = value ?? mode),
            ),
            SwitchListTile(
              value: approval,
              title: const Text('Require registration approval'),
              onChanged: (value) => setDialogState(() => approval = value),
            ),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final value = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: opensAt ?? DateTime.now(),
                      );
                      if (value != null) {
                        setDialogState(() => opensAt = value);
                      }
                    },
                    child: Text('Opens: ${_shortDate(opensAt)}'),
                  ),
                ),
                Expanded(
                  child: TextButton(
                    onPressed: () async {
                      final value = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        initialDate: closesAt ?? opensAt ?? DateTime.now(),
                      );
                      if (value != null) {
                        setDialogState(() => closesAt = value);
                      }
                    },
                    child: Text('Closes: ${_shortDate(closesAt)}'),
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
            onPressed: () => Navigator.pop(context, (
              int.tryParse(capacity.text) ?? 0,
              mode,
              approval,
              opensAt,
              closesAt,
            )),
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  capacity.dispose();
  return result;
}

Future<(String, double)?> _budgetLimitDialog(
  BuildContext context,
  CompetitionPlan plan,
) async {
  final currency = TextEditingController(text: plan.currency);
  final limit = TextEditingController(text: '${plan.budgetLimit}');
  final result = await showDialog<(String, double)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Competition budget'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: currency,
            decoration: const InputDecoration(labelText: 'Currency'),
          ),
          TextField(
            controller: limit,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Budget limit'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            currency.text.trim(),
            double.tryParse(limit.text) ?? 0,
          )),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  currency.dispose();
  limit.dispose();
  return result;
}

Future<(String, String, double)?> _budgetItemDialog(
  BuildContext context,
) async {
  final name = TextEditingController();
  final category = TextEditingController(text: 'Operations');
  final amount = TextEditingController();
  final result = await showDialog<(String, String, double)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Add budget item'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(labelText: 'Item'),
          ),
          TextField(
            controller: category,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
          TextField(
            controller: amount,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, (
            name.text.trim(),
            category.text.trim(),
            double.tryParse(amount.text) ?? 0,
          )),
          child: const Text('Add'),
        ),
      ],
    ),
  );
  name.dispose();
  category.dispose();
  amount.dispose();
  return result;
}

Future<(String, String, String, String, String, String, String)?>
_registrationEntryDialog(
  BuildContext context,
  List<CompetitionDivision> divisions,
) async {
  final applicant = TextEditingController();
  final email = TextEditingController();
  final entry = TextEditingController();
  var applicantType = 'school';
  var entryType = 'learner';
  var divisionId = divisions.isEmpty ? '' : divisions.first.id;
  String divisionName() {
    for (final division in divisions) {
      if (division.id == divisionId) return division.name;
    }
    return 'Unassigned';
  }

  final result =
      await showDialog<
        (String, String, String, String, String, String, String)
      >(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Add approved participant'),
            content: SizedBox(
              width: 460,
              child: ListView(
                shrinkWrap: true,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: applicantType,
                    decoration: const InputDecoration(
                      labelText: 'Applicant type',
                    ),
                    items: const [
                      DropdownMenuItem(value: 'school', child: Text('School')),
                      DropdownMenuItem(
                        value: 'organization',
                        child: Text('Organisation'),
                      ),
                      DropdownMenuItem(
                        value: 'individual',
                        child: Text('Individual'),
                      ),
                    ],
                    onChanged: (value) => setDialogState(
                      () => applicantType = value ?? applicantType,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: applicant,
                    decoration: const InputDecoration(
                      labelText: 'Applicant name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Contact email',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: entryType,
                    decoration: const InputDecoration(labelText: 'Entry type'),
                    items: const [
                      DropdownMenuItem(
                        value: 'learner',
                        child: Text('Learner'),
                      ),
                      DropdownMenuItem(value: 'team', child: Text('Team')),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => entryType = value ?? entryType),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: entry,
                    decoration: InputDecoration(
                      labelText: entryType == 'team'
                          ? 'Team name'
                          : 'Learner name',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: divisionId.isEmpty ? null : divisionId,
                    decoration: const InputDecoration(labelText: 'Division'),
                    items: [
                      for (final division in divisions)
                        DropdownMenuItem(
                          value: division.id,
                          child: Text(division.name),
                        ),
                    ],
                    onChanged: (value) =>
                        setDialogState(() => divisionId = value ?? ''),
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
                  if (applicant.text.trim().isEmpty ||
                      entry.text.trim().isEmpty) {
                    return;
                  }
                  Navigator.pop(context, (
                    applicant.text.trim(),
                    applicantType,
                    email.text.trim(),
                    entryType,
                    entry.text.trim(),
                    divisionId,
                    divisionName(),
                  ));
                },
                child: const Text('Add participant'),
              ),
            ],
          ),
        ),
      );
  applicant.dispose();
  email.dispose();
  entry.dispose();
  return result;
}

Future<(bool, String)?> _eligibilityReviewDialog(
  BuildContext context,
  CompetitionRegistration registration,
) async {
  final notes = TextEditingController(text: registration.eligibilityNotes);
  var eligible = registration.eligible ?? true;
  final result = await showDialog<(bool, String)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Eligibility review'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('Eligible')),
                ButtonSegment(value: false, label: Text('Ineligible')),
              ],
              selected: {eligible},
              onSelectionChanged: (value) =>
                  setDialogState(() => eligible = value.single),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: notes,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Review notes',
                hintText: 'Age, division, school, or qualification evidence',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (eligible, notes.text.trim())),
            child: const Text('Save review'),
          ),
        ],
      ),
    ),
  );
  notes.dispose();
  return result;
}

String _label(String value) {
  final spaced = value.replaceAllMapped(
    RegExp(r'([a-z])([A-Z])'),
    (match) => '${match.group(1)} ${match.group(2)}',
  );
  return spaced.isEmpty
      ? spaced
      : '${spaced[0].toUpperCase()}${spaced.substring(1)}';
}

String _shortDate(DateTime? date) =>
    date == null ? 'Not set' : '${date.day}/${date.month}/${date.year}';

String _dateRange(DateTime? start, DateTime? end) =>
    '${_shortDate(start)} – ${_shortDate(end)}';
