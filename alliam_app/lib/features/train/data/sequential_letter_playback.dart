typedef PlayLetter = Future<void> Function(String letter);

Future<void> playSequentialLetters(
  String word, {
  required PlayLetter playLetter,
  required void Function(int index) onLetter,
  required bool Function() isCancelled,
  Duration gap = const Duration(milliseconds: 260),
  Future<void> Function(Duration duration)? wait,
}) async {
  final pause = wait ?? Future<void>.delayed;
  try {
    for (var index = 0; index < word.length; index++) {
      if (isCancelled()) return;
      onLetter(index);
      await playLetter(word[index].toLowerCase());
      if (isCancelled()) return;
      await pause(gap);
    }
  } finally {
    onLetter(-1);
  }
}
