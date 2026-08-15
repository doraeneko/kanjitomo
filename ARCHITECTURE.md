# Architecture

kanjitomo is a Flutter app with a small, dependency-injection-free
architecture: one `AppDependencies` object owns every repository/service and
is threaded down through constructors. There is no state-management
framework (no Provider/Riverpod/Bloc) — screens hold their own `State` and
either read a `ValueNotifier` (for the one piece of truly shared, observed
state, `StudyScope`) or call repository methods directly and `setState`.

```
lib/
  main.dart                 – app entrypoint, license registry, startup screen
  app_dependencies.dart     – the one DI container, owns every repository
  core/                     – recognition pipeline + database, no UI
    kanji_recognizer.dart
    canonicalize.dart
    kanji_rasterizer.dart
    drawing_canvas.dart
    db/
      tables.dart
      app_database.dart
      app_database.g.dart   – drift-generated, do not hand-edit
  data/                     – read-only repositories over bundled JSON assets
    kanji_info_repository.dart
    jlpt_levels_repository.dart
    rtk_index_repository.dart
    kanji_level_rank_repository.dart
    composita_repository.dart
    sentences_repository.dart
    stories_repository.dart
    stroke_paths_repository.dart
    word_index_repository.dart
  features/
    lookup/                 – main draw-to-recognize screen + word lookup
    kanji_browser/           – browse-all-kanji grid + kanji detail view
    learning/                – Learning section (JLPT/Custom edit, Help)
    review/                  – StudyScope, SM-2 engine, review session/start/stats
    stroke_order/            – stroke-order animation widget (+ a standalone
                                dev harness screen, not reachable from the app)
assets/                      – bundled JSON data + the ONNX model (see below)
test/                        – mirrors lib/'s structure
```

## Layering

```
features/*   (screens, StatefulWidgets)
     │  reads/writes
     ▼
data/* repositories   core/db (drift/SQLite)   core/kanji_recognizer.dart
     │                      │                          │
     ▼                      ▼                          ▼
assets/*.json         SQLite file              assets/model/*.onnx
(bundled, read-only,  (user's own progress,     (bundled, read-only,
 one per aspect of    notes, custom lists —     loaded once via
 kanji/word data)      the only mutable state)   flutter_onnxruntime)
```

- **`data/` repositories** are the only thing that ever calls
  `rootBundle.loadString`/`rootBundle.load`. Each one loads exactly one
  `assets/*.json` file once (via `AppDependencies.load()`, run in parallel
  with `Future.wait`) and serves synchronous, in-memory lookups afterwards —
  there is no lazy/streamed asset loading anywhere. They are pure data
  classes; none of them know about Flutter widgets or the database.
- **`core/db`** is the only mutable, persisted state: SM-2 review progress,
  per-character personal notes, and the user's custom kanji/composita
  selections. Everything else the app shows is derived from the read-only
  bundled JSON at request time.
- **`features/`** screens are the only layer that imports Flutter Material
  widgets. A screen typically holds one repository instance in its `State`,
  fetches what it needs in `initState`/event handlers, and rebuilds via
  `setState` — there's no cross-screen reactive graph beyond `StudyScope`'s
  `ValueNotifier` (see below).

## Data flow: `AppDependencies`

`AppDependencies` (`lib/app_dependencies.dart`) is constructed once in
`main.dart` and passed down as a constructor parameter to every screen. It
owns:

- `database` — the single `AppDatabase` (drift/SQLite) instance.
- `recognizer` — the single `KanjiRecognizer` (ONNX session) instance.
- One repository instance per bundled JSON asset (`kanjiInfo`, `jlptLevels`,
  `rtkIndex`, `kanjiLevelRank`, `composita`, `sentences`, `stories`,
  `strokePaths`, `wordIndex`).
- `studyScope` — the one shared, observed piece of app state (see below).

`AppDependencies.load()` parallel-loads every JSON-backed repository, then
syncs two derived pieces of state into the database:

