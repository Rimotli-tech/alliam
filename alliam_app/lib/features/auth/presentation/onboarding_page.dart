import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_background.dart';
import '../../../core/widgets/alliam_logo.dart';
import '../data/account_repository.dart';
import '../domain/account_session.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({
    required this.user,
    required this.onComplete,
    super.key,
  });

  final User user;
  final VoidCallback onComplete;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _ownerName = TextEditingController();
  final _learnerName = TextEditingController();
  final _schoolName = TextEditingController();
  final _learnerSchool = TextEditingController();
  AccountRole _role = AccountRole.student;
  String _grade = 'Grade 1';
  String _country = 'Nigeria';
  int _step = 0;
  bool _busy = false;
  String? _error;

  int get _lastStep => switch (_role) {
    AccountRole.parent => 3,
    AccountRole.organization => 2,
    _ => 2,
  };

  @override
  void initState() {
    super.initState();
    final displayName = widget.user.displayName?.trim() ?? '';
    _ownerName.text = displayName;
    _learnerName.text = displayName;
  }

  @override
  void dispose() {
    _ownerName.dispose();
    _learnerName.dispose();
    _schoolName.dispose();
    _learnerSchool.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    setState(() => _error = null);
    if (!_validate()) return;
    if (_step < _lastStep) {
      setState(() => _step++);
      return;
    }
    setState(() => _busy = true);
    try {
      final repository = AccountRepository(FirebaseFirestore.instance);
      switch (_role) {
        case AccountRole.parent:
          await repository.completeParent(
            user: widget.user,
            parentName: _ownerName.text.trim(),
            country: _country,
            learnerName: _learnerName.text.trim(),
            grade: _grade,
            school: _learnerSchool.text.trim(),
          );
        case AccountRole.organization:
          await repository.completeOrganization(
            user: widget.user,
            schoolName: _schoolName.text.trim(),
            administratorName: _ownerName.text.trim(),
            country: _country,
          );
        default:
          await repository.completeStudent(
            user: widget.user,
            name: _learnerName.text.trim(),
            grade: _grade,
            country: _country,
            school: _learnerSchool.text.trim(),
          );
      }
      widget.onComplete();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Setup could not be saved. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _validate() {
    final message = switch ((_role, _step)) {
      (_, 0) => null,
      (AccountRole.parent, 1) when _ownerName.text.trim().isEmpty =>
        'Enter the parent or guardian name.',
      (AccountRole.parent, 2) when _learnerName.text.trim().isEmpty =>
        'Enter the learner name.',
      (AccountRole.organization, 1) when _schoolName.text.trim().isEmpty =>
        'Enter the organisation or coaching name.',
      (AccountRole.organization, 1) when _ownerName.text.trim().isEmpty =>
        'Enter the administrator or coach name.',
      (AccountRole.student, 1) when _learnerName.text.trim().isEmpty =>
        'Enter the learner name.',
      _ => null,
    };
    if (message != null) setState(() => _error = message);
    return message == null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;
          final side = _OnboardingBrand(
            step: _step,
            total: _lastStep + 1,
            compact: compact,
          );
          final form = Expanded(
            child: AlliamBackground(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(compact ? 24 : 48),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 580),
                    child: _buildStep(context),
                  ),
                ),
              ),
            ),
          );
          return compact
              ? Column(
                  children: [
                    SizedBox(height: 170, child: side),
                    form,
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: constraints.maxWidth * 0.34, child: side),
                    form,
                  ],
                );
        },
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    final content = switch ((_role, _step)) {
      (_, 0) => _roleStep(context),
      (AccountRole.parent, 1) => _parentStep(context),
      (AccountRole.parent, 2) => _learnerStep(
        context,
        title: 'Add the first learner',
      ),
      (AccountRole.organization, 1) => _organizationStep(context),
      (AccountRole.student, 1) => _learnerStep(
        context,
        title: 'Create the learner profile',
      ),
      _ => _readyStep(context),
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey('${_role.name}-$_step'),
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: AlliamColors.surface,
          borderRadius: BorderRadius.circular(36),
          border: Border.all(color: AlliamColors.line),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55E1DCD8),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            content,
            if (_error != null) ...[
              const SizedBox(height: 18),
              Text(_error!, style: const TextStyle(color: AlliamColors.error)),
            ],
            const SizedBox(height: 28),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_step > 0)
                  OutlinedButton(
                    onPressed: _busy ? null : () => setState(() => _step--),
                    child: const Text('Back'),
                  ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _busy ? null : _continue,
                  child: Text(
                    _busy
                        ? 'Saving…'
                        : _step == _lastStep
                        ? 'Enter Alliam'
                        : 'Continue',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        context,
        'Choose how you’ll use Alliam',
        'This determines the experience we prepare.',
      ),
      const SizedBox(height: 28),
      LayoutBuilder(
        builder: (context, constraints) {
          final cards = [
            (AccountRole.student, Icons.person_outline_rounded, 'Student'),
            (AccountRole.parent, Icons.shield_outlined, 'Parent'),
            (
              AccountRole.organization,
              Icons.corporate_fare_outlined,
              'Organisation / Coach',
            ),
          ];
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in cards)
                SizedBox(
                  width: (constraints.maxWidth - 24) / 3,
                  height: 150,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => setState(() => _role = item.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      decoration: BoxDecoration(
                        color: _role == item.$1
                            ? Colors.white
                            : AlliamColors.surfaceStrong,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _role == item.$1
                              ? AlliamColors.coral
                              : AlliamColors.line,
                          width: _role == item.$1 ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.$2, color: AlliamColors.coral, size: 34),
                          const SizedBox(height: 14),
                          Text(item.$3),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ],
  );

  Widget _parentStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        context,
        'Create the parent profile',
        'Manage learners, permissions, and progress.',
      ),
      const SizedBox(height: 26),
      _field('Parent or guardian name', _ownerName, 'Your name'),
      const SizedBox(height: 16),
      _countryField(),
    ],
  );

  Widget _organizationStep(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        context,
        'Set up your organisation',
        'Create the account for rosters, teams, fixtures, and competitions.',
      ),
      const SizedBox(height: 26),
      _field(
        'Organisation, school, or coaching name',
        _schoolName,
        'Emerald Primary School',
      ),
      const SizedBox(height: 16),
      _field('Administrator or coach name', _ownerName, 'Your name'),
      const SizedBox(height: 16),
      _countryField(),
    ],
  );

  Widget _learnerStep(BuildContext context, {required String title}) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _heading(
        context,
        title,
        'Only the essentials for fair, age-appropriate competition.',
      ),
      const SizedBox(height: 26),
      _field('First name or competition nickname', _learnerName, 'e.g. Ada'),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(child: _gradeField()),
          const SizedBox(width: 14),
          Expanded(child: _countryField()),
        ],
      ),
      const SizedBox(height: 16),
      _field('School (optional)', _learnerSchool, 'Your school'),
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AlliamColors.surfaceStrong,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AlliamColors.line),
        ),
        child: const Row(
          children: [
            Icon(Icons.mic_none_rounded, color: AlliamColors.coral),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Voice features require parent or guardian consent for child accounts.',
              ),
            ),
            Icon(Icons.lock_outline_rounded, size: 18),
          ],
        ),
      ),
    ],
  );

  Widget _readyStep(BuildContext context) {
    final (title, body, icon) = switch (_role) {
      AccountRole.parent => (
        'Your family is ready',
        'Add more learners or switch between them from your family profile.',
        Icons.family_restroom_rounded,
      ),
      AccountRole.organization => (
        'Your organisation hub is ready',
        'Build your roster, organise teams, and schedule competitions.',
        Icons.corporate_fare_outlined,
      ),
      _ => (
        'You’re ready to spell',
        'Start with Foundation words. Alliam adapts as you improve.',
        Icons.spellcheck_rounded,
      ),
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading(context, title, body),
        const SizedBox(height: 30),
        Center(
          child: Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              color: AlliamColors.surfaceStrong,
              borderRadius: BorderRadius.circular(34),
              border: Border.all(color: AlliamColors.line, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33D7B69B),
                  blurRadius: 34,
                  offset: Offset(10, 18),
                ),
              ],
            ),
            child: Icon(icon, color: AlliamColors.coral, size: 44),
          ),
        ),
      ],
    );
  }

  Widget _heading(BuildContext context, String title, String subtitle) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AlliamColors.coral,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(subtitle),
        ],
      );

  Widget _field(String label, TextEditingController controller, String hint) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 7),
          TextField(
            controller: controller,
            decoration: InputDecoration(hintText: hint),
          ),
        ],
      );

  Widget _gradeField() => DropdownButtonFormField<String>(
    initialValue: _grade,
    decoration: const InputDecoration(labelText: 'Grade'),
    items: [
      for (var index = 1; index <= 12; index++)
        DropdownMenuItem(value: 'Grade $index', child: Text('Grade $index')),
    ],
    onChanged: (value) => setState(() => _grade = value ?? _grade),
  );

  Widget _countryField() => DropdownButtonFormField<String>(
    initialValue: _country,
    decoration: const InputDecoration(labelText: 'Country'),
    items: const [
      DropdownMenuItem(value: 'Nigeria', child: Text('Nigeria')),
      DropdownMenuItem(value: 'Ghana', child: Text('Ghana')),
      DropdownMenuItem(value: 'Kenya', child: Text('Kenya')),
      DropdownMenuItem(value: 'South Africa', child: Text('South Africa')),
      DropdownMenuItem(value: 'Other', child: Text('Other')),
    ],
    onChanged: (value) => setState(() => _country = value ?? _country),
  );
}

class _OnboardingBrand extends StatelessWidget {
  const _OnboardingBrand({
    required this.step,
    required this.total,
    required this.compact,
  });

  final int step;
  final int total;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AlliamColors.coral, Color(0xFFFFA046)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(compact ? 26 : 52),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AlliamLogo(width: 112, color: Colors.white),
            const Spacer(),
            if (!compact)
              Text(
                'Train.\nCompete.\nRise.',
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontSize: 56,
                  height: 1.08,
                  fontWeight: FontWeight.w600,
                ),
              ),
            if (!compact) const SizedBox(height: 28),
            Row(
              children: [
                for (var index = 0; index < total; index++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: index == step ? 34 : 9,
                    height: 9,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: index == step
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
