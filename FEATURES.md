# Features

A user-facing tour of kanjitomo. For how any of this is implemented, see
[ARCHITECTURE.md](ARCHITECTURE.md).

kanjitomo helps you learn to **read and write Japanese kanji**: draw a
character to look it up (backed by a trained recognition model, not a
lookup-by-stroke-count/radical system), then track your study progress
through a spaced-repetition review system covering both individual kanji and
the compound words (composita) they appear in.

The app's main navigation is a Material 3 bottom navigation bar with five
tabs: **Kanji** (draw-to-recognize), **Words** (word lookup), **Learn**
(learning hub), **Browse** (kanji browser), and **Help** (help, settings,
about).

## Draw-to-recognize lookup (home screen)

The screen you land on. Draw a character stroke by stroke on the canvas;
after every stroke, the app automatically re-runs recognition (no separate
"Recognize" button) and shows up to 3 candidates as a ranked list with
confidence bars. If the top match is already confident, only that one
candidate is shown — there's nothing to disambiguate. Tap a candidate to
open its full kanji detail as a bottom sheet.

The recognizer is a custom-trained model (see
[ARCHITECTURE.md](ARCHITECTURE.md#the-recognition-pipeline-core), it's not a
generic OCR/handwriting API), covering the ~2,140 Jōyō kanji plus hiragana
and katakana. A "Clear" button resets the canvas.

## Word lookup

The Words tab. Build up a word one character at a time by drawing each one
(same draw-and-pick mechanic as the home screen), or type directly into the
word field. Every change re-runs an **exact-word** dictionary lookup (JMdict)
and shows matching entries with their reading and meaning. Useful for looking
up compound words rather than single kanji.

## Browse kanji

The Browse tab. A flat, searchable grid of every Jōyō kanji.
The search box accepts:

- **A reading**, in hiragana or katakana (either script matches either kind
  of reading — typing hiragana still matches a kanji whose on'yomi is
  stored in katakana).
- **A meaning**, matched as a case-insensitive substring (e.g. "water"
  matches 水 but also 湯 "hot water", 滝 "waterfall", etc.).
- **A bare number**, matched as an exact stroke count (not a range).
- **The character itself**.

Each cell shows up to two small progress dots (reading/writing, green =
known, orange = missed) from your review history. Tapping a cell opens its
full detail screen.

## Kanji detail

Shown as a full screen (from Browse kanji) or a bottom sheet (from the
drawing screen or a review card's feedback). Includes, in order:

1. The character itself, with a copy-to-clipboard button.
2. On'yomi / kun'yomi / meaning (skipped for kana, which don't have these).
3. An animated, looping stroke-order reference.
4. Your own personal **keyword** (a short recall cue) and **story** (a
   fuller mnemonic) — both freely editable, autosaved as you type. Skipped
   for kana, which have no mnemonic in the same sense a kanji does.
5. **Composita** — compound words containing this kanji, ranked by
   frequency, each showing its reading, meaning, and JLPT level (a "?"
   marks an estimated level, inferred from the word's hardest constituent
   kanji, when no official word-level JLPT tag exists).
6. **Example sentences** for those composita words — real sentences with
   furigana over every word, the specific word highlighted, and an English
   translation where available.

## Learning

The Learn tab. The hub screen shows three action buttons at the top (Review,
JLPT-like Quiz, Add/Remove), then a stats card with settings, and below that
the current learning pool with due-highlighting.

### Settings (on the learning hub)

- **New cards/day** — how many never-before-seen cards to introduce per
  session (default 30, 0 = unlimited).
- **Max reviews/day** — total daily budget for all cards (reviews +
  new cards combined, default 200, 0 = unlimited). Reviews always take
  priority; new cards fill remaining capacity.
- **Vocabulary level limit** — limits which compound words are
  auto-selected when adding kanji. A word's level is determined by its
  hardest constituent kanji (e.g. 胃腸 is rated N1 because 腸 is N1, even
  though 胃 itself is N3). With the ceiling set to N2, 胃腸 won't be
  auto-selected but 胃袋 (all kanji N2 or easier) will. You can always
  manually add any word regardless of this limit via the composita picker.
  "Off" allows all levels.
- **Words per kanji** — how many compound words to auto-select per kanji
  (2–5, default 4). The algorithm prefers words that cover distinct
  readings of the kanji, then fills remaining slots by frequency.

### Add / Remove

A separate screen with four tabs via bottom navigation:

- **JLPT**: pick a level (N5 easiest – N1 hardest) and how many kanji to
  add. Kanji are added in RTK (Remembering the Kanji) order within the
  level.
- **RTK**: add kanji in pure RTK order regardless of JLPT level.
- **Draw**: draw a kanji to add it directly.
- **Pool**: the current learning pool — all kanji you're studying, with
  composita counts, sortable by RTK order / date added / last modified.
  Long-press to remove a kanji. Tap to edit composita, story, or keyword.

The JLPT and RTK tabs also show the composita settings for convenience.
When adding kanji, compound words are auto-selected based on the vocabulary
level limit and words-per-kanji settings. You can adjust the selection for
any kanji afterwards via the composita picker.

### Review

Launches a spaced-repetition review session. The hub shows how many cards
are due, with configurable **new cards per day** and **max reviews per
day** limits.

During review, each card is one of four kinds:

- **Draw from meaning** — shown the meaning/readings (+ your keyword, if
  set), draw the kanji.
- **Kanji recognition** — shown the bare kanji, recall its reading and
  meaning yourself, then reveal and self-grade (Again/Good).
- **Reading cloze** — a sentence with one word blanked; recall its
  reading, then reveal and self-grade.
- **Draw in sentence** — a sentence with the target kanji replaced by a
  small drawing canvas; draw it in context.

A kanji only turns **green** once both Draw-from-meaning and Kanji
recognition have been passed at least once — composita/sentence testing is
tracked separately (see Statistics) and never blocks the green status. On a
draw-based card, a wrong guess always reveals the correct answer (plus that
character's full detail) before moving on — nothing is silently skipped.

### Quiz

A quick multiple-choice self-test with no effect on spaced-repetition
progress. Two question types are randomly mixed: Kanji→Reading and
Reading→Kanji, both using sentences as context. Only kanji you've reviewed
at least once are included.

### Statistics

Known/missed/not-started counts for each of the four card types, scoped to
the current learning pool. A separate row shows composita/sentence coverage
(how many testable words have been read/drawn at least once). From here you
can also reset all review progress (with confirmation — keyword/story notes
are preserved).

## Help & Settings

The Help tab includes:

- A guided **welcome tour** (shown on first launch, can be replayed).
- **Theme picker** — five preset color themes (Indigo, Teal, Sakura, Forest,
  Amber) shown as choice chips. Tapping one recolors the entire app instantly
  via Material 3's `colorSchemeSeed`. The choice persists across restarts.
  Indigo is the default; selecting it acts as a reset.
- **Support development** — link to buy the developer a coffee.
- **Report a bug** — pre-filled email link.
- **Open source licenses** — attributions for JMdict/EDICT, KANJIDIC2,
  KanjiVG, Tatoeba, and the ETL Character Database.
- **Restore Purchases** (shown for non-Pro users).
- **Reset help** — re-shows all first-time dialog tips.

## What's intentionally not in the current UI

Nothing major — RTK ordering is fully used in the Add/Remove screen for
kanji insertion order.
