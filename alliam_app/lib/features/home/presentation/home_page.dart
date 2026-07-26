import 'dart:math' as math;
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/audio/sound_effects_service.dart';
import '../../../core/widgets/alliam_background.dart';
import '../../../core/widgets/alliam_card.dart';
import '../../../core/widgets/alliam_logo.dart';
import '../../auth/data/account_repository.dart';
import '../../auth/domain/account_session.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const SizedBox.shrink();
    }

    return FutureBuilder<AccountSession>(
      future: AccountRepository(FirebaseFirestore.instance).load(user),
      builder: (context, snapshot) {
        final session =
            snapshot.data ?? AccountSession.fallback(user.email ?? 'Speller');
        return Scaffold(
          body: AlliamBackground(
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    top: 10,
                    child: const AlliamLogo(width: 102),
                  ),
                  Positioned(
                    right: 12,
                    top: 6,
                    child: IconButton(
                      tooltip: 'Notifications',
                      onPressed: () {},
                      icon: const Icon(
                        Icons.notifications_none_rounded,
                        color: AlliamColors.coral,
                        size: 20,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AlliamColors.surfaceStrong.withValues(
                          alpha: 0.75,
                        ),
                        side: const BorderSide(color: AlliamColors.line),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final mobile = constraints.maxWidth <= 760;
                        final narrow = constraints.maxWidth <= 420;
                        final columns = narrow
                            ? 1
                            : mobile
                            ? 2
                            : 3;
                        final horizontalPadding = mobile ? 20.0 : 32.0;
                        final gap = mobile ? 14.0 : 22.0;
                        final cardHeight = narrow
                            ? 122.0
                            : mobile
                            ? 145.0
                            : 178.0;
                        final gridWidth = math.min(
                          930.0,
                          constraints.maxWidth - horizontalPadding * 2,
                        );
                        final cardWidth =
                            (gridWidth - gap * (columns - 1)) / columns;
                        return SingleChildScrollView(
                          padding: EdgeInsets.fromLTRB(
                            horizontalPadding,
                            mobile ? 104 : 110,
                            horizontalPadding,
                            64,
                          ),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: mobile
                                  ? 0
                                  : constraints.maxHeight - 174,
                            ),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 930,
                                ),
                                child: Column(
                                  mainAxisAlignment: mobile
                                      ? MainAxisAlignment.start
                                      : MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Welcome back, ${session.firstName}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AlliamColors.text,
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Where to?',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displaySmall
                                          ?.copyWith(
                                            color: AlliamColors.coral,
                                            fontSize: mobile ? 38 : 58,
                                            height: 1,
                                            letterSpacing: -2.6,
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 34),
                                    GridView.count(
                                      crossAxisCount: columns,
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      mainAxisSpacing: mobile ? 14 : 22,
                                      crossAxisSpacing: mobile ? 14 : 22,
                                      childAspectRatio: cardWidth / cardHeight,
                                      children: [
                                        AlliamCard(
                                          icon: Icons.fitness_center_rounded,
                                          title: 'Train',
                                          subtitle: 'Build your spelling',
                                          onTap: () {
                                            unawaited(
                                              SoundEffectsService.instance
                                                  .startModule(),
                                            );
                                            context.go('/train');
                                          },
                                        ),
                                        AlliamCard(
                                          icon: Icons.sports_kabaddi_rounded,
                                          title: 'Compete',
                                          subtitle: 'Enter the arena',
                                          onTap: () {
                                            unawaited(
                                              SoundEffectsService.instance
                                                  .startModule(),
                                            );
                                            context.go('/compete');
                                          },
                                        ),
                                        AlliamCard(
                                          icon: Icons.leaderboard_outlined,
                                          title: 'Rankings',
                                          subtitle: 'See your position',
                                          onTap: () => context.go('/rankings'),
                                        ),
                                        AlliamCard(
                                          icon: Icons.groups_outlined,
                                          title: 'Friends & teams',
                                          subtitle: 'Spell together',
                                          onTap: () => context.go('/social'),
                                        ),
                                        AlliamCard(
                                          icon: Icons.person_outline_rounded,
                                          title:
                                              session.role == AccountRole.parent
                                              ? 'Family'
                                              : session.role ==
                                                    AccountRole.school
                                              ? 'School'
                                              : 'Profile',
                                          subtitle:
                                              session.role == AccountRole.parent
                                              ? 'Manage learners'
                                              : session.role ==
                                                    AccountRole.school
                                              ? 'Manage your school'
                                              : 'Your progress',
                                          onTap: () => context.go('/profile'),
                                        ),
                                        AlliamCard(
                                          icon: Icons.settings_outlined,
                                          title: 'Settings',
                                          subtitle: 'Make it yours',
                                          onTap: () => context.go('/settings'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
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
