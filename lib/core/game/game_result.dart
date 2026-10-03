enum ResultTone { win, loss, draw }

/// Game-end text from the user's point of view, shown on the suggestion card.
final class GameResultHeadline {
  const GameResultHeadline(this.text, this.tone);

  static const String separator = ' — ';

  final String text;
  final ResultTone tone;

  /// [text] split at [separator], for a two-line layout.
  List<String> get lines => text.split(separator);

  @override
  bool operator ==(Object other) =>
      other is GameResultHeadline && other.text == text && other.tone == tone;

  @override
  int get hashCode => Object.hash(text, tone);

  @override
  String toString() => 'GameResultHeadline($text, ${tone.name})';
}
