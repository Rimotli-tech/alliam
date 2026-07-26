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
import '../../train/domain/learner_pathway.dart';

class PathwayPage extends StatefulWidget {
  const PathwayPage({super.key});

  @override
  State<PathwayPage> createState() => _PathwayPageState();
}

class _PathwayPageState extends State<PathwayPage> {
  late final Future<({AccountSession session, AlliamSettings settings})> _data;

  @override
  void initState() {
    super.initState();
    _data = _load();
  }

  Future<({AccountSession session, AlliamSettings settings})> _load() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser!;
    final values = await Future.wait([
      AccountRepository(FirebaseFirestore.instance).load(user),
      SettingsRepository(FirebaseFirestore.instance, auth).load(),
    ]);
    return (
      session: values[0] as AccountSession,
      settings: values[1] as AlliamSettings,
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
                      ({AccountSession session, AlliamSettings settings})
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

  final ({AccountSession session, AlliamSettings settings}) data;
  final ValueChanged<String> onStart;

  @override
  Widget build(BuildContext context) {
    final learner = data.session.activeLearner;
    final journey = learner?.journey ?? const <String, dynamic>{};
    final current = LearnerPathway.stage(journey['stage']?.toString());
    final sessions = (journey['stageSessions'] as num?)?.round() ?? 0;
    final accuracy = (journey['stageAccuracy'] as num?)?.round() ?? 0;
    final currentIndex = LearnerPathway.stages.indexOf(current);
    final recommendedSlug = sessions.isEven ? 'hear-and-spell' : 'word-flash';
    final recommendedLabel = sessions.isEven ? 'Hear & Spell' : 'Word Flash';

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
                  Text(
                    'Welcome back, ${learner?.name ?? data.session.firstName}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AlliamColors.text),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your spelling path',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AlliamColors.coral,
                      fontWeight: FontWeight.w700,
                      fontSize: compact ? 38 : 50,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${learner?.grade ?? 'Grade 1'} · Keep moving forward, one word at a time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AlliamColors.text),
                  ),
                  SizedBox(height: compact ? 34 : 46),
                  for (
                    var index = 0;
                    index < LearnerPathway.stages.length;
                    index++
                  )
                    _PathStop(
                      stage: LearnerPathway.stages[index],
                      index: index,
                      state: index < currentIndex
                          ? _StopState.complete
                          : index == currentIndex
                          ? _StopState.current
                          : _StopState.locked,
                      sessions: index == currentIndex ? sessions : 0,
                      accuracy: index == currentIndex ? accuracy : 0,
                      mode: index == currentIndex ? recommendedLabel : null,
                      alignRight: index.isOdd,
                      compact: compact,
                      isLast: index == LearnerPathway.stages.length - 1,
                      onTap: index == currentIndex
                          ? () => onStart(recommendedSlug)
                          : null,
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
}

enum _StopState { complete, current, locked }

class _PathStop extends StatelessWidget {
  const _PathStop({
    required this.stage,
    required this.index,
    required this.state,
    required this.sessions,
    required this.accuracy,
    required this.mode,
    required this.alignRight,
    required this.compact,
    required this.isLast,
    required this.onTap,
  });

  final PathwayStage stage;
  final int index;
  final _StopState state;
  final int sessions;
  final int accuracy;
  final String? mode;
  final bool alignRight;
  final bool compact;
  final bool isLast;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final current = state == _StopState.current;
    final complete = state == _StopState.complete;
    final progress = stage.sessionsRequired == 0
        ? 1.0
        : (sessions / stage.sessionsRequired).clamp(0.0, 1.0);
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
              button: current,
              label: '${stage.label} stage',
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
                        stage.label,
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
                            ? 'Stage complete'
                            : current
                            ? '$mode · Continue'
                            : 'Complete ${LearnerPathway.stages[index - 1].label} to unlock',
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
                          '$sessions/${stage.sessionsRequired} sessions · $accuracy% accuracy',
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
