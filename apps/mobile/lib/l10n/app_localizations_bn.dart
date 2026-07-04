// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Bengali Bangla (`bn`).
class AppLocalizationsBn extends AppLocalizations {
  AppLocalizationsBn([String locale = 'bn']) : super(locale);

  @override
  String get appTitle => 'RemiMinder';

  @override
  String get login => 'লগইন';

  @override
  String get logout => 'লগআউট';

  @override
  String get settings => 'সেটিংস';

  @override
  String get language => 'ভাষা';

  @override
  String get profileSettings => 'প্রোফাইল সেটিংস';

  @override
  String get languageSettings => 'ভাষা';

  @override
  String languageUpdated(String language) {
    return 'ভাষা আপডেট হয়েছে। এখন অ্যাপ $language ভাষায় দেখাবে।';
  }

  @override
  String get navHome => 'হোম';

  @override
  String get navVisits => 'ভিজিট';

  @override
  String get navOverview => 'সারাংশ';

  @override
  String get navCareTeam => 'টিম';

  @override
  String get navProfile => 'প্রোফাইল';

  @override
  String get navPatients => 'রোগী';

  @override
  String get goodMorning => 'সুপ্রভাত';

  @override
  String get goodAfternoon => 'শুভ অপরাহ্ন';

  @override
  String get goodEvening => 'শুভ সন্ধ্যা';

  @override
  String get goodNight => 'শুভ রাত্রি';

  @override
  String get howAreYouFeeling => 'আজ আপনি কেমন অনুভব করছেন?';

  @override
  String get todaysProgress => 'আজকের অগ্রগতি';

  @override
  String doneCount(int done, int total) {
    return '$done/$total সম্পন্ন';
  }

  @override
  String get yourSchedule => 'আপনার সময়সূচি';

  @override
  String get seeAll => 'সব দেখুন →';

  @override
  String get nothingScheduledYet => 'এখনও কিছু নির্ধারিত নেই';

  @override
  String get unableToLoadReminders => 'রিমাইন্ডার লোড করা যায়নি';

  @override
  String get addReminder => 'রিমাইন্ডার যোগ করুন';

  @override
  String get myTasks => 'আমার কাজ';

  @override
  String pendingCount(int count) {
    return '$count বাকি';
  }

  @override
  String get noTasksYet => 'এখনও কোনো কাজ নেই';

  @override
  String get addTask => 'কাজ যোগ করুন';

  @override
  String get statusUpcoming => 'আসন্ন';

  @override
  String get statusScheduled => 'নির্ধারিত';

  @override
  String get statusDone => 'সম্পন্ন';

  @override
  String get reminder => 'রিমাইন্ডার';

  @override
  String get task => 'কাজ';

  @override
  String get careTeamTitle => 'যত্ন দল';

  @override
  String get careTeamSubtitle =>
      'নিয়ন্ত্রণ আপনার হাতে। নিচে শেয়ারিং অনুমতি দেখুন।';

  @override
  String get sectionPending => 'অপেক্ষমাণ';

  @override
  String get sectionAddNew => 'নতুন যোগ';

  @override
  String get inviteCaregiver => 'যত্নকারীকে আমন্ত্রণ';

  @override
  String get inviteCaregiverSubtitle =>
      'আপনার স্বাস্থ্য তথ্যে অ্যাক্সেস শেয়ার করুন';

  @override
  String get invitationPending => 'আমন্ত্রণ অপেক্ষমাণ';

  @override
  String get resend => 'পুনরায় পাঠান';

  @override
  String get cancel => 'বাতিল';

  @override
  String get activeCaregivers => 'সক্রিয় যত্নকারী';

  @override
  String get noCaregiversYet => 'এখনও কোনো যত্নকারী যোগ হয়নি';

  @override
  String get english => 'ইংরেজি';

  @override
  String get spanish => 'স্প্যানিশ';

  @override
  String get hindi => 'হিন্দি';

  @override
  String get french => 'ফরাসি';

  @override
  String get portuguese => 'পর্তুগিজ';

  @override
  String get german => 'জার্মান';

  @override
  String get bangla => 'বাংলা';

  @override
  String get tamil => 'তামিল';

  @override
  String get gujarati => 'ગુજરાતી';

  @override
  String get punjabi => 'ਪੰਜਾਬੀ';

  @override
  String get accountDetails => 'অ্যাকাউন্ট বিবরণ';

  @override
  String get accountDetailsSubtitle => 'আপনার প্রোফাইল তথ্য দেখুন';

  @override
  String get accountSecurity => 'অ্যাকাউন্ট নিরাপত্তা';

  @override
  String get accountSecuritySubtitle => 'পাসওয়ার্ড ও গোপনীয়তা পরিচালনা';

  @override
  String get notificationsLabel => 'বিজ্ঞপ্তি';

  @override
  String get mobileLabel => 'মোবাইল';

  @override
  String get emailLabel => 'ইমেইল';

  @override
  String get upgrade => 'আপগ্রেড';

  @override
  String get signOut => 'সাইন আউট';

  @override
  String get deleteAccount => 'অ্যাকাউন্ট মুছুন';

