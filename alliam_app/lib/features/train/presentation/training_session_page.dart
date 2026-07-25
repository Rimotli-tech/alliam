import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_background.dart';
import '../data/training_audio_service.dart';
import '../data/training_progress_repository.dart';
import '../data/word_repository.dart';
import '../domain/spelling_word.dart';
import '../domain/training_mode.dart';
import 'widgets/letter_diamonds.dart';

enum _SessionPhase {
  loading,
  intro,
  countdown,
  teaching,
  attempt,
  feedback,
  complete,
  error,
}

class TrainingSessionPage extends StatefulWidget {
  const TrainingSessionPage({required this.mode, super.key});

  final TrainingMode mode;

  @override
  State<TrainingSessionPage> createState() => _TrainingSessionPageState();
}

class _TrainingSessionPageState extends State<TrainingSessionPage> {
  late final WordRepository _words;
  late final TrainingAudioService _audio;
  late final TrainingProgressRepository _progress;
  final _answer = TextEditingController();
  final _focus = FocusNode();
  List<SpellingWord> _sessionWords = [];
  _SessionPhase _phase = _SessionPhase.loading;
  int _index = 0;
  int _correct = 0;
  int _countdown = 0;
  int _secondsLeft = 20;
  int _lives = 3;
  int _streak = 0;
  int _activeSpellingLetter = -1;
  int _runId = 0;
  bool _showHeldWord = false;
  bool _lastCorrect = false;
  String _level = 'Foundation';
  int _wordCount = 5;
  Timer? _timer;
  String? _error;
  final Set<String> _incorrectWords = {};

  SpellingWord? get _current =>
      _sessionWords.isEmpty ? null : _sessionWords[_index];

  @override
  void initState() {
    super.initState();
    _words = WordRepository(FirebaseFirestore.instance);
    _audio = TrainingAudioService(
      FirebaseStorage.instance,
      FirebaseFirestore.instance,
    );
    _progress = TrainingProgressRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    _loadSession();
  }

  @override
  void dispose() {
    _runId++;
    _timer?.cancel();
    _answer.dispose();
    _focus.dispose();
    _audio.dispose();
    super.dispose();
  }

