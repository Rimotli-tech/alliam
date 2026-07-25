import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/alliam_card.dart';
import '../../../core/widgets/alliam_page.dart';
import '../domain/training_mode.dart';

class TrainPage extends StatelessWidget {
  const TrainPage({super.key});

  @override
  Widget build(BuildContext context) {
    const modes = TrainingMode.values;
    return AlliamPage(
      title: 'Choose your training',
      subtitle: 'Build competition readiness',
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = constraints.maxWidth < 620
              ? 1
              : constraints.maxWidth < 900
              ? 2
              : 4;
          return GridView.builder(
            itemCount: modes.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: columns,
              mainAxisSpacing: 18,
              crossAxisSpacing: 18,
              mainAxisExtent: 158,
            ),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              final mode = modes[index];
              return AlliamCard(
                icon: _icon(mode),
                title: mode.label,
                variant: AlliamCardVariant.training,
                subtitle: mode.isImplemented
                    ? mode.subtitle
                    : '${mode.subtitle} · Soon',
                onTap: mode.isImplemented
                    ? () => context.go('/train/session/${mode.slug}')
                    : () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${mode.label} is next in the migration queue.',
                          ),
                        ),
                      ),
              );
            },
          );
        },
      ),
    );
  }

  IconData _icon(TrainingMode mode) {
    return switch (mode) {
      TrainingMode.hearAndSpell => Icons.hearing_rounded,
      TrainingMode.wordFlash => Icons.visibility_outlined,
      TrainingMode.timedDrill => Icons.timer_outlined,
      TrainingMode.listenAndSpell => Icons.graphic_eq_rounded,
      TrainingMode.missingLetters => Icons.edit_outlined,
      TrainingMode.patternDrill => Icons.pattern_rounded,
      TrainingMode.similarWords => Icons.compare_arrows_rounded,
      TrainingMode.buildTheWord => Icons.view_module_outlined,
      TrainingMode.mockBee => Icons.emoji_events_outlined,
      TrainingMode.survivalRun => Icons.shield_outlined,
      TrainingMode.streakChallenge => Icons.local_fire_department_outlined,
      TrainingMode.recallLadder => Icons.stairs_outlined,
      TrainingMode.dailyChallenge => Icons.today_outlined,
      TrainingMode.themeChallenge => Icons.flag_outlined,
      TrainingMode.reverseSpell => Icons.sync_alt_rounded,
      TrainingMode.missedWords => Icons.replay_rounded,
    };
  }
}