  @override
  String get deleteAccountTitle => 'অ্যাকাউন্ট মুছুন';

  @override
  String get deleteAccountMessage =>
      'এটি আপনার অ্যাকাউন্ট ও সব ডেটা স্থায়ীভাবে মুছে দেবে। এটি পূর্বাবস্থায় ফেরানো যাবে না। আপনি কি নিশ্চিত?';

  @override
  String get delete => 'মুছুন';

  @override
  String get searchSummariesHint => 'সারাংশ খুঁজুন...';

  @override
  String get tabSummaries => 'সারাংশ';

  @override
  String get tabLabResults => 'ল্যাব';

  @override
  String get tabScannedDocs => 'স্ক্যান';

  @override
  String get noSummariesYet => 'এখনও কোনো সারাংশ নেই';

  @override
  String get summariesWillAppearHere => 'আপনার ভিজিট সারাংশ এখানে দেখা যাবে';

  @override
  String get failedToLoadSummaries => 'সারাংশ লোড ব্যর্থ';

  @override
  String get retry => 'পুনরায় চেষ্টা';

  @override
  String get shareLabel => 'শেয়ার';

  @override
  String get doctorVisit => 'ডাক্তার ভিজিট';

  @override
  String timeToday(String time) {
    return 'আজ, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'গতকাল, $time';
  }

  @override
  String get summaryProcessingHint =>
      'রিফ্রেশ করতে নিচে টানুন। সাধারণত ৩০–৬০ সেকেন্ড লাগে।';

  @override
  String get summaryCouldNotGenerate => 'সারাংশ তৈরি করা যায়নি';

  @override
  String get retrySummary => 'সারাংশ পুনরায় চেষ্টা';

  @override
  String get stuckRetrySummary => 'আটকে গেছেন? পুনরায় চেষ্টা';

  @override
  String get scannedDocument => 'স্ক্যান করা নথি';

  @override
  String scannedOn(String date) {
    return 'স্ক্যান $date';
  }

  @override
  String get visitDetails => 'ভিজিট বিবরণ';

  @override
  String get healthVisitSummary => 'স্বাস্থ্য ভিজিট সারাংশ';

  @override
  String get refreshSummaryTooltip => 'সারাংশ রিফ্রেশ';

  @override
  String get preparingVisitSummary => 'ভিজিট সারাংশ প্রস্তুত হচ্ছে...';

  @override
  String get preparingVisitSubtitle => 'এক মিনিট লাগতে পারে।';

  @override
  String get unableToLoadVisitSummary => 'ভিজিট সারাংশ লোড করা যায়নি';

  @override
  String get visitSummaryUnavailable => 'ভিজিট সারাংশ উপলব্ধ নয়';

  @override
  String get visitSummary => 'ভিজিট সারাংশ';

  @override
  String get visitProcessingTitle => 'আপনার ভিজিট প্রক্রিয়াকরণ হচ্ছে';

  @override
  String get visitProcessingBody =>
      '৩০–৬০ সেকেন্ড লাগতে পারে।\nআপনি অ্যাপ ব্যবহার চালিয়ে যেতে পারেন। অগ্রগতি দেখতে সারাংশ খুলুন।';

  @override
  String get viewOverviewAction => 'সারাংশ দেখুন';

  @override
  String get goToHome => 'হোমে যান';

  @override
  String get medication => 'ওষুধ';

  @override
  String get nextToDo => 'পরবর্তী কাজ';

  @override
  String get conditionsDiscussed => 'আলোচিত অবস্থা';

  @override
  String get followUp => 'ফলো-আপ';

  @override
  String get nameLabel => 'নাম';

  @override
  String get notSet => 'সেট নয়';

  @override
  String get appleIdHidden => 'Apple ID (লুকানো)';

  @override
  String get accountType => 'অ্যাকাউন্ট ধরন';

  @override
  String get patientRole => 'রোগী';

  @override
  String get caregiverRole => 'যত্নকারী';

  @override
  String get phoneLabel => 'ফোন';

  @override
  String get edit => 'সম্পাদনা';

  @override
  String get add => 'যোগ';

  @override
  String get planLabel => 'প্ল্যান';

  @override
  String get planFree => 'ফ্রি';

  @override
  String get planPremium => 'প্রিমিয়াম';

  @override
  String get chooseYourRole => 'আপনার ভূমিকা বেছে নিন';

  @override
  String get chooseYourRoleSubtitle =>
      'আপনি কীভাবে RemiMinder ব্যবহার করবেন তা নির্বাচন করুন';

  @override
  String get patientRoleCardDescription =>
      'আপনার ওষুধ, অ্যাপয়েন্টমেন্ট এবং স্বাস্থ্য রেকর্ড পরিচালনা করুন';

  @override
  String get caregiverRoleCardDescription =>
      'পরিবারের সদস্য বা রোগীদের ওষুধ ও যত্ন পরিচালনায় সহায়তা করুন';

  @override
  String get continueButton => 'চালিয়ে যান';

  @override
  String get usageLabel => 'ব্যবহার';

  @override
  String freePlanUsage(int used, int limit) {
    return '$used / $limit সারাংশ ব্যবহৃত';
  }

