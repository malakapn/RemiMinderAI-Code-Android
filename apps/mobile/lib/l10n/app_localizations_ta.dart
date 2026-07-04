// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appTitle => 'RemiMinder';

  @override
  String get login => 'உள்நுழை';

  @override
  String get logout => 'வெளியேறு';

  @override
  String get settings => 'அமைப்புகள்';

  @override
  String get language => 'மொழி';

  @override
  String get profileSettings => 'சுயவிவர அமைப்புகள்';

  @override
  String get languageSettings => 'மொழி';

  @override
  String languageUpdated(String language) {
    return 'மொழி புதுப்பிக்கப்பட்டது. பயன்பாடு இப்போது $language மொழியில் காட்டப்படும்.';
  }

  @override
  String get navHome => 'முகப்பு';

  @override
  String get navVisits => 'வருகைகள்';

  @override
  String get navOverview => 'சுருக்கம்';

  @override
  String get navCareTeam => 'குழு';

  @override
  String get navProfile => 'சுயவிவரம்';

  @override
  String get navPatients => 'நோயாளிகள்';

  @override
  String get goodMorning => 'காலை வணக்கம்';

  @override
  String get goodAfternoon => 'மதிய வணக்கம்';

  @override
  String get goodEvening => 'மாலை வணக்கம்';

  @override
  String get goodNight => 'இரவு வணக்கம்';

  @override
  String get howAreYouFeeling => 'இன்று நீங்கள் எப்படி உணர்கிறீர்கள்?';

  @override
  String get todaysProgress => 'இன்றைய முன்னேற்றம்';

  @override
  String doneCount(int done, int total) {
    return '$done/$total முடிந்தது';
  }

  @override
  String get yourSchedule => 'உங்கள் அட்டவணை';

  @override
  String get seeAll => 'அனைத்தும் →';

  @override
  String get nothingScheduledYet => 'இன்னும் எதுவும் திட்டமிடப்படவில்லை';

  @override
  String get unableToLoadReminders => 'நினைவூட்டல்களை ஏற்ற முடியவில்லை';

  @override
  String get addReminder => 'நினைவூட்டல் சேர்';

  @override
  String get myTasks => 'என் பணிகள்';

  @override
  String pendingCount(int count) {
    return '$count நிலுவையில்';
  }

  @override
  String get noTasksYet => 'இன்னும் பணிகள் இல்லை';

  @override
  String get addTask => 'பணி சேர்';

  @override
  String get statusUpcoming => 'வரவிருக்கும்';

  @override
  String get statusScheduled => 'திட்டமிடப்பட்டது';

  @override
  String get statusDone => 'முடிந்தது';

  @override
  String get reminder => 'நினைவூட்டல்';

  @override
  String get task => 'பணி';

  @override
  String get careTeamTitle => 'பராமரிப்பு குழு';

  @override
  String get careTeamSubtitle =>
      'கட்டுப்பாடு உங்களிடம். கீழே பகிர்வு அனுமதிகளைப் பாருங்கள்.';

  @override
  String get sectionPending => 'நிலுவையில்';

  @override
  String get sectionAddNew => 'புதிதாக சேர்';

  @override
  String get inviteCaregiver => 'பராமரிப்பாளரை அழை';

  @override
  String get inviteCaregiverSubtitle =>
      'உங்கள் சுகாதார தகவல்களுக்கான அணுகலைப் பகிர்';

  @override
  String get invitationPending => 'அழைப்பு நிலுவையில்';

  @override
  String get resend => 'மீண்டும் அனுப்பு';

  @override
  String get cancel => 'ரத்து';

  @override
  String get activeCaregivers => 'செயலில் உள்ள பராமரிப்பாளர்கள்';

  @override
  String get noCaregiversYet => 'இன்னும் பராமரிப்பாளர் சேர்க்கப்படவில்லை';

  @override
  String get english => 'ஆங்கிலம்';

  @override
  String get spanish => 'ஸ்பானிஷ்';

  @override
  String get hindi => 'ஹிந்தி';

  @override
  String get french => 'பிரெஞ்சு';

  @override
  String get portuguese => 'போர்த்துகீசியம்';

  @override
  String get german => 'ஜெர்மன்';

  @override
  String get bangla => 'வங்காளம்';

  @override
  String get tamil => 'தமிழ்';

  @override
  String get gujarati => 'ગુજરાતી';

  @override
  String get punjabi => 'ਪੰਜਾਬੀ';

  @override
  String get accountDetails => 'கணக்கு விவரங்கள்';

  @override
  String get accountDetailsSubtitle => 'உங்கள் சுயவிவர தகவலைப் பார்';

  @override
  String get accountSecurity => 'கணக்கு பாதுகாப்பு';

  @override
  String get accountSecuritySubtitle =>
      'கடவுச்சொல் மற்றும் தனியுரிமையை நிர்வகி';

  @override
  String get notificationsLabel => 'அறிவிப்புகள்';

  @override
  String get mobileLabel => 'மொபைல்';

  @override
  String get emailLabel => 'மின்னஞ்சல்';

  @override
  String get upgrade => 'மேம்படுத்து';

  @override
  String get signOut => 'வெளியேறு';

  @override
  String get deleteAccount => 'கணக்கை நீக்கு';

  @override
  String get deleteAccountTitle => 'கணக்கை நீக்கு';

  @override
  String get deleteAccountMessage =>
      'இது உங்கள் கணக்கையும் அனைத்து தரவையும் நிரந்தரமாக நீக்கும். இதை மீளமுடியாது. நிச்சயமா?';

  @override
  String get delete => 'நீக்கு';

  @override
  String get searchSummariesHint => 'சுருக்கங்களைத் தேடு...';

  @override
  String get tabSummaries => 'சுருக்கங்கள்';

  @override
  String get tabLabResults => 'ஆய்வகம்';

  @override
  String get tabScannedDocs => 'ஸ்கேன்';

  @override
  String get noSummariesYet => 'இன்னும் சுருக்கங்கள் இல்லை';

  @override
  String get summariesWillAppearHere =>
      'உங்கள் வருகை சுருக்கங்கள் இங்கே தோன்றும்';

  @override
  String get failedToLoadSummaries => 'சுருக்கங்களை ஏற்ற முடியவில்லை';

  @override
  String get retry => 'மீண்டும் முயற்சி';

  @override
  String get shareLabel => 'பகிர்';

  @override
  String get doctorVisit => 'மருத்துவ வருகை';

  @override
  String timeToday(String time) {
    return 'இன்று, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'நேற்று, $time';
  }

  @override
  String get summaryProcessingHint =>
      'புதுப்பிக்க கீழே இழுக்கவும். பொதுவாக 30–60 வினாடிகள் ஆகும்.';

  @override
  String get summaryCouldNotGenerate => 'சுருக்கம் உருவாக்க முடியவில்லை';

  @override
  String get retrySummary => 'சுருக்கத்தை மீண்டும் முயற்சி';

  @override
  String get stuckRetrySummary => 'சிக்கியதா? மீண்டும் முயற்சி';

  @override
  String get scannedDocument => 'ஸ்கேன் செய்யப்பட்ட ஆவணம்';

  @override
  String scannedOn(String date) {
    return 'ஸ்கேன் $date';
  }

  @override
  String get visitDetails => 'வருகை விவரங்கள்';

  @override
  String get healthVisitSummary => 'சுகாதார வருகை சுருக்கம்';

  @override
  String get refreshSummaryTooltip => 'சுருக்கத்தைப் புதுப்பி';

  @override
  String get preparingVisitSummary => 'வருகை சுருக்கம் தயாராகிறது...';

  @override
  String get preparingVisitSubtitle => 'ஒரு நிமிடம் ஆகலாம்.';

  @override
  String get unableToLoadVisitSummary => 'வருகை சுருக்கத்தை ஏற்ற முடியவில்லை';

  @override
  String get visitSummaryUnavailable => 'வருகை சுருக்கம் கிடைக்கவில்லை';

  @override
  String get visitSummary => 'வருகை சுருக்கம்';

  @override
  String get visitProcessingTitle => 'உங்கள் வருகை செயலாக்கப்படுகிறது';

  @override
  String get visitProcessingBody =>
      '30–60 வினாடிகள் ஆகலாம்.\nபயன்பாட்டைத் தொடரலாம். முன்னேற்றத்தைப் பார்க்க சுருக்கத்தைத் திறக்கவும்.';

  @override
  String get viewOverviewAction => 'சுருக்கத்தைப் பார்';

  @override
  String get goToHome => 'முகப்புக்குச் செல்';

  @override
  String get medication => 'மருந்து';

  @override
  String get nextToDo => 'அடுத்த படி';

  @override
  String get conditionsDiscussed => 'விவாதிக்கப்பட்ட நிலைகள்';

  @override
  String get followUp => 'பின்தொடர்தல்';

  @override
  String get nameLabel => 'பெயர்';

  @override
  String get notSet => 'அமைக்கப்படவில்லை';

  @override
  String get appleIdHidden => 'Apple ID (மறைக்கப்பட்டது)';

  @override
  String get accountType => 'கணக்கு வகை';

  @override
  String get patientRole => 'நோயாளி';

  @override
  String get caregiverRole => 'பராமரிப்பாளர்';

  @override
  String get phoneLabel => 'தொலைபேசி';

  @override
  String get edit => 'திருத்து';

  @override
  String get add => 'சேர்';

  @override
  String get planLabel => 'திட்டம்';

  @override
  String get planFree => 'இலவசம்';

  @override
  String get planPremium => 'பிரீமியம்';

  @override
  String get usageLabel => 'பயன்பாடு';

  @override
  String freePlanUsage(int used, int limit) {
    return 'இலவச திட்டம் — $used / $limit சுருக்கங்கள் பயன்படுத்தப்பட்டது';
  }

  @override
  String get unlimited => 'வரம்பற்றது';

  @override
  String get editPhoneNumber => 'தொலைபேசி எண்ணைத் திருத்து';

  @override
  String get phoneNumber => 'தொலைபேசி எண்';

  @override
  String get save => 'சேமி';

  @override
  String get phoneMinLength =>
      'தொலைபேசி எண் குறைந்தது 8 எழுத்துகள் இருக்க வேண்டும்';

  @override
  String get phoneUpdatedSuccess =>
      'தொலைபேசி எண் வெற்றிகரமாக புதுப்பிக்கப்பட்டது';

  @override
  String phoneUpdateFailed(String error) {
    return 'தொலைபேசி புதுப்பிப்பு தோல்வி: $error';
  }

  @override
  String get changePassword => 'கடவுச்சொல் மாற்று';

  @override
  String get changePasswordSubtitle =>
      'பாதுகாப்புக்காக கடவுச்சொல்லைப் புதுப்பி';

  @override
  String get privacySettings => 'தனியுரிமை அமைப்புகள்';

  @override
  String get privacySettingsSubtitle => 'தரவு பகிர்வு விருப்பங்களை நிர்வகி';

  @override
  String get managePrivacy => 'தனியுரிமையை நிர்வகி';

  @override
  String changePasswordProviderMessage(String provider) {
    return 'நீங்கள் $provider மூலம் உள்நுழைந்தீர்கள். $provider கணக்கில் கடவுச்சொல்லை மாற்றவும்.';
  }

  @override
  String get ok => 'சரி';

  @override
  String get selectDate => 'தேதியைத் தேர்வு';

  @override
  String get changePasswordIntro =>
      'கணக்கைப் பாதுகாக்க கடவுச்சொல்லைப் புதுப்பிக்கவும்.';

  @override
  String get currentPassword => 'தற்போதைய கடவுச்சொல்';

  @override
  String get currentPasswordHint => 'தற்போதைய கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get enterCurrentPassword => 'தற்போதைய கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get newPassword => 'புதிய கடவுச்சொல்';

  @override
  String get newPasswordHint => 'புதிய கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get enterNewPassword => 'புதிய கடவுச்சொல்லை உள்ளிடவும்';

  @override
  String get passwordMinLength =>
      'கடவுச்சொல் குறைந்தது 8 எழுத்துகள் இருக்க வேண்டும்';

  @override
  String get confirmNewPassword => 'புதிய கடவுச்சொல்லை உறுதிசெய்';

  @override
  String get confirmNewPasswordHint => 'புதிய கடவுச்சொல்லை மீண்டும் உள்ளிடவும்';

  @override
  String get confirmNewPasswordRequired => 'புதிய கடவுச்சொல்லை உறுதிசெய்யவும்';

  @override
  String get passwordsDoNotMatch => 'கடவுச்சொற்கள் பொருந்தவில்லை';

  @override
  String get updatePassword => 'கடவுச்சொல்லைப் புதுப்பி';

  @override
  String get passwordUpdatedSuccess =>
      'கடவுச்சொல் வெற்றிகரமாக புதுப்பிக்கப்பட்டது';

  @override
  String get passwordUpdateFailed => 'கடவுச்சொல் புதுப்பிப்பு தோல்வி';

  @override
  String get wrongPassword => 'தற்போதைய கடவுச்சொல் தவறானது';

  @override
  String get weakPassword => 'கடவுச்சொல் மிகவும் பலவீனமானது';

  @override
  String get requiresRecentLogin => 'மீண்டும் உள்நுழைந்து முயற்சிக்கவும்';

  @override
  String get checkInternetConnection => 'இணைய இணைப்பைச் சரிபார்க்கவும்';

  @override
  String get dataSharing => 'தரவு பகிர்வு';

  @override
  String get allowCaregiverSummaries =>
      'பராமரிப்பாளர் சுருக்கங்களைப் பார்க்க அனுமதி';

  @override
  String get allowCaregiverMedications =>
      'பராமரிப்பாளர் மருந்துகளைப் பார்க்க அனுமதி';

  @override
  String get allowCaregiverReminders =>
      'பராமரிப்பாளர் நினைவூட்டல்களைப் பார்க்க அனுமதி';

  @override
  String get allowAiImprovement =>
      'AI என் தரவை தயாரிப்பு மேம்பாட்டுக்கு பயன்படுத்த அனுமதி';

  @override
  String get communicationAndConsent => 'தொடர்பு & ஒப்புதல்';

  @override
  String get allowEmailNotifications => 'மின்னஞ்சல் அறிவிப்புகளை அனுமதி';

  @override
  String get allowSmsNotifications => 'SMS அறிவிப்புகளை அனுமதி';

  @override
  String get allowPushNotifications => 'புஷ் அறிவிப்புகளை அனுமதி';

  @override
  String get dataControl => 'தரவு கட்டுப்பாடு';

  @override
  String get exportMyData => 'என் தரவை ஏற்றுமதி செய்';

  @override
  String get deleteAllMedicalRecords =>
      'என் அனைத்து மருத்துவ பதிவுகளையும் நீக்கு';

  @override
  String get deleteMedicalRecordsTitle => 'மருத்துவ பதிவுகளை நீக்கு';

  @override
  String get deleteMedicalRecordsMessage =>
      'இது உங்கள் அனைத்து மருத்துவ பதிவுகளையும் நிரந்தரமாக நீக்கும். இதை மீளமுடியாது.';

  @override
  String get deleteRecords => 'பதிவுகளை நீக்கு';

  @override
  String get deleteMyAccount => 'என் கணக்கை நீக்கு';

  @override
  String get legal => 'சட்டம்';

  @override
  String get viewPrivacyPolicy => 'தனியுரிமைக் கொள்கையைப் பார்';

  @override
  String get viewTermsOfService => 'சேவை விதிமுறைகளைப் பார்';

  @override
  String get termsOfService => 'சேவை விதிமுறைகள்';

  @override
  String get termsOfServiceBody =>
      'RemiMinder சேவை விதிமுறைகள்\n\n1. விதிமுறை ஏற்பு\nRemiMinder பயன்படுத்துவதன் மூலம் இந்த விதிமுறைகளை ஏற்கிறீர்கள்.\n\n2. சேவை பயன்பாடு\nRemiMinder சுகாதாரம் மற்றும் மருந்து நினைவூட்டல்களை நிர்வகிக்க உதவுகிறது.\n\n3. தனியுரிமை\nஉங்கள் தனியுரிமை முக்கியம். அனைத்து சுகாதார தரவும் பாதுகாப்பாக கையாளப்படுகிறது.\n\nமுழு விதிமுறைகளுக்கு எங்கள் வலைத்தளத்தைப் பாருங்கள்.';

  @override
  String get privacyPolicy => 'தனியுரிமைக் கொள்கை';

  @override
  String get privacyPolicyBody =>
      'RemiMinder தனியுரிமைக் கொள்கை\n\n1. நாங்கள் சேகரிக்கும் தகவல்\nநீங்கள் வழங்கும் தகவல் மற்றும் பயன்பாட்டு தரவை சேகரிக்கிறோம்.\n\n2. தகவல் பயன்பாடு\nசுகாதார நிர்வாக சேவைகளுக்கு தகவல் பயன்படுத்தப்படுகிறது.\n\n3. தகவல் பகிர்வு\nஉங்கள் தனிப்பட்ட தகவலை விற்க மாட்டோம்.\n\nமுழு கொள்கைக்கு எங்கள் வலைத்தளத்தைப் பாருங்கள்.';

  @override
  String get close => 'மூடு';

  @override
  String featureComingSoon(String feature) {
    return '$feature விரைவில் வரும்';
  }

  @override
  String get caregiverSharingEnabled => 'பராமரிப்பாளர் பகிர்வு இயக்கப்பட்டது';

  @override
  String get caregiverSharingDisabled => 'பராமரிப்பாளர் பகிர்வு முடக்கப்பட்டது';

  @override
  String get dataExport => 'தரவு ஏற்றுமதி';

  @override
  String get remindersTitle => 'நினைவூட்டல்கள்';

  @override
  String get tabAll => 'அனைத்தும்';

  @override
  String get tabToday => 'இன்று';

  @override
  String get tabPending => 'நிலுவை';

  @override
  String get tabCompleted => 'முடிந்தது';

  @override
  String get searchRemindersHint => 'நினைவூட்டல்களைத் தேடு...';

  @override
  String get failedToLoadRemindersRetry => 'ஏற்ற முடியவில்லை. மீண்டும்';

  @override
  String get deleteReminderTitle => 'நினைவூட்டலை நீக்கு';

  @override
  String get deleteReminderMessage =>
      'இந்த நினைவூட்டலை நீக்க விரும்புகிறீர்களா?';

  @override
  String get markDone => 'முடிந்தது';

  @override
  String get snooze => 'தள்ளிப்போடு';

  @override
  String snoozedUntil(String time) {
    return '$time வரை தள்ளிப்போடு';
  }

  @override
  String get statusDueNow => 'இப்போது';

  @override
  String get statusActive => 'செயலில்';

  @override
  String get statusMissed => 'தவறியது';

  @override
  String get statusSnoozed => 'தள்ளிப்போடு';

  @override
  String get statusSkipped => 'தவிர்க்கப்பட்டது';

  @override
  String get statusPending => 'நிலுவை';

  @override
  String get noRemindersFound => 'நினைவூட்டல்கள் இல்லை';

  @override
  String get noRemindersMatchSearch => 'பொருந்தவில்லை';

  @override
  String get createFirstReminder => 'தொடங்க முதல் நினைவூட்டலை உருவாக்குங்கள்';

  @override
  String get tryAdjustSearch => 'வேறு தேடல் சொற்களை முயற்சிக்கவும்';

  @override
  String get createReminder => 'நினைவூட்டல் உருவாக்கு';

  @override
  String get newReminder => 'புதிய நினைவூட்டல்';

  @override
  String get editReminder => 'நினைவூட்டலைத் திருத்து';

  @override
  String get reminderTitleLabel => 'தலைப்பு';

  @override
  String get dosageOptional => 'அளவு (விரும்பினால்)';

  @override
  String get dosageHint => 'எ.கா. 10 mg நாளொன்றுக்கு ஒருமுறை';

  @override
  String get reminderTypeLabel => 'வகை';

  @override
  String get appointment => 'சந்திப்பு';

  @override
  String get repeatLabel => 'மீண்டும்';

  @override
  String get once => 'ஒருமுறை';

  @override
  String get daily => 'தினசரி';

  @override
  String get weekly => 'வாராந்திர';

  @override
  String get pleaseEnterTitle => 'தலைப்பை உள்ளிடவும்';

  @override
  String get reminderCreated => 'நினைவூட்டல் உருவாக்கப்பட்டது!';

  @override
  String failedToCreateReminder(String error) {
    return 'உருவாக்க முடியவில்லை: $error';
  }

  @override
  String get saveChanges => 'மாற்றங்களைச் சேமி';

  @override
  String get cannotRescheduleMissingType => 'மறுதிட்டமிட முடியாது: வகை இல்லை';

  @override
  String get reminderUpdated => 'நினைவூட்டல் புதுப்பிக்கப்பட்டது!';

  @override
  String failedToUpdateReminder(String error) {
    return 'புதுப்பிப்பு தோல்வி: $error';
  }

  @override
  String get reminderMarkedCompleted => 'நினைவூட்டல் முடிந்தது!';

  @override
  String get reminderSnoozed30 => '30 நிமிடம் தள்ளிப்போடு';

  @override
  String timeInHours(int hours, String time) {
    return '$hours மணி நேரத்தில் ($time)';
  }

  @override
  String timeInMinutes(int minutes, String time) {
    return '$minutes நிமிடத்தில் ($time)';
  }

  @override
  String get timeNow => 'இப்போது';

  @override
  String timeHoursAgo(int hours) {
    return '$hours மணி நேரம் முன்பு';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes நிமிடம் முன்பு';
  }

  @override
  String timeInDays(int days) {
    return '$days நாட்களில்';
  }

  @override
  String timeInHoursShort(int hours) {
    return '$hours மணி நேரத்தில்';
  }

  @override
  String timeInMinutesShort(int minutes) {
    return '$minutes நிமிடத்தில்';
  }

  @override
  String get selectTime => 'நேரம் தேர்வு';

  @override
  String get presetMorning => 'காலை (8:00)';

  @override
  String get presetNoon => 'மதியம் (12:00)';

  @override
  String get presetEvening => 'மாலை (6:00)';

  @override
  String get presetNight => 'இரவு (8:00)';

  @override
  String get hourLabel => 'மணி';

  @override
  String get minuteLabel => 'நிமி';

  @override
  String get amPmLabel => 'AM / PM';

  @override
  String get amLabel => 'AM';

  @override
  String get pmLabel => 'PM';

  @override
  String selectedTimeLabel(String time) {
    return 'தேர்ந்தெடுத்த நேரம்: $time';
  }

  @override
  String setForTime(String time) {
    return '$time அமை ✓';
  }

  @override
  String get medicationAdherence => 'மருந்து adherence';

  @override
  String get thisWeek => 'இந்த வாரம்';

  @override
  String get thisMonth => 'இந்த மாதம்';

  @override
  String get overall => 'மொத்தம்';

  @override
  String dosesCount(int done, int total) {
    return '$done/$total doses';
  }

  @override
  String get byMedication => 'மருந்து வாரியாக';

  @override
  String get noPastRemindersAnalyze =>
      'பகுப்பாய்வுக்கு பழைய நினைவூட்டல்கள் இல்லை';

  @override
  String get adherenceTips => 'Adherence குறிப்புகள்';

  @override
  String get adherenceTipsBody =>
      '• மருந்து நேரத்திற்கு ஃபோன் நினைவூட்டல்\n• மருந்துகளை தெரியும் இடத்தில் வைக்க\n• pill organizer பயன்படுத்த\n• முன்னேற்றத்தை கண்காணி';

  @override
  String get actionFailed => 'செயல் தோல்வி';

  @override
  String get snoozeAlreadyUsed =>
      'இந்த நினைவூட்டல் ஏற்கனவே ஒருமுறை தள்ளிப்போடப்பட்டது';

  @override
  String get reminderDeleted => 'நினைவூட்டல் நீக்கப்பட்டது';

  @override
  String get deleteFailed => 'நீக்குதல் தோல்வி';

  @override
  String get sectionRecentAlerts => 'சமீபத்திய எச்சரிக்கைகள்';

  @override
  String get viewAll => 'அனைத்தையும் காண்க';

  @override
  String get sectionInvitations => 'அழைப்புகள்';

  @override
  String get summaryPatients => 'நோயாளிகள்';

  @override
  String get summaryAlerts => 'எச்சரிக்கைகள்';

  @override
  String get summaryPending => 'நிலுவையில்';

  @override
  String get noAlertsAtThisTime => 'இப்போது எச்சரிக்கைகள் இல்லை';

  @override
  String get noPendingInvitations => 'நிலுவையில் அழைப்புகள் இல்லை';

  @override
  String get pendingInvitationsTitle => 'நிலுவையில் அழைப்புகள்';

  @override
  String invitationsWaiting(int count) {
    return '$count அழைப்பு(கள்) காத்திருக்கின்றன';
  }

  @override
  String get reviewAcceptInvitations =>
      'பராமரிப்பாளர் அழைப்புகளை மதிப்பாய்வு செய்து ஏற்கவும்.';

  @override
  String get viewInvitations => 'அழைப்புகளைக் காண்க';

  @override
  String get defaultPatient => 'நோயாளி';

  @override
  String get defaultCaregiver => 'பராமரிப்பாளர்';

  @override
  String caregiverPatientTime(String name, String time) {
    return 'நோயாளி: $name • $time';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days நாட்களுக்கு முன்';
  }

  @override
  String get alertsTitle => 'எச்சரிக்கைகள்';

  @override
  String get filterUnread => 'படிக்காதவை';

  @override
  String get filterRead => 'படித்தவை';

  @override
  String get filterHighPriority => 'உயர் முன்னுரிமை';

  @override
  String get filterActionRequired => 'நடவடிக்கை தேவை';

  @override
  String get alertSingular => 'எச்சரிக்கை';

  @override
  String get alertsPlural => 'எச்சரிக்கைகள்';

  @override
  String get clearFilter => 'வடிகட்டியை அழிக்க';

  @override
  String get noAlertsMatchFilter =>
      'இந்த வடிகட்டிக்கு எச்சரிக்கைகள் பொருந்தவில்லை';

  @override
  String get allPatientActivitiesSmooth =>
      'அனைத்து நோயாளி செயல்பாடுகளும் சீராக உள்ளன';

  @override
  String get tryAdjustingFilter =>
      'மேலும் எச்சரிக்கைகளைக் காண வடிகட்டியை சரிசெய்யவும்';

  @override
  String get viewAllAlerts => 'அனைத்து எச்சரிக்கைகளையும் காண்க';

  @override
  String get alertMarkedAsRead => 'எச்சரிக்கை படித்ததாகக் குறிக்கப்பட்டது';

  @override
  String alertsMarkedAsRead(int count) {
    return '$count எச்சரிக்கைகள் படித்ததாகக் குறிக்கப்பட்டன';
  }

  @override
  String get allAlertsAlreadyRead =>
      'அனைத்து எச்சரிக்கைகளும் ஏற்கனவே படிக்கப்பட்டவை';

  @override
  String get myPatientsTitle => 'என் நோயாளிகள்';

  @override
  String get patientsConnectedSubtitle => 'உங்களுடன் இணைக்கப்பட்ட நோயாளிகள்';

  @override
  String get myPatientsSection => 'என் நோயாளிகள்';

  @override
  String connectedCount(int count) {
    return '$count இணைக்கப்பட்டது';
  }

  @override
  String get searchPatientsHint => 'நோயாளிகளைத் தேடுங்கள்...';

  @override
  String get noPatientsMatchSearch =>
      'உங்கள் தேடலுக்கு நோயாளிகள் பொருந்தவில்லை.';

  @override
  String get noPatientsConnectedYet => 'இன்னும் நோயாளிகள் இணைக்கப்படவில்லை';

  @override
  String get acceptInvitationToSeePatient => 'நோயாளியைக் காண அழைப்பை ஏற்கவும்.';

  @override
  String get badgeNew => 'புதிய';

  @override
  String joinedOn(String date) {
    return 'சேர்ந்தது $date';
  }

  @override
  String get neverSynced => 'இன்னும் ஏற்றப்படவில்லை';

  @override
  String get privacyDataRequestMessage =>
      'உங்கள் தரவை ஏற்றுமதி அல்லது நீக்க privacy@remiminder.ai ஐ தொடர்பு கொள்ளுங்கள்.';

  @override
  String syncMinutesAgo(int minutes) {
    return '$minutes நி. முன்';
  }

  @override
  String syncHoursAgo(int hours) {
    return '$hours ம. முன்';
  }

  @override
  String syncDaysAgo(int days) {
    return '$days நா. முன்';
  }

  @override
  String get primaryCondition => 'முதன்மை நிலை';

  @override
  String get lastSynced => 'கடைசி ஒத்திசைவு';

  @override
  String get allergiesLabel => 'ஒவ்வாமை';

  @override
  String get dateOfBirth => 'பிறந்த தேதி';

  @override
  String get currentMedications => 'தற்போதைய மருந்துகள்';

  @override
  String get viewCarePlan => 'பராமரிப்பு திட்டத்தைக் காண்க';

  @override
  String get remindersButton => 'நினைவூட்டல்கள்';

  @override
  String get caregiverCareTeamSubtitle =>
      'குடும்பம் அல்லது மருத்துவ பணியாளர்களை அழைக்கவும்';

  @override
  String get invitationsReceived => 'பெறப்பட்ட அழைப்புகள்';

  @override
  String pendingBadge(int count) {
    return '$count நிலுவையில்';
  }

  @override
  String get patientOverviewTitle => 'நோயாளி கண்ணோட்டம்';

  @override
  String get patientOverviewTabVisits => 'வருகைகள்';

  @override
  String get patientOverviewTabReminders => 'நினைவூட்டல்கள்';

  @override
  String get patientOverviewNoVisits => 'வருகைகள் இல்லை';

  @override
  String get patientOverviewNoReminders => 'நினைவூட்டல்கள் இல்லை';

  @override
  String get patientOverviewMissingPatientId => 'நோயாளி தகவல் இல்லை';

  @override
  String get patientOverviewLastVisit => 'கடைசி வருகை';

  @override
  String get patientOverviewCareTeam => 'பராமரிப்பு குழு உறுப்பினர்';

  @override
  String get patientOverviewScheduledReminder => 'திட்டமிடப்பட்ட நினைவூட்டல்';

  @override
  String get patientOverviewNever => 'ஒருபோதும் இல்லை';

  @override
  String get patientOverviewYesterday => 'நேற்று';

  @override
  String get statusViewed => 'பார்க்கப்பட்டது';

  @override
  String get statusExpired => 'காலாவதி';

  @override
  String get statusJoined => 'சேர்ந்தார்';

  @override
  String get noInvitationsToShow => 'காட்ட எந்த அழைப்பும் இல்லை';

  @override
  String invitedByLabel(String name) {
    return 'அழைத்தவர்: $name';
  }

  @override
  String get acceptInvitation => 'ஏற்க';

  @override
  String get declineInvitation => 'நிராகரி';

  @override
  String get invitationDeclined => 'அழைப்பு நிராகரிக்கப்பட்டது';

  @override
  String joinedCareTeamSnackbar(String patientName, String role) {
    return '$patientName பராமரிப்பு குழுவில் $role ஆக சேர்ந்தார்';
  }

  @override
  String get manageAccess => 'அணுகலை நிர்வகி';

  @override
  String get manageAccessDescription =>
      'பராமரிப்பாளர் அனுமதியை புதுப்பிக்கவும் அல்லது அணுகலை நீக்கவும்.';

  @override
  String get manage => 'நிர்வகி';

  @override
  String get accessUpdatedSuccess => 'அணுகல் வெற்றிகரமாக புதுப்பிக்கப்பட்டது';

  @override
  String get accessUpdateFailed =>
      'அணுகலை புதுப்பிக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get removeCaregiverTitle => 'பராமரிப்பாளரை நீக்கவா?';

  @override
  String get removeCaregiverMessage =>
      'இந்த பராமரிப்பாளரை நீக்க விரும்புகிறீர்களா? அவர்களின் அணுகல் உடனடியாக நிறுத்தப்படும்.';

  @override
  String get remove => 'நீக்கு';

  @override
  String get updatingAccess => 'அணுகல் புதுப்பிக்கப்படுகிறது...';

  @override
  String get removingCaregiver => 'பராமரிப்பாளர் நீக்கப்படுகிறார்...';

  @override
  String get removeCaregiverFailed =>
      'பராமரிப்பாளரை நீக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get viewAccess => 'பார்வை அணுகல்';

  @override
  String get fullAccess => 'முழு அணுகல்';

  @override
  String get viewOnly => 'பார்வை மட்டும்';

  @override
  String get resendingInvitation => 'அழைப்பு மீண்டும் அனுப்பப்படுகிறது...';

  @override
  String get invitationResent => 'அழைப்பு மீண்டும் அனுப்பப்பட்டது';

  @override
  String get failedToResendInvitation => 'அழைப்பை மீண்டும் அனுப்ப முடியவில்லை';

  @override
  String get cancelingInvitation => 'அழைப்பு ரத்து செய்யப்படுகிறது...';

  @override
  String get invitationCanceled => 'அழைப்பு ரத்து';

  @override
  String get failedToCancelInvitation => 'அழைப்பை ரத்து செய்ய முடியவில்லை';

  @override
  String get relationshipSon => 'மகன்';

  @override
  String get relationshipDaughter => 'மகள்';

  @override
  String get relationshipFriend => 'நண்பர்';

  @override
  String get relationshipSpousePartner => 'வாழ்க்கைத் துணை/துணை';

  @override
  String get relationshipParent => 'பெற்றோர்';

  @override
  String get relationshipChild => 'குழந்தை';

  @override
  String get relationshipFamilyMember => 'குடும்ப உறுப்பினர்';

  @override
  String get relationshipHealthcareProfessional => 'சுகாதார நிபுணர்';

  @override
  String get relationshipCaregiver => 'பராமரிப்பாளர்';

  @override
  String get relationshipSister => 'சகோதரி';

  @override
  String get relationshipBrother => 'சகோதரர்';

  @override
  String get relationshipOther => 'மற்றவை';

  @override
  String get visitActionTitle => 'நீங்கள் என்ன செய்ய விரும்புகிறீர்கள்?';

  @override
  String get visitActionAudioTitle => 'ஆடியோ உரையாடலை பதிவு செய்';

  @override
  String get visitActionAudioSubtitle =>
      'தானியங்கி சுருக்கத்திற்கு உங்கள் மருத்துவர் வருகையை பதிவு செய்யுங்கள்';

  @override
  String get visitActionCaptureTitle => 'பிடித்து ஸ்கேன் செய்';

  @override
  String get visitActionCaptureSubtitle =>
      'அறிக்கைகள், மருந்து பாட்டில்கள் மற்றும் ஆவணங்களின் புகைப்படங்களை எடுக்கவும்';

  @override
  String get inviteCaregiverDialogTitle => 'பராமரிப்பாளரை அழை';

  @override
  String get caregiverNameHint => 'பராமரிப்பாளரின் முழு பெயரை உள்ளிடவும்';

  @override
  String get caregiverEmailHint => 'பராமரிப்பாளரின் மின்னஞ்சலை உள்ளிடவும்';

  @override
  String get relationshipLabel => 'உறவு';

  @override
  String get relationshipHint => 'எ.கா., மகன், மகள், நண்பர், செவிலியர்';

  @override
  String get sendInvite => 'அழைப்பு அனுப்பு';

  @override
  String get emailAndRoleRequired => 'மின்னஞ்சல் மற்றும் பாத்திரம் தேவை';

  @override
  String get summaryReadyTitle => 'உங்கள் வருகை சுருக்கம் தயார்!';

  @override
  String get summaryReadyBody => 'இப்போது பார்க்க விரும்புகிறீர்களா?';

  @override
  String get later => 'பின்னர்';

  @override
  String get viewSummary => 'சுருக்கத்தைப் பார்';

  @override
  String get noLabResultsYet => 'இன்னும் ஆய்வக முடிவுகள் இல்லை';

  @override
  String get labResultsScanHint =>
      'முடிவுகளை இங்கே பார்க்க பிடித்து ஸ்கேன் மூலம் ஆய்வக அறிக்கையை ஸ்கேன் செய்யுங்கள்.';

  @override
  String get captureAndScan => 'பிடித்து ஸ்கேன் செய்';

  @override
  String get noScannedDocsYet => 'இன்னும் ஸ்கேன் செய்யப்பட்ட ஆவணங்கள் இல்லை';

  @override
  String get scannedDocsHint =>
      'உங்கள் வருகைகளின் போது ஸ்கேன் செய்யப்பட்ட ஆவணங்கள் இங்கே தோன்றும்.';

  @override
  String get selectAtLeastOneSummary =>
      'குறைந்தது ஒரு சுருக்கத்தைத் தேர்ந்தெடுக்கவும்';

  @override
  String get failedToDeleteSummaries =>
      'சுருக்கங்களை நீக்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get noCaregiverAddedYet => 'இன்னும் பராமரிப்பாளர் சேர்க்கப்படவில்லை';

  @override
  String get summaryGenerationRestarted =>
      'சுருக்க உருவாக்கம் மீண்டும் தொடங்கியது';

  @override
  String retryFailed(String error) {
    return 'மீண்டும் முயற்சி தோல்வி: $error';
  }

  @override
  String get generateSummary => 'சுருக்கம் உருவாக்கு';

  @override
  String get discardRecording => 'பதிவை நிராகரி';

  @override
  String unableToStartRecording(String error) {
    return 'பதிவைத் தொடங்க முடியவில்லை: $error';
  }

  @override
  String get recordingCompleted => 'பதிவு முடிந்தது!';

  @override
  String unableToStopRecording(String error) {
    return 'பதிவை நிறுத்த முடியவில்லை: $error';
  }

  @override
  String get recordingDiscarded => 'பதிவு நிராகரிக்கப்பட்டது';

  @override
  String get unableToOpenPrivacyPolicy =>
      'தனியுரிமைக் கொள்கையைத் திறக்க முடியவில்லை.';

  @override
  String get noRecordingAvailable => 'பதிவு இல்லை';

  @override
  String get uploadingAudio => 'ஆடியோ பதிவேற்றப்படுகிறது...';

  @override
  String failedToUploadAudio(String error) {
    return 'ஆடியோ பதிவேற்றம் தோல்வி: $error';
  }

  @override
  String get stopRecordingTitle => 'பதிவை நிறுத்தவா?';

  @override
  String get stopRecordingMessage =>
      'Are you sure you want to stop recording? This action cannot be undone.';

  @override
  String get continueRecording => 'பதிவைத் தொடரவும்';

  @override
  String get stopAndDiscard => 'நிறுத்தி நிராகரி';

  @override
  String get share => 'பகிர்';

  @override
  String get cameraNotReady => 'கேமரா தயாராக இல்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String failedToCaptureImage(String error) {
    return 'படம் எடுப்பு தோல்வி: $error';
  }

  @override
  String get unableToStartCamera =>
      'கேமராவைத் தொடங்க முடியவில்லை. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get cameraReadyHint =>
      'கேமரா தயார். ஆவணத்தை வைத்து கேப்சர் அழுத்தவும்.';

  @override
  String unableToStartScanning(String error) {
    return 'ஸ்கேன் தொடங்க முடியவில்லை: $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'படம் பதிவேற்றம் தோல்வி: $error';
  }

  @override
  String get noImageToProcess => 'செயலாக்க படம் இல்லை. மீண்டும் எடுக்கவும்.';

  @override
  String get documentScannedSaved => 'ஆவணம் ஸ்கேன் செய்து சேமிக்கப்பட்டது!';

  @override
  String scanProcessingFailed(String error) {
    return 'ஸ்கேன் செயலாக்கம் தோல்வி: $error';
  }

  @override
  String get scanSavedToHistory =>
      'ஸ்கேன் உங்கள் வருகை வரலாற்றில் சேமிக்கப்பட்டது';

  @override
  String localNotificationSchedulingFailed(String error) {
    return 'உள்ளூர் அறிவிப்பு திட்டமிடல் தோல்வி: $error';
  }

  @override
  String reminderRescheduleFailed(String error) {
    return 'நினைவூட்டல் மறுதிட்டமிடல் தோல்வி: $error';
  }

  @override
  String get authenticationErrorLoginAgain =>
      'அங்கீகார பிழை. மீண்டும் உள்நுழையவும்.';
}
