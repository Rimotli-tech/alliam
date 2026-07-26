import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_background.dart';
import '../../../core/audio/background_music_service.dart';
import '../../../core/audio/sound_effects_service.dart';
import '../../auth/data/account_repository.dart';
import '../../settings/data/settings_repository.dart';
import '../data/training_audio_service.dart';
import '../data/training_progress_repository.dart';
import '../data/session_audio_manifest.dart';
import '../data/word_repository.dart';
import '../domain/spelling_word.dart';
import '../domain/training_mode.dart';
import '../domain/learner_pathway.dart';
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
  int _score = 0;
  int _activeSpellingLetter = -1;
  int _typedLength = 0;
  int _runId = 0;
  bool _showHeldWord = false;
  bool _flashUsed = false;
  bool _lastCorrect = false;
  String _learnerName = 'Speller';
  String _level = 'Foundation';
  int _wordCount = 5;
  Timer? _timer;
  String? _error;
  final Set<String> _incorrectWords = {};
  final Set<int> _usedTileIndices = {};
  final List<int> _usedTileOrder = [];
  late final SettingsRepository _settings;
  String _missingVariant = 'Multiple letters';
  String _patternFocus = 'Automatic';
  TrainingSessionOutcome? _outcome;
  bool _progressRecorded = false;

  SpellingWord? get _current =>
      _sessionWords.isEmpty ? null : _sessionWords[_index];

  @override
  void initState() {
    super.initState();
    _words = WordRepository(FirebaseFirestore.instance);
    _audio = TrainingAudioService.shared(
      FirebaseStorage.instance,
      FirebaseFirestore.instance,
    );
    _progress = TrainingProgressRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    _settings = SettingsRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    _loadSession();
  }

  @override
  void dispose() {
    _runId++;
    _timer?.cancel();
    unawaited(BackgroundMusicService.instance.leaveExercise());
    _answer.dispose();
    _focus.dispose();
    unawaited(_audio.stop());
    super.dispose();
  }

  Future<void> _loadSession() async {
    final run = ++_runId;
    _timer?.cancel();
    _answer.clear();
    _typedLength = 0;
    setState(() {
      _phase = _SessionPhase.loading;
      _error = null;
      _index = 0;
      _correct = 0;
      _score = 0;
      _outcome = null;
      _progressRecorded = false;
      _lives = 3;
      _streak = 0;
      _incorrectWords.clear();
    });
    try {
      final preferences = await _settings.load();
      final user = FirebaseAuth.instance.currentUser;
      var pathwayLevel = preferences.level;
      if (user != null && preferences.automaticPathway) {
        final session = await AccountRepository(
          FirebaseFirestore.instance,
        ).load(user);
        _learnerName = session.activeLearnerName.trim().split(' ').first;
        pathwayLevel = LearnerPathway.stage(
          session.activeLearner?.journey['stage']?.toString(),
        ).wordLevel;
      }
      final module = preferences.module(widget.mode.slug);
      _level = pathwayLevel;
      _wordCount = (module['wordCount'] as num?)?.round() ?? _wordCount;
      _missingVariant = module['missingVariant']?.toString() ?? _missingVariant;
      _patternFocus = module['patternFocus']?.toString() ?? _patternFocus;
      final words = await _words.load(level: _level, count: _wordCount);
      if (!_valid(run)) return;
      await _audio.prepareSession(words);
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
    _typedLength = 0;
    _lastCorrect = false;
    _showHeldWord = false;
    _flashUsed = false;
    _usedTileIndices.clear();
    _usedTileOrder.clear();
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

    if (firstWord) {
      await _runCountdown(3, activeRun);
      if (!_valid(activeRun)) return;
    }
    setState(() => _phase = _SessionPhase.teaching);
    unawaited(SoundEffectsService.instance.wordEntry());

    if (widget.mode == TrainingMode.hearAndSpell) {
      await _teachHearAndSpell(activeRun);
    } else if (widget.mode == TrainingMode.wordFlash) {
      await _wait(const Duration(seconds: 3), activeRun);
      if (_valid(activeRun)) _beginAttempt();
    } else if (widget.mode == TrainingMode.reverseSpell) {
      await _spellCurrent(activeRun);
      if (_valid(activeRun)) _beginAttempt();
    } else if ({
      TrainingMode.missingLetters,
      TrainingMode.patternDrill,
      TrainingMode.similarWords,
      TrainingMode.buildTheWord,
      TrainingMode.themeChallenge,
    }.contains(widget.mode)) {
      await _playPronunciation();
      if (!_valid(activeRun)) return;
      await _wait(const Duration(seconds: 2), activeRun);
      if (_valid(activeRun)) _beginAttempt();
    } else {
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
    await BackgroundMusicService.instance.pauseForCountdown();
    try {
      setState(() => _phase = _SessionPhase.countdown);
      for (var count = from; count > 0; count--) {
        if (!_valid(run)) return;
        setState(() => _countdown = count);
        unawaited(SoundEffectsService.instance.countdown());
        await _wait(const Duration(seconds: 1), run);
      }
    } finally {
      await BackgroundMusicService.instance.resumeAfterCountdown();
    }
  }

  void _beginAttempt() {
    setState(() {
      _phase = _SessionPhase.attempt;
      _activeSpellingLetter = -1;
    });
    if ({
      TrainingMode.similarWords,
      TrainingMode.buildTheWord,
    }.contains(widget.mode)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
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

  Future<void> _submit({bool timedOut = false}) async {
    if (_phase != _SessionPhase.attempt) return;
    _timer?.cancel();
    final correct = !timedOut && _answer.text.toLowerCase() == _expectedAnswer;
    if (correct) {
      _incorrectWords.remove(_current!.word);
      unawaited(SoundEffectsService.instance.correct());
    } else {
      _incorrectWords.add(_current!.word);
      unawaited(SoundEffectsService.instance.wrongAnswer());
    }
    setState(() {
      _lastCorrect = correct;
      _correct += correct ? 1 : 0;
      _score += correct ? 100 : 0;
      _streak = correct ? _streak + 1 : 0;
      if (!correct && widget.mode == TrainingMode.survivalRun) _lives--;
      _phase = _SessionPhase.feedback;
    });
    if (_index == _sessionWords.length - 1) {
      final run = _runId;
      await _wait(const Duration(milliseconds: 850), run);
      if (!_valid(run)) return;
      await _recordProgress();
      if (mounted) setState(() => _phase = _SessionPhase.complete);
    }
  }

  Future<void> _next() async {
    if (widget.mode == TrainingMode.survivalRun && _lives <= 0) {
      await _recordProgress();
      if (mounted) setState(() => _phase = _SessionPhase.complete);
      return;
    }
    if (_index >= _sessionWords.length - 1) {
      await _recordProgress();
      if (mounted) setState(() => _phase = _SessionPhase.complete);
      return;
    }
    unawaited(SoundEffectsService.instance.nextWord());
    setState(() => _index++);
    await _prepareCurrent(firstWord: false);
  }

  Future<void> _recordProgress() async {
    if (_progressRecorded) return;
    _progressRecorded = true;
    try {
      final outcome = await _progress.recordSession(
        mode: widget.mode,
        correct: _correct,
        attempted: _index + 1,
        incorrectWords: _incorrectWords,
      );
      if (mounted) setState(() => _outcome = outcome);
    } catch (_) {
      // Completion remains available offline; the session can be retried.
    }
  }

  Future<void> _openSettings() async {
    var count = _wordCount;
    var missingVariant = _missingVariant;
    var patternFocus = _patternFocus;
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.route_outlined),
                    title: Text(_level),
                    subtitle: const Text(
                      'Word level follows the learner pathway',
                    ),
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
                  if (widget.mode == TrainingMode.missingLetters) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: missingVariant,
                      decoration: const InputDecoration(
                        labelText: 'Missing letters',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'One letter',
                          child: Text('One letter'),
                        ),
                        DropdownMenuItem(
                          value: 'Multiple letters',
                          child: Text('Multiple letters'),
                        ),
                        DropdownMenuItem(
                          value: 'Vowels only',
                          child: Text('Vowels only'),
                        ),
                        DropdownMenuItem(
                          value: 'Difficult letters',
                          child: Text('Difficult letters'),
                        ),
                      ],
                      onChanged: (value) => setSheetState(
                        () => missingVariant = value ?? missingVariant,
                      ),
                    ),
                  ],
                  if (widget.mode == TrainingMode.patternDrill) ...[
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: patternFocus,
                      decoration: const InputDecoration(labelText: 'Pattern'),
                      items: const [
                        DropdownMenuItem(
                          value: 'Automatic',
                          child: Text('Automatic'),
                        ),
                        DropdownMenuItem(value: '-tion', child: Text('-tion')),
                        DropdownMenuItem(value: '-sion', child: Text('-sion')),
                        DropdownMenuItem(
                          value: 'Silent letters',
                          child: Text('Silent letters'),
                        ),
                        DropdownMenuItem(
                          value: 'Double consonants',
                          child: Text('Double consonants'),
                        ),
                      ],
                      onChanged: (value) => setSheetState(
                        () => patternFocus = value ?? patternFocus,
                      ),
                    ),
                  ],
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
      _wordCount = count;
      _missingVariant = missingVariant;
      _patternFocus = patternFocus;
      await _settings.saveModule(widget.mode.slug, {
        'wordCount': count,
        'missingVariant': missingVariant,
        'patternFocus': patternFocus,
      });
      await _loadSession();
    }
  }

  List<int> get _missingIndices {
    final word = _current!.word;
    if (_missingVariant == 'One letter') return [word.length ~/ 2];
    if (_missingVariant == 'Vowels only') {
      final values = <int>[
        for (var index = 0; index < word.length; index++)
          if ('aeiou'.contains(word[index])) index,
      ];
      return values.isEmpty ? [word.length ~/ 2] : values;
    }
    if (_missingVariant == 'Difficult letters') {
      final values = <int>[
        for (var index = 0; index < word.length; index++)
          if ('cqxyzph'.contains(word[index])) index,
      ];
      return values.isEmpty ? [word.length ~/ 2] : values;
    }
    return [
      for (var index = 0; index < word.length; index++)
        if (index.isOdd) index,
    ];
  }

  String get _patternTarget {
    final word = _current!.word;
    for (final ending in const [
      'tion',
      'sion',
      'cian',
      'ious',
      'ance',
      'ence',
    ]) {
      if (word.endsWith(ending)) return ending;
    }
    return word.substring((word.length - 3).clamp(0, word.length));
  }

  String get _expectedAnswer => switch (widget.mode) {
    TrainingMode.missingLetters =>
      _missingIndices.map((index) => _current!.word[index]).join(),
    TrainingMode.patternDrill => _patternTarget,
    _ => _current!.word,
  };

  String get _similarDistractor {
    const known = {
      'necessary': 'neccessary',
      'separate': 'seperate',
      'conscience': 'conscious',
      'privilege': 'priviledge',
      'pronunciation': 'pronounciation',
      'beautiful': 'beautifull',
      'mischievous': 'mischievious',
      'rhythm': 'rythm',
    };
    return known[_current!.word] ??
        '${_current!.word.substring(0, _current!.word.length - 1)}e';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AlliamBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Column(
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
              if (_phase == _SessionPhase.attempt ||
                  _phase == _SessionPhase.feedback)
                Positioned(
                  left: 18,
                  bottom: 18,
                  child: _SessionScore(
                    key: ValueKey('score-$_score'),
                    learnerName: _learnerName,
                    score: _score,
                    celebrate: _phase == _SessionPhase.feedback && _lastCorrect,
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
            onPressed: () {
              unawaited(SoundEffectsService.instance.back());
              context.go('/train');
            },
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
      return _AudioPreparationPanel(audio: _audio);
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
        'Hear it. Study it. Spell it.',
      ),
      TrainingMode.wordFlash => (
        'Word Flash',
        'See it briefly. Spell from memory.',
      ),
      TrainingMode.timedDrill => (
        'Timed Drill',
        'Spell accurately against the clock.',
      ),
      TrainingMode.listenAndSpell => (
        'Listen & Spell',
        'Hear it once. Spell from memory.',
      ),
      TrainingMode.missingLetters => (
        'Missing Letters',
        'Complete the hidden letters.',
      ),
      TrainingMode.patternDrill => (
        'Pattern Drill',
        'Master a recurring spelling pattern.',
      ),
      TrainingMode.similarWords => (
        'Similar Words',
        'Separate commonly confused spellings.',
      ),
      TrainingMode.buildTheWord => (
        'Build the Word',
        'Build the spelling from its pieces.',
      ),
      TrainingMode.mockBee => ('Mock Bee', 'One word. One careful attempt.'),
      TrainingMode.survivalRun => (
        'Survival Run',
        'Three lives. Keep spelling.',
      ),
      TrainingMode.streakChallenge => (
        'Streak Challenge',
        'Protect your longest correct streak.',
      ),
      TrainingMode.recallLadder => (
        'Recall Ladder',
        'Climb as recall gets harder.',
      ),
      TrainingMode.dailyChallenge => (
        'Daily Challenge',
        'Complete today’s shared word set.',
      ),
      TrainingMode.themeChallenge => (
        'Theme Challenge',
        'Spell through a focused collection.',
      ),
      TrainingMode.reverseSpell => (
        'Reverse Spell',
        'Hear the letters. Name the word.',
      ),
      TrainingMode.missedWords => (
        'Missed Words',
        'Turn difficult words into strengths.',
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

    return GestureDetector(
      key: ValueKey('exercise-$_index'),
      behavior: HitTestBehavior.translucent,
      onTap: () {
        if (_phase != _SessionPhase.attempt ||
            _answer.text.length >= _current!.word.length) {
          return;
        }
        _focus.requestFocus();
        SystemChannels.textInput.invokeMethod<void>('TextInput.show');
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Column(
              children: [
                if (_phase == _SessionPhase.attempt &&
                    widget.mode != TrainingMode.similarWords &&
                    widget.mode != TrainingMode.buildTheWord)
                  SizedBox(
                    width: 1,
                    height: 1,
                    child: Opacity(
                      opacity: 0.01,
                      child: TextField(
                        controller: _answer,
                        focusNode: _focus,
                        autofocus: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        enableInteractiveSelection: false,
                        showCursor: false,
                        textCapitalization: TextCapitalization.none,
                        keyboardType: TextInputType.text,
                        textInputAction: TextInputAction.done,
                        maxLength: _current!.word.length,
                        buildCounter:
                            (
                              context, {
                              required currentLength,
                              required isFocused,
                              required maxLength,
                            }) => null,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp('[a-zA-Z]')),
                          _LowerCaseTextFormatter(),
                        ],
                        onChanged: (value) {
                          if (value.length > _typedLength) {
                            unawaited(SoundEffectsService.instance.key());
                          }
                          _typedLength = value.length;
                          setState(() {});
                          if (value.length >= _current!.word.length) {
                            _focus.unfocus();
                            SystemChannels.textInput.invokeMethod<void>(
                              'TextInput.hide',
                            );
                          }
                        },
                        onSubmitted: (_) {
                          if (_answer.text.isNotEmpty) unawaited(_submit());
                        },
                      ),
                    ),
                  ),
                SizedBox(
                  height: 76,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      if (feedback && _lastCorrect)
                        Positioned(
                          top: -62,
                          child: _SuccessCheck(
                            key: ValueKey('success-check-$_index'),
                          ),
                        ),
                      Column(
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
                      word: _expectedAnswer,
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
        final missing = _missingIndices.toSet();
        final masked = [
          for (var i = 0; i < word.length; i++)
            missing.contains(i) ? '_' : word[i],
        ].join(' ');
        return Text(masked, textAlign: TextAlign.center, style: style);
      case TrainingMode.patternDrill:
        final target = _patternTarget.toUpperCase();
        final stem = word.substring(0, word.length - target.length);
        return _PromptCard(
          label: _patternFocus == 'Automatic'
              ? 'Complete the pattern'
              : _patternFocus,
          text: '$stem _ _ _',
        );
      case TrainingMode.similarWords:
        return Column(
          children: [
            _PromptCard(
              label: 'Meaning',
              text: _current!.definition.isEmpty
                  ? 'Choose the spelling that matches the word you hear.'
                  : _current!.definition,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final option in [_current!.word, _similarDistractor])
                  OutlinedButton(
                    onPressed: _phase != _SessionPhase.attempt
                        ? null
                        : () {
                            _answer.text = option;
                            setState(() {});
                            unawaited(_submit());
                          },
                    child: Text(option),
                  ),
              ],
            ),
          ],
        );
      case TrainingMode.buildTheWord:
        final pieces = word.split('').reversed.toList();
        return Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var index = 0; index < pieces.length; index++)
              OutlinedButton(
                onPressed:
                    _phase != _SessionPhase.attempt ||
                        _usedTileIndices.contains(index)
                    ? null
                    : () {
                        _usedTileIndices.add(index);
                        _usedTileOrder.add(index);
                        _answer.text += pieces[index].toLowerCase();
                        setState(() {});
                      },
                child: Text(pieces[index]),
              ),
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
              SizedBox(
                width: 58,
                height: 58,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder(),
                  ),
                  onPressed: _answer.text.isEmpty
                      ? null
                      : () {
                          if (widget.mode == TrainingMode.buildTheWord &&
                              _usedTileOrder.isNotEmpty) {
                            _usedTileIndices.remove(
                              _usedTileOrder.removeLast(),
                            );
                          }
                          final text = _answer.text;
                          _answer.text = text.substring(0, text.length - 1);
                          _answer.selection = TextSelection.collapsed(
                            offset: _answer.text.length,
                          );
                          _typedLength = _answer.text.length;
                          setState(() {});
                          _focus.requestFocus();
                        },
                  child: const Icon(Icons.undo_rounded),
                ),
              ),
              SizedBox(
                width: 150,
                height: 60,
                child: FilledButton(
                  onPressed: _answer.text.isEmpty ? null : _submit,
                  child: const Text(
                    'Submit',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                ),
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
                    onPointerDown: (_) {
                      if (_flashUsed) return;
                      setState(() {
                        _flashUsed = true;
                        _showHeldWord = true;
                      });
                    },
                    onPointerUp: (_) {
                      if (_showHeldWord) {
                        setState(() => _showHeldWord = false);
                      }
                    },
                    onPointerCancel: (_) =>
                        setState(() => _showHeldWord = false),
                    child: IgnorePointer(
                      child: OutlinedButton(
                        onPressed: _flashUsed ? null : () {},
                        child: Text(
                          _flashUsed ? 'Flash used' : 'Hold to flash',
                        ),
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
      return SizedBox(
        width: 164,
        height: 60,
        child: FilledButton(
          onPressed: _next,
          child: Text(
            _index == _sessionWords.length - 1 ? 'View results' : 'Next word',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
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
    final outcome = _outcome;
    final promoted = outcome?.promoted == true;
    return _MilestonePayoff(
      key: const ValueKey('complete'),
      title: promoted ? '${outcome!.stage.label} unlocked' : 'Session complete',
      accuracy: accuracy,
      correct: _correct,
      attempted: attempted,
      scoreEarned: outcome?.scoreEarned ?? _score,
      stageLabel: outcome?.stage.label ?? _level,
      stageProgress: outcome?.progress ?? 0,
      stageSessions: outcome?.stageSessions ?? 0,
      stageRequired: outcome?.stage.sessionsRequired ?? 5,
      promoted: promoted,
      bestStreak: widget.mode == TrainingMode.streakChallenge ? _streak : null,
      onAgain: _loadSession,
      onLeave: () => context.go('/pathway'),
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

class _AudioPreparationPanel extends StatelessWidget {
  const _AudioPreparationPanel({required this.audio});

  final TrainingAudioService audio;

  @override
  Widget build(BuildContext context) => StreamBuilder<SessionAudioPreparation>(
    stream: audio.preparation,
    initialData: audio.currentPreparation,
    builder: (context, snapshot) {
      final preparation = snapshot.data!;
      final progress = preparation.total == 0
          ? null
          : preparation.progress.clamp(0.0, 1.0);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.graphic_eq_rounded,
                  color: AlliamColors.coral,
                  size: 42,
                ),
                const SizedBox(height: 18),
                Text(
                  'Preparing your session',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AlliamColors.coral,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Loading the words and audio you need.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AlliamColors.text),
                ),
                const SizedBox(height: 22),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(8),
                  backgroundColor: AlliamColors.line,
                  color: AlliamColors.coral,
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
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

class _LowerCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toLowerCase(),
      selection: TextSelection.collapsed(offset: newValue.text.length),
      composing: TextRange.empty,
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

class _SuccessCheck extends StatelessWidget {
  const _SuccessCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 680),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.rotate(
        angle: (1 - value) * -0.22,
        child: Transform.scale(scale: value, child: child),
      ),
      child: const Icon(
        Icons.check_rounded,
        color: AlliamColors.success,
        size: 62,
      ),
    );
  }
}

class _SessionScore extends StatelessWidget {
  const _SessionScore({
    required this.learnerName,
    required this.score,
    required this.celebrate,
    super.key,
  });

  final String learnerName;
  final int score;
  final bool celebrate;

  @override
  Widget build(BuildContext context) {
    final initial = learnerName.trim().isEmpty
        ? 'S'
        : learnerName.trim()[0].toUpperCase();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: celebrate ? 0.76 : 0.94, end: 1),
      duration: const Duration(milliseconds: 620),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        alignment: Alignment.bottomLeft,
        child: child,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(7, 7, 12, 7),
            decoration: BoxDecoration(
              color: AlliamColors.surfaceStrong.withValues(alpha: 0.94),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AlliamColors.line),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x24948D87),
                  blurRadius: 28,
                  offset: Offset(10, 16),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AlliamColors.coral,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  learnerName,
                  style: const TextStyle(
                    color: AlliamColors.text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '$score',
                  style: const TextStyle(
                    color: AlliamColors.success,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (celebrate) ...[
            const Positioned(
              right: -10,
              top: -18,
              child: Icon(
                Icons.add_rounded,
                color: AlliamColors.success,
                size: 20,
              ),
            ),
            const Positioned(
              right: -24,
              top: 2,
              child: Icon(
                Icons.add_rounded,
                color: AlliamColors.success,
                size: 14,
              ),
            ),
            const Positioned(
              right: -8,
              bottom: -16,
              child: Text(
                '+100',
                style: TextStyle(
                  color: AlliamColors.success,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MilestonePayoff extends StatelessWidget {
  const _MilestonePayoff({
    required this.title,
    required this.accuracy,
    required this.correct,
    required this.attempted,
    required this.scoreEarned,
    required this.stageLabel,
    required this.stageProgress,
    required this.stageSessions,
    required this.stageRequired,
    required this.promoted,
    required this.onAgain,
    required this.onLeave,
    this.bestStreak,
    super.key,
  });

  final String title;
  final int accuracy;
  final int correct;
  final int attempted;
  final int scoreEarned;
  final String stageLabel;
  final double stageProgress;
  final int stageSessions;
  final int stageRequired;
  final bool promoted;
  final int? bestStreak;
  final VoidCallback onAgain;
  final VoidCallback onLeave;

  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.86, end: 1),
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeOutBack,
        builder: (context, scale, child) =>
            Transform.scale(scale: scale, child: child),
        child: Container(
          width: 560,
          padding: const EdgeInsets.fromLTRB(34, 32, 34, 30),
          decoration: BoxDecoration(
            color: AlliamColors.surfaceStrong.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: AlliamColors.line),
            boxShadow: [
              BoxShadow(
                color: AlliamColors.success.withValues(alpha: 0.14),
                blurRadius: 34,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AlliamColors.success.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  promoted ? Icons.auto_awesome_rounded : Icons.check_rounded,
                  size: 38,
                  color: AlliamColors.success,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: promoted ? AlliamColors.success : AlliamColors.coral,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$correct of $attempted words · $accuracy% accuracy',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (bestStreak != null) ...[
                const SizedBox(height: 6),
                Text('Best streak $bestStreak'),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.add_circle_outline_rounded,
                    color: AlliamColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$scoreEarned points',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AlliamColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Text(
                    stageLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  Text('$stageSessions/$stageRequired sessions'),
                ],
              ),
              const SizedBox(height: 9),
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: LinearProgressIndicator(
                  value: stageProgress,
                  minHeight: 10,
                  color: promoted ? AlliamColors.success : AlliamColors.coral,
                  backgroundColor: AlliamColors.line,
                ),
              ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(
                    onPressed: onLeave,
                    child: const Text('Pathway'),
                  ),
                  FilledButton(
                    onPressed: onAgain,
                    child: const Text('Next session'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _CenteredPanel extends StatelessWidget {
  const _CenteredPanel({
    required this.title,
    required this.body,
    required this.action,
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