  @override
  String get unlimited => 'অসীম';

  @override
  String get editPhoneNumber => 'ফোন নম্বর সম্পাদনা';

  @override
  String get phoneNumber => 'ফোন নম্বর';

  @override
  String get save => 'সংরক্ষণ';

  @override
  String get phoneMinLength => 'ফোন নম্বর কমপক্ষে ৮ অক্ষরের হতে হবে';

  @override
  String get phoneUpdatedSuccess => 'ফোন নম্বর সফলভাবে আপডেট হয়েছে';

  @override
  String phoneUpdateFailed(String error) {
    return 'ফোন আপডেট ব্যর্থ: $error';
  }

  @override
  String get changePassword => 'পাসওয়ার্ড পরিবর্তন';

  @override
  String get changePasswordSubtitle => 'নিরাপত্তার জন্য পাসওয়ার্ড আপডেট করুন';

  @override
  String get privacySettings => 'গোপনীয়তা সেটিংস';

  @override
  String get privacySettingsSubtitle => 'ডেটা শেয়ারিং পছন্দ পরিচালনা';

  @override
  String get managePrivacy => 'গোপনীয়তা পরিচালনা';

  @override
  String changePasswordProviderMessage(String provider) {
    return 'আপনি $provider দিয়ে সাইন ইন করেছেন। $provider অ্যাকাউন্টে পাসওয়ার্ড পরিবর্তন করুন।';
  }

  @override
  String get ok => 'ঠিক আছে';

  @override
  String get selectDate => 'তারিখ নির্বাচন';

  @override
  String get changePasswordIntro =>
      'অ্যাকাউন্ট সুরক্ষিত রাখতে পাসওয়ার্ড আপডেট করুন।';

  @override
  String get currentPassword => 'বর্তমান পাসওয়ার্ড';

  @override
  String get currentPasswordHint => 'বর্তমান পাসওয়ার্ড লিখুন';

  @override
  String get enterCurrentPassword => 'বর্তমান পাসওয়ার্ড লিখুন';

  @override
  String get newPassword => 'নতুন পাসওয়ার্ড';

  @override
  String get newPasswordHint => 'নতুন পাসওয়ার্ড লিখুন';

  @override
  String get enterNewPassword => 'নতুন পাসওয়ার্ড লিখুন';

  @override
  String get passwordMinLength => 'পাসওয়ার্ড কমপক্ষে ৮ অক্ষরের হতে হবে';

  @override
  String get confirmNewPassword => 'নতুন পাসওয়ার্ড নিশ্চিত';

  @override
  String get confirmNewPasswordHint => 'নতুন পাসওয়ার্ড আবার লিখুন';

  @override
  String get confirmNewPasswordRequired => 'নতুন পাসওয়ার্ড নিশ্চিত করুন';

  @override
  String get passwordsDoNotMatch => 'পাসওয়ার্ড মিলছে না';

  @override
  String get updatePassword => 'পাসওয়ার্ড আপডেট';

  @override
  String get passwordUpdatedSuccess => 'পাসওয়ার্ড সফলভাবে আপডেট হয়েছে';

  @override
  String get passwordUpdateFailed => 'পাসওয়ার্ড আপডেট ব্যর্থ';

  @override
  String get wrongPassword => 'বর্তমান পাসওয়ার্ড ভুল';

  @override
  String get weakPassword => 'পাসওয়ার্ড খুব দুর্বল';

  @override
  String get requiresRecentLogin => 'আবার লগইন করে চেষ্টা করুন';

  @override
  String get checkInternetConnection => 'ইন্টারনেট সংযোগ পরীক্ষা করুন';

  @override
  String get dataSharing => 'ডেটা শেয়ারিং';

  @override
  String get allowCaregiverSummaries => 'যত্নকারী সারাংশ দেখতে পারবে';

  @override
  String get allowCaregiverMedications => 'যত্নকারী ওষুধ দেখতে পারবে';

  @override
  String get allowCaregiverReminders => 'যত্নকারী রিমাইন্ডার দেখতে পারবে';

  @override
  String get allowAiImprovement =>
      'AI আমার ডেটা পণ্য উন্নতিতে ব্যবহার করতে পারে';

  @override
  String get communicationAndConsent => 'যোগাযোগ ও সম্মতি';

  @override
  String get allowEmailNotifications => 'ইমেইল বিজ্ঞপ্তি অনুমতি';

  @override
  String get allowSmsNotifications => 'SMS বিজ্ঞপ্তি অনুমতি';

  @override
  String get allowPushNotifications => 'পুশ বিজ্ঞপ্তি অনুমতি';

  @override
  String get dataControl => 'ডেটা নিয়ন্ত্রণ';

  @override
  String get exportMyData => 'আমার ডেটা রপ্তানি';

  @override
  String get deleteAllMedicalRecords => 'সব চিকিৎসা রেকর্ড মুছুন';

  @override
  String get deleteMedicalRecordsTitle => 'চিকিৎসা রেকর্ড মুছুন';

