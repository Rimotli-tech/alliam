import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/alliam_colors.dart';
import '../../../core/widgets/alliam_page.dart';

class RankingsPage extends StatelessWidget {
  const RankingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AlliamPage(
      title: 'Rankings',
      subtitle: 'See how spellers are progressing',
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('players')
            .orderBy('rating', descending: true)
            .limit(100)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _Message(
              icon: Icons.cloud_off_outlined,
              text: 'Rankings are unavailable right now.',
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final rows = snapshot.data!.docs;
          if (rows.isEmpty) {
            return const _Message(
              icon: Icons.leaderboard_outlined,
              text: 'The first rankings will appear after competitive matches.',
            );
          }
          final uid = FirebaseAuth.instance.currentUser?.uid;
          return Container(
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
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              itemCount: rows.length,
              separatorBuilder: (_, _) =>
                  const Divider(color: AlliamColors.line, height: 1),
              itemBuilder: (context, index) {
                final row = rows[index];
                final data = row.data();
                final name =
                    (data['nickname'] ?? data['displayName'] ?? 'Speller')
                        .toString();
                final rating = (data['rating'] as num?)?.round() ?? 1200;
                final country = data['country']?.toString() ?? '';
                final mine = row.id == uid;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 7,
                  ),
                  leading: SizedBox(
                    width: 38,
                    child: Text(
                      '${index + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: mine ? AlliamColors.coral : AlliamColors.text,
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  title: Text(
                    mine ? '$name · You' : name,
                    style: TextStyle(
                      color: mine ? AlliamColors.coral : AlliamColors.text,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: country.isEmpty ? null : Text(country),
                  trailing: Text(
                    '$rating',
                    style: const TextStyle(
                      color: AlliamColors.coral,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(48),
    child: Column(
      children: [
        Icon(icon, color: AlliamColors.coral, size: 46),
        const SizedBox(height: 16),
        Text(text, textAlign: TextAlign.center),
      ],
    ),
  );
}
