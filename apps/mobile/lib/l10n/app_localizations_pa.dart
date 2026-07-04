// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Panjabi Punjabi (`pa`).
class AppLocalizationsPa extends AppLocalizations {
  AppLocalizationsPa([String locale = 'pa']) : super(locale);

  @override
  String get appTitle => 'RemiMinder';

  @override
  String get login => 'ਲਾਗਿਨ';

  @override
  String get logout => 'ਲਾਗਆਉਟ';

  @override
  String get settings => 'ਸੈਟਿੰਗਾਂ';

  @override
  String get language => 'ਭਾਸ਼ਾ';

  @override
  String get profileSettings => 'ਪ੍ਰੋਫਾਈਲ ਸੈਟਿੰਗਾਂ';

  @override
  String get languageSettings => 'ਭਾਸ਼ਾ ਸੈਟਿੰਗਾਂ';

  @override
  String languageUpdated(String language) {
    return 'ਭਾਸ਼ਾ ਅੱਪਡੇਟ ਕੀਤੀ ਗਈ। ਐਪ ਹੁਣ ਵਿੱਚ ਪ੍ਰਦਰਸ਼ਿਤ ਹੋਵੇਗਾ$language.';
  }

  @override
  String get navHome => 'ਘਰ';

  @override
  String get navVisits => 'ਮੁਲਾਕਾਤਾਂ';

  @override
  String get navOverview => 'ਸੰਖੇਪ ਜਾਣਕਾਰੀ';

  @override
  String get navCareTeam => 'ਕੇਅਰ ਟੀਮ';

  @override
  String get navProfile => 'ਪ੍ਰੋਫਾਈਲ';

  @override
  String get navPatients => 'ਮਰੀਜ਼';

  @override
  String get goodMorning => 'ਸ਼ੁਭ ਸਵੇਰ';

  @override
  String get goodAfternoon => 'ਨਮਸਕਾਰ';

  @override
  String get goodEvening => 'ਸਤ ਸ੍ਰੀ ਅਕਾਲ';

  @override
  String get goodNight => 'ਸ਼ੁਭ ਰਾਤ';

  @override
  String get howAreYouFeeling => 'ਤੁਸੀਂ ਅੱਜ ਕਿਵੇਂ ਮਹਿਸੂਸ ਕਰ ਰਹੇ ਹੋ?';

  @override
  String get todaysProgress => 'ਅੱਜ ਦੀ ਤਰੱਕੀ';

  @override
  String doneCount(int done, int total) {
    return '$done/$totalਕੀਤਾ';
  }

  @override
  String get yourSchedule => 'ਤੁਹਾਡਾ ਅਨੁਸੂਚੀ';

  @override
  String get seeAll => 'ਸਭ ਦੇਖੋ →';

  @override
  String get nothingScheduledYet => 'ਹਾਲੇ ਕੁਝ ਵੀ ਨਿਯਤ ਨਹੀਂ ਕੀਤਾ ਗਿਆ ਹੈ';

  @override
  String get unableToLoadReminders => 'ਰੀਮਾਈਂਡਰ ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਮਰੱਥ';

  @override
  String get addReminder => 'ਰੀਮਾਈਂਡਰ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get myTasks => 'ਮੇਰੇ ਕਾਰਜ';

  @override
  String pendingCount(int count) {
    return '$countਬਕਾਇਆ';
  }

  @override
  String get noTasksYet => 'ਅਜੇ ਕੋਈ ਕਾਰਜ ਨਹੀਂ';

  @override
  String get addTask => 'ਕਾਰਜ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get statusUpcoming => 'ਆਗਾਮੀ';

  @override
  String get statusScheduled => 'ਤਹਿ ਕੀਤਾ';

  @override
  String get statusDone => 'ਹੋ ਗਿਆ';

  @override
  String get reminder => 'ਰੀਮਾਈਂਡਰ';

  @override
  String get task => 'ਟਾਸਕ';

  @override
  String get careTeamTitle => 'ਕੇਅਰ ਟੀਮ';

  @override
  String get careTeamSubtitle =>
      'ਤੁਸੀਂ ਕੰਟਰੋਲ ਵਿੱਚ ਹੋ। ਹੇਠਾਂ ਆਪਣੀਆਂ ਸਾਂਝਾਕਰਨ ਅਨੁਮਤੀਆਂ ਦੀ ਸਮੀਖਿਆ ਕਰੋ।';

  @override
  String get sectionPending => 'ਬਕਾਇਆ';

  @override
  String get sectionAddNew => 'ਨਵਾਂ ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get inviteCaregiver => 'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਨੂੰ ਸੱਦਾ ਦਿਓ';

  @override
  String get inviteCaregiverSubtitle => 'ਆਪਣੀ ਸਿਹਤ ਜਾਣਕਾਰੀ ਤੱਕ ਪਹੁੰਚ ਸਾਂਝੀ ਕਰੋ';

  @override
  String get invitationPending => 'ਸੱਦਾ ਬਕਾਇਆ';

  @override
  String get resend => 'ਦੁਬਾਰਾ ਭੇਜੋ';

  @override
  String get cancel => 'ਰੱਦ ਕਰੋ';

  @override
  String get activeCaregivers => 'ਸਰਗਰਮ ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ';

  @override
  String get noCaregiversYet =>
      'ਅਜੇ ਤੱਕ ਕੋਈ ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਸ਼ਾਮਲ ਨਹੀਂ ਕੀਤੇ ਗਏ ਹਨ';

  @override
  String get english => 'ਅੰਗਰੇਜ਼ੀ';

  @override
  String get spanish => 'ਸਪੇਨੀ';

  @override
  String get hindi => 'ਹਿੰਦੀ';

  @override
  String get french => 'ਫ੍ਰੈਂਚ';

  @override
  String get portuguese => 'ਪੁਰਤਗਾਲੀ';

  @override
  String get german => 'ਜਰਮਨ';

  @override
  String get bangla => 'ਬੰਗਲਾ';

  @override
  String get tamil => 'ਤਾਮਿਲ';

  @override
  String get gujarati => 'ગુજરાતી';

  @override
  String get punjabi => 'ਪੰਜਾਬੀ';

  @override
  String get accountDetails => 'ਖਾਤੇ ਦੇ ਵੇਰਵੇ';

  @override
  String get accountDetailsSubtitle => 'ਆਪਣੀ ਪ੍ਰੋਫਾਈਲ ਜਾਣਕਾਰੀ ਦੇਖੋ';

  @override
  String get accountSecurity => 'ਖਾਤਾ ਸੁਰੱਖਿਆ';

  @override
  String get accountSecuritySubtitle => 'ਪਾਸਵਰਡ ਅਤੇ ਗੋਪਨੀਯਤਾ ਦਾ ਪ੍ਰਬੰਧਨ ਕਰੋ';

  @override
  String get notificationsLabel => 'ਸੂਚਨਾਵਾਂ';

  @override
  String get mobileLabel => 'ਮੋਬਾਈਲ';

  @override
  String get emailLabel => 'ਈਮੇਲ';

  @override
  String get upgrade => 'ਅੱਪਗ੍ਰੇਡ ਕਰੋ';

  @override
  String get signOut => 'ਸਾਇਨ ਆਉਟ';

  @override
  String get deleteAccount => 'ਖਾਤਾ ਮਿਟਾਓ';

  @override
  String get deleteAccountTitle => 'ਖਾਤਾ ਮਿਟਾਓ';

  @override
  String get deleteAccountMessage =>
      'ਇਹ ਤੁਹਾਡੇ ਖਾਤੇ ਅਤੇ ਤੁਹਾਡੇ ਸਾਰੇ ਡੇਟਾ ਨੂੰ ਸਥਾਈ ਤੌਰ \'ਤੇ ਮਿਟਾ ਦੇਵੇਗਾ। ਇਸਨੂੰ ਅਣਕੀਤਾ ਨਹੀਂ ਕੀਤਾ ਜਾ ਸਕਦਾ। ਤੁਹਾਨੂੰ ਪੂਰਾ ਵਿਸ਼ਵਾਸ ਹੈ?';

  @override
  String get delete => 'ਮਿਟਾਓ';

