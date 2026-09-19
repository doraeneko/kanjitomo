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
  String get lookupTitle => '漢字友';

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
  String get learningSettings => 'Settings';

  @override
  String get learningStatistics => 'Statistics';

  @override
  String get helpTitle => 'Help & About';

  @override
  String get helpTagline => 'A kanji learning tool for serious learners';

  @override
  String get helpFeaturesSection => 'What\'s inside';

  @override
  String get helpFeatureRecognitionTitle => 'Handwriting Recognition';

  @override
  String get helpFeatureRecognitionDesc =>
      'Draw any kanji for instant offline recognition — neural network, 6,500+ characters.';

  @override
  String get helpFeatureSrsTitle => 'Spaced Repetition (SRS)';

  @override
  String get helpFeatureSrsDesc =>
      'Draw kanji from memory, not just recognize them. Four card types build real recall through active writing.';

  @override
  String get helpFeatureCompositaTitle => 'Composita & Sentences';

  @override
  String get helpFeatureCompositaDesc =>
      'You choose which compound words to study. Learn kanji in context with 6,000+ example sentences.';

  @override
  String get helpFeatureStrokeOrderTitle => 'Stroke Order';

  @override
  String get helpFeatureStrokeOrderDesc =>
      'Animated stroke-by-stroke diagrams with a practice canvas for every kanji.';

  @override
  String get helpFeatureDictionaryTitle => 'Dictionary';

  @override
  String get helpFeatureDictionaryDesc =>
      '60,000+ words from JMdict. Draw to look up single kanji or build words character by character.';

  @override
  String get helpFeatureStoriesTitle => 'Keywords & Stories';

  @override
  String get helpFeatureStoriesDesc =>
      'Add your own mnemonics and keywords to each kanji to make them stick.';

  @override
  String get helpSettingsSection => 'Settings';

  @override
  String get helpAcknowledgement =>
      'Kanjitomo would not be possible without these wonderful open-source projects and data sets:';

  @override
  String get helpOpenSourceLicenses => 'All licenses';

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
    return '$character: Composita';
  }

  @override
  String get compositaPickerDescription =>
      'Only words checked here are used for composita/sentence testing — unlike JLPT mode, custom mode has no level ceiling, so nothing is tested until you pick words below.';

  @override
  String get compositaPickerEmpty => 'No composita found for this kanji.';

  @override
  String get customEditAddByKanji => 'Add kanji';

  @override
  String get customEditAddByWord => 'Add composita';

  @override
  String get compositaPickerSearchHint => 'Search JMdict for a word...';

  @override
  String get compositaPickerDrawButton => 'Additional composita';

  @override
  String compositaPickerDrawTitle(String char) {
    return 'Draw composita for $char';
  }

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
  String get wordLookupAlreadyInReview => 'Already in review';

  @override
  String get wordLookupClearWord => 'Clear word';

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
  String reviewHeader(int done, int total) {
    return 'Review — $done/$total';
  }

  @override
  String reviewHeaderNew(int done, int total) {
    return 'Review — $done/$total — New';
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
  String get reviewShowDetails => 'Show details';

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
    return '$count facts due now';
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
  String get reviewStartNewKanjiPerDay => 'New kanji per day:';

  @override
  String get reviewStartButton => 'Review';

  @override
  String reviewStartPoolHeading(int count) {
    return 'Learning pool ($count)';
  }

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
  String get statisticsKnown => 'Passed';

  @override
  String get statisticsMissed => 'Learning';

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
  String statisticsLearnt(int count, int total) {
    return '$count / $total learnt';
  }

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
  String get undoStroke => 'Undo stroke';

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

  @override
  String get customEditAddElements => 'Add elements';

  @override
  String get dueOverviewTitle => 'Upcoming reviews';

  @override
  String get dueOverviewOverdue => 'Overdue';

  @override
  String get dueOverviewToday => 'Today';

  @override
  String get dueOverviewTomorrow => 'Tomorrow';

  @override
  String get dueOverviewThisWeek => 'This week';

  @override
  String get dueOverviewLater => 'Later';

  @override
  String get dueOverviewNotStarted => 'Not started';

  @override
  String dueOverviewCompact(int tomorrow, int week, int later) {
    return 'Tomorrow: $tomorrow · This week: $week · Later: $later';
  }

  @override
  String get learningQuiz => 'JLPT-like Quiz';

  @override
  String get quizStartTitle => 'Quiz';

  @override
  String get quizStartQuestionCount => 'Number of questions:';

  @override
  String get quizStartButton => 'Start Quiz';

  @override
  String quizProgress(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get quizPickReading => 'What is the reading of the highlighted word?';

  @override
  String get quizPickKanji => 'Which word fits in the sentence?';

  @override
  String get quizCorrect => 'Correct!';

  @override
  String get quizWrong => 'Wrong — the answer is:';

  @override
  String get quizNext => 'Next';

  @override
  String get quizResultTitle => 'Quiz Results';

  @override
  String quizResultScore(int correct, int total) {
    return '$correct/$total correct';
  }

  @override
  String get quizDone => 'Done';

  @override
  String get quizNotEnoughWords => 'Not enough words in scope for a quiz.';

  @override
  String reviewStartBacklogInfo(int count) {
    return 'You have $count cards to review from previous days.';
  }

  @override
  String get reviewStartReviewBacklog => 'Review backlog first';

  @override
  String reviewStartBacklogAndNew(int count) {
    return 'Also learn $count new kanji';
  }

  @override
  String reviewStartNewKanjiDialog(int dueCount, int newCount, int totalCount) {
    return 'You have $dueCount cards due for review. Want to add $newCount new kanji? That results in $totalCount facts to review.';
  }

  @override
  String get reviewStartDialogYes => 'Yes';

  @override
  String get reviewStartDialogNo => 'No';

  @override
  String reviewLearnMoreEstimate(int factCount) {
    return 'That adds $factCount new facts';
  }

  @override
  String get reviewUndoTooltip => 'Redo previous card';

  @override
  String get jlptEditCompositaPerKanji => 'Composita words per kanji';

  @override
  String get quizOnlySeenKanji => 'Only quiz seen kanji';

  @override
  String get reviewMaxBacklog => 'Maximum backlog:';

  @override
  String get reviewMaxBacklogHint => '0 = no limit';

  @override
  String get ftdLookupTitle => 'Draw to recognize';

  @override
  String get ftdLookupMessage =>
      'Draw any kanji on the canvas — the neural network recognizes it instantly, even with messy handwriting. Supports 6,500+ characters, entirely offline.\n\nTap a result to see readings, meaning, stroke order, example sentences, and compound words.\n\nTry it now — minimize this card and draw something!';

  @override
  String get ftdWordLookupTitle => 'Word lookup';

  @override
  String get ftdWordLookupMessage =>
      'Look up compound words in a 60,000+ entry dictionary (JMdict). Draw each character to build the word, or type directly.\n\nMinimize this card to try it out!';

  @override
  String get ftdLearningTitle => 'Learning';

  @override
  String get ftdLearningMessage =>
      'You decide what to study. Add kanji by JLPT level or hand-pick individual characters. Spaced repetition tests you four ways — including drawing from memory, which builds the active recall that passive apps can\'t match.\n\nTrack your progress with detailed statistics.';

  @override
  String get ftdBrowserTitle => 'Kanji browser';

  @override
  String get ftdBrowserMessage =>
      'Browse all Jōyō kanji in a searchable table. Filter by reading, meaning, or stroke count. Tap any kanji to see its detail — and choose which compound words (composita) you want in your reviews.\n\nColored dots show your review progress at a glance.';

  @override
  String get ftdReviewSessionTitle => 'Review session';

  @override
  String get ftdReviewSessionMessage =>
      'Four card types test different aspects of recall:\n• Draw from meaning — see the keyword, write the kanji from memory\n• Kanji recognition — see the kanji, recall its reading and meaning\n• Reading cloze — read a compound word in a real sentence\n• Draw in sentence — write a kanji in context\n\nDrawing from memory is harder than multiple choice — that\'s the point. Grade yourself with Again (missed) or Good (recalled).';

  @override
  String get ftdGotIt => 'Got it';

  @override
  String get helpResetTips => 'Reset help';

  @override
  String get helpResetTipsDone =>
      'Help reset — the welcome tour will appear again next time.';

  @override
  String get welcomeTitle => 'Welcome to Kanjitomo';

  @override
  String get welcomeSubtitle => 'A kanji learning tool for serious learners';

  @override
  String get welcomeTakeTour => 'Take a tour';

  @override
  String get welcomeSkip => 'Skip';

  @override
  String get welcomeDone => 'Start learning!';

  @override
  String get tourNext => 'Next';

  @override
  String get tourBack => 'Back';

  @override
  String get welcomeDontShowAgain => 'Don\'t show again';

  @override
  String get welcomeFeatureList =>
      'Draw kanji from memory to build real recall — not just recognition. You choose what to study: pick your kanji, your compound words, your pace. Offline, no account, no tracking.';

  @override
  String get helpReviewStart =>
      'Review uses spaced repetition (SM-2) to schedule cards at increasing intervals.\n\nFour card types test you:\n• Draw from meaning — see the meaning, draw the kanji\n• Kanji recognition — see the kanji, recall its reading\n• Reading cloze — read a word in a sentence\n• Draw in sentence — draw a kanji in context\n\nNew cards per day and max reviews per day are set on the learning hub. Reviews always take priority; new cards fill whatever daily budget remains. Use \"Learn more\" inside a session to add extra cards beyond the daily limit.\n\nGrade yourself: Again (forgot) or Good (recalled). Cards reappear after at least 1 day, with intervals growing as you succeed.\n\nYou can add a personal keyword and story (mnemonic) for each kanji. Tap any kanji in the browser or during review to edit them. Your keyword is shown during draw-from-meaning cards; your story appears when you reveal the answer. These help you build memorable associations between a kanji\'s shape, meaning, and components.';

  @override
  String get helpJlptEdit =>
      'Select one or more JLPT levels. All kanji from the selected levels are combined into your study scope.\n\nComposita ceiling controls which vocabulary words are tested:\n• Off — no word/sentence testing, only bare kanji\n• N5–N1 — only test words at or easier than this level\nThe ceiling is independent of kanji levels (e.g. study N3 kanji with N5 words only).\n\nNew kanji/day: how many new characters to introduce each day (default 10).\n\nMax backlog: optional limit on how many due cards can pile up before new kanji stop being introduced. Set to 0 to disable the limit.\n\nComposita/kanji: how many words per character are tested (2–5, default 4).\n\nChanging levels takes effect immediately. Review progress is shared between JLPT and Custom mode — a kanji reviewed in one mode counts as reviewed in the other.';

  @override
  String get helpCustomEdit =>
      'Build your own study list by drawing kanji one at a time.\n\nTap a kanji to choose which vocabulary words (composita) to test for it. Unlike JLPT mode, nothing is auto-included — you explicitly pick each word.\n\nLong-press a kanji to remove it from your list.\n\nReview progress is shared between JLPT and Custom mode — a kanji reviewed in one mode counts as reviewed in the other.';

  @override
  String get helpQuiz =>
      'The quiz is a quick multiple-choice self-test. It has no effect on your spaced-repetition progress.\n\nTwo question types are randomly mixed:\n• Kanji → Reading: a sentence with a kanji highlighted; pick its reading\n• Reading → Kanji: a sentence with readings shown; pick which kanji word fits\n\nOnly kanji you have already reviewed at least once are included.';

  @override
  String get helpStatistics =>
      'Statistics show your progress for the current study scope.\n\nDue overview: how many cards are overdue, due today, tomorrow, this week, or later.\n\nPer card type (draw, recognition, reading cloze, draw in sentence):\n• Learnt (green): answered correctly 2 times in a row\n• Learning (orange): reviewed but not yet at 2 consecutive correct answers\n• Not started (gray): never reviewed\n\nA wrong answer resets the count back to zero — you need 2 consecutive correct answers again.\n\nKanji grid: each kanji shows colored dots.\n• First dot — core progress: green (both reading and writing learnt), orange (at least one direction started), gray (not yet reviewed)\n• Second dot — composita progress (only shown when the character has testable composita words): green (all words tested in both directions), orange (at least one tested), gray (none tested)\n\nComposita coverage shows how many eligible words have been tested at least once for reading and writing.\n\nUse the reset button at the bottom to erase all review progress and start over.';

  @override
  String get helpLearning =>
      'This is your learning hub for managing kanji study.\n\nReview: Start a spaced-repetition session with your due cards.\n\nQuiz: A multiple-choice self-test (no effect on review progress).\n\nAdd/Remove: Add kanji by JLPT level, RTK order, or drawing. Manage your learning pool, composita settings, and individual kanji.\n\nStatistics: View your progress per card type, composita coverage, and a kanji grid with color-coded dots.\n\n── Settings ──\n\nNew cards/day: How many never-before-seen cards are introduced per day. These are kanji you added but haven\'t reviewed yet.\n\nMax reviews/day: The total daily budget for all cards — both reviews of previously seen cards and new cards combined. Reviews always take priority; new cards fill whatever capacity remains.\n\nExample: With New=30 and Max=200, if you have 120 due reviews and have already done 50 today:\n• Daily budget remaining: 200 − 50 = 150\n• Due reviews: 120 (all fit within 150)\n• Remaining for new cards: 150 − 120 = 30\n• Total session: 150 cards\n\nIf due reviews alone exceed the max (e.g. 250 due, max 200), only 200 reviews are shown and no new cards — catching up on reviews comes first.\n\nSet either value to 0 for unlimited.';

  @override
  String get helpSupportDevelopment => 'Support development';

  @override
  String get helpSupportDescription =>
      'Kanjitomo is free and always will be. If you find it useful, consider buying me a coffee!';

  @override
  String get helpReportBug => 'Report a bug';

  @override
  String get helpReportBugDescription =>
      'Found a problem? Send us an email and we\'ll look into it.';

  @override
  String get helpBugEmailSubject => 'Kanjitomo bug report';

  @override
  String get helpPrivacyPolicy => 'Privacy policy';

  @override
  String get learningPoolStats => 'Your learning pool';

  @override
  String learningKanjiCount(int count) {
    return '$count kanji in pool';
  }

  @override
  String learningSeen(int seen) {
    return '$seen seen';
  }

  @override
  String learningDue(int due) {
    return '$due cards due';
  }

  @override
  String get learningAddRemove => 'Add/Remove';

  @override
  String learningQuickAddJlpt(int count, int level) {
    return '+$count JLPT N$level';
  }

  @override
  String learningQuickAddRtk(int count) {
    return '+$count RTK';
  }

  @override
  String get learningQuickAddHint => 'Shortcut — adds kanji in RTK order.';

  @override
  String get learningDetailedAdd => 'Add / Remove (detailed)';

  @override
  String get addRemoveBrowseTab => 'Browse';

  @override
  String get addRemoveBrowseHelp =>
      'Tap + to add a kanji to your learning pool. Kanji already in your pool show a checkmark.';

  @override
  String get addRemoveTitle => 'Add / Remove kanji';

  @override
  String get addRemoveAddByJlpt => 'Add by JLPT level';

  @override
  String get addRemoveJlptHelp =>
      'Add kanji grouped by JLPT level (N5 = easiest, N1 = hardest). Pick a level and how many to add — they\'ll be added in Heisig (RTK) order for efficient memorization. Compound words are auto-selected based on your settings below.';

  @override
  String get addRemoveKanjiCount => 'Number of kanji';

  @override
  String get addRemoveAddTip =>
      'Tip: Add just a few new kanji each day for the best retention.';

  @override
  String get addRemoveAddJlptButton => 'Add JLPT kanji';

  @override
  String get addRemoveAddByRtk => 'Add by RTK order';

  @override
  String get addRemoveRtkHelp =>
      'Add kanji in Heisig\'s Remembering the Kanji (RTK) order, regardless of JLPT level. Good if you\'re following the RTK book or want to learn kanji by building on shared components.';

  @override
  String get addRemoveAddRtkButton => 'Add RTK kanji';

  @override
  String get addRemoveDrawToAdd => 'Add by drawing';

  @override
  String get addRemoveDrawHelp =>
      'Draw any kanji to add it to your learning pool. Useful for adding a specific character you encountered. Compound words are auto-selected based on your settings below.';

  @override
  String get addRemoveCompositaSettings => 'Composita settings';

  @override
  String get addRemoveCompositaCeiling => 'Vocabulary level limit';

  @override
  String get addRemoveCompositaCeilingHelp =>
      'Limits which compound words are auto-selected when adding kanji. A word\'s level is determined by its hardest kanji (e.g. 胃腸 is N1 because 腸 is N1, even though 胃 is N3). Set to N2 and 胃腸 won\'t be auto-selected, but 胃袋 (N2) will. You can always manually add any word via the composita picker. \"Off\" allows all levels.';

  @override
  String get addRemoveCeilingOff => 'Off';

  @override
  String get addRemoveMaxComposita => 'Words per kanji';

  @override
  String get addRemoveMaxCompositaHelp =>
      'How many compound words to auto-select per kanji for review. More words means more variety but also more cards to review.';

  @override
  String get addRemovePoolSortRtk => 'RTK order';

  @override
  String get addRemovePoolSortAdded => 'Date added';

  @override
  String get addRemovePoolSortModified => 'Last modified';

  @override
  String get addRemovePoolSortMastery => 'Mastery';

  @override
  String addRemovePoolTitle(int count) {
    return 'Learning pool ($count)';
  }

  @override
  String get addRemovePoolEmpty => 'No kanji in your learning pool yet.';

  @override
  String get addRemovePoolTip =>
      'Tap a kanji to edit its composita, story, or keyword. Long-press to remove.';

  @override
  String get addRemovePoolSearch => 'Search pool';

  @override
  String get addRemoveClearAll => 'Clear all';

  @override
  String get addRemoveConfirmClearTitle => 'Clear learning pool?';

  @override
  String addRemoveConfirmClearContent(int count) {
    return 'Remove all $count kanji and delete all review progress? This cannot be undone.';
  }

  @override
  String get addRemoveClearSecondConfirm =>
      'All review progress will be permanently lost. Your keywords and stories are kept.';

  @override
  String get addRemoveConfirmRemoveTitle => 'Remove kanji?';

  @override
  String addRemoveConfirmRemoveContent(String char) {
    return 'Remove $char and delete all review progress for it? This cannot be undone.';
  }

  @override
  String get addRemoveRemoveButton => 'Remove';

  @override
  String addRemoveAlreadyInPool(String char) {
    return '$char is already in your learning pool.';
  }

  @override
  String addRemoveSlideshowTitle(int current, int total) {
    return 'New kanji ($current/$total)';
  }

  @override
  String get addRemoveSlideshowComposita => 'Selected composita:';

  @override
  String get addRemoveSlideshowNext => 'Next';

  @override
  String get addRemoveSlideshowDone => 'Done';

  @override
  String get kanjiDetailEditComposita => 'Edit composita';

  @override
  String get kanjiDetailAddToLearning => 'Add to learning';

  @override
  String get learningNewCardsPerDay => 'New cards/day:';

  @override
  String get learningMaxReviewsPerDay => 'Max reviews/day:';

  @override
  String learningWaitingCards(int count) {
    return '$count waiting';
  }

  @override
  String reviewDailyLimitReached(int count) {
    return 'Daily limit reached. $count more cards available.';
  }

  @override
  String reviewContinueCards(int count) {
    return 'Continue with $count more';
  }

  @override
  String get progressDetailRecognition => 'Recognition';

  @override
  String get progressDetailDrawing => 'Drawing';

  @override
  String progressDetailStatus(int reps, int threshold) {
    return '$reps/$threshold';
  }

  @override
  String get progressDetailNotStarted => 'Not started';

  @override
  String get progressDetailViewFull => 'View detail';

  @override
  String get progressDetailComposita => 'Composita';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeIndigo => 'Indigo';

  @override
  String get themeTeal => 'Teal';

  @override
  String get themeSakura => 'Sakura';

  @override
  String get themeForest => 'Forest';

  @override
  String get themeAmber => 'Amber';

  @override
  String get settingsBrightness => 'Brightness';

  @override
  String get themeAuto => 'Auto';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get settingsRecognitionModel => 'Recognition model';

  @override
  String get modelStandard => 'Standard (~3,000 kanji)';

  @override
  String get modelExtended => 'Extended (~6,500 kanji)';

  @override
  String get modelSwitching => 'Switching model...';

  @override
  String get modelSwitched => 'Recognition model switched';

  @override
  String modelSwitchFailed(String error) {
    return 'Failed to switch model: $error';
  }
}