  @override
  String get deleteMedicalRecordsMessage =>
      'এটি সব চিকিৎসা রেকর্ড স্থায়ীভাবে মুছে দেবে। এটি পূর্বাবস্থায় ফেরানো যাবে না।';

  @override
  String get deleteRecords => 'রেকর্ড মুছুন';

  @override
  String get deleteMyAccount => 'আমার অ্যাকাউন্ট মুছুন';

  @override
  String get legal => 'আইনি';

  @override
  String get viewPrivacyPolicy => 'গোপনীয়তা নীতি দেখুন';

  @override
  String get viewTermsOfService => 'সেবার শর্তাবলী দেখুন';

  @override
  String get termsOfService => 'সেবার শর্তাবলী';

  @override
  String get termsOfServiceBody =>
      'RemiMinder সেবার শর্তাবলী\n\n১. শর্ত গ্রহণ\nRemiMinder ব্যবহার করে আপনি এই শর্তাবলী মেনে নিচ্ছেন।\n\n২. সেবার ব্যবহার\nRemiMinder স্বাস্থ্যসেবা ও ওষুধের রিমাইন্ডার পরিচালনায় সাহায্য করে।\n\n৩. গোপনীয়তা\nআপনার গোপনীয়তা গুরুত্বপূর্ণ। সব স্বাস্থ্য ডেটা নিরাপদে পরিচালিত হয়।\n\nসম্পূর্ণ শর্তাবলীর জন্য আমাদের ওয়েবসাইট দেখুন।';

  @override
  String get privacyPolicy => 'গোপনীয়তা নীতি';

  @override
  String get privacyPolicyBody =>
      'RemiMinder গোপনীয়তা নীতি\n\n১. আমরা যে তথ্য সংগ্রহ করি\nআপনি যে তথ্য দেন ও ব্যবহারের ডেটা আমরা সংগ্রহ করি।\n\n২. তথ্যের ব্যবহার\nস্বাস্থ্যসেবা পরিচালনার জন্য তথ্য ব্যবহৃত হয়।\n\n৩. তথ্য শেয়ারিং\nআমরা আপনার ব্যক্তিগত তথ্য বিক্রি করি না।\n\nসম্পূর্ণ নীতির জন্য আমাদের ওয়েবসাইট দেখুন।';

  @override
  String get close => 'বন্ধ';

  @override
  String featureComingSoon(String feature) {
    return '$feature শীঘ্রই আসছে';
  }

  @override
  String get caregiverSharingEnabled => 'যত্নকারী শেয়ারিং চালু';

  @override
  String get caregiverSharingDisabled => 'যত্নকারী শেয়ারিং বন্ধ';

  @override
  String get dataExport => 'ডেটা রপ্তানি';

  @override
  String get remindersTitle => 'রিমাইন্ডার';

  @override
  String get tabAll => 'সব';

  @override
  String get tabToday => 'আজ';

  @override
  String get tabPending => 'অপেক্ষমাণ';

  @override
  String get tabCompleted => 'সম্পন্ন';

  @override
  String get searchRemindersHint => 'রিমাইন্ডার খুঁজুন...';

  @override
  String get failedToLoadRemindersRetry => 'লোড ব্যর্থ। আবার চেষ্টা';

  @override
  String get deleteReminderTitle => 'রিমাইন্ডার মুছুন';

  @override
  String get deleteReminderMessage => 'আপনি কি এই রিমাইন্ডার মুছতে চান?';

  @override
  String get markDone => 'সম্পন্ন';

  @override
  String get snooze => 'স্নুজ';

  @override
  String snoozedUntil(String time) {
    return '$time পর্যন্ত স্নুজ';
  }

  @override
  String get statusDueNow => 'এখনই';

  @override
  String get statusActive => 'সক্রিয়';

  @override
  String get statusMissed => 'মিস';

  @override
  String get statusSnoozed => 'স্নুজ';

  @override
  String get statusSkipped => 'এড়ানো';

  @override
  String get statusPending => 'অপেক্ষমাণ';

  @override
  String get noRemindersFound => 'কোনো রিমাইন্ডার নেই';

  @override
  String get noRemindersMatchSearch => 'কোনো মিল নেই';

  @override
  String get createFirstReminder => 'শুরু করতে প্রথম রিমাইন্ডার তৈরি করুন';

  @override
  String get tryAdjustSearch => 'অন্য শব্দে খুঁজুন';

  @override
  String get createReminder => 'রিমাইন্ডার তৈরি';

  @override
  String get newReminder => 'নতুন রিমাইন্ডার';

  @override
  String get editReminder => 'রিমাইন্ডার সম্পাদনা';

  @override
  String get reminderTitleLabel => 'শিরোনাম';

  @override
  String get dosageOptional => 'ডোজ (ঐচ্ছিক)';

  @override
  String get dosageHint => 'যেমন ১০ mg দিনে একবার';

  @override
  String get reminderTypeLabel => 'ধরন';

  @override
  String get appointment => 'অ্যাপয়েন্টমেন্ট';

  @override
  String get repeatLabel => 'পুনরাবৃত্তি';

  @override
  String get once => 'একবার';

  @override
  String get daily => 'দৈনিক';

