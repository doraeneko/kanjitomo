
# Kanjitomo — Current Implementation Status

_Last updated: 2026-10-23 (version `1.0.0+10`)_

## What the app does

A kanji learning app for Japanese learners. Five main tabs:

1. **Lookup** — Draw a kanji to recognize it (ONNX model), or photograph text (camera OCR), and see readings/meanings/stroke order
2. **Word Lookup** — Build words character-by-character, look up in JMdict dictionary
3. **Learning** — Hub for SRS review, quiz, kanji pool management, statistics
4. **Browse** — Searchable grid of all ~2,140 Jōyō kanji with progress indicators
5. **Help** — Tour, acknowledgements, support links, bug report, restore purchases

## Core systems

### SRS Review (SM-2)
Four card types per kanji:
- **A: drawFromMeaning** (kanji recall) — meaning+readings shown, draw the kanji
- **B: kanjiRecognition** (kanji recognition) — kanji shown, recall reading+meaning (self-graded)
- **C: readingCloze** (composita recognition) — sentence with word highlighted, recall reading (self-graded)
- **D: drawInSentence** (composita recall) — sentence with target kanji replaced by draw canvas

"Green" (mastered) = A+B passed. C+D tracked separately in statistics only.

**Starting a review:** one Review button opens a sheet where the user ticks which of the four card kinds to include (with due counts per kind). The selection is remembered (`review.card_types` in SharedPreferences). All four ticked = unfiltered session.

**Grading:**
- Self-graded cards (B, C): Again (q=2) / Good (q=4) / Easy (q=5 + easy bonus).
- Drawing cards (A, D): graded by the recognizer (`gradeDrawAndPick`, q=0–5). After a correct drawing the user can tap Continue (keep that grade) or Easy (rolled back and re-graded with the easy bonus — one review-log entry per answer, undo still works).
- Easy bonus (`sm2.dart`): fresh card → 4 days (instead of 1), second review → 8 days (instead of 6), afterwards interval × ease × 1.3. Only applied when the user explicitly picks Easy.

### Composita system
Each kanji has ranked compound words (composita) from bundled data (~95k entries).
Users can auto-select or manually pick composita per kanji.
Composita drive the C+D card types — each word gets its own cards.
Sentences are mined from Tatoeba + LLM-generated, matched to composita words.

### AnkiDroid import (Android only)
Learning → Add/Remove → Import from AnkiDroid. Steps: deck → note type → **field** → preview.
- Steps auto-skip only when there is exactly one option.
- Field step lists each field with a sample value and its distinct-kanji count; the auto-detected field (`pickKanjiFieldIndex`: kanji in ≥80% as many notes as the best field, then fewest kanji — prefers vocab/kanji fields over example sentences) is starred.
- Composita are extracted from the chosen field only (greedy longest dictionary match, 8→2 chars) and saved as custom composita.
- Kotlin side (`MainActivity.kt`): `queryDecks`, `queryModels`, `queryNotesByDeck` (deck name escaped for Anki search syntax).

### Quiz
Multiple-choice self-test (no SRS effect). Two question types:
kanjiToReading and readingToKanji. Configurable question count.

### Recognition models
Two ONNX models bundled: `assets/model/standard` (~11 MB) and `assets/model/extended` (~18 MB).

### Data
- ~110 MB bundled JSON assets (composita, sentences, JMdict dictionary, stroke paths, kanji info); the 5 largest repos are lazy-loaded on first access
- Drift/SQLite database for review state, user notes, composita selections
- SharedPreferences for UI state, theme, onboarding flags, review settings

### Freemium
InAppPurchase integration exists (`pro_unlock` product, `purchase_service.dart`). Pro status defaults to `false` and is read from SharedPreferences.
**Note:** nothing in the app currently gates features on Pro — the only use of `isProUnlocked` is the "Restore purchases" button on the Help screen. The planned 56-kanji free-tier limit is not enforced.

## What's ready

- All five tabs functional, including camera OCR lookup and a writing grid
- Full SRS review cycle (all 4 card types, card-kind selection, Again/Good/Easy, SM-2 scheduling, undo, requeue on fail)
- Kanji recognition via ONNX model (standard + extended)
- Composita + sentence integration (bundled data, user selections, synthetic fallback)
- AnkiDroid import with field selection
- Kanji browser with search (reading, meaning, stroke count) and progress dots
- Editable personal stories/keywords per kanji (autosaved)
- Animated stroke order display
- Quiz system (multiple choice, distractors)
- Statistics screen (per-card-type breakdown, composita coverage, reset)
- Onboarding: welcome screen, tour, first-time dialogs per feature
- Theme selection incl. dark mode; splash screens with dark variants
- TTS (text-to-speech) for Japanese
- Localization: en, vi, id — UI strings complete except `statisticsLearntKanjiOnly` (missing in vi/id)
- Store material drafted: `store_listing.md`, `privacy_policy.html` (dated 2026-09-19), store screenshots in `docs/manual/store/`, feature graphic and 512px icon in `assets/icon/`
- User manual on GitHub Pages (`docs/manual/`)
- 39 test files

## What's missing for public launch

### Must-fix

1. **Decide on the free tier** — either enforce the free-tier limit (paywall when adding kanji beyond the limit) or drop the paywall concept and keep Pro as a supporter purchase. Right now buying Pro unlocks nothing.

2. **InAppPurchase product configuration** — Create `pro_unlock` in App Store Connect and Google Play Console; test the purchase and restore flows against real store backends.

3. **Store submission** — Listing text and screenshots are drafted; still needed: upload, content rating, data-safety form, hosting the privacy policy at a public URL.

4. **Failing tests** — `help_screen_test.dart` (expects text "Kanjitomo helps") and `widget_test.dart` (expects the `drawing_canvas` key at launch) fail; probably outdated after UI changes, not yet investigated.

### Should-fix

5. **Translations** — vi/id are missing `statisticsLearntKanjiOnly`. Content data (kanji meanings, composita meanings, sentence translations) is English-only in all locales. Complete or remove vi/id for launch.

6. **iOS testing** — Development has focused on Android. iOS build, permissions (camera, TTS) and store setup need verification. AnkiDroid import is Android-only.

7. **Asset size** — ~110 MB JSON plus ~29 MB models (release APK ≈ 212 MB). Compression or downloadable packs remain possible.

8. **Crash reporting** — None integrated. Errors are silent in production.

9. **Analyzer warnings** — Unused code in `add_remove_screen.dart` (`_buildCompositaSettings`, `_buildCompositaLine`, unused `words`) and `review_session_screen.dart` (`_showFeedbackDetails`, unused `l`).

10. **Repo hygiene** — `android/build/` is untracked but not in `.gitignore`; `assets/kanji_database.db` is an empty, unreferenced file.

### Nice-to-have (post-launch)

11. **Backup/restore** — No way to export or import review progress. Users lose everything on reinstall.
12. **Anki import: separate composita field** — Choose the kanji field and the composita field independently; skip composita the user already has so "+N" means new ones.
13. **Card ordering variety** — Avoid showing same-kanji cards back-to-back.
14. **Sentence furigana QA** — Fix fugashi misreadings (homographs, bad segmentation) by cross-checking against composita/JMdict.
15. **Landscape / tablet layout** — Locked to portrait, single-column phone layout.
16. **Analytics** — None. Not needed for launch.
17. **Accessibility** — Basic text-scaling support; no comprehensive audit.

---

# Translation assessment: Vietnamese + Indonesian

(See ARCHITECTURE.md for full translation effort breakdown — ~259,000 strings across UI+data per language.)
