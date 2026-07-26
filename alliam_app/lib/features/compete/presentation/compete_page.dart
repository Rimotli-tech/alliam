import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../auth/data/account_repository.dart';
import '../../../core/audio/sound_effects_service.dart';
import '../data/competition_service.dart';
import 'match_page.dart';
import '../../../core/widgets/alliam_card.dart';
import '../../../core/widgets/alliam_page.dart';

class CompetePage extends StatelessWidget {
  const CompetePage({super.key});

  @override
  Widget build(BuildContext context) {
    const arenas = [
      (Icons.sports_kabaddi_rounded, 'Casual', '1v1'),
      (Icons.emoji_events_outlined, 'Ranked', 'Rating'),
      (Icons.groups_outlined, 'Private', 'Room code'),
      (Icons.shield_outlined, 'Teams', '6v6'),
      (Icons.corporate_fare_outlined, 'Organisations', 'Fixture'),
      (Icons.flag_outlined, 'Tournament', 'Bracket'),
    ];
    return AlliamPage(
      title: 'Choose an arena',
      subtitle: 'Pick a format and begin',
      child: Column(
        children: [
          FutureBuilder<String?>(
            future: CompetitionService().activeMatchId(),
            builder: (context, snapshot) {
              final matchId = snapshot.data;
              if (matchId == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => MatchPage(
                        mode: 'Active match',
                        initialMatchId: matchId,
                      ),
                    ),
                  ),
                  icon: const Icon(Icons.restore_rounded),
                  label: const Text('Resume active match'),
                ),
              );
            },
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth < 620
                  ? 1
                  : constraints.maxWidth < 900
                  ? 2
                  : 3;
              return GridView.builder(
                itemCount: arenas.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 18,
                  mainAxisExtent: 158,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final arena = arenas[index];
                  return AlliamCard(
                    icon: arena.$1,
                    title: arena.$2,
                    subtitle: arena.$3,
                    variant: AlliamCardVariant.training,
                    onTap: () => _openArena(context, index),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _openArena(BuildContext context, int index) {
    unawaited(SoundEffectsService.instance.startModule());
    if (index == 0 || index == 1) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) =>
              MatchPage(mode: index == 0 ? 'Casual 1v1' : 'Ranked 1v1'),
        ),
      );
      return;
    }
    if (index == 2) {
      _openPrivateRoom(context);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          index == 3
              ? 'Team matches are created from your team hub.'
              : 'This arena is scheduled through the Organisation dashboard.',
        ),
      ),
    );
  }

  Future<void> _openPrivateRoom(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in to create a private match.')),
      );
      return;
    }
    final code = TextEditingController();
    final action = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Private match'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Join with a room code'),
            const SizedBox(height: 12),
            TextField(
              controller: code,
              textCapitalization: TextCapitalization.characters,
              maxLength: 8,
              decoration: const InputDecoration(hintText: 'Enter code'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, 'create'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create a new room'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, 'join:${code.text.trim()}'),
            child: const Text('Join room'),
          ),
        ],
      ),
    );
    code.dispose();
    if (action == null || !context.mounted) return;

    final service = CompetitionService();
    try {
      final session = await AccountRepository(
        FirebaseFirestore.instance,
      ).load(user);
      await service.bootstrap(session);
      if (!context.mounted) return;
      if (action == 'create') {
        final roomCode = await service.createPrivateRoom();
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MatchPage(mode: 'Private 1v1', privateRoomCode: roomCode),
          ),
        );
      } else {
        final roomCode = action.substring(5).trim();
        if (roomCode.isEmpty) throw StateError('Enter a room code.');
        final matchId = await service.joinPrivateRoom(roomCode);
        if (!context.mounted) return;
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MatchPage(mode: 'Private 1v1', initialMatchId: matchId),
          ),
        );
      }
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }
}
