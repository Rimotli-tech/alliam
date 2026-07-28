import 'dart:async';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_background.dart';
import '../../../core/audio/background_music_service.dart';
import '../../../core/audio/sound_effects_service.dart';
import '../../auth/data/account_repository.dart';
import '../../auth/domain/account_session.dart';
import '../../settings/data/settings_repository.dart';
import '../data/training_audio_service.dart';
import '../data/training_progress_repository.dart';
import '../data/session_audio_manifest.dart';
import '../data/word_repository.dart';
import '../data/learner_word_progress_repository.dart';
import '../data/learner_pathway_progress_repository.dart';
import '../domain/spelling_word.dart';
import '../domain/training_mode.dart';
import '../domain/training_score.dart';
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
  const TrainingSessionPage({
    required this.mode,
    this.reviewWords = const [],
    super.key,
  });

  final TrainingMode mode;
  final List<String> reviewWords;

  @override
  State<TrainingSessionPage> createState() => _TrainingSessionPageState();
}

class _TrainingSessionPageState extends State<TrainingSessionPage> {
  late final WordRepository _words;
  late final TrainingAudioService _audio;
  late final TrainingProgressRepository _progress;
  late final LearnerWordProgressRepository _wordProgress;
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
  bool _wrongFeedbackReady = true;
  int _repeatUses = 0;
  int _lastWordPoints = 0;
  DateTime _attemptStartedAt = DateTime.now();
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
  TrainingMode? _introModeShown;
  AccountSession? _accountSession;
  DateTime _sessionStartedAt = DateTime.now();
  String? _accountId;
  String? _activeLearnerId;
  String _wordLedgerSessionId = '';
  bool _guidedIntroduction = true;
  bool _suspendTypingFocus = false;
  bool _showRotatePrompt = false;
  bool _sessionLoadStarted = false;
  bool _lockedLandscape = false;
  final Set<String> _masteredThisSession = {};
  final Set<String> _needsPracticeThisSession = {};
  LearnerMasterySummary? _masterySummary;

  SpellingWord? get _current =>
      _sessionWords.isEmpty ? null : _sessionWords[_index];

  bool get _isCompactPhoneLandscape {
    if (!mounted) return false;
    final size = MediaQuery.sizeOf(context);
    return _isPhonePlatform &&
        size.width > size.height &&
        size.shortestSide < 600;
  }

