// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'RemiMinder';

  @override
  String get login => 'लॉग इन';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get settings => 'सेटिंग्स';

  @override
  String get language => 'भाषा';

  @override
  String get profileSettings => 'प्रोफ़ाइल सेटिंग्स';

  @override
  String get languageSettings => 'भाषा';

  @override
  String languageUpdated(String language) {
    return 'भाषा अपडेट हो गई। अब ऐप $language में दिखेगा।';
  }

  @override
  String get navHome => 'होम';

  @override
  String get navVisits => 'विज़िट';

  @override
  String get navOverview => 'अवलोकन';

  @override
  String get navCareTeam => 'केयर टीम';

  @override
  String get navProfile => 'प्रोफ़ाइल';

  @override
  String get navPatients => 'मरीज़';

  @override
  String get goodMorning => 'सुप्रभात';

  @override
  String get goodAfternoon => 'नमस्कार';

  @override
  String get goodEvening => 'शुभ संध्या';

  @override
  String get goodNight => 'शुभ रात्रि';

  @override
  String get howAreYouFeeling => 'आज आप कैसा महसूस कर रहे हैं?';

  @override
  String get todaysProgress => 'आज की प्रगति';

  @override
  String doneCount(int done, int total) {
    return '$done/$total पूर्ण';
  }

  @override
  String get yourSchedule => 'आपका शेड्यूल';

  @override
  String get seeAll => 'सभी देखें →';

  @override
  String get nothingScheduledYet => 'अभी कुछ निर्धारित नहीं';

  @override
  String get unableToLoadReminders => 'रिमाइंडर लोड नहीं हो सके';

  @override
  String get addReminder => 'रिमाइंडर जोड़ें';

  @override
  String get myTasks => 'मेरे कार्य';

  @override
  String pendingCount(int count) {
    return '$count लंबित';
  }

  @override
  String get noTasksYet => 'अभी कोई कार्य नहीं';

  @override
  String get addTask => 'कार्य जोड़ें';

  @override
  String get statusUpcoming => 'आगामी';

  @override
  String get statusScheduled => 'निर्धारित';

  @override
  String get statusDone => 'पूर्ण';

  @override
  String get reminder => 'रिमाइंडर';

  @override
  String get task => 'कार्य';

  @override
  String get careTeamTitle => 'केयर टीम';

  @override
  String get careTeamSubtitle =>
      'नियंत्रण आपके पास है। नीचे अपनी साझा अनुमतियाँ देखें।';

  @override
  String get sectionPending => 'लंबित';

  @override
  String get sectionAddNew => 'नया जोड़ें';

  @override
  String get inviteCaregiver => 'केयरगिवर को आमंत्रित करें';

  @override
  String get inviteCaregiverSubtitle =>
      'अपनी स्वास्थ्य जानकारी तक पहुँच साझा करें';

  @override
  String get invitationPending => 'आमंत्रण लंबित';

  @override
  String get resend => 'पुनः भेजें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get activeCaregivers => 'सक्रिय केयरगिवर';

  @override
  String get noCaregiversYet => 'अभी कोई केयरगिवर नहीं जोड़ा गया';

  @override
  String get english => 'अंग्रेज़ी';

  @override
  String get spanish => 'स्पेनिश';

  @override
  String get hindi => 'हिन्दी';

  @override
  String get french => 'फ़्रेंच';

  @override
  String get portuguese => 'पुर्तगाली';

  @override
  String get german => 'जर्मन';

  @override
  String get bangla => 'बांग्ला';

  @override
  String get tamil => 'तमिल';

  @override
  String get gujarati => 'ગુજરાતી';

  @override
  String get punjabi => 'ਪੰਜਾਬੀ';

  @override
  String get accountDetails => 'खाता विवरण';

  @override
  String get accountDetailsSubtitle => 'अपनी प्रोफ़ाइल जानकारी देखें';

  @override
  String get accountSecurity => 'खाता सुरक्षा';

  @override
  String get accountSecuritySubtitle => 'पासवर्ड और गोपनीयता प्रबंधित करें';

  @override
  String get notificationsLabel => 'सूचनाएँ';

  @override
  String get mobileLabel => 'मोबाइल';

  @override
  String get emailLabel => 'ईमेल';

  @override
  String get upgrade => 'अपग्रेड';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get deleteAccount => 'खाता हटाएँ';

  @override
  String get deleteAccountTitle => 'खाता हटाएँ';

  @override
  String get deleteAccountMessage =>
      'यह आपका खाता और सभी डेटा स्थायी रूप से हटा देगा। यह पूर्ववत नहीं हो सकता। क्या आप सुनिश्चित हैं?';

  @override
  String get delete => 'हटाएँ';

  @override
  String get searchSummariesHint => 'सारांश खोजें...';

  @override
  String get tabSummaries => 'सारांश';

  @override
  String get tabLabResults => 'लैब परिणाम';

  @override
  String get tabScannedDocs => 'स्कैन किए';

  @override
  String get noSummariesYet => 'अभी कोई सारांश नहीं';

  @override
  String get summariesWillAppearHere => 'आपके विज़िट सारांश यहाँ दिखेंगे';

  @override
  String get failedToLoadSummaries => 'सारांश लोड नहीं हो सके';

  @override
  String get retry => 'पुनः प्रयास';

  @override
  String get shareLabel => 'साझा करें';

  @override
  String get doctorVisit => 'डॉक्टर विज़िट';

  @override
  String timeToday(String time) {
    return 'आज, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'कल, $time';
  }

  @override
  String get summaryProcessingHint =>
      'रिफ्रेश करने के लिए नीचे खींचें। आमतौर पर 30–60 सेकंड लगते हैं।';

  @override
  String get summaryCouldNotGenerate => 'सारांश नहीं बनाया जा सका';

  @override
  String get retrySummary => 'सारांश पुनः प्रयास';

  @override
  String get stuckRetrySummary => 'अटका? पुनः प्रयास';

  @override
  String get scannedDocument => 'स्कैन किया दस्तावेज़';

  @override
  String scannedOn(String date) {
    return 'स्कैन $date';
  }

  @override
  String get visitDetails => 'विज़िट विवरण';

  @override
  String get healthVisitSummary => 'स्वास्थ्य विज़िट सारांश';

  @override
  String get refreshSummaryTooltip => 'सारांश रिफ्रेश करें';

  @override
  String get preparingVisitSummary => 'विज़िट सारांश तैयार हो रहा है...';

  @override
  String get preparingVisitSubtitle => 'इसमें एक मिनट लग सकता है।';

  @override
  String get unableToLoadVisitSummary => 'विज़िट सारांश लोड नहीं हो सका';

  @override
  String get visitSummaryUnavailable => 'विज़िट सारांश उपलब्ध नहीं';

  @override
  String get visitSummary => 'विज़िट सारांश';

  @override
  String get visitProcessingTitle => 'आपकी यात्रा संसाधित हो रही है';

  @override
  String get visitProcessingBody =>
      'इसमें 30–60 सेकंड लग सकते हैं।\nआप ऐप का उपयोग जारी रख सकते हैं। प्रगति देखने के लिए अवलोकन खोलें।';

  @override
  String get viewOverviewAction => 'अवलोकन देखें';

  @override
  String get goToHome => 'होम पर जाएँ';

  @override
  String get medication => 'दवा';

  @override
  String get nextToDo => 'अगले कार्य';

  @override
  String get conditionsDiscussed => 'चर्चित स्थितियाँ';

  @override
  String get followUp => 'फ़ॉलो-अप';

  @override
  String get nameLabel => 'नाम';

  @override
  String get notSet => 'सेट नहीं';

  @override
  String get appleIdHidden => 'Apple ID (छुपा हुआ)';

  @override
  String get accountType => 'खाता प्रकार';

  @override
  String get patientRole => 'मरीज़';

  @override
  String get caregiverRole => 'केयरगिवर';

  @override
  String get phoneLabel => 'फ़ोन';

  @override
  String get edit => 'संपादित करें';

  @override
  String get add => 'जोड़ें';

  @override
  String get planLabel => 'योजना';

  @override
  String get planFree => 'मुफ़्त';

  @override
  String get planPremium => 'प्रीमियम';

  @override
  String get usageLabel => 'उपयोग';

  @override
  String freePlanUsage(int used, int limit) {
    return 'मुफ़्त योजना — $used / $limit सारांश उपयोग';
  }

  @override
  String get unlimited => 'असीमित';

  @override
  String get editPhoneNumber => 'फ़ोन नंबर संपादित करें';

  @override
  String get phoneNumber => 'फ़ोन नंबर';

  @override
  String get save => 'सहेजें';

  @override
  String get phoneMinLength => 'फ़ोन नंबर कम से कम 8 अक्षर का होना चाहिए';

  @override
  String get phoneUpdatedSuccess => 'फ़ोन नंबर सफलतापूर्वक अपडेट हुआ';

  @override
  String phoneUpdateFailed(String error) {
    return 'फ़ोन अपडेट विफल: $error';
  }

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get changePasswordSubtitle => 'सुरक्षा के लिए अपना पासवर्ड अपडेट करें';

  @override
  String get privacySettings => 'गोपनीयता सेटिंग्स';

  @override
  String get privacySettingsSubtitle =>
      'डेटा साझाकरण प्राथमिकताएँ प्रबंधित करें';

  @override
  String get managePrivacy => 'गोपनीयता प्रबंधित करें';

  @override
  String changePasswordProviderMessage(String provider) {
    return 'आपने $provider से साइन इन किया है। कृपया अपने $provider खाते में पासवर्ड बदलें।';
  }

  @override
  String get ok => 'ठीक है';

  @override
  String get selectDate => 'तारीख चुनें';

  @override
  String get changePasswordIntro =>
      'अपना खाता सुरक्षित रखने के लिए पासवर्ड अपडेट करें।';

  @override
  String get currentPassword => 'वर्तमान पासवर्ड';

  @override
  String get currentPasswordHint => 'अपना वर्तमान पासवर्ड दर्ज करें';

  @override
  String get enterCurrentPassword => 'कृपया अपना वर्तमान पासवर्ड दर्ज करें';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get newPasswordHint => 'अपना नया पासवर्ड दर्ज करें';

  @override
  String get enterNewPassword => 'कृपया नया पासवर्ड दर्ज करें';

  @override
  String get passwordMinLength => 'पासवर्ड कम से कम 8 अक्षर का होना चाहिए';

  @override
  String get confirmNewPassword => 'नया पासवर्ड पुष्टि करें';

  @override
  String get confirmNewPasswordHint => 'अपना नया पासवर्ड फिर से दर्ज करें';

  @override
  String get confirmNewPasswordRequired => 'कृपया अपना नया पासवर्ड पुष्टि करें';

  @override
  String get passwordsDoNotMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get updatePassword => 'पासवर्ड अपडेट करें';

  @override
  String get passwordUpdatedSuccess => 'पासवर्ड सफलतापूर्वक अपडेट हुआ';

  @override
  String get passwordUpdateFailed => 'पासवर्ड अपडेट विफल';

  @override
  String get wrongPassword => 'वर्तमान पासवर्ड गलत है';

  @override
  String get weakPassword => 'पासवर्ड बहुत कमज़ोर है';

  @override
  String get requiresRecentLogin => 'कृपया फिर से लॉग इन करें और प्रयास करें';

  @override
  String get checkInternetConnection => 'अपना इंटरनेट कनेक्शन जाँचें';

  @override
  String get dataSharing => 'डेटा साझाकरण';

  @override
  String get allowCaregiverSummaries =>
      'केयरगिवर को सारांश देखने की अनुमति दें';

  @override
  String get allowCaregiverMedications =>
      'केयरगिवर को दवाएँ देखने की अनुमति दें';

  @override
  String get allowCaregiverReminders =>
      'केयरगिवर को रिमाइंडर देखने की अनुमति दें';

  @override
  String get allowAiImprovement =>
      'उत्पाद सुधार के लिए AI को मेरा डेटा उपयोग करने दें';

  @override
  String get communicationAndConsent => 'संचार और सहमति';

  @override
  String get allowEmailNotifications => 'ईमेल सूचनाएँ अनुमति दें';

  @override
  String get allowSmsNotifications => 'SMS सूचनाएँ अनुमति दें';

  @override
  String get allowPushNotifications => 'पुश सूचनाएँ अनुमति दें';

  @override
  String get dataControl => 'डेटा नियंत्रण';

  @override
  String get exportMyData => 'मेरा डेटा निर्यात करें';

  @override
  String get deleteAllMedicalRecords => 'सभी चिकित्सा रिकॉर्ड हटाएँ';

  @override
  String get deleteMedicalRecordsTitle => 'चिकित्सा रिकॉर्ड हटाएँ';

  @override
  String get deleteMedicalRecordsMessage =>
      'यह आपके सभी चिकित्सा रिकॉर्ड स्थायी रूप से हटा देगा। यह पूर्ववत नहीं हो सकता।';

  @override
  String get deleteRecords => 'रिकॉर्ड हटाएँ';

  @override
  String get deleteMyAccount => 'मेरा खाता हटाएँ';

  @override
  String get legal => 'कानूनी';

  @override
  String get viewPrivacyPolicy => 'गोपनीयता नीति देखें';

  @override
  String get viewTermsOfService => 'सेवा की शर्तें देखें';

  @override
  String get termsOfService => 'सेवा की शर्तें';

  @override
  String get termsOfServiceBody =>
      'RemiMinder की सेवा की शर्तें\n\n1. शर्तों की स्वीकृति\nRemiMinder का उपयोग करके, आप इन शर्तों से सहमत होते हैं।\n\n2. सेवा का उपयोग\nRemiMinder स्वास्थ्य और दवा रिमाइंडर प्रबंधन में मदद के लिए बनाया गया है।\n\n3. गोपनीयता\nआपकी गोपनीयता महत्वपूर्ण है। सभी स्वास्थ्य डेटा सुरक्षित रूप से संभाला जाता है।\n\nपूर्ण शर्तों के लिए, कृपया हमारी वेबसाइट देखें।';

  @override
  String get privacyPolicy => 'गोपनीयता नीति';

  @override
  String get privacyPolicyBody =>
      'RemiMinder की गोपनीयता नीति\n\n1. हम कौन सी जानकारी एकत्र करते हैं\nहम आपकी दी गई जानकारी और उपयोग डेटा एकत्र करते हैं।\n\n2. जानकारी का उपयोग\nजानकारी स्वास्थ्य प्रबंधन सेवाएँ प्रदान करने के लिए उपयोग होती है।\n\n3. जानकारी साझाकरण\nहम आपकी व्यक्तिगत जानकारी नहीं बेचते।\n\nपूर्ण नीति के लिए, कृपया हमारी वेबसाइट देखें।';

  @override
  String get close => 'बंद करें';

  @override
  String featureComingSoon(String feature) {
    return '$feature जल्द आ रहा है';
  }

  @override
  String get caregiverSharingEnabled => 'केयरगिवर साझाकरण सक्षम';

  @override
  String get caregiverSharingDisabled => 'केयरगिवर साझाकरण अक्षम';

  @override
  String get dataExport => 'डेटा निर्यात';

  @override
  String get remindersTitle => 'रिमाइंडर';

  @override
  String get tabAll => 'सभी';

  @override
  String get tabToday => 'आज';

  @override
  String get tabPending => 'लंबित';

  @override
  String get tabCompleted => 'पूर्ण';

  @override
  String get searchRemindersHint => 'रिमाइंडर खोजें...';

  @override
  String get failedToLoadRemindersRetry => 'लोड नहीं हो सके। पुनः प्रयास';

  @override
  String get deleteReminderTitle => 'रिमाइंडर हटाएँ';

  @override
  String get deleteReminderMessage => 'क्या आप इस रिमाइंडर को हटाना चाहते हैं?';

  @override
  String get markDone => 'पूर्ण करें';

  @override
  String get snooze => 'स्नूज़';

  @override
  String snoozedUntil(String time) {
    return '$time तक स्नूज़';
  }

  @override
  String get statusDueNow => 'अभी देय';

  @override
  String get statusActive => 'सक्रिय';

  @override
  String get statusMissed => 'छूटा';

  @override
  String get statusSnoozed => 'स्नूज़';

  @override
  String get statusSkipped => 'छोड़ा';

  @override
  String get statusPending => 'लंबित';

  @override
  String get noRemindersFound => 'कोई रिमाइंडर नहीं';

  @override
  String get noRemindersMatchSearch => 'कोई मेल नहीं';

  @override
  String get createFirstReminder => 'शुरू करने के लिए पहला रिमाइंडर बनाएँ';

  @override
  String get tryAdjustSearch => 'खोज बदलकर देखें';

  @override
  String get createReminder => 'रिमाइंडर बनाएँ';

  @override
  String get newReminder => 'नया रिमाइंडर';

  @override
  String get editReminder => 'रिमाइंडर संपादित करें';

  @override
  String get reminderTitleLabel => 'शीर्षक';

  @override
  String get dosageOptional => 'खुराक (वैकल्पिक)';

  @override
  String get dosageHint => 'जैसे 10 mg दिन में एक बार';

  @override
  String get reminderTypeLabel => 'प्रकार';

  @override
  String get appointment => 'अपॉइंटमेंट';

  @override
  String get repeatLabel => 'दोहराएँ';

  @override
  String get once => 'एक बार';

  @override
  String get daily => 'दैनिक';

  @override
  String get weekly => 'साप्ताहिक';

  @override
  String get pleaseEnterTitle => 'कृपया शीर्षक दर्ज करें';

  @override
  String get reminderCreated => 'रिमाइंडर बन गया!';

  @override
  String failedToCreateReminder(String error) {
    return 'बनाने में विफल: $error';
  }

  @override
  String get saveChanges => 'बदलाव सहेजें';

  @override
  String get cannotRescheduleMissingType => 'पुनर्निर्धारण नहीं: प्रकार गायब';

  @override
  String get reminderUpdated => 'रिमाइंडर अपडेट!';

  @override
  String failedToUpdateReminder(String error) {
    return 'अपडेट विफल: $error';
  }

  @override
  String get reminderMarkedCompleted => 'रिमाइंडर पूर्ण!';

  @override
  String get reminderSnoozed30 => '30 मिनट के लिए स्नूज़';

  @override
  String timeInHours(int hours, String time) {
    return '$hours घंटे में ($time)';
  }

  @override
  String timeInMinutes(int minutes, String time) {
    return '$minutes मिनट में ($time)';
  }

  @override
  String get timeNow => 'अभी';

  @override
  String timeHoursAgo(int hours) {
    return '$hours घंटे पहले';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes मिनट पहले';
  }

  @override
  String timeInDays(int days) {
    return '$days दिन में';
  }

  @override
  String timeInHoursShort(int hours) {
    return '$hours घंटे में';
  }

  @override
  String timeInMinutesShort(int minutes) {
    return '$minutes मिनट में';
  }

  @override
  String get selectTime => 'समय चुनें';

  @override
  String get presetMorning => 'सुबह (8:00 AM)';

  @override
  String get presetNoon => 'दोपहर (12:00 PM)';

  @override
  String get presetEvening => 'शाम (6:00 PM)';

  @override
  String get presetNight => 'रात (8:00 PM)';

  @override
  String get hourLabel => 'घंटा';

  @override
  String get minuteLabel => 'मिन';

  @override
  String get amPmLabel => 'AM / PM';

  @override
  String get amLabel => 'AM';

  @override
  String get pmLabel => 'PM';

  @override
  String selectedTimeLabel(String time) {
    return 'चयनित समय: $time';
  }

  @override
  String setForTime(String time) {
    return '$time पर सेट ✓';
  }

  @override
  String get medicationAdherence => 'दवा अनुपालन';

  @override
  String get thisWeek => 'इस सप्ताह';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get overall => 'कुल मिलाकर';

  @override
  String dosesCount(int done, int total) {
    return '$done/$total खुराक';
  }

  @override
  String get byMedication => 'दवा के अनुसार';

  @override
  String get noPastRemindersAnalyze =>
      'विश्लेषण के लिए कोई पिछला रिमाइंडर नहीं';

  @override
  String get adherenceTips => 'अनुपालन सुझाव';

  @override
  String get adherenceTipsBody =>
      '• दवा समय के लिए फोन रिमाइंडर सेट करें\n• दवाएँ दृश्य स्थान पर रखें\n• पिल ऑर्गनाइज़र का उपयोग करें\n• प्रगति ट्रैक करें';

  @override
  String get actionFailed => 'कार्रवाई विफल';

  @override
  String get snoozeAlreadyUsed =>
      'यह रिमाइंडर पहले ही एक बार स्नूज़ हो चुका है';

  @override
  String get reminderDeleted => 'रिमाइंडर हटाया गया';

  @override
  String get deleteFailed => 'हटाना विफल';

  @override
  String get sectionRecentAlerts => 'हाल की अलर्ट';

  @override
  String get viewAll => 'सभी देखें';

  @override
  String get sectionInvitations => 'आमंत्रण';

  @override
  String get summaryPatients => 'मरीज़';

  @override
  String get summaryAlerts => 'अलर्ट';

  @override
  String get summaryPending => 'लंबित';

  @override
  String get noAlertsAtThisTime => 'इस समय कोई अलर्ट नहीं';

  @override
  String get noPendingInvitations => 'कोई लंबित आमंत्रण नहीं';

  @override
  String get pendingInvitationsTitle => 'लंबित आमंत्रण';

  @override
  String invitationsWaiting(int count) {
    return '$count आमंत्रण लंबित';
  }

  @override
  String get reviewAcceptInvitations =>
      'केयरगिवर आमंत्रणों की समीक्षा करें और स्वीकार करें।';

  @override
  String get viewInvitations => 'आमंत्रण देखें';

  @override
  String get defaultPatient => 'मरीज़';

  @override
  String get defaultCaregiver => 'केयरगिवर';

  @override
  String caregiverPatientTime(String name, String time) {
    return 'मरीज़: $name • $time';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days दिन पहले';
  }

  @override
  String get alertsTitle => 'अलर्ट';

  @override
  String get filterUnread => 'अपठित';

  @override
  String get filterRead => 'पढ़ा हुआ';

  @override
  String get filterHighPriority => 'उच्च प्राथमिकता';

  @override
  String get filterActionRequired => 'कार्रवाई आवश्यक';

  @override
  String get alertSingular => 'अलर्ट';

  @override
  String get alertsPlural => 'अलर्ट';

  @override
  String get clearFilter => 'फ़िल्टर हटाएँ';

  @override
  String get noAlertsMatchFilter => 'इस फ़िल्टर से कोई अलर्ट मेल नहीं खाता';

  @override
  String get allPatientActivitiesSmooth =>
      'सभी मरीज़ गतिविधियाँ सुचारू रूप से चल रही हैं';

  @override
  String get tryAdjustingFilter =>
      'अधिक अलर्ट देखने के लिए फ़िल्टर समायोजित करें';

  @override
  String get viewAllAlerts => 'सभी अलर्ट देखें';

  @override
  String get alertMarkedAsRead => 'अलर्ट पढ़ा हुआ चिह्नित';

  @override
  String alertsMarkedAsRead(int count) {
    return '$count अलर्ट पढ़े हुए चिह्नित';
  }

  @override
  String get allAlertsAlreadyRead => 'सभी अलर्ट पहले से पढ़े हुए हैं';

  @override
  String get myPatientsTitle => 'मेरे मरीज़';

  @override
  String get patientsConnectedSubtitle => 'आपसे जुड़े मरीज़';

  @override
  String get myPatientsSection => 'मेरे मरीज़';

  @override
  String connectedCount(int count) {
    return '$count जुड़े';
  }

  @override
  String get searchPatientsHint => 'मरीज़ खोजें...';

  @override
  String get noPatientsMatchSearch => 'आपकी खोज से कोई मरीज़ मेल नहीं खाता।';

  @override
  String get noPatientsConnectedYet => 'अभी कोई मरीज़ जुड़ा नहीं';

  @override
  String get acceptInvitationToSeePatient =>
      'मरीज़ देखने के लिए आमंत्रण स्वीकार करें।';

  @override
  String get badgeNew => 'नया';

  @override
  String joinedOn(String date) {
    return 'जुड़े $date';
  }

  @override
  String get neverSynced => 'अभी लोड नहीं हुआ';

  @override
  String get privacyDataRequestMessage =>
      'अपना डेटा निर्यात या हटाने के लिए privacy@remiminder.ai से संपर्क करें।';

  @override
  String syncMinutesAgo(int minutes) {
    return '$minutes मि० पहले';
  }

  @override
  String syncHoursAgo(int hours) {
    return '$hours घं० पहले';
  }

  @override
  String syncDaysAgo(int days) {
    return '$days दि० पहले';
  }

  @override
  String get primaryCondition => 'प्राथमिक स्थिति';

  @override
  String get lastSynced => 'अंतिम सिंक';

  @override
  String get allergiesLabel => 'एलर्जी';

  @override
  String get dateOfBirth => 'जन्म तिथि';

  @override
  String get currentMedications => 'वर्तमान दवाएँ';

  @override
  String get viewCarePlan => 'केयर प्लान देखें';

  @override
  String get remindersButton => 'रिमाइंडर';

  @override
  String get caregiverCareTeamSubtitle =>
      'परिवार या चिकित्सा कर्मचारी को आमंत्रित करें';

  @override
  String get invitationsReceived => 'प्राप्त आमंत्रण';

  @override
  String pendingBadge(int count) {
    return '$count लंबित';
  }

  @override
  String get patientOverviewTitle => 'रोगी अवलोकन';

  @override
  String get patientOverviewTabVisits => 'विज़िट';

  @override
  String get patientOverviewTabReminders => 'अनुस्मारक';

  @override
  String get patientOverviewNoVisits => 'कोई विज़िट उपलब्ध नहीं';

  @override
  String get patientOverviewNoReminders => 'कोई अनुस्मारक उपलब्ध नहीं';

  @override
  String get patientOverviewMissingPatientId => 'रोगी की जानकारी अनुपलब्ध';

  @override
  String get patientOverviewLastVisit => 'अंतिम विज़िट';

  @override
  String get patientOverviewCareTeam => 'केयर टीम सदस्य';

  @override
  String get patientOverviewScheduledReminder => 'निर्धारित अनुस्मारक';

  @override
  String get patientOverviewNever => 'कभी नहीं';

  @override
  String get patientOverviewYesterday => 'कल';

  @override
  String get statusViewed => 'देखा गया';

  @override
  String get statusExpired => 'समाप्त';

  @override
  String get statusJoined => 'शामिल';

  @override
  String get noInvitationsToShow => 'दिखाने के लिए कोई आमंत्रण नहीं';

  @override
  String invitedByLabel(String name) {
    return 'आमंत्रित: $name';
  }

  @override
  String get acceptInvitation => 'स्वीकारें';

  @override
  String get declineInvitation => 'अस्वीकार';

  @override
  String get invitationDeclined => 'आमंत्रण अस्वीकार किया';

  @override
  String joinedCareTeamSnackbar(String patientName, String role) {
    return '$patientName की केयर टीम में $role के रूप में शामिल';
  }

  @override
  String get manageAccess => 'एक्सेस प्रबंधित करें';

  @override
  String get manageAccessDescription =>
      'केयरगिवर की अनुमति अपडेट करें या एक्सेस हटाएं.';

  @override
  String get manage => 'प्रबंधित करें';

  @override
  String get accessUpdatedSuccess => 'एक्सेस सफलतापूर्वक अपडेट हुआ';

  @override
  String get accessUpdateFailed =>
      'एक्सेस अपडेट करने में विफल. कृपया पुनः प्रयास करें.';

  @override
  String get removeCaregiverTitle => 'केयरगिवर हटाएं?';

  @override
  String get removeCaregiverMessage =>
      'क्या आप वाकई इस केयरगिवर को हटाना चाहते हैं? उनकी एक्सेस तुरंत समाप्त हो जाएगी.';

  @override
  String get remove => 'हटाएं';

  @override
  String get updatingAccess => 'एक्सेस अपडेट हो रहा है...';

  @override
  String get removingCaregiver => 'केयरगिवर हटाया जा रहा है...';

  @override
  String get removeCaregiverFailed =>
      'केयरगिवर हटाने में विफल. कृपया पुनः प्रयास करें.';

  @override
  String get viewAccess => 'देखने की अनुमति';

  @override
  String get fullAccess => 'पूर्ण एक्सेस';

  @override
  String get viewOnly => 'केवल देखें';

  @override
  String get resendingInvitation => 'आमंत्रण पुनः भेजा जा रहा है...';

  @override
  String get invitationResent => 'आमंत्रण पुनः भेजा गया';

  @override
  String get failedToResendInvitation => 'आमंत्रण पुनः भेजने में विफल';

  @override
  String get cancelingInvitation => 'आमंत्रण रद्द किया जा रहा है...';

  @override
  String get invitationCanceled => 'आमंत्रण रद्द';

  @override
  String get failedToCancelInvitation => 'आमंत्रण रद्द करने में विफल';

  @override
  String get relationshipSon => 'पुत्र';

  @override
  String get relationshipDaughter => 'पुत्री';

  @override
  String get relationshipFriend => 'मित्र';

  @override
  String get relationshipSpousePartner => 'जीवनसाथी/साथी';

  @override
  String get relationshipParent => 'अभिभावक';

  @override
  String get relationshipChild => 'बच्चा';

  @override
  String get relationshipFamilyMember => 'परिवार का सदस्य';

  @override
  String get relationshipHealthcareProfessional => 'स्वास्थ्य पेशेवर';

  @override
  String get relationshipCaregiver => 'केयरगिवर';

  @override
  String get relationshipSister => 'बहन';

  @override
  String get relationshipBrother => 'भाई';

  @override
  String get relationshipOther => 'अन्य';

  @override
  String get visitActionTitle => 'आप क्या करना चाहेंगे?';

  @override
  String get visitActionAudioTitle => 'ऑडियो बातचीत रिकॉर्ड करें';

  @override
  String get visitActionAudioSubtitle =>
      'स्वचालित सारांश के लिए अपनी डॉक्टर विज़िट रिकॉर्ड करें';

  @override
  String get visitActionCaptureTitle => 'कैप्चर और स्कैन';

  @override
  String get visitActionCaptureSubtitle =>
      'रिपोर्ट, दवा की बोतलों और दस्तावेज़ों की तस्वीरें लें';

  @override
  String get inviteCaregiverDialogTitle => 'केयरगिवर को आमंत्रित करें';

  @override
  String get caregiverNameHint => 'केयरगिवर का पूरा नाम दर्ज करें';

  @override
  String get caregiverEmailHint => 'केयरगिवर का ईमेल पता दर्ज करें';

  @override
  String get relationshipLabel => 'संबंध';

  @override
  String get relationshipHint => 'जैसे, बेटा, बेटी, मित्र, नर्स';

  @override
  String get sendInvite => 'आमंत्रण भेजें';

  @override
  String get emailAndRoleRequired => 'ईमेल और भूमिका आवश्यक हैं';

  @override
  String get summaryReadyTitle => 'आपका विज़िट सारांश तैयार है!';

  @override
  String get summaryReadyBody => 'क्या आप इसे अभी देखना चाहेंगे?';

  @override
  String get later => 'बाद में';

  @override
  String get viewSummary => 'सारांश देखें';

  @override
  String get noLabResultsYet => 'अभी तक कोई लैब परिणाम नहीं';

  @override
  String get labResultsScanHint =>
      'यहाँ परिणाम देखने के लिए कैप्चर और स्कैन से लैब रिपोर्ट स्कैन करें।';

  @override
  String get captureAndScan => 'कैप्चर और स्कैन';

  @override
  String get noScannedDocsYet => 'अभी तक कोई स्कैन किए गए दस्तावेज़ नहीं';

  @override
  String get scannedDocsHint =>
      'आपकी विज़िट के दौरान स्कैन किए गए दस्तावेज़ यहाँ दिखाई देंगे।';

  @override
  String get selectAtLeastOneSummary => 'कम से कम एक सारांश चुनें';

  @override
  String get failedToDeleteSummaries =>
      'सारांश हटाने में विफल। कृपया पुनः प्रयास करें।';

  @override
  String get noCaregiverAddedYet => 'अभी तक कोई केयरगिवर नहीं जोड़ा गया';

  @override
  String get summaryGenerationRestarted => 'सारांश जनरेशन पुनः शुरू हुआ';

  @override
  String retryFailed(String error) {
    return 'पुनः प्रयास विफल: $error';
  }

  @override
  String get generateSummary => 'सारांश बनाएं';

  @override
  String get discardRecording => 'रिकॉर्डिंग हटाएं';

  @override
  String unableToStartRecording(String error) {
    return 'रिकॉर्डिंग शुरू नहीं हो सकी: $error';
  }

  @override
  String get recordingCompleted => 'रिकॉर्डिंग पूर्ण!';

  @override
  String unableToStopRecording(String error) {
    return 'रिकॉर्डिंग रोक नहीं सकी: $error';
  }

  @override
  String get recordingDiscarded => 'रिकॉर्डिंग हटा दी गई';

  @override
  String get unableToOpenPrivacyPolicy => 'गोपनीयता नीति नहीं खोल सकी।';

  @override
  String get noRecordingAvailable => 'कोई रिकॉर्डिंग उपलब्ध नहीं';

  @override
  String get uploadingAudio => 'ऑडियो अपलोड हो रहा है...';

  @override
  String failedToUploadAudio(String error) {
    return 'ऑडियो अपलोड विफल: $error';
  }

  @override
  String get stopRecordingTitle => 'रिकॉर्डिंग रोकें?';

  @override
  String get stopRecordingMessage =>
      'Are you sure you want to stop recording? This action cannot be undone.';

  @override
  String get continueRecording => 'रिकॉर्डिंग जारी रखें';

  @override
  String get stopAndDiscard => 'रोकें और हटाएं';

  @override
  String get share => 'साझा करें';

  @override
  String get cameraNotReady => 'कैमरा तैयार नहीं। कृपया पुनः प्रयास करें।';

  @override
  String failedToCaptureImage(String error) {
    return 'छवि कैप्चर विफल: $error';
  }

  @override
  String get unableToStartCamera =>
      'कैमरा शुरू नहीं हो सका। कृपया पुनः प्रयास करें।';

  @override
  String get cameraReadyHint =>
      'कैमरा तैयार। दस्तावेज़ रखें और कैप्चर टैप करें।';

  @override
  String unableToStartScanning(String error) {
    return 'स्कैन शुरू नहीं हो सका: $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'छवि अपलोड विफल: $error';
  }

  @override
  String get noImageToProcess =>
      'प्रोसेस करने के लिए कोई छवि नहीं। फिर से कैप्चर करें।';

  @override
  String get documentScannedSaved => 'दस्तावेज़ स्कैन और सहेजा गया!';

  @override
  String scanProcessingFailed(String error) {
    return 'स्कैन प्रोसेसिंग विफल: $error';
  }

  @override
  String get scanSavedToHistory => 'स्कैन आपके विज़िट इतिहास में सहेजा गया';

  @override
  String localNotificationSchedulingFailed(String error) {
    return 'स्थानीय सूचना शेड्यूल विफल: $error';
  }

  @override
  String reminderRescheduleFailed(String error) {
    return 'रिमाइंडर पुनर्निर्धारण विफल: $error';
  }

  @override
  String get authenticationErrorLoginAgain =>
      'प्रमाणीकरण त्रुटि। कृपया फिर से लॉग इन करें।';
}
