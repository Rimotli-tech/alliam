import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/audio/sound_effects_service.dart';
import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_background.dart';
import '../../../core/widgets/alliam_logo.dart';
import '../../../core/widgets/account_menu_button.dart';
import '../../auth/data/account_repository.dart';
import '../../auth/domain/account_session.dart';
import '../../settings/data/settings_repository.dart';
import '../../train/data/learner_pathway_progress_repository.dart';
import '../../train/data/learner_word_progress_repository.dart';
import '../../train/domain/learner_pathway.dart';
import '../../train/domain/training_mode.dart';

class PathwayPage extends StatefulWidget {
  const PathwayPage({super.key});

  @override
  State<PathwayPage> createState() => _PathwayPageState();
}

class _PathwayPageState extends State<PathwayPage> {
  late final Future<
    ({
      AccountSession session,
      AlliamSettings settings,
      LearnerMasterySummary mastery,
      LearnerPathwayPosition position,
    })
  >
  _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<
    ({
      AccountSession session,
      AlliamSettings settings,
      LearnerMasterySummary mastery,
      LearnerPathwayPosition position,
    })
  >
  _load() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    if (user == null) throw StateError('Sign in to continue.');
    final values = await Future.wait([
      AccountRepository(FirebaseFirestore.instance).load(user),
      SettingsRepository(FirebaseFirestore.instance, auth).load(),
    ]);
    final session = values[0] as AccountSession;
    final learnerId = session.activeLearnerId;
    var mastery = LearnerMasterySummary.empty;
    var position = LearnerPathway.position(introduced: 0, mastered: 0);
    if (learnerId != null) {
      mastery = await LearnerWordProgressRepository(
        FirebaseFirestore.instance,
      ).loadSummary(accountId: user.uid, learnerId: learnerId);
      position =
          await LearnerPathwayProgressRepository(
            FirebaseFirestore.instance,
          ).syncPosition(
            accountId: user.uid,
            learnerId: learnerId,
            introduced: mastery.introduced,
            mastered: mastery.mastered,
          );
    }
    return (
      session: session,
      settings: values[1] as AlliamSettings,
      mastery: mastery,
      position: position,
    );
  }

  void _openSession(String slug) {
    unawaited(SoundEffectsService.instance.startModule());
    context.go('/train/session/$slug');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AlliamBackground(
        child: SafeArea(
          child: Stack(
            children: [
              const Positioned(left: 18, top: 12, child: AlliamLogo(width: 98)),
              Positioned.fill(
                child:
                    FutureBuilder<
                      ({
                        AccountSession session,
                        AlliamSettings settings,
                        LearnerMasterySummary mastery,
                        LearnerPathwayPosition position,
                      })
                    >(
                      future: _data,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return _PathContent(
                          data: snapshot.data!,
                          onStart: _openSession,
                        );
                      },
                    ),
              ),
              Positioned(
                left: 18,
                bottom: 16,
                child: TextButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.grid_view_rounded),
                  label: const Text('Explore'),
                ),
              ),
              Positioned(
                right: 18,
                top: 8,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AlliamColors.surfaceStrong,
                    shape: BoxShape.circle,
                    border: Border.all(color: AlliamColors.line),
                  ),
                  child: const AccountMenuButton(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PathContent extends StatelessWidget {
  const _PathContent({required this.data, required this.onStart});

  final ({
    AccountSession session,
    AlliamSettings settings,
    LearnerMasterySummary mastery,
    LearnerPathwayPosition position,
  })
  data;
  final ValueChanged<String> onStart;

  @override
  Widget build(BuildContext context) {
    final learner = data.session.activeLearner;
    final unit = LearnerPathway.unit(data.position.unitId);
    final unitIndex = LearnerPathway.foundationUnits.indexOf(unit);
    final currentIndex = unit.nodes.indexWhere(
      (node) => node.id == data.position.nodeId,
    );
    final resolvedNodeIndex = currentIndex < 0 ? 0 : currentIndex;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 680;
        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            compact ? 22 : 48,
            compact ? 82 : 70,
            compact ? 22 : 48,
            86,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hi ${learner?.name ?? data.session.firstName}',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AlliamColors.coral,
                        fontWeight: FontWeight.w700,
                        fontSize: compact ? 38 : 50,
                      ),
                    ),
                  ),
                  SizedBox(height: compact ? 34 : 46),
                  ..._unitTrail(
                    currentUnitIndex: unitIndex,
                    currentNodeIndex: resolvedNodeIndex,
                    mastery: data.mastery,
                    compact: compact,
                  ),
                  const SizedBox(height: 14),
                  TextButton.icon(
                    onPressed: () => context.go('/train'),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Choose a practice mode'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _unitTrail({
    required int currentUnitIndex,
    required int currentNodeIndex,
    required LearnerMasterySummary mastery,
    required bool compact,
  }) {
    final widgets = <Widget>[];
    var trailIndex = 0;
    final units = LearnerPathway.foundationUnits;
    final totalNodes = units.fold<int>(
      0,
      (total, unit) => total + unit.nodes.length,
    );
    for (var unitIndex = 0; unitIndex < units.length; unitIndex++) {
      final unit = units[unitIndex];
      final unitState = unitIndex < currentUnitIndex
          ? _UnitState.complete
          : unitIndex == currentUnitIndex
          ? _UnitState.current
          : _UnitState.locked;
      widgets.add(
        _UnitHeading(
          unit: unit,
          number: unitIndex + 1,
          total: units.length,
          state: unitState,
          mastery: mastery,
          showIncomingTrail: unitIndex > 0,
        ),
      );
      for (var nodeIndex = 0; nodeIndex < unit.nodes.length; nodeIndex++) {
        final state = unitIndex < currentUnitIndex
            ? _StopState.complete
            : unitIndex > currentUnitIndex
            ? _StopState.locked
            : nodeIndex < currentNodeIndex
            ? _StopState.complete
            : nodeIndex == currentNodeIndex
            ? _StopState.current
            : _StopState.locked;
        final available = state != _StopState.locked;
        widgets.add(
          _PathStop(
            node: unit.nodes[nodeIndex],
            index: trailIndex,
            state: state,
            mastery: mastery,
            alignRight: trailIndex.isOdd,
            compact: compact,
            isLast: trailIndex == totalNodes - 1,
            onTap: available
                ? () => onStart(unit.nodes[nodeIndex].mode.slug)
                : null,
          ),
        );
        trailIndex++;
      }
    }
    return widgets;
  }
}