  @override
  String get weekly => 'সাপ্তাহিক';

  @override
  String get pleaseEnterTitle => 'শিরোনাম লিখুন';

  @override
  String get reminderCreated => 'রিমাইন্ডার তৈরি হয়েছে!';

  @override
  String failedToCreateReminder(String error) {
    return 'তৈরি ব্যর্থ: $error';
  }

  @override
  String get saveChanges => 'পরিবর্তন সংরক্ষণ';

  @override
  String get cannotRescheduleMissingType => 'পুনঃনির্ধারণ সম্ভব নয়: ধরন নেই';

  @override
  String get reminderUpdated => 'রিমাইন্ডার আপডেট!';

  @override
  String failedToUpdateReminder(String error) {
    return 'আপডেট ব্যর্থ: $error';
  }

  @override
  String get reminderMarkedCompleted => 'রিমাইন্ডার সম্পন্ন!';

  @override
  String get reminderSnoozed30 => '৩০ মিনিট স্নুজ';

  @override
  String timeInHours(int hours, String time) {
    return '$hours ঘণ্টায় ($time)';
  }

  @override
  String timeInMinutes(int minutes, String time) {
    return '$minutes মিনিটে ($time)';
  }

  @override
  String get timeNow => 'এখন';

  @override
  String timeHoursAgo(int hours) {
    return '$hours ঘণ্টা আগে';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes মিনিট আগে';
  }

  @override
  String timeInDays(int days) {
    return '$days দিনে';
  }

  @override
  String timeInHoursShort(int hours) {
    return '$hours ঘণ্টায়';
  }

  @override
  String timeInMinutesShort(int minutes) {
    return '$minutes মিনিটে';
  }

  @override
  String get selectTime => 'সময় নির্বাচন';

  @override
  String get presetMorning => 'সকাল (৮:০০)';

  @override
  String get presetNoon => 'দুপুর (১২:০০)';

  @override
  String get presetEvening => 'সন্ধ্যা (৬:০০)';

  @override
  String get presetNight => 'রাত (৮:০০)';

  @override
  String get hourLabel => 'ঘণ্টা';

  @override
  String get minuteLabel => 'মিন';

  @override
  String get amPmLabel => 'AM / PM';

  @override
  String get amLabel => 'AM';

  @override
  String get pmLabel => 'PM';

  @override
  String selectedTimeLabel(String time) {
    return 'নির্বাচিত সময়: $time';
  }

  @override
  String setForTime(String time) {
    return '$time সেট ✓';
  }

  @override
  String get medicationAdherence => 'ওষুধ অনুগতি';

  @override
  String get thisWeek => 'এই সপ্তাহ';

  @override
  String get thisMonth => 'এই মাস';

  @override
  String get overall => 'সামগ্রিক';

  @override
  String dosesCount(int done, int total) {
    return '$done/$total ডোজ';
  }

  @override
  String get byMedication => 'ওষুধ অনুযায়ী';

  @override
  String get noPastRemindersAnalyze =>
      'বিশ্লেষণের জন্য কোনো পূর্বের রিমাইন্ডার নেই';

  @override
  String get adherenceTips => 'অনুগতি পরামর্শ';

  @override
  String get adherenceTipsBody =>
      '• ওষুধের সময় ফোন রিমাইন্ডার সেট করুন\n• ওষুধ দৃশ্যমান স্থানে রাখুন\n• পিল অর্গানাইজার ব্যবহার করুন\n• অগ্রগতি ট্র্যাক করুন';

  @override
  String get actionFailed => 'কাজ ব্যর্থ';

  @override
  String get snoozeAlreadyUsed =>
      'এই রিমাইন্ডার ইতিমধ্যে একবার স্নুজ করা হয়েছে';

  @override
  String get reminderDeleted => 'রিমাইন্ডার মুছে ফেলা হয়েছে';

  @override
  String get deleteFailed => 'মুছতে ব্যর্থ';

  @override
  String get sectionRecentAlerts => 'সাম্প্রতিক সতর্কতা';

  @override
  String get viewAll => 'সব দেখুন';

  @override
  String get sectionInvitations => 'আমন্ত্রণ';

  @override
  String get summaryPatients => 'রোগী';

  @override
  String get summaryAlerts => 'সতর্কতা';

  @override
  String get summaryPending => 'অপেক্ষমাণ';

  @override
  String get noAlertsAtThisTime => 'এই মুহূর্তে কোনো সতর্কতা নেই';

  @override
  String get noPendingInvitations => 'কোনো অপেক্ষমাণ আমন্ত্রণ নেই';

  @override
  String get pendingInvitationsTitle => 'অপেক্ষমাণ আমন্ত্রণ';

  @override
  String invitationsWaiting(int count) {
    return '$countটি আমন্ত্রণ অপেক্ষমাণ';
  }

  @override
  String get reviewAcceptInvitations =>
      'কেয়ারগিভার আমন্ত্রণ পর্যালোচনা করুন এবং গ্রহণ করুন।';

  @override
  String get viewInvitations => 'আমন্ত্রণ দেখুন';

  @override
  String get defaultPatient => 'রোগী';

