# Features

A user-facing tour of kanjitomo. For how any of this is implemented, see
[ARCHITECTURE.md](ARCHITECTURE.md).

kanjitomo helps you learn to **read and write Japanese kanji**: draw a
character to look it up (backed by a trained recognition model, not a
lookup-by-stroke-count/radical system), then track your study progress
through a spaced-repetition review system covering both individual kanji and
the compound words (composita) they appear in.

The app's main navigation lives in the top app bar of the drawing screen:
**Word lookup**, **Browse kanji**, **Learning**, and **Help**.

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

Reachable via the text-fields icon. Build up a word one character at a time
by drawing each one (same draw-and-pick mechanic as the home screen), or
type directly into the word field. Every change re-runs an **exact-word**
dictionary lookup (JMdict) and shows matching entries with their reading and
meaning. Useful for looking up compound words rather than single kanji.

## Browse kanji

Reachable via the grid icon. A flat, searchable grid of every Jōyō kanji.
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

Reachable via the graduation-cap icon. Split into two independent
sections, **JLPT** and **Custom**, each offering the same three actions:

### Review

Launches a review session over whichever kanji (and composita) are
currently in scope. Before starting, you can:

- Choose **what to quiz**: *Kanji only* — the two per-kanji skills (draw
  from meaning, and recall reading/meaning from the bare kanji); *Composita*
  — reading and drawing kanji within compound words/sentences; or *Both*.
- Choose **new kanji per day** (how many not-yet-seen characters to
  introduce per day; default 10, persisted across app restarts).
- Choose the **session size** (how many cards to load at most; default 50).
- See a summary of the current scope, how many kanji it covers, and how
  many cards are currently due — followed, below the Start button, by the
  full list of in-scope kanji (tap any to jump to its detail).

If you skip reviewing for two or more days, the app automatically holds
off on introducing new kanji until you've cleared your backlog of due
cards — you can still add more manually via "Learn more" if you want.
A single day off is normal (yesterday's cards come back for their first
review) and doesn't trigger this.

During review, each card is one of four kinds:

- **Draw from meaning** — shown the meaning/readings (+ your keyword, if
  set), draw the kanji.
- **Kanji recognition** — shown the bare kanji, recall its reading and
  meaning yourself, then reveal and self-grade (Again/Good).
- **Reading (composita/sentence)** — a sentence with one word blanked;
  recall its reading, then reveal and self-grade.
- **Draw in sentence** — a sentence with the target kanji replaced by a
  small drawing canvas; draw it in context.

A kanji only turns **green** once both Draw-from-meaning and Kanji
recognition have been passed at least once — composita/sentence testing is
tracked separately (see Statistics) and never blocks the green status. On a
draw-based card, a wrong guess always reveals the correct answer (plus that
character's full detail) before moving on — nothing is silently skipped.
Once the day's due cards run out, a "Learn more" option offers to introduce
additional not-yet-seen characters on demand rather than waiting for the
next day.

### Edit Kanji to learn

- **JLPT**: pick one or more JLPT levels (N1 hardest – N5 easiest). New
  kanji are introduced automatically at a configurable daily pace (set in
  the Review screen before starting a session). Separately, set a
  **composita/sentence ceiling**: the hardest level a compound word is
  allowed to be before it's included in composita testing, independent of which
  kanji levels you're studying (a kanji's own level and a word containing
  it can differ). Leaving this off skips composita/sentence testing entirely
  for this scope.
- **Custom**: draw kanji one at a time to build your own hand-picked study
  list (tap a cell to remove it; a confirmation dialog guards clearing the
  whole set). Long-press any kanji in the list to pick exactly which of its
  compound words you want tested — custom mode has no level ceiling,
  so nothing is tested for a kanji until you explicitly opt words in here.

### Statistics

Known/missed/not-started counts for each of the four card types, scoped to
whichever kanji are currently selected (JLPT or Custom, whichever section
you opened Statistics from) — not the whole ~2,140-kanji dictionary. A
separate row shows composita/sentence coverage (how many testable words
have been read/drawn at least once), explicitly called out as informational
only. From here you can also jump to Browse kanji, or reset all review
progress (with a confirmation dialog — this cannot be undone, though your
personal keyword/story notes are preserved).

## Help

A short in-app explanation of how Learning/green status works, plus an
"Open source licenses" page attributing the third-party dictionary and
example-sentence data this app is built on (JMdict/EDICT, Tatoeba).

## What's intentionally not in the current UI

RTK (Remembering the Kanji ordinal ordering) is fully implemented at the
data and scheduling layer but not exposed in any current screen — a
product decision to de-emphasize it, not a removal.
