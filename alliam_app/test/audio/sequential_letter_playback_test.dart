import 'package:alliam_app/features/train/data/sequential_letter_playback.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('letters play sequentially and publish each active index', () async {
    final played = <String>[];
    final indices = <int>[];

    await playSequentialLetters(
      'cab',
      playLetter: (letter) async => played.add(letter),
      onLetter: indices.add,
      isCancelled: () => false,
      wait: (_) async {},
    );

    expect(played, ['c', 'a', 'b']);
    expect(indices, [0, 1, 2, -1]);
  });

  test('cancellation stops the sequence and clears the active index', () async {
    final played = <String>[];
    final indices = <int>[];
    var cancelled = false;

    await playSequentialLetters(
      'word',
      playLetter: (letter) async {
        played.add(letter);
        cancelled = true;
      },
      onLetter: indices.add,
      isCancelled: () => cancelled,
      wait: (_) async {},
    );

    expect(played, ['w']);
    expect(indices, [0, -1]);
  });

  test('playback errors still clear the active index', () async {
    final indices = <int>[];

    await expectLater(
      playSequentialLetters(
        'a',
        playLetter: (_) async => throw StateError('missing'),
        onLetter: indices.add,
        isCancelled: () => false,
        wait: (_) async {},
      ),
      throwsStateError,
    );
    expect(indices, [0, -1]);
  });
}