enum _StopState { complete, current, locked }

enum _UnitState { complete, current, locked }

class _UnitHeading extends StatelessWidget {
  const _UnitHeading({
    required this.unit,
    required this.number,
    required this.total,
    required this.state,
    required this.mastery,
    required this.showIncomingTrail,
  });

  final PathwayUnit unit;
  final int number;
  final int total;
  final _UnitState state;
  final LearnerMasterySummary mastery;
  final bool showIncomingTrail;

  @override
  Widget build(BuildContext context) {
    final current = state == _UnitState.current;
    final complete = state == _UnitState.complete;
    return Padding(
      padding: EdgeInsets.only(top: showIncomingTrail ? 34 : 0, bottom: 24),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (showIncomingTrail)
            Positioned(
              top: 0,
              bottom: 0,
              child: Container(
                width: 3,
                color: (complete || current)
                    ? AlliamColors.coral.withValues(alpha: 0.28)
                    : AlliamColors.line,
              ),
            ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
            decoration: BoxDecoration(
              color: current
                  ? AlliamColors.surfaceStrong
                  : AlliamColors.surface,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: current ? AlliamColors.coral : AlliamColors.line,
                width: current ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  complete
                      ? Icons.check_circle_outline_rounded
                      : current
                      ? Icons.route_rounded
                      : Icons.lock_outline_rounded,
                  color: complete || current
                      ? AlliamColors.coral
                      : AlliamColors.muted,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit $number of $total · ${unit.label}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: current
                              ? AlliamColors.coral
                              : AlliamColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(unit.description),
                    ],
                  ),
                ),
                if (complete)
                  Text(
                    '${unit.masteryTarget} mastered',
                    style: const TextStyle(
                      color: AlliamColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else if (current)
                  Text(
                    '${mastery.mastered}/${unit.masteryTarget}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PathStop extends StatelessWidget {
  const _PathStop({
    required this.node,
    required this.index,
    required this.state,
    required this.mastery,
    required this.alignRight,
    required this.compact,
    required this.isLast,
    required this.onTap,
  });

  final PathwayNode node;
  final int index;
  final _StopState state;
  final LearnerMasterySummary mastery;
  final bool alignRight;
  final bool compact;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final current = state == _StopState.current;
    final complete = state == _StopState.complete;
    final progress = node.masteredRequired > 0
        ? (mastery.mastered / node.masteredRequired).clamp(0.0, 1.0)
        : node.introducedRequired > 0
        ? (mastery.introduced / node.introducedRequired).clamp(0.0, 1.0)
        : 1.0;
    final width = compact ? 238.0 : 310.0;

    return SizedBox(
      height: current ? 245 : 205,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (!isLast)
            Positioned(
              top: current ? 178 : 145,
              bottom: 0,
              child: CustomPaint(
                size: const Size(80, 70),
                painter: _TrailPainter(reverse: alignRight),
              ),
            ),
          Align(
            alignment: alignRight ? Alignment.topRight : Alignment.topLeft,
            child: Semantics(
              button: current || complete,
              label: complete
                  ? '${node.label}, mastered, review again'
                  : '${node.label} path node',
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(34),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: width,
                  padding: const EdgeInsets.fromLTRB(20, 17, 20, 18),
                  decoration: BoxDecoration(
                    color: current
                        ? AlliamColors.surfaceStrong
                        : AlliamColors.surface,
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: current ? AlliamColors.coral : AlliamColors.line,
                      width: current ? 3 : 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22948D87),
                        blurRadius: 22,
                        offset: Offset(7, 13),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _House(
                        color: current || complete
                            ? AlliamColors.coral
                            : AlliamColors.text.withValues(alpha: 0.55),
                        icon: complete
                            ? Icons.check_rounded
                            : current
                            ? Icons.play_arrow_rounded
                            : Icons.lock_outline_rounded,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        node.label,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: current
                              ? AlliamColors.coral
                              : AlliamColors.text,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        complete
                            ? '${node.mode.label} · Review again'
                            : current
                            ? '${node.mode.label} · Continue'
                            : 'Complete the previous node to unlock',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AlliamColors.text,
                          fontSize: 13,
                        ),
                      ),
                      if (current) ...[
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(10),
                          backgroundColor: AlliamColors.line,
                          color: AlliamColors.coral,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          node.masteredRequired > 0
                              ? '${mastery.mastered}/${node.masteredRequired} words mastered'
                              : '${mastery.introduced}/${node.introducedRequired} words introduced',
                          style: TextStyle(
                            color: AlliamColors.text,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _House extends StatelessWidget {
  const _House({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      height: 66,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Transform.rotate(
            angle: math.pi / 4,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: color, width: 3),
              ),
            ),
          ),
          Container(
            width: 70,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AlliamColors.surfaceStrong,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color, width: 3),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
        ],
      ),
    );
  }
}

class _TrailPainter extends CustomPainter {
  const _TrailPainter({required this.reverse});

  final bool reverse;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AlliamColors.coral.withValues(alpha: 0.35)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    final startX = reverse ? size.width * 0.75 : size.width * 0.25;
    final endX = reverse ? size.width * 0.25 : size.width * 0.75;
    path.moveTo(startX, 0);
    path.cubicTo(startX, 22, endX, 42, endX, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrailPainter oldDelegate) =>
      reverse != oldDelegate.reverse;
}
