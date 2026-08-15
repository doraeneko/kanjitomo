# Tangotomo — JLPT Vocabulary Learning App

## Concept

Learn Japanese vocabulary through sentences, not isolated words. Every word card is a **sentence card** — at least one example sentence per word, enriched with real-world context (screenshots, photos, audio) that the user collects from their immersion.

Cross-platform (phone + PC) with sync between devices.

## Core Data

### Vocabulary

- ~12,262 words with verified JLPT level tags (sourced from jlpt-word-list / tanos.co.uk, cross-referenced with JMdict)
- Inferred levels from kanji are **not reliable** for word difficulty (e.g. 大丈夫 = N5 kanji but N4 word, 一応 = N5 kanji but N2 word) — only use actual tags
- Distribution: N1 ~4,200 / N2 ~2,600 / N3 ~3,300 / N4 ~1,000 / N5 ~1,100
- Expand later with additional community lists and frequency data to reach estimated ~20,000 total JLPT words

### Sentences (prebundled)

Every word needs at least 1 example sentence with English translation. Target 2-3 per word.

**Pipeline:**
1. Match against Tatoeba corpus first (good coverage for N5-N3 common words)
2. LLM-generate for uncovered words (with reading, meaning, level as context; validate target word appears in output)
3. Tokenize + furigana via MeCab/Sudachi (reuse kanjirec pipeline)
4. Quality pass: spot-check per level, flag bad tokenizations

Estimated output: ~50-60k sentences, ~5-10MB as JSON.

Sentence selection should prefer sentences at or below the word's JLPT level (don't use N1 grammar to teach an N5 word).

### Existing infrastructure (from kanjirec)

- `build_composita.py` — already sources JLPT word lists, maps levels, cross-references JMdict
- `build_sentences.py` — already mines Tatoeba for example sentences with tokenization
- `composita.json` — 95k words with readings, meanings, JLPT levels, frequency ranks
- `jlpt_levels.json` — kanji-to-JLPT mapping
- Tatoeba corpus matching + MeCab tokenization pipeline

## Data Model

```
Word
  ├── word (kanji form)
  ├── reading
  ├── meaning
  ├── jlptLevel (N1-N5)
  ├── frequencyRank
  ├── Sentence[] (at least one)
  │     ├── text (Japanese)
  │     ├── translation (English)
  │     ├── furigana tokens
  │     ├── source (tatoeba / llm / user)
  │     └── Media[] (user-added)
  │           ├── type (screenshot / photo / audio)
  │           ├── data (file reference)
  │           └── addedOn (phone / pc)
  └── SRS state (per card type)
```

## Card Types

1. **Meaning recall** — show sentence with target word highlighted, recall meaning
2. **Reading recall** — show sentence with word in kanji, recall reading
3. **Listening** — play audio (TTS or user-recorded), identify word/meaning
4. **Cloze** — sentence with target word blanked, fill in
5. **Production** — given meaning, write/type the word

## Adding Words

### Draw-to-add (reuse from Kanjitomo)

Same draw-and-pick mechanic as Kanjitomo's word lookup: draw kanji/kana one character at a time using the neural net recognizer, building up a word. Each candidate tap appends to the word field. The word is looked up in JMdict as you type/draw. On match, the user can add it to their study pool.

When adding a word, the user picks (or confirms) an example sentence — either from the prebundled corpus or by typing/pasting their own. User-supplied sentences are tokenized and stored alongside the bundled ones.

This is the primary way to add words encountered in the wild (reading, conversation, media) beyond the structured JLPT progression.

### JLPT batch add

Select a level (N5–N1) and add the next N words in frequency order. Sentences are auto-assigned from the bundled corpus.

### Manual text input

Type or paste a word directly (for users who prefer keyboard over drawing). Same lookup + sentence selection flow.

## Platform & Sync

### Cross-platform

- Phone: Flutter (Android/iOS) — same stack as Kanjitomo
- PC: Flutter desktop (macOS/Windows/Linux) or Flutter web

### Device-specific features

- **PC:** screenshot tool (region select) to capture words from websites/games/reading
- **Phone:** camera/gallery pick for photos of words in the wild (signs, books, menus)
- **Both:** paste/type custom sentences, TTS playback
- **PC:** record or import audio clips

### Sync

Text/SRS state is tiny; media (screenshots, photos, audio) is the expensive part.

Options (to be decided):
- **Firebase/Supabase** — easiest for auth + realtime sync, ongoing cost
- **Self-hosted API + S3** — more control, more work
- **Peer-to-peer export/import** — simplest, no server, but manual

Offline-first is important (study on the train without connectivity).

## Shared Code with Kanjitomo

### Reuse directly
- SM-2 spaced repetition engine
- Furigana rendering (FuriganaSentence)
- TTS integration
- Drawing recognition (for writing practice card type)
- Drift database layer
- Pro/IAP infrastructure

### Adapt
- Card types — word-focused instead of kanji-focused
- Study scope — words instead of characters
- Sentence selection — sentences testing a specific word, not a kanji within a composita
- Review session screen — different card type UI

### New
- JLPT word list data pipeline (extend existing kanjirec scripts)
- Sentence corpus at word level (scale up from composita-level)
- Media capture + storage (screenshots, photos, audio)
- Sync infrastructure
- PC-specific UI (screenshot tool, audio recording)

## Open Questions

- How to structure shared code? Common package / monorepo / fork-and-diverge?
- Which sync backend? (Firebase vs self-hosted vs peer-to-peer)
- Should bundled sentences be supplemented with user sentences from day one, or is that a power-user feature?
- Audio: TTS-only for v1, or invest in recorded audio?
- How to handle words that span multiple JLPT levels in different senses?
- Card type selection: all 5 from the start, or start with 2-3 and expand?

## v1 Scope

1. 12k JLPT-tagged words with prebundled sentences (Tatoeba + LLM)
2. Phone app only (no sync yet)
3. Card types: meaning recall + reading recall + cloze
4. SM-2 review with new cards/day + max reviews/day caps
5. User can add custom sentences (text only, no media yet)
6. JLPT level filtering (study N5 first, then N4, etc.)
