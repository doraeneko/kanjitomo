import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show MethodChannel, PlatformException;
import '../../app_dependencies.dart';
import '../../data/word_index_repository.dart';
import '../../l10n/app_localizations.dart';
import '../review/sentence_selection.dart' show isKanji;

/// Pick the field index that most likely holds the kanji or word being
/// studied, given each note's raw field values.
///
/// Only fields that contain kanji in nearly as many notes as the best field
/// are considered; among those, the one with the fewest kanji wins. This
/// prefers a "Kanji" or "Vocabulary" field over an example-sentence field,
/// which also has kanji in every note but many more of them.
@visibleForTesting
int pickKanjiFieldIndex(List<List<String>> notesFields) {
  var fieldCount = 0;
  for (final fields in notesFields) {
    if (fields.length > fieldCount) fieldCount = fields.length;
  }
  if (fieldCount == 0) return 0;

  final coverage = List.filled(fieldCount, 0);
  final kanjiCount = List.filled(fieldCount, 0);
  for (final fields in notesFields) {
    for (var fi = 0; fi < fields.length; fi++) {
      final count = stripAnkiHtml(fields[fi]).runes.where(isKanji).length;
      if (count > 0) coverage[fi]++;
      kanjiCount[fi] += count;
    }
  }

  final maxCoverage = coverage.reduce((a, b) => a > b ? a : b);
  if (maxCoverage == 0) return 0;

  int? best;
  for (var fi = 0; fi < fieldCount; fi++) {
    if (coverage[fi] < maxCoverage * 0.8) continue;
    if (best == null || kanjiCount[fi] < kanjiCount[best]) best = fi;
  }
  return best!;
}