  @override
  String get defaultCaregiver => 'কেয়ারগিভার';

  @override
  String caregiverPatientTime(String name, String time) {
    return 'রোগী: $name • $time';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days দিন আগে';
  }

  @override
  String get alertsTitle => 'সতর্কতা';

  @override
  String get filterUnread => 'অপঠিত';

  @override
  String get filterRead => 'পঠিত';

  @override
  String get filterHighPriority => 'উচ্চ অগ্রাধিকার';

  @override
  String get filterActionRequired => 'পদক্ষেপ প্রয়োজন';

  @override
  String get alertSingular => 'সতর্কতা';

  @override
  String get alertsPlural => 'সতর্কতা';

  @override
  String get clearFilter => 'ফিল্টার মুছুন';

  @override
  String get noAlertsMatchFilter => 'এই ফিল্টারের সাথে কোনো সতর্কতা মেলে না';

  @override
  String get allPatientActivitiesSmooth => 'সব রোগীর কার্যকলাপ সুচারুভাবে চলছে';

  @override
  String get tryAdjustingFilter => 'আরও সতর্কতা দেখতে ফিল্টার সামঞ্জস্য করুন';

  @override
  String get viewAllAlerts => 'সব সতর্কতা দেখুন';

  @override
  String get alertMarkedAsRead => 'সতর্কতা পঠিত হিসেবে চিহ্নিত';

  @override
  String alertsMarkedAsRead(int count) {
    return '$countটি সতর্কতা পঠিত হিসেবে চিহ্নিত';
  }

  @override
  String get allAlertsAlreadyRead => 'সব সতর্কতা ইতিমধ্যে পঠিত';

  @override
  String get myPatientsTitle => 'আমার রোগী';

  @override
  String get patientsConnectedSubtitle => 'আপনার সাথে সংযুক্ত রোগী';

  @override
  String get myPatientsSection => 'আমার রোগী';

  @override
  String connectedCount(int count) {
    return '$count সংযুক্ত';
  }

  @override
  String get searchPatientsHint => 'রোগী খুঁজুন...';

  @override
  String get noPatientsMatchSearch =>
      'আপনার অনুসন্ধানের সাথে কোনো রোগী মেলে না।';

  @override
  String get noPatientsConnectedYet => 'এখনও কোনো রোগী সংযুক্ত নেই';

  @override
  String get acceptInvitationToSeePatient =>
      'রোগী দেখতে একটি আমন্ত্রণ গ্রহণ করুন।';

  @override
  String get badgeNew => 'নতুন';

  @override
  String joinedOn(String date) {
    return 'যোগ দিয়েছেন $date';
  }

  @override
  String get neverSynced => 'এখনও লোড হয়নি';

  @override
  String get privacyDataRequestMessage =>
      'আপনার ডেটা রপ্তানি বা মুছে ফেলতে privacy@remiminder.ai এ যোগাযোগ করুন।';

  @override
  String syncMinutesAgo(int minutes) {
    return '$minutes মি. আগে';
  }

  @override
  String syncHoursAgo(int hours) {
    return '$hours ঘ. আগে';
  }

  @override
  String syncDaysAgo(int days) {
    return '$days দি. আগে';
  }

  @override
  String get primaryCondition => 'প্রাথমিক অবস্থা';

  @override
  String get lastSynced => 'সর্বশেষ সিঙ্ক';

  @override
  String get allergiesLabel => 'অ্যালার্জি';

  @override
  String get dateOfBirth => 'জন্ম তারিখ';

  @override
  String get currentMedications => 'বর্তমান ওষুধ';

  @override
  String get viewCarePlan => 'কেয়ার প্ল্যান দেখুন';

  @override
  String get remindersButton => 'রিমাইন্ডার';

  @override
  String get caregiverCareTeamSubtitle =>
      'পরিবার বা চিকিৎসা কর্মীকে আমন্ত্রণ করুন';

  @override
  String get invitationsReceived => 'প্রাপ্ত আমন্ত্রণ';

  @override
  String pendingBadge(int count) {
    return '$count অপেক্ষমাণ';
  }

  @override
  String get patientOverviewTitle => 'রোগীর সংক্ষিপ্ত বিবরণ';

  @override
  String get patientOverviewTabVisits => 'ভিজিট';

  @override
  String get patientOverviewTabReminders => 'অনুস্মারক';

  @override
  String get patientOverviewNoVisits => 'কোনো ভিজিট নেই';

  @override
  String get patientOverviewNoReminders => 'কোনো অনুস্মারক নেই';

  @override
  String get patientOverviewMissingPatientId => 'রোগীর তথ্য অনুপস্থিত';

  @override
  String get patientOverviewLastVisit => 'শেষ ভিজিট';

  @override
  String get patientOverviewCareTeam => 'কেয়ার টিম সদস্য';

  @override
  String get patientOverviewScheduledReminder => 'নির্ধারিত অনুস্মারক';

  @override
  String get patientOverviewNever => 'কখনো নয়';

  @override
  String get patientOverviewYesterday => 'গতকাল';

  @override
  String get statusViewed => 'দেখা হয়েছে';

