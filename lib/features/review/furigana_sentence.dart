import 'package:flutter/material.dart';

import '../../data/sentences_repository.dart';

/// Renders a tokenized sentence with furigana above each word, as a Wrap of
/// small columns -- not RichText/WidgetSpan: CJK has no whitespace word
/// breaks, so per-token wrapping is the correct line-break behavior here,
/// not a workaround (mirrors the same Wrap-over-Row reasoning already used
/// elsewhere in this app for button rows).
///
/// Supports the per-target modifications the quiz's two sentence-based
/// card types need:
///  - [hideTargetReading] + [emphasizeTargetReading]: blank the target
///    word's furigana, then once revealed show it in red/bold as "the
///    answer" (reading-cloze card).
///  - [highlightTargetBox]: draw a red box around the target word's kanji
///    themselves, so it's visually obvious which word is being asked about
///    even while its reading is hidden (reading-cloze card).
///  - [targetCharacter] + [targetReplacement]: swap out only the ONE
///    character within the target word that matches [targetCharacter] for
///    another widget (e.g. an inline drawing canvas), leaving any other
///    kanji in that same compound word visible -- a token is a whole word
///    (e.g. 一番), not a single character, so blanking the whole token would
///    incorrectly hide kanji the card isn't even testing (draw-in-sentence
///    card).
class FuriganaSentence extends StatelessWidget {
  final List<SentenceToken> tokens;
  final double fontSize;
  final double furiganaFontSize;
  final bool hideTargetReading;
  final bool emphasizeTargetReading;
  final bool highlightTargetBox;
  final String? targetCharacter;
  final Widget? targetReplacement;

  const FuriganaSentence({
    super.key,
    required this.tokens,
    this.fontSize = 24,
    this.furiganaFontSize = 12,
    this.hideTargetReading = false,
    this.emphasizeTargetReading = false,
    this.highlightTargetBox = false,
    this.targetCharacter,
    this.targetReplacement,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: tokens
          .map(
            (t) => _RubyUnit(
              token: t,
              fontSize: fontSize,
              furiganaFontSize: furiganaFontSize,
              hideReading: hideTargetReading && t.isTarget,
              emphasize: emphasizeTargetReading && t.isTarget,
              highlightBox: highlightTargetBox && t.isTarget,
              targetCharacter: t.isTarget ? targetCharacter : null,
              replacement: t.isTarget ? targetReplacement : null,
            ),
          )
          .toList(),
    );
  }
}

class _RubyUnit extends StatelessWidget {
  final SentenceToken token;
  final double fontSize;
  final double furiganaFontSize;
  final bool hideReading;
  final bool emphasize;
  final bool highlightBox;
  final String? targetCharacter;
  final Widget? replacement;

  const _RubyUnit({
    required this.token,
    required this.fontSize,
    required this.furiganaFontSize,
    required this.hideReading,
    required this.emphasize,
    required this.highlightBox,
    required this.targetCharacter,
    required this.replacement,
  });

  Widget _buildBase() {
    // Only substitute the one matching character within the word, not the
    // whole token -- a compound word like 一番 has kanji the card isn't
    // testing, and those must stay visible.
    if (replacement != null && targetCharacter != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: token.surface.split('').map((char) {
          return char == targetCharacter
              ? replacement!
              : Text(char, style: TextStyle(fontSize: fontSize));
        }).toList(),
      );
    }
    return replacement ??
        Text(token.surface, style: TextStyle(fontSize: fontSize));
  }

  /// The ruby text to show above this token. Any trailing okurigana
  /// already visible as plain kana in [SentenceToken.surface] (e.g. the ぎ
  /// in 過ぎ, or the つ in 一つ) is stripped off the reading first: standard
  /// furigana convention never repeats an okurigana's own kana as ruby
  /// (e.g. 過[す]ぎ / 一[ひと]つ, not 過[すぎ]ぎ / 一[ひとつ]つ) -- showing
  /// the whole word's reading above text that already ends in that same
  /// kana reads as though it were pronounced twice. Applies to every
  /// token, not just a partially-masked target (draw-in-sentence's "blank
  /// just the kanji, leave the okurigana visible" case) -- an ordinary,
  /// fully-visible token with trailing okurigana has exactly the same
  /// duplication otherwise. Falls back to the full reading whenever the
  /// surface has no trailing kana to strip, or [reading] doesn't actually
  /// end with it (an unexpected shape -- safer to show everything than to
  /// silently truncate).
  String get _displayReading {
    final reading = token.reading;
    final trailingKana = _trailingKana(token.surface);
    if (trailingKana.isEmpty || !reading.endsWith(trailingKana)) return reading;
    final stripped = reading.substring(0, reading.length - trailingKana.length);
    return stripped.isEmpty ? reading : stripped;
  }

  /// The longest suffix of [surface] made up entirely of hiragana/katakana
  /// -- okurigana already legible as plain text alongside its kanji stem.
  static String _trailingKana(String surface) {
    var start = surface.length;
    while (start > 0 && _isKana(surface.codeUnitAt(start - 1))) {
      start--;
    }
    return surface.substring(start);
  }

  static bool _isKana(int codeUnit) =>
      (codeUnit >= 0x3040 && codeUnit <= 0x309F) || // hiragana
      (codeUnit >= 0x30A0 && codeUnit <= 0x30FF); // katakana

  @override
  Widget build(BuildContext context) {
    final hasReading =
        token.reading.isNotEmpty && token.reading != token.surface;

    Widget base = _buildBase();
    if (highlightBox) {
      base = Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: base,
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Fixed height regardless of content: hiding the reading must never
        // reflow the surrounding layout.
        SizedBox(
          height: furiganaFontSize * 1.4,
          child: !hasReading || hideReading
              ? null
              : Text(
                  _displayReading,
                  style: TextStyle(
                    fontSize: furiganaFontSize,
                    color: emphasize ? Colors.red : null,
                    fontWeight: emphasize ? FontWeight.bold : null,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
        base,
      ],
    );
  }
}