  bool get _usesTypedAnswer => !{
    TrainingMode.similarWords,
    TrainingMode.buildTheWord,
  }.contains(widget.mode);

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
    _wordProgress = LearnerWordProgressRepository(FirebaseFirestore.instance);
    _settings = SettingsRepository(
      FirebaseFirestore.instance,
      FirebaseAuth.instance,
    );
    FocusManager.instance.addListener(_maintainTypingFocus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_preparePhoneOrientation());
    });
  }

  @override
  void dispose() {
    _runId++;
    _timer?.cancel();
    unawaited(BackgroundMusicService.instance.leaveExercise());
    _answer.dispose();
    FocusManager.instance.removeListener(_maintainTypingFocus);
    _focus.dispose();
    unawaited(_audio.stop());
    if (_lockedLandscape) {
      unawaited(
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
      );
    }
    super.dispose();
  }

  bool get _isPhonePlatform =>
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;

  Future<void> _preparePhoneOrientation() async {
    if (!mounted) return;
    final size = MediaQuery.sizeOf(context);
    final phone = _isPhonePlatform && size.shortestSide < 600;
    if (!phone) {
      _beginSessionLoad();
      return;
    }
    if (size.width > size.height) {
      if (!kIsWeb) {
        _lockedLandscape = true;
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
      if (mounted) _beginSessionLoad();
      return;
    }
    setState(() => _showRotatePrompt = true);
    if (kIsWeb) return;
    await Future<void>.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    _lockedLandscape = true;
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (mounted) _beginSessionLoad();
  }

  void _beginSessionLoad() {
    if (_sessionLoadStarted || !mounted) return;
    _sessionLoadStarted = true;
    setState(() => _showRotatePrompt = false);
    unawaited(_loadSession());
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
      _masteredThisSession.clear();
      _needsPracticeThisSession.clear();
      _masterySummary = null;
      _sessionStartedAt = DateTime.now();
      _wordLedgerSessionId =
          '${DateTime.now().microsecondsSinceEpoch}-${widget.mode.slug}';
    });
    try {
      final preferences = await _settings.load();
      final user = FirebaseAuth.instance.currentUser;
      var pathwayLevel = preferences.level;
      if (user != null) {
        final session = await AccountRepository(
          FirebaseFirestore.instance,
        ).load(user);
        _accountSession = session;
        _accountId = user.uid;
        _activeLearnerId = session.activeLearnerId;
        _learnerName = session.activeLearnerName.trim().split(' ').first;
        final gradeMatch = RegExp(
          r'\d+',
        ).firstMatch(session.activeLearner?.grade ?? '');
        final grade = int.tryParse(gradeMatch?.group(0) ?? '');
        _guidedIntroduction = grade == null || grade <= 3;
        if (preferences.automaticPathway) {
          pathwayLevel = LearnerPathway.stage(
            session.activeLearner?.journey['stage']?.toString(),
          ).wordLevel;
        }
      }
      final module = preferences.module(widget.mode.slug);
      _level = pathwayLevel;
      _wordCount = (module['wordCount'] as num?)?.round() ?? _wordCount;
      _missingVariant = module['missingVariant']?.toString() ?? _missingVariant;
      _patternFocus = module['patternFocus']?.toString() ?? _patternFocus;
      final words =
          {
            TrainingMode.wordFlash,
            TrainingMode.missedWords,
          }.contains(widget.mode)
          ? await _loadWordFlashQueue()
          : await _words.load(level: _level, count: _wordCount);
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
    final showModeIntro = firstWord && _introModeShown != widget.mode;
    _timer?.cancel();
    _answer.clear();
    _typedLength = 0;
    _lastCorrect = false;
    _wrongFeedbackReady = true;
    _showHeldWord = false;
    _flashUsed = false;
    _repeatUses = 0;
    _lastWordPoints = 0;
    _usedTileIndices.clear();
    _usedTileOrder.clear();
    setState(() {
      _phase = showModeIntro ? _SessionPhase.intro : _SessionPhase.teaching;
      _activeSpellingLetter = -1;
    });

    if (showModeIntro) {
      await _wait(const Duration(milliseconds: 3500), activeRun);
      if (!_valid(activeRun)) return;
      _introModeShown = widget.mode;
    } else if (!firstWord) {
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
    if (!_guidedIntroduction) {
      if (_valid(run)) _beginAttempt();
      return;
    }
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
    _attemptStartedAt = DateTime.now();
    setState(() {
      _phase = _SessionPhase.attempt;
      _activeSpellingLetter = -1;
    });
    if (!_usesTypedAnswer) {
      return;
    }
    if (_isCompactPhoneLandscape) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focus.requestFocus();
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    });
  }

  void _maintainTypingFocus() {
    if (!mounted ||
        _isCompactPhoneLandscape ||
        _suspendTypingFocus ||
        _phase != _SessionPhase.attempt ||
        _focus.hasFocus) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _suspendTypingFocus || _phase != _SessionPhase.attempt) {
        return;
      }
      _focus.requestFocus();
    });
  }

  void _restoreTypingFocus() {
    if (!mounted ||
        _isCompactPhoneLandscape ||
        _phase != _SessionPhase.attempt) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _phase == _SessionPhase.attempt) {
        _focus.requestFocus();
      }
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
    final submittedIndex = _index;
    final submittedLastWord = submittedIndex == _sessionWords.length - 1;
    final correct = !timedOut && _answer.text.toLowerCase() == _expectedAnswer;
    final points = TrainingScore.wordPoints(
      correct: correct,
      responseTime: DateTime.now().difference(_attemptStartedAt),
      usedFlash: _flashUsed,
      repeatUses: _repeatUses,
    );
    if (correct) {
      _incorrectWords.remove(_current!.word);
      unawaited(SoundEffectsService.instance.correct());
    } else {
      _incorrectWords.add(_current!.word);
      unawaited(SoundEffectsService.instance.wrongAnswer());
    }
    setState(() {
      _lastCorrect = correct;
      _wrongFeedbackReady = correct;
      _lastWordPoints = points;
      _correct += correct ? 1 : 0;
      _score += points;
      _streak = correct ? _streak + 1 : 0;
      if (!correct && widget.mode == TrainingMode.survivalRun) _lives--;
      _phase = _SessionPhase.feedback;
    });
    if (!correct) {
      unawaited(_releaseWrongFeedback(submittedIndex));
    }
    await _recordWordAttempt(correct);
    if (submittedLastWord) {
      final run = _runId;
      await _wait(Duration(milliseconds: correct ? 850 : 3650), run);
      if (!_valid(run)) return;
      setState(() => _phase = _SessionPhase.complete);
      unawaited(_recordProgress());
    }
  }

  void _typeLetter(String letter) {
    if (_phase != _SessionPhase.attempt ||
        !_usesTypedAnswer ||
        _answer.text.length >= _expectedAnswer.length) {
      return;
    }
    _answer.text += letter.toLowerCase();
    _answer.selection = TextSelection.collapsed(offset: _answer.text.length);
    _typedLength = _answer.text.length;
    unawaited(SoundEffectsService.instance.key());
    setState(() {});
  }

  void _removeLetter() {
    if (_phase != _SessionPhase.attempt || _answer.text.isEmpty) return;
    final text = _answer.text;
    _answer.text = text.substring(0, text.length - 1);
    _answer.selection = TextSelection.collapsed(offset: _answer.text.length);
    _typedLength = _answer.text.length;
    setState(() {});
  }

  Future<List<SpellingWord>> _loadWordFlashQueue() async {
    final accountId = _accountId;
    final learnerId = _activeLearnerId;
    if (accountId == null || learnerId == null) {
      throw StateError('Choose a learner before starting this review.');
    }
    final queuedWords = widget.reviewWords.isNotEmpty
        ? widget.reviewWords
        : await _wordProgress.loadReviewQueue(
            accountId: accountId,
            learnerId: learnerId,
            count: _wordCount,
          );
    if (queuedWords.isEmpty) {
      throw StateError(
        'Complete Hear & Spell first to build this learner’s review queue.',
      );
    }
    return _words.loadWords(queuedWords);
  }

  Future<void> _recordWordAttempt(bool correct) async {
    final accountId = _accountId;
    final learnerId = _activeLearnerId;
    final word = _current;
    if (accountId == null || learnerId == null || word == null) return;
    try {
      final change = await _wordProgress.recordAttempt(
        accountId: accountId,
        learnerId: learnerId,
        word: word,
        mode: widget.mode,
        correct: correct,
        sessionId: _wordLedgerSessionId,
      );
      if (change == null || !mounted) return;
      setState(() {
        if (change.becameMastered) {
          _masteredThisSession.add(word.word);
          _needsPracticeThisSession.remove(word.word);
        } else if (!correct || change.currentState == 'learning') {
          _needsPracticeThisSession.add(word.word);
        }
      });
    } catch (_) {
      // The spelling session should remain playable if progress sync fails.
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

  Future<void> _releaseWrongFeedback(int submittedIndex) async {
    final run = _runId;
    await _wait(const Duration(milliseconds: 3500), run);
    if (!_valid(run) ||
        _phase != _SessionPhase.feedback ||
        _index != submittedIndex) {
      return;
    }
    setState(() => _wrongFeedbackReady = true);
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
        durationSeconds: DateTime.now()
            .difference(_sessionStartedAt)
            .inSeconds
            .clamp(1, 3600),
        currentStreak: _streak,
        pointsEarned: _score,
      );
      LearnerMasterySummary? mastery;
      final accountId = _accountId;
      final learnerId = _activeLearnerId;
      if (accountId != null && learnerId != null) {
        mastery = await _wordProgress.loadSummary(
          accountId: accountId,
          learnerId: learnerId,
        );
        await LearnerPathwayProgressRepository(
          FirebaseFirestore.instance,
        ).syncPosition(
          accountId: accountId,
          learnerId: learnerId,
          introduced: mastery.introduced,
          mastered: mastery.mastered,
        );
      }
      if (mounted) {
        setState(() {
          _outcome = outcome;
          _masterySummary = mastery;
        });
      }
    } catch (_) {
      // Completion remains available offline; the session can be retried.
    }
  }

  Future<void> _openSettings() async {
    var count = _wordCount;
    var missingVariant = _missingVariant;
    var patternFocus = _patternFocus;
    final learners = _accountSession?.learners ?? const <LearnerProfile>[];
    var selectedLearnerId =
        _accountSession?.activeLearnerId ??
        (learners.isEmpty ? null : learners.first.id);

    Widget settingsContent(BuildContext modalContext) {
      return StatefulBuilder(
        builder: (context, setModalState) => SafeArea(
          child: SingleChildScrollView(
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Session settings',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AlliamColors.coral,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close settings',
                      onPressed: () => Navigator.pop(modalContext, false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                if (learners.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedLearnerId,
                    decoration: const InputDecoration(
                      labelText: 'Learner',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    items: [
                      for (final learner in learners)
                        DropdownMenuItem(
                          value: learner.id,
                          child: Text('${learner.avatar}  ${learner.name}'),
                        ),
                    ],
                    onChanged: (value) =>
                        setModalState(() => selectedLearnerId = value),
                  ),
                  const SizedBox(height: 14),
                ],
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
                      setModalState(() => count = value ?? count),
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
                    onChanged: (value) => setModalState(
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
                    onChanged: (value) => setModalState(
                      () => patternFocus = value ?? patternFocus,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                FilledButton(
                  onPressed: () => Navigator.pop(modalContext, true),
                  child: const Text('Apply and restart'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final desktop = MediaQuery.sizeOf(context).width >= 700;
    bool? changed;
    if (desktop) {
      changed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: AlliamColors.surface,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(32),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
            side: const BorderSide(color: AlliamColors.line),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: settingsContent(dialogContext),
          ),
        ),
      );
    } else {
      changed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AlliamColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        builder: settingsContent,
      );
    }

    if (changed == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null &&
            selectedLearnerId != null &&
            selectedLearnerId != _accountSession?.activeLearnerId) {
          await AccountRepository(
            FirebaseFirestore.instance,
          ).setActiveLearner(user, selectedLearnerId!);
        }
        _wordCount = count;
        _missingVariant = missingVariant;
        _patternFocus = patternFocus;
        await _settings.saveModule(widget.mode.slug, {
          'wordCount': count,
          'missingVariant': missingVariant,
          'patternFocus': patternFocus,
        });
        await _loadSession();
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session settings could not be applied. Try again.'),
          ),
        );
      }
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
    if (_showRotatePrompt) {
      final landscape =
          MediaQuery.sizeOf(context).width > MediaQuery.sizeOf(context).height;
      if (kIsWeb && landscape) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _beginSessionLoad(),
        );
      }
      return const Scaffold(body: _RotatePhonePrompt());
    }
    final compactLandscape = _isCompactPhoneLandscape;
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
              if (!compactLandscape &&
                  (_phase == _SessionPhase.attempt ||
                      _phase == _SessionPhase.feedback))
                Positioned(
                  left: 18,
                  top: compactLandscape ? 76 : null,
                  bottom: compactLandscape ? null : 18,
                  child: _SessionScore(
                    key: ValueKey('score-$_score'),
                    learnerName: _learnerName,
                    score: _score,
                    celebrate: _phase == _SessionPhase.feedback && _lastCorrect,
                  ),
                ),
              if (_phase == _SessionPhase.feedback && !_lastCorrect)
                Positioned.fill(
                  child: IgnorePointer(
                    child: _WrongEdgeFlash(key: ValueKey('wrong-$_index')),
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
          _SessionProgress(
            current: _sessionWords.isEmpty ? 0 : _index,
            total: _sessionWords.length,
          ),
          const Spacer(),
          if (_isCompactPhoneLandscape && _current != null) ...[
            _SessionIconButton(
              tooltip: 'Word helpers',
              onPressed: _openCompactHelpers,
              icon: const Icon(Icons.more_horiz_rounded),
            ),
            const SizedBox(width: 8),
          ],
          _SessionIconButton(
            tooltip: 'Session settings',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
    );
  }

  Future<void> _openCompactHelpers() async {
    final word = _current;
    if (word == null) return;
    final size = MediaQuery.sizeOf(context);
    final action = await showMenu<String>(
      context: context,
      color: AlliamColors.surfaceStrong,
      position: RelativeRect.fromLTRB(size.width - 300, 76, 18, 0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      items: [
        const PopupMenuItem(
          value: 'repeat',
          child: ListTile(
            leading: Icon(Icons.refresh_rounded),
            title: Text('Repeat'),
          ),
        ),
        PopupMenuItem(
          value: 'flash',
          enabled: widget.mode == TrainingMode.hearAndSpell && !_flashUsed,
          child: const ListTile(
            leading: Icon(Icons.visibility_outlined),
            title: Text('Flash word'),
          ),
        ),
        PopupMenuItem(
          value: 'Definition',
          enabled: word.definition.isNotEmpty,
          child: const ListTile(
            leading: Icon(Icons.menu_book_outlined),
            title: Text('Definition'),
          ),
        ),
        PopupMenuItem(
          value: 'Sentence',
          enabled: word.sentence.isNotEmpty,
          child: const ListTile(
            leading: Icon(Icons.format_quote_rounded),
            title: Text('Used in a sentence'),
          ),
        ),
        PopupMenuItem(
          value: 'Origin',
          enabled: word.origin.isNotEmpty,
          child: const ListTile(
            leading: Icon(Icons.public_rounded),
            title: Text('Origin'),
          ),
        ),
        PopupMenuItem(
          value: 'Part of speech',
          enabled: word.partOfSpeech.isNotEmpty,
          child: const ListTile(
            leading: Icon(Icons.category_outlined),
            title: Text('Part of speech'),
          ),
        ),
      ],
    );
    if (!mounted || action == null) return;
    if (action == 'repeat') {
      _repeatUses++;
      await _playPronunciation();
      return;
    }
    if (action == 'flash') {
      setState(() {
        _flashUsed = true;
        _showHeldWord = true;
      });
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      if (mounted) setState(() => _showHeldWord = false);
      return;
    }
    await _showWordInfo(action);
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
        'Listen, study the word, then spell it yourself.',
      ),
      TrainingMode.wordFlash => (
        'Word Flash',
        'Study the word briefly, then spell it from memory.',
      ),
      TrainingMode.timedDrill => (
        'Timed Drill',
        'Listen once, then spell the word before time runs out.',
      ),
      TrainingMode.listenAndSpell => (
        'Listen & Spell',
        'Listen to the word, then spell it from memory.',
      ),
      TrainingMode.missingLetters => (
        'Missing Letters',
        'Complete the word by filling in its hidden letters.',
      ),
      TrainingMode.patternDrill => (
        'Pattern Drill',
        'Use the recurring pattern to complete the spelling.',
      ),
      TrainingMode.similarWords => (
        'Similar Words',
        'Use the clue to choose the correct spelling.',
      ),
      TrainingMode.buildTheWord => (
        'Build the Word',
        'Arrange the letter pieces to build the correct word.',
      ),
      TrainingMode.mockBee => (
        'Mock Bee',
        'Listen carefully and spell each word in one attempt.',
      ),
      TrainingMode.survivalRun => (
        'Survival Run',
        'Keep spelling correctly for as long as your three lives last.',
      ),
      TrainingMode.streakChallenge => (
        'Streak Challenge',
        'Spell each word correctly to build your longest streak.',
      ),
      TrainingMode.recallLadder => (
        'Recall Ladder',
        'Recall each spelling as the challenge becomes harder.',
      ),
      TrainingMode.dailyChallenge => (
        'Daily Challenge',
        'Complete today’s shared set of spelling words.',
      ),
      TrainingMode.themeChallenge => (
        'Theme Challenge',
        'Use each clue to spell words from the featured theme.',
      ),
      TrainingMode.reverseSpell => (
        'Reverse Spell',
        'Listen to the letters, then identify the complete word.',
      ),
      TrainingMode.missedWords => (
        'Missed Words',
        'Practise previously missed words until they become strengths.',
      ),
    };
    final showingCountdown = _phase == _SessionPhase.countdown;
    return Center(
      key: const ValueKey('intro'),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!showingCountdown) ...[
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
            ] else ...[
              Container(
                width: 104,
                height: 104,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(color: const Color(0xFFFDDAB9), width: 2),
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
          ],
        ),
      ),
    );
  }

  Widget _exercise(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final compactLandscape =
        size.width > size.height && size.shortestSide < 600;
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

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.enter): () {
          if (_phase == _SessionPhase.attempt && _answer.text.isNotEmpty) {
            unawaited(_submit());
          } else if (_phase == _SessionPhase.feedback && _wrongFeedbackReady) {
            unawaited(_next());
          }
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          if (_phase == _SessionPhase.attempt && _answer.text.isNotEmpty) {
            unawaited(_submit());
          } else if (_phase == _SessionPhase.feedback && _wrongFeedbackReady) {
            unawaited(_next());
          }
        },
      },
      child: GestureDetector(
        key: ValueKey('exercise-$_index'),
        behavior: HitTestBehavior.translucent,
        onTap: () {
          if (compactLandscape ||
              _phase != _SessionPhase.attempt ||
              _answer.text.length >= _current!.word.length) {
            return;
          }
          _focus.requestFocus();
          SystemChannels.textInput.invokeMethod<void>('TextInput.show');
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            compactLandscape ? 2 : 18,
            24,
            compactLandscape ? 12 : 40,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 980),
              child: Column(
                children: [
                  if (_phase == _SessionPhase.attempt &&
                      !compactLandscape &&
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
                            FilteringTextInputFormatter.allow(
                              RegExp('[a-zA-Z]'),
                            ),
                            _LowerCaseTextFormatter(),
                          ],
                          onChanged: (value) {
                            if (value.length > _typedLength) {
                              unawaited(SoundEffectsService.instance.key());
                            }
                            _typedLength = value.length;
                            setState(() {});
                          },
                          onSubmitted: (_) {
                            if (_answer.text.isNotEmpty) unawaited(_submit());
                          },
                        ),
                      ),
                    ),
                  if (!compactLandscape)
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
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
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
                              if (feedback && _lastCorrect) ...[
                                const SizedBox(height: 6),
                                Text(
                                  '+$_lastWordPoints points',
                                  style: const TextStyle(
                                    color: AlliamColors.coral,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
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
                  SizedBox(height: compactLandscape ? 2 : 22),
                  _modePrompt(context, teaching: teaching),
                  SizedBox(height: compactLandscape ? 2 : 22),
                  SizedBox(
                    height: compactLandscape ? 112 : 250,
                    child: Center(
                      child: LetterDiamonds(
                        word: _expectedAnswer,
                        entered: _answer.text,
                        revealWord: reveal,
                        success: feedback && _lastCorrect,
                        incorrect: feedback && !_lastCorrect,
                        compact: compactLandscape,
                        activeIndex: teaching ? _activeSpellingLetter : -1,
                      ),
                    ),
                  ),
                  SizedBox(height: compactLandscape ? 8 : 22),
                  SizedBox(
                    height: compactLandscape
                        ? _usesTypedAnswer
                              ? 0
                              : 64
                        : widget.mode == TrainingMode.hearAndSpell
                        ? 220
                        : widget.mode == TrainingMode.wordFlash
                        ? 170
                        : 150,
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: compactLandscape && _usesTypedAnswer
                          ? const SizedBox.shrink()
                          : _exerciseControls(
                              feedback,
                              compactLandscape: compactLandscape,
                            ),
                    ),
                  ),
                  if (compactLandscape && _usesTypedAnswer) ...[
                    const SizedBox(height: 4),
                    _AlliamKeyboard(
                      enabled: _phase == _SessionPhase.attempt,
                      canSubmit: _phase == _SessionPhase.attempt
                          ? _answer.text.isNotEmpty
                          : _phase == _SessionPhase.feedback &&
                                _wrongFeedbackReady &&
                                _index < _sessionWords.length - 1,
                      actionLabel: _phase == _SessionPhase.feedback
                          ? 'Next word'
                          : 'Submit',
                      onLetter: _typeLetter,
                      onBackspace: _removeLetter,
                      onSubmit: () {
                        if (_phase == _SessionPhase.feedback) {
                          unawaited(_next());
                        } else {
                          unawaited(_submit());
                        }
                      },
                    ),
                  ],
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

  Widget _exerciseControls(bool feedback, {required bool compactLandscape}) {
    if (_phase == _SessionPhase.attempt) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compactLandscape || !_usesTypedAnswer)
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
                            _removeLetter();
                            _restoreTypingFocus();
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
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          if (widget.mode == TrainingMode.hearAndSpell ||
              widget.mode == TrainingMode.listenAndSpell ||
              widget.mode == TrainingMode.mockBee) ...[
            SizedBox(height: compactLandscape ? 10 : 26),
            Wrap(
              spacing: 16,
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    _repeatUses++;
                    await _playPronunciation();
                    _restoreTypingFocus();
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Repeat'),
                ),
                if (widget.mode == TrainingMode.hearAndSpell)
                  Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) {
                      if (_flashUsed) return;
                      setState(() {
                        _flashUsed = true;
                        _showHeldWord = true;
                      });
                      _restoreTypingFocus();
                    },
                    onPointerUp: (_) {
                      if (_showHeldWord) {
                        setState(() => _showHeldWord = false);
                      }
                      _restoreTypingFocus();
                    },
                    onPointerCancel: (_) {
                      setState(() => _showHeldWord = false);
                      _restoreTypingFocus();
                    },
                    child: IgnorePointer(
                      child: OutlinedButton(
                        onPressed: _flashUsed ? null : () {},
                        child: Text(
                          _flashUsed ? 'Flash used' : 'Hold to flash',
                        ),
                      ),
                    ),
                  ),
                if (compactLandscape &&
                    widget.mode == TrainingMode.hearAndSpell)
                  ..._wordInfoButtons(),
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
          if (widget.mode == TrainingMode.hearAndSpell && !compactLandscape ||
              widget.mode == TrainingMode.wordFlash) ...[
            SizedBox(height: compactLandscape ? 10 : 18),
            _wordInfoActions(),
          ],
        ],
      );
    }

    if (feedback) {
      if (!_wrongFeedbackReady) {
        return const SizedBox(width: 164, height: 60);
      }
      if (_index == _sessionWords.length - 1) {
        return const SizedBox(width: 164, height: 60);
      }
      return SizedBox(
        width: 164,
        height: 60,
        child: FilledButton(
          onPressed: _next,
          child: const Text(
            'Next word',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
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

  Widget _wordInfoActions() {
    return Semantics(
      label: 'Word information',
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 18,
        runSpacing: 12,
        children: _wordInfoButtons(),
      ),
    );
  }

  List<Widget> _wordInfoButtons() {
    final word = _current!;
    return [
      _WordInfoButton(
        label: 'Definition',
        icon: Icons.menu_book_outlined,
        available: word.definition.isNotEmpty,
        onPressed: () => _showWordInfo('Definition'),
      ),
      _WordInfoButton(
        label: 'Used in a sentence',
        icon: Icons.format_quote_rounded,
        available: word.sentence.isNotEmpty,
        onPressed: () => _showWordInfo('Sentence'),
      ),
      _WordInfoButton(
        label: 'Origin',
        icon: Icons.public_rounded,
        available: word.origin.isNotEmpty,
        onPressed: () => _showWordInfo('Origin'),
      ),
      _WordInfoButton(
        label: 'Part of speech',
        icon: Icons.category_outlined,
        available: word.partOfSpeech.isNotEmpty,
        onPressed: () => _showWordInfo('Part of speech'),
      ),
    ];
  }

  Widget _result(BuildContext context) {
    final attempted = (_index + 1).clamp(0, _sessionWords.length);
    final accuracy = attempted == 0 ? 0 : (_correct / attempted * 100).round();
    final outcome = _outcome;
    final promoted = outcome?.promoted == true;
    final mastery = _masterySummary;
    final mastered = mastery?.mastered ?? 0;
    final position = LearnerPathway.position(
      introduced: mastery?.introduced ?? 0,
      mastered: mastered,
    );
    final unit = LearnerPathway.unit(position.unitId);
    return _MilestonePayoff(
      key: const ValueKey('complete'),
      title: promoted ? '${outcome!.stage.label} unlocked' : 'Session complete',
      accuracy: accuracy,
      correct: _correct,
      attempted: attempted,
      masteredThisSession: _masteredThisSession.length,
      needsPracticeThisSession: _needsPracticeThisSession.length,
      stageLabel: outcome?.stage.label ?? _level,
      stageProgress: unit.masteryTarget == 0
          ? 1
          : (mastered / unit.masteryTarget).clamp(0, 1),
      masteredWords: mastered,
      masteryTarget: unit.masteryTarget,
      promoted: promoted,
      bestStreak: widget.mode == TrainingMode.streakChallenge ? _streak : null,
      onAgain: _openNextSession,
      onLeave: () => context.go('/pathway'),
    );
  }

  void _openNextSession() {
    final nextMode = widget.mode.nextLearningSession;
    if (widget.mode == TrainingMode.hearAndSpell) {
      final words = _sessionWords.map((word) => word.word).join(',');
      context.go('/train/session/${nextMode.slug}?words=$words');
      return;
    }
    context.go('/train/session/${nextMode.slug}');
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
    _suspendTypingFocus = true;
    final content = Builder(
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(28, 26, 28, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type == 'Sentence' ? 'Used in a sentence' : type,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AlliamColors.coral,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
    try {
      if (MediaQuery.sizeOf(context).width >= 700) {
        await showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: AlliamColors.surface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: content,
            ),
          ),
        );
      } else {
        await showModalBottomSheet<void>(
          context: context,
          backgroundColor: AlliamColors.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          builder: (context) => SafeArea(child: content),
        );
      }
    } finally {
      _suspendTypingFocus = false;
    }
    _restoreTypingFocus();
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

class _WordInfoButton extends StatelessWidget {
  const _WordInfoButton({
    required this.label,
    required this.icon,
    required this.available,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool available;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: available ? label : '$label unavailable',
    child: Semantics(
      button: true,
      enabled: available,
      label: label,
      child: IconButton(
        onPressed: available ? onPressed : null,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          minimumSize: const Size.square(46),
          foregroundColor: AlliamColors.coral,
          disabledForegroundColor: AlliamColors.muted.withValues(alpha: 0.45),
          side: BorderSide(
            color: available
                ? AlliamColors.coral.withValues(alpha: 0.28)
                : AlliamColors.muted.withValues(alpha: 0.18),
          ),
        ),
      ),
    ),
  );
}

class _AlliamKeyboard extends StatelessWidget {
  const _AlliamKeyboard({
    required this.enabled,
    required this.canSubmit,
    required this.actionLabel,
    required this.onLetter,
    required this.onBackspace,
    required this.onSubmit,
  });

  final bool enabled;
  final bool canSubmit;
  final String actionLabel;
  final ValueChanged<String> onLetter;
  final VoidCallback onBackspace;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _letterRow('qwertyuiop'),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: _letterRow('asdfghjkl'),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 54),
            child: Row(
              children: [
                for (final letter in 'zxcvbnm'.split('')) ...[
                  Expanded(child: _letterKey(letter)),
                  const SizedBox(width: 6),
                ],
                Expanded(
                  child: _KeyboardAction(
                    tooltip: 'Backspace',
                    onPressed: enabled ? onBackspace : null,
                    child: const Icon(Icons.backspace_outlined, size: 20),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 2,
                  child: _KeyboardAction(
                    tooltip: 'Submit',
                    onPressed: canSubmit ? onSubmit : null,
                    primary: true,
                    child: Text(
                      actionLabel,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _letterRow(String letters) => Row(
    children: [
      for (var index = 0; index < letters.length; index++) ...[
        Expanded(child: _letterKey(letters[index])),
        if (index < letters.length - 1) const SizedBox(width: 6),
      ],
    ],
  );

  Widget _letterKey(String letter) => SizedBox(
    height: 40,
    child: FilledButton.tonal(
      onPressed: enabled ? () => onLetter(letter) : null,
      style: FilledButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: AlliamColors.surfaceStrong,
        foregroundColor: AlliamColors.text,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
      ),
      child: Text(
        letter.toUpperCase(),
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
      ),
    ),
  );
}

class _KeyboardAction extends StatelessWidget {
  const _KeyboardAction({
    required this.tooltip,
    required this.onPressed,
    required this.child,
    this.primary = false,
  });

  final String tooltip;
  final VoidCallback? onPressed;
  final Widget child;
  final bool primary;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: primary
              ? AlliamColors.coral
              : AlliamColors.surfaceStrong,
          foregroundColor: primary ? Colors.white : AlliamColors.coral,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(11),
          ),
        ),
        child: child,
      ),
    ),
  );
}

class _RotatePhonePrompt extends StatefulWidget {
  const _RotatePhonePrompt();

  @override
  State<_RotatePhonePrompt> createState() => _RotatePhonePromptState();
}

class _RotatePhonePromptState extends State<_RotatePhonePrompt>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlliamBackground(
    child: SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Transform.rotate(
                  angle:
                      Curves.easeInOutCubic.transform(_controller.value) *
                      math.pi /
                      2,
                  child: child,
                ),
                child: Container(
                  width: 76,
                  height: 122,
                  decoration: BoxDecoration(
                    color: AlliamColors.surfaceStrong,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AlliamColors.coral, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: AlliamColors.coral.withValues(alpha: 0.16),
                        blurRadius: 28,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.screen_rotation_rounded,
                      color: AlliamColors.coral,
                      size: 34,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 42),
              Text(
                'Turning sideways',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AlliamColors.coral,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                kIsWeb
                    ? 'Rotate your phone to begin the spelling session.'
                    : 'Your spelling session uses landscape so every word stays on one line.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _WrongEdgeFlash extends StatefulWidget {
  const _WrongEdgeFlash({super.key});

  @override
  State<_WrongEdgeFlash> createState() => _WrongEdgeFlashState();
}

class _WrongEdgeFlashState extends State<_WrongEdgeFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, _) {
      final pulse = math.sin(_controller.value * math.pi);
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color(0xFFE23B32).withValues(alpha: pulse * 0.72),
            width: 5 + pulse * 7,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE23B32).withValues(alpha: pulse * 0.18),
              blurRadius: 34,
              spreadRadius: 10,
            ),
          ],
        ),
      );
    },
  );
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