1. `database.syncKanjiStatic(...)` — upserts a `kanji_static` row per
   character with its JLPT level / RTK index / level-rank, so the review
   engine can express "which characters are in scope" as one SQL `WHERE`
   instead of joining against three separate in-memory maps on every query.
2. `database.seedStories(...)` — inserts the bundled personal-story seed
   text for any character that doesn't have a `kanji_notes` row yet
   (`insertOrIgnore`, never overwrites a user's own edits).

`recognizer` is deliberately **not** part of this shared load: ONNX session
creation is the slowest, most failure-prone step, and only the lookup/draw
screens need it. Each of those screens loads it independently and shows its
own spinner/error state, so a slow or failed model load never blocks the
rest of the app.

Tests construct `AppDependencies(database: AppDatabase.forTesting(...))` to
swap in an in-memory SQLite database (the real constructor needs
`path_provider`, which has no implementation in a plain widget test).

## The recognition pipeline (`core/`)

This is a straight Dart port of the sibling Python project **kanjirec**'s
training/inference pipeline, kept byte-for-byte compatible so a drawing
canonicalized in Dart produces the same model input a Python-side training
run would have seen.

```
finger/stylus input
   │  DrawingCanvas (raw Listener, not GestureDetector — see below)
   ▼
List<Stroke>            – points in fixed 64×64 grid space
   │  KanjiRasterizer.rasterize(strokes, size: 256)
   ▼
ui.Image (256×256)      – supersampled well above the model's input size
   │  toByteData(rawRgba)
   ▼
canonicalize()           – core/canonicalize.dart
   │    1. crop to the ink's bounding box (+ 10% margin)
   │    2. area-average resize down to 64×64
   │    3. binarize + invert (ink → 1.0, background → 0.0)
   ▼
Float32List[64*64]      – exact model input, in [0, 1]
   │  KanjiRecognizer.predictTopK()
   ▼
OrtSession.run()          – flutter_onnxruntime, model.onnx
   │  softmax over logits
   ▼
List<Prediction>          – (label, probability, isReject), sorted desc.
```

Key points:

- **`DrawingCanvas`** (`core/drawing_canvas.dart`) uses a raw `Listener`,
  not `GestureDetector`, specifically so a vertical stroke never loses the
  gesture-arena contest to an enclosing `Scrollable`'s own drag recognizer.
  It's a fully "controlled component" — the owner (the screen) holds the
  stroke list and reacts to three callbacks; the widget itself holds no
  drawing state. It's shared between the main draw screen and every review
  card that needs a scratch pad (`DrawAndPickWidget`).
- **`KanjiRasterizer`** renders strokes to a `ui.Image` with zero Flutter
  widget dependency, so it's directly unit-testable.
- **`canonicalize()`** (`core/canonicalize.dart`) is the single most
  important "contract" file in the app: its constants (`targetSize=64`,
  `marginFrac=0.10`, `inkThreshold=200`) must match
  `kanjirec/preprocessing.py`'s `canonicalize()` exactly, or the model sees
  out-of-distribution input. It expects a supersampled source (256px, not
  64px) so cropping-then-upscaling a small drawing doesn't throw away detail
  before it even gets here.
- **`KanjiRecognizer`** (`core/kanji_recognizer.dart`) loads
  `assets/model/model.onnx` by copying it to a **content-hashed** temp file
  path (`model_<md5>.onnx`) before opening an `OrtSession` on it — not the
  plugin's own `createSessionFromAsset`, which caches by filename only and
  silently kept serving a stale model across several real model swaps
  during development (confirmed by comparing raw logits against a direct
  Python run). Also loads `classes.json` (index → character label) and
  `inference_config.json` (which class index is the reject/"not a kanji"
  sentinel).
- **`DrawAndPickWidget`** (`features/review/draw_and_pick.dart`) wraps this
  whole pipeline into one reusable "draw → auto-recognize after every
  stroke → tap a top-K candidate" widget, used by: the review session's
  draw-based cards, the kanji browser's custom-set editor, and the word
  lookup screen's character-by-character input.

Both the main lookup screen and `DrawAndPickWidget` show at most 3
candidates, but collapse to just the top one whenever it's already
confident (probability ≥ 0.9) — no point making the user disambiguate
against distractors when there's nothing to disambiguate. Both request a
few extra candidates beyond what they show, since `isReject` predictions
don't count as a usable candidate and would otherwise shrink the visible
list.

## Database (`core/db`, drift/SQLite)

Six tables, `schemaVersion` currently 6 (see `app_database.dart`'s
`MigrationStrategy` for the upgrade path from each prior version):

| Table | Primary key | Purpose |
|---|---|---|
| `ReviewCards` | (character, cardType) | SM-2 state (ease factor, interval, repetitions, due date, lapses) — one row per skill being tracked for a character. |
| `ReviewLog` | autoincrement id | Append-only history of every grading event, for future stats/streaks. Not read by the scheduler itself. |
| `KanjiNotes` | character | User-editable personal `storyKeyword` (short recall cue) + `story` (fuller mnemonic), seeded from `assets/stories.json` on first run, freely editable after. |
| `KanjiStatic` | character | Reference data synced from `jlpt_levels.json`/`rtk_index.json`/`kanji_level_rank.json` at startup — lets scope filtering be one SQL predicate instead of in-memory joins. |
| `CompositaProgress` | (character, word, direction) | Which composita words have been passed (quality ≥ 3) at least once, per direction (reading/writing) — the composita tracking store, statistics-only. |
| `CustomComposita` | (character, word) | Which composita the user explicitly attached to a kanji in their Custom study list. |

`ReviewRepository` (`features/review/review_repository.dart`) is the only
class that queries these tables; `sm2.dart`'s pure scheduling function never
touches the database directly.

## The review engine

### Four learning axes (A/B/C/D)

Per kanji, the app tracks four independent skills, each its own
`CardType`/`ReviewCards` row (see `plan.md` at the repo root for the
original design rationale):

| Card type | Axis | What's shown | What's produced |
|---|---|---|---|
| `drawFromMeaning` | A | Meaning + readings (+ personal keyword) | Draw the kanji (`DrawAndPickWidget`) |
| `kanjiRecognition` | B | The bare kanji | Recall reading + meaning, self-graded |
| `readingCloze` | C/D | A sentence with the target word blanked | Recall its reading, self-graded |
| `drawInSentence` | C/D | A sentence with the target kanji replaced by a canvas | Draw the kanji in context |

**"Green" is kanji-only** (`ReviewRepository.overallProgress`): a character's
`reading` status comes from `kanjiRecognition` alone, `writing` from
`drawFromMeaning` alone — a plain `repetitions > 0` check, no
cross-referencing composita. Composita cards (`readingCloze`/`drawInSentence`)
never gate this; they're tracked separately in `CompositaProgress` and
surfaced only in Statistics. This is a deliberate simplification from an
earlier design where "all composita covered" also had to be true for green.

`readingCloze` and `drawInSentence` are **not** separate mechanisms for C
vs. D — they're the same skill (composita reading / composita drawing),
just with or without a real mined example sentence for context:
`sentence_selection.dart`'s `syntheticSentenceFor()` builds a one-token
pseudo-"sentence" (just the word itself) whenever no real sentence exists,
so C-only testing (no D coverage) still runs through the exact same
`FuriganaSentence`-based card builders.

### `StudyScope` — what's in scope

`features/review/study_scope.dart` defines which characters (and, for
composita, which words) are currently being studied. Exactly one mode is
active at a time:

- **`jlpt`** — one or more JLPT levels, plus an independent
  `compositaCeiling` (the hardest JLPT level a composita *word* is allowed
  to be, gating C/D separately from which kanji *levels* are selected — a
  kanji's own level and a word containing it can differ). New-card pacing is
  handled by a configurable "new kanji per day" cap (default 10, chosen in
  `ReviewStartScreen` and persisted via `shared_preferences`) rather than
  manual chunking.
- **`custom`** — an explicit, hand-picked `Set<String>` of characters, each
  with its own hand-picked set of composita words (`CustomComposita`) — no
  ceiling concept, since the whole point is a curated list.
- **`rtk`** — an RTK-ordinal cutoff. Kept in the data/schema layer but
  deliberately **hidden from every current screen** (a product decision to
  de-emphasize RTK, not a removal — the enum value, `RtkIndexRepository`,
  and `StudyScope.matches`'s rtk branch are all still fully functional and
  tested).

`StudyScope` is persisted via `shared_preferences` (a handful of scalars, no
drift table — `StudyScopeRepository`) and exposed as a `ValueNotifier<StudyScope>`,
the one piece of state observed reactively across screens (kanji browser
grid filtering, the review launcher, both edit screens).

`sentence_selection.dart` sits between `StudyScope` and the review engine,
translating "what's the scope" into "which composita/sentences are
actually eligible right now": `compositaEnabled`, `jlptCeilingFor`,
`compositaWithinCeiling`, `eligibleComposita`, `pickUntested`.

### `ReviewFocus` — what's being quizzed this session

Orthogonal to `StudyScope` (which defines *what* is in scope):
`features/review/review_focus.dart`'s `ReviewFocus` (`core`/`composita`/`both`)
is chosen fresh each time in `ReviewStartScreen` and controls which
`CardType`s a given session introduces and draws from — `core` restricts to
kanji-only card types, `composita` to composita card types, `both` applies
no restriction.

### Backlog prevention (new-card suppression after extended absence)

When a user skips reviewing for 2+ days, due cards pile up. To prevent
overwhelming the user with new material on top of a large backlog,
`_introduceNewCardsForToday()` in `review_session_screen.dart` checks
the gap between `review.last_intro_date` (persisted in
`SharedPreferences`) and today: if **2 or more days** have passed AND
there are already due cards waiting, automatic new-card introduction is
skipped so old reviews get cleared first. The user can still explicitly
add more via the "Learn more" button (`bypassDailyCap`).

A **single-day** gap is not treated as a backlog — that's normal SM-2
behaviour (yesterday's newly introduced cards come back after 1 day on
their first review).

### SM-2 scheduling

`features/review/sm2.dart` is a pure, zero-dependency port of the classic
SM-2 spaced-repetition algorithm (`computeNextReview`) plus
`gradeDrawAndPick`, which turns a draw-and-pick result into an SM-2 quality
score 0–5:

- target absent from the recognizer's top-K candidates → `q=0`.
- target present, but the user tapped a different one → `q=2` (recognized
  *something* familiar, but misidentified it — weaker than a blackout, but
  still a failed recall since `q<3`).
- target present and correctly picked → `q=5`/`4`/`3` by rank (1st/2nd/3rd+;
  rank 3+ lands exactly on SM-2's own "correct with serious difficulty"
  boundary).

`ReviewRepository.dueCards()` selects due-or-fragile cards (fragile =
`repetitions <= 1`, so a card that's only been reviewed once doesn't
disappear from the pool for weeks the instant it's passed) oldest-due-first,
then **reorders** the result via the top-level `interleaveByCharacter()`
function so a character's several card types — typically introduced
together with the same due date — don't show up back-to-back in the
session.

### `ReviewSessionScreen` — the quiz UI

`features/review/review_session_screen.dart` presents one queue entry at a
time, building whichever card widget matches its `CardType`. Two of the four
(`drawFromMeaning`, `drawInSentence`) are "draw and pick a candidate" cards
built on `DrawAndPickWidget`, graded immediately by `gradeDrawAndPick` but
**not advanced** until the user dismisses a feedback screen (so a miss
always reveals the right answer instead of silently moving on). The other
two (`kanjiRecognition`, `readingCloze`) are "reveal, then self-grade
Again/Good" cards, mirroring classic Anki-style review.

A layout constraint worth knowing if you touch this file: the drawing
canvas is deliberately kept **outside** any `SingleChildScrollView` (a
scrollable ancestor's drag recognizer competes with the canvas's raw
`Listener` for vertical strokes and can win), and the info block above it is
a plain, non-`Expanded` `Column` (an `Expanded` sibling would reflow —
visibly shifting the canvas — every time `DrawAndPickWidget`'s own height
changes after each stroke). `_buildDrawInSentence` measures real available
height via `LayoutBuilder` and gives the (variable-length, wrappable)
sentence a `ConstrainedBox`+`SingleChildScrollView` sized from what's
actually left over, rather than a guessed fixed budget.

## Kanji info / composita / sentences

- **`KanjiDetailContent`** (`features/kanji_browser/kanji_detail_content.dart`)
  is the one shared "everything about this character" widget, embedded both
  as a full screen (kanji browser → tap a cell) and inside a modal bottom
  sheet (lookup screen → tap a recognized candidate) and inside the review
  session's feedback screen. It shows, in order: the character (+ copy
  button), readings/meaning (skipped for kana — see below), stroke order
  (`StrokeOrderView`), personal keyword/story fields (skipped for kana),
  composita (top-ranked, via `rankComposita`), and — as the final section —
  example sentences for those composita words, rendered with
  `FuriganaSentence` and, when available, a translation.
- Kana (hiragana/katakana) are detected by Unicode range and shown a
  reduced view (just the character + stroke order) — they have no
  on'yomi/kun'yomi/meaning, composita, or mnemonic story in the same sense a
  kanji does, so those sections are simply hidden rather than shown empty.
- **`FuriganaSentence`** (`features/review/furigana_sentence.dart`) renders a
  tokenized sentence with per-word ruby furigana as a `Wrap` (not
  `RichText`/`WidgetSpan` — CJK has no whitespace word breaks, so per-token
  wrapping is the correct line-break unit here). It strips any trailing
  okurigana already visible in a token's surface from the displayed
  reading (standard furigana convention: 一[ひと]つ, not 一[ひとつ]つ), and
  supports masking/emphasizing/boxing/replacing the one target token a card
  is testing.

## Testing conventions

The test suite mirrors `lib/`'s directory structure. A few non-obvious
patterns recur throughout and are worth knowing before adding a test:

- **Real asset loads need `tester.runAsync()`.** `AppDependencies.load()`
  does real `rootBundle` reads; a plain `tester.pump()` runs inside a
  fake-async zone whose virtual clock never lets those real futures
  resolve. Each test file that calls `loadTestDeps`/constructs a full
  `AppDependencies` tends to live in its own file — a second
  `runAsync`-wrapped real asset load in the same test *process* has been
  observed to hang indefinitely.
- **`GridView.builder` only realizes on-screen children.** Tests that need
  to assert something about a filtered/large result set (e.g. the kanji
  browser's search) call the `SliverChildBuilderDelegate`'s own `builder`
  directly for every index, rather than `find.descendant`/`widgetList`,
  which would silently miss anything scrolled out of the initial viewport.
- **Pure logic is factored out of widgets specifically to be unit-tested
  without a running app**: `sm2.dart`, `canonicalize.dart`,
  `kanji_rasterizer.dart`, `interleaveByCharacter()`, `kanji_search.dart`'s
  matching functions, `sentence_selection.dart`'s helpers. Prefer a plain
  `test()` over a `testWidgets()` wherever the logic under test has no
  actual Flutter/widget dependency.
- **`StrokeOrderView`'s animation loops forever**, so any test that
  navigates to a screen containing it must use bounded `tester.pump(duration)`
  calls rather than `tester.pumpAndSettle()`, which would never see frame
  scheduling stop.

## The `kanjirec` pipeline (external, sibling project)

Every file under `assets/` (the ONNX model + every bundled JSON) is
generated by a separate sibling Python project, `kanjirec`
(`scripts/build_*.py`, `train.py`, `export_onnx.py`). kanjitomo never
generates or mutates this data at runtime — it's a read-only consumer.
Regenerating an asset (e.g. after a data-quality fix) means running the
corresponding script in `kanjirec` and re-copying its output into
`kanjitomo/assets/`; see that project's own docs for the pipeline details.