  @override
  String get searchSummariesHint => 'ਸੰਖੇਪ ਖੋਜੋ...';

  @override
  String get tabSummaries => 'ਸੰਖੇਪ';

  @override
  String get tabLabResults => 'ਲੈਬ ਨਤੀਜੇ';

  @override
  String get tabScannedDocs => 'ਸਕੈਨ ਕੀਤੇ ਡੌਕਸ';

  @override
  String get noSummariesYet => 'ਅਜੇ ਕੋਈ ਸਾਰਾਂਸ਼ ਨਹੀਂ';

  @override
  String get summariesWillAppearHere => 'ਤੁਹਾਡੇ ਦੌਰੇ ਦੇ ਸੰਖੇਪ ਇੱਥੇ ਦਿਖਾਈ ਦੇਣਗੇ';

  @override
  String get failedToLoadSummaries => 'ਸਾਰਾਂਸ਼ਾਂ ਨੂੰ ਲੋਡ ਕਰਨਾ ਅਸਫਲ ਰਿਹਾ';

  @override
  String get retry => 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get shareLabel => 'ਸ਼ੇਅਰ ਕਰੋ';

  @override
  String get doctorVisit => 'ਡਾਕਟਰ ਦੀ ਮੁਲਾਕਾਤ';

  @override
  String timeToday(String time) {
    return 'ਅੱਜ,$time';
  }

  @override
  String timeYesterday(String time) {
    return 'ਕੱਲ੍ਹ,$time';
  }

  @override
  String get summaryProcessingHint =>
      'ਤਾਜ਼ਾ ਕਰਨ ਲਈ ਹੇਠਾਂ ਖਿੱਚੋ। ਇਸ ਵਿੱਚ ਆਮ ਤੌਰ \'ਤੇ 30-60 ਸਕਿੰਟ ਲੱਗਦੇ ਹਨ।';

  @override
  String get summaryCouldNotGenerate => 'ਸਾਰਾਂਸ਼ ਤਿਆਰ ਨਹੀਂ ਕੀਤਾ ਜਾ ਸਕਿਆ';

  @override
  String get retrySummary => 'ਸੰਖੇਪ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get stuckRetrySummary => 'ਫਸਿਆ? ਸੰਖੇਪ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get scannedDocument => 'ਸਕੈਨ ਕੀਤਾ ਦਸਤਾਵੇਜ਼';

  @override
  String scannedOn(String date) {
    return 'ਸਕੈਨ ਕੀਤਾ$date';
  }

  @override
  String get visitDetails => 'ਵੇਰਵਿਆਂ \'ਤੇ ਜਾਓ';

  @override
  String get healthVisitSummary => 'ਸਿਹਤ ਦੌਰੇ ਦਾ ਸਾਰ';

  @override
  String get refreshSummaryTooltip => 'ਸਾਰਾਂਸ਼ ਨੂੰ ਤਾਜ਼ਾ ਕਰੋ';

  @override
  String get preparingVisitSummary => 'ਮੁਲਾਕਾਤ ਸਾਰਾਂਸ਼ ਤਿਆਰ ਕਰ ਰਿਹਾ ਹੈ...';

  @override
  String get preparingVisitSubtitle => 'ਇਸ ਵਿੱਚ ਇੱਕ ਮਿੰਟ ਲੱਗ ਸਕਦਾ ਹੈ।';

  @override
  String get unableToLoadVisitSummary =>
      'ਮੁਲਾਕਾਤ ਸਾਰਾਂਸ਼ ਨੂੰ ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਮਰੱਥ';

  @override
  String get visitSummaryUnavailable => 'ਮੁਲਾਕਾਤ ਦਾ ਸਾਰ ਉਪਲਬਧ ਨਹੀਂ ਹੈ';

  @override
  String get visitSummary => 'ਸੰਖੇਪ \'ਤੇ ਜਾਓ';

  @override
  String get visitProcessingTitle => 'ਤੁਹਾਡੀ ਫੇਰੀ ਦੀ ਪ੍ਰਕਿਰਿਆ ਕੀਤੀ ਜਾ ਰਹੀ ਹੈ';

  @override
  String get visitProcessingBody =>
      'ਇਸ ਵਿੱਚ 30-60 ਸਕਿੰਟ ਲੱਗ ਸਕਦੇ ਹਨ।\nਤੁਸੀਂ ਐਪ ਦੀ ਵਰਤੋਂ ਕਰਨਾ ਜਾਰੀ ਰੱਖ ਸਕਦੇ ਹੋ। ਪ੍ਰਗਤੀ ਦੇਖਣ ਲਈ ਸੰਖੇਪ ਜਾਣਕਾਰੀ ਖੋਲ੍ਹੋ।';

  @override
  String get viewOverviewAction => 'ਸੰਖੇਪ ਜਾਣਕਾਰੀ ਵੇਖੋ';

  @override
  String get goToHome => 'ਘਰ \'ਤੇ ਜਾਓ';

  @override
  String get medication => 'ਦਵਾਈ';

  @override
  String get nextToDo => 'ਕਰਨ ਲਈ ਅੱਗੇ';

  @override
  String get conditionsDiscussed => 'ਸ਼ਰਤਾਂ \'ਤੇ ਚਰਚਾ ਕੀਤੀ';

  @override
  String get followUp => 'Ran leti';

  @override
  String get nameLabel => 'ਨਾਮ';

  @override
  String get notSet => 'ਸੈੱਟ ਨਹੀਂ ਹੈ';

  @override
  String get appleIdHidden => 'ਐਪਲ ਆਈਡੀ (ਲੁਕਿਆ ਹੋਇਆ)';

  @override
  String get accountType => 'ਖਾਤੇ ਦੀ ਕਿਸਮ';

  @override
  String get patientRole => 'ਮਰੀਜ਼';

  @override
  String get caregiverRole => 'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲਾ';

  @override
  String get phoneLabel => 'ਫ਼ੋਨ';

  @override
  String get edit => 'ਸੰਪਾਦਿਤ ਕਰੋ';

  @override
  String get add => 'ਸ਼ਾਮਲ ਕਰੋ';

  @override
  String get planLabel => 'ਯੋਜਨਾ';

  @override
  String get planFree => 'ਮੁਫ਼ਤ';

  @override
  String get planPremium => 'ਪ੍ਰੀਮੀਅਮ';

  @override
  String get usageLabel => 'ਵਰਤੋਂ';

  @override
  String freePlanUsage(int used, int limit) {
    return 'ਮੁਫਤ ਯੋਜਨਾ -$used / $limitਸੰਖੇਪ ਵਰਤੇ ਗਏ';
  }

  @override
  String get unlimited => 'ਅਸੀਮਤ';

  @override
  String get editPhoneNumber => 'ਫ਼ੋਨ ਨੰਬਰ ਦਾ ਸੰਪਾਦਨ ਕਰੋ';

  @override
  String get phoneNumber => 'ਫੋਨ ਨੰਬਰ';

  @override
  String get save => 'ਸੇਵ ਕਰੋ';

  @override
  String get phoneMinLength => 'ਫ਼ੋਨ ਨੰਬਰ ਘੱਟੋ-ਘੱਟ 8 ਅੱਖਰਾਂ ਦਾ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ';

  @override
  String get phoneUpdatedSuccess => 'ਫ਼ੋਨ ਨੰਬਰ ਸਫਲਤਾਪੂਰਵਕ ਅੱਪਡੇਟ ਕੀਤਾ ਗਿਆ';

  @override
  String phoneUpdateFailed(String error) {
    return 'ਫ਼ੋਨ ਨੰਬਰ ਅੱਪਡੇਟ ਕਰਨ ਵਿੱਚ ਅਸਫਲ:$error';
  }

  @override
  String get changePassword => 'ਪਾਸਵਰਡ ਬਦਲੋ';

  @override
  String get changePasswordSubtitle =>
      'ਸੁਰੱਖਿਆ ਲਈ ਆਪਣੇ ਖਾਤੇ ਦਾ ਪਾਸਵਰਡ ਅੱਪਡੇਟ ਕਰੋ';

  @override
  String get privacySettings => 'ਗੋਪਨੀਯਤਾ ਸੈਟਿੰਗਾਂ';

