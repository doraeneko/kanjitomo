import 'package:flutter/material.dart';

import '../../data/kanji_info_repository.dart';
import '../../data/sentences_repository.dart';
import 'reading_splitter.dart' show splitReading, katakanaToHiragana;
import 'sentence_selection.dart' show isKanji;

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

  /// When set, draws the red highlight box around only this ONE character
  /// within the target word, not around the whole word. Used after reveal
  /// in reading-cloze cards to mark only the kanji being tested, while
  /// leaving the rest of the compound word unhighlighted. Distinct from
  /// [targetCharacter]+[targetReplacement] (draw-in-sentence), which
  /// *replaces* the character with a widget rather than just highlighting it.
  final String? highlightCharacter;

  /// When set, this key is placed on the first target [_RubyUnit] instead of
  /// on the [FuriganaSentence] itself, so that [Scrollable.ensureVisible] can
  /// scroll directly to the highlighted word rather than to the top of the
  /// whole sentence.
  final GlobalKey? targetKey;

  /// Optional kanji lookup function for per-character furigana splitting.
  /// When provided, multi-kanji words like 埋立地 get per-character readings
  /// (う above 埋, めたて above 立, ち above 地) instead of the whole reading
  /// centered over the entire word.
  final KanjiInfo? Function(String char)? kanjiLookup;

  /// Characters the user has already learned. When [hideTargetReading] is true
  /// and this set is provided, per-character furigana splitting still runs:
  /// readings for characters NOT in this set are shown as hints, while readings
  /// for characters IN this set (the ones being tested) are hidden.
  final Set<String>? seenCharacters;

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
    this.highlightCharacter,
    this.targetKey,
    this.kanjiLookup,
    this.seenCharacters,
  });

  @override
  Widget build(BuildContext context) {
    bool targetKeyAssigned = false;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.end,
      children: tokens.map((t) {
        Key? key;
        if (t.isTarget && !targetKeyAssigned && targetKey != null) {
          key = targetKey;
          targetKeyAssigned = true;
        }
        return _RubyUnit(
          key: key,
          token: t,
          fontSize: fontSize,
          furiganaFontSize: furiganaFontSize,
          hideReading: hideTargetReading && t.isTarget,
          emphasize: emphasizeTargetReading && t.isTarget,
          highlightBox: highlightTargetBox && t.isTarget,
          targetCharacter: t.isTarget ? targetCharacter : null,
          replacement: t.isTarget ? targetReplacement : null,
          highlightCharacter: t.isTarget ? highlightCharacter : null,
          kanjiLookup: kanjiLookup,
          seenCharacters: t.isTarget ? seenCharacters : null,
        );
      }).toList(),
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
  final String? highlightCharacter;
  final KanjiInfo? Function(String char)? kanjiLookup;
  final Set<String>? seenCharacters;

  const _RubyUnit({
    super.key,
    required this.token,
    required this.fontSize,
    required this.furiganaFontSize,
    required this.hideReading,
    required this.emphasize,
    required this.highlightBox,
    required this.targetCharacter,
    required this.replacement,
    this.highlightCharacter,
    this.kanjiLookup,
    this.seenCharacters,
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
    var reading = token.reading;

    // Strip leading kana prefix (e.g. シャボン from シャボン玉).
    // Compare in hiragana so katakana surface matches hiragana reading.
    final leadingKana = _leadingKana(token.surface);
    if (leadingKana.isNotEmpty) {
      final leadingHira = katakanaToHiragana(leadingKana);
      if (reading.startsWith(leadingHira)) {
        final after = reading.substring(leadingHira.length);
        if (after.isNotEmpty) reading = after;
      } else if (reading.startsWith(leadingKana)) {
        final after = reading.substring(leadingKana.length);
        if (after.isNotEmpty) reading = after;
      }
    }

    // Strip trailing kana suffix (e.g. ぎ from 過ぎ).
    final trailingKana = _trailingKana(token.surface);
    if (trailingKana.isNotEmpty) {
      final trailingHira = katakanaToHiragana(trailingKana);
      if (reading.endsWith(trailingHira)) {
        final before = reading.substring(0, reading.length - trailingHira.length);
        if (before.isNotEmpty) reading = before;
      } else if (reading.endsWith(trailingKana)) {
        final before = reading.substring(0, reading.length - trailingKana.length);
        if (before.isNotEmpty) reading = before;
      }
    }

    return reading;
  }

  /// The longest prefix of [surface] made up entirely of hiragana/katakana
  /// -- leading kana already legible as plain text before the kanji.
  static String _leadingKana(String surface) {
    var end = 0;
    while (end < surface.length && _isKana(surface.codeUnitAt(end))) {
      end++;
    }
    return surface.substring(0, end);
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

  /// Builds per-character furigana for a list of characters and their
  /// readings. The kanji text determines each cell's width; furigana is
  /// centered above it and may overflow slightly for narrow kanji with
  /// wide readings (standard ruby behaviour). A ・ separator is shown
  /// between adjacent furigana readings.
  Widget _buildSplitRow(List<_CharReading> segments) {
    final rubyHeight = furiganaFontSize * 1.4;
    final baseStyle = TextStyle(fontSize: fontSize);
    final furiStyle = TextStyle(
      fontSize: furiganaFontSize,
      color: emphasize ? Colors.red : null,
      fontWeight: emphasize ? FontWeight.bold : null,
    );
    final allKana = token.surface.codeUnits.every(_isKana);
    final underline = highlightBox && !allKana;

    final children = <Widget>[];
    bool lastHadRuby = false;
    for (final seg in segments) {
      final needsRuby = seg.reading.isNotEmpty && seg.reading != seg.surface;

      // Prepend ・ to the furigana text when two readings are adjacent,
      // so the separator lives inside the ruby row without pushing the
      // kanji apart horizontally.
      final displayReading = (needsRuby && lastHadRuby)
          ? '・${seg.reading}'
          : seg.reading;

      final isHighlighted = highlightCharacter != null &&
          seg.surface == highlightCharacter;
      final isReplaced = targetCharacter != null &&
          replacement != null &&
          seg.surface == targetCharacter;
      Widget baseText = isReplaced
          ? replacement!
          : Text(seg.surface, style: baseStyle);
      if (isHighlighted && !isReplaced) {
        baseText = Container(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 2),
          ),
          child: baseText,
        );
      }

      children.add(Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: rubyHeight,
            child: needsRuby
                ? Text(displayReading, style: furiStyle,
                    textAlign: TextAlign.center)
                : null,
          ),
          baseText,
        ],
      ));
      lastHadRuby = needsRuby;
    }

    Widget row = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: children,
    );

    if (underline) {
      row = Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.red, width: 2)),
        ),
        child: row,
      );
    }

    return row;
  }

  @override
  Widget build(BuildContext context) {
    final hasReading =
        token.reading.isNotEmpty && token.reading != token.surface;

    Widget base = _buildBase();
    final allKana = token.surface.codeUnits.every(_isKana);
    if (highlightBox && highlightCharacter == null) {
      // Whole-word highlight box (pre-reveal, or when no specific character
      // is singled out).
      base = Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.red, width: 2),
        ),
        child: base,
      );
    } else if (highlightBox && highlightCharacter != null) {
      // Per-character highlight: only the tested character gets the red box.
      base = Row(
        mainAxisSize: MainAxisSize.min,
        children: token.surface.split('').map((char) {
          final w = Text(char, style: TextStyle(fontSize: fontSize));
          if (char == highlightCharacter) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red, width: 2),
              ),
              child: w,
            );
          }
          return w;
        }).toList(),
      );
    }

    // --- Split rendering: place furigana above the correct characters ---
    //
    // When hideReading is true but seenCharacters is provided, we still
    // do the split: unseen kanji get their reading shown as a hint, while
    // seen kanji (the ones being tested) have their reading hidden.
    //
    // When targetCharacter is set (drawInSentence), we also do the split
    // so each character gets its own reading with ・ separators, and the
    // replaced character gets the replacement widget as its base.
    final wantPartialHide = hideReading && seenCharacters != null;
    final hasTargetReplace = targetCharacter != null && replacement != null;
    if (hasReading &&
        (!hideReading || wantPartialHide || hasTargetReplace)) {

      // 1. Best: per-character split using kanjiLookup (handles
      //    interleaved kana like 寄せ集め, pure-kanji like 埋立地,
      //    and words with okurigana like 照らす — all in one path).
      if (kanjiLookup != null) {
        final chars = token.surface.split('');
        final splits = splitReading(
          token.surface, token.reading, kanjiLookup!,
        );
        if (splits != null && splits.length == chars.length) {
          final segments = List.generate(chars.length, (i) {
            // When partially hiding: show reading only for unseen kanji.
            if (wantPartialHide) {
              final ch = chars[i];
              final code = ch.codeUnitAt(0);
              final isKanjiChar = isKanji(code);
              final isSeen = seenCharacters!.contains(ch);
              // Hide reading for seen kanji (being tested); show for unseen.
              if (isKanjiChar && isSeen) {
                return _CharReading(ch, '');
              }
            }
            return _CharReading(chars[i], splits[i]);
          });
          return _buildSplitRow(segments);
        }
      }

      // 2. Fallback: simple okurigana split (strip leading/trailing kana).
      //    Compare in hiragana so katakana surface matches hiragana reading.
      //    Skip when wantPartialHide — we can't do per-character hiding
      //    without a successful split, so fall through to full-hide.
      if (!wantPartialHide) {
        final leadingKana = _leadingKana(token.surface);
        final trailingKana = _trailingKana(token.surface);
        final leadingHira = katakanaToHiragana(leadingKana);
        final trailingHira = katakanaToHiragana(trailingKana);
        final hasLeading = leadingKana.isNotEmpty &&
            (token.reading.startsWith(leadingHira) ||
             token.reading.startsWith(leadingKana));
        final hasTrailing = trailingKana.isNotEmpty &&
            (token.reading.endsWith(trailingHira) ||
             token.reading.endsWith(trailingKana));

        if (hasLeading || hasTrailing) {
          final leadLen = hasLeading ? leadingHira.length : 0;
          final trailLen = hasTrailing ? trailingHira.length : 0;
          final stemStart = hasLeading ? leadingKana.length : 0;
          final stemEnd = hasTrailing
              ? token.surface.length - trailingKana.length
              : token.surface.length;
          final stem = token.surface.substring(stemStart, stemEnd);
          final readingStem = token.reading.substring(
            leadLen,
            token.reading.length - trailLen,
          );

          final segments = <_CharReading>[];
          if (hasLeading) {
            segments.add(_CharReading(leadingKana, leadingKana));
          }
          // When we need per-character targeting (replace or highlight) and
          // the stem is multi-character, split it so each character gets its
          // own segment.  The full stem reading goes above the first character.
          final needsSplit = stem.length > 1 &&
              (targetCharacter != null || highlightCharacter != null) &&
              stem.contains(targetCharacter ?? highlightCharacter ?? '');
          if (needsSplit) {
            final stemChars = stem.split('');
            for (var i = 0; i < stemChars.length; i++) {
              segments.add(_CharReading(
                stemChars[i],
                i == 0 ? readingStem : '',
              ));
            }
          } else {
            segments.add(_CharReading(stem, readingStem));
          }
          if (hasTrailing) {
            segments.add(_CharReading(trailingKana, trailingKana));
          }
          return _buildSplitRow(segments);
        }
      }
    }

    // Underline the whole word when per-character highlighting is active
    // (highlightCharacter boxes only one kanji; the underline marks the full
    // word). Skipped when highlightCharacter is null — build() already wraps
    // the whole word in a full red box in that case.
    if (highlightBox && highlightCharacter != null && !allKana) {
      base = Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.red, width: 2)),
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

/// A character and its reading, used for split furigana rendering.
class _CharReading {
  final String surface;
  final String reading;
  const _CharReading(this.surface, this.reading);
}
