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
  /// **'漢字友'**
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

  /// Button label for settings/edit
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get learningSettings;

  /// Button label for statistics
  ///
  /// In en, this message translates to:
  /// **'Statistics'**
  String get learningStatistics;

  /// AppBar title for help screen
  ///
  /// In en, this message translates to:
  /// **'Help & About'**
  String get helpTitle;

  /// Short tagline shown below app name on help screen
  ///
  /// In en, this message translates to:
  /// **'A kanji learning tool for serious learners'**
  String get helpTagline;

  /// Section divider label for feature highlights
  ///
  /// In en, this message translates to:
  /// **'What\'s inside'**
  String get helpFeaturesSection;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'Handwriting Recognition'**
  String get helpFeatureRecognitionTitle;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'Draw any kanji for instant offline recognition — neural network, 6,500+ characters.'**
  String get helpFeatureRecognitionDesc;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'Spaced Repetition (SRS)'**
  String get helpFeatureSrsTitle;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'Draw kanji from memory, not just recognize them. Four card types build real recall through active writing.'**
  String get helpFeatureSrsDesc;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'Composita & Sentences'**
  String get helpFeatureCompositaTitle;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'You choose which compound words to study. Learn kanji in context with 6,000+ example sentences.'**
  String get helpFeatureCompositaDesc;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'Stroke Order'**
  String get helpFeatureStrokeOrderTitle;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'Animated stroke-by-stroke diagrams with a practice canvas for every kanji.'**
  String get helpFeatureStrokeOrderDesc;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'Dictionary'**
  String get helpFeatureDictionaryTitle;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'60,000+ words from JMdict. Draw to look up single kanji or build words character by character.'**
  String get helpFeatureDictionaryDesc;

  /// Feature card title
  ///
  /// In en, this message translates to:
  /// **'Keywords & Stories'**
  String get helpFeatureStoriesTitle;

  /// Feature card description
  ///
  /// In en, this message translates to:
  /// **'Add your own mnemonics and keywords to each kanji to make them stick.'**
  String get helpFeatureStoriesDesc;

  /// Section divider label for settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get helpSettingsSection;

  /// Acknowledgement text before the licenses button
  ///
  /// In en, this message translates to:
  /// **'Kanjitomo would not be possible without these wonderful open-source projects and data sets:'**
  String get helpAcknowledgement;

  /// Button to open licenses page
  ///
  /// In en, this message translates to:
  /// **'All licenses'**
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
  /// **'{character}: Composita'**
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
  /// **'Add kanji'**
  String get customEditAddByKanji;

  /// Segment label for adding words/composita to custom set
  ///
  /// In en, this message translates to:
  /// **'Add composita'**
  String get customEditAddByWord;

  /// Hint text for composita picker search field
  ///
  /// In en, this message translates to:
  /// **'Search JMdict for a word...'**
  String get compositaPickerSearchHint;

  /// Button to open draw-to-build-word screen for composita
  ///
  /// In en, this message translates to:
  /// **'Additional composita'**
  String get compositaPickerDrawButton;

  /// Title of the draw composita screen
  ///
  /// In en, this message translates to:
  /// **'Draw composita for {char}'**
  String compositaPickerDrawTitle(String char);

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

  /// Label shown when a word is already added as composita for review
  ///
  /// In en, this message translates to:
  /// **'Already in review'**
  String get wordLookupAlreadyInReview;

  /// Button to clear the word text field, shown next to Clear drawing
  ///
  /// In en, this message translates to:
  /// **'Clear word'**
  String get wordLookupClearWord;

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

  /// AppBar title during review showing progress
  ///
  /// In en, this message translates to:
  /// **'Review — {done}/{total}'**
  String reviewHeader(int done, int total);

  /// AppBar title during review for a new card showing progress
  ///
  /// In en, this message translates to:
  /// **'Review — {done}/{total} — New'**
  String reviewHeaderNew(int done, int total);

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

  /// Button to expand kanji details in feedback
  ///
  /// In en, this message translates to:
  /// **'Show details'**
  String get reviewShowDetails;

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
  /// **'{count} facts due now'**
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

  /// Label for daily new cap input
  ///
  /// In en, this message translates to:
  /// **'New kanji per day:'**
  String get reviewStartNewKanjiPerDay;

  /// Button to start the review session
  ///
  /// In en, this message translates to:
  /// **'Review'**
  String get reviewStartButton;

  /// Heading for the kanji pool list on the review start screen
  ///
  /// In en, this message translates to:
  /// **'Learning pool ({count})'**
  String reviewStartPoolHeading(int count);

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

  /// Legend label for cards passed (2+ consecutive correct)
  ///
  /// In en, this message translates to:
  /// **'Passed'**
  String get statisticsKnown;

  /// Legend label for cards still being learned
  ///
  /// In en, this message translates to:
  /// **'Learning'**
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

  /// Count of fully learnt kanji (green/green)
  ///
  /// In en, this message translates to:
  /// **'{count} / {total} learnt'**
  String statisticsLearnt(int count, int total);

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

  /// Tooltip/label for the undo last stroke button
  ///
  /// In en, this message translates to:
  /// **'Undo stroke'**
  String get undoStroke;

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

  /// Button label and screen title for adding kanji/composita to custom set
  ///
  /// In en, this message translates to:
  /// **'Add elements'**
  String get customEditAddElements;

  /// Section title for due date distribution
  ///
  /// In en, this message translates to:
  /// **'Upcoming reviews'**
  String get dueOverviewTitle;

  /// Label for overdue bucket
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get dueOverviewOverdue;

  /// Label for today bucket
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dueOverviewToday;

  /// Label for tomorrow bucket
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dueOverviewTomorrow;

  /// Label for this week bucket
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get dueOverviewThisWeek;

  /// Label for later bucket
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get dueOverviewLater;

  /// Label for not started bucket
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get dueOverviewNotStarted;

  /// Compact due date summary on review start screen
  ///
  /// In en, this message translates to:
  /// **'Tomorrow: {tomorrow} · This week: {week} · Later: {later}'**
  String dueOverviewCompact(int tomorrow, int week, int later);

  /// Button label for quiz on learning screen
  ///
  /// In en, this message translates to:
  /// **'JLPT-like Quiz'**
  String get learningQuiz;

  /// AppBar title for quiz start screen
  ///
  /// In en, this message translates to:
  /// **'Quiz'**
  String get quizStartTitle;

  /// Label for question count picker
  ///
  /// In en, this message translates to:
  /// **'Number of questions:'**
  String get quizStartQuestionCount;

  /// Button to start the quiz
  ///
  /// In en, this message translates to:
  /// **'Start Quiz'**
  String get quizStartButton;

  /// Progress indicator during quiz
  ///
  /// In en, this message translates to:
  /// **'Question {current}/{total}'**
  String quizProgress(int current, int total);

  /// Prompt for reading question type
  ///
  /// In en, this message translates to:
  /// **'What is the reading of the highlighted word?'**
  String get quizPickReading;

  /// Prompt for kanji question type
  ///
  /// In en, this message translates to:
  /// **'Which word fits in the sentence?'**
  String get quizPickKanji;

  /// Feedback when answer is correct
  ///
  /// In en, this message translates to:
  /// **'Correct!'**
  String get quizCorrect;

  /// Feedback when answer is wrong
  ///
  /// In en, this message translates to:
  /// **'Wrong — the answer is:'**
  String get quizWrong;

  /// Button to advance to next question
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get quizNext;

  /// Title of results screen
  ///
  /// In en, this message translates to:
  /// **'Quiz Results'**
  String get quizResultTitle;

  /// Score summary
  ///
  /// In en, this message translates to:
  /// **'{correct}/{total} correct'**
  String quizResultScore(int correct, int total);

  /// Button to return from quiz results
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get quizDone;

  /// Shown when scope has too few composita for a quiz
  ///
  /// In en, this message translates to:
  /// **'Not enough words in scope for a quiz.'**
  String get quizNotEnoughWords;

  /// Informational text when user returns with a backlog of due cards
  ///
  /// In en, this message translates to:
  /// **'You have {count} cards to review from previous days.'**
  String reviewStartBacklogInfo(int count);

  /// Button to start review without introducing new cards
  ///
  /// In en, this message translates to:
  /// **'Review backlog first'**
  String get reviewStartReviewBacklog;

  /// Button to start review and also introduce new cards despite backlog
  ///
  /// In en, this message translates to:
  /// **'Also learn {count} new kanji'**
  String reviewStartBacklogAndNew(int count);

  /// Dialog text asking whether to introduce new kanji
  ///
  /// In en, this message translates to:
  /// **'You have {dueCount} cards due for review. Want to add {newCount} new kanji? That results in {totalCount} facts to review.'**
  String reviewStartNewKanjiDialog(int dueCount, int newCount, int totalCount);

  /// Confirm button in new kanji dialog
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get reviewStartDialogYes;

  /// Decline button in new kanji dialog
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get reviewStartDialogNo;

  /// Fact count estimate shown next to learn-more on queue-exhausted screen
  ///
  /// In en, this message translates to:
  /// **'That adds {factCount} new facts'**
  String reviewLearnMoreEstimate(int factCount);

  /// Tooltip for undo button in review AppBar
  ///
  /// In en, this message translates to:
  /// **'Redo previous card'**
  String get reviewUndoTooltip;

  /// Section title for max composita per kanji setting
  ///
  /// In en, this message translates to:
  /// **'Composita words per kanji'**
  String get jlptEditCompositaPerKanji;

  /// Switch label to restrict quiz to kanji the user has already reviewed
  ///
  /// In en, this message translates to:
  /// **'Only quiz seen kanji'**
  String get quizOnlySeenKanji;

  /// Label for maximum backlog setting
  ///
  /// In en, this message translates to:
  /// **'Maximum backlog:'**
  String get reviewMaxBacklog;

  /// Helper text below the max backlog field
  ///
  /// In en, this message translates to:
  /// **'0 = no limit'**
  String get reviewMaxBacklogHint;

  /// First-time dialog title for lookup screen
  ///
  /// In en, this message translates to:
  /// **'Draw to recognize'**
  String get ftdLookupTitle;

  /// First-time dialog message for lookup screen
  ///
  /// In en, this message translates to:
  /// **'Draw any kanji on the canvas — the neural network recognizes it instantly, even with messy handwriting. Supports 6,500+ characters, entirely offline.\n\nTap a result to see readings, meaning, stroke order, example sentences, and compound words.\n\nTry it now — minimize this card and draw something!'**
  String get ftdLookupMessage;

  /// First-time dialog title for word lookup screen
  ///
  /// In en, this message translates to:
  /// **'Word lookup'**
  String get ftdWordLookupTitle;

  /// First-time dialog message for word lookup screen
  ///
  /// In en, this message translates to:
  /// **'Look up compound words in a 60,000+ entry dictionary (JMdict). Draw each character to build the word, or type directly.\n\nMinimize this card to try it out!'**
  String get ftdWordLookupMessage;

  /// First-time dialog title for learning screen
  ///
  /// In en, this message translates to:
  /// **'Learning'**
  String get ftdLearningTitle;

  /// First-time dialog message for learning screen
  ///
  /// In en, this message translates to:
  /// **'You decide what to study. Add kanji by JLPT level or hand-pick individual characters. Spaced repetition tests you four ways — including drawing from memory, which builds the active recall that passive apps can\'t match.\n\nTrack your progress with detailed statistics.'**
  String get ftdLearningMessage;

  /// First-time dialog title for kanji browser screen
  ///
  /// In en, this message translates to:
  /// **'Kanji browser'**
  String get ftdBrowserTitle;

  /// First-time dialog message for kanji browser screen
  ///
  /// In en, this message translates to:
  /// **'Browse all Jōyō kanji in a searchable table. Filter by reading, meaning, or stroke count. Tap any kanji to see its detail — and choose which compound words (composita) you want in your reviews.\n\nColored dots show your review progress at a glance.'**
  String get ftdBrowserMessage;

  /// First-time dialog title for review session screen
  ///
  /// In en, this message translates to:
  /// **'Review session'**
  String get ftdReviewSessionTitle;

  /// First-time dialog message for review session screen
  ///
  /// In en, this message translates to:
  /// **'Four card types test different aspects of recall:\n• Draw from meaning — see the keyword, write the kanji from memory\n• Kanji recognition — see the kanji, recall its reading and meaning\n• Reading cloze — read a compound word in a real sentence\n• Draw in sentence — write a kanji in context\n\nDrawing from memory is harder than multiple choice — that\'s the point. Grade yourself with Again (missed) or Good (recalled).'**
  String get ftdReviewSessionMessage;

  /// Dismiss button for first-time dialogs
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get ftdGotIt;

  /// Button to reset all first-time dialog tips
  ///
  /// In en, this message translates to:
  /// **'Reset help'**
  String get helpResetTips;

  /// Snackbar after resetting tips
  ///
  /// In en, this message translates to:
  /// **'Help reset — the welcome tour will appear again next time.'**
  String get helpResetTipsDone;

  /// Title on welcome screen
  ///
  /// In en, this message translates to:
  /// **'Welcome to Kanjitomo'**
  String get welcomeTitle;

  /// Subtitle on welcome screen
  ///
  /// In en, this message translates to:
  /// **'A kanji learning tool for serious learners'**
  String get welcomeSubtitle;

  /// Button to start guided tour
  ///
  /// In en, this message translates to:
  /// **'Take a tour'**
  String get welcomeTakeTour;

  /// Button to skip welcome tour
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get welcomeSkip;

  /// Button on final tour step
  ///
  /// In en, this message translates to:
  /// **'Start learning!'**
  String get welcomeDone;

  /// Button to advance tour
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get tourNext;

  /// Button to go back in tour
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get tourBack;

  /// Button to permanently dismiss welcome screen
  ///
  /// In en, this message translates to:
  /// **'Don\'t show again'**
  String get welcomeDontShowAgain;

  /// Brief feature summary on the welcome screen
  ///
  /// In en, this message translates to:
  /// **'Draw kanji from memory to build real recall — not just recognition. You choose what to study: pick your kanji, your compound words, your pace. Offline, no account, no tracking.'**
  String get welcomeFeatureList;

  /// Help text for review start screen
  ///
  /// In en, this message translates to:
  /// **'Review uses spaced repetition (SM-2) to schedule cards at increasing intervals.\n\nFour card types test you:\n• Draw from meaning — see the meaning, draw the kanji\n• Kanji recognition — see the kanji, recall its reading\n• Reading cloze — read a word in a sentence\n• Draw in sentence — draw a kanji in context\n\nNew cards per day and max reviews per day are set on the learning hub. Reviews always take priority; new cards fill whatever daily budget remains. Use \"Learn more\" inside a session to add extra cards beyond the daily limit.\n\nGrade yourself: Again (forgot) or Good (recalled). Cards reappear after at least 1 day, with intervals growing as you succeed.\n\nYou can add a personal keyword and story (mnemonic) for each kanji. Tap any kanji in the browser or during review to edit them. Your keyword is shown during draw-from-meaning cards; your story appears when you reveal the answer. These help you build memorable associations between a kanji\'s shape, meaning, and components.'**
  String get helpReviewStart;

  /// Help text for JLPT edit screen
  ///
  /// In en, this message translates to:
  /// **'Select one or more JLPT levels. All kanji from the selected levels are combined into your study scope.\n\nComposita ceiling controls which vocabulary words are tested:\n• Off — no word/sentence testing, only bare kanji\n• N5–N1 — only test words at or easier than this level\nThe ceiling is independent of kanji levels (e.g. study N3 kanji with N5 words only).\n\nNew kanji/day: how many new characters to introduce each day (default 10).\n\nMax backlog: optional limit on how many due cards can pile up before new kanji stop being introduced. Set to 0 to disable the limit.\n\nComposita/kanji: how many words per character are tested (2–5, default 4).\n\nChanging levels takes effect immediately. Review progress is shared between JLPT and Custom mode — a kanji reviewed in one mode counts as reviewed in the other.'**
  String get helpJlptEdit;

  /// Help text for custom edit screen
  ///
  /// In en, this message translates to:
  /// **'Build your own study list by drawing kanji one at a time.\n\nTap a kanji to choose which vocabulary words (composita) to test for it. Unlike JLPT mode, nothing is auto-included — you explicitly pick each word.\n\nLong-press a kanji to remove it from your list.\n\nReview progress is shared between JLPT and Custom mode — a kanji reviewed in one mode counts as reviewed in the other.'**
  String get helpCustomEdit;

  /// Help text for quiz screen
  ///
  /// In en, this message translates to:
  /// **'The quiz is a quick multiple-choice self-test. It has no effect on your spaced-repetition progress.\n\nTwo question types are randomly mixed:\n• Kanji → Reading: a sentence with a kanji highlighted; pick its reading\n• Reading → Kanji: a sentence with readings shown; pick which kanji word fits\n\nOnly kanji you have already reviewed at least once are included.'**
  String get helpQuiz;

  /// Help text for statistics screen
  ///
  /// In en, this message translates to:
  /// **'Statistics show your progress for the current study scope.\n\nDue overview: how many cards are overdue, due today, tomorrow, this week, or later.\n\nPer card type (draw, recognition, reading cloze, draw in sentence):\n• Learnt (green): answered correctly 2 times in a row\n• Learning (orange): reviewed but not yet at 2 consecutive correct answers\n• Not started (gray): never reviewed\n\nA wrong answer resets the count back to zero — you need 2 consecutive correct answers again.\n\nKanji grid: each kanji shows colored dots.\n• First dot — core progress: green (both reading and writing learnt), orange (at least one direction started), gray (not yet reviewed)\n• Second dot — composita progress (only shown when the character has testable composita words): green (all words tested in both directions), orange (at least one tested), gray (none tested)\n\nComposita coverage shows how many eligible words have been tested at least once for reading and writing.\n\nUse the reset button at the bottom to erase all review progress and start over.'**
  String get helpStatistics;

  /// Help text for learning screen
  ///
  /// In en, this message translates to:
  /// **'This is your learning hub for managing kanji study.\n\nReview: Start a spaced-repetition session with your due cards.\n\nQuiz: A multiple-choice self-test (no effect on review progress).\n\nAdd/Remove: Add kanji by JLPT level, RTK order, or drawing. Manage your learning pool, composita settings, and individual kanji.\n\nStatistics: View your progress per card type, composita coverage, and a kanji grid with color-coded dots.\n\n── Settings ──\n\nNew cards/day: How many never-before-seen cards are introduced per day. These are kanji you added but haven\'t reviewed yet.\n\nMax reviews/day: The total daily budget for all cards — both reviews of previously seen cards and new cards combined. Reviews always take priority; new cards fill whatever capacity remains.\n\nExample: With New=30 and Max=200, if you have 120 due reviews and have already done 50 today:\n• Daily budget remaining: 200 − 50 = 150\n• Due reviews: 120 (all fit within 150)\n• Remaining for new cards: 150 − 120 = 30\n• Total session: 150 cards\n\nIf due reviews alone exceed the max (e.g. 250 due, max 200), only 200 reviews are shown and no new cards — catching up on reviews comes first.\n\nSet either value to 0 for unlimited.'**
  String get helpLearning;

  /// Button label for buy me a coffee link
  ///
  /// In en, this message translates to:
  /// **'Support development'**
  String get helpSupportDevelopment;

  /// Text above the support button
  ///
  /// In en, this message translates to:
  /// **'Kanjitomo is free and always will be. If you find it useful, consider buying me a coffee!'**
  String get helpSupportDescription;

  /// Button label for bug report email
  ///
  /// In en, this message translates to:
  /// **'Report a bug'**
  String get helpReportBug;

  /// Text above the bug report button
  ///
  /// In en, this message translates to:
  /// **'Found a problem? Send us an email and we\'ll look into it.'**
  String get helpReportBugDescription;

  /// Pre-filled email subject for bug reports
  ///
  /// In en, this message translates to:
  /// **'Kanjitomo bug report'**
  String get helpBugEmailSubject;

  /// Label for privacy policy link on help screen
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get helpPrivacyPolicy;

  /// Section title for the unified learning pool
  ///
  /// In en, this message translates to:
  /// **'Your learning pool'**
  String get learningPoolStats;

  /// Count of kanji in the learning pool
  ///
  /// In en, this message translates to:
  /// **'{count} kanji in pool'**
  String learningKanjiCount(int count);

  /// Count of seen kanji in pool
  ///
  /// In en, this message translates to:
  /// **'{seen} seen'**
  String learningSeen(int seen);

  /// Count of due cards
  ///
  /// In en, this message translates to:
  /// **'{due} cards due'**
  String learningDue(int due);

  /// Button to open add/remove kanji screen
  ///
  /// In en, this message translates to:
  /// **'Add/Remove'**
  String get learningAddRemove;

  /// Quick-add button for JLPT kanji
  ///
  /// In en, this message translates to:
  /// **'+{count} JLPT N{level}'**
  String learningQuickAddJlpt(int count, int level);

  /// Quick-add button for RTK kanji
  ///
  /// In en, this message translates to:
  /// **'+{count} RTK'**
  String learningQuickAddRtk(int count);

  /// Hint below quick-add buttons
  ///
  /// In en, this message translates to:
  /// **'Shortcut — adds kanji in RTK order.'**
  String get learningQuickAddHint;

  /// Button to open detailed add/remove screen
  ///
  /// In en, this message translates to:
  /// **'Add / Remove (detailed)'**
  String get learningDetailedAdd;

  /// Tab label for the browse-all-kanji tab
  ///
  /// In en, this message translates to:
  /// **'Browse'**
  String get addRemoveBrowseTab;

  /// Brief instruction text for the browse tab
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a kanji to your learning pool. Kanji already in your pool show a checkmark.'**
  String get addRemoveBrowseHelp;

  /// AppBar title for add/remove screen
  ///
  /// In en, this message translates to:
  /// **'Add / Remove kanji'**
  String get addRemoveTitle;

  /// Section title for adding by JLPT
  ///
  /// In en, this message translates to:
  /// **'Add by JLPT level'**
  String get addRemoveAddByJlpt;

  /// Help text for the JLPT tab
  ///
  /// In en, this message translates to:
  /// **'Add kanji grouped by JLPT level (N5 = easiest, N1 = hardest). Pick a level and how many to add — they\'ll be added in Heisig (RTK) order for efficient memorization. Compound words are auto-selected based on your settings below.'**
  String get addRemoveJlptHelp;

  /// Label for the count text field when adding kanji
  ///
  /// In en, this message translates to:
  /// **'Number of kanji'**
  String get addRemoveKanjiCount;

  /// Tip shown on JLPT and RTK add tabs
  ///
  /// In en, this message translates to:
  /// **'Tip: Add just a few new kanji each day for the best retention.'**
  String get addRemoveAddTip;

  /// Button to add kanji from a JLPT level
  ///
  /// In en, this message translates to:
  /// **'Add JLPT kanji'**
  String get addRemoveAddJlptButton;

  /// Section title for adding by RTK
  ///
  /// In en, this message translates to:
  /// **'Add by RTK order'**
  String get addRemoveAddByRtk;

  /// Help text for the RTK tab
  ///
  /// In en, this message translates to:
  /// **'Add kanji in Heisig\'s Remembering the Kanji (RTK) order, regardless of JLPT level. Good if you\'re following the RTK book or want to learn kanji by building on shared components.'**
  String get addRemoveRtkHelp;

  /// Button to add kanji by RTK order
  ///
  /// In en, this message translates to:
  /// **'Add RTK kanji'**
  String get addRemoveAddRtkButton;

  /// Section title for draw-to-add
  ///
  /// In en, this message translates to:
  /// **'Add by drawing'**
  String get addRemoveDrawToAdd;

  /// Help text for the draw tab
  ///
  /// In en, this message translates to:
  /// **'Draw any kanji to add it to your learning pool. Useful for adding a specific character you encountered. Compound words are auto-selected based on your settings below.'**
  String get addRemoveDrawHelp;

  /// Section title for composita settings
  ///
  /// In en, this message translates to:
  /// **'Composita settings'**
  String get addRemoveCompositaSettings;

  /// Label for composita ceiling setting
  ///
  /// In en, this message translates to:
  /// **'Vocabulary level limit'**
  String get addRemoveCompositaCeiling;

  /// Help text explaining the composita ceiling
  ///
  /// In en, this message translates to:
  /// **'Limits which compound words are auto-selected when adding kanji. A word\'s level is determined by its hardest kanji (e.g. 胃腸 is N1 because 腸 is N1, even though 胃 is N3). Set to N2 and 胃腸 won\'t be auto-selected, but 胃袋 (N2) will. You can always manually add any word via the composita picker. \"Off\" allows all levels.'**
  String get addRemoveCompositaCeilingHelp;

  /// Label when composita ceiling is off
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get addRemoveCeilingOff;

  /// Label for max composita per kanji setting
  ///
  /// In en, this message translates to:
  /// **'Words per kanji'**
  String get addRemoveMaxComposita;

  /// Help text explaining max composita per kanji
  ///
  /// In en, this message translates to:
  /// **'How many compound words to auto-select per kanji for review. More words means more variety but also more cards to review.'**
  String get addRemoveMaxCompositaHelp;

  /// Sort pool by RTK index
  ///
  /// In en, this message translates to:
  /// **'RTK order'**
  String get addRemovePoolSortRtk;

  /// Sort pool by date added
  ///
  /// In en, this message translates to:
  /// **'Date added'**
  String get addRemovePoolSortAdded;

  /// Sort pool by last modification date
  ///
  /// In en, this message translates to:
  /// **'Last modified'**
  String get addRemovePoolSortModified;

  /// Sort pool by mastery level (best learned last)
  ///
  /// In en, this message translates to:
  /// **'Mastery'**
  String get addRemovePoolSortMastery;

  /// Section title for the pool list with count
  ///
  /// In en, this message translates to:
  /// **'Learning pool ({count})'**
  String addRemovePoolTitle(int count);

  /// Shown when the learning pool is empty
  ///
  /// In en, this message translates to:
  /// **'No kanji in your learning pool yet.'**
  String get addRemovePoolEmpty;

  /// Help tip in the learning pool tab
  ///
  /// In en, this message translates to:
  /// **'Tap a kanji to edit its composita, story, or keyword. Long-press to remove.'**
  String get addRemovePoolTip;

  /// Search field label in learning pool tab
  ///
  /// In en, this message translates to:
  /// **'Search pool'**
  String get addRemovePoolSearch;

  /// Button to remove all kanji from pool
  ///
  /// In en, this message translates to:
  /// **'Clear all'**
  String get addRemoveClearAll;

  /// Dialog title for clearing the pool
  ///
  /// In en, this message translates to:
  /// **'Clear learning pool?'**
  String get addRemoveConfirmClearTitle;

  /// Dialog content for clearing the pool
  ///
  /// In en, this message translates to:
  /// **'Remove all {count} kanji and delete all review progress? This cannot be undone.'**
  String addRemoveConfirmClearContent(int count);

  /// Second confirmation body when clearing the pool
  ///
  /// In en, this message translates to:
  /// **'All review progress will be permanently lost. Your keywords and stories are kept.'**
  String get addRemoveClearSecondConfirm;

  /// Dialog title for removing a kanji from pool
  ///
  /// In en, this message translates to:
  /// **'Remove kanji?'**
  String get addRemoveConfirmRemoveTitle;

  /// Dialog content for removing a kanji from pool
  ///
  /// In en, this message translates to:
  /// **'Remove {char} and delete all review progress for it? This cannot be undone.'**
  String addRemoveConfirmRemoveContent(String char);

  /// Remove button in confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get addRemoveRemoveButton;

  /// Snackbar when drawn kanji is already in pool
  ///
  /// In en, this message translates to:
  /// **'{char} is already in your learning pool.'**
  String addRemoveAlreadyInPool(String char);

  /// AppBar title during new kanji slideshow from add/remove
  ///
  /// In en, this message translates to:
  /// **'New kanji ({current}/{total})'**
  String addRemoveSlideshowTitle(int current, int total);

  /// Label for selected composita in slideshow
  ///
  /// In en, this message translates to:
  /// **'Selected composita:'**
  String get addRemoveSlideshowComposita;

  /// Button to advance slideshow
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get addRemoveSlideshowNext;

  /// Button to finish slideshow
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get addRemoveSlideshowDone;

  /// Button to edit composita for a kanji
  ///
  /// In en, this message translates to:
  /// **'Edit composita'**
  String get kanjiDetailEditComposita;

  /// Button to add kanji to the learning pool
  ///
  /// In en, this message translates to:
  /// **'Add to learning'**
  String get kanjiDetailAddToLearning;

  /// Label for max new (never-reviewed) cards per review
  ///
  /// In en, this message translates to:
  /// **'New cards/day:'**
  String get learningNewCardsPerDay;

  /// Label for max total cards per review session
  ///
  /// In en, this message translates to:
  /// **'Max reviews/day:'**
  String get learningMaxReviewsPerDay;

  /// Number of never-reviewed cards waiting to be introduced
  ///
  /// In en, this message translates to:
  /// **'{count} waiting'**
  String learningWaitingCards(int count);

  /// Shown when the session cap is hit but more cards exist
  ///
  /// In en, this message translates to:
  /// **'Daily limit reached. {count} more cards available.'**
  String reviewDailyLimitReached(int count);

  /// Button to load more cards beyond the daily cap
  ///
  /// In en, this message translates to:
  /// **'Continue with {count} more'**
  String reviewContinueCards(int count);

  /// Label for recognition direction in progress detail dialog
  ///
  /// In en, this message translates to:
  /// **'Recognition'**
  String get progressDetailRecognition;

  /// Label for drawing direction in progress detail dialog
  ///
  /// In en, this message translates to:
  /// **'Drawing'**
  String get progressDetailDrawing;

  /// Progress fraction shown in detail dialog
  ///
  /// In en, this message translates to:
  /// **'{reps}/{threshold}'**
  String progressDetailStatus(int reps, int threshold);

  /// Shown when a direction has never been reviewed
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get progressDetailNotStarted;

  /// Button in progress dialog to open full kanji detail
  ///
  /// In en, this message translates to:
  /// **'View detail'**
  String get progressDetailViewFull;

  /// Label for composita progress in the tap-to-inspect dialog
  ///
  /// In en, this message translates to:
  /// **'Composita'**
  String get progressDetailComposita;

  /// Label for theme picker in settings
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// Name of the Indigo color theme
  ///
  /// In en, this message translates to:
  /// **'Indigo'**
  String get themeIndigo;

  /// Name of the Teal color theme
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get themeTeal;

  /// Name of the Sakura (pink) color theme
  ///
  /// In en, this message translates to:
  /// **'Sakura'**
  String get themeSakura;

  /// Name of the Forest (green) color theme
  ///
  /// In en, this message translates to:
  /// **'Forest'**
  String get themeForest;

  /// Name of the Amber (gold) color theme
  ///
  /// In en, this message translates to:
  /// **'Amber'**
  String get themeAmber;

  /// Label for brightness mode picker in settings
  ///
  /// In en, this message translates to:
  /// **'Brightness'**
  String get settingsBrightness;

  /// Brightness mode that follows system setting
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get themeAuto;

  /// Force light mode
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Force dark mode
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// Label for recognition model picker in settings
  ///
  /// In en, this message translates to:
  /// **'Recognition model'**
  String get settingsRecognitionModel;

  /// Label for standard recognition model
  ///
  /// In en, this message translates to:
  /// **'Standard (~3,000 kanji)'**
  String get modelStandard;

  /// Label for extended recognition model
  ///
  /// In en, this message translates to:
  /// **'Extended (~6,500 kanji)'**
  String get modelExtended;

  /// Snackbar shown while model is being loaded
  ///
  /// In en, this message translates to:
  /// **'Switching model...'**
  String get modelSwitching;

  /// Snackbar after model switch completes
  ///
  /// In en, this message translates to:
  /// **'Recognition model switched'**
  String get modelSwitched;

  /// Snackbar when model switch fails
  ///
  /// In en, this message translates to:
  /// **'Failed to switch model: {error}'**
  String modelSwitchFailed(String error);
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
