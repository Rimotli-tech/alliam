import 'package:alliam_app/core/theme/alliam_theme.dart';
import 'package:alliam_app/core/widgets/alliam_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Alliam cards render their title and subtitle', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AlliamTheme.light,
        home: const Scaffold(
          body: AlliamCard(
            icon: Icons.hearing_rounded,
            title: 'Hear & Spell',
            subtitle: 'Learn the word, then spell',
          ),
        ),
      ),
    );

    expect(find.text('Hear & Spell'), findsOneWidget);
    expect(find.text('Learn the word, then spell'), findsOneWidget);
  });
}