  @override
  String get statusExpired => 'মেয়াদোত্তীর্ণ';

  @override
  String get statusJoined => 'যোগ দিয়েছেন';

  @override
  String get noInvitationsToShow => 'দেখানোর জন্য কোনো আমন্ত্রণ নেই';

  @override
  String invitedByLabel(String name) {
    return 'আমন্ত্রিত: $name';
  }

  @override
  String get acceptInvitation => 'গ্রহণ করুন';

  @override
  String get declineInvitation => 'প্রত্যাখ্যান';

  @override
  String get invitationDeclined => 'আমন্ত্রণ প্রত্যাখ্যান করা হয়েছে';

  @override
  String joinedCareTeamSnackbar(String patientName, String role) {
    return '$patientName-এর কেয়ার টিমে $role হিসেবে যোগ দিয়েছেন';
  }

  @override
  String get manageAccess => 'অ্যাক্সেস পরিচালনা';

  @override
  String get manageAccessDescription =>
      'কেয়ারগিভারের অনুমতি আপডেট করুন বা অ্যাক্সেস সরান.';

  @override
  String get manage => 'পরিচালনা';

  @override
  String get accessUpdatedSuccess => 'অ্যাক্সেস সফলভাবে আপডেট হয়েছে';

  @override
  String get accessUpdateFailed => 'অ্যাক্সেস আপডেট ব্যর্থ. আবার চেষ্টা করুন.';

  @override
  String get removeCaregiverTitle => 'কেয়ারগিভার সরাবেন?';

  @override
  String get removeCaregiverMessage =>
      'আপনি কি নিশ্চিত এই কেয়ারগিভারকে সরাতে চান? তাদের অ্যাক্সেস তৎক্ষণাৎ বন্ধ হয়ে যাবে.';

  @override
  String get remove => 'সরান';

  @override
  String get updatingAccess => 'অ্যাক্সেস আপডেট হচ্ছে...';

  @override
  String get removingCaregiver => 'কেয়ারগিভার সরানো হচ্ছে...';

  @override
  String get removeCaregiverFailed =>
      'কেয়ারগিভার সরাতে ব্যর্থ. আবার চেষ্টা করুন.';

  @override
  String get viewAccess => 'দেখার অনুমতি';

  @override
  String get fullAccess => 'সম্পূর্ণ অ্যাক্সেস';

  @override
  String get viewOnly => 'শুধু দেখুন';

  @override
  String get resendingInvitation => 'আমন্ত্রণ পুনরায় পাঠানো হচ্ছে...';

  @override
  String get invitationResent => 'আমন্ত্রণ পুনরায় পাঠানো হয়েছে';

  @override
  String get failedToResendInvitation => 'আমন্ত্রণ পুনরায় পাঠাতে ব্যর্থ';

  @override
  String get cancelingInvitation => 'আমন্ত্রণ বাতিল করা হচ্ছে...';

  @override
  String get invitationCanceled => 'আমন্ত্রণ বাতিল';

  @override
  String get failedToCancelInvitation => 'আমন্ত্রণ বাতিল করতে ব্যর্থ';

  @override
  String get relationshipSon => 'পুত্র';

  @override
  String get relationshipDaughter => 'কন্যা';

  @override
  String get relationshipFriend => 'বন্ধু';

  @override
  String get relationshipSpousePartner => 'স্বামী/স্ত্রী/সঙ্গী';

  @override
  String get relationshipParent => 'অভিভাবক';

  @override
  String get relationshipChild => 'সন্তান';

  @override
  String get relationshipFamilyMember => 'পরিবারের সদস্য';

  @override
  String get relationshipHealthcareProfessional => 'স্বাস্থ্যসেবা পেশাদার';

  @override
  String get relationshipCaregiver => 'কেয়ারগিভার';

  @override
  String get relationshipSister => 'বোন';

  @override
  String get relationshipBrother => 'ভাই';

  @override
  String get relationshipOther => 'অন্যান্য';

  @override
  String get visitActionTitle => 'আপনি কী করতে চান?';

  @override
  String get visitActionAudioTitle => 'অডিও কথোপকথন রেকর্ড করুন';

  @override
  String get visitActionAudioSubtitle =>
      'স্বয়ংক্রিয় সারাংশের জন্য আপনার ডাক্তারের ভিজিট রেকর্ড করুন';

  @override
  String get visitActionCaptureTitle => 'ক্যাপচার ও স্ক্যান';

  @override
  String get visitActionCaptureSubtitle =>
      'রিপোর্ট, ওষুধের বোতল ও নথির ছবি তুলুন';

  @override
  String get inviteCaregiverDialogTitle => 'যত্নকারীকে আমন্ত্রণ';

  @override
  String get caregiverNameHint => 'যত্নকারীর পুরো নাম লিখুন';

  @override
  String get caregiverEmailHint => 'যত্নকারীর ইমেইল ঠিকানা লিখুন';

  @override
  String get relationshipLabel => 'সম্পর্ক';

  @override
  String get relationshipHint => 'যেমন, ছেলে, মেয়ে, বন্ধু, নার্স';