/// Strip HTML tags and common entities from an Anki field value.
String stripAnkiHtml(String text) {
  return text
      .replaceAll(RegExp(r'<br\s*/?>'), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .trim();
}

/// Result returned from the AnkiDroid import wizard.
class AnkiImportResult {
  final List<String> kanji;
  final Map<String, List<String>> extraComposita;
  const AnkiImportResult({required this.kanji, required this.extraComposita});
}

/// Stepped wizard for importing kanji from AnkiDroid on the same device.
/// Android only — uses AnkiDroid's Content Provider API via MethodChannel.
///
/// Steps:
/// 0. Deck selection
/// 1. Note type (model) selection
/// 2. Field selection (auto-detected field marked as recommended)
/// 3. Preview (extracted kanji with checkboxes)
class AnkiImportScreen extends StatefulWidget {
  final AppDependencies deps;
  const AnkiImportScreen({super.key, required this.deps});

  @override
  State<AnkiImportScreen> createState() => _AnkiImportScreenState();
}

class _AnkiImportScreenState extends State<AnkiImportScreen> {
  static const _notesChannel = MethodChannel('com.kanjitomo/anki_notes');

  int _step = 0;

  // Step 0: Deck selection
  List<_DeckEntry>? _decks;

  // Step 1: Model selection
  List<_ModelEntry>? _models;

  // Loaded after deck is selected
  List<Map<String, dynamic>>? _allNotes;

  // Step 2: Field selection
  List<Map<String, dynamic>>? _modelNotes;
  List<_FieldEntry>? _fieldOptions;
  int? _recommendedFieldIndex;

  // Step 2: Preview
  List<_KanjiPreviewItem>? _previewItems;
  List<_KanjiPreviewItem>? _poolCompositaItems;

  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initAnki();
  }

  Future<void> _initAnki() async {
    setState(() => _loading = true);
    try {
      final granted = await _notesChannel.invokeMethod<bool>('requestPermission');
      if (granted != true) {
        if (mounted) {
          setState(() {
            _error = 'permission_denied';
            _loading = false;
          });
        }
        return;
      }

      // Query decks first.
      final decksRaw = await _notesChannel.invokeMethod<List<dynamic>>('queryDecks');
      if (!mounted) return;

      final decks = <_DeckEntry>[];
      for (final d in decksRaw?.cast<Map<dynamic, dynamic>>() ?? []) {
        final id = d['id'] as int;
        final name = d['name']?.toString() ?? 'Deck $id';
        decks.add(_DeckEntry(name: name, id: id));
      }
      decks.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;

      if (decks.isEmpty) {
        setState(() {
          _error = 'no_models';
          _loading = false;
        });
        return;
      }

      _decks = decks;

      if (decks.length == 1) {
        _onDeckSelected(decks.first);
      } else {
        setState(() {
          _loading = false;
          _step = 0;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _error = _classifyError(e);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _classifyError(e);
          _loading = false;
        });
      }
    }
  }

  String _classifyError(Object? error) {
    final msg = error?.toString() ?? '';
    if (msg.contains('permission') || msg.contains('Permission')) {
      return 'permission_denied';
    }
    if (msg.contains('not installed') ||
        msg.contains('No Activity found') ||
        msg.contains('ContentProvider')) {
      return 'not_installed';
    }
    return 'unknown';
  }

  Future<void> _onDeckSelected(_DeckEntry deck) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    try {
      // Query notes for this deck first, so we know which models are used.
      final notesRaw = await _notesChannel.invokeMethod<List<dynamic>>(
        'queryNotesByDeck',
        {'deckName': deck.name},
      );
      if (!mounted) return;

      final deckNotes = notesRaw?.cast<Map<dynamic, dynamic>>().map((m) {
        return <String, dynamic>{
          'id': m['id'],
          'mid': m['mid'],
          'fields': (m['fields'] as List).cast<String>(),
          'tags': m['tags']?.toString() ?? '',
        };
      }).toList() ?? [];
      _allNotes = deckNotes;

      // Collect model IDs actually present in this deck.
      final midSet = deckNotes.map((n) => n['mid'] as int).toSet();

      // Query all models, then filter to only those in the deck.
      final modelsRaw = await _notesChannel.invokeMethod<List<dynamic>>('queryModels');
      if (!mounted) return;

      final models = <_ModelEntry>[];
      for (final m in modelsRaw?.cast<Map<dynamic, dynamic>>() ?? []) {
        final id = m['id'] as int;
        if (!midSet.contains(id)) continue;
        final name = m['name']?.toString() ?? 'Model $id';
        final fieldNamesRaw = m['fieldNames']?.toString() ?? '';
        final fieldNames = fieldNamesRaw.isEmpty
            ? <String>[]
            : fieldNamesRaw.split('\x1f');
        final noteCount = deckNotes.where((n) => n['mid'] == id).length;
        models.add(_ModelEntry(
          name: name,
          id: id,
          noteCount: noteCount,
          fieldNames: fieldNames,
        ));
      }
      models.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

      if (!mounted) return;

      if (models.isEmpty) {
        setState(() {
          _error = 'no_models';
          _loading = false;
        });
        return;
      }

      _models = models;

      if (models.length == 1) {
        _onModelSelected(models.first);
      } else {
        setState(() {
          _loading = false;
          _step = 1;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _classifyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _onModelSelected(_ModelEntry model) async {
    if (!mounted) return;
    setState(() {
      _loading = true;
    });

    try {
      // Filter already-loaded deck notes to the selected model.
      final filteredNotes = (_allNotes ?? [])
          .where((n) => n['mid'] == model.id)
          .toList();

      final notesFields = [
        for (final n in filteredNotes) n['fields'] as List<String>,
      ];
      final bestFieldIndex = pickKanjiFieldIndex(notesFields);

      var fieldCount = model.fieldNames.length;
      for (final fields in notesFields) {
        if (fields.length > fieldCount) fieldCount = fields.length;
      }

      final options = <_FieldEntry>[];
      for (var fi = 0; fi < fieldCount; fi++) {
        final kanji = <String>{};
        String? sample;
        for (final fields in notesFields) {
          if (fi >= fields.length) continue;
          final text = stripAnkiHtml(fields[fi]);
          if (sample == null && text.isNotEmpty) sample = text;
          for (final rune in text.runes) {
            if (isKanji(rune)) kanji.add(String.fromCharCode(rune));
          }
        }
        options.add(_FieldEntry(
          index: fi,
          name: fi < model.fieldNames.length && model.fieldNames[fi].isNotEmpty
              ? model.fieldNames[fi]
              : 'Field ${fi + 1}',
          sample: sample ?? '',
          kanjiCount: kanji.length,
        ));
      }

      _modelNotes = filteredNotes;
      _fieldOptions = options;
      _recommendedFieldIndex = bestFieldIndex;

      if (options.length <= 1) {
        await _buildPreviewData(filteredNotes, bestFieldIndex);
      } else if (mounted) {
        setState(() {
          _loading = false;
          _step = 2;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _classifyError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _buildPreviewData(
    List<Map<String, dynamic>> notes,
    int fieldIndex,
  ) async {
    final pool = widget.deps.studyScope.scope.value.characters;

    // Extract kanji from the chosen field across all notes.
    final kanjiSet = <String>{};
    final fieldTexts = <String>[];
    for (final note in notes) {
      final fields = note['fields'] as List<String>;
      if (fieldIndex >= fields.length) continue;
      final text = stripAnkiHtml(fields[fieldIndex]);
      fieldTexts.add(text);
      for (final rune in text.runes) {
        if (isKanji(rune)) {
          kanjiSet.add(String.fromCharCode(rune));
        }
      }
    }

    // Sort by JLPT level (N5 first), then RTK order within level.
    final kanjiList = kanjiSet.toList();
    kanjiList.sort((a, b) {
      final la = widget.deps.jlptLevels.levelOf(a);
      final lb = widget.deps.jlptLevels.levelOf(b);
      final levelA = la != null ? (6 - la) : 100;
      final levelB = lb != null ? (6 - lb) : 100;
      if (levelA != levelB) return levelA.compareTo(levelB);
      final ai = widget.deps.rtkIndex.indexOf(a) ?? 99999;
      final bi = widget.deps.rtkIndex.indexOf(b) ?? 99999;
      return ai.compareTo(bi);
    });

    // Always extract composita.
    final extraComposita = <String, List<String>>{};
    if (widget.deps.wordIndex.isLoaded) {
      final wordIndex = widget.deps.wordIndex;
      for (final text in fieldTexts) {
        _extractCompositaFromText(text, kanjiSet, wordIndex, extraComposita);
      }
    }

    // Split into new kanji and in-pool kanji with new composita.
    final newItems = <_KanjiPreviewItem>[];
    final poolItems = <_KanjiPreviewItem>[];
    for (final char in kanjiList) {
      final inPool = pool.contains(char);
      final composita = extraComposita[char] ?? [];
      if (inPool) {
        if (composita.isNotEmpty) {
          poolItems.add(_KanjiPreviewItem(
            character: char,
            inPool: true,
            selected: true,
            composita: composita,
          ));
        }
      } else {
        newItems.add(_KanjiPreviewItem(
          character: char,
          inPool: false,
          selected: true,
          composita: composita,
        ));
      }
    }

    if (mounted) {
      setState(() {
        _previewItems = newItems;
        _poolCompositaItems = poolItems;
        _loading = false;
        _step = 3;
      });
    }
  }

  Future<void> _onFieldSelected(_FieldEntry field) async {
    setState(() => _loading = true);
    try {
      await _buildPreviewData(_modelNotes ?? [], field.index);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = _classifyError(e);
          _loading = false;
        });
      }
    }
  }

  void _extractCompositaFromText(
    String text,
    Set<String> kanjiSet,
    WordIndexRepository wordIndex,
    Map<String, List<String>> result,
  ) {
    for (var i = 0; i < text.length;) {
      String? bestWord;
      for (var len = 8; len >= 2; len--) {
        if (i + len > text.length) continue;
        final candidate = text.substring(i, i + len);
        if (wordIndex.containsWord(candidate)) {
          bestWord = candidate;
          break;
        }
      }
      if (bestWord != null) {
        final wordKanji = bestWord.runes
            .where((r) => isKanji(r))
            .map((r) => String.fromCharCode(r))
            .where((c) => kanjiSet.contains(c))
            .toSet();
        for (final char in wordKanji) {
          final list = result.putIfAbsent(char, () => []);
          if (!list.contains(bestWord)) {
            list.add(bestWord);
          }
        }
        i += bestWord.length;
      } else {
        i++;
      }
    }
  }

  void _confirm() {
    final items = _previewItems;
    if (items == null) return;

    final selectedNew = items.where((i) => i.selected).toList();
    final kanji = selectedNew.map((i) => i.character).toList();

    final composita = <String, List<String>>{};
    for (final item in selectedNew) {
      if (item.composita.isNotEmpty) {
        composita[item.character] = item.composita;
      }
    }
    for (final item in _poolCompositaItems ?? <_KanjiPreviewItem>[]) {
      if (item.selected && item.composita.isNotEmpty) {
        composita[item.character] = item.composita;
      }
    }

    if (kanji.isEmpty && composita.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pop(
      AnkiImportResult(kanji: kanji, extraComposita: composita),
    );
  }

  int get _selectedNewCount =>
      _previewItems?.where((i) => i.selected).length ?? 0;

  int get _poolCompositaCount =>
      _poolCompositaItems?.where((i) => i.selected).length ?? 0;

  // ── Build ──────────────────────────────────────────────────────────────

  /// Whether [step] was shown to the user (steps with one option are skipped).
  bool _stepShown(int step) {
    switch (step) {
      case 0:
        return (_decks?.length ?? 0) > 1;
      case 1:
        return (_models?.length ?? 0) > 1;
      case 2:
        return (_fieldOptions?.length ?? 0) > 1;
      default:
        return true;
    }
  }

  void _goBack() {
    for (var prev = _step - 1; prev >= 0; prev--) {
      if (_stepShown(prev)) {
        setState(() => _step = prev);
        return;
      }
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _goBack,
          ),
          title: Text(l.ankiImportTitle),
        ),
        body: SafeArea(child: _buildBody(l)),
      ),
    );
  }

  Widget _buildBody(AppLocalizations l) {
    if (_error != null) return _buildError(l);
    if (_loading) return _buildLoading(l);
    switch (_step) {
      case 0:
        return _buildDeckSelection(l);
      case 1:
        return _buildModelSelection(l);
      case 2:
        return _buildFieldSelection(l);
      case 3:
        return _buildPreview(l);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildLoading(AppLocalizations l) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(l.ankiImportLoadingNotes),
        ],
      ),
    );
  }

  Widget _buildError(AppLocalizations l) {
    final String message;
    if (_error == 'permission_denied') {
      message = l.ankiImportPermissionDenied;
    } else if (_error == 'not_installed') {
      message = l.ankiImportNotInstalled;
    } else if (_error == 'no_models') {
      message = l.ankiImportNoNotes;
    } else if (_error == 'no_notes') {
      message = l.ankiImportNoKanji;
    } else {
      message = l.ankiImportUnknownError;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48,
                color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _error = null;
                  _loading = false;
                });
                _initAnki();
              },
              child: Text(l.ankiImportRetry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeckSelection(AppLocalizations l) {
    final decks = _decks;
    if (decks == null || decks.isEmpty) {
      return Center(child: Text(l.ankiImportNoNotes));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(l.ankiImportSelectDeck,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: decks.length,
            itemBuilder: (context, index) {
              final deck = decks[index];
              return ListTile(
                title: Text(deck.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _onDeckSelected(deck),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelection(AppLocalizations l) {
    final models = _models;
    if (models == null || models.isEmpty) {
      return Center(child: Text(l.ankiImportNoNotes));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(l.ankiImportSelectModel,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: models.length,
            itemBuilder: (context, index) {
              final model = models[index];
              return ListTile(
                title: Text(model.name),
                subtitle: model.noteCount > 0
                    ? Text('${model.noteCount} notes')
                    : null,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _onModelSelected(model),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFieldSelection(AppLocalizations l) {
    final fields = _fieldOptions ?? [];
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(l.ankiImportSelectField,
              style: Theme.of(context).textTheme.titleMedium),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              final recommended = field.index == _recommendedFieldIndex;
              return ListTile(
                leading: Icon(
                  recommended ? Icons.star : Icons.notes,
                  color: recommended ? colors.primary : null,
                ),
                title: Text(field.name),
                subtitle: Text(
                  [
                    if (field.sample.isNotEmpty)
                      field.sample.replaceAll('\n', ' '),
                    '${field.kanjiCount} kanji',
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                enabled: field.kanjiCount > 0,
                onTap: () => _onFieldSelected(field),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPreview(AppLocalizations l) {
    final items = _previewItems;
    final poolItems = _poolCompositaItems ?? [];
    if (items == null) return _buildLoading(l);

    if (items.isEmpty && poolItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(l.ankiImportNoKanji, textAlign: TextAlign.center),
        ),
      );
    }

    final hasConfirmable = _selectedNewCount > 0 || _poolCompositaCount > 0;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
            children: [
              if (items.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(l.ankiImportPreview,
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                for (final item in items)
                  _buildKanjiTile(item, l),
              ],
              if (poolItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  child: Text(
                    '${l.ankiImportAlreadyAdded} — new composita',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final item in poolItems)
                        FilterChip(
                          label: Text(
                            '${item.character} +${item.composita.length}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          selected: item.selected,
                          onSelected: (on) =>
                              setState(() => item.selected = on),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: hasConfirmable ? _confirm : null,
              child: Text(l.ankiImportConfirm(_selectedNewCount)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildKanjiTile(_KanjiPreviewItem item, AppLocalizations l) {
    final info = widget.deps.kanjiInfo.lookup(item.character);
    final meaning = info?.meanings.isNotEmpty == true
        ? info!.meanings.join(', ')
        : '';
    final level = widget.deps.jlptLevels.levelOf(item.character);

    return CheckboxListTile(
      value: item.selected,
      onChanged: (v) => setState(() => item.selected = v ?? false),
      secondary: Text(
        item.character,
        style: const TextStyle(fontSize: 28, fontFamily: 'NotoSansJP'),
      ),
      title: Text(meaning, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text([
        if (level != null) 'N$level',
        if (item.composita.isNotEmpty)
          '${item.composita.length} composita',
      ].join(' · ')),
    );
  }
}

class _DeckEntry {
  final String name;
  final int id;
  const _DeckEntry({required this.name, required this.id});
}

class _FieldEntry {
  final int index;
  final String name;
  final String sample;
  final int kanjiCount;
  const _FieldEntry({
    required this.index,
    required this.name,
    required this.sample,
    required this.kanjiCount,
  });
}

class _ModelEntry {
  final String name;
  final int id;
  final int noteCount;
  final List<String> fieldNames;
  const _ModelEntry({
    required this.name,
    required this.id,
    required this.noteCount,
    required this.fieldNames,
  });
}

class _KanjiPreviewItem {
  final String character;
  final bool inPool;
  bool selected;
  final List<String> composita;

  _KanjiPreviewItem({
    required this.character,
    required this.inPool,
    required this.selected,
    required this.composita,
  });
}
