// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'kanjitomo';

  @override
  String failedToLoadAppData(String error) {
    return 'Gagal memuat data aplikasi: $error';
  }

  @override
  String get lookupTitle => '漢字友';

  @override
  String get lookupWords => 'Kata';

  @override
  String get lookupLearn => 'Belajar';

  @override
  String get lookupBrowse => 'Jelajah';

  @override
  String get lookupHelp => 'Bantuan';

  @override
  String get lookupHeading => 'Kanji';

  @override
  String get lookupClearDrawing => 'Hapus gambar';

  @override
  String get lookupRecognizing => 'Mengenali...';

  @override
  String get lookupLoadingModel => 'Memuat model...';

  @override
  String lookupModelFailed(String error) {
    return 'Model gagal dimuat: $error';
  }

  @override
  String get lookupBestMatch => 'Kecocokan terbaik:';

  @override
  String lookupTopN(int count) {
    return '$count teratas:';
  }

  @override
  String get lookupInCustomReview => 'Dalam ulasan khusus';

  @override
  String get lookupAddToCustomReview => 'Tambah ke ulasan khusus';

  @override
  String get wordLookupTitle => 'Cari kata';

  @override
  String get wordLookupDrawInstruction =>
      'Gambar kanji atau kana untuk menambahkannya ke kata:';

  @override
  String get wordLookupWordLabel => 'Kata';

  @override
  String get wordLookupClear => 'Hapus';

  @override
  String get wordLookupNoEntry => 'Tidak ada entri JMdict untuk kata ini.';

  @override
  String wordLookupCopied(String word) {
    return 'Menyalin \"$word\" ke papan klip';
  }

  @override
  String get copyToClipboard => 'Salin ke papan klip';

  @override
  String get learningTitle => 'Pembelajaran';

  @override
  String get learningJlpt => 'Mode JLPT';

  @override
  String get learningCustom => 'Mode khusus';

  @override
  String get learningReview => 'Ulasan';

  @override
  String get learningSelect => 'Pilih';

  @override
  String get learningSettings => 'Pengaturan';

  @override
  String get learningStatistics => 'Statistik';

  @override
  String get helpTitle => 'Bantuan & Tentang';

  @override
  String get helpTagline => 'Alat belajar kanji untuk pembelajar serius';

  @override
  String get helpFeaturesSection => 'Fitur unggulan';

  @override
  String get helpFeatureRecognitionTitle => 'Pengenalan Tulisan Tangan';

  @override
  String get helpFeatureRecognitionDesc =>
      'Gambar kanji apa pun untuk pengenalan offline instan — jaringan saraf, 6.500+ karakter.';

  @override
  String get helpFeatureSrsTitle => 'Pengulangan Berjarak (SRS)';

  @override
  String get helpFeatureSrsDesc =>
      'Gambar kanji dari ingatan, tidak hanya mengenalinya. Empat jenis kartu membangun kemampuan mengingat nyata melalui menulis aktif.';

  @override
  String get helpFeatureCompositaTitle => 'Composita & Kalimat';

  @override
  String get helpFeatureCompositaDesc =>
      'Anda memilih kata majemuk mana yang akan dipelajari. Pelajari kanji dalam konteks dengan 6.000+ kalimat contoh.';

  @override
  String get helpFeatureStrokeOrderTitle => 'Urutan Goresan';

  @override
  String get helpFeatureStrokeOrderDesc =>
      'Diagram goresan animasi langkah demi langkah dengan kanvas latihan untuk setiap kanji.';

  @override
  String get helpFeatureDictionaryTitle => 'Kamus';

  @override
  String get helpFeatureDictionaryDesc =>
      '60.000+ kata dari JMdict. Gambar untuk mencari kanji tunggal atau susun kata karakter demi karakter.';

  @override
  String get helpFeatureStoriesTitle => 'Kata Kunci & Cerita';

  @override
  String get helpFeatureStoriesDesc =>
      'Tambahkan mnemonik dan kata kunci Anda sendiri ke setiap kanji agar lebih mudah diingat.';

  @override
  String get helpSettingsSection => 'Pengaturan';

  @override
  String get helpAcknowledgement =>
      'Kanjitomo tidak akan mungkin ada tanpa proyek sumber terbuka dan kumpulan data luar biasa ini:';

  @override
  String get helpOpenSourceLicenses => 'Semua lisensi';

  @override
  String get jlptEditTitle => 'Edit cakupan JLPT';

  @override
  String get jlptEditLevels => 'Level JLPT';

  @override
  String jlptEditKanjiInScope(int count) {
    return '$count kanji dalam cakupan';
  }

  @override
  String get jlptEditCompositaCeiling => 'Batas composita/kalimat';

  @override
  String get jlptEditCompositaCeilingDescription =>
      'Level tersulit yang diperbolehkan untuk kata composita, terlepas dari level kanji yang dipilih di atas. Matikan untuk melewati pengujian composita/kalimat sepenuhnya untuk cakupan ini.';

  @override
  String get jlptEditCeilingOff => 'Mati';

  @override
  String get customEditTitle => 'Edit set khusus';

  @override
  String get customEditClear => 'Hapus';

  @override
  String get customEditDrawInstruction =>
      'Gambar kanji untuk menambahkannya ke set Anda:';

  @override
  String get customEditSetEmpty => 'Set khusus Anda kosong.';

  @override
  String get customEditSetInstruction =>
      'Set khusus Anda (ketuk untuk edit, tahan untuk hapus):';

  @override
  String customEditIsKana(String char) {
    return '$char adalah kana, bukan kanji';
  }

  @override
  String customEditAlreadyInSet(String char) {
    return '$char sudah ada di set Anda';
  }

  @override
  String customEditAdded(String char) {
    return '$char ditambahkan ke set Anda';
  }

  @override
  String customEditRemoveDialogTitle(String char) {
    return 'Hapus $char?';
  }

  @override
  String customEditRemoveDialogContent(String char) {
    return 'Hapus $char dari set khusus Anda?';
  }

  @override
  String get dialogRemove => 'Hapus';

  @override
  String get customEditClearDialogTitle => 'Kosongkan set khusus?';

  @override
  String customEditClearDialogContent(int count) {
    return 'Ini menghapus semua $count kanji dari set khusus Anda. Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get dialogCancel => 'Batal';

  @override
  String get dialogClear => 'Kosongkan';

  @override
  String compositaPickerTitle(String character) {
    return '$character: Composita';
  }

  @override
  String get compositaPickerDescription =>
      'Hanya kata yang dicentang di sini yang digunakan untuk pengujian composita/kalimat — berbeda dengan mode JLPT, mode khusus tidak memiliki batas level, jadi tidak ada yang diuji sampai Anda memilih kata di bawah.';

  @override
  String get compositaPickerEmpty =>
      'Tidak ada composita ditemukan untuk kanji ini.';

  @override
  String get customEditAddByKanji => 'Tambah kanji';

  @override
  String get customEditAddByWord => 'Tambah composita';

  @override
  String get compositaPickerSearchHint => 'Cari kata di JMdict...';

  @override
  String get compositaPickerDrawButton => 'Composita tambahan';

  @override
  String compositaPickerDrawTitle(String char) {
    return 'Gambar composita untuk $char';
  }

  @override
  String get compositaPickerAdd => 'Tambah';

  @override
  String compositaPickerAdded(String word) {
    return '$word ditambahkan';
  }

  @override
  String get compositaPickerNoResults => 'Tidak ada kata yang cocok.';

  @override
  String compositaPickerWordNotForChar(String char) {
    return 'Kata ini tidak mengandung $char';
  }

  @override
  String get wordLookupAddToReview => 'Tambah ke ulasan';

  @override
  String wordLookupAddedToReview(String word) {
    return '$word ditambahkan untuk ulasan';
  }

  @override
  String wordLookupPickKanjiTitle(String word) {
    return 'Tambahkan $word untuk kanji yang mana?';
  }

  @override
  String get wordLookupPickKanjiConfirm => 'Tambah';

  @override
  String get wordLookupAlreadyInReview => 'Sudah dalam ulasan';

  @override
  String get wordLookupClearWord => 'Hapus kata';

  @override
  String get kanjiBrowserTitle => 'Penjelajah kanji';

  @override
  String get kanjiBrowserSearchLabel =>
      'Cari berdasarkan bacaan, arti, atau jumlah goresan';

  @override
  String get kanjiBrowserNoMatch => 'Tidak ada kanji yang cocok.';

  @override
  String get kanjiBrowserColumnKanji => 'Kanji';

  @override
  String get kanjiBrowserColumnMeaning => 'Arti';

  @override
  String get kanjiBrowserColumnKeyword => 'Kata kunci';

  @override
  String get kanjiBrowserColumnReadings => 'Bacaan';

  @override
  String get kanjiBrowserColumnStrokes => 'Goresan';

  @override
  String get kanjiDetailNoDictionaryEntry =>
      'Tidak ada entri kamus (kana tidak tercakup dalam kamus kanji yang dibundel aplikasi ini).';

  @override
  String get kanjiDetailOnyomi => 'On\'yomi';

  @override
  String get kanjiDetailKunyomi => 'Kun\'yomi';

  @override
  String get kanjiDetailMeaning => 'Arti';

  @override
  String get kanjiDetailStrokeOrder => 'Urutan goresan';

  @override
  String get kanjiDetailKeyword => 'Kata kunci';

  @override
  String get kanjiDetailKeywordHint =>
      'Petunjuk singkat untuk mengingat (ditampilkan sebelum Anda menggambar)...';

  @override
  String get kanjiDetailStory => 'Cerita';

  @override
  String get kanjiDetailStoryHint =>
      'Tulis mnemonik atau cerita Anda sendiri untuk kanji ini...';

  @override
  String get kanjiDetailComposita => 'Composita';

  @override
  String get kanjiDetailExampleSentences => 'Kalimat contoh';

  @override
  String kanjiDetailCopied(String character) {
    return 'Menyalin \"$character\" ke papan klip';
  }

  @override
  String get reviewTitle => 'Ulasan';

  @override
  String reviewHeader(int done, int total) {
    return 'Ulasan — $done/$total';
  }

  @override
  String reviewHeaderNew(int done, int total) {
    return 'Ulasan — $done/$total — Baru';
  }

  @override
  String get reviewNoCardsDue => 'Tidak ada kartu yang jatuh tempo saat ini.';

  @override
  String reviewLearnMore(int count) {
    return 'Pelajari $count lagi';
  }

  @override
  String reviewMoreAvailable(int count) {
    return '$count lagi tersedia';
  }

  @override
  String get reviewLearnMoreButton => 'Pelajari lagi';

  @override
  String get reviewReturnButton => 'Kembali';

  @override
  String get reviewCorrect => 'Benar!';

  @override
  String reviewAnswer(String character) {
    return 'Jawaban: $character';
  }

  @override
  String reviewYouPicked(String character) {
    return 'Anda memilih: $character';
  }

  @override
  String get reviewContinue => 'Lanjut';

  @override
  String get reviewShowDetails => 'Tampilkan detail';

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
    return 'Arti: $meanings';
  }

  @override
  String reviewKeyword(String keyword) {
    return 'Kata kunci: $keyword';
  }

  @override
  String get reviewDrawFromMeaningPrompt => 'Gambar kanji ini dari ingatan:';

  @override
  String get reviewDontKnow => 'Tidak tahu';

  @override
  String get reviewKanjiRecognitionPrompt => 'Apa bacaan dan arti kanji ini?';

  @override
  String get reviewReveal => 'Tampilkan';

  @override
  String get reviewAgain => 'Lagi';

  @override
  String get reviewGood => 'Bagus';

  @override
  String get reviewShowTranslation => 'Tampilkan terjemahan';

  @override
  String get reviewHideTranslation => 'Sembunyikan terjemahan';

  @override
  String get reviewReadingClozePrompt => 'Apa bacaan kata yang disorot?';

  @override
  String reviewSlideshowTitle(int current, int total) {
    return 'Kanji baru ($current/$total)';
  }

  @override
  String get reviewSlideshowStartReview => 'Mulai ulasan';

  @override
  String get reviewSlideshowNext => 'Berikutnya';

  @override
  String get reviewStartTitle => 'Ulasan';

  @override
  String get reviewStartCurrentSelection => 'Pilihan saat ini';

  @override
  String reviewStartKanjiInScope(int count) {
    return '$count kanji dalam cakupan';
  }

  @override
  String get reviewStartCountingDue => 'Menghitung kartu jatuh tempo…';

  @override
  String reviewStartDueNow(int count) {
    return '$count fakta jatuh tempo sekarang';
  }

  @override
  String reviewStartSeen(int seen, int unseen) {
    return '$seen sudah dipelajari, $unseen baru';
  }

  @override
  String get reviewStartCustomSetEmpty => 'Set khusus (kosong)';

  @override
  String get reviewStartCustomSet => 'Set khusus';

  @override
  String reviewStartRtk(int index) {
    return 'RTK sampai $index';
  }

  @override
  String get reviewStartNothingSelected => 'Tidak ada yang dipilih';

  @override
  String get reviewStartNewKanjiPerDay => 'Kanji baru per hari:';

  @override
  String get reviewStartButton => 'Ulasan';

  @override
  String reviewStartPoolHeading(int count) {
    return 'Kumpulan belajar ($count)';
  }

  @override
  String get reviewContinueButton => 'Lanjutkan Ulasan';

  @override
  String reviewStartLearnNew(int count) {
    return 'Pelajari $count kanji baru';
  }

  @override
  String get reviewLeaveDialogTitle => 'Tinggalkan ulasan?';

  @override
  String get reviewLeaveDialogContent =>
      'Ulasan harian Anda belum selesai. Tetap tinggalkan?';

  @override
  String get reviewLeaveConfirm => 'Tinggalkan';

  @override
  String get statisticsTitle => 'Statistik';

  @override
  String get statisticsKanjiRecognition => 'Pengenalan kanji';

  @override
  String get statisticsDrawFromMeaning => 'Gambar dari arti';

  @override
  String get statisticsReadingCloze => 'Bacaan (composita/kalimat)';

  @override
  String get statisticsDrawInSentence =>
      'Gambar dalam kalimat (composita/kalimat)';

  @override
  String get statisticsKnown => 'Lulus';

  @override
  String get statisticsMissed => 'Sedang dipelajari';

  @override
  String get statisticsNotStarted => 'Belum dimulai';

  @override
  String get statisticsCompositaTitle => 'Pengujian composita/kalimat';

  @override
  String statisticsTestableWords(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'kata',
      one: 'kata',
    );
    return '$count $_temp0 yang dapat diuji dalam cakupan ini — tidak pernah menghalangi hijau, dilacak secara terpisah.';
  }

  @override
  String get statisticsReadingTested => 'Bacaan diuji';

  @override
  String get statisticsWritingTested => 'Tulisan diuji';

  @override
  String get statisticsInspectAllKanji => 'Periksa semua kanji';

  @override
  String statisticsLearnt(int count, int total) {
    return '$count / $total dipelajari';
  }

  @override
  String get statisticsResetButton => 'Reset statistik';

  @override
  String get statisticsResetDialogTitle => 'Reset statistik?';

  @override
  String get statisticsResetDialogContent =>
      'Ini menghapus semua progres ulasan (tanggal jatuh tempo, status diketahui/tidak diketahui, dan pengenalan kartu baru) untuk semua kanji. Anda akan memulai dari awal. Tindakan ini tidak dapat dibatalkan.';

  @override
  String get statisticsResetConfirm => 'Reset';

  @override
  String get undoStroke => 'Batalkan goresan';

  @override
  String get drawAndPickClearDrawing => 'Hapus gambar';

  @override
  String get drawAndPickRecognizing => 'Mengenali...';

  @override
  String get drawAndPickWhichOne => 'Yang mana yang Anda gambar?';

  @override
  String legendValuePercent(String label, int value, int percent) {
    return '$label: $value ($percent%)';
  }

  @override
  String compositaPieLabel(String label, int tested, int testable) {
    return '$label: $tested/$testable';
  }

  @override
  String get proPaywallTitle => 'Buka Pro';

  @override
  String get proPaywallDescription =>
      'Dapatkan akses ke semua level JLPT, set belajar khusus, pengujian composita, dan statistik.';

  @override
  String get proPaywallFeatureJlpt => 'Semua level JLPT (N1–N3)';

  @override
  String get proPaywallFeatureCustom => 'Set kanji khusus tanpa batas';

  @override
  String get proPaywallFeatureComposita => 'Pengujian composita & kalimat';

  @override
  String get proPaywallFeatureStats => 'Statistik terperinci';

  @override
  String proPaywallBuyButton(String price) {
    return 'Buka Pro — $price';
  }

  @override
  String get proPaywallRestore => 'Pulihkan Pembelian';

  @override
  String get proPaywallRestoring => 'Memulihkan...';

  @override
  String get proPaywallError => 'Pembelian gagal. Silakan coba lagi.';

  @override
  String get proPaywallRestoreSuccess => 'Pembelian dipulihkan!';

  @override
  String get proPaywallRestoreNothing =>
      'Tidak ada pembelian sebelumnya ditemukan.';

  @override
  String get proLevelLocked => 'Pro diperlukan untuk N1–N3';

  @override
  String get helpRestorePurchases => 'Pulihkan Pembelian';

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
    return 'Versi gratis dibatasi $limit kanji';
  }

  @override
  String get customEditAddElements => 'Tambah elemen';

  @override
  String get dueOverviewTitle => 'Ulasan mendatang';

  @override
  String get dueOverviewOverdue => 'Terlambat';

  @override
  String get dueOverviewToday => 'Hari ini';

  @override
  String get dueOverviewTomorrow => 'Besok';

  @override
  String get dueOverviewThisWeek => 'Minggu ini';

  @override
  String get dueOverviewLater => 'Nanti';

  @override
  String get dueOverviewNotStarted => 'Belum dimulai';

  @override
  String dueOverviewCompact(int tomorrow, int week, int later) {
    return 'Besok: $tomorrow · Minggu ini: $week · Nanti: $later';
  }

  @override
  String get learningQuiz => 'Kuis Gaya JLPT';

  @override
  String get quizStartTitle => 'Kuis';

  @override
  String get quizStartQuestionCount => 'Jumlah pertanyaan:';

  @override
  String get quizStartButton => 'Mulai Kuis';

  @override
  String quizProgress(int current, int total) {
    return 'Pertanyaan $current/$total';
  }

  @override
  String get quizPickReading => 'Apa bacaan kata yang disorot?';

  @override
  String get quizPickKanji => 'Kata mana yang cocok dalam kalimat?';

  @override
  String get quizCorrect => 'Benar!';

  @override
  String get quizWrong => 'Salah — jawabannya adalah:';

  @override
  String get quizNext => 'Berikutnya';

  @override
  String get quizResultTitle => 'Hasil Kuis';

  @override
  String quizResultScore(int correct, int total) {
    return '$correct/$total benar';
  }

  @override
  String get quizDone => 'Selesai';

  @override
  String get quizNotEnoughWords => 'Tidak cukup kata dalam cakupan untuk kuis.';

  @override
  String reviewStartBacklogInfo(int count) {
    return 'Anda memiliki $count kartu untuk diulas dari hari-hari sebelumnya.';
  }

  @override
  String get reviewStartReviewBacklog => 'Ulas tumpukan dulu';

  @override
  String reviewStartBacklogAndNew(int count) {
    return 'Juga pelajari $count kanji baru';
  }

  @override
  String reviewStartNewKanjiDialog(int dueCount, int newCount, int totalCount) {
    return 'Anda memiliki $dueCount kartu jatuh tempo untuk diulas. Ingin menambahkan $newCount kanji baru? Itu menghasilkan $totalCount fakta untuk diulas.';
  }

  @override
  String get reviewStartDialogYes => 'Ya';

  @override
  String get reviewStartDialogNo => 'Tidak';

  @override
  String reviewLearnMoreEstimate(int factCount) {
    return 'Itu menambahkan $factCount fakta baru';
  }

  @override
  String get reviewUndoTooltip => 'Ulangi kartu sebelumnya';

  @override
  String get jlptEditCompositaPerKanji => 'Kata composita per kanji';

  @override
  String get quizOnlySeenKanji => 'Hanya kuis kanji yang sudah dipelajari';

  @override
  String get reviewMaxBacklog => 'Tumpukan maksimum:';

  @override
  String get reviewMaxBacklogHint => '0 = tanpa batas';

  @override
  String get ftdLookupTitle => 'Gambar untuk mengenali';

  @override
  String get ftdLookupMessage =>
      'Gambar kanji apa pun di kanvas — jaringan saraf mengenalinya secara instan, bahkan dengan tulisan tangan yang berantakan. Mendukung 6.500+ karakter, sepenuhnya offline.\n\nKetuk hasil untuk melihat bacaan, arti, urutan goresan, kalimat contoh, dan kata majemuk.\n\nCoba sekarang — perkecil kartu ini dan gambar sesuatu!';

  @override
  String get ftdWordLookupTitle => 'Pencarian kata';

  @override
  String get ftdWordLookupMessage =>
      'Cari kata majemuk di kamus 60.000+ entri (JMdict). Gambar setiap karakter untuk menyusun kata, atau ketik langsung.\n\nPerkecil kartu ini untuk mencobanya!';

  @override
  String get ftdLearningTitle => 'Pembelajaran';

  @override
  String get ftdLearningMessage =>
      'Anda yang memutuskan apa yang dipelajari. Tambahkan kanji berdasarkan level JLPT atau pilih karakter individual secara manual. Pengulangan berjarak menguji Anda empat cara — termasuk menggambar dari ingatan, yang membangun kemampuan mengingat aktif yang tidak bisa ditandingi aplikasi pasif.\n\nLacak kemajuan Anda dengan statistik terperinci.';

  @override
  String get ftdBrowserTitle => 'Penjelajah kanji';

  @override
  String get ftdBrowserMessage =>
      'Jelajahi semua kanji Jōyō dalam tabel yang dapat dicari. Filter berdasarkan bacaan, arti, atau jumlah goresan. Ketuk kanji mana pun untuk melihat detailnya — dan pilih kata majemuk (composita) mana yang Anda inginkan dalam ulasan.\n\nTitik berwarna menunjukkan kemajuan ulasan Anda sekilas.';

  @override
  String get ftdReviewSessionTitle => 'Sesi ulasan';

  @override
  String get ftdReviewSessionMessage =>
      'Empat jenis kartu menguji aspek mengingat yang berbeda:\n• Gambar dari arti — lihat kata kunci, tulis kanji dari ingatan\n• Pengenalan kanji — lihat kanji, ingat bacaan dan artinya\n• Isian bacaan — baca kata majemuk dalam kalimat nyata\n• Gambar dalam kalimat — tulis kanji dalam konteks\n\nMenggambar dari ingatan lebih sulit daripada pilihan ganda — itulah intinya. Nilai diri Anda dengan Lagi (salah) atau Bagus (berhasil mengingat).';

  @override
  String get ftdGotIt => 'Mengerti';

  @override
  String get helpResetTips => 'Reset bantuan';

  @override
  String get helpResetTipsDone =>
      'Bantuan direset — tur selamat datang akan muncul lagi di lain waktu.';

  @override
  String get welcomeTitle => 'Selamat Datang di Kanjitomo';

  @override
  String get welcomeSubtitle => 'Alat belajar kanji untuk pembelajar serius';

  @override
  String get welcomeTakeTour => 'Ikuti tur';

  @override
  String get welcomeSkip => 'Lewati';

  @override
  String get welcomeDone => 'Mulai belajar!';

  @override
  String get tourNext => 'Berikutnya';

  @override
  String get tourBack => 'Kembali';

  @override
  String get welcomeDontShowAgain => 'Jangan tampilkan lagi';

  @override
  String get welcomeFeatureList =>
      'Gambar kanji dari ingatan untuk membangun kemampuan mengingat nyata — bukan sekadar pengenalan. Anda memilih apa yang dipelajari: pilih kanji, pilih kata majemuk, pilih tempo Anda. Offline, tanpa akun, tanpa pelacakan.';

  @override
  String get helpReviewStart =>
      'Ulasan menggunakan pengulangan berjarak (SM-2) untuk menjadwalkan kartu dengan interval yang meningkat.\n\nEmpat jenis kartu menguji Anda:\n• Gambar dari arti — lihat artinya, gambar kanji-nya\n• Pengenalan kanji — lihat kanji-nya, ingat bacaannya\n• Isian bacaan — baca kata dalam kalimat\n• Gambar dalam kalimat — gambar kanji dalam konteks\n\nKartu baru per hari dan ulasan maksimum per hari diatur di pusat pembelajaran. Ulasan selalu diprioritaskan; kartu baru mengisi sisa anggaran harian. Gunakan \"Pelajari lagi\" dalam sesi untuk menambah kartu ekstra melampaui batas harian.\n\nNilai diri Anda: Lagi (lupa) atau Bagus (berhasil mengingat). Kartu muncul kembali setelah minimal 1 hari, dengan interval yang bertambah seiring keberhasilan Anda.\n\nAnda dapat menambahkan kata kunci dan cerita (mnemonik) pribadi untuk setiap kanji. Ketuk kanji mana pun di penjelajah atau selama ulasan untuk mengeditnya. Kata kunci Anda ditampilkan saat kartu gambar-dari-arti; cerita Anda muncul saat Anda menampilkan jawaban. Ini membantu Anda membangun asosiasi yang mudah diingat antara bentuk, arti, dan komponen kanji.';

  @override
  String get helpJlptEdit =>
      'Pilih satu atau lebih level JLPT. Semua kanji dari level yang dipilih digabungkan ke dalam cakupan belajar Anda.\n\nBatas composita mengontrol kata kosakata mana yang diuji:\n• Mati — tidak ada pengujian kata/kalimat, hanya kanji saja\n• N5–N1 — hanya menguji kata pada atau lebih mudah dari level ini\nBatas ini tidak tergantung pada level kanji (mis. pelajari kanji N3 dengan kata N5 saja).\n\nKanji baru/hari: berapa karakter baru yang diperkenalkan setiap hari (default 10).\n\nTumpukan maksimum: batas opsional berapa kartu jatuh tempo yang bisa menumpuk sebelum kanji baru berhenti diperkenalkan. Atur ke 0 untuk menonaktifkan batas.\n\nComposita/kanji: berapa kata per karakter yang diuji (2–5, default 4).\n\nPerubahan level langsung berlaku. Progres ulasan dibagi antara mode JLPT dan mode Khusus — kanji yang diulas di satu mode dihitung sebagai sudah diulas di mode lainnya.';

  @override
  String get helpCustomEdit =>
      'Buat daftar belajar Anda sendiri dengan menggambar kanji satu per satu.\n\nKetuk kanji untuk memilih kata kosakata (composita) mana yang akan diuji. Berbeda dengan mode JLPT, tidak ada yang otomatis dimasukkan — Anda secara eksplisit memilih setiap kata.\n\nTahan lama kanji untuk menghapusnya dari daftar Anda.\n\nProgres ulasan dibagi antara mode JLPT dan mode Khusus — kanji yang diulas di satu mode dihitung sebagai sudah diulas di mode lainnya.';

  @override
  String get helpQuiz =>
      'Kuis adalah tes mandiri pilihan ganda yang cepat. Tidak berpengaruh pada progres pengulangan berjarak Anda.\n\nDua jenis pertanyaan dicampur secara acak:\n• Kanji → Bacaan: kalimat dengan kanji yang disorot; pilih bacaannya\n• Bacaan → Kanji: kalimat dengan bacaan yang ditampilkan; pilih kata kanji yang sesuai\n\nHanya kanji yang sudah pernah Anda ulas yang diikutsertakan.';

  @override
  String get helpStatistics =>
      'Statistik menunjukkan kemajuan Anda untuk cakupan belajar saat ini.\n\nRingkasan jatuh tempo: berapa kartu yang terlambat, jatuh tempo hari ini, besok, minggu ini, atau nanti.\n\nPer jenis kartu (gambar, pengenalan, isian bacaan, gambar dalam kalimat):\n• Lulus (hijau): dijawab dengan benar 2 kali berturut-turut\n• Sedang dipelajari (oranye): sudah diulas tapi belum mencapai 2 jawaban benar berturut-turut\n• Belum dimulai (abu-abu): belum pernah diulas\n\nJawaban salah mengatur ulang hitungan ke nol — Anda perlu 2 jawaban benar berturut-turut lagi.\n\nGrid kanji: setiap kanji menampilkan titik berwarna.\n• Titik pertama — progres inti: hijau (bacaan dan tulisan keduanya lulus), oranye (setidaknya satu arah dimulai), abu-abu (belum diulas)\n• Titik kedua — progres composita (hanya ditampilkan jika karakter memiliki kata composita yang bisa diuji): hijau (semua kata diuji di kedua arah), oranye (setidaknya satu diuji), abu-abu (tidak ada yang diuji)\n\nCakupan composita menunjukkan berapa kata yang memenuhi syarat telah diuji setidaknya sekali untuk bacaan dan tulisan.\n\nGunakan tombol reset di bagian bawah untuk menghapus semua progres ulasan dan memulai dari awal.';

  @override
  String get helpLearning =>
      'Ini adalah pusat pembelajaran Anda untuk mengelola belajar kanji.\n\nUlasan: Mulai sesi pengulangan berjarak dengan kartu jatuh tempo Anda.\n\nKuis: Tes mandiri pilihan ganda (tidak berpengaruh pada progres ulasan).\n\nTambah/Hapus: Tambahkan kanji berdasarkan level JLPT, urutan RTK, atau menggambar. Kelola kumpulan belajar, pengaturan composita, dan kanji individual.\n\nStatistik: Lihat kemajuan Anda per jenis kartu, cakupan composita, dan grid kanji dengan titik berwarna.\n\n── Pengaturan ──\n\nKartu baru/hari: Berapa kartu yang belum pernah dilihat yang diperkenalkan per hari. Ini adalah kanji yang Anda tambahkan tapi belum diulas.\n\nUlasan maks/hari: Anggaran harian total untuk semua kartu — baik ulasan kartu yang sudah pernah dilihat maupun kartu baru digabungkan. Ulasan selalu diprioritaskan; kartu baru mengisi kapasitas yang tersisa.\n\nContoh: Dengan Baru=30 dan Maks=200, jika Anda memiliki 120 ulasan jatuh tempo dan sudah menyelesaikan 50 hari ini:\n• Sisa anggaran harian: 200 − 50 = 150\n• Ulasan jatuh tempo: 120 (semua muat dalam 150)\n• Sisa untuk kartu baru: 150 − 120 = 30\n• Total sesi: 150 kartu\n\nJika ulasan jatuh tempo saja melebihi batas maks (mis. 250 jatuh tempo, maks 200), hanya 200 ulasan yang ditampilkan dan tidak ada kartu baru — mengejar ulasan lebih diutamakan.\n\nAtur salah satu nilai ke 0 untuk tanpa batas.';

  @override
  String get helpSupportDevelopment => 'Dukung pengembangan';

  @override
  String get helpSupportDescription =>
      'Kanjitomo gratis dan akan selalu gratis. Jika Anda merasa berguna, pertimbangkan untuk mentraktir kami kopi!';

  @override
  String get helpReportBug => 'Laporkan bug';

  @override
  String get helpReportBugDescription =>
      'Menemukan masalah? Kirim email kepada kami dan kami akan memeriksanya.';

  @override
  String get helpBugEmailSubject => 'Laporan bug Kanjitomo';

  @override
  String get helpPrivacyPolicy => 'Kebijakan privasi';

  @override
  String get learningPoolStats => 'Kumpulan belajar Anda';

  @override
  String learningKanjiCount(int count) {
    return '$count kanji dalam kumpulan';
  }

  @override
  String learningSeen(int seen) {
    return '$seen sudah dipelajari';
  }

  @override
  String learningDue(int due) {
    return '$due kartu jatuh tempo';
  }

  @override
  String get learningAddRemove => 'Tambah/Hapus';

  @override
  String learningQuickAddJlpt(int count, int level) {
    return '+$count JLPT N$level';
  }

  @override
  String learningQuickAddRtk(int count) {
    return '+$count RTK';
  }

  @override
  String get learningQuickAddHint =>
      'Pintasan — menambahkan kanji dalam urutan RTK.';

  @override
  String get learningDetailedAdd => 'Tambah / Hapus (terperinci)';

  @override
  String get addRemoveBrowseTab => 'Jelajah';

  @override
  String get addRemoveBrowseHelp =>
      'Ketuk + untuk menambahkan kanji ke kumpulan belajar Anda. Kanji yang sudah ada di kumpulan Anda menampilkan tanda centang.';

  @override
  String get addRemoveTitle => 'Tambah / Hapus kanji';

  @override
  String get addRemoveAddByJlpt => 'Tambah berdasarkan level JLPT';

  @override
  String get addRemoveJlptHelp =>
      'Tambahkan kanji yang dikelompokkan berdasarkan level JLPT (N5 = termudah, N1 = tersulit). Pilih level dan berapa banyak yang akan ditambahkan — mereka akan ditambahkan dalam urutan Heisig (RTK) untuk menghafal yang efisien. Kata majemuk dipilih otomatis berdasarkan pengaturan Anda di bawah.';

  @override
  String get addRemoveKanjiCount => 'Jumlah kanji';

  @override
  String get addRemoveAddTip =>
      'Tip: Tambahkan hanya beberapa kanji baru setiap hari untuk retensi terbaik.';

  @override
  String get addRemoveAddJlptButton => 'Tambah kanji JLPT';

  @override
  String get addRemoveAddByRtk => 'Tambah berdasarkan urutan RTK';

  @override
  String get addRemoveRtkHelp =>
      'Tambahkan kanji dalam urutan Remembering the Kanji (RTK) Heisig, terlepas dari level JLPT. Baik jika Anda mengikuti buku RTK atau ingin mempelajari kanji berdasarkan komponen yang sama.';

  @override
  String get addRemoveAddRtkButton => 'Tambah kanji RTK';

  @override
  String get addRemoveDrawToAdd => 'Tambah dengan menggambar';

  @override
  String get addRemoveDrawHelp =>
      'Gambar kanji apa pun untuk menambahkannya ke kumpulan belajar Anda. Berguna untuk menambahkan karakter tertentu yang Anda temui. Kata majemuk dipilih otomatis berdasarkan pengaturan Anda di bawah.';

  @override
  String get addRemoveCompositaSettings => 'Pengaturan composita';

  @override
  String get addRemoveCompositaCeiling => 'Batas level kosakata';

  @override
  String get addRemoveCompositaCeilingHelp =>
      'Membatasi kata majemuk mana yang dipilih otomatis saat menambahkan kanji. Level sebuah kata ditentukan oleh kanji tersulit-nya (mis. 胃腸 adalah N1 karena 腸 adalah N1, meskipun 胃 adalah N3). Atur ke N2 dan 胃腸 tidak akan dipilih otomatis, tetapi 胃袋 (N2) akan dipilih. Anda selalu bisa menambahkan kata apa pun secara manual melalui pemilih composita. \"Mati\" mengizinkan semua level.';

  @override
  String get addRemoveCeilingOff => 'Mati';

  @override
  String get addRemoveMaxComposita => 'Kata per kanji';

  @override
  String get addRemoveMaxCompositaHelp =>
      'Berapa kata majemuk yang dipilih otomatis per kanji untuk ulasan. Lebih banyak kata berarti lebih banyak variasi tetapi juga lebih banyak kartu untuk diulas.';

  @override
  String get addRemovePoolSortRtk => 'Urutan RTK';

  @override
  String get addRemovePoolSortAdded => 'Tanggal ditambahkan';

  @override
  String get addRemovePoolSortModified => 'Terakhir diubah';

  @override
  String get addRemovePoolSortMastery => 'Penguasaan';

  @override
  String addRemovePoolTitle(int count) {
    return 'Kumpulan belajar ($count)';
  }

  @override
  String get addRemovePoolEmpty => 'Belum ada kanji di kumpulan belajar Anda.';

  @override
  String get addRemovePoolTip =>
      'Ketuk kanji untuk mengedit composita, cerita, atau kata kuncinya. Tahan lama untuk menghapus.';

  @override
  String get addRemovePoolSearch => 'Cari kumpulan';

  @override
  String get addRemoveClearAll => 'Hapus semua';

  @override
  String get addRemoveConfirmClearTitle => 'Kosongkan kumpulan belajar?';

  @override
  String addRemoveConfirmClearContent(int count) {
    return 'Hapus semua $count kanji dan hapus semua progres ulasan? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get addRemoveClearSecondConfirm =>
      'Semua progres ulasan akan hilang secara permanen. Kata kunci dan cerita Anda tetap disimpan.';

  @override
  String get addRemoveConfirmRemoveTitle => 'Hapus kanji?';

  @override
  String addRemoveConfirmRemoveContent(String char) {
    return 'Hapus $char dan hapus semua progres ulasan untuknya? Tindakan ini tidak dapat dibatalkan.';
  }

  @override
  String get addRemoveRemoveButton => 'Hapus';

  @override
  String addRemoveAlreadyInPool(String char) {
    return '$char sudah ada di kumpulan belajar Anda.';
  }

  @override
  String addRemoveSlideshowTitle(int current, int total) {
    return 'Kanji baru ($current/$total)';
  }

  @override
  String get addRemoveSlideshowComposita => 'Composita terpilih:';

  @override
  String get addRemoveSlideshowNext => 'Berikutnya';

  @override
  String get addRemoveSlideshowDone => 'Selesai';

  @override
  String get kanjiDetailEditComposita => 'Edit composita';

  @override
  String get kanjiDetailAddToLearning => 'Tambah ke pembelajaran';

  @override
  String get learningNewCardsPerDay => 'Kartu baru/hari:';

  @override
  String get learningMaxReviewsPerDay => 'Ulasan maks/hari:';

  @override
  String learningWaitingCards(int count) {
    return '$count menunggu';
  }

  @override
  String reviewDailyLimitReached(int count) {
    return 'Batas harian tercapai. $count kartu lagi tersedia.';
  }

  @override
  String reviewContinueCards(int count) {
    return 'Lanjutkan dengan $count lagi';
  }

  @override
  String get progressDetailRecognition => 'Pengenalan';

  @override
  String get progressDetailDrawing => 'Menggambar';

  @override
  String progressDetailStatus(int reps, int threshold) {
    return '$reps/$threshold';
  }

  @override
  String get progressDetailNotStarted => 'Belum dimulai';

  @override
  String get progressDetailViewFull => 'Lihat detail';

  @override
  String get progressDetailComposita => 'Composita';

  @override
  String get settingsTheme => 'Tema';

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
  String get settingsBrightness => 'Kecerahan';

  @override
  String get themeAuto => 'Otomatis';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get settingsRecognitionModel => 'Model pengenalan';

  @override
  String get modelStandard => 'Standar (~3.000 kanji)';

  @override
  String get modelExtended => 'Diperluas (~6.500 kanji)';

  @override
  String get modelSwitching => 'Mengganti model...';

  @override
  String get modelSwitched => 'Model pengenalan diganti';

  @override
  String modelSwitchFailed(String error) {
    return 'Gagal mengganti model: $error';
  }
}
