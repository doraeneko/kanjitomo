// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'kanjitomo';

  @override
  String failedToLoadAppData(String error) {
    return 'Không thể tải dữ liệu ứng dụng: $error';
  }

  @override
  String get lookupTitle => '漢字友';

  @override
  String get lookupWords => 'Từ vựng';

  @override
  String get lookupLearn => 'Học';

  @override
  String get lookupBrowse => 'Duyệt';

  @override
  String get lookupHelp => 'Trợ giúp';

  @override
  String get lookupHeading => 'Kanji';

  @override
  String get lookupClearDrawing => 'Xóa nét vẽ';

  @override
  String get lookupRecognizing => 'Đang nhận dạng...';

  @override
  String get lookupLoadingModel => 'Đang tải mô hình...';

  @override
  String lookupModelFailed(String error) {
    return 'Không thể tải mô hình: $error';
  }

  @override
  String get lookupBestMatch => 'Kết quả tốt nhất:';

  @override
  String lookupTopN(int count) {
    return 'Top $count:';
  }

  @override
  String get lookupInCustomReview => 'Đã có trong ôn tập tùy chỉnh';

  @override
  String get lookupAddToCustomReview => 'Thêm vào ôn tập tùy chỉnh';

  @override
  String get wordLookupTitle => 'Tra từ';

  @override
  String get wordLookupDrawInstruction =>
      'Vẽ một ký tự kanji hoặc kana để thêm vào từ:';

  @override
  String get wordLookupWordLabel => 'Từ';

  @override
  String get wordLookupClear => 'Xóa';

  @override
  String get wordLookupNoEntry =>
      'Không tìm thấy mục nào trong JMdict cho từ này.';

  @override
  String wordLookupCopied(String word) {
    return 'Đã sao chép \"$word\" vào bộ nhớ tạm';
  }

  @override
  String get copyToClipboard => 'Sao chép vào bộ nhớ tạm';

  @override
  String get learningTitle => 'Học tập';

  @override
  String get learningJlpt => 'Chế độ JLPT';

  @override
  String get learningCustom => 'Chế độ tùy chỉnh';

  @override
  String get learningReview => 'Ôn tập';

  @override
  String get learningSelect => 'Chọn';

  @override
  String get learningSettings => 'Cài đặt';

  @override
  String get learningStatistics => 'Thống kê';

  @override
  String get helpTitle => 'Trợ giúp & Giới thiệu';

  @override
  String get helpTagline => 'Công cụ học kanji cho người học nghiêm túc';

  @override
  String get helpFeaturesSection => 'Tính năng';

  @override
  String get helpFeatureRecognitionTitle => 'Nhận dạng chữ viết tay';

  @override
  String get helpFeatureRecognitionDesc =>
      'Vẽ bất kỳ kanji nào để nhận dạng ngay lập tức ngoại tuyến — mạng nơ-ron, hơn 6.500 ký tự.';

  @override
  String get helpFeatureSrsTitle => 'Lặp lại ngắt quãng (SRS)';

  @override
  String get helpFeatureSrsDesc =>
      'Vẽ kanji từ trí nhớ, không chỉ nhận dạng. Bốn loại thẻ xây dựng khả năng nhớ lại thực sự qua việc viết chủ động.';

  @override
  String get helpFeatureCompositaTitle => 'Composita & Câu ví dụ';

  @override
  String get helpFeatureCompositaDesc =>
      'Bạn chọn từ ghép nào để học. Học kanji trong ngữ cảnh với hơn 6.000 câu ví dụ.';

  @override
  String get helpFeatureStrokeOrderTitle => 'Thứ tự nét';

  @override
  String get helpFeatureStrokeOrderDesc =>
      'Sơ đồ hoạt hình từng nét với khung tập viết cho mỗi kanji.';

  @override
  String get helpFeatureDictionaryTitle => 'Từ điển';

  @override
  String get helpFeatureDictionaryDesc =>
      'Hơn 60.000 từ từ JMdict. Vẽ để tra kanji đơn lẻ hoặc ghép từ theo từng ký tự.';

  @override
  String get helpFeatureStoriesTitle => 'Từ khóa & Câu chuyện';

  @override
  String get helpFeatureStoriesDesc =>
      'Thêm phương pháp ghi nhớ và từ khóa riêng cho mỗi kanji để nhớ lâu hơn.';

  @override
  String get helpSettingsSection => 'Cài đặt';

  @override
  String get helpAcknowledgement =>
      'Kanjitomo sẽ không thể ra đời nếu thiếu các dự án mã nguồn mở và bộ dữ liệu tuyệt vời sau:';

  @override
  String get helpOpenSourceLicenses => 'Tất cả giấy phép';

  @override
  String get jlptEditTitle => 'Chỉnh sửa phạm vi JLPT';

  @override
  String get jlptEditLevels => 'Cấp độ JLPT';

  @override
  String jlptEditKanjiInScope(int count) {
    return '$count kanji trong phạm vi';
  }

  @override
  String get jlptEditCompositaCeiling => 'Giới hạn composita/câu';

  @override
  String get jlptEditCompositaCeilingDescription =>
      'Cấp độ khó nhất mà một từ composita được phép có, độc lập với các cấp kanji đã chọn ở trên. Tắt để bỏ qua hoàn toàn phần kiểm tra composita/câu cho phạm vi này.';

  @override
  String get jlptEditCeilingOff => 'Tắt';

  @override
  String get customEditTitle => 'Chỉnh sửa bộ tùy chỉnh';

  @override
  String get customEditClear => 'Xóa';

  @override
  String get customEditDrawInstruction =>
      'Vẽ một kanji để thêm vào bộ của bạn:';

  @override
  String get customEditSetEmpty => 'Bộ tùy chỉnh của bạn đang trống.';

  @override
  String get customEditSetInstruction =>
      'Bộ tùy chỉnh của bạn (chạm để sửa, giữ để xóa):';

  @override
  String customEditIsKana(String char) {
    return '$char là kana, không phải kanji';
  }

  @override
  String customEditAlreadyInSet(String char) {
    return '$char đã có trong bộ của bạn';
  }

  @override
  String customEditAdded(String char) {
    return 'Đã thêm $char vào bộ của bạn';
  }

  @override
  String customEditRemoveDialogTitle(String char) {
    return 'Xóa $char?';
  }

  @override
  String customEditRemoveDialogContent(String char) {
    return 'Xóa $char khỏi bộ tùy chỉnh của bạn?';
  }

  @override
  String get dialogRemove => 'Xóa';

  @override
  String get customEditClearDialogTitle => 'Xóa bộ tùy chỉnh?';

  @override
  String customEditClearDialogContent(int count) {
    return 'Thao tác này sẽ xóa tất cả $count kanji khỏi bộ tùy chỉnh. Không thể hoàn tác.';
  }

  @override
  String get dialogCancel => 'Hủy';

  @override
  String get dialogClear => 'Xóa';

  @override
  String compositaPickerTitle(String character) {
    return '$character: Composita';
  }

  @override
  String get compositaPickerDescription =>
      'Chỉ những từ được chọn ở đây mới được dùng cho kiểm tra composita/câu — khác với chế độ JLPT, chế độ tùy chỉnh không có giới hạn cấp, nên không có gì được kiểm tra cho đến khi bạn chọn từ bên dưới.';

  @override
  String get compositaPickerEmpty => 'Không tìm thấy composita cho kanji này.';

  @override
  String get customEditAddByKanji => 'Thêm kanji';

  @override
  String get customEditAddByWord => 'Thêm composita';

  @override
  String get compositaPickerSearchHint => 'Tìm kiếm từ trong JMdict...';

  @override
  String get compositaPickerDrawButton => 'Composita bổ sung';

  @override
  String compositaPickerDrawTitle(String char) {
    return 'Vẽ composita cho $char';
  }

  @override
  String get compositaPickerAdd => 'Thêm';

  @override
  String compositaPickerAdded(String word) {
    return 'Đã thêm $word';
  }

  @override
  String get compositaPickerNoResults => 'Không tìm thấy từ phù hợp.';

  @override
  String compositaPickerWordNotForChar(String char) {
    return 'Từ này không chứa $char';
  }

  @override
  String get wordLookupAddToReview => 'Thêm vào ôn tập';

  @override
  String wordLookupAddedToReview(String word) {
    return 'Đã thêm $word để ôn tập';
  }

  @override
  String wordLookupPickKanjiTitle(String word) {
    return 'Thêm $word cho kanji nào?';
  }

  @override
  String get wordLookupPickKanjiConfirm => 'Thêm';

  @override
  String get wordLookupAlreadyInReview => 'Đã có trong ôn tập';

  @override
  String get wordLookupClearWord => 'Xóa từ';

  @override
  String get kanjiBrowserTitle => 'Duyệt kanji';

  @override
  String get kanjiBrowserSearchLabel => 'Tìm theo cách đọc, nghĩa, hoặc số nét';

  @override
  String get kanjiBrowserNoMatch => 'Không tìm thấy kanji phù hợp.';

  @override
  String get kanjiBrowserColumnKanji => 'Kanji';

  @override
  String get kanjiBrowserColumnMeaning => 'Nghĩa';

  @override
  String get kanjiBrowserColumnKeyword => 'Từ khóa';

  @override
  String get kanjiBrowserColumnReadings => 'Cách đọc';

  @override
  String get kanjiBrowserColumnStrokes => 'Nét';

  @override
  String get kanjiDetailNoDictionaryEntry =>
      'Không có mục từ điển (kana không có trong từ điển kanji đi kèm ứng dụng này).';

  @override
  String get kanjiDetailOnyomi => 'On\'yomi';

  @override
  String get kanjiDetailKunyomi => 'Kun\'yomi';

  @override
  String get kanjiDetailMeaning => 'Nghĩa';

  @override
  String get kanjiDetailStrokeOrder => 'Thứ tự nét';

  @override
  String get kanjiDetailKeyword => 'Từ khóa';

  @override
  String get kanjiDetailKeywordHint =>
      'Gợi ý ngắn để nhớ lại (hiển thị trước khi bạn vẽ)...';

  @override
  String get kanjiDetailStory => 'Câu chuyện';

  @override
  String get kanjiDetailStoryHint =>
      'Viết câu chuyện ghi nhớ riêng của bạn cho kanji này...';

  @override
  String get kanjiDetailComposita => 'Composita';

  @override
  String get kanjiDetailExampleSentences => 'Câu ví dụ';

  @override
  String kanjiDetailCopied(String character) {
    return 'Đã sao chép \"$character\" vào bộ nhớ tạm';
  }

  @override
  String get reviewTitle => 'Ôn tập';

  @override
  String reviewHeader(int done, int total) {
    return 'Ôn tập — $done/$total';
  }

  @override
  String reviewHeaderNew(int done, int total) {
    return 'Ôn tập — $done/$total — Mới';
  }

  @override
  String get reviewNoCardsDue => 'Không có thẻ nào cần ôn lúc này.';

  @override
  String reviewLearnMore(int count) {
    return 'Học thêm $count';
  }

  @override
  String reviewMoreAvailable(int count) {
    return 'Còn $count chờ học';
  }

  @override
  String get reviewLearnMoreButton => 'Học thêm';

  @override
  String get reviewReturnButton => 'Quay lại';

  @override
  String get reviewCorrect => 'Chính xác!';

  @override
  String reviewAnswer(String character) {
    return 'Đáp án: $character';
  }

  @override
  String reviewYouPicked(String character) {
    return 'Bạn chọn: $character';
  }

  @override
  String get reviewContinue => 'Tiếp tục';

  @override
  String get reviewShowDetails => 'Xem chi tiết';

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
    return 'Nghĩa: $meanings';
  }

  @override
  String reviewKeyword(String keyword) {
    return 'Từ khóa: $keyword';
  }

  @override
  String get reviewDrawFromMeaningPrompt => 'Vẽ kanji này từ trí nhớ:';

  @override
  String get reviewDontKnow => 'Không biết';

  @override
  String get reviewKanjiRecognitionPrompt =>
      'Cách đọc và nghĩa của kanji này là gì?';

  @override
  String get reviewReveal => 'Hiện đáp án';

  @override
  String get reviewAgain => 'Lại';

  @override
  String get reviewGood => 'Tốt';

  @override
  String get reviewShowTranslation => 'Hiện bản dịch';

  @override
  String get reviewHideTranslation => 'Ẩn bản dịch';

  @override
  String get reviewReadingClozePrompt => 'Cách đọc của từ được tô sáng là gì?';

  @override
  String reviewSlideshowTitle(int current, int total) {
    return 'Kanji mới ($current/$total)';
  }

  @override
  String get reviewSlideshowStartReview => 'Bắt đầu ôn tập';

  @override
  String get reviewSlideshowNext => 'Tiếp';

  @override
  String get reviewStartTitle => 'Ôn tập';

  @override
  String get reviewStartCurrentSelection => 'Lựa chọn hiện tại';

  @override
  String reviewStartKanjiInScope(int count) {
    return '$count kanji trong phạm vi';
  }

  @override
  String get reviewStartCountingDue => 'Đang đếm thẻ cần ôn…';

  @override
  String reviewStartDueNow(int count) {
    return '$count thẻ cần ôn ngay';
  }

  @override
  String reviewStartSeen(int seen, int unseen) {
    return '$seen đã học, $unseen mới';
  }

  @override
  String get reviewStartCustomSetEmpty => 'Bộ tùy chỉnh (trống)';

  @override
  String get reviewStartCustomSet => 'Bộ tùy chỉnh';

  @override
  String reviewStartRtk(int index) {
    return 'RTK đến $index';
  }

  @override
  String get reviewStartNothingSelected => 'Chưa chọn gì';

  @override
  String get reviewStartNewKanjiPerDay => 'Kanji mới mỗi ngày:';

  @override
  String get reviewStartButton => 'Ôn tập';

  @override
  String reviewStartPoolHeading(int count) {
    return 'Danh sách học ($count)';
  }

  @override
  String get reviewContinueButton => 'Tiếp tục ôn tập';

  @override
  String reviewStartLearnNew(int count) {
    return 'Học $count kanji mới';
  }

  @override
  String get reviewLeaveDialogTitle => 'Rời khỏi ôn tập?';

  @override
  String get reviewLeaveDialogContent =>
      'Bạn chưa hoàn thành ôn tập hôm nay. Vẫn rời đi?';

  @override
  String get reviewLeaveConfirm => 'Rời đi';

  @override
  String get statisticsTitle => 'Thống kê';

  @override
  String get statisticsKanjiRecognition => 'Nhận dạng kanji';

  @override
  String get statisticsDrawFromMeaning => 'Vẽ từ nghĩa';

  @override
  String get statisticsReadingCloze => 'Đọc (composita/câu)';

  @override
  String get statisticsDrawInSentence => 'Vẽ trong câu (composita/câu)';

  @override
  String get statisticsKnown => 'Đạt';

  @override
  String get statisticsMissed => 'Đang học';

  @override
  String get statisticsNotStarted => 'Chưa bắt đầu';

  @override
  String get statisticsCompositaTitle => 'Kiểm tra composita/câu';

  @override
  String statisticsTestableWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'từ',
      one: 'từ',
    );
    return '$count $_temp0 có thể kiểm tra trong phạm vi này — không ảnh hưởng đến thanh xanh, được theo dõi riêng.';
  }

  @override
  String get statisticsReadingTested => 'Đã kiểm tra đọc';

  @override
  String get statisticsWritingTested => 'Đã kiểm tra viết';

  @override
  String get statisticsInspectAllKanji => 'Xem tất cả kanji';

  @override
  String statisticsLearnt(int count, int total) {
    return '$count / $total đã thuộc';
  }

  @override
  String get statisticsResetButton => 'Đặt lại thống kê';

  @override
  String get statisticsResetDialogTitle => 'Đặt lại thống kê?';

  @override
  String get statisticsResetDialogContent =>
      'Thao tác này sẽ xóa toàn bộ tiến trình ôn tập (ngày đến hạn, trạng thái biết/chưa biết, và lần giới thiệu thẻ mới) cho mọi kanji. Bạn sẽ bắt đầu lại từ đầu. Không thể hoàn tác.';

  @override
  String get statisticsResetConfirm => 'Đặt lại';

  @override
  String get undoStroke => 'Hoàn tác nét';

  @override
  String get drawAndPickClearDrawing => 'Xóa nét vẽ';

  @override
  String get drawAndPickRecognizing => 'Đang nhận dạng...';

  @override
  String get drawAndPickWhichOne => 'Bạn đã vẽ chữ nào?';

  @override
  String legendValuePercent(String label, int value, int percent) {
    return '$label: $value ($percent%)';
  }

  @override
  String compositaPieLabel(String label, int tested, int testable) {
    return '$label: $tested/$testable';
  }

  @override
  String get proPaywallTitle => 'Mở khóa Pro';

  @override
  String get proPaywallDescription =>
      'Truy cập tất cả cấp độ JLPT, bộ học tùy chỉnh, kiểm tra composita và thống kê.';

  @override
  String get proPaywallFeatureJlpt => 'Tất cả cấp độ JLPT (N1–N3)';

  @override
  String get proPaywallFeatureCustom => 'Bộ kanji tùy chỉnh không giới hạn';

  @override
  String get proPaywallFeatureComposita => 'Kiểm tra composita & câu';

  @override
  String get proPaywallFeatureStats => 'Thống kê chi tiết';

  @override
  String proPaywallBuyButton(String price) {
    return 'Mở khóa Pro — $price';
  }

  @override
  String get proPaywallRestore => 'Khôi phục giao dịch';

  @override
  String get proPaywallRestoring => 'Đang khôi phục...';

  @override
  String get proPaywallError => 'Giao dịch thất bại. Vui lòng thử lại.';

  @override
  String get proPaywallRestoreSuccess => 'Đã khôi phục giao dịch!';

  @override
  String get proPaywallRestoreNothing => 'Không tìm thấy giao dịch trước đó.';

  @override
  String get proLevelLocked => 'Cần Pro cho N1–N3';

  @override
  String get helpRestorePurchases => 'Khôi phục giao dịch';

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
    return 'Bản miễn phí giới hạn $limit kanji';
  }

  @override
  String get customEditAddElements => 'Thêm thành phần';

  @override
  String get dueOverviewTitle => 'Lịch ôn tập sắp tới';

  @override
  String get dueOverviewOverdue => 'Quá hạn';

  @override
  String get dueOverviewToday => 'Hôm nay';

  @override
  String get dueOverviewTomorrow => 'Ngày mai';

  @override
  String get dueOverviewThisWeek => 'Tuần này';

  @override
  String get dueOverviewLater => 'Sau này';

  @override
  String get dueOverviewNotStarted => 'Chưa bắt đầu';

  @override
  String dueOverviewCompact(int tomorrow, int week, int later) {
    return 'Ngày mai: $tomorrow · Tuần này: $week · Sau này: $later';
  }

  @override
  String get learningQuiz => 'Câu đố kiểu JLPT';

  @override
  String get quizStartTitle => 'Câu đố';

  @override
  String get quizStartQuestionCount => 'Số câu hỏi:';

  @override
  String get quizStartButton => 'Bắt đầu';

  @override
  String quizProgress(int current, int total) {
    return 'Câu $current/$total';
  }

  @override
  String get quizPickReading => 'Cách đọc của từ được tô sáng là gì?';

  @override
  String get quizPickKanji => 'Từ nào phù hợp với câu?';

  @override
  String get quizCorrect => 'Chính xác!';

  @override
  String get quizWrong => 'Sai — đáp án là:';

  @override
  String get quizNext => 'Tiếp';

  @override
  String get quizResultTitle => 'Kết quả';

  @override
  String quizResultScore(int correct, int total) {
    return '$correct/$total đúng';
  }

  @override
  String get quizDone => 'Xong';

  @override
  String get quizNotEnoughWords => 'Không đủ từ trong phạm vi để làm câu đố.';

  @override
  String reviewStartBacklogInfo(int count) {
    return 'Bạn có $count thẻ cần ôn từ những ngày trước.';
  }

  @override
  String get reviewStartReviewBacklog => 'Ôn phần tồn đọng trước';

  @override
  String reviewStartBacklogAndNew(int count) {
    return 'Đồng thời học thêm $count kanji mới';
  }

  @override
  String reviewStartNewKanjiDialog(int dueCount, int newCount, int totalCount) {
    return 'Bạn có $dueCount thẻ cần ôn. Bạn muốn thêm $newCount kanji mới không? Tổng cộng sẽ có $totalCount thẻ cần ôn.';
  }

  @override
  String get reviewStartDialogYes => 'Có';

  @override
  String get reviewStartDialogNo => 'Không';

  @override
  String reviewLearnMoreEstimate(int factCount) {
    return 'Sẽ thêm $factCount thẻ mới';
  }

  @override
  String get reviewUndoTooltip => 'Làm lại thẻ trước';

  @override
  String get jlptEditCompositaPerKanji => 'Số từ composita mỗi kanji';

  @override
  String get quizOnlySeenKanji => 'Chỉ hỏi kanji đã học';

  @override
  String get reviewMaxBacklog => 'Tồn đọng tối đa:';

  @override
  String get reviewMaxBacklogHint => '0 = không giới hạn';

  @override
  String get ftdLookupTitle => 'Vẽ để nhận dạng';

  @override
  String get ftdLookupMessage =>
      'Vẽ bất kỳ kanji nào trên khung vẽ — mạng nơ-ron nhận dạng ngay lập tức, ngay cả với chữ viết tay lộn xộn. Hỗ trợ hơn 6.500 ký tự, hoàn toàn ngoại tuyến.\n\nChạm vào kết quả để xem cách đọc, nghĩa, thứ tự nét, câu ví dụ và từ ghép.\n\nThử ngay bây giờ — thu nhỏ thẻ này và vẽ thử!';

  @override
  String get ftdWordLookupTitle => 'Tra từ';

  @override
  String get ftdWordLookupMessage =>
      'Tra từ ghép trong từ điển hơn 60.000 từ (JMdict). Vẽ từng ký tự để ghép từ, hoặc gõ trực tiếp.\n\nThu nhỏ thẻ này để thử!';

  @override
  String get ftdLearningTitle => 'Học tập';

  @override
  String get ftdLearningMessage =>
      'Bạn quyết định học gì. Thêm kanji theo cấp JLPT hoặc chọn từng ký tự riêng lẻ. Lặp lại ngắt quãng kiểm tra bạn bốn cách — bao gồm vẽ từ trí nhớ, xây dựng khả năng nhớ lại chủ động mà các ứng dụng thụ động không thể có.\n\nTheo dõi tiến trình với thống kê chi tiết.';

  @override
  String get ftdBrowserTitle => 'Duyệt kanji';

  @override
  String get ftdBrowserMessage =>
      'Duyệt tất cả kanji Jōyō trong bảng có thể tìm kiếm. Lọc theo cách đọc, nghĩa, hoặc số nét. Chạm vào bất kỳ kanji nào để xem chi tiết — và chọn từ ghép (composita) nào bạn muốn trong ôn tập.\n\nCác chấm màu thể hiện tiến trình ôn tập của bạn một cách nhanh chóng.';

  @override
  String get ftdReviewSessionTitle => 'Phiên ôn tập';

  @override
  String get ftdReviewSessionMessage =>
      'Bốn loại thẻ kiểm tra các khía cạnh nhớ lại khác nhau:\n• Vẽ từ nghĩa — xem từ khóa, viết kanji từ trí nhớ\n• Nhận dạng kanji — xem kanji, nhớ lại cách đọc và nghĩa\n• Điền khuyết cách đọc — đọc từ ghép trong câu thực tế\n• Vẽ trong câu — viết kanji trong ngữ cảnh\n\nVẽ từ trí nhớ khó hơn chọn đáp án — đó chính là mục đích. Tự chấm điểm với Lại (nhầm) hoặc Tốt (nhớ được).';

  @override
  String get ftdGotIt => 'Đã hiểu';

  @override
  String get helpResetTips => 'Đặt lại trợ giúp';

  @override
  String get helpResetTipsDone =>
      'Đã đặt lại trợ giúp — hướng dẫn chào mừng sẽ xuất hiện lại lần tới.';

  @override
  String get welcomeTitle => 'Chào mừng đến Kanjitomo';

  @override
  String get welcomeSubtitle => 'Công cụ học kanji cho người học nghiêm túc';

  @override
  String get welcomeTakeTour => 'Xem hướng dẫn';

  @override
  String get welcomeSkip => 'Bỏ qua';

  @override
  String get welcomeDone => 'Bắt đầu học!';

  @override
  String get tourNext => 'Tiếp';

  @override
  String get tourBack => 'Quay lại';

  @override
  String get welcomeDontShowAgain => 'Không hiển thị lại';

  @override
  String get welcomeFeatureList =>
      'Vẽ kanji từ trí nhớ để xây dựng khả năng nhớ lại thực sự — không chỉ nhận dạng. Bạn chọn những gì cần học: chọn kanji, chọn từ ghép, chọn tốc độ. Ngoại tuyến, không cần tài khoản, không theo dõi.';

  @override
  String get helpReviewStart =>
      'Ôn tập sử dụng lặp lại ngắt quãng (SM-2) để lên lịch thẻ với khoảng cách tăng dần.\n\nBốn loại thẻ kiểm tra bạn:\n• Vẽ từ nghĩa — xem nghĩa, vẽ kanji\n• Nhận dạng kanji — xem kanji, nhớ lại cách đọc\n• Điền khuyết cách đọc — đọc một từ trong câu\n• Vẽ trong câu — vẽ kanji trong ngữ cảnh\n\nSố thẻ mới mỗi ngày và số lượt ôn tối đa mỗi ngày được cài đặt ở trung tâm học tập. Ôn tập luôn được ưu tiên; thẻ mới sẽ lấp đầy ngân sách còn lại. Sử dụng \"Học thêm\" trong phiên để thêm thẻ vượt giới hạn hàng ngày.\n\nTự chấm điểm: Lại (quên) hoặc Tốt (nhớ được). Thẻ sẽ xuất hiện lại sau ít nhất 1 ngày, với khoảng cách tăng dần khi bạn trả lời đúng.\n\nBạn có thể thêm từ khóa và câu chuyện (mẹo ghi nhớ) riêng cho mỗi kanji. Chạm vào bất kỳ kanji nào trong trình duyệt hoặc khi ôn tập để chỉnh sửa. Từ khóa hiển thị trong thẻ vẽ từ nghĩa; câu chuyện xuất hiện khi bạn hiện đáp án. Chúng giúp bạn tạo liên kết dễ nhớ giữa hình dạng, nghĩa và các thành phần của kanji.';

  @override
  String get helpJlptEdit =>
      'Chọn một hoặc nhiều cấp độ JLPT. Tất cả kanji từ các cấp đã chọn được kết hợp thành phạm vi học.\n\nGiới hạn composita kiểm soát từ vựng nào được kiểm tra:\n• Tắt — không kiểm tra từ/câu, chỉ kanji đơn\n• N5–N1 — chỉ kiểm tra từ ở cấp đó hoặc dễ hơn\nGiới hạn này độc lập với cấp kanji (ví dụ: học kanji N3 với chỉ từ N5).\n\nKanji mới/ngày: số ký tự mới được giới thiệu mỗi ngày (mặc định 10).\n\nTồn đọng tối đa: giới hạn tùy chọn về số thẻ đến hạn có thể tích lũy trước khi ngừng giới thiệu kanji mới. Đặt 0 để tắt giới hạn.\n\nComposita/kanji: số từ được kiểm tra cho mỗi ký tự (2–5, mặc định 4).\n\nThay đổi cấp độ có hiệu lực ngay lập tức. Tiến trình ôn tập được chia sẻ giữa chế độ JLPT và Tùy chỉnh — kanji đã ôn ở chế độ này cũng được tính ở chế độ kia.';

  @override
  String get helpCustomEdit =>
      'Tạo danh sách học riêng bằng cách vẽ từng kanji một.\n\nChạm vào kanji để chọn từ vựng (composita) nào sẽ được kiểm tra. Khác với chế độ JLPT, không có gì được tự động thêm — bạn tự chọn từng từ.\n\nGiữ lâu vào kanji để xóa khỏi danh sách.\n\nTiến trình ôn tập được chia sẻ giữa chế độ JLPT và Tùy chỉnh — kanji đã ôn ở chế độ này cũng được tính ở chế độ kia.';

  @override
  String get helpQuiz =>
      'Câu đố là bài tự kiểm tra nhanh dạng trắc nghiệm. Không ảnh hưởng đến tiến trình lặp lại ngắt quãng.\n\nHai loại câu hỏi được trộn ngẫu nhiên:\n• Kanji → Cách đọc: một câu có kanji được tô sáng; chọn cách đọc đúng\n• Cách đọc → Kanji: một câu hiển thị cách đọc; chọn từ kanji phù hợp\n\nChỉ bao gồm kanji bạn đã ôn ít nhất một lần.';

  @override
  String get helpStatistics =>
      'Thống kê hiển thị tiến trình cho phạm vi học hiện tại.\n\nTổng quan đến hạn: số thẻ quá hạn, đến hạn hôm nay, ngày mai, tuần này, hoặc sau này.\n\nTheo loại thẻ (vẽ, nhận dạng, điền khuyết cách đọc, vẽ trong câu):\n• Đã thuộc (xanh): trả lời đúng 2 lần liên tiếp\n• Đang học (cam): đã ôn nhưng chưa đạt 2 lần đúng liên tiếp\n• Chưa bắt đầu (xám): chưa từng ôn\n\nTrả lời sai sẽ đặt lại về 0 — bạn cần 2 lần đúng liên tiếp lại.\n\nLưới kanji: mỗi kanji hiển thị các chấm màu.\n• Chấm thứ nhất — tiến trình chính: xanh (cả đọc và viết đã thuộc), cam (ít nhất một hướng đã bắt đầu), xám (chưa ôn)\n• Chấm thứ hai — tiến trình composita (chỉ hiển thị khi ký tự có từ composita có thể kiểm tra): xanh (tất cả từ đã kiểm tra cả hai hướng), cam (ít nhất một từ đã kiểm tra), xám (chưa kiểm tra)\n\nĐộ phủ composita cho thấy bao nhiêu từ đủ điều kiện đã được kiểm tra ít nhất một lần cho đọc và viết.\n\nSử dụng nút đặt lại ở cuối để xóa toàn bộ tiến trình ôn tập và bắt đầu lại.';

  @override
  String get helpLearning =>
      'Đây là trung tâm học tập để quản lý việc học kanji.\n\nÔn tập: Bắt đầu phiên lặp lại ngắt quãng với các thẻ đến hạn.\n\nCâu đố: Bài tự kiểm tra trắc nghiệm (không ảnh hưởng tiến trình ôn tập).\n\nThêm/Xóa: Thêm kanji theo cấp JLPT, thứ tự RTK, hoặc bằng cách vẽ. Quản lý danh sách học, cài đặt composita và từng kanji riêng lẻ.\n\nThống kê: Xem tiến trình theo loại thẻ, độ phủ composita và lưới kanji với chấm màu.\n\n── Cài đặt ──\n\nThẻ mới/ngày: Số thẻ chưa từng ôn được giới thiệu mỗi ngày. Đây là kanji bạn đã thêm nhưng chưa ôn.\n\nÔn tối đa/ngày: Ngân sách hàng ngày cho tất cả thẻ — cả ôn lại thẻ đã học và thẻ mới. Ôn tập luôn được ưu tiên; thẻ mới lấp đầy phần còn lại.\n\nVí dụ: Với Mới=30 và Tối đa=200, nếu bạn có 120 thẻ cần ôn và đã làm 50 hôm nay:\n• Ngân sách còn lại: 200 − 50 = 150\n• Thẻ cần ôn: 120 (nằm trong 150)\n• Còn lại cho thẻ mới: 150 − 120 = 30\n• Tổng phiên: 150 thẻ\n\nNếu thẻ cần ôn vượt quá tối đa (ví dụ: 250 cần ôn, tối đa 200), chỉ 200 thẻ ôn được hiển thị và không có thẻ mới — ưu tiên ôn bù trước.\n\nĐặt giá trị nào bằng 0 để không giới hạn.';

  @override
  String get helpSupportDevelopment => 'Ủng hộ phát triển';

  @override
  String get helpSupportDescription =>
      'Kanjitomo miễn phí và sẽ luôn miễn phí. Nếu bạn thấy hữu ích, hãy mời tôi một ly cà phê!';

  @override
  String get helpReportBug => 'Báo lỗi';

  @override
  String get helpReportBugDescription =>
      'Phát hiện vấn đề? Gửi email cho chúng tôi và chúng tôi sẽ xem xét.';

  @override
  String get helpBugEmailSubject => 'Báo lỗi Kanjitomo';

  @override
  String get helpPrivacyPolicy => 'Chính sách bảo mật';

  @override
  String get learningPoolStats => 'Danh sách học của bạn';

  @override
  String learningKanjiCount(int count) {
    return '$count kanji trong danh sách';
  }

  @override
  String learningSeen(int seen) {
    return '$seen đã học';
  }

  @override
  String learningDue(int due) {
    return '$due thẻ đến hạn';
  }

  @override
  String get learningAddRemove => 'Thêm/Xóa';

  @override
  String learningQuickAddJlpt(int count, int level) {
    return '+$count JLPT N$level';
  }

  @override
  String learningQuickAddRtk(int count) {
    return '+$count RTK';
  }

  @override
  String get learningQuickAddHint => 'Phím tắt — thêm kanji theo thứ tự RTK.';

  @override
  String get learningDetailedAdd => 'Thêm / Xóa (chi tiết)';

  @override
  String get addRemoveBrowseTab => 'Duyệt';

  @override
  String get addRemoveBrowseHelp =>
      'Chạm + để thêm kanji vào danh sách học. Kanji đã có trong danh sách hiển thị dấu tích.';

  @override
  String get addRemoveTitle => 'Thêm / Xóa kanji';

  @override
  String get addRemoveAddByJlpt => 'Thêm theo cấp JLPT';

  @override
  String get addRemoveJlptHelp =>
      'Thêm kanji theo nhóm cấp JLPT (N5 = dễ nhất, N1 = khó nhất). Chọn cấp và số lượng cần thêm — chúng sẽ được thêm theo thứ tự Heisig (RTK) để ghi nhớ hiệu quả. Từ ghép được tự động chọn dựa trên cài đặt bên dưới.';

  @override
  String get addRemoveKanjiCount => 'Số lượng kanji';

  @override
  String get addRemoveAddTip =>
      'Mẹo: Chỉ thêm vài kanji mới mỗi ngày để nhớ tốt nhất.';

  @override
  String get addRemoveAddJlptButton => 'Thêm kanji JLPT';

  @override
  String get addRemoveAddByRtk => 'Thêm theo thứ tự RTK';

  @override
  String get addRemoveRtkHelp =>
      'Thêm kanji theo thứ tự Remembering the Kanji (RTK) của Heisig, không phụ thuộc cấp JLPT. Phù hợp nếu bạn đang theo sách RTK hoặc muốn học kanji dựa trên các thành phần chung.';

  @override
  String get addRemoveAddRtkButton => 'Thêm kanji RTK';

  @override
  String get addRemoveDrawToAdd => 'Thêm bằng cách vẽ';

  @override
  String get addRemoveDrawHelp =>
      'Vẽ bất kỳ kanji nào để thêm vào danh sách học. Hữu ích khi muốn thêm một ký tự cụ thể bạn gặp. Từ ghép được tự động chọn dựa trên cài đặt bên dưới.';

  @override
  String get addRemoveCompositaSettings => 'Cài đặt composita';

  @override
  String get addRemoveCompositaCeiling => 'Giới hạn cấp từ vựng';

  @override
  String get addRemoveCompositaCeilingHelp =>
      'Giới hạn từ ghép nào được tự động chọn khi thêm kanji. Cấp của một từ được xác định bởi kanji khó nhất (ví dụ: 胃腸 là N1 vì 腸 là N1, dù 胃 là N3). Đặt N2 thì 胃腸 sẽ không được tự động chọn, nhưng 胃袋 (N2) sẽ được chọn. Bạn luôn có thể thêm bất kỳ từ nào qua bộ chọn composita. \"Tắt\" cho phép tất cả cấp.';

  @override
  String get addRemoveCeilingOff => 'Tắt';

  @override
  String get addRemoveMaxComposita => 'Số từ mỗi kanji';

  @override
  String get addRemoveMaxCompositaHelp =>
      'Số từ ghép được tự động chọn cho mỗi kanji để ôn tập. Nhiều từ hơn nghĩa là đa dạng hơn nhưng cũng nhiều thẻ cần ôn hơn.';

  @override
  String get addRemovePoolSortRtk => 'Thứ tự RTK';

  @override
  String get addRemovePoolSortAdded => 'Ngày thêm';

  @override
  String get addRemovePoolSortModified => 'Sửa gần nhất';

  @override
  String get addRemovePoolSortMastery => 'Mức thành thạo';

  @override
  String addRemovePoolTitle(int count) {
    return 'Danh sách học ($count)';
  }

  @override
  String get addRemovePoolEmpty => 'Chưa có kanji nào trong danh sách học.';

  @override
  String get addRemovePoolTip =>
      'Chạm vào kanji để chỉnh sửa composita, câu chuyện hoặc từ khóa. Giữ lâu để xóa.';

  @override
  String get addRemovePoolSearch => 'Tìm trong danh sách';

  @override
  String get addRemoveClearAll => 'Xóa tất cả';

  @override
  String get addRemoveConfirmClearTitle => 'Xóa danh sách học?';

  @override
  String addRemoveConfirmClearContent(int count) {
    return 'Xóa tất cả $count kanji và xóa toàn bộ tiến trình ôn tập? Không thể hoàn tác.';
  }

  @override
  String get addRemoveClearSecondConfirm =>
      'Toàn bộ tiến trình ôn tập sẽ bị mất vĩnh viễn. Từ khóa và câu chuyện của bạn được giữ lại.';

  @override
  String get addRemoveConfirmRemoveTitle => 'Xóa kanji?';

  @override
  String addRemoveConfirmRemoveContent(String char) {
    return 'Xóa $char và xóa toàn bộ tiến trình ôn tập cho nó? Không thể hoàn tác.';
  }

  @override
  String get addRemoveRemoveButton => 'Xóa';

  @override
  String addRemoveAlreadyInPool(String char) {
    return '$char đã có trong danh sách học.';
  }

  @override
  String addRemoveSlideshowTitle(int current, int total) {
    return 'Kanji mới ($current/$total)';
  }

  @override
  String get addRemoveSlideshowComposita => 'Composita đã chọn:';

  @override
  String get addRemoveSlideshowNext => 'Tiếp';

  @override
  String get addRemoveSlideshowDone => 'Xong';

  @override
  String get kanjiDetailEditComposita => 'Chỉnh sửa composita';

  @override
  String get kanjiDetailAddToLearning => 'Thêm vào học';

  @override
  String get learningNewCardsPerDay => 'Thẻ mới/ngày:';

  @override
  String get learningMaxReviewsPerDay => 'Ôn tối đa/ngày:';

  @override
  String learningWaitingCards(int count) {
    return '$count đang chờ';
  }

  @override
  String reviewDailyLimitReached(int count) {
    return 'Đã đạt giới hạn hàng ngày. Còn $count thẻ nữa.';
  }

  @override
  String reviewContinueCards(int count) {
    return 'Tiếp tục với $count thẻ nữa';
  }

  @override
  String get progressDetailRecognition => 'Nhận dạng';

  @override
  String get progressDetailDrawing => 'Viết';

  @override
  String progressDetailStatus(int reps, int threshold) {
    return '$reps/$threshold';
  }

  @override
  String get progressDetailNotStarted => 'Chưa bắt đầu';

  @override
  String get progressDetailViewFull => 'Xem chi tiết';

  @override
  String get progressDetailComposita => 'Composita';

  @override
  String get settingsTheme => 'Giao diện';

  @override
  String get themeIndigo => 'Chàm';

  @override
  String get themeTeal => 'Ngọc lam';

  @override
  String get themeSakura => 'Sakura';

  @override
  String get themeForest => 'Rừng';

  @override
  String get themeAmber => 'Hổ phách';

  @override
  String get settingsBrightness => 'Độ sáng';

  @override
  String get themeAuto => 'Tự động';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get settingsRecognitionModel => 'Mô hình nhận dạng';

  @override
  String get modelStandard => 'Tiêu chuẩn (~3.000 kanji)';

  @override
  String get modelExtended => 'Mở rộng (~6.500 kanji)';

  @override
  String get modelSwitching => 'Đang chuyển mô hình...';

  @override
  String get modelSwitched => 'Đã chuyển mô hình nhận dạng';

  @override
  String modelSwitchFailed(String error) {
    return 'Không thể chuyển mô hình: $error';
  }
}
