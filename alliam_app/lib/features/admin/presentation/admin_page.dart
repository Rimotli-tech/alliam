import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/admin/admin_access.dart';
import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_page.dart';
import '../data/admin_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final _service = AdminService();
  AudioPlayer _player = AudioPlayer();
  late Future<bool> _access;
  List<AdminWordAudio> _words = const [];
  List<AdminLearner> _learners = const [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMoreWords = false;
  int _section = 0;
  String? _busyId;
  String? _playingId;
  String? _loadError;
  String _nextWordCursor = '';
  int _playRevision = 0;

  @override
  void initState() {
    super.initState();
    _access = _initialize();
  }

  Future<bool> _initialize() async {
    final allowed = await AdminAccess.ensureAdmin();
    if (!allowed) return false;
    await _reload();
    return true;
  }

  Future<void> _reload() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final overview = await _service.loadOverview();
      if (!mounted) return;
      setState(() {
        _words = overview.words;
        _learners = overview.learners;
        _nextWordCursor = overview.nextWordCursor;
        _hasMoreWords = overview.hasMoreWords;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loadError = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMoreWords() async {
    if (_loadingMore || !_hasMoreWords || _nextWordCursor.isEmpty) return;
    setState(() {
      _loadingMore = true;
      _loadError = null;
    });
    try {
      final overview = await _service.loadOverview(
        wordCursor: _nextWordCursor,
        includeLearners: false,
      );
      if (!mounted) return;
      final existingIds = _words.map((word) => word.id).toSet();
      setState(() {
        _words = [
          ..._words,
          ...overview.words.where((word) => existingIds.add(word.id)),
        ];
        _nextWordCursor = overview.nextWordCursor;
        _hasMoreWords = overview.hasMoreWords;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = _friendlyError(error));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('deadline-exceeded') ||
        message.contains('TimeoutException')) {
      return 'Admin data took too long to respond. Please try again.';
    }
    if (message.contains('permission-denied')) {
      return 'Your administrator session needs refreshing. Sign out and sign '
          'in again, then retry.';
    }
    return 'Admin data could not be loaded. Please try again.';
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(AdminWordAudio word) async {
    if (word.storagePath.isEmpty) return;
    final revision = ++_playRevision;
    if (_playingId == word.id) {
      setState(() => _playingId = null);
      await _player.stop();
      return;
    }
    final previousPlayer = _player;
    final selectedPlayer = AudioPlayer();
    _player = selectedPlayer;
    setState(() => _playingId = word.id);
    try {
      await previousPlayer.stop();
      await previousPlayer.dispose();
      final url = await _service.audioUrl(word.storagePath);
      if (revision != _playRevision) return;
      await selectedPlayer.setAudioSource(
        AudioSource.uri(Uri.parse(url), tag: word.id),
        initialPosition: Duration.zero,
        preload: true,
      );
      if (revision != _playRevision) return;
      await selectedPlayer.seek(Duration.zero);
      await selectedPlayer.play();
    } catch (_) {
      if (mounted && revision == _playRevision) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${word.word} could not be played.')),
        );
      }
    } finally {
      if (mounted && revision == _playRevision) {
        setState(() => _playingId = null);
      }
    }
  }

  Future<void> _approve(AdminWordAudio word) async {
    setState(() => _busyId = word.id);
    try {
      await _service.approveWord(word.id);
      await _reload();
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _reset(AdminLearner learner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset learner progress?'),
        content: Text(
          '${learner.name} will return to Foundation with scores, sessions, '
          'accuracy and review words cleared.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset progress'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _busyId = '${learner.accountId}/${learner.id}');
    try {
      await _service.resetLearner(learner);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${learner.name}’s progress was reset.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _access,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const AlliamPage(
            title: 'Admin',
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return AlliamPage(
            title: 'Admin',
            child: _AdminLoadError(
              message: _friendlyError(snapshot.error!),
              onRetry: () => setState(() => _access = _initialize()),
            ),
          );
        }
        if (snapshot.data != true) {
          return const AlliamPage(
            title: 'Admin',
            child: Center(child: Text('Administrator access is required.')),
          );
        }
        return AlliamPage(
          title: 'Admin',
          subtitle: 'Word audio and learner management',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ChoiceChip(
                    selected: _section == 0,
                    label: Text(
                      'Word audio (${_words.length}${_hasMoreWords ? '+' : ''})',
                    ),
                    onSelected: (_) => setState(() => _section = 0),
                  ),
                  ChoiceChip(
                    selected: _section == 1,
                    label: Text('Learners (${_learners.length})'),
                    onSelected: (_) => setState(() => _section = 1),
                  ),
                  ActionChip(
                    avatar: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Refresh'),
                    onPressed: _reload,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_loadError != null)
                _AdminLoadError(message: _loadError!, onRetry: _reload)
              else if (_section == 0)
                _WordAudioList(
                  words: _words,
                  busyId: _busyId,
                  playingId: _playingId,
                  hasMore: _hasMoreWords,
                  loadingMore: _loadingMore,
                  onPlay: _play,
                  onApprove: _approve,
                  onLoadMore: _loadMoreWords,
                )
              else
                _LearnerList(
                  learners: _learners,
                  busyId: _busyId,
                  onReset: _reset,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminLoadError extends StatelessWidget {
  const _AdminLoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.error_outline_rounded, size: 36),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _WordAudioList extends StatelessWidget {
  const _WordAudioList({
    required this.words,
    required this.busyId,
    required this.playingId,
    required this.hasMore,
    required this.loadingMore,
    required this.onPlay,
    required this.onApprove,
    required this.onLoadMore,
  });

  final List<AdminWordAudio> words;
  final String? busyId;
  final String? playingId;
  final bool hasMore;
  final bool loadingMore;
  final ValueChanged<AdminWordAudio> onPlay;
  final ValueChanged<AdminWordAudio> onApprove;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        for (final word in words)
          ListTile(
            leading: IconButton(
              tooltip: playingId == word.id
                  ? 'Stop ${word.word}'
                  : 'Play ${word.word}',
              onPressed: word.storagePath.isEmpty ? null : () => onPlay(word),
              icon: Icon(
                playingId == word.id
                    ? Icons.stop_circle_outlined
                    : Icons.play_arrow_rounded,
              ),
            ),
            title: Text(word.word),
            subtitle: Text(
              word.storagePath.isEmpty
                  ? '${word.level} · No pronunciation file'
                  : '${word.level} · ${word.storagePath}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: word.approved
                ? const Chip(
                    avatar: Icon(Icons.check_rounded, size: 16),
                    label: Text('Approved'),
                  )
                : FilledButton(
                    onPressed: word.storagePath.isEmpty || busyId != null
                        ? null
                        : () => onApprove(word),
                    child: busyId == word.id
                        ? const SizedBox.square(
                            dimension: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Approve'),
                  ),
          ),
        if (hasMore)
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: loadingMore ? null : onLoadMore,
              icon: loadingMore
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.expand_more_rounded),
              label: Text(loadingMore ? 'Loading…' : 'Load 25 more'),
            ),
          ),
      ],
    ),
  );
}

class _LearnerList extends StatelessWidget {
  const _LearnerList({
    required this.learners,
    required this.busyId,
    required this.onReset,
  });

  final List<AdminLearner> learners;
  final String? busyId;
  final ValueChanged<AdminLearner> onReset;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        for (final learner in learners)
          ListTile(
            leading: CircleAvatar(
              backgroundColor: AlliamColors.coralSoft,
              child: Text(learner.name.characters.first.toUpperCase()),
            ),
            title: Text(learner.name),
            subtitle: Text(learner.grade),
            trailing: OutlinedButton.icon(
              onPressed: busyId == null ? () => onReset(learner) : null,
              icon: const Icon(Icons.restart_alt_rounded),
              label: const Text('Reset progress'),
            ),
          ),
      ],
    ),
  );
}