  @override
  String get privacySettingsSubtitle =>
      'ਆਪਣੀਆਂ ਡੇਟਾ ਸ਼ੇਅਰਿੰਗ ਤਰਜੀਹਾਂ ਦਾ ਪ੍ਰਬੰਧਨ ਕਰੋ';

  @override
  String get managePrivacy => 'ਗੋਪਨੀਯਤਾ ਦਾ ਪ੍ਰਬੰਧਨ ਕਰੋ';

  @override
  String changePasswordProviderMessage(String provider) {
    return 'ਤੁਸੀਂ ਵਰਤ ਕੇ ਸਾਈਨ ਇਨ ਕੀਤਾ ਹੈ$provider. ਕਿਰਪਾ ਕਰਕੇ ਆਪਣੇ ਵਿੱਚ ਆਪਣਾ ਪਾਸਵਰਡ ਬਦਲੋ$providerਖਾਤਾ।';
  }

  @override
  String get ok => 'ਠੀਕ ਹੈ';

  @override
  String get selectDate => 'ਮਿਤੀ ਚੁਣੋ';

  @override
  String get changePasswordIntro =>
      'ਆਪਣੇ ਖਾਤੇ ਨੂੰ ਸੁਰੱਖਿਅਤ ਰੱਖਣ ਲਈ ਆਪਣਾ ਪਾਸਵਰਡ ਅੱਪਡੇਟ ਕਰੋ।';

  @override
  String get currentPassword => 'ਵਰਤਮਾਨ ਪਾਸਵਰਡ';

  @override
  String get currentPasswordHint => 'ਆਪਣਾ ਮੌਜੂਦਾ ਪਾਸਵਰਡ ਦਰਜ ਕਰੋ';

  @override
  String get enterCurrentPassword => 'ਕਿਰਪਾ ਕਰਕੇ ਆਪਣਾ ਮੌਜੂਦਾ ਪਾਸਵਰਡ ਦਾਖਲ ਕਰੋ';

  @override
  String get newPassword => 'ਨਵਾਂ ਪਾਸਵਰਡ';

  @override
  String get newPasswordHint => 'ਆਪਣਾ ਨਵਾਂ ਪਾਸਵਰਡ ਦਰਜ ਕਰੋ';

  @override
  String get enterNewPassword => 'ਕਿਰਪਾ ਕਰਕੇ ਇੱਕ ਨਵਾਂ ਪਾਸਵਰਡ ਦਾਖਲ ਕਰੋ';

  @override
  String get passwordMinLength => 'ਪਾਸਵਰਡ ਘੱਟੋ-ਘੱਟ 8 ਅੱਖਰਾਂ ਦਾ ਹੋਣਾ ਚਾਹੀਦਾ ਹੈ';

  @override
  String get confirmNewPassword => 'ਨਵੇਂ ਪਾਸਵਰਡ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ';

  @override
  String get confirmNewPasswordHint => 'ਆਪਣਾ ਨਵਾਂ ਪਾਸਵਰਡ ਦੁਬਾਰਾ ਦਰਜ ਕਰੋ';

  @override
  String get confirmNewPasswordRequired =>
      'ਕਿਰਪਾ ਕਰਕੇ ਆਪਣੇ ਨਵੇਂ ਪਾਸਵਰਡ ਦੀ ਪੁਸ਼ਟੀ ਕਰੋ';

  @override
  String get passwordsDoNotMatch => 'ਪਾਸਵਰਡ ਮੇਲ ਨਹੀਂ ਖਾਂਦੇ';

  @override
  String get updatePassword => 'ਪਾਸਵਰਡ ਅੱਪਡੇਟ ਕਰੋ';

  @override
  String get passwordUpdatedSuccess => 'ਪਾਸਵਰਡ ਸਫਲਤਾਪੂਰਵਕ ਅੱਪਡੇਟ ਕੀਤਾ ਗਿਆ';

  @override
  String get passwordUpdateFailed => 'ਪਾਸਵਰਡ ਅੱਪਡੇਟ ਕਰਨ ਵਿੱਚ ਅਸਫਲ';

  @override
  String get wrongPassword => 'ਮੌਜੂਦਾ ਪਾਸਵਰਡ ਗਲਤ ਹੈ';

  @override
  String get weakPassword => 'ਪਾਸਵਰਡ ਬਹੁਤ ਕਮਜ਼ੋਰ ਹੈ';

  @override
  String get requiresRecentLogin =>
      'ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਲੌਗ ਇਨ ਕਰੋ ਅਤੇ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get checkInternetConnection => 'ਆਪਣੇ ਇੰਟਰਨੈਟ ਕਨੈਕਸ਼ਨ ਦੀ ਜਾਂਚ ਕਰੋ';

  @override
  String get dataSharing => 'ਡਾਟਾ ਸ਼ੇਅਰਿੰਗ';

  @override
  String get allowCaregiverSummaries =>
      'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਨੂੰ ਸਾਰਾਂਸ਼ ਦੇਖਣ ਦੀ ਆਗਿਆ ਦਿਓ';

  @override
  String get allowCaregiverMedications =>
      'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਨੂੰ ਦਵਾਈਆਂ ਦੇਖਣ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ';

  @override
  String get allowCaregiverReminders =>
      'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਨੂੰ ਰੀਮਾਈਂਡਰ ਦੇਖਣ ਦੀ ਇਜਾਜ਼ਤ ਦਿਓ';

  @override
  String get allowAiImprovement =>
      'AI ਨੂੰ ਉਤਪਾਦ ਨੂੰ ਬਿਹਤਰ ਬਣਾਉਣ ਲਈ ਮੇਰੇ ਡੇਟਾ ਦੀ ਵਰਤੋਂ ਕਰਨ ਦਿਓ';

  @override
  String get communicationAndConsent => 'ਸੰਚਾਰ ਅਤੇ ਸਹਿਮਤੀ';

  @override
  String get allowEmailNotifications => 'ਈਮੇਲ ਸੂਚਨਾਵਾਂ ਦੀ ਆਗਿਆ ਦਿਓ';

  @override
  String get allowSmsNotifications => 'SMS ਸੂਚਨਾਵਾਂ ਦੀ ਆਗਿਆ ਦਿਓ';

  @override
  String get allowPushNotifications => 'ਪੁਸ਼ ਸੂਚਨਾਵਾਂ ਦੀ ਆਗਿਆ ਦਿਓ';

  @override
  String get dataControl => 'ਡਾਟਾ ਕੰਟਰੋਲ';

  @override
  String get exportMyData => 'ਮੇਰਾ ਡੇਟਾ ਨਿਰਯਾਤ ਕਰੋ';

  @override
  String get deleteAllMedicalRecords => 'ਮੇਰੇ ਸਾਰੇ ਮੈਡੀਕਲ ਰਿਕਾਰਡ ਮਿਟਾਓ';

  @override
  String get deleteMedicalRecordsTitle => 'ਮੈਡੀਕਲ ਰਿਕਾਰਡ ਮਿਟਾਓ';

  @override
  String get deleteMedicalRecordsMessage =>
      'ਇਹ ਤੁਹਾਡੇ ਸਾਰੇ ਮੈਡੀਕਲ ਰਿਕਾਰਡਾਂ ਨੂੰ ਪੱਕੇ ਤੌਰ \'ਤੇ ਮਿਟਾ ਦੇਵੇਗਾ। ਇਸ ਕਾਰਵਾਈ ਨੂੰ ਅਣਕੀਤਾ ਨਹੀਂ ਕੀਤਾ ਜਾ ਸਕਦਾ।';

  @override
  String get deleteRecords => 'ਰਿਕਾਰਡ ਮਿਟਾਓ';

  @override
  String get deleteMyAccount => 'ਮੇਰਾ ਖਾਤਾ ਮਿਟਾਓ';

  @override
  String get legal => 'ਕਾਨੂੰਨੀ';

  @override
  String get viewPrivacyPolicy => 'ਗੋਪਨੀਯਤਾ ਨੀਤੀ ਦੇਖੋ';

  @override
  String get viewTermsOfService => 'ਸੇਵਾ ਦੀਆਂ ਸ਼ਰਤਾਂ ਦੇਖੋ';

  @override
  String get termsOfService => 'ਸੇਵਾ ਦੀਆਂ ਸ਼ਰਤਾਂ';