class _SessionProgress extends StatelessWidget {
  const _SessionProgress({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox(width: 96, height: 18);
    return Semantics(
      label: 'Word ${current + 1} of $total',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < total; index++) ...[
            if (index > 0)
              Container(
                width: 18,
                height: 2,
                color: index <= current
                    ? AlliamColors.coral
                    : AlliamColors.line,
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: index == current ? 18 : 12,
              height: index == current ? 18 : 12,
              decoration: BoxDecoration(
                color: index < current
                    ? AlliamColors.coral
                    : AlliamColors.surfaceStrong,
                shape: BoxShape.circle,
                border: Border.all(
                  color: index <= current
                      ? AlliamColors.coral
                      : AlliamColors.line,
                  width: index == current ? 3 : 2,
                ),
                boxShadow: index == current
                    ? const [
                        BoxShadow(
                          color: Color(0x33FF684D),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: index < current
                  ? const Icon(
                      Icons.check_rounded,
                      size: 9,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ],
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
    required this.masteredThisSession,
    required this.needsPracticeThisSession,
    required this.stageLabel,
    required this.stageProgress,
    required this.masteredWords,
    required this.masteryTarget,
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
  final int masteredThisSession;
  final int needsPracticeThisSession;
  final String stageLabel;
  final double stageProgress;
  final int masteredWords;
  final int masteryTarget;
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
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 22,
                runSpacing: 10,
                children: [
                  _MasteryResult(
                    icon: Icons.workspace_premium_outlined,
                    value: '$masteredThisSession',
                    label: masteredThisSession == 1
                        ? 'word mastered'
                        : 'words mastered',
                    color: AlliamColors.success,
                  ),
                  _MasteryResult(
                    icon: Icons.replay_rounded,
                    value: '$needsPracticeThisSession',
                    label: needsPracticeThisSession == 1
                        ? 'word to practise'
                        : 'words to practise',
                    color: AlliamColors.coral,
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
                  Text('$masteredWords/$masteryTarget words mastered'),
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

class _MasteryResult extends StatelessWidget {
  const _MasteryResult({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, color: color),
      const SizedBox(width: 7),
      Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(width: 5),
      Text(label),
    ],
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
