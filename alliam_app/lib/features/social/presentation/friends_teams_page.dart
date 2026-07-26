import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_page.dart';
import '../data/social_service.dart';

class FriendsTeamsPage extends StatefulWidget {
  const FriendsTeamsPage({super.key});

  @override
  State<FriendsTeamsPage> createState() => _FriendsTeamsPageState();
}

class _FriendsTeamsPageState extends State<FriendsTeamsPage> {
  final _service = SocialService();

  @override
  Widget build(BuildContext context) {
    return AlliamPage(
      title: 'Friends & teams',
      subtitle: 'Spell together',
      child: Column(
        children: [
          _Section(
            title: 'Invitations',
            action: FilledButton.icon(
              onPressed: _addFriend,
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: const Text('Add friend'),
            ),
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _service.requests(),
              builder: (context, snapshot) => _RequestList(
                documents:
                    snapshot.data?.docs ??
                    const <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                onRespond: _respond,
              ),
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 820;
              final children = [
                _Section(
                  title: 'Friends',
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _service.friendships(),
                    builder: (context, snapshot) => _FriendList(
                      uid: _service.uid,
                      documents:
                          snapshot.data?.docs ??
                          const <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                    ),
                  ),
                ),
                _Section(
                  title: 'Teams',
                  action: OutlinedButton.icon(
                    onPressed: _createTeam,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create'),
                  ),
                  child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _service.teams(),
                    builder: (context, snapshot) =>
                        _TeamList(documents: snapshot.data?.docs ?? const []),
                  ),
                ),
              ];
              if (!wide) {
                return Column(
                  children: [
                    children.first,
                    const SizedBox(height: 18),
                    children.last,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: children.first),
                  const SizedBox(width: 18),
                  Expanded(child: children.last),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _addFriend() async {
    final controller = TextEditingController();
    final identifier = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add a friend'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email, phone or friend code',
            hintText: 'name@example.com or +234…',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Send invitation'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (identifier == null || identifier.trim().isEmpty) return;
    await _run(() => _service.sendRequest(identifier), 'Invitation sent.');
  }

  Future<void> _respond(String id, bool accept) => _run(
    () => _service.respond(id, accept),
    accept ? 'Friend added.' : 'Invitation declined.',
  );

  Future<void> _createTeam() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create a team'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Team name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().length < 3) return;
    await _run(() => _service.createTeam(name), 'Team created.');
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (mounted) _notice(success);
    } catch (error) {
      if (mounted) {
        _notice(error.toString().replaceFirst('Bad state: ', ''));
      }
    }
  }

  void _notice(String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.action});
  final String title;
  final Widget child;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: AlliamColors.surface,
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: AlliamColors.line),
      boxShadow: const [
        BoxShadow(
          color: Color(0x35D7B69B),
          blurRadius: 26,
          offset: Offset(8, 14),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(title, style: Theme.of(context).textTheme.titleLarge),
            ),
            ?action,
          ],
        ),
        const SizedBox(height: 16),
        child,
      ],
    ),
  );
}

class _RequestList extends StatelessWidget {
  const _RequestList({required this.documents, required this.onRespond});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents;
  final Future<void> Function(String, bool) onRespond;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const Text('No pending invitations.');
    return Column(
      children: [
        for (final document in documents)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              ((document.data()['senderProfile'] as Map?)?['nickname'] ??
                      'Speller')
                  .toString(),
            ),
            subtitle: const Text('Wants to connect'),
            trailing: Wrap(
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => onRespond(document.id, false),
                  child: const Text('Decline'),
                ),
                FilledButton(
                  onPressed: () => onRespond(document.id, true),
                  child: const Text('Accept'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _FriendList extends StatelessWidget {
  const _FriendList({required this.uid, required this.documents});
  final String uid;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Text('Add a friend to practise together.');
    }
    return Column(
      children: [
        for (final document in documents)
          Builder(
            builder: (context) {
              final profiles = document.data()['profiles'] as Map? ?? {};
              final entry = profiles.entries.firstWhere(
                (item) => item.key != uid,
                orElse: () => const MapEntry('', <String, dynamic>{}),
              );
              final profile = entry.value as Map? ?? {};
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AlliamColors.surfaceStrong,
                  child: Icon(Icons.person_outline, color: AlliamColors.coral),
                ),
                title: Text(
                  (profile['nickname'] ?? profile['displayName'] ?? 'Speller')
                      .toString(),
                ),
                subtitle: Text(
                  [profile['grade'], profile['country']]
                      .where((value) => value?.toString().isNotEmpty == true)
                      .join(' · '),
                ),
                trailing: const Icon(
                  Icons.sports_kabaddi_rounded,
                  color: AlliamColors.coral,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _TeamList extends StatelessWidget {
  const _TeamList({required this.documents});
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const Text('Create a team for shared competition.');
    }
    return Column(
      children: [
        for (final document in documents)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.shield_outlined,
              color: AlliamColors.coral,
            ),
            title: Text(document.data()['name']?.toString() ?? 'Team'),
            subtitle: Text(
              '${(document.data()['memberUids'] as List?)?.length ?? 0} members',
            ),
            trailing: Text(
              '${(document.data()['rating'] as num?)?.round() ?? 1200}',
            ),
          ),
      ],
    );
  }
}
