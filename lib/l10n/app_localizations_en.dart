// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'kanjitomo';

  @override
  String failedToLoadAppData(String error) {
    return 'Failed to load app data: $error';
  }

  @override
  String get lookupTitle => '漢字とも';

  @override
  String get lookupWords => 'Words';

  @override
  String get lookupLearn => 'Learn';

  @override
  String get lookupBrowse => 'Browse';

  @override
  String get lookupHelp => 'Help';

  @override
  String get lookupHeading => 'Kanji';

  @override
  String get lookupClearDrawing => 'Clear drawing';

  @override
  String get lookupRecognizing => 'Recognizing...';

  @override
  String get lookupLoadingModel => 'Loading model...';

  @override
  String lookupModelFailed(String error) {
    return 'Model failed to load: $error';
  }

  @override
  String get lookupBestMatch => 'Best match:';

  @override
  String lookupTopN(int count) {
    return 'Top $count:';
  }

  @override
  String get lookupInCustomReview => 'In custom review';

  @override
  String get lookupAddToCustomReview => 'Add to custom review';

  @override
  String get wordLookupTitle => 'Word lookup';

  @override
  String get wordLookupDrawInstruction =>
      'Draw a kanji or kana character to add it to the word:';

  @override
  String get wordLookupWordLabel => 'Word';

  @override
  String get wordLookupClear => 'Clear';

  @override
  String get wordLookupNoEntry => 'No JMdict entry for this exact word.';

  @override
  String wordLookupCopied(String word) {
    return 'Copied \"$word\" to clipboard';
  }

  @override
  String get copyToClipboard => 'Copy to clipboard';

  @override
  String get learningTitle => 'Learning';

  @override
  String get learningJlpt => 'JLPT mode';

  @override
  String get learningCustom => 'Custom mode';

  @override
  String get learningReview => 'Review';

  @override
  String get learningSelect => 'Select';

  @override
  String get learningStatistics => 'Statistics';

  @override
  String get helpTitle => 'Help';

  @override
  String get helpIntro =>
      'kanjitomo helps you learn to read and write Japanese kanji: draw a character to look it up, then track your progress in Learning.';

  @override
  String get helpLearningTitle => 'Learning';

  @override
  String get helpLearningDescription =>
      'Pick JLPT or Custom, then Review, Edit, or check Statistics. A kanji turns green once both its reading (kanji recognition) and writing (draw from meaning) have been passed at least once. Composita/sentence testing (reading and drawing kanji within real words) is tracked separately and doesn\'t affect that green status.';

  @override
  String get helpReviewTitle => 'Review';

  @override
  String get helpReviewDescription =>
      'New kanji are introduced in RTK (Remembering the Kanji) order, starting with numbers and basic radicals, then building progressively on shared components. You can set how many new kanji to introduce per day on the review start screen.';

  @override
  String get helpOpenSourceLicenses => 'Open source licenses';

  @override
  String get jlptEditTitle => 'Edit JLPT scope';

  @override
  String get jlptEditLevels => 'JLPT level(s)';

  @override
  String jlptEditKanjiInScope(int count) {
    return '$count kanji in scope';
  }

  @override
  String get jlptEditCompositaCeiling => 'Composita/sentence ceiling';

  @override
  String get jlptEditCompositaCeilingDescription =>
      'The hardest level a composita word is allowed to be, independent of the kanji level(s) selected above. Leave off to skip composita/sentence testing entirely for this scope.';

  @override
  String get jlptEditCeilingOff => 'Off';

  @override
  String get customEditTitle => 'Edit custom set';

  @override
  String get customEditClear => 'Clear';

  @override
  String get customEditDrawInstruction => 'Draw a kanji to add it to your set:';

  @override
  String get customEditSetEmpty => 'Your custom set is empty.';

  @override
  String get customEditSetInstruction =>
      'Your custom set (tap to edit, hold to remove):';

  @override
  String customEditIsKana(String char) {
    return '$char is kana, not a kanji';
  }

  @override
  String customEditAlreadyInSet(String char) {
    return '$char is already in your set';
  }

  @override
  String customEditAdded(String char) {
    return 'Added $char to your set';
  }

  @override
  String customEditRemoveDialogTitle(String char) {
    return 'Remove $char?';
  }

  @override
  String customEditRemoveDialogContent(String char) {
    return 'Remove $char from your custom set?';
  }

  @override
  String get dialogRemove => 'Remove';

  @override
  String get customEditClearDialogTitle => 'Clear custom set?';

  @override
  String customEditClearDialogContent(int count) {
    return 'This removes all $count kanji from your custom set. This cannot be undone.';
  }

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get dialogClear => 'Clear';

  @override
  String compositaPickerTitle(String character) {
    return '$character: Composita for testing';
  }

  @override
  String get compositaPickerDescription =>
      'Only words checked here are used for composita/sentence testing — unlike JLPT mode, custom mode has no level ceiling, so nothing is tested until you pick words below.';

  @override
  String get compositaPickerEmpty => 'No composita found for this kanji.';

  @override
  String get customEditAddByKanji => 'By kanji';

  @override
  String get customEditAddByWord => 'By word';

  @override
  String get compositaPickerSearchHint => 'Search JMdict for a word...';

  @override
  String get compositaPickerAdd => 'Add';

  @override
  String compositaPickerAdded(String word) {
    return 'Added $word';
  }

  @override
  String get compositaPickerNoResults => 'No matching word found.';

  @override
  String compositaPickerWordNotForChar(String char) {
    return 'This word doesn\'t contain $char';
  }

  @override
  String get wordLookupAddToReview => 'Add to review';

  @override
  String wordLookupAddedToReview(String word) {
    return 'Added $word for review';
  }

  @override
  String wordLookupPickKanjiTitle(String word) {
    return 'Add $word for which kanji?';
  }

  @override
  String get wordLookupPickKanjiConfirm => 'Add';

  @override
  String get kanjiBrowserTitle => 'Kanji browser';

  @override
  String get kanjiBrowserSearchLabel =>
      'Search by reading, meaning, or stroke count';

  @override
  String get kanjiBrowserNoMatch => 'No matching kanji.';

  @override
  String get kanjiBrowserColumnKanji => 'Kanji';

  @override
  String get kanjiBrowserColumnMeaning => 'Meaning';

  @override
  String get kanjiBrowserColumnKeyword => 'Keyword';

  @override
  String get kanjiBrowserColumnReadings => 'Readings';

  @override
  String get kanjiBrowserColumnStrokes => 'Strokes';

  @override
  String get kanjiDetailNoDictionaryEntry =>
      'No dictionary entry (kana aren\'t covered by the kanji dictionary this app bundles).';

  @override
  String get kanjiDetailOnyomi => 'On\'yomi';

  @override
  String get kanjiDetailKunyomi => 'Kun\'yomi';

  @override
  String get kanjiDetailMeaning => 'Meaning';

  @override
  String get kanjiDetailStrokeOrder => 'Stroke order';

  @override
  String get kanjiDetailKeyword => 'Keyword';

  @override
  String get kanjiDetailKeywordHint =>
      'A short recall cue (shown before you draw)...';

  @override
  String get kanjiDetailStory => 'Story';

  @override
  String get kanjiDetailStoryHint =>
      'Write your own mnemonic or story for this kanji...';

  @override
  String get kanjiDetailComposita => 'Composita';

  @override
  String get kanjiDetailExampleSentences => 'Example sentences';

  @override
  String kanjiDetailCopied(String character) {
    return 'Copied \"$character\" to clipboard';
  }

  @override
  String get reviewTitle => 'Review';

  @override
  String reviewHeader(int current, int total) {
    return 'Review ($current/$total)';
  }

  @override
  String reviewHeaderNew(int current, int total) {
    return 'Review ($current/$total) — New';
  }

  @override
  String get reviewNoCardsDue => 'No cards due right now.';

  @override
  String reviewLearnMore(int count) {
    return 'Learn $count more';
  }

  @override
  String reviewMoreAvailable(int count) {
    return '$count more available';
  }

  @override
  String get reviewLearnMoreButton => 'Learn more';

  @override
  String get reviewReturnButton => 'Return';

  @override
  String get reviewCorrect => 'Correct!';

  @override
  String reviewAnswer(String character) {
    return 'Answer: $character';
  }

  @override
  String reviewYouPicked(String character) {
    return 'You picked: $character';
  }

  @override
  String get reviewContinue => 'Continue';

  @override
  String reviewOnyomi(String readings) {
    return 'On\'yomi: $readings';
  }

  @override
  String reviewKunyomi(String readings) {
    return 'Kun\'yomi: $readings';
  }

  @override
  String reviewMeaning(String meanings) {
    return 'Meaning: $meanings';
  }

  @override
  String reviewKeyword(String keyword) {
    return 'Keyword: $keyword';
  }

  @override
  String get reviewDrawFromMeaningPrompt => 'Draw this kanji from memory:';

  @override
  String get reviewDontKnow => 'Don\'t know';

  @override
  String get reviewKanjiRecognitionPrompt =>
      'What is the reading and meaning of this kanji?';

  @override
  String get reviewReveal => 'Reveal';

  @override
  String get reviewAgain => 'Again';

  @override
  String get reviewGood => 'Good';

  @override
  String get reviewShowTranslation => 'Show translation';

  @override
  String get reviewHideTranslation => 'Hide translation';

  @override
  String get reviewReadingClozePrompt =>
      'What is the reading of the highlighted word?';

  @override
  String reviewSlideshowTitle(int current, int total) {
    return 'New kanji ($current/$total)';
  }

  @override
  String get reviewSlideshowStartReview => 'Start review';

  @override
  String get reviewSlideshowNext => 'Next';

  @override
  String get reviewStartTitle => 'Review';

  @override
  String get reviewStartCurrentSelection => 'Current selection';

  @override
  String reviewStartKanjiInScope(int count) {
    return '$count kanji in scope';
  }

  @override
  String get reviewStartCountingDue => 'Counting due cards…';

  @override
  String reviewStartDueNow(int count) {
    return '$count due now';
  }

  @override
  String reviewStartSeen(int seen, int unseen) {
    return '$seen seen, $unseen new';
  }

  @override
  String get reviewStartCustomSetEmpty => 'Custom set (empty)';

  @override
  String get reviewStartCustomSet => 'Custom set';

  @override
  String reviewStartRtk(int index) {
    return 'RTK up to $index';
  }

  @override
  String get reviewStartNothingSelected => 'Nothing selected';

  @override
  String get reviewStartWhatToQuiz => 'What to quiz';

  @override
  String get reviewStartKanjiOnly => 'Kanji only';

  @override
  String get reviewStartComposita => 'Composita';

  @override
  String get reviewStartBoth => 'Both';

  @override
  String get reviewStartCompositaOff =>
      'No composita/sentence testing is enabled for this scope yet — set a composita ceiling while editing it in the Learning section.';

  @override
  String get reviewStartNewKanjiPerDay => 'New kanji per day:';

  @override
  String get reviewStartButton => 'Start Review';

  @override
  String get reviewContinueButton => 'Continue Review';

  @override
  String reviewStartLearnNew(int count) {
    return 'Learn $count new kanji';
  }

  @override
  String get reviewLeaveDialogTitle => 'Leave review?';

  @override
  String get reviewLeaveDialogContent =>
      'Your daily review is not complete yet. Leave anyway?';

  @override
  String get reviewLeaveConfirm => 'Leave';

  @override
  String get statisticsTitle => 'Statistics';

  @override
  String get statisticsKanjiRecognition => 'Kanji recognition';

  @override
  String get statisticsDrawFromMeaning => 'Draw from meaning';

  @override
  String get statisticsReadingCloze => 'Reading (composita/sentence)';

  @override
  String get statisticsDrawInSentence =>
      'Draw in sentence (composita/sentence)';

  @override
  String get statisticsKnown => 'Known';

  @override
  String get statisticsMissed => 'Missed';

  @override
  String get statisticsNotStarted => 'Not started';

  @override
  String get statisticsCompositaTitle => 'Composita/sentence testing';

  @override
  String statisticsTestableWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'words',
      one: 'word',
    );
    return '$count testable $_temp0 in this scope — never gates green, tracked separately.';
  }

  @override
  String get statisticsReadingTested => 'Reading tested';

  @override
  String get statisticsWritingTested => 'Writing tested';

  @override
  String get statisticsInspectAllKanji => 'Inspect all kanji';

  @override
  String get statisticsResetButton => 'Reset statistics';

  @override
  String get statisticsResetDialogTitle => 'Reset statistics?';

  @override
  String get statisticsResetDialogContent =>
      'This clears all review progress (due dates, known/unknown status, and new-card introductions) for every kanji. You will start from scratch. This cannot be undone.';

  @override
  String get statisticsResetConfirm => 'Reset';

  @override
  String get drawAndPickClearDrawing => 'Clear drawing';

  @override
  String get drawAndPickRecognizing => 'Recognizing...';

  @override
  String get drawAndPickWhichOne => 'Which one did you draw?';

  @override
  String legendValuePercent(String label, int value, int percent) {
    return '$label: $value ($percent%)';
  }

  @override
  String compositaPieLabel(String label, int tested, int testable) {
    return '$label: $tested/$testable';
  }

  @override
  String get proPaywallTitle => 'Unlock Pro';

  @override
  String get proPaywallDescription =>
      'Get access to all JLPT levels, custom study sets, composita testing, and statistics.';

  @override
  String get proPaywallFeatureJlpt => 'All JLPT levels (N1–N3)';

  @override
  String get proPaywallFeatureCustom => 'Unlimited custom kanji sets';

  @override
  String get proPaywallFeatureComposita => 'Composita & sentence testing';

  @override
  String get proPaywallFeatureStats => 'Detailed statistics';

  @override
  String proPaywallBuyButton(String price) {
    return 'Unlock Pro — $price';
  }

  @override
  String get proPaywallRestore => 'Restore Purchases';

  @override
  String get proPaywallRestoring => 'Restoring...';

  @override
  String get proPaywallError => 'Purchase failed. Please try again.';

  @override
  String get proPaywallRestoreSuccess => 'Purchases restored!';

  @override
  String get proPaywallRestoreNothing => 'No previous purchase found.';

  @override
  String get proLevelLocked => 'Pro required for N1–N3';

  @override
  String get helpRestorePurchases => 'Restore Purchases';

  @override
  String customEditKanjiCount(int count, int limit) {
    return '$count/$limit kanji';
  }

  @override
  String customEditKanjiCountPro(int count) {
    return '$count kanji';
  }

  @override
  String customEditLimitReached(int limit) {
    return 'Free tier limited to $limit kanji';
  }
}