  @override
  String get sendInvite => 'আমন্ত্রণ পাঠান';

  @override
  String get emailAndRoleRequired => 'ইমেইল ও ভূমিকা প্রয়োজন';

  @override
  String get summaryReadyTitle => 'আপনার ভিজিট সারাংশ প্রস্তুত!';

  @override
  String get summaryReadyBody => 'আপনি কি এখনই দেখতে চান?';

  @override
  String get later => 'পরে';

  @override
  String get viewSummary => 'সারাংশ দেখুন';

  @override
  String get noLabResultsYet => 'এখনও কোনো ল্যাব ফলাফল নেই';

  @override
  String get labResultsScanHint =>
      'এখানে ফলাফল দেখতে ক্যাপচার ও স্ক্যান দিয়ে ল্যাব রিপোর্ট স্ক্যান করুন।';

  @override
  String get captureAndScan => 'ক্যাপচার ও স্ক্যান';

  @override
  String get noScannedDocsYet => 'এখনও কোনো স্ক্যান করা নথি নেই';

  @override
  String get scannedDocsHint =>
      'আপনার ভিজিটের সময় স্ক্যান করা নথি এখানে দেখা যাবে।';

  @override
  String get selectAtLeastOneSummary => 'অন্তত একটি সারাংশ নির্বাচন করুন';

  @override
  String get failedToDeleteSummaries =>
      'সারাংশ মুছতে ব্যর্থ। আবার চেষ্টা করুন।';

  @override
  String get noCaregiverAddedYet => 'এখনও কোনো যত্নকারী যোগ করা হয়নি';

  @override
  String get summaryGenerationRestarted => 'সারাংশ তৈরি পুনরায় শুরু হয়েছে';

  @override
  String retryFailed(String error) {
    return 'পুনরায় চেষ্টা ব্যর্থ: $error';
  }

  @override
  String get generateSummary => 'সারাংশ তৈরি করুন';

  @override
  String get discardRecording => 'রেকর্ডিং বাতিল করুন';

  @override
  String unableToStartRecording(String error) {
    return 'রেকর্ডিং শুরু করা যায়নি: $error';
  }

  @override
  String get recordingCompleted => 'রেকর্ডিং সম্পন্ন!';

  @override
  String unableToStopRecording(String error) {
    return 'রেকর্ডিং বন্ধ করা যায়নি: $error';
  }

  @override
  String get recordingDiscarded => 'রেকর্ডিং বাতিল করা হয়েছে';

  @override
  String get unableToOpenPrivacyPolicy => 'গোপনীয়তা নীতি খোলা যায়নি।';

  @override
  String get noRecordingAvailable => 'কোনো রেকর্ডিং নেই';

  @override
  String get uploadingAudio => 'অডিও আপলোড হচ্ছে...';

  @override
  String failedToUploadAudio(String error) {
    return 'অডিও আপলোড ব্যর্থ: $error';
  }

  @override
  String get stopRecordingTitle => 'রেকর্ডিং বন্ধ করবেন?';

  @override
  String get stopRecordingMessage =>
      'Are you sure you want to stop recording? This action cannot be undone.';

  @override
  String get continueRecording => 'রেকর্ডিং চালিয়ে যান';

  @override
  String get stopAndDiscard => 'বন্ধ করুন ও বাতিল করুন';

  @override
  String get share => 'শেয়ার';

  @override
  String get cameraNotReady => 'ক্যামেরা প্রস্তুত নয়। আবার চেষ্টা করুন।';

  @override
  String failedToCaptureImage(String error) {
    return 'ছবি তোলা ব্যর্থ: $error';
  }

  @override
  String get unableToStartCamera =>
      'ক্যামেরা শুরু করা যায়নি। আবার চেষ্টা করুন।';

  @override
  String get cameraReadyHint =>
      'ক্যামেরা প্রস্তুত। নথি রাখুন এবং ক্যাপচার ট্যাপ করুন।';

  @override
  String unableToStartScanning(String error) {
    return 'স্ক্যান শুরু করা যায়নি: $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'ছবি আপলোড ব্যর্থ: $error';
  }

  @override
  String get noImageToProcess =>
      'প্রক্রিয়ার জন্য ছবি নেই। আবার ক্যাপচার করুন।';

  @override
  String get documentScannedSaved => 'নথি স্ক্যান ও সংরক্ষিত!';

  @override
  String scanProcessingFailed(String error) {
    return 'স্ক্যান প্রক্রিয়াকরণ ব্যর্থ: $error';
  }

  @override
  String get scanSavedToHistory => 'স্ক্যান আপনার ভিজিট ইতিহাসে সংরক্ষিত';

  @override
  String localNotificationSchedulingFailed(String error) {
    return 'স্থানীয় বিজ্ঞপ্তি শিডিউল ব্যর্থ: $error';
  }

  @override
  String reminderRescheduleFailed(String error) {
    return 'রিমাইন্ডার পুনঃনির্ধারণ ব্যর্থ: $error';
  }

  @override
  String get authenticationErrorLoginAgain =>
      'প্রমাণীকরণ ত্রুটি। আবার লগ ইন করুন।';
}