  Future<void> _loadSession() async {
    final run = ++_runId;
    _timer?.cancel();
    _answer.clear();
    setState(() {
      _phase = _SessionPhase.loading;
      _error = null;
      _index = 0;
      _correct = 0;
      _lives = 3;
      _streak = 0;
      _incorrectWords.clear();
    });
    try {
      final words = await _words.load(level: _level, count: _wordCount);
      if (!_valid(run)) return;
      setState(() => _sessionWords = words);
      await _prepareCurrent(firstWord: true, run: run);
    } catch (error) {
      if (!_valid(run)) return;
      setState(() {
        _phase = _SessionPhase.error;
        _error = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _prepareCurrent({required bool firstWord, int? run}) async {
    final activeRun = run ?? ++_runId;
    _timer?.cancel();
    _answer.clear();
    _lastCorrect = false;
    _showHeldWord = false;
    setState(() {
      _phase = firstWord ? _SessionPhase.intro : _SessionPhase.teaching;
      _activeSpellingLetter = -1;
    });

    if (firstWord) {
      await _wait(
        widget.mode == TrainingMode.hearAndSpell
            ? const Duration(milliseconds: 500)
            : const Duration(seconds: 2),
        activeRun,
      );
    } else {
      await _wait(const Duration(milliseconds: 550), activeRun);
    }
    if (!_valid(activeRun)) return;

    if (widget.mode == TrainingMode.hearAndSpell) {
      if (firstWord) {
        await _runCountdown(3, activeRun);
        if (!_valid(activeRun)) return;
      }
      await _teachHearAndSpell(activeRun);
    } else if (widget.mode == TrainingMode.wordFlash) {
      if (firstWord) {
        await _runCountdown(3, activeRun);
        if (!_valid(activeRun)) return;
      }
      setState(() => _phase = _SessionPhase.teaching);
      await _wait(const Duration(seconds: 3), activeRun);
      if (_valid(activeRun)) _beginAttempt();
    } else if (widget.mode == TrainingMode.reverseSpell) {
      if (firstWord) {
        await _runCountdown(3, activeRun);
        if (!_valid(activeRun)) return;
      }
      setState(() => _phase = _SessionPhase.teaching);
      await _spellCurrent(activeRun);
      if (_valid(activeRun)) _beginAttempt();
    } else if ({
      TrainingMode.missingLetters,
      TrainingMode.patternDrill,
      TrainingMode.similarWords,
      TrainingMode.buildTheWord,
      TrainingMode.themeChallenge,
    }.contains(widget.mode)) {
      if (firstWord) {
        await _runCountdown(3, activeRun);
        if (!_valid(activeRun)) return;
      }
      setState(() => _phase = _SessionPhase.teaching);
      await _playPronunciation();
      if (!_valid(activeRun)) return;
      await _wait(const Duration(seconds: 2), activeRun);
      if (_valid(activeRun)) _beginAttempt();
    } else {
      if (firstWord) {
        await _runCountdown(3, activeRun);
        if (!_valid(activeRun)) return;
      }
      setState(() => _phase = _SessionPhase.teaching);
      await _playPronunciation();
      if (_valid(activeRun)) {
        _beginAttempt();
        if (widget.mode.isTimed) _startTimer();
      }
    }
  }

  Future<void> _spellCurrent(int run) async {
    try {
      await _audio.spell(
        _current!.word,
        onLetter: (index) {
          if (mounted && _valid(run)) {
            setState(() => _activeSpellingLetter = index);
          }
        },
      );
    } catch (error) {
      _showAudioWarning(error);
    }
  }

  Future<void> _teachHearAndSpell(int run) async {
    setState(() => _phase = _SessionPhase.teaching);
    await _wait(const Duration(milliseconds: 500), run);
    if (!_valid(run)) return;
    await _playPronunciation();
    await _wait(const Duration(seconds: 3), run);
    if (!_valid(run)) return;
    await _playPronunciation();
    await _wait(const Duration(milliseconds: 650), run);
    if (!_valid(run)) return;
    await _spellCurrent(run);
    if (_valid(run)) _beginAttempt();
  }

  Future<void> _runCountdown(int from, int run) async {
    setState(() => _phase = _SessionPhase.countdown);
    for (var count = from; count > 0; count--) {
      if (!_valid(run)) return;
      setState(() => _countdown = count);
      await _wait(const Duration(seconds: 1), run);
    }
  }

  void _beginAttempt() {
    setState(() {
      _phase = _SessionPhase.attempt;
      _activeSpellingLetter = -1;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  Future<void> _playPronunciation() async {
    try {
      await _audio.play(_current?.pronunciation);
    } catch (error) {
      _showAudioWarning(error);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _secondsLeft = 20);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _phase != _SessionPhase.attempt) {
        timer.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        timer.cancel();
        setState(() => _secondsLeft = 0);
        _submit(timedOut: true);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _handleKeyEvent(KeyEvent event) {
    if (_phase != _SessionPhase.attempt || event is! KeyDownEvent) return;

    if (event.logicalKey == LogicalKeyboardKey.enter) {
      if (_answer.text.isNotEmpty) unawaited(_submit());
      return;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_answer.text.isNotEmpty) {
        _answer.text = _answer.text.substring(0, _answer.text.length - 1);
        setState(() {});
      }
      return;
    }

    final character = event.character?.toLowerCase();
    if (character == null ||
        !RegExp(r'^[a-z]$').hasMatch(character) ||
        _answer.text.length >= (_current?.word.length ?? 0)) {
      return;
    }
    _answer.text += character;
    setState(() {});
  }

  Future<void> _submit({bool timedOut = false}) async {
    if (_phase != _SessionPhase.attempt) return;
    _timer?.cancel();
    final correct = !timedOut && _answer.text == _current!.word;
    if (correct) {
      _incorrectWords.remove(_current!.word);
    } else {
      _incorrectWords.add(_current!.word);
    }
    setState(() {
      _lastCorrect = correct;
      _correct += correct ? 1 : 0;
      _streak = correct ? _streak + 1 : 0;
      if (!correct && widget.mode == TrainingMode.survivalRun) _lives--;
      _phase = _SessionPhase.feedback;
    });
  }

  Future<void> _next() async {
    if (widget.mode == TrainingMode.survivalRun && _lives <= 0) {
      setState(() => _phase = _SessionPhase.complete);
      await _recordProgress();
      return;
    }
    if (_index >= _sessionWords.length - 1) {
      setState(() => _phase = _SessionPhase.complete);
      await _recordProgress();
      return;
    }
    setState(() => _index++);
    await _prepareCurrent(firstWord: false);
  }

  Future<void> _recordProgress() async {
    unawaited(
      _progress.recordSession(
        mode: widget.mode,
        correct: _correct,
        attempted: _index + 1,
        incorrectWords: _incorrectWords,
      ),
    );
  }

  Future<void> _openSettings() async {
    var level = _level;
    var count = _wordCount;
    final changed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AlliamColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                26,
                24,
                26,
                24 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Session settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AlliamColors.coral,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: level,
                    decoration: const InputDecoration(labelText: 'Word level'),
                    items: const [
                      DropdownMenuItem(
                        value: 'Foundation',
                        child: Text('Foundation'),
                      ),
                      DropdownMenuItem(
                        value: 'Builder',
                        child: Text('Builder'),
                      ),
                      DropdownMenuItem(
                        value: 'Championship',
                        child: Text('Championship'),
                      ),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => level = value ?? level),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<int>(
                    initialValue: count,
                    decoration: const InputDecoration(labelText: 'Words'),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('5 words')),
                      DropdownMenuItem(value: 10, child: Text('10 words')),
                      DropdownMenuItem(value: 15, child: Text('15 words')),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => count = value ?? count),
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Apply and restart'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (changed == true) {
      _level = level;
      _wordCount = count;
      await _loadSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AlliamBackground(
        child: SafeArea(
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 320),
                  child: _content(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          _SessionIconButton(
            tooltip: 'Back to training',
            onPressed: () => context.go('/train'),
            icon: const Icon(Icons.home_outlined),
          ),
          const Spacer(),
          Text(
            '${_sessionWords.isEmpty ? 0 : _index + 1}/${_sessionWords.length}',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const Spacer(),
          _SessionIconButton(
            tooltip: 'Session settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Widget _content(BuildContext context) {
    if (_phase == _SessionPhase.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_phase == _SessionPhase.error) {
      return _CenteredPanel(
        title: 'Training could not start',
        body: _error ?? 'Please try again.',
        action: FilledButton(
          onPressed: _loadSession,
          child: const Text('Try again'),
        ),
      );
    }
    if (_phase == _SessionPhase.complete) return _result(context);
    if (_current == null) return const SizedBox.shrink();

    final intro =
        _phase == _SessionPhase.intro || _phase == _SessionPhase.countdown;
    if (intro) {
      return _intro(context);
    }
    return _exercise(context);
  }

  Widget _intro(BuildContext context) {
    final copy = switch (widget.mode) {
      TrainingMode.hearAndSpell => (
        'Listen carefully',
        'Study the word, hear it pronounced and spelled, then try it yourself',
      ),
      TrainingMode.wordFlash => (
        'Word Flash',
        'Watch closely. The word will appear briefly, then disappear.',
      ),
      TrainingMode.timedDrill => (
        'Timed Drill',
        'Hear the word once, then spell it before the clock expires.',
      ),
      TrainingMode.listenAndSpell => (
        'Listen & Spell',
        'You will hear the word only. Hold it in memory, then spell.',
      ),
      TrainingMode.missingLetters => (
        'Missing Letters',
        'Study the pattern and complete the hidden letters.',
      ),
      TrainingMode.patternDrill => (
        'Pattern Drill',
        'Use the recurring spelling pattern to complete each word.',
      ),
      TrainingMode.similarWords => (
        'Similar Words',
        'Use the meaning to separate commonly confused spellings.',
      ),
      TrainingMode.buildTheWord => (
        'Build the Word',
        'Rearrange the letter pieces into the correct spelling.',
      ),
      TrainingMode.mockBee => (
        'Mock Bee',
        'One word, one attempt. Think carefully before you submit.',
      ),
      TrainingMode.survivalRun => (
        'Survival Run',
        'You have three lives. Keep spelling for as long as you can.',
      ),
      TrainingMode.streakChallenge => (
        'Streak Challenge',
        'Stay accurate and protect your longest correct streak.',
      ),
      TrainingMode.recallLadder => (
        'Recall Ladder',
        'Each correct answer raises the difficulty and the pressure.',
      ),
      TrainingMode.dailyChallenge => (
        'Daily Challenge',
        'Complete today’s shared five-word challenge.',
      ),
      TrainingMode.themeChallenge => (
        'Theme Challenge',
        'Use the word clues to work through a focused collection.',
      ),
      TrainingMode.reverseSpell => (
        'Reverse Spell',
        'Hear the letters in sequence, then identify the complete word.',
      ),
      TrainingMode.missedWords => (
        'Missed Words',
        'Return to difficult words and turn them into strengths.',
      ),
    };
    return Center(
      key: const ValueKey('intro'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              copy.$1,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                color: AlliamColors.coral,
                fontWeight: FontWeight.w700,
                fontSize: 54,
                height: 1.1,
                letterSpacing: -1.8,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              copy.$2,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 34),
            AnimatedOpacity(
              opacity: _phase == _SessionPhase.countdown ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Column(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.58),
                      borderRadius: BorderRadius.circular(34),
                      border: Border.all(
                        color: const Color(0xFFFDDAB9),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x3DD7B69B),
                          blurRadius: 65,
                          offset: Offset(18, 28),
                        ),
                      ],
                    ),
                    child: Text(
                      '$_countdown',
                      style: const TextStyle(
                        color: AlliamColors.coral,
                        fontSize: 54,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'STARTING IN',
                    style: TextStyle(
                      color: AlliamColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.32,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _exercise(BuildContext context) {
    final teaching = _phase == _SessionPhase.teaching;
    final feedback = _phase == _SessionPhase.feedback;
    final reveal =
        feedback ||
        _showHeldWord ||
        widget.mode == TrainingMode.hearAndSpell && teaching ||
        widget.mode == TrainingMode.wordFlash && teaching;
    final title = feedback
        ? _lastCorrect
              ? 'Well done'
              : 'Not quite'
        : teaching
        ? widget.mode == TrainingMode.wordFlash
              ? 'Look closely'
              : 'Listen carefully'
        : widget.mode.isTimed
        ? 'Beat the clock'
        : widget.mode == TrainingMode.reverseSpell
        ? 'Name the word'
        : 'Your turn';

    return KeyboardListener(
      key: ValueKey('exercise-$_index'),
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _focus.requestFocus,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                children: [
                  SizedBox(
                    height: 76,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(
                                color: AlliamColors.coral,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          feedback
                              ? _lastCorrect
                                    ? 'That spelling is correct.'
                                    : 'The correct spelling is shown below.'
                              : teaching
                              ? 'Stay focused.'
                              : 'Type the spelling, then submit.',
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  if (widget.mode == TrainingMode.timedDrill &&
                      _phase == _SessionPhase.attempt) ...[
                    const SizedBox(height: 18),
                    _Clock(seconds: _secondsLeft),
                  ],
                  if (widget.mode.isTimed &&
                      widget.mode != TrainingMode.timedDrill &&
                      _phase == _SessionPhase.attempt) ...[
                    const SizedBox(height: 18),
                    _Clock(seconds: _secondsLeft),
                  ],
                  if (widget.mode == TrainingMode.survivalRun ||
                      widget.mode == TrainingMode.streakChallenge) ...[
                    const SizedBox(height: 14),
                    _RunStatus(
                      lives: widget.mode == TrainingMode.survivalRun
                          ? _lives
                          : null,
                      streak: _streak,
                    ),
                  ],
                  const SizedBox(height: 22),
                  _modePrompt(context, teaching: teaching),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 250,
                    child: Center(
                      child: LetterDiamonds(
                        word: _current!.word,
                        entered: _answer.text,
                        revealWord: reveal,
                        success: feedback && _lastCorrect,
                        activeIndex: teaching ? _activeSpellingLetter : -1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 150,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: _exerciseControls(feedback),
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

  Widget _modePrompt(BuildContext context, {required bool teaching}) {
    final word = _current!.word.toUpperCase();
    final style = Theme.of(context).textTheme.titleLarge?.copyWith(
      color: AlliamColors.text,
      fontWeight: FontWeight.w600,
      letterSpacing: 1.2,
    );
    switch (widget.mode) {
      case TrainingMode.missingLetters:
        final masked = [
          for (var i = 0; i < word.length; i++) i.isOdd ? '_' : word[i],
        ].join(' ');
        return Text(masked, textAlign: TextAlign.center, style: style);
      case TrainingMode.patternDrill:
        final length = word.length;
        final pattern = word.substring(length > 4 ? length - 4 : 0);
        return _ClueChip(
          icon: Icons.pattern_rounded,
          text: 'Pattern  $pattern',
        );
      case TrainingMode.similarWords:
        return _PromptCard(
          label: 'Meaning',
          text: _current!.definition.isEmpty
              ? 'Choose the spelling that matches the word you hear.'
              : _current!.definition,
        );
      case TrainingMode.buildTheWord:
        final pieces = word.split('').reversed;
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final letter in pieces)
              _ClueChip(icon: Icons.drag_indicator_rounded, text: letter),
          ],
        );
      case TrainingMode.themeChallenge:
        final clue = [
          if (_current!.partOfSpeech.isNotEmpty) _current!.partOfSpeech,
          if (_current!.origin.isNotEmpty) _current!.origin,
        ].join(' · ');
        return _ClueChip(
          icon: Icons.flag_outlined,
          text: clue.isEmpty ? 'Today’s collection' : clue,
        );
      case TrainingMode.reverseSpell:
        return _ClueChip(
          icon: Icons.hearing_rounded,
          text: teaching ? 'Listen to the letters' : 'What word did they form?',
        );
      case TrainingMode.recallLadder:
        return _ClueChip(
          icon: Icons.stairs_outlined,
          text: 'Rung ${_index + 1}',
        );
      case TrainingMode.dailyChallenge:
        return const _ClueChip(icon: Icons.today_outlined, text: 'Today’s set');
      case TrainingMode.missedWords:
        return const _ClueChip(
          icon: Icons.replay_rounded,
          text: 'Review round',
        );
      case TrainingMode.mockBee:
        return const _ClueChip(
          icon: Icons.emoji_events_outlined,
          text: 'One attempt',
        );
      default:
        return const SizedBox(height: 0);
    }
  }

  Widget _exerciseControls(bool feedback) {
    if (_phase == _SessionPhase.attempt) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: _answer.text.isEmpty
                    ? null
                    : () {
                        final text = _answer.text;
                        _answer.text = text.substring(0, text.length - 1);
                        _answer.selection = TextSelection.collapsed(
                          offset: _answer.text.length,
                        );
                        setState(() {});
                        _focus.requestFocus();
                      },
                icon: const Icon(Icons.undo_rounded),
                label: const Text('Undo'),
              ),
              FilledButton(
                onPressed: _answer.text.isEmpty ? null : _submit,
                child: const Text('Submit'),
              ),
            ],
          ),
          if (widget.mode == TrainingMode.hearAndSpell ||
              widget.mode == TrainingMode.listenAndSpell ||
              widget.mode == TrainingMode.mockBee) ...[
            const SizedBox(height: 26),
            Wrap(
              spacing: 16,
              children: [
                OutlinedButton.icon(
                  onPressed: _playPronunciation,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Repeat'),
                ),
                if (widget.mode == TrainingMode.hearAndSpell)
                  Listener(
                    onPointerDown: (_) => setState(() => _showHeldWord = true),
                    onPointerUp: (_) => setState(() => _showHeldWord = false),
                    onPointerCancel: (_) =>
                        setState(() => _showHeldWord = false),
                    child: const IgnorePointer(
                      child: OutlinedButton(
                        onPressed: null,
                        child: Text('Hold to flash'),
                      ),
                    ),
                  ),
                if (widget.mode == TrainingMode.listenAndSpell)
                  OutlinedButton.icon(
                    onPressed: () => _showWordInfo('Definition'),
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Definition'),
                  ),
                if (widget.mode == TrainingMode.listenAndSpell)
                  OutlinedButton.icon(
                    onPressed: () => _showWordInfo('Sentence'),
                    icon: const Icon(Icons.format_quote_rounded),
                    label: const Text('Sentence'),
                  ),
                if (widget.mode == TrainingMode.listenAndSpell)
                  OutlinedButton.icon(
                    onPressed: () => _showWordInfo('Origin'),
                    icon: const Icon(Icons.public_rounded),
                    label: const Text('Origin'),
                  ),
                if (widget.mode == TrainingMode.listenAndSpell)
                  OutlinedButton.icon(
                    onPressed: () => _showWordInfo('Part of speech'),
                    icon: const Icon(Icons.category_outlined),
                    label: const Text('Part of speech'),
                  ),
              ],
            ),
          ],
        ],
      );
    }

    if (feedback) {
      return FilledButton(
        onPressed: _next,
        child: Text(
          _index == _sessionWords.length - 1 ? 'View results' : 'Next word',
        ),
      );
    }

    return Icon(
      _activeSpellingLetter >= 0
          ? Icons.graphic_eq_rounded
          : Icons.volume_up_outlined,
      color: AlliamColors.coralSoft,
      size: 38,
    );
  }

  Widget _result(BuildContext context) {
    final attempted = (_index + 1).clamp(0, _sessionWords.length);
    final accuracy = attempted == 0 ? 0 : (_correct / attempted * 100).round();
    return _CenteredPanel(
      key: const ValueKey('complete'),
      title: '$accuracy% accuracy',
      body: widget.mode == TrainingMode.streakChallenge
          ? '$_correct correct · Best streak $_streak'
          : '$_correct of $attempted words correct',
      action: Wrap(
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          OutlinedButton(
            onPressed: _loadSession,
            child: const Text('Train again'),
          ),
          FilledButton(
            onPressed: () => context.go('/train'),
            child: const Text('Choose another mode'),
          ),
        ],
      ),
    );
  }

  Future<void> _wait(Duration duration, int run) async {
    await Future<void>.delayed(duration);
    if (!_valid(run)) return;
  }

  bool _valid(int run) => mounted && run == _runId;

  Future<void> _showWordInfo(String type) async {
    final word = _current!;
    final value = switch (type) {
      'Definition' => word.definition,
      'Sentence' => word.sentence,
      'Origin' => word.origin,
      _ => word.partOfSpeech,
    };
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AlliamColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 26, 28, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                type,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AlliamColors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                value.isEmpty
                    ? 'This information is not available yet.'
                    : value,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    );
    if (mounted) _focus.requestFocus();
  }

  void _showAudioWarning(Object error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text(
            'Recorded audio is unavailable. You can still complete this word.',
          ),
        ),
      );
  }
}

class _ClueChip extends StatelessWidget {
  const _ClueChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AlliamColors.surfaceStrong,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AlliamColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24948D87),
            blurRadius: 22,
            offset: Offset(8, 12),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AlliamColors.coral, size: 19),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(
              color: AlliamColors.text,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 560),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: AlliamColors.surfaceStrong,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AlliamColors.line),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AlliamColors.coral,
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          Text(text, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _RunStatus extends StatelessWidget {
  const _RunStatus({required this.lives, required this.streak});

  final int? lives;
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      children: [
        if (lives != null)
          _ClueChip(
            icon: Icons.favorite_rounded,
            text: '$lives ${lives == 1 ? 'life' : 'lives'}',
          ),
        _ClueChip(icon: Icons.local_fire_department_outlined, text: '$streak'),
      ],
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final urgent = seconds <= 5;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: urgent ? AlliamColors.error : AlliamColors.coral,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        '00:${seconds.toString().padLeft(2, '0')}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _SessionIconButton extends StatelessWidget {
  const _SessionIconButton({
    required this.tooltip,
    required this.onPressed,
    required this.icon,
  });

  final String tooltip;
  final VoidCallback onPressed;
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AlliamColors.surfaceStrong,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AlliamColors.line),
        boxShadow: const [
          BoxShadow(
            color: Color(0x24948D87),
            blurRadius: 22,
            offset: Offset(9, 14),
          ),
        ],
      ),
      child: IconButton(
        tooltip: tooltip,
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        color: AlliamColors.coral,
        iconSize: 21,
        icon: icon,
      ),
    );
  }
}

class _CenteredPanel extends StatelessWidget {
  const _CenteredPanel({
    required this.title,
    required this.body,
    required this.action,
    super.key,
  });

  final String title;
  final String body;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                color: AlliamColors.coral,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(body, textAlign: TextAlign.center),
            const SizedBox(height: 28),
            action,
          ],
        ),
      ),
    );
  }
}
