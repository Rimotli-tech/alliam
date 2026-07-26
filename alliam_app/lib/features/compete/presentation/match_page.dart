import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_background.dart';
import '../../../core/audio/sound_effects_service.dart';
import '../../auth/data/account_repository.dart';
import '../../train/data/training_audio_service.dart';
import '../../train/data/word_repository.dart';
import '../../train/domain/spelling_word.dart';
import '../../train/presentation/widgets/letter_diamonds.dart';
import '../data/competition_service.dart';
import '../domain/live_match.dart';

enum _MatchPhase { preparing, queue, playing, waiting, complete, error }

class MatchPage extends StatefulWidget {
  const MatchPage({
    required this.mode,
    this.initialMatchId,
    this.privateRoomCode,
    super.key,
  });

  final String mode;
  final String? initialMatchId;
  final String? privateRoomCode;

  @override
  State<MatchPage> createState() => _MatchPageState();
}

class _MatchPageState extends State<MatchPage> with WidgetsBindingObserver {
  final _service = CompetitionService();
  final _audio = TrainingAudioService(
    FirebaseStorage.instance,
    FirebaseFirestore.instance,
  );
  final _words = WordRepository(FirebaseFirestore.instance);
  final _focus = FocusNode();
  final _answer = StringBuffer();
  StreamSubscription<String?>? _assignmentSubscription;
  StreamSubscription<String?>? _roomSubscription;
  StreamSubscription<LiveMatch?>? _matchSubscription;
  _MatchPhase _phase = _MatchPhase.preparing;
  LiveMatch? _match;
  SpellingWord? _word;
  String? _matchId;
  String? _error;
  String? _loadedWord;
  bool _submitting = false;
  bool _resultRecorded = false;
  bool _leaving = false;
  bool _allowPop = false;
  Timer? _presenceTimer;
  DateTime _startedAt = DateTime.now();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _presenceTimer?.cancel();
    _assignmentSubscription?.cancel();
    _roomSubscription?.cancel();
    _matchSubscription?.cancel();
    _audio.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final matchId = _matchId;
    if (matchId == null || _match?.status != 'active') return;
    unawaited(
      _service.touchPresence(matchId, away: state != AppLifecycleState.resumed),
    );
  }

  Future<void> _start() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _fail('Sign in with an Alliam account to enter live competition.');
      return;
    }
    try {
      final session = await AccountRepository(
        FirebaseFirestore.instance,
      ).load(user);
      await _service.bootstrap(session);
      if (widget.initialMatchId?.isNotEmpty == true) {
        _subscribeMatch(widget.initialMatchId!);
        return;
      }
      if (widget.privateRoomCode?.isNotEmpty == true) {
        setState(() => _phase = _MatchPhase.queue);
        _roomSubscription = _service
            .watchPrivateRoom(widget.privateRoomCode!)
            .listen((matchId) {
              if (matchId != null && matchId.isNotEmpty) {
                _subscribeMatch(matchId);
              }
            });
        return;
      }
      final ticket = await _service.joinQueue(widget.mode);
      if (!mounted) return;
      setState(() => _phase = _MatchPhase.queue);
      if (ticket.matchId != null) {
        _subscribeMatch(ticket.matchId!);
      } else {
        _assignmentSubscription = _service
            .watchAssignment(ignoreMatchId: ticket.previousAssignment)
            .listen((matchId) {
              if (matchId != null && matchId.isNotEmpty) {
                _subscribeMatch(matchId);
              }
            });
      }
    } catch (error) {
      _fail(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _subscribeMatch(String matchId) {
    if (_matchId == matchId) return;
    _matchId = matchId;
    _startedAt = DateTime.now();
    _assignmentSubscription?.cancel();
    _roomSubscription?.cancel();
    _matchSubscription?.cancel();
    _matchSubscription = _service
        .watchMatch(matchId)
        .listen(_syncMatch, onError: (Object error) => _fail(error.toString()));
    _presenceTimer?.cancel();
    unawaited(_service.touchPresence(matchId));
    _presenceTimer = Timer.periodic(const Duration(seconds: 12), (_) {
      unawaited(_heartbeat(matchId));
    });
  }

  Future<void> _heartbeat(String matchId) async {
    if (!mounted || _matchId != matchId || _match?.status == 'completed') {
      return;
    }
    try {
      await _service.touchPresence(matchId);
      final match = _match;
      if (match != null &&
          match.opponentAppearsDisconnected(_uid, DateTime.now())) {
        await _service.claimDisconnectedMatch(matchId);
      }
    } catch (_) {
      // Presence is best-effort; the next heartbeat retries.
    }
  }

  Future<void> _syncMatch(LiveMatch? match) async {
    if (match == null || !mounted) return;
    final roundChanged =
        _match == null || _match!.currentRound != match.currentRound;
    _match = match;
    if (match.status == 'completed') {
      _presenceTimer?.cancel();
      setState(() => _phase = _MatchPhase.complete);
      unawaited(_recordResult(match));
      return;
    }
    final mine = match.submission(match.currentRound, _uid);
    setState(() {
      _phase = mine == null ? _MatchPhase.playing : _MatchPhase.waiting;
      if (roundChanged) _answer.clear();
    });
    if (roundChanged || _loadedWord != match.currentWord) {
      await _loadRoundWord(match.currentWord);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  Future<void> _recordResult(LiveMatch match) async {
    if (_resultRecorded) return;
    _resultRecorded = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final opponentUid = match.opponentUid(_uid);
    final opponent = match.playerProfiles[opponentUid]?.name ?? 'Opponent';
    final mine = match.scores[_uid] ?? 0;
    final theirs = match.scores[opponentUid] ?? 0;
    final won = match.winnerUid == _uid;
    final draw = match.winnerUid == null && match.completionReason != 'forfeit';
    await AccountRepository(FirebaseFirestore.instance).recordMatch(
      user: user,
      matchId: match.id,
      opponent: opponent,
      mode: match.mode,
      myScore: mine,
      opponentScore: theirs,
      won: won,
      ratingDelta: draw
          ? 4
          : won
          ? 16
          : -16,
    );
  }

  Future<void> _loadRoundWord(String word) async {
    try {
      final loaded = await _words.loadWord(word);
      if (!mounted) return;
      setState(() {
        _word = loaded;
        _loadedWord = word;
      });
      await Future<void>.delayed(const Duration(milliseconds: 500));
      await _audio.play(loaded.pronunciation);
    } catch (error) {
      _fail(error.toString().replaceFirst('Bad state: ', ''));
    }
  }

  void _handleKey(KeyEvent event) {
    if (_phase != _MatchPhase.playing || event is! KeyDownEvent) return;
    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_answer.isNotEmpty) unawaited(_submit());
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      final value = _answer.toString();
      if (value.isNotEmpty) {
        _answer
          ..clear()
          ..write(value.substring(0, value.length - 1));
        setState(() {});
      }
      return;
    }
    final character = event.character?.toLowerCase();
    if (character == null ||
        !RegExp(r'^[a-z]$').hasMatch(character) ||
        _answer.length >= (_word?.word.length ?? 0)) {
      return;
    }
    _answer.write(character);
    setState(() {});
  }

  Future<void> _submit() async {
    if (_submitting || _matchId == null || _answer.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await _service.submitRound(_matchId!, _answer.toString());
      if (mounted) setState(() => _phase = _MatchPhase.waiting);
    } catch (error) {
      _notice(error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    final active =
        _matchId != null &&
        _match?.status == 'active' &&
        _phase != _MatchPhase.complete;
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(active ? 'Forfeit this match?' : 'Leave matchmaking?'),
        content: Text(
          active
              ? 'The match is active. Leaving awards the win to your opponent and deducts 16 rating points.'
              : 'Your place in the matchmaking queue will be cancelled.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(active ? 'Forfeit and leave' : 'Leave'),
          ),
        ],
      ),
    );
    if (leave != true) return;
    setState(() => _leaving = true);
    try {
      final cleanup = active
          ? _service.forfeit(_matchId!)
          : widget.privateRoomCode != null
          ? _service.cancelPrivateRoom(widget.privateRoomCode!)
          : _service.cancelQueue();
      await cleanup.timeout(const Duration(seconds: 3));
    } catch (_) {
      // The route should remain escapable if the network disappears.
    }
    if (mounted) {
      unawaited(SoundEffectsService.instance.back());
      setState(() => _allowPop = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final navigator = Navigator.of(context);
        navigator.canPop() ? navigator.pop() : context.go('/compete');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop || _phase == _MatchPhase.complete,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_leave());
      },
      child: Scaffold(
        body: AlliamBackground(
          child: SafeArea(
            child: KeyboardListener(
              focusNode: _focus,
              autofocus: true,
              onKeyEvent: _handleKey,
              child: Stack(
                children: [
                  Positioned.fill(child: _content(context)),
                  Positioned(
                    left: 16,
                    top: 10,
                    child: IconButton(
                      tooltip: 'Leave match',
                      onPressed: _leave,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return switch (_phase) {
      _MatchPhase.preparing => const _MatchStatus(
        icon: Icons.sync_rounded,
        title: 'Preparing your arena',
        body: 'Checking your player profile and competition access.',
        loading: true,
      ),
      _MatchPhase.queue => _MatchStatus(
        icon: Icons.person_search_outlined,
        title: widget.privateRoomCode == null
            ? 'Finding a speller'
            : 'Room ${widget.privateRoomCode}',
        body: widget.privateRoomCode == null
            ? 'Keep this screen open. Your match begins when another player joins.'
            : 'Share this code. The match begins when your opponent joins.',
        loading: true,
        action: OutlinedButton(
          onPressed: _leaving ? null : _leave,
          child: Text(
            _leaving
                ? 'Leaving…'
                : widget.privateRoomCode == null
                ? 'Cancel search'
                : 'Leave room',
          ),
        ),
      ),
      _MatchPhase.playing => _arena(context, waiting: false),
      _MatchPhase.waiting => _arena(context, waiting: true),
      _MatchPhase.complete => _results(context),
      _MatchPhase.error => _MatchStatus(
        icon: Icons.error_outline_rounded,
        title: 'Competition unavailable',
        body: _error ?? 'Please try again.',
        action: FilledButton(
          onPressed: () => context.go('/compete'),
          child: const Text('Back to arenas'),
        ),
      ),
    };
  }

  Widget _arena(BuildContext context, {required bool waiting}) {
    final match = _match;
    final word = _word;
    if (match == null || word == null) {
      return const _MatchStatus(
        icon: Icons.volume_up_outlined,
        title: 'Loading your word',
        body: 'Get ready.',
        loading: true,
      );
    }
    final opponentUid = match.opponentUid(_uid);
    final opponent = match.playerProfiles[opponentUid];
    final me = match.playerProfiles[_uid];
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 54, 24, 40),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            children: [
              Text(
                'Round ${match.currentRound + 1}/${match.totalRounds}',
                style: const TextStyle(
                  color: AlliamColors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              _ScoreBar(
                myName: me?.name ?? 'You',
                myScore: match.scores[_uid] ?? 0,
                opponentName: opponent?.name ?? 'Opponent',
                opponentScore: match.scores[opponentUid] ?? 0,
              ),
              const SizedBox(height: 28),
              Text(
                waiting ? 'Opponent spelling' : 'Your word',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AlliamColors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                waiting ? 'Your answer is locked in.' : 'Listen, then spell',
              ),
              const SizedBox(height: 30),
              SizedBox(
                height: 250,
                child: Center(
                  child: LetterDiamonds(
                    word: word.word,
                    entered: _answer.toString(),
                    revealWord: false,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: waiting
                    ? const _WaitingForOpponent()
                    : Column(
                        children: [
                          Wrap(
                            spacing: 12,
                            children: [
                              OutlinedButton.icon(
                                onPressed: () {
                                  final value = _answer.toString();
                                  if (value.isEmpty) return;
                                  _answer
                                    ..clear()
                                    ..write(
                                      value.substring(0, value.length - 1),
                                    );
                                  setState(() {});
                                },
                                icon: const Icon(Icons.undo_rounded),
                                label: const Text('Undo'),
                              ),
                              FilledButton(
                                onPressed: _answer.isEmpty || _submitting
                                    ? null
                                    : _submit,
                                child: Text(
                                  _submitting ? 'Submitting…' : 'Submit',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () => _audio.play(word.pronunciation),
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Repeat'),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _results(BuildContext context) {
    final match = _match!;
    final opponentUid = match.opponentUid(_uid);
    final opponent = match.playerProfiles[opponentUid]?.name ?? 'Opponent';
    final mine = match.scores[_uid] ?? 0;
    final theirs = match.scores[opponentUid] ?? 0;
    final draw = match.winnerUid == null && match.completionReason != 'forfeit';
    final won = match.winnerUid == _uid;
    final forfeit = match.completionReason == 'forfeit';
    final heading = draw
        ? 'Draw'
        : won
        ? forfeit
              ? 'Opponent forfeited'
              : 'Victory'
        : forfeit
        ? 'Match forfeited'
        : 'Match complete';
    final minutes = DateTime.now()
        .difference(_startedAt)
        .inMinutes
        .clamp(1, 99);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Container(
                width: 104,
                height: 104,
                decoration: BoxDecoration(
                  color: won
                      ? const Color(0xFFE4F3DF)
                      : AlliamColors.surfaceStrong,
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: won ? AlliamColors.success : AlliamColors.line,
                    width: 2,
                  ),
                ),
                child: Icon(
                  won ? Icons.emoji_events_outlined : Icons.flag_outlined,
                  color: won ? AlliamColors.success : AlliamColors.coral,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                heading,
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AlliamColors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text('You $mine — $theirs $opponent'),
              const SizedBox(height: 28),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _ResultStat(
                    label: 'Rating',
                    value: draw
                        ? '+4'
                        : won
                        ? '+16'
                        : '-16',
                  ),
                  _ResultStat(label: 'Rounds', value: '$mine'),
                  _ResultStat(label: 'Time', value: '${minutes}m'),
                ],
              ),
              const SizedBox(height: 28),
              Wrap(
                spacing: 12,
                children: [
                  if (!forfeit)
                    OutlinedButton.icon(
                      onPressed: () => context.go('/compete'),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('New match'),
                    ),
                  FilledButton(
                    onPressed: () => context.go('/home'),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _phase = _MatchPhase.error;
    });
  }

  void _notice(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _MatchStatus extends StatelessWidget {
  const _MatchStatus({
    required this.icon,
    required this.title,
    required this.body,
    this.loading = false,
    this.action,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool loading;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AlliamColors.coral, size: 52),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: AlliamColors.coral,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Text(body, textAlign: TextAlign.center),
          ),
          if (loading) ...[
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
          if (action != null) ...[const SizedBox(height: 24), action!],
        ],
      ),
    ),
  );
}

class _ScoreBar extends StatelessWidget {
  const _ScoreBar({
    required this.myName,
    required this.myScore,
    required this.opponentName,
    required this.opponentScore,
  });

  final String myName;
  final int myScore;
  final String opponentName;
  final int opponentScore;

  @override
  Widget build(BuildContext context) => Container(
    height: 66,
    padding: const EdgeInsets.symmetric(horizontal: 22),
    decoration: BoxDecoration(
      color: AlliamColors.surface,
      borderRadius: BorderRadius.circular(25),
      border: Border.all(color: AlliamColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x24D7B69B),
          blurRadius: 24,
          offset: Offset(8, 14),
        ),
      ],
    ),
    child: Row(
      children: [
        Expanded(child: Text(myName, overflow: TextOverflow.ellipsis)),
        Text(
          '$myScore',
          style: const TextStyle(
            color: AlliamColors.coral,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18),
          child: Text('—'),
        ),
        Text(
          '$opponentScore',
          style: const TextStyle(
            color: AlliamColors.coral,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            opponentName,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

class _WaitingForOpponent extends StatelessWidget {
  const _WaitingForOpponent();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const Icon(Icons.hourglass_top_rounded, color: AlliamColors.coral),
      const SizedBox(height: 10),
      const Text(
        'Waiting for opponent',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: const LinearProgressIndicator(minHeight: 5),
      ),
    ],
  );
}

class _ResultStat extends StatelessWidget {
  const _ResultStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    width: 150,
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: AlliamColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AlliamColors.line),
    ),
    child: Column(
      children: [
        Text(label),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    ),
  );
}