  @override
  String get termsOfServiceBody =>
      'RemiMinder ਲਈ ਸੇਵਾ ਦੀਆਂ ਸ਼ਰਤਾਂ\n\n1. ਸ਼ਰਤਾਂ ਦੀ ਸਵੀਕ੍ਰਿਤੀ\nRemiMinder ਦੀ ਵਰਤੋਂ ਕਰਕੇ, ਤੁਸੀਂ ਇਹਨਾਂ ਸ਼ਰਤਾਂ ਨਾਲ ਸਹਿਮਤ ਹੁੰਦੇ ਹੋ।\n\n2. ਸੇਵਾ ਦੀ ਵਰਤੋਂ\nRemiMinder ਨੂੰ ਸਿਹਤ ਸੰਭਾਲ ਅਤੇ ਦਵਾਈ ਰੀਮਾਈਂਡਰਾਂ ਦਾ ਪ੍ਰਬੰਧਨ ਕਰਨ ਵਿੱਚ ਮਦਦ ਕਰਨ ਲਈ ਤਿਆਰ ਕੀਤਾ ਗਿਆ ਹੈ।\n\n3. ਗੋਪਨੀਯਤਾ\nਤੁਹਾਡੀ ਗੋਪਨੀਯਤਾ ਸਾਡੇ ਲਈ ਮਹੱਤਵਪੂਰਨ ਹੈ। ਸਾਰੇ ਸਿਹਤ ਡੇਟਾ ਨੂੰ ਸੁਰੱਖਿਅਤ ਢੰਗ ਨਾਲ ਸੰਭਾਲਿਆ ਜਾਂਦਾ ਹੈ।\n\nਸੇਵਾ ਦੀਆਂ ਪੂਰੀਆਂ ਸ਼ਰਤਾਂ ਲਈ, ਕਿਰਪਾ ਕਰਕੇ ਸਾਡੀ ਵੈੱਬਸਾਈਟ \'ਤੇ ਜਾਓ।';

  @override
  String get privacyPolicy => 'ਪਰਾਈਵੇਟ ਨੀਤੀ';

  @override
  String get privacyPolicyBody =>
      'ਰੀਮੀਮਾਈਂਡਰ ਲਈ ਗੋਪਨੀਯਤਾ ਨੀਤੀ\n\n1. ਜਾਣਕਾਰੀ ਅਸੀਂ ਇਕੱਠੀ ਕਰਦੇ ਹਾਂ\nਅਸੀਂ ਸਾਡੀ ਸੇਵਾ ਨੂੰ ਬਿਹਤਰ ਬਣਾਉਣ ਲਈ ਤੁਹਾਡੇ ਦੁਆਰਾ ਪ੍ਰਦਾਨ ਕੀਤੀ ਜਾਣਕਾਰੀ ਅਤੇ ਵਰਤੋਂ ਡੇਟਾ ਇਕੱਤਰ ਕਰਦੇ ਹਾਂ।\n\n2. ਅਸੀਂ ਜਾਣਕਾਰੀ ਦੀ ਵਰਤੋਂ ਕਿਵੇਂ ਕਰਦੇ ਹਾਂ\nਜਾਣਕਾਰੀ ਦੀ ਵਰਤੋਂ ਸਿਹਤ ਸੰਭਾਲ ਪ੍ਰਬੰਧਨ ਸੇਵਾਵਾਂ ਪ੍ਰਦਾਨ ਕਰਨ ਲਈ ਕੀਤੀ ਜਾਂਦੀ ਹੈ।\n\n3. ਜਾਣਕਾਰੀ ਸਾਂਝੀ ਕਰਨਾ\nਅਸੀਂ ਤੁਹਾਡੀ ਨਿੱਜੀ ਜਾਣਕਾਰੀ ਨਹੀਂ ਵੇਚਦੇ।\n\nਪੂਰੀ ਗੋਪਨੀਯਤਾ ਨੀਤੀ ਲਈ, ਕਿਰਪਾ ਕਰਕੇ ਸਾਡੀ ਵੈੱਬਸਾਈਟ \'ਤੇ ਜਾਓ।';

  @override
  String get close => 'ਬੰਦ ਕਰੋ';

  @override
  String featureComingSoon(String feature) {
    return '$featureਆਨ ਵਾਲੀ';
  }

  @override
  String get caregiverSharingEnabled => 'ਕੇਅਰਗਿਵਰ ਸ਼ੇਅਰਿੰਗ ਸਮਰੱਥ ਹੈ';

  @override
  String get caregiverSharingDisabled => 'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲਾ ਸਾਂਝਾਕਰਨ ਅਯੋਗ ਹੈ';

  @override
  String get dataExport => 'ਡਾਟਾ ਨਿਰਯਾਤ';

  @override
  String get remindersTitle => 'ਰੀਮਾਈਂਡਰ';

  @override
  String get tabAll => 'ਸਾਰੇ';

  @override
  String get tabToday => 'ਅੱਜ';

  @override
  String get tabPending => 'ਬਕਾਇਆ';

  @override
  String get tabCompleted => 'ਪੂਰਾ ਹੋਇਆ';

  @override
  String get searchRemindersHint => 'ਰੀਮਾਈਂਡਰ ਖੋਜੋ...';

  @override
  String get failedToLoadRemindersRetry =>
      'ਰੀਮਾਈਂਡਰ ਲੋਡ ਕਰਨ ਵਿੱਚ ਅਸਫਲ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get deleteReminderTitle => 'ਰੀਮਾਈਂਡਰ ਮਿਟਾਓ';

  @override
  String get deleteReminderMessage =>
      'ਕੀ ਤੁਸੀਂ ਯਕੀਨੀ ਤੌਰ \'ਤੇ ਇਸ ਰੀਮਾਈਂਡਰ ਨੂੰ ਮਿਟਾਉਣਾ ਚਾਹੁੰਦੇ ਹੋ?';

  @override
  String get markDone => 'ਹੋ ਗਿਆ ਮਾਰਕ ਕਰੋ';

  @override
  String get snooze => 'ਸਨੂਜ਼ ਕਰੋ';

  @override
  String snoozedUntil(String time) {
    return 'ਤੱਕ ਸਨੂਜ਼ ਕੀਤਾ ਗਿਆ$time';
  }

  @override
  String get statusDueNow => 'ਹੁਣ ਬਕਾਇਆ';

  @override
  String get statusActive => 'ਕਿਰਿਆਸ਼ੀਲ';

  @override
  String get statusMissed => 'ਖੁੰਝ ਗਈ';

  @override
  String get statusSnoozed => 'ਸਨੂਜ਼ ਕੀਤਾ ਗਿਆ';

  @override
  String get statusSkipped => 'ਛੱਡਿਆ';

  @override
  String get statusPending => 'ਬਕਾਇਆ';

  @override
  String get noRemindersFound => 'ਕੋਈ ਰੀਮਾਈਂਡਰ ਨਹੀਂ ਮਿਲੇ';

  @override
  String get noRemindersMatchSearch =>
      'ਕੋਈ ਰੀਮਾਈਂਡਰ ਤੁਹਾਡੀ ਖੋਜ ਨਾਲ ਮੇਲ ਨਹੀਂ ਖਾਂਦਾ';

  @override
  String get createFirstReminder => 'ਸ਼ੁਰੂ ਕਰਨ ਲਈ ਆਪਣਾ ਪਹਿਲਾ ਰੀਮਾਈਂਡਰ ਬਣਾਓ';

  @override
  String get tryAdjustSearch =>
      'ਆਪਣੇ ਖੋਜ ਸ਼ਬਦਾਂ ਨੂੰ ਵਿਵਸਥਿਤ ਕਰਨ ਦੀ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get createReminder => 'ਰੀਮਾਈਂਡਰ ਬਣਾਓ';

  @override
  String get newReminder => 'ਨਵਾਂ ਰੀਮਾਈਂਡਰ';

  @override
  String get editReminder => 'ਰੀਮਾਈਂਡਰ ਦਾ ਸੰਪਾਦਨ ਕਰੋ';

  @override
  String get reminderTitleLabel => 'ਸਿਰਲੇਖ';

