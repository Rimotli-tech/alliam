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
  final _player = AudioPlayer();
  late Future<bool> _access;
  List<AdminWordAudio> _words = const [];
  List<AdminLearner> _learners = const [];
  bool _loading = true;
  int _section = 0;
  String? _busyId;

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
    if (mounted) setState(() => _loading = true);
    final results = await Future.wait([
      _service.loadWords(),
      _service.loadLearners(),
    ]);
    if (!mounted) return;
    setState(() {
      _words = results[0] as List<AdminWordAudio>;
      _learners = results[1] as List<AdminLearner>;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _play(AdminWordAudio word) async {
    if (word.storagePath.isEmpty) return;
    setState(() => _busyId = word.id);
    try {
      await _player.setUrl(await _service.audioUrl(word.storagePath));
      await _player.play();
    } finally {
      if (mounted) setState(() => _busyId = null);
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
        if (!snapshot.hasData) {
          return const AlliamPage(
            title: 'Admin',
            child: Center(child: CircularProgressIndicator()),
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
                    label: Text('Word audio (${_words.length})'),
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
              else if (_section == 0)
                _WordAudioList(
                  words: _words,
                  busyId: _busyId,
                  onPlay: _play,
                  onApprove: _approve,
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

class _WordAudioList extends StatelessWidget {
  const _WordAudioList({
    required this.words,
    required this.busyId,
    required this.onPlay,
    required this.onApprove,
  });

  final List<AdminWordAudio> words;
  final String? busyId;
  final ValueChanged<AdminWordAudio> onPlay;
  final ValueChanged<AdminWordAudio> onApprove;

  @override
  Widget build(BuildContext context) => Card(
    child: Column(
      children: [
        for (final word in words)
          ListTile(
            leading: IconButton(
              tooltip: 'Play ${word.word}',
              onPressed: word.storagePath.isEmpty || busyId != null
                  ? null
                  : () => onPlay(word),
              icon: const Icon(Icons.play_arrow_rounded),
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
