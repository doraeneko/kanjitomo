
# Kanjitomo — Current Implementation Status

## What the app does

A kanji learning app for Japanese learners. Five main tabs:

1. **Lookup** — Draw a kanji to recognize it (ONNX model), see readings/meanings/stroke order
2. **Word Lookup** — Build words character-by-character, look up in JMdict dictionary
3. **Learning** — Hub for SRS review, quiz, kanji pool management, statistics
4. **Browse** — Searchable grid of all ~2,140 Jōyō kanji with progress indicators
5. **Help** — Tour, acknowledgements, support links, bug report

## Core systems

### SRS Review (SM-2)
Four card types per kanji:
- **A: drawFromMeaning** — meaning+readings shown, draw the kanji
- **B: kanjiRecognition** — kanji shown, recall reading+meaning (self-graded)
- **C: readingCloze** — sentence with word highlighted, recall reading (self-graded)
- **D: drawInSentence** — sentence with target kanji replaced by draw canvas

"Green" (mastered) = A+B passed. C+D tracked separately in statistics only.

### Composita system
Each kanji has ranked compound words (composita) from bundled data (~95k entries).
Users can auto-select or manually pick composita per kanji.
Composita drive the C+D card types — each word gets its own cards.
Sentences are mined from Tatoeba + LLM-generated, matched to composita words.

### Quiz
Multiple-choice self-test (no SRS effect). Two question types:
kanjiToReading and readingToKanji. Configurable question count.

### Data
- ~110 MB bundled JSON assets (composita, sentences, JMdict dictionary, stroke paths, kanji info)
- Drift/SQLite database for review state, user notes, composita selections
- SharedPreferences for UI state, onboarding flags

### Freemium
InAppPurchase integration exists. Free tier: 56 kanji limit.
**Currently hardcoded to Pro=true for development.**

## What's ready

- All five tabs functional
- Full SRS review cycle (all 4 card types, SM-2 scheduling, undo, requeue on fail)
- Kanji recognition via ONNX model (draw → recognize → pick)
- Composita + sentence integration (bundled data, user selections, synthetic fallback)
- Kanji browser with search (reading, meaning, stroke count) and progress dots
- Editable personal stories/keywords per kanji (autosaved)
- Animated stroke order display
- Quiz system (multiple choice, distractors)
- Statistics screen (per-card-type breakdown, composita coverage, reset)
- Onboarding: welcome screen, 5-step tour, first-time dialogs per feature
- Help screen with tour reset, acknowledgements, coffee/bug-report links
- TTS (text-to-speech) for Japanese
- 40 test files with good coverage (SRS logic, review flows, UI screens)
- Localization framework (ARB-based, 3 locales declared)

## What's missing for public launch

### Must-fix

1. **Revert Pro status** — `pro_status_repository.dart` has `isProUnlocked` hardcoded to `true`. Must revert to `false` and read from SharedPreferences/purchase state. Without this, every user gets Pro for free.

2. **App Store / Play Store setup** — No store listings, screenshots, descriptions, privacy policy, or metadata prepared. Need app icons finalized, feature graphics, and store descriptions in supported languages.

3. **InAppPurchase product configuration** — The `pro_unlock` product ID needs to be created in App Store Connect and Google Play Console. Purchase flow exists in code but hasn't been tested against real store backends.

4. **Privacy policy** — Required by both stores. Needs to cover: what data is stored locally (review progress, personal notes), what's NOT collected (no analytics, no server communication), TTS usage.

5. **Version number** — Currently `0.1.0+1`. Needs proper versioning before release.

### Should-fix

6. **Indonesian/Vietnamese translations incomplete** — ARB UI strings are partially translated (many fall back to English). Content data (kanji meanings, composita meanings, sentence translations) is English-only in all locales. Either complete the translations or remove vi/id from supported locales for launch.

7. **Old screens not deleted** — `jlpt_edit_screen.dart`, `custom_edit_screen.dart`, `custom_add_screen.dart` still exist but are no longer navigated to. Their test files also remain. Should be deleted to avoid confusion.

8. **Old test files not deleted** — Tests for removed screens (`jlpt_edit_screen_test.dart`, `jlpt_edit_daily_cap_test.dart`, `custom_edit_screen_test.dart`, `custom_edit_daily_cap_test.dart`, `review_start_screen_learn_new_test.dart`, `review_session_learn_more_test.dart`) still exist.

9. **Asset size optimization** — ~110 MB of bundled JSON is large. Consider: lazy loading, compression, or splitting into downloadable packs. The word_index.json alone is 35 MB.

10. **iOS testing** — Development has focused on Android. iOS build, permissions (TTS), and store setup need verification.

11. **Landscape orientation** — Locked to portrait. Not a blocker but limits tablet usability.

12. **Error handling / crash reporting** — No crash reporting service integrated (Sentry, Firebase Crashlytics, etc.). Errors are silent in production.

13. **Analytics** — No usage analytics. Not strictly needed for launch but helpful for understanding user behavior and prioritizing features.

### Nice-to-have (post-launch)

14. **Backup/restore** — No way to export or import review progress. Users lose everything on reinstall.

15. **Dark mode** — Uses Material 3 with indigo seed color but no explicit dark theme support.

16. **Tablet layout** — Single-column phone layout only. No adaptive layout for tablets.

17. **Offline model** — The ONNX model and all data are bundled, so the app works fully offline. This is a strength worth highlighting in store listings.

18. **Accessibility** — Basic accessibility (text scaling support exists in review layout calculations) but no comprehensive audit done.

---

# Translation assessment: Vietnamese + Indonesian

(See ARCHITECTURE.md for full translation effort breakdown — ~259,000 strings across UI+data per language.)