  @override
  String get dosageOptional => 'ਖੁਰਾਕ (ਵਿਕਲਪਿਕ)';

  @override
  String get dosageHint => 'ਜਿਵੇਂ ਕਿ ਦਿਨ ਵਿੱਚ ਇੱਕ ਵਾਰ 10 ਮਿਲੀਗ੍ਰਾਮ';

  @override
  String get reminderTypeLabel => 'ਟਾਈਪ ਕਰੋ';

  @override
  String get appointment => 'ਮੁਲਾਕਾਤ';

  @override
  String get repeatLabel => 'ਦੁਹਰਾਓ';

  @override
  String get once => 'ਇੱਕ ਵਾਰ';

  @override
  String get daily => 'ਰੋਜ਼ਾਨਾ';

  @override
  String get weekly => 'ਹਫ਼ਤਾਵਾਰੀ';

  @override
  String get pleaseEnterTitle => 'ਕਿਰਪਾ ਕਰਕੇ ਇੱਕ ਸਿਰਲੇਖ ਦਾਖਲ ਕਰੋ';

  @override
  String get reminderCreated => 'ਰੀਮਾਈਂਡਰ ਬਣਾਇਆ ਗਿਆ!';

  @override
  String failedToCreateReminder(String error) {
    return 'ਰੀਮਾਈਂਡਰ ਬਣਾਉਣ ਵਿੱਚ ਅਸਫਲ:$error';
  }

  @override
  String get saveChanges => 'ਤਬਦੀਲੀਆਂ ਨੂੰ ਸੁਰੱਖਿਅਤ ਕਰੋ';

  @override
  String get cannotRescheduleMissingType =>
      'ਮੁੜ-ਨਿਯਤ ਨਹੀਂ ਕੀਤਾ ਜਾ ਸਕਦਾ: ਰੀਮਾਈਂਡਰ ਕਿਸਮ ਗੁੰਮ ਹੈ';

  @override
  String get reminderUpdated => 'ਰੀਮਾਈਂਡਰ ਅੱਪਡੇਟ ਕੀਤਾ ਗਿਆ!';

  @override
  String failedToUpdateReminder(String error) {
    return 'ਅੱਪਡੇਟ ਕਰਨ ਵਿੱਚ ਅਸਫਲ:$error';
  }

  @override
  String get reminderMarkedCompleted =>
      'ਰੀਮਾਈਂਡਰ ਦੀ ਮੁਕੰਮਲ ਵਜੋਂ ਨਿਸ਼ਾਨਦੇਹੀ ਕੀਤੀ ਗਈ!';

  @override
  String get reminderSnoozed30 => 'ਰੀਮਾਈਂਡਰ ਨੂੰ 30 ਮਿੰਟਾਂ ਲਈ ਸਨੂਜ਼ ਕੀਤਾ ਗਿਆ';

  @override
  String timeInHours(int hours, String time) {
    return 'ਵਿੱਚ$hoursਘੰਟੇ ($time)';
  }

  @override
  String timeInMinutes(int minutes, String time) {
    return 'ਵਿੱਚ$minutesਮਿੰਟ ($time)';
  }

  @override
  String get timeNow => 'ਹੁਣ';

  @override
  String timeHoursAgo(int hours) {
    return '$hoursਘੰਟੇ ਪਹਿਲਾਂ';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutesਮਿੰਟ ਪਹਿਲਾਂ';
  }

  @override
  String timeInDays(int days) {
    return '$days ਦਿਨਾਂ ਵਿੱਚ';
  }

  @override
  String timeInHoursShort(int hours) {
    return '$hours ਘੰਟਿਆਂ ਵਿੱਚ';
  }

  @override
  String timeInMinutesShort(int minutes) {
    return '$minutes ਮਿੰਟਾਂ ਵਿੱਚ';
  }

  @override
  String get selectTime => 'ਸਮਾਂ ਚੁਣੋ';

  @override
  String get presetMorning => 'ਸਵੇਰ (8:00 AM)';

  @override
  String get presetNoon => 'ਦੁਪਹਿਰ (12:00 ਵਜੇ)';

  @override
  String get presetEvening => 'ਸ਼ਾਮ (6:00 PM)';

  @override
  String get presetNight => 'ਰਾਤ (8:00 PM)';

  @override
  String get hourLabel => 'ਘੰਟਾ';

  @override
  String get minuteLabel => 'ਘੱਟੋ-ਘੱਟ';

  @override
  String get amPmLabel => 'AM / PM';

  @override
  String get amLabel => 'ਏ.ਐੱਮ';

  @override
  String get pmLabel => 'ਪੀ.ਐੱਮ';

  @override
  String selectedTimeLabel(String time) {
    return 'ਚੁਣਿਆ ਸਮਾਂ:$time';
  }

  @override
  String setForTime(String time) {
    return 'ਲਈ ਸੈੱਟ ਕਰੋ$time ✓';
  }

  @override
  String get medicationAdherence => 'ਦਵਾਈ ਦੀ ਪਾਲਣਾ';

  @override
  String get thisWeek => 'ਇਸ ਹਫ਼ਤੇ';

  @override
  String get thisMonth => 'ਇਸ ਮਹੀਨੇ';

  @override
  String get overall => 'ਕੁੱਲ ਮਿਲਾ ਕੇ';

  @override
  String dosesCount(int done, int total) {
    return '$done/$totalਖੁਰਾਕਾਂ';
  }

  @override
  String get byMedication => 'ਦਵਾਈ ਦੁਆਰਾ';

  @override
  String get noPastRemindersAnalyze =>
      'ਵਿਸ਼ਲੇਸ਼ਣ ਕਰਨ ਲਈ ਕੋਈ ਪਿਛਲੀ ਰੀਮਾਈਂਡਰ ਨਹੀਂ';

  @override
  String get adherenceTips => 'ਪਾਲਣਾ ਸੁਝਾਅ';

  @override
  String get adherenceTipsBody =>
      '• ਦਵਾਈ ਦੇ ਸਮੇਂ ਲਈ ਫ਼ੋਨ ਰੀਮਾਈਂਡਰ ਸੈੱਟ ਕਰੋ\n• ਦਵਾਈਆਂ ਨੂੰ ਨਜ਼ਰ ਆਉਣ ਵਾਲੀ ਥਾਂ \'ਤੇ ਰੱਖੋ\n• ਰੋਜ਼ਾਨਾ ਖੁਰਾਕਾਂ ਲਈ ਗੋਲੀ ਪ੍ਰਬੰਧਕ ਦੀ ਵਰਤੋਂ ਕਰੋ\n• ਪ੍ਰੇਰਿਤ ਰਹਿਣ ਲਈ ਆਪਣੀ ਤਰੱਕੀ \'ਤੇ ਨਜ਼ਰ ਰੱਖੋ';

  @override
  String get actionFailed => 'ਕਾਰਵਾਈ ਅਸਫਲ ਰਹੀ';

  @override
  String get snoozeAlreadyUsed =>
      'ਇਸ ਰੀਮਾਈਂਡਰ ਨੂੰ ਪਹਿਲਾਂ ਹੀ ਇੱਕ ਵਾਰ ਸਨੂਜ਼ ਕੀਤਾ ਗਿਆ ਸੀ';

  @override
  String get reminderDeleted => 'ਰੀਮਾਈਂਡਰ ਮਿਟਾਇਆ ਗਿਆ';

  @override
  String get deleteFailed => 'ਮਿਟਾਉਣਾ ਅਸਫਲ ਰਿਹਾ';

  @override
  String get sectionRecentAlerts => 'ਹਾਲੀਆ ਚੇਤਾਵਨੀਆਂ';

  @override
  String get viewAll => 'ਸਭ ਦੇਖੋ';

  @override
  String get sectionInvitations => 'ਸੱਦੇ';

  @override
  String get summaryPatients => 'ਮਰੀਜ਼';

  @override
  String get summaryAlerts => 'ਚੇਤਾਵਨੀਆਂ';

  @override
  String get summaryPending => 'ਬਕਾਇਆ';

  @override
  String get noAlertsAtThisTime => 'ਇਸ ਸਮੇਂ ਕੋਈ ਚੇਤਾਵਨੀਆਂ ਨਹੀਂ ਹਨ';

