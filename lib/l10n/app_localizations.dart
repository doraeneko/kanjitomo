import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
    Locale('vi'),
  ];

  /// App title shown in MaterialApp and Help screen
  ///
  /// In en, this message translates to:
  /// **'kanjitomo'**
  String get appTitle;

  /// Error message on startup
  ///
  /// In en, this message translates to:
  /// **'Failed to load app data: {error}'**
  String failedToLoadAppData(String error);

  /// AppBar title on lookup screen
  ///
  /// In en, this message translates to:
  /// **'漢字とも'**
  String get lookupTitle;

  /// Tab label for word lookup
  ///
  /// In en, this message translates to:
  /// **'Words'**
  String get lookupWords;

  /// AppBar button label for learning
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get lookupLearn;

  /// AppBar button label for kanji browser
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get lookupBrowse;

  /// AppBar button label for help
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get lookupHelp;

  /// Tab label for kanji lookup
  ///
  /// In en, this message translates to:
  /// **'Kanji'**
  String get lookupHeading;

  /// Button to clear the drawing canvas
  ///
  /// In en, this message translates to:
  /// **'Clear drawing'**
  String get lookupClearDrawing;

  /// Shown while recognizer is running
  ///
  /// In en, this message translates to:
  /// **'Recognizing...'**
  String get lookupRecognizing;

  /// Shown while ONNX model is loading
  ///
  /// In en, this message translates to:
  /// **'Loading model...'**
  String get lookupLoadingModel;

  /// Error when model fails to load
  ///
  /// In en, this message translates to:
  /// **'Model failed to load: {error}'**
  String lookupModelFailed(String error);

  /// Label when only one confident match
  ///
  /// In en, this message translates to:
  /// **'Best match:'**
  String get lookupBestMatch;

  /// Label showing number of top candidates
  ///
  /// In en, this message translates to:
  /// **'Top {count}:'**
  String lookupTopN(int count);

  /// Button label when kanji already added to custom set
  ///
  /// In en, this message translates to:
  /// **'In custom review'**
  String get lookupInCustomReview;

  /// Button label to add kanji to custom set
  ///
  /// In en, this message translates to:
  /// **'Add to custom review'**
  String get lookupAddToCustomReview;

  /// AppBar title for word lookup screen
  ///
  /// In en, this message translates to:
  /// **'Word lookup'**
  String get wordLookupTitle;

  /// Instruction text on word lookup screen
  ///
  /// In en, this message translates to:
  /// **'Draw a kanji or kana character to add it to the word:'**
  String get wordLookupDrawInstruction;

  /// Label for the word text field
  ///
  /// In en, this message translates to:
  /// **'Word'**
  String get wordLookupWordLabel;

  /// Clear button on word lookup
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get wordLookupClear;

  /// Shown when no dictionary entry found
  ///
  /// In en, this message translates to:
  /// **'No JMdict entry for this exact word.'**
  String get wordLookupNoEntry;

  /// Snackbar when word copied to clipboard
  ///
  /// In en, this message translates to:
  /// **'Copied \"{word}\" to clipboard'**
  String wordLookupCopied(String word);

  /// Tooltip for copy button
  ///
  /// In en, this message translates to:
  /// **'Copy to clipboard'**
  String get copyToClipboard;

  /// AppBar title for learning screen
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get learningTitle;

  /// Section title for JLPT mode
  ///
  /// In en, this message translates to:
  /// **'JLPT mode'**
  String get learningJlpt;

  /// Section title for custom mode
  ///
  /// In en, this message translates to:
  /// **'Custom mode'**
  String get learningCustom;

  /// Button label for review
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get learningReview;

  /// Button label for edit/select
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get learningSelect;

  /// Button label for statistics
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get learningStatistics;

  /// AppBar title for help screen
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get helpTitle;

  /// Introduction paragraph on help screen
  ///
  /// In en, this message translates to:
  /// **'kanjitomo helps you learn to read and write Japanese kanji: draw a character to look it up, then track your progress in Learning.'**
  String get helpIntro;

  /// Section title on help screen
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get helpLearningTitle;

  /// Learning section description on help screen
  ///
  /// In en, this message translates to:
  /// **'Pick JLPT or Custom, then Review, Edit, or check Statistics. A kanji turns green once both its reading (kanji recognition) and writing (draw from meaning) have been passed at least once. Composita/sentence testing (reading and drawing kanji within real words) is tracked separately and doesn\'t affect that green status.'**
  String get helpLearningDescription;

  /// Section title on help screen
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get helpReviewTitle;

  /// Review section description on help screen
  ///
  /// In en, this message translates to:
  /// **'New kanji are introduced in RTK (Remembering the Kanji) order, starting with numbers and basic radicals, then building progressively on shared components. You can set how many new kanji to introduce per day on the review start screen.'**
  String get helpReviewDescription;

  /// Button to open licenses page
  ///
  /// In en, this message translates to:
  /// **'Open source licenses'**
  String get helpOpenSourceLicenses;

  /// AppBar title for JLPT edit screen
  ///
  /// In en, this message translates to:
  /// **'Edit JLPT scope'**
  String get jlptEditTitle;

  /// Section title for level selection
  ///
  /// In en, this message translates to:
  /// **'JLPT level(s)'**
  String get jlptEditLevels;

  /// Count of kanji matching current scope
  ///
  /// In en, this message translates to:
  /// **'{count} kanji in scope'**
  String jlptEditKanjiInScope(int count);

  /// Section title for composita ceiling
  ///
  /// In en, this message translates to:
  /// **'Composita/sentence ceiling'**
  String get jlptEditCompositaCeiling;

  /// Explanation of composita ceiling
  ///
  /// In en, this message translates to:
  /// **'The hardest level a composita word is allowed to be, independent of the kanji level(s) selected above. Leave off to skip composita/sentence testing entirely for this scope.'**
  String get jlptEditCompositaCeilingDescription;

  /// Label for composita ceiling off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get jlptEditCeilingOff;

  /// AppBar title for custom edit screen
  ///
  /// In en, this message translates to:
  /// **'Edit custom set'**
  String get customEditTitle;

  /// Clear button in app bar
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get customEditClear;

  /// Instruction for drawing
  ///
  /// In en, this message translates to:
  /// **'Draw a kanji to add it to your set:'**
  String get customEditDrawInstruction;

  /// Shown when custom set has no kanji
  ///
  /// In en, this message translates to:
  /// **'Your custom set is empty.'**
  String get customEditSetEmpty;

  /// Shown above custom set grid
  ///
  /// In en, this message translates to:
  /// **'Your custom set (tap to edit, hold to remove):'**
  String get customEditSetInstruction;

  /// Snackbar when user draws kana
  ///
  /// In en, this message translates to:
  /// **'{char} is kana, not a kanji'**
  String customEditIsKana(String char);

  /// Snackbar when kanji already in set
  ///
  /// In en, this message translates to:
  /// **'{char} is already in your set'**
  String customEditAlreadyInSet(String char);

  /// Snackbar confirming kanji added
  ///
  /// In en, this message translates to:
  /// **'Added {char} to your set'**
  String customEditAdded(String char);

  /// Dialog title for removing a single kanji from custom set
  ///
  /// In en, this message translates to:
  /// **'Remove {char}?'**
  String customEditRemoveDialogTitle(String char);

  /// Dialog content for removing a single kanji
  ///
  /// In en, this message translates to:
  /// **'Remove {char} from your custom set?'**
  String customEditRemoveDialogContent(String char);

  /// Remove button in confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get dialogRemove;

  /// Dialog title for clearing custom set
  ///
  /// In en, this message translates to:
  /// **'Clear custom set?'**
  String get customEditClearDialogTitle;

  /// Dialog content for clearing custom set
  ///
  /// In en, this message translates to:
  /// **'This removes all {count} kanji from your custom set. This cannot be undone.'**
  String customEditClearDialogContent(int count);

  /// Cancel button in dialogs
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// Clear button in confirmation dialogs
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get dialogClear;

  /// Title of the composita picker
  ///
  /// In en, this message translates to:
  /// **'{character}: Composita for testing'**
  String compositaPickerTitle(String character);

  /// Explanation text in composita picker
  ///
  /// In en, this message translates to:
  /// **'Only words checked here are used for composita/sentence testing — unlike JLPT mode, custom mode has no level ceiling, so nothing is tested until you pick words below.'**
  String get compositaPickerDescription;

  /// Shown when kanji has no composita
  ///
  /// In en, this message translates to:
  /// **'No composita found for this kanji.'**
  String get compositaPickerEmpty;

  /// Segment label for adding single kanji to custom set
  ///
  /// In en, this message translates to:
  /// **'By kanji'**
  String get customEditAddByKanji;

  /// Segment label for adding words/composita to custom set
  ///
  /// In en, this message translates to:
  /// **'By word'**
  String get customEditAddByWord;

  /// Hint text for composita picker search field
  ///
  /// In en, this message translates to:
  /// **'Search JMdict for a word...'**
  String get compositaPickerSearchHint;

  /// Button to add a word from JMdict search
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get compositaPickerAdd;

  /// Shown when word was added via JMdict search
  ///
  /// In en, this message translates to:
  /// **'Added {word}'**
  String compositaPickerAdded(String word);

  /// Shown when JMdict search has no results
  ///
  /// In en, this message translates to:
  /// **'No matching word found.'**
  String get compositaPickerNoResults;

  /// Shown when searched word doesn't contain the picker's kanji
  ///
  /// In en, this message translates to:
  /// **'This word doesn\'t contain {char}'**
  String compositaPickerWordNotForChar(String char);

  /// Button to add a word from word lookup to review
  ///
  /// In en, this message translates to:
  /// **'Add to review'**
  String get wordLookupAddToReview;

  /// Snackbar when word added to review from word lookup
  ///
  /// In en, this message translates to:
  /// **'Added {word} for review'**
  String wordLookupAddedToReview(String word);

  /// Dialog title asking which kanji to add a word for
  ///
  /// In en, this message translates to:
  /// **'Add {word} for which kanji?'**
  String wordLookupPickKanjiTitle(String word);

  /// Confirm button in kanji picker dialog
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get wordLookupPickKanjiConfirm;

  /// AppBar title for kanji browser
  ///
  /// In en, this message translates to:
  /// **'Kanji browser'**
  String get kanjiBrowserTitle;

  /// Search field label
  ///
  /// In en, this message translates to:
  /// **'Search by reading, meaning, or stroke count'**
  String get kanjiBrowserSearchLabel;

  /// Shown when search has no results
  ///
  /// In en, this message translates to:
  /// **'No matching kanji.'**
  String get kanjiBrowserNoMatch;

  /// Table header for kanji column
  ///
  /// In en, this message translates to:
  /// **'Kanji'**
  String get kanjiBrowserColumnKanji;

  /// Table header for meaning column
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get kanjiBrowserColumnMeaning;

  /// Table header for keyword column
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get kanjiBrowserColumnKeyword;

  /// Table header for readings column
  ///
  /// In en, this message translates to:
  /// **'Readings'**
  String get kanjiBrowserColumnReadings;

  /// Table header for strokes column
  ///
  /// In en, this message translates to:
  /// **'Strokes'**
  String get kanjiBrowserColumnStrokes;

  /// Shown for kana characters
  ///
  /// In en, this message translates to:
  /// **'No dictionary entry (kana aren\'t covered by the kanji dictionary this app bundles).'**
  String get kanjiDetailNoDictionaryEntry;

  /// Label for on'yomi readings
  ///
  /// In en, this message translates to:
  /// **'On\'yomi'**
  String get kanjiDetailOnyomi;

  /// Label for kun'yomi readings
  ///
  /// In en, this message translates to:
  /// **'Kun\'yomi'**
  String get kanjiDetailKunyomi;

  /// Label for kanji meaning
  ///
  /// In en, this message translates to:
  /// **'Meaning'**
  String get kanjiDetailMeaning;

  /// Section title for stroke order
  ///
  /// In en, this message translates to:
  /// **'Stroke order'**
  String get kanjiDetailStrokeOrder;

  /// Section title for keyword
  ///
  /// In en, this message translates to:
  /// **'Keyword'**
  String get kanjiDetailKeyword;

  /// Hint text for keyword field
  ///
  /// In en, this message translates to:
  /// **'A short recall cue (shown before you draw)...'**
  String get kanjiDetailKeywordHint;

  /// Section title for story
  ///
  /// In en, this message translates to:
  /// **'Story'**
  String get kanjiDetailStory;

  /// Hint text for story field
  ///
  /// In en, this message translates to:
  /// **'Write your own mnemonic or story for this kanji...'**
  String get kanjiDetailStoryHint;

  /// Section title for composita
  ///
  /// In en, this message translates to:
  /// **'Composita'**
  String get kanjiDetailComposita;

  /// Section title for example sentences
  ///
  /// In en, this message translates to:
  /// **'Example sentences'**
  String get kanjiDetailExampleSentences;

  /// Snackbar when character copied
  ///
  /// In en, this message translates to:
  /// **'Copied \"{character}\" to clipboard'**
  String kanjiDetailCopied(String character);

  /// AppBar title for review screens
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewTitle;

  /// AppBar title during review with progress
  ///
  /// In en, this message translates to:
  /// **'Review ({current}/{total})'**
  String reviewHeader(int current, int total);

  /// AppBar title during review for a new card
  ///
  /// In en, this message translates to:
  /// **'Review ({current}/{total}) — New'**
  String reviewHeaderNew(int current, int total);

  /// Shown when queue is exhausted
  ///
  /// In en, this message translates to:
  /// **'No cards due right now.'**
  String get reviewNoCardsDue;

  /// Button to introduce more cards
  ///
  /// In en, this message translates to:
  /// **'Learn {count} more'**
  String reviewLearnMore(int count);

  /// Shows how many more new kanji remain in scope
  ///
  /// In en, this message translates to:
  /// **'{count} more available'**
  String reviewMoreAvailable(int count);

  /// Button to introduce more new kanji
  ///
  /// In en, this message translates to:
  /// **'Learn more'**
  String get reviewLearnMoreButton;

  /// Button to leave the review session
  ///
  /// In en, this message translates to:
  /// **'Return'**
  String get reviewReturnButton;

  /// Feedback heading when answer is correct
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get reviewCorrect;

  /// Shows the correct answer
  ///
  /// In en, this message translates to:
  /// **'Answer: {character}'**
  String reviewAnswer(String character);

  /// Shows what the user picked
  ///
  /// In en, this message translates to:
  /// **'You picked: {character}'**
  String reviewYouPicked(String character);

  /// Button to continue after feedback
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get reviewContinue;

  /// On'yomi reading line in review
  ///
  /// In en, this message translates to:
  /// **'On\'yomi: {readings}'**
  String reviewOnyomi(String readings);

  /// Kun'yomi reading line in review
  ///
  /// In en, this message translates to:
  /// **'Kun\'yomi: {readings}'**
  String reviewKunyomi(String readings);

  /// Meaning line in review
  ///
  /// In en, this message translates to:
  /// **'Meaning: {meanings}'**
  String reviewMeaning(String meanings);

  /// Story keyword hint in review
  ///
  /// In en, this message translates to:
  /// **'Keyword: {keyword}'**
  String reviewKeyword(String keyword);

  /// Prompt for draw from meaning card
  ///
  /// In en, this message translates to:
  /// **'Draw this kanji from memory:'**
  String get reviewDrawFromMeaningPrompt;

  /// Button when user doesn't know the answer
  ///
  /// In en, this message translates to:
  /// **'Don\'t know'**
  String get reviewDontKnow;

  /// Prompt for kanji recognition card
  ///
  /// In en, this message translates to:
  /// **'What is the reading and meaning of this kanji?'**
  String get reviewKanjiRecognitionPrompt;

  /// Button to reveal the answer
  ///
  /// In en, this message translates to:
  /// **'Reveal'**
  String get reviewReveal;

  /// Grade button for failed recall
  ///
  /// In en, this message translates to:
  /// **'Again'**
  String get reviewAgain;

  /// Grade button for successful recall
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get reviewGood;

  /// Toggle to show sentence translation
  ///
  /// In en, this message translates to:
  /// **'Show translation'**
  String get reviewShowTranslation;

  /// Toggle to hide sentence translation
  ///
  /// In en, this message translates to:
  /// **'Hide translation'**
  String get reviewHideTranslation;

  /// Prompt for reading cloze card
  ///
  /// In en, this message translates to:
  /// **'What is the reading of the highlighted word?'**
  String get reviewReadingClozePrompt;

  /// AppBar title during new kanji slideshow
  ///
  /// In en, this message translates to:
  /// **'New kanji ({current}/{total})'**
  String reviewSlideshowTitle(int current, int total);

  /// Button on last slideshow slide
  ///
  /// In en, this message translates to:
  /// **'Start review'**
  String get reviewSlideshowStartReview;

  /// Button to advance slideshow
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get reviewSlideshowNext;

  /// AppBar title for review start screen
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewStartTitle;

  /// Card title on review start screen
  ///
  /// In en, this message translates to:
  /// **'Current selection'**
  String get reviewStartCurrentSelection;

  /// Count of kanji in current scope
  ///
  /// In en, this message translates to:
  /// **'{count} kanji in scope'**
  String reviewStartKanjiInScope(int count);

  /// Shown while due count is loading
  ///
  /// In en, this message translates to:
  /// **'Counting due cards…'**
  String get reviewStartCountingDue;

  /// Number of cards due
  ///
  /// In en, this message translates to:
  /// **'{count} due now'**
  String reviewStartDueNow(int count);

  /// Count of seen vs unseen kanji in scope
  ///
  /// In en, this message translates to:
  /// **'{seen} seen, {unseen} new'**
  String reviewStartSeen(int seen, int unseen);

  /// Scope description for empty custom set
  ///
  /// In en, this message translates to:
  /// **'Custom set (empty)'**
  String get reviewStartCustomSetEmpty;

  /// Scope description for custom set
  ///
  /// In en, this message translates to:
  /// **'Custom set'**
  String get reviewStartCustomSet;

  /// Scope description for RTK mode
  ///
  /// In en, this message translates to:
  /// **'RTK up to {index}'**
  String reviewStartRtk(int index);

  /// Scope description when nothing selected
  ///
  /// In en, this message translates to:
  /// **'Nothing selected'**
  String get reviewStartNothingSelected;

  /// Section title for quiz focus
  ///
  /// In en, this message translates to:
  /// **'What to quiz'**
  String get reviewStartWhatToQuiz;

  /// Segment label for core focus
  ///
  /// In en, this message translates to:
  /// **'Kanji only'**
  String get reviewStartKanjiOnly;

  /// Segment label for composita focus
  ///
  /// In en, this message translates to:
  /// **'Composita'**
  String get reviewStartComposita;

  /// Segment label for both focus
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get reviewStartBoth;

  /// Warning when composita not enabled
  ///
  /// In en, this message translates to:
  /// **'No composita/sentence testing is enabled for this scope yet — set a composita ceiling while editing it in the Learning section.'**
  String get reviewStartCompositaOff;

  /// Label for daily new cap input
  ///
  /// In en, this message translates to:
  /// **'New kanji per day:'**
  String get reviewStartNewKanjiPerDay;

  /// Button to start the review session
  ///
  /// In en, this message translates to:
  /// **'Start Review'**
  String get reviewStartButton;

  /// Button to continue a review session when cards are due
  ///
  /// In en, this message translates to:
  /// **'Continue Review'**
  String get reviewContinueButton;

  /// Button label when nothing is due but new kanji can be learned
  ///
  /// In en, this message translates to:
  /// **'Learn {count} new kanji'**
  String reviewStartLearnNew(int count);

  /// Dialog title when leaving review mid-session
  ///
  /// In en, this message translates to:
  /// **'Leave review?'**
  String get reviewLeaveDialogTitle;

  /// Dialog content when leaving review mid-session
  ///
  /// In en, this message translates to:
  /// **'Your daily review is not complete yet. Leave anyway?'**
  String get reviewLeaveDialogContent;

  /// Confirm button for leaving review
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get reviewLeaveConfirm;

  /// AppBar title for statistics screen
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get statisticsTitle;

  /// Card type label
  ///
  /// In en, this message translates to:
  /// **'Kanji recognition'**
  String get statisticsKanjiRecognition;

  /// Card type label
  ///
  /// In en, this message translates to:
  /// **'Draw from meaning'**
  String get statisticsDrawFromMeaning;

  /// Card type label
  ///
  /// In en, this message translates to:
  /// **'Reading (composita/sentence)'**
  String get statisticsReadingCloze;

  /// Card type label
  ///
  /// In en, this message translates to:
  /// **'Draw in sentence (composita/sentence)'**
  String get statisticsDrawInSentence;

  /// Legend label for known cards
  ///
  /// In en, this message translates to:
  /// **'Known'**
  String get statisticsKnown;

  /// Legend label for missed cards
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get statisticsMissed;

  /// Legend label for not started cards
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get statisticsNotStarted;

  /// Section title for composita stats
  ///
  /// In en, this message translates to:
  /// **'Composita/sentence testing'**
  String get statisticsCompositaTitle;

  /// Explanation of testable composita words
  ///
  /// In en, this message translates to:
  /// **'{count} testable {count, plural, =1{word} other{words}} in this scope — never gates green, tracked separately.'**
  String statisticsTestableWords(int count);

  /// Label for reading coverage pie
  ///
  /// In en, this message translates to:
  /// **'Reading tested'**
  String get statisticsReadingTested;

  /// Label for writing coverage pie
  ///
  /// In en, this message translates to:
  /// **'Writing tested'**
  String get statisticsWritingTested;

  /// Button to open kanji browser
  ///
  /// In en, this message translates to:
  /// **'Inspect all kanji'**
  String get statisticsInspectAllKanji;

  /// Button to reset all stats
  ///
  /// In en, this message translates to:
  /// **'Reset statistics'**
  String get statisticsResetButton;

  /// Dialog title for reset
  ///
  /// In en, this message translates to:
  /// **'Reset statistics?'**
  String get statisticsResetDialogTitle;

  /// Dialog content for reset
  ///
  /// In en, this message translates to:
  /// **'This clears all review progress (due dates, known/unknown status, and new-card introductions) for every kanji. You will start from scratch. This cannot be undone.'**
  String get statisticsResetDialogContent;

  /// Confirm button for reset dialog
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get statisticsResetConfirm;

  /// Clear button on draw and pick widget
  ///
  /// In en, this message translates to:
  /// **'Clear drawing'**
  String get drawAndPickClearDrawing;

  /// Shown while recognizer runs
  ///
  /// In en, this message translates to:
  /// **'Recognizing...'**
  String get drawAndPickRecognizing;

  /// Prompt to pick a candidate
  ///
  /// In en, this message translates to:
  /// **'Which one did you draw?'**
  String get drawAndPickWhichOne;

  /// Legend row showing label, count, and percentage
  ///
  /// In en, this message translates to:
  /// **'{label}: {value} ({percent}%)'**
  String legendValuePercent(String label, int value, int percent);

  /// Composita pie chart label
  ///
  /// In en, this message translates to:
  /// **'{label}: {tested}/{testable}'**
  String compositaPieLabel(String label, int tested, int testable);

  /// Title of the Pro paywall bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro'**
  String get proPaywallTitle;

  /// Description in paywall sheet
  ///
  /// In en, this message translates to:
  /// **'Get access to all JLPT levels, custom study sets, composita testing, and statistics.'**
  String get proPaywallDescription;

  /// Feature bullet for JLPT levels
  ///
  /// In en, this message translates to:
  /// **'All JLPT levels (N1–N3)'**
  String get proPaywallFeatureJlpt;

  /// Feature bullet for custom sets
  ///
  /// In en, this message translates to:
  /// **'Unlimited custom kanji sets'**
  String get proPaywallFeatureCustom;

  /// Feature bullet for composita
  ///
  /// In en, this message translates to:
  /// **'Composita & sentence testing'**
  String get proPaywallFeatureComposita;

  /// Feature bullet for statistics
  ///
  /// In en, this message translates to:
  /// **'Detailed statistics'**
  String get proPaywallFeatureStats;

  /// Purchase button label with price
  ///
  /// In en, this message translates to:
  /// **'Unlock Pro — {price}'**
  String proPaywallBuyButton(String price);

  /// Restore purchases link
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get proPaywallRestore;

  /// Shown while restoring purchases
  ///
  /// In en, this message translates to:
  /// **'Restoring...'**
  String get proPaywallRestoring;

  /// Error message when purchase fails
  ///
  /// In en, this message translates to:
  /// **'Purchase failed. Please try again.'**
  String get proPaywallError;

  /// Shown after successful restore
  ///
  /// In en, this message translates to:
  /// **'Purchases restored!'**
  String get proPaywallRestoreSuccess;

  /// Shown when restore finds nothing
  ///
  /// In en, this message translates to:
  /// **'No previous purchase found.'**
  String get proPaywallRestoreNothing;

  /// Hint when tapping a gated JLPT level
  ///
  /// In en, this message translates to:
  /// **'Pro required for N1–N3'**
  String get proLevelLocked;

  /// Button on help screen to restore purchases
  ///
  /// In en, this message translates to:
  /// **'Restore Purchases'**
  String get helpRestorePurchases;

  /// Kanji count with free-tier limit
  ///
  /// In en, this message translates to:
  /// **'{count}/{limit} kanji'**
  String customEditKanjiCount(int count, int limit);

  /// Kanji count for Pro users (no limit)
  ///
  /// In en, this message translates to:
  /// **'{count} kanji'**
  String customEditKanjiCountPro(int count);

  /// Snackbar when free user hits custom set cap
  ///
  /// In en, this message translates to:
  /// **'Free tier limited to {limit} kanji'**
  String customEditLimitReached(int limit);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