  @override
  String get noPendingInvitations => 'ਕੋਈ ਬਕਾਇਆ ਸੱਦੇ ਨਹੀਂ ਹਨ';

  @override
  String get pendingInvitationsTitle => 'ਵਿਚਾਰ-ਅਧੀਨ ਸੱਦੇ';

  @override
  String invitationsWaiting(int count) {
    return '$countਸੱਦਾ(ਸ) ਉਡੀਕ ਰਹੇ ਹਨ';
  }

  @override
  String get reviewAcceptInvitations =>
      'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਸੱਦਿਆਂ ਦੀ ਸਮੀਖਿਆ ਕਰੋ ਅਤੇ ਸਵੀਕਾਰ ਕਰੋ।';

  @override
  String get viewInvitations => 'ਸੱਦੇ ਵੇਖੋ';

  @override
  String get defaultPatient => 'ਮਰੀਜ਼';

  @override
  String get defaultCaregiver => 'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲਾ';

  @override
  String caregiverPatientTime(String name, String time) {
    return 'ਮਰੀਜ਼:$name • $time';
  }

  @override
  String timeDaysAgo(int days) {
    return '$daysਦਿਨ ਪਹਿਲਾਂ';
  }

  @override
  String get alertsTitle => 'ਚੇਤਾਵਨੀਆਂ';

  @override
  String get filterUnread => 'ਨਾ ਪੜ੍ਹਿਆ';

  @override
  String get filterRead => 'ਪੜ੍ਹੋ';

  @override
  String get filterHighPriority => 'ਉੱਚ ਤਰਜੀਹ';

  @override
  String get filterActionRequired => 'ਕਾਰਵਾਈ ਦੀ ਲੋੜ ਹੈ';

  @override
  String get alertSingular => 'ਚੇਤਾਵਨੀ';

  @override
  String get alertsPlural => 'ਚੇਤਾਵਨੀਆਂ';

  @override
  String get clearFilter => 'ਫਿਲਟਰ ਸਾਫ਼ ਕਰੋ';

  @override
  String get noAlertsMatchFilter =>
      'ਕੋਈ ਚੇਤਾਵਨੀਆਂ ਇਸ ਫਿਲਟਰ ਨਾਲ ਮੇਲ ਨਹੀਂ ਖਾਂਦੀਆਂ';

  @override
  String get allPatientActivitiesSmooth =>
      'ਮਰੀਜ਼ਾਂ ਦੀਆਂ ਸਾਰੀਆਂ ਗਤੀਵਿਧੀਆਂ ਸੁਚਾਰੂ ਢੰਗ ਨਾਲ ਚੱਲ ਰਹੀਆਂ ਹਨ';

  @override
  String get tryAdjustingFilter =>
      'ਹੋਰ ਚੇਤਾਵਨੀਆਂ ਦੇਖਣ ਲਈ ਆਪਣੇ ਫਿਲਟਰ ਨੂੰ ਵਿਵਸਥਿਤ ਕਰਨ ਦੀ ਕੋਸ਼ਿਸ਼ ਕਰੋ';

  @override
  String get viewAllAlerts => 'ਸਾਰੀਆਂ ਚੇਤਾਵਨੀਆਂ ਵੇਖੋ';

  @override
  String get alertMarkedAsRead =>
      'ਚੇਤਾਵਨੀ ਨੂੰ ਪੜ੍ਹਿਆ ਗਿਆ ਵਜੋਂ ਚਿੰਨ੍ਹਿਤ ਕੀਤਾ ਗਿਆ';

  @override
  String alertsMarkedAsRead(int count) {
    return 'ਮਾਰਕ ਕੀਤਾ$countਪੜ੍ਹੇ ਅਨੁਸਾਰ ਚੇਤਾਵਨੀਆਂ';
  }

  @override
  String get allAlertsAlreadyRead =>
      'ਸਾਰੀਆਂ ਚੇਤਾਵਨੀਆਂ ਪਹਿਲਾਂ ਹੀ ਪੜ੍ਹੀਆਂ ਗਈਆਂ ਹਨ';

  @override
  String get myPatientsTitle => 'ਮੇਰੇ ਮਰੀਜ਼';

  @override
  String get patientsConnectedSubtitle => 'ਤੁਹਾਡੇ ਨਾਲ ਜੁੜੇ ਮਰੀਜ਼';

  @override
  String get myPatientsSection => 'ਮੇਰੇ ਮਰੀਜ਼';

  @override
  String connectedCount(int count) {
    return '$countਜੁੜਿਆ';
  }

  @override
  String get searchPatientsHint => 'ਮਰੀਜ਼ਾਂ ਦੀ ਭਾਲ...';

  @override
  String get noPatientsMatchSearch =>
      'ਕੋਈ ਮਰੀਜ਼ ਤੁਹਾਡੀ ਖੋਜ ਨਾਲ ਮੇਲ ਨਹੀਂ ਖਾਂਦਾ।';

  @override
  String get noPatientsConnectedYet => 'ਅਜੇ ਤੱਕ ਕੋਈ ਮਰੀਜ਼ ਜੁੜਿਆ ਨਹੀਂ ਹੈ';

  @override
  String get acceptInvitationToSeePatient =>
      'ਇੱਥੇ ਇੱਕ ਮਰੀਜ਼ ਨੂੰ ਦੇਖਣ ਲਈ ਇੱਕ ਸੱਦਾ ਸਵੀਕਾਰ ਕਰੋ.';

  @override
  String get badgeNew => 'ਨਵਾਂ';

  @override
  String joinedOn(String date) {
    return 'ਸ਼ਾਮਲ ਹੋਏ$date';
  }

  @override
  String get neverSynced => 'ਹਾਲੇ ਲੋਡ ਨਹੀਂ ਹੋਇਆ';

  @override
  String get privacyDataRequestMessage =>
      'ਆਪਣੇ ਡੇਟਾ ਨੂੰ ਨਿਰਯਾਤ ਕਰਨ ਜਾਂ ਮਿਟਾਉਣ ਲਈ privacy@remiminder.ai \'ਤੇ ਸੰਪਰਕ ਕਰੋ।';

  @override
  String syncMinutesAgo(int minutes) {
    return '$minutesਮੀ ਪਹਿਲਾਂ';
  }

  @override
  String syncHoursAgo(int hours) {
    return '$hoursਘੰਟੇ ਪਹਿਲਾਂ';
  }

  @override
  String syncDaysAgo(int days) {
    return '${days}d ਪਹਿਲਾਂ';
  }

  @override
  String get primaryCondition => 'ਪ੍ਰਾਇਮਰੀ ਹਾਲਤ';

  @override
  String get lastSynced => 'ਆਖਰੀ ਵਾਰ ਸਿੰਕ ਕੀਤਾ ਗਿਆ';

  @override
  String get allergiesLabel => 'ਐਲਰਜੀ';

  @override
  String get dateOfBirth => 'ਜਨਮ ਤਾਰੀਖ';

  @override
  String get currentMedications => 'ਮੌਜੂਦਾ ਦਵਾਈਆਂ';

  @override
  String get viewCarePlan => 'ਦੇਖਭਾਲ ਯੋਜਨਾ ਵੇਖੋ';

  @override
  String get remindersButton => 'ਰੀਮਾਈਂਡਰ';

  @override
  String get caregiverCareTeamSubtitle =>
      'ਪਰਿਵਾਰ ਜਾਂ ਮੈਡੀਕਲ ਸਟਾਫ਼ ਨੂੰ ਸੱਦਾ ਦਿਓ';

  @override
  String get invitationsReceived => 'ਸੱਦੇ ਮਿਲੇ ਹਨ';

  @override
  String pendingBadge(int count) {
    return '$countਬਕਾਇਆ';
  }

  @override
  String get patientOverviewTitle => 'ਮਰੀਜ਼ ਦੀ ਸੰਖੇਪ ਜਾਣਕਾਰੀ';

  @override
  String get patientOverviewTabVisits => 'ਮੁਲਾਕਾਤਾਂ';

  @override
  String get patientOverviewTabReminders => 'ਰੀਮਾਈਂਡਰ';

  @override
  String get patientOverviewNoVisits => 'ਕੋਈ ਮੁਲਾਕਾਤਾਂ ਉਪਲਬਧ ਨਹੀਂ ਹਨ';

  @override
  String get patientOverviewNoReminders => 'ਕੋਈ ਰੀਮਾਈਂਡਰ ਉਪਲਬਧ ਨਹੀਂ ਹਨ';

  @override
  String get patientOverviewMissingPatientId => 'ਮਰੀਜ਼ ਦੀ ਜਾਣਕਾਰੀ ਗੁੰਮ ਹੈ';

  @override
  String get patientOverviewLastVisit => 'ਆਖਰੀ ਫੇਰੀ';

  @override
  String get patientOverviewCareTeam => 'ਕੇਅਰ ਟੀਮ ਦੇ ਮੈਂਬਰ';

  @override
  String get patientOverviewScheduledReminder => 'ਨਿਯਤ ਰੀਮਾਈਂਡਰ';

  @override
  String get patientOverviewNever => 'ਕਦੇ ਨਹੀਂ';

  @override
  String get patientOverviewYesterday => 'ਕੱਲ੍ਹ';

  @override
  String get statusViewed => 'ਦੇਖਿਆ';

  @override
  String get statusExpired => 'ਮਿਆਦ ਪੁੱਗੀ';

  @override
  String get statusJoined => 'ਸ਼ਾਮਲ';

  @override
  String get noInvitationsToShow => 'ਦਿਖਾਉਣ ਲਈ ਕੋਈ ਸੱਦੇ ਨਹੀਂ';

  @override
  String invitedByLabel(String name) {
    return 'ਸੱਦਾ ਦਿੱਤਾ: $name';
  }

  @override
  String get acceptInvitation => 'ਸਵੀਕਾਰ';

  @override
  String get declineInvitation => 'ਅਸਵੀਕਾਰ';

  @override
  String get invitationDeclined => 'ਸੱਦਾ ਅਸਵੀਕਾਰ';

  @override
  String joinedCareTeamSnackbar(String patientName, String role) {
    return '$patientName ਦੀ ਦੇਖਭਾਲ ਟੀਮ ਵਿੱਚ $role ਵਜੋਂ ਸ਼ਾਮਲ';
  }

  @override
  String get manageAccess => 'ਪਹੁੰਚ ਪ੍ਰਬੰਧਿਤ ਕਰੋ';

  @override
  String get manageAccessDescription =>
      'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਦੀ ਇਜਾਜ਼ਤ ਅਪਡੇਟ ਕਰੋ ਜਾਂ ਪਹੁੰਚ ਹਟਾਓ.';

  @override
  String get manage => 'ਪ੍ਰਬੰਧਿਤ';

  @override
  String get accessUpdatedSuccess => 'ਪਹੁੰਚ ਸਫਲਤਾਪੂਰਵਕ ਅਪਡੇਟ';

  @override
  String get accessUpdateFailed =>
      'ਪਹੁੰਚ ਅਪਡੇਟ ਅਸਫਲ. ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ.';

  @override
  String get removeCaregiverTitle => 'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਨੂੰ ਹਟਾਓ?';

  @override
  String get removeCaregiverMessage =>
      'ਕੀ ਤੁਸੀਂ ਯਕੀਨਨ ਇਸ ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਨੂੰ ਹਟਾਉਣਾ ਚਾਹੁੰਦੇ ਹੋ? ਉਨ੍ਹਾਂ ਦੀ ਪਹੁੰਚ ਤੁਰੰਤ ਬੰਦ ਹੋ ਜਾਵੇਗੀ.';

  @override
  String get remove => 'ਹਟਾਓ';

  @override
  String get updatingAccess => 'ਪਹੁੰਚ ਅਪਡੇਟ ਹੋ ਰਹੀ ਹੈ...';

  @override
  String get removingCaregiver => 'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲਾ ਹਟਾਇਆ ਜਾ ਰਿਹਾ ਹੈ...';

  @override
  String get removeCaregiverFailed =>
      'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲਾ ਹਟਾਉਣ ਵਿੱਚ ਅਸਫਲ. ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ.';

  @override
  String get viewAccess => 'ਦੇਖਣ ਦੀ ਪਹੁੰਚ';

  @override
  String get fullAccess => 'ਪੂਰੀ ਪਹੁੰਚ';

  @override
  String get viewOnly => 'ਸਿਰਫ ਦੇਖੋ';

  @override
  String get resendingInvitation => 'ਸੱਦਾ ਦੁਬਾਰਾ ਭੇਜਿਆ ਜਾ ਰਿਹਾ ਹੈ...';

  @override
  String get invitationResent => 'ਸੱਦਾ ਦੁਬਾਰਾ ਭੇਜਿਆ';

  @override
  String get failedToResendInvitation => 'ਸੱਦਾ ਦੁਬਾਰਾ ਭੇਜਣ ਵਿੱਚ ਅਸਫਲ';

  @override
  String get cancelingInvitation => 'ਸੱਦਾ ਰੱਦ ਕੀਤਾ ਜਾ ਰਿਹਾ ਹੈ...';

  @override
  String get invitationCanceled => 'ਸੱਦਾ ਰੱਦ';

  @override
  String get failedToCancelInvitation => 'ਸੱਦਾ ਰੱਦ ਕਰਨ ਵਿੱਚ ਅਸਫਲ';

  @override
  String get relationshipSon => 'ਪੁੱਤਰ';

  @override
  String get relationshipDaughter => 'ਧੀ';

  @override
  String get relationshipFriend => 'ਦੋਸਤ';

  @override
  String get relationshipSpousePartner => 'ਜੀਵਨ ਸਾਥੀ/ਸਾਥੀ';

  @override
  String get relationshipParent => 'ਮਾਤਾ-ਪਿਤਾ';

  @override
  String get relationshipChild => 'ਬੱਚਾ';

  @override
  String get relationshipFamilyMember => 'ਪਰਿਵਾਰਕ ਮੈਂਬਰ';

  @override
  String get relationshipHealthcareProfessional => 'ਸਿਹਤ ਪੇਸ਼ੇਵਰ';

  @override
  String get relationshipCaregiver => 'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲਾ';

  @override
  String get relationshipSister => 'ਭੈਣ';

  @override
  String get relationshipBrother => 'ਭਰਾ';

  @override
  String get relationshipOther => 'ਹੋਰ';

  @override
  String get visitActionTitle => 'ਤੁਸੀਂ ਕੀ ਕਰਨਾ ਚਾਹੋਗੇ?';

  @override
  String get visitActionAudioTitle => 'ਆਡੀਓ ਗੱਲਬਾਤ ਰਿਕਾਰਡ ਕਰੋ';

  @override
  String get visitActionAudioSubtitle =>
      'ਸਵੈਚਾਲਿਤ ਸਾਰਾਂਸ਼ ਲਈ ਆਪਣੀ ਡਾਕਟਰ ਮੁਲਾਕਾਤ ਰਿਕਾਰਡ ਕਰੋ';

  @override
  String get visitActionCaptureTitle => 'ਕੈਪਚਰ ਅਤੇ ਸਕੈਨ';

  @override
  String get visitActionCaptureSubtitle =>
      'ਰਿਪੋਰਟਾਂ, ਦਵਾਈ ਦੀਆਂ ਬੋਤਲਾਂ ਅਤੇ ਦਸਤਾਵੇਜ਼ਾਂ ਦੀਆਂ ਫੋਟੋਆਂ ਲਓ';

  @override
  String get inviteCaregiverDialogTitle => 'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਨੂੰ ਸੱਦਾ ਦਿਓ';

  @override
  String get caregiverNameHint => 'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਦਾ ਪੂਰਾ ਨਾਮ ਦਰਜ ਕਰੋ';

  @override
  String get caregiverEmailHint => 'ਦੇਖਭਾਲ ਕਰਨ ਵਾਲੇ ਦਾ ਈਮੇਲ ਪਤਾ ਦਰਜ ਕਰੋ';

  @override
  String get relationshipLabel => 'ਰਿਸ਼ਤਾ';

  @override
  String get relationshipHint => 'ਜਿਵੇਂ, ਪੁੱਤਰ, ਧੀ, ਦੋਸਤ, ਨਰਸ';

  @override
  String get sendInvite => 'ਸੱਦਾ ਭੇਜੋ';

  @override
  String get emailAndRoleRequired => 'ਈਮੇਲ ਅਤੇ ਭੂਮਿਕਾ ਲੋੜੀਂਦੀ ਹੈ';

  @override
  String get summaryReadyTitle => 'ਤੁਹਾਡਾ ਮੁਲਾਕਾਤ ਸਾਰਾਂਸ਼ ਤਿਆਰ ਹੈ!';

  @override
  String get summaryReadyBody => 'ਕੀ ਤੁਸੀਂ ਇਸਨੂੰ ਹੁਣੇ ਦੇਖਣਾ ਚਾਹੋਗੇ?';

  @override
  String get later => 'ਬਾਅਦ ਵਿੱਚ';

  @override
  String get viewSummary => 'ਸਾਰਾਂਸ਼ ਦੇਖੋ';

  @override
  String get noLabResultsYet => 'ਅਜੇ ਤੱਕ ਕੋਈ ਲੈਬ ਨਤੀਜੇ ਨਹੀਂ';

  @override
  String get labResultsScanHint =>
      'ਨਤੀਜੇ ਇੱਥੇ ਦੇਖਣ ਲਈ ਕੈਪਚਰ ਅਤੇ ਸਕੈਨ ਨਾਲ ਲੈਬ ਰਿਪੋਰਟ ਸਕੈਨ ਕਰੋ।';

  @override
  String get captureAndScan => 'ਕੈਪਚਰ ਅਤੇ ਸਕੈਨ';

  @override
  String get noScannedDocsYet => 'ਅਜੇ ਤੱਕ ਕੋਈ ਸਕੈਨ ਕੀਤੇ ਦਸਤਾਵੇਜ਼ ਨਹੀਂ';

  @override
  String get scannedDocsHint =>
      'ਤੁਹਾਡੀਆਂ ਮੁਲਾਕਾਤਾਂ ਦੌਰਾਨ ਸਕੈਨ ਕੀਤੇ ਦਸਤਾਵੇਜ਼ ਇੱਥੇ ਦਿਖਾਈ ਦੇਣਗੇ।';

  @override
  String get selectAtLeastOneSummary => 'ਘੱਟੋ-ਘੱਟ ਇੱਕ ਸਾਰਾਂਸ਼ ਚੁਣੋ';

  @override
  String get failedToDeleteSummaries =>
      'ਸਾਰਾਂਸ਼ ਮਿਟਾਉਣ ਵਿੱਚ ਅਸਫਲ। ਕਿਰਪਾ ਕਰਕੇ ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get noCaregiverAddedYet =>
      'ਅਜੇ ਤੱਕ ਕੋਈ ਦੇਖਭਾਲ ਕਰਨ ਵਾਲਾ ਨਹੀਂ ਜੋੜਿਆ ਗਿਆ';

  @override
  String get summaryGenerationRestarted => 'ਸਾਰਾਂਸ਼ ਜਨਰੇਸ਼ਨ ਮੁੜ ਸ਼ੁਰੂ ਹੋਈ';

  @override
  String retryFailed(String error) {
    return 'ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਅਸਫਲ: $error';
  }

  @override
  String get generateSummary => 'ਸਾਰਾਂਸ਼ ਬਣਾਓ';

  @override
  String get discardRecording => 'ਰਿਕਾਰਡਿੰਗ ਰੱਦ ਕਰੋ';

  @override
  String unableToStartRecording(String error) {
    return 'ਰਿਕਾਰਡਿੰਗ ਸ਼ੁਰੂ ਨਹੀਂ ਹੋ ਸਕੀ: $error';
  }

  @override
  String get recordingCompleted => 'ਰਿਕਾਰਡਿੰਗ ਪੂਰੀ!';

  @override
  String unableToStopRecording(String error) {
    return 'ਰਿਕਾਰਡਿੰਗ ਰੋਕੀ ਨਹੀਂ ਜਾ ਸਕੀ: $error';
  }

  @override
  String get recordingDiscarded => 'ਰਿਕਾਰਡਿੰਗ ਰੱਦ ਕੀਤੀ ਗਈ';

  @override
  String get unableToOpenPrivacyPolicy => 'ਗੋਪਨੀਯਤਾ ਨੀਤੀ ਨਹੀਂ ਖੋਲ੍ਹੀ ਜਾ ਸਕੀ।';

  @override
  String get noRecordingAvailable => 'ਕੋਈ ਰਿਕਾਰਡਿੰਗ ਉਪਲਬਧ ਨਹੀਂ';

  @override
  String get uploadingAudio => 'ਆਡੀਓ ਅਪਲੋਡ ਹੋ ਰਿਹਾ ਹੈ...';

  @override
  String failedToUploadAudio(String error) {
    return 'ਆਡੀਓ ਅਪਲੋਡ ਅਸਫਲ: $error';
  }

  @override
  String get stopRecordingTitle => 'ਰਿਕਾਰਡਿੰਗ ਰੋਕੋ?';

  @override
  String get stopRecordingMessage =>
      'Are you sure you want to stop recording? This action cannot be undone.';

  @override
  String get continueRecording => 'ਰਿਕਾਰਡਿੰਗ ਜਾਰੀ ਰੱਖੋ';

  @override
  String get stopAndDiscard => 'ਰੋਕੋ ਅਤੇ ਰੱਦ ਕਰੋ';

  @override
  String get share => 'ਸਾਂਝਾ ਕਰੋ';

  @override
  String get cameraNotReady => 'ਕੈਮਰਾ ਤਿਆਰ ਨਹੀਂ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String failedToCaptureImage(String error) {
    return 'ਚਿੱਤਰ ਕੈਪਚਰ ਅਸਫਲ: $error';
  }

  @override
  String get unableToStartCamera =>
      'ਕੈਮਰਾ ਸ਼ੁਰੂ ਨਹੀਂ ਹੋ ਸਕਿਆ। ਦੁਬਾਰਾ ਕੋਸ਼ਿਸ਼ ਕਰੋ।';

  @override
  String get cameraReadyHint => 'ਕੈਮਰਾ ਤਿਆਰ। ਦਸਤਾਵੇਜ਼ ਰੱਖੋ ਅਤੇ ਕੈਪਚਰ ਟੈਪ ਕਰੋ।';

  @override
  String unableToStartScanning(String error) {
    return 'ਸਕੈਨ ਸ਼ੁਰੂ ਨਹੀਂ ਹੋ ਸਕਿਆ: $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'ਚਿੱਤਰ ਅਪਲੋਡ ਅਸਫਲ: $error';
  }

  @override
  String get noImageToProcess => 'ਪ੍ਰੋਸੈਸ ਕਰਨ ਲਈ ਚਿੱਤਰ ਨਹੀਂ। ਦੁਬਾਰਾ ਕੈਪਚਰ ਕਰੋ।';

  @override
  String get documentScannedSaved => 'ਦਸਤਾਵੇਜ਼ ਸਕੈਨ ਅਤੇ ਸੰਭਾਲਿਆ ਗਿਆ!';

  @override
  String scanProcessingFailed(String error) {
    return 'ਸਕੈਨ ਪ੍ਰੋਸੈਸਿੰਗ ਅਸਫਲ: $error';
  }

  @override
  String get scanSavedToHistory =>
      'ਸਕੈਨ ਤੁਹਾਡੇ ਮੁਲਾਕਾਤ ਇਤਿਹਾਸ ਵਿੱਚ ਸੰਭਾਲਿਆ ਗਿਆ';

  @override
  String localNotificationSchedulingFailed(String error) {
    return 'ਸਥਾਨਕ ਸੂਚਨਾ ਸ਼ੈਡਿਊਲ ਅਸਫਲ: $error';
  }

  @override
  String reminderRescheduleFailed(String error) {
    return 'ਰਿਮਾਈਂਡਰ ਮੁੜ-ਸ਼ੈਡਿਊਲ ਅਸਫਲ: $error';
  }

  @override
  String get authenticationErrorLoginAgain =>
      'ਪ੍ਰਮਾਣੀਕਰਨ ਗਲਤੀ। ਦੁਬਾਰਾ ਲੌਗ ਇਨ ਕਰੋ।';
}
