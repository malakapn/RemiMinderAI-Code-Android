// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Gujarati (`gu`).
class AppLocalizationsGu extends AppLocalizations {
  AppLocalizationsGu([String locale = 'gu']) : super(locale);

  @override
  String get appTitle => 'RemiMinder';

  @override
  String get login => 'લૉગિન કરો';

  @override
  String get logout => 'લોગઆઉટ';

  @override
  String get settings => 'સેટિંગ્સ';

  @override
  String get language => 'ભાષા';

  @override
  String get profileSettings => 'પ્રોફાઇલ સેટિંગ્સ';

  @override
  String get languageSettings => 'ભાષા સેટિંગ્સ';

  @override
  String languagesAvailableCount(int count) {
    return '$count ભાષાઓ';
  }

  @override
  String get scrollForMoreLanguages => 'બધી ભાષાઓ જોવા નીચે સ્ક્રોલ કરો';

  @override
  String languageUpdated(String language) {
    return 'ભાષા અપડેટ કરી. એપ્લિકેશન હવે પ્રદર્શિત થશે$language.';
  }

  @override
  String get navHome => 'ઘર';

  @override
  String get navVisits => 'મુલાકાતો';

  @override
  String get navOverview => 'વિહંગાવલોકન';

  @override
  String get navCareTeam => 'સંભાળ ટીમ';

  @override
  String get navProfile => 'પ્રોફાઇલ';

  @override
  String get navPatients => 'દર્દીઓ';

  @override
  String get goodMorning => 'શુભ સવાર';

  @override
  String get goodAfternoon => 'શુભ બપોર';

  @override
  String get goodEvening => 'શુભ સાંજ';

  @override
  String get goodNight => 'શુભ રાત્રિ';

  @override
  String get howAreYouFeeling => 'આજે તમને કેવું લાગે છે?';

  @override
  String get todaysProgress => 'આજની પ્રગતિ';

  @override
  String doneCount(int done, int total) {
    return '$done/$totalપૂર્ણ';
  }

  @override
  String get yourSchedule => 'તમારું શેડ્યૂલ';

  @override
  String get seeAll => 'બધા જુઓ →';

  @override
  String get nothingScheduledYet => 'હજુ સુધી કંઈ સુનિશ્ચિત નથી';

  @override
  String get unableToLoadReminders => 'રીમાઇન્ડર્સ લોડ કરવામાં અસમર્થ';

  @override
  String get addReminder => 'રીમાઇન્ડર ઉમેરો';

  @override
  String get myTasks => 'મારા કાર્યો';

  @override
  String pendingCount(int count) {
    return '$countબાકી';
  }

  @override
  String get noTasksYet => 'હજુ સુધી કોઈ કાર્ય નથી';

  @override
  String get addTask => 'કાર્ય ઉમેરો';

  @override
  String get statusUpcoming => 'આગામી';

  @override
  String get statusScheduled => 'સુનિશ્ચિત';

  @override
  String get statusDone => 'થઈ ગયું';

  @override
  String get reminder => 'રીમાઇન્ડર';

  @override
  String get task => 'કાર્ય';

  @override
  String get careTeamTitle => 'સંભાળ ટીમ';

  @override
  String get careTeamSubtitle =>
      'તમે નિયંત્રણમાં છો. નીચે તમારી શેરિંગ પરવાનગીઓની સમીક્ષા કરો.';

  @override
  String get sectionPending => 'બાકી';

  @override
  String get sectionAddNew => 'નવું ઉમેરો';

  @override
  String get inviteCaregiver => 'સંભાળ રાખનારને આમંત્રિત કરો';

  @override
  String get inviteCaregiverSubtitle =>
      'તમારી સ્વાસ્થ્ય માહિતીની ઍક્સેસ શેર કરો';

  @override
  String get invitationPending => 'આમંત્રણ બાકી છે';

  @override
  String get resend => 'ફરી મોકલો';

  @override
  String get cancel => 'રદ કરો';

  @override
  String get activeCaregivers => 'સક્રિય સંભાળ રાખનારાઓ';

  @override
  String get noCaregiversYet => 'હજુ સુધી કોઈ સંભાળ રાખનાર ઉમેરાયા નથી';

  @override
  String get english => 'અંગ્રેજી';

  @override
  String get spanish => 'સ્પેનિશ';

  @override
  String get hindi => 'હિન્દી';

  @override
  String get french => 'ફ્રેન્ચ';

  @override
  String get portuguese => 'પોર્ટુગીઝ';

  @override
  String get german => 'જર્મન';

  @override
  String get bangla => 'બાંગ્લા';

  @override
  String get tamil => 'તમિલ';

  @override
  String get gujarati => 'ગુજરાતી';

  @override
  String get punjabi => 'ਪੰਜਾਬੀ';

  @override
  String get accountDetails => 'ખાતાની વિગતો';

  @override
  String get accountDetailsSubtitle => 'તમારી પ્રોફાઇલ માહિતી જુઓ';

  @override
  String get accountSecurity => 'એકાઉન્ટ સુરક્ષા';

  @override
  String get accountSecuritySubtitle => 'પાસવર્ડ અને ગોપનીયતા મેનેજ કરો';

  @override
  String get notificationsLabel => 'સૂચનાઓ';

  @override
  String get mobileLabel => 'મોબાઈલ';

  @override
  String get emailLabel => 'ઈમેલ';

  @override
  String get upgrade => 'અપગ્રેડ કરો';

  @override
  String get signOut => 'સાઇન આઉટ કરો';

  @override
  String get deleteAccount => 'એકાઉન્ટ કાઢી નાખો';

  @override
  String get deleteAccountTitle => 'એકાઉન્ટ કાઢી નાખો';

  @override
  String get deleteAccountMessage =>
      'આ તમારા એકાઉન્ટ અને તમારો બધો ડેટા કાયમ માટે કાઢી નાખશે. આ પૂર્વવત્ કરી શકાતું નથી. શું તમને ખાતરી છે?';

  @override
  String get delete => 'કાઢી નાખો';

  @override
  String get searchSummariesHint => 'સારાંશ શોધો...';

  @override
  String get tabSummaries => 'સારાંશ';

  @override
  String get tabLabResults => 'લેબ પરિણામો';

  @override
  String get tabScannedDocs => 'સ્કેન કરેલ દસ્તાવેજ';

  @override
  String get noSummariesYet => 'હજુ સુધી કોઈ સારાંશ નથી';

  @override
  String get summariesWillAppearHere => 'તમારી મુલાકાતના સારાંશ અહીં દેખાશે';

  @override
  String get failedToLoadSummaries => 'સારાંશ લોડ કરવામાં નિષ્ફળ';

  @override
  String get retry => 'ફરી પ્રયાસ કરો';

  @override
  String get shareLabel => 'શેર કરો';

  @override
  String get doctorVisit => 'ડૉક્ટરની મુલાકાત';

  @override
  String timeToday(String time) {
    return 'આજે,$time';
  }

  @override
  String timeYesterday(String time) {
    return 'ગઈ કાલે,$time';
  }

  @override
  String get summaryProcessingHint =>
      'તાજું કરવા માટે નીચે ખેંચો. આમાં સામાન્ય રીતે 30-60 સેકન્ડ લાગે છે.';

  @override
  String get summaryCouldNotGenerate => 'સારાંશ જનરેટ કરી શકાયો નથી';

  @override
  String get retrySummary => 'ફરી પ્રયાસ કરો સારાંશ';

  @override
  String get stuckRetrySummary => 'અટકી ગયા? ફરી પ્રયાસ કરો સારાંશ';

  @override
  String get scannedDocument => 'સ્કેન કરેલ દસ્તાવેજ';

  @override
  String scannedOn(String date) {
    return 'સ્કેન કર્યું$date';
  }

  @override
  String get visitDetails => 'વિગતોની મુલાકાત લો';

  @override
  String get healthVisitSummary => 'આરોગ્ય મુલાકાત સારાંશ';

  @override
  String get refreshSummaryTooltip => 'તાજું સારાંશ';

  @override
  String get preparingVisitSummary =>
      'મુલાકાતનો સારાંશ તૈયાર કરી રહ્યાં છીએ...';

  @override
  String get preparingVisitSubtitle => 'આમાં એક મિનિટ લાગી શકે છે.';

  @override
  String get unableToLoadVisitSummary => 'મુલાકાતનો સારાંશ લોડ કરવામાં અસમર્થ';

  @override
  String get visitSummaryUnavailable => 'મુલાકાતનો સારાંશ અનુપલબ્ધ છે';

  @override
  String get visitSummary => 'સારાંશની મુલાકાત લો';

  @override
  String get visitProcessingTitle =>
      'તમારી મુલાકાતની પ્રક્રિયા કરવામાં આવી રહી છે';

  @override
  String get visitProcessingBody =>
      'આમાં 30-60 સેકન્ડ લાગી શકે છે.\nતમે એપ્લિકેશનનો ઉપયોગ કરવાનું ચાલુ રાખી શકો છો. પ્રગતિ જોવા માટે વિહંગાવલોકન ખોલો.';

  @override
  String get viewOverviewAction => 'વિહંગાવલોકન જુઓ';

  @override
  String get goToHome => 'હોમ પર જાઓ';

  @override
  String get medication => 'દવા';

  @override
  String get nextToDo => 'કરવા માટે આગળ';

  @override
  String get conditionsDiscussed => 'શરતોની ચર્ચા કરી';

  @override
  String get followUp => 'ફોલો અપ કરો';

  @override
  String get nameLabel => 'નામ';

  @override
  String get notSet => 'સેટ નથી';

  @override
  String get appleIdHidden => 'Apple ID (છુપાયેલ)';

  @override
  String get accountType => 'એકાઉન્ટ પ્રકાર';

  @override
  String get patientRole => 'દર્દી';

  @override
  String get caregiverRole => 'સંભાળ રાખનાર';

  @override
  String get phoneLabel => 'ફોન';

  @override
  String get edit => 'સંપાદિત કરો';

  @override
  String get add => 'ઉમેરો';

  @override
  String get planLabel => 'યોજના';

  @override
  String get planFree => 'મફત';

  @override
  String get planPremium => 'પ્રીમિયમ';

  @override
  String get chooseYourRole => 'તમારી ભૂમિકા પસંદ કરો';

  @override
  String get chooseYourRoleSubtitle =>
      'તમે RemiMinder કેવી રીતે ઉપયોગ કરશો તે પસંદ કરો';

  @override
  String get patientRoleCardDescription =>
      'તમારી દવાઓ, અપોઇન્ટમેન્ટ્સ અને આરોગ્ય રેકોર્ડ્સ મેનેજ કરો';

  @override
  String get caregiverRoleCardDescription =>
      'પરિવારના સભ્યો અથવા દર્દીઓની દવાઓ અને સંભાળ મેનેજ કરવામાં મદદ કરો';

  @override
  String get continueButton => 'ચાલુ રાખો';

  @override
  String get usageLabel => 'ઉપયોગ';

  @override
  String freePlanUsage(int used, int limit) {
    return '$used / $limit સારાંશ વપરાયા';
  }

  @override
  String get unlimited => 'અમર્યાદિત';

  @override
  String get editPhoneNumber => 'ફોન નંબર સંપાદિત કરો';

  @override
  String get phoneNumber => 'ફોન નંબર';

  @override
  String get save => 'સાચવો';

  @override
  String get phoneMinLength => 'ફોન નંબર ઓછામાં ઓછો 8 અક્ષર લાંબો હોવો જોઈએ';

  @override
  String get phoneUpdatedSuccess => 'ફોન નંબર સફળતાપૂર્વક અપડેટ થયો';

  @override
  String phoneUpdateFailed(String error) {
    return 'ફોન નંબર અપડેટ કરવામાં નિષ્ફળ:$error';
  }

  @override
  String get changePassword => 'પાસવર્ડ બદલો';

  @override
  String get changePasswordSubtitle =>
      'સુરક્ષા માટે તમારા એકાઉન્ટનો પાસવર્ડ અપડેટ કરો';

  @override
  String get privacySettings => 'ગોપનીયતા સેટિંગ્સ';

  @override
  String get privacySettingsSubtitle => 'તમારી ડેટા શેરિંગ પસંદગીઓને મેનેજ કરો';

  @override
  String get managePrivacy => 'ગોપનીયતા મેનેજ કરો';

  @override
  String changePasswordProviderMessage(String provider) {
    return 'તમે ઉપયોગ કરીને સાઇન ઇન કર્યું છે$provider. કૃપા કરીને તમારામાં તમારો પાસવર્ડ બદલો$providerએકાઉન્ટ';
  }

  @override
  String get ok => 'ઓકે';

  @override
  String get selectDate => 'તારીખ પસંદ કરો';

  @override
  String get changePasswordIntro =>
      'તમારું એકાઉન્ટ સુરક્ષિત રાખવા માટે તમારો પાસવર્ડ અપડેટ કરો.';

  @override
  String get currentPassword => 'વર્તમાન પાસવર્ડ';

  @override
  String get currentPasswordHint => 'તમારો વર્તમાન પાસવર્ડ દાખલ કરો';

  @override
  String get enterCurrentPassword =>
      'કૃપા કરીને તમારો વર્તમાન પાસવર્ડ દાખલ કરો';

  @override
  String get newPassword => 'નવો પાસવર્ડ';

  @override
  String get newPasswordHint => 'તમારો નવો પાસવર્ડ દાખલ કરો';

  @override
  String get enterNewPassword => 'કૃપા કરીને નવો પાસવર્ડ દાખલ કરો';

  @override
  String get passwordMinLength => 'પાસવર્ડ ઓછામાં ઓછો 8 અક્ષરનો હોવો જોઈએ';

  @override
  String get confirmNewPassword => 'નવા પાસવર્ડની પુષ્ટિ કરો';

  @override
  String get confirmNewPasswordHint => 'તમારો નવો પાસવર્ડ ફરીથી દાખલ કરો';

  @override
  String get confirmNewPasswordRequired =>
      'કૃપા કરીને તમારા નવા પાસવર્ડની પુષ્ટિ કરો';

  @override
  String get passwordsDoNotMatch => 'પાસવર્ડ મેળ ખાતા નથી';

  @override
  String get updatePassword => 'પાસવર્ડ અપડેટ કરો';

  @override
  String get passwordUpdatedSuccess => 'પાસવર્ડ સફળતાપૂર્વક અપડેટ થયો';

  @override
  String get passwordUpdateFailed => 'પાસવર્ડ અપડેટ કરવામાં નિષ્ફળ';

  @override
  String get wrongPassword => 'વર્તમાન પાસવર્ડ ખોટો છે';

  @override
  String get weakPassword => 'પાસવર્ડ ખૂબ નબળો છે';

  @override
  String get requiresRecentLogin => 'કૃપા કરીને ફરી લોગ ઇન કરો અને પ્રયાસ કરો';

  @override
  String get checkInternetConnection => 'તમારું ઇન્ટરનેટ કનેક્શન તપાસો';

  @override
  String get dataSharing => 'ડેટા શેરિંગ';

  @override
  String get allowCaregiverSummaries =>
      'સંભાળ રાખનારને સારાંશ જોવાની મંજૂરી આપો';

  @override
  String get allowCaregiverMedications =>
      'સંભાળ રાખનારને દવાઓ જોવાની મંજૂરી આપો';

  @override
  String get allowCaregiverReminders =>
      'સંભાળ રાખનારને રીમાઇન્ડર્સ જોવાની મંજૂરી આપો';

  @override
  String get allowAiImprovement =>
      'ઉત્પાદનને સુધારવા માટે AI ને મારા ડેટાનો ઉપયોગ કરવાની મંજૂરી આપો';

  @override
  String get communicationAndConsent => 'સંચાર અને સંમતિ';

  @override
  String get allowEmailNotifications => 'ઇમેઇલ સૂચનાઓને મંજૂરી આપો';

  @override
  String get allowSmsNotifications => 'SMS સૂચનાઓને મંજૂરી આપો';

  @override
  String get allowPushNotifications => 'પુશ સૂચનાઓને મંજૂરી આપો';

  @override
  String get dataControl => 'ડેટા નિયંત્રણ';

  @override
  String get exportMyData => 'મારો ડેટા નિકાસ કરો';

  @override
  String get deleteAllMedicalRecords => 'મારા તમામ મેડિકલ રેકોર્ડ્સ કાઢી નાખો';

  @override
  String get deleteMedicalRecordsTitle => 'તબીબી રેકોર્ડ્સ કાઢી નાખો';

  @override
  String get deleteMedicalRecordsMessage =>
      'આ તમારા તમામ મેડિકલ રેકોર્ડ્સને કાયમ માટે કાઢી નાખશે. આ ક્રિયા પૂર્વવત્ કરી શકાતી નથી.';

  @override
  String get deleteRecords => 'રેકોર્ડ્સ કાઢી નાખો';

  @override
  String get deleteMyAccount => 'મારું એકાઉન્ટ કાઢી નાખો';

  @override
  String get legal => 'કાનૂની';

  @override
  String get viewPrivacyPolicy => 'ગોપનીયતા નીતિ જુઓ';

  @override
  String get viewTermsOfService => 'સેવાની શરતો જુઓ';

  @override
  String get termsOfService => 'સેવાની શરતો';

  @override
  String get termsOfServiceBody =>
      'RemiMinder માટે સેવાની શરતો\n\n1. શરતોની સ્વીકૃતિ\nRemiMinder નો ઉપયોગ કરીને, તમે આ શરતો સાથે સંમત થાઓ છો.\n\n2. સેવાનો ઉપયોગ\nRemiMinder આરોગ્યસંભાળ અને દવા રીમાઇન્ડર્સનું સંચાલન કરવામાં મદદ કરવા માટે રચાયેલ છે.\n\n3. ગોપનીયતા\nતમારી ગોપનીયતા અમારા માટે મહત્વપૂર્ણ છે. તમામ આરોગ્ય ડેટા સુરક્ષિત રીતે હેન્ડલ કરવામાં આવે છે.\n\nસેવાની સંપૂર્ણ શરતો માટે, કૃપા કરીને અમારી વેબસાઇટની મુલાકાત લો.';

  @override
  String get privacyPolicy => 'ગોપનીયતા નીતિ';

  @override
  String get privacyPolicyBody =>
      'RemiMinder માટે ગોપનીયતા નીતિ\n\n1. માહિતી અમે એકત્રિત કરીએ છીએ\nઅમે અમારી સેવાને બહેતર બનાવવા માટે તમે પ્રદાન કરો છો તે માહિતી એકત્રિત કરીએ છીએ અને ડેટાનો ઉપયોગ કરીએ છીએ.\n\n2. અમે માહિતીનો ઉપયોગ કેવી રીતે કરીએ છીએ\nમાહિતીનો ઉપયોગ હેલ્થકેર મેનેજમેન્ટ સેવાઓ પ્રદાન કરવા માટે થાય છે.\n\n3. માહિતી શેરિંગ\nઅમે તમારી અંગત માહિતી વેચતા નથી.\n\nસંપૂર્ણ ગોપનીયતા નીતિ માટે, કૃપા કરીને અમારી વેબસાઇટની મુલાકાત લો.';

  @override
  String get close => 'બંધ કરો';

  @override
  String featureComingSoon(String feature) {
    return '$featureટૂંક સમયમાં આવી રહ્યું છે';
  }

  @override
  String get emailNotificationPreferenceMessage =>
      'Email notification preferences are managed by our support team. Contact privacy@remiminder.ai to update them.';

  @override
  String get pushNotificationsDisabled =>
      'Push notifications are disabled. Enable them in your device settings to receive alerts.';

  @override
  String get caregiverSharingEnabled => 'કેરગીવર શેરિંગ સક્ષમ છે';

  @override
  String get caregiverSharingDisabled => 'કેરગીવર શેરિંગ અક્ષમ છે';

  @override
  String get dataExport => 'ડેટા નિકાસ';

  @override
  String get remindersTitle => 'રીમાઇન્ડર્સ';

  @override
  String get tabAll => 'બધા';

  @override
  String get tabToday => 'આજે';

  @override
  String get tabPending => 'બાકી છે';

  @override
  String get tabCompleted => 'પૂર્ણ થયું';

  @override
  String get searchRemindersHint => 'રિમાઇન્ડર્સ શોધો...';

  @override
  String get failedToLoadRemindersRetry =>
      'રિમાઇન્ડર્સ લોડ કરવામાં નિષ્ફળ. ફરી પ્રયાસ કરો';

  @override
  String get deleteReminderTitle => 'રીમાઇન્ડર કાઢી નાખો';

  @override
  String get deleteReminderMessage =>
      'શું તમે ખરેખર આ રીમાઇન્ડર કાઢી નાખવા માંગો છો?';

  @override
  String get markDone => 'માર્ક ડન';

  @override
  String get snooze => 'સ્નૂઝ';

  @override
  String snoozedUntil(String time) {
    return 'સુધી સ્નૂઝ કર્યું$time';
  }

  @override
  String get statusDueNow => 'બાકી હવે';

  @override
  String get statusActive => 'સક્રિય';

  @override
  String get statusMissed => 'ચૂકી ગયા';

  @override
  String get statusSnoozed => 'સ્નૂઝ કર્યું';

  @override
  String get statusSkipped => 'છોડી દીધું';

  @override
  String get statusPending => 'બાકી છે';

  @override
  String get noRemindersFound => 'કોઈ રીમાઇન્ડર્સ મળ્યાં નથી';

  @override
  String get noRemindersMatchSearch =>
      'કોઈ રીમાઇન્ડર તમારી શોધ સાથે મેળ ખાતા નથી';

  @override
  String get createFirstReminder =>
      'પ્રારંભ કરવા માટે તમારું પ્રથમ રીમાઇન્ડર બનાવો';

  @override
  String get tryAdjustSearch => 'તમારા શોધ શબ્દોને સમાયોજિત કરવાનો પ્રયાસ કરો';

  @override
  String get createReminder => 'રીમાઇન્ડર બનાવો';

  @override
  String get newReminder => 'નવું રીમાઇન્ડર';

  @override
  String get editReminder => 'રીમાઇન્ડર સંપાદિત કરો';

  @override
  String get reminderTitleLabel => 'શીર્ષક';

  @override
  String get dosageOptional => 'ડોઝ (વૈકલ્પિક)';

  @override
  String get dosageHint => 'દા.ત. દિવસમાં એકવાર 10 મિલિગ્રામ';

  @override
  String get reminderTypeLabel => 'પ્રકાર';

  @override
  String get appointment => 'નિમણૂક';

  @override
  String get repeatLabel => 'પુનરાવર્તન કરો';

  @override
  String get once => 'એકવાર';

  @override
  String get daily => 'દૈનિક';

  @override
  String get weekly => 'સાપ્તાહિક';

  @override
  String get pleaseEnterTitle => 'કૃપા કરીને એક શીર્ષક દાખલ કરો';

  @override
  String get reminderCreated => 'રીમાઇન્ડર બનાવ્યું!';

  @override
  String failedToCreateReminder(String error) {
    return 'રીમાઇન્ડર બનાવવામાં નિષ્ફળ:$error';
  }

  @override
  String get saveChanges => 'ફેરફારો સાચવો';

  @override
  String get cannotRescheduleMissingType =>
      'ફરીથી શેડ્યૂલ કરી શકાતું નથી: રીમાઇન્ડર પ્રકાર ખૂટે છે';

  @override
  String get reminderUpdated => 'રીમાઇન્ડર અપડેટ કર્યું!';

  @override
  String failedToUpdateReminder(String error) {
    return 'અપડેટ કરવામાં નિષ્ફળ:$error';
  }

  @override
  String get reminderMarkedCompleted =>
      'રીમાઇન્ડર પૂર્ણ તરીકે ચિહ્નિત થયેલ છે!';

  @override
  String get reminderSnoozed30 => 'રિમાઇન્ડર 30 મિનિટ માટે સ્નૂઝ કર્યું';

  @override
  String timeInHours(int hours, String time) {
    return 'માં$hoursકલાક ($time)';
  }

  @override
  String timeInMinutes(int minutes, String time) {
    return 'માં$minutesમિનિટ ($time)';
  }

  @override
  String get timeNow => 'હવે';

  @override
  String timeHoursAgo(int hours) {
    return '$hoursકલાક પહેલા';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutesમિનિટ પહેલા';
  }

  @override
  String timeInDays(int days) {
    return '$days દિવસમાં';
  }

  @override
  String timeInHoursShort(int hours) {
    return '$hours કલાકમાં';
  }

  @override
  String timeInMinutesShort(int minutes) {
    return '$minutes મિનિટમાં';
  }

  @override
  String get selectTime => 'સમય પસંદ કરો';

  @override
  String get presetMorning => 'સવારે (8:00 AM)';

  @override
  String get presetNoon => 'બપોર (12:00 PM)';

  @override
  String get presetEvening => 'સાંજે (6:00 PM)';

  @override
  String get presetNight => 'રાત્રિ (8:00 PM)';

  @override
  String get hourLabel => 'કલાક';

  @override
  String get minuteLabel => 'મિનિ';

  @override
  String get amPmLabel => 'AM/PM';

  @override
  String get amLabel => 'એએમ';

  @override
  String get pmLabel => 'પીએમ';

  @override
  String selectedTimeLabel(String time) {
    return 'પસંદ કરેલ સમય:$time';
  }

  @override
  String setForTime(String time) {
    return 'માટે સેટ કરો$time ✓';
  }

  @override
  String get medicationAdherence => 'દવાનું પાલન';

  @override
  String get thisWeek => 'આ અઠવાડિયે';

  @override
  String get thisMonth => 'આ મહિને';

  @override
  String get overall => 'એકંદરે';

  @override
  String dosesCount(int done, int total) {
    return '$done/$totalડોઝ';
  }

  @override
  String get byMedication => 'દવા દ્વારા';

  @override
  String get noPastRemindersAnalyze =>
      'વિશ્લેષણ કરવા માટે કોઈ ભૂતકાળના રીમાઇન્ડર્સ નથી';

  @override
  String get adherenceTips => 'પાલન ટિપ્સ';

  @override
  String get adherenceTipsBody =>
      '• દવાના સમય માટે ફોન રીમાઇન્ડર્સ સેટ કરો\n• દવાઓ દેખાતી જગ્યાએ રાખો\n• દૈનિક માત્રા માટે ગોળી આયોજકનો ઉપયોગ કરો\n• પ્રેરિત રહેવા માટે તમારી પ્રગતિને ટ્રૅક કરો';

  @override
  String get actionFailed => 'ક્રિયા નિષ્ફળ';

  @override
  String get snoozeAlreadyUsed =>
      'આ રિમાઇન્ડર પહેલેથી જ એકવાર સ્નૂઝ કરવામાં આવ્યું હતું';

  @override
  String get reminderDeleted => 'રીમાઇન્ડર કાઢી નાખ્યું';

  @override
  String get deleteFailed => 'કાઢી નાખવામાં નિષ્ફળ';

  @override
  String get sectionRecentAlerts => 'તાજેતરની ચેતવણીઓ';

  @override
  String get viewAll => 'બધા જુઓ';

  @override
  String get sectionInvitations => 'આમંત્રણો';

  @override
  String get summaryPatients => 'દર્દીઓ';

  @override
  String get summaryAlerts => 'ચેતવણીઓ';

  @override
  String get summaryPending => 'બાકી છે';

  @override
  String get noAlertsAtThisTime => 'આ સમયે કોઈ ચેતવણીઓ નથી';

  @override
  String get noPendingInvitations => 'કોઈ બાકી આમંત્રણો નથી';

  @override
  String get pendingInvitationsTitle => 'બાકી આમંત્રણો';

  @override
  String invitationsWaiting(int count) {
    return '$countઆમંત્રણ(ઓ) રાહ જોઈ રહ્યું છે';
  }

  @override
  String get reviewAcceptInvitations =>
      'કેરગીવર આમંત્રણોની સમીક્ષા કરો અને સ્વીકારો.';

  @override
  String get viewInvitations => 'આમંત્રણો જુઓ';

  @override
  String get defaultPatient => 'દર્દી';

  @override
  String get defaultCaregiver => 'સંભાળ રાખનાર';

  @override
  String get caregiverHomeSubtitle => 'Your care dashboard';

  @override
  String get caregiverScheduleTitle => 'Support schedule';

  @override
  String get caregiverScheduleSubtitle => 'Reminders & appointments';

  @override
  String get caregiverAlertsSubtitle => 'Medication and care updates';

  @override
  String caregiverPatientTime(String name, String time) {
    return 'દર્દી:$name • $time';
  }

  @override
  String timeDaysAgo(int days) {
    return '$daysદિવસો પહેલા';
  }

  @override
  String get alertsTitle => 'ચેતવણીઓ';

  @override
  String get filterUnread => 'ન વાંચેલ';

  @override
  String get filterRead => 'વાંચો';

  @override
  String get filterHighPriority => 'ઉચ્ચ અગ્રતા';

  @override
  String get filterActionRequired => 'ક્રિયા જરૂરી';

  @override
  String get alertSingular => 'ચેતવણી';

  @override
  String get alertsPlural => 'ચેતવણીઓ';

  @override
  String get clearFilter => 'ફિલ્ટર સાફ કરો';

  @override
  String get noAlertsMatchFilter => 'કોઈ ચેતવણીઓ આ ફિલ્ટર સાથે મેળ ખાતી નથી';

  @override
  String get allPatientActivitiesSmooth =>
      'દર્દીઓની તમામ પ્રવૃતિઓ સરળતાથી ચાલી રહી છે';

  @override
  String get tryAdjustingFilter =>
      'વધુ ચેતવણીઓ જોવા માટે તમારા ફિલ્ટરને સમાયોજિત કરવાનો પ્રયાસ કરો';

  @override
  String get viewAllAlerts => 'બધી ચેતવણીઓ જુઓ';

  @override
  String get alertMarkedAsRead => 'ચેતવણી વાંચેલી તરીકે ચિહ્નિત કરી';

  @override
  String alertsMarkedAsRead(int count) {
    return 'ચિહ્નિત$countવાંચ્યા મુજબ ચેતવણીઓ';
  }

  @override
  String get allAlertsAlreadyRead => 'બધી ચેતવણીઓ પહેલેથી જ વાંચવામાં આવી છે';

  @override
  String get markAllAlertsRead => 'Mark all read';

  @override
  String get myPatientsTitle => 'મારા દર્દીઓ';

  @override
  String get patientsConnectedSubtitle => 'તમારી સાથે જોડાયેલા દર્દીઓ';

  @override
  String get myPatientsSection => 'મારા દર્દીઓ';

  @override
  String connectedCount(int count) {
    return '$countજોડાયેલ';
  }

  @override
  String get searchPatientsHint => 'દર્દીઓને શોધો...';

  @override
  String get noPatientsMatchSearch => 'કોઈ દર્દી તમારી શોધ સાથે મેળ ખાતા નથી.';

  @override
  String get noPatientsConnectedYet => 'હજુ સુધી કોઈ દર્દી જોડાયેલા નથી';

  @override
  String get acceptInvitationToSeePatient =>
      'અહીં દર્દીને જોવા માટેનું આમંત્રણ સ્વીકારો.';

  @override
  String get badgeNew => 'નવી';

  @override
  String joinedOn(String date) {
    return 'જોડાયા$date';
  }

  @override
  String get neverSynced => 'હજુ સુધી લોડ નથી';

  @override
  String get privacyDataRequestMessage =>
      'તમારો ડેટા નિકાસ કરવા અથવા કાઢી નાખવા માટે privacy@remiminder.ai નો સંપર્ક કરો.';

  @override
  String syncMinutesAgo(int minutes) {
    return '$minutesમી પહેલા';
  }

  @override
  String syncHoursAgo(int hours) {
    return '$hoursકલાક પહેલા';
  }

  @override
  String syncDaysAgo(int days) {
    return '$daysડી પહેલા';
  }

  @override
  String get primaryCondition => 'પ્રાથમિક સ્થિતિ';

  @override
  String get lastSynced => 'છેલ્લે સમન્વયિત';

  @override
  String get allergiesLabel => 'એલર્જી';

  @override
  String get dateOfBirth => 'જન્મ તારીખ';

  @override
  String get currentMedications => 'વર્તમાન દવાઓ';

  @override
  String get viewCarePlan => 'સંભાળ યોજના જુઓ';

  @override
  String get remindersButton => 'રીમાઇન્ડર્સ';

  @override
  String get caregiverCareTeamSubtitle =>
      'કુટુંબ અથવા તબીબી સ્ટાફને આમંત્રિત કરો';

  @override
  String get invitationsReceived => 'આમંત્રણો મળ્યા';

  @override
  String pendingBadge(int count) {
    return '$countબાકી';
  }

  @override
  String get patientOverviewTitle => 'દર્દીની ઝાંખી';

  @override
  String get patientOverviewTabVisits => 'મુલાકાતો';

  @override
  String get patientOverviewTabReminders => 'રીમાઇન્ડર્સ';

  @override
  String get patientOverviewNoVisits => 'કોઈ મુલાકાતો ઉપલબ્ધ નથી';

  @override
  String get patientOverviewNoReminders => 'કોઈ રીમાઇન્ડર ઉપલબ્ધ નથી';

  @override
  String get patientOverviewMissingPatientId => 'દર્દીની માહિતી ખૂટે છે';

  @override
  String get patientOverviewLastVisit => 'છેલ્લી મુલાકાત';

  @override
  String get patientOverviewCareTeam => 'સંભાળ ટીમના સભ્ય';

  @override
  String get patientOverviewScheduledReminder => 'સુનિશ્ચિત રીમાઇન્ડર';

  @override
  String get patientOverviewNever => 'ક્યારેય નહીં';

  @override
  String get patientOverviewYesterday => 'ગઈકાલે';

  @override
  String get statusViewed => 'જોયેલ';

  @override
  String get statusExpired => 'સમાપ્ત';

  @override
  String get statusJoined => 'જોડાયા';

  @override
  String get noInvitationsToShow => 'બતાવવા માટે કોઈ આમંત્રણ નથી';

  @override
  String invitedByLabel(String name) {
    return '$name દ્વારા આમંત્રિત';
  }

  @override
  String get acceptInvitation => 'સ્વીકારો';

  @override
  String get declineInvitation => 'નકારો';

  @override
  String get invitationDeclined => 'આમંત્રણ નકાર્યું';

  @override
  String joinedCareTeamSnackbar(String patientName, String role) {
    return '$patientName ની સંભાળ ટીમમાં $role તરીકે જોડાયા';
  }

  @override
  String get manageAccess => 'ઍક્સેસ મેનેજ કરો';

  @override
  String get manageAccessDescription =>
      'કેરગિવર પરવાનગી અપડેટ કરો અથવા ઍક્સેસ દૂર કરો.';

  @override
  String get manage => 'મેનેજ';

  @override
  String get accessUpdatedSuccess => 'ઍક્સેસ સફળતાપૂર્વક અપડેટ થઈ';

  @override
  String get accessUpdateFailed =>
      'ઍક્સેસ અપડેટ કરવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String get removeCaregiverTitle => 'કેરગિવર દૂર કરીએ?';

  @override
  String get removeCaregiverMessage =>
      'શું તમે ખરેખર આ કેરગિવરને દૂર કરવા માંગો છો? તેમની ઍક્સેસ તરત બંધ થશે.';

  @override
  String get remove => 'દૂર કરો';

  @override
  String get updatingAccess => 'ઍક્સેસ અપડેટ થઈ રહી છે...';

  @override
  String get removingCaregiver => 'કેરગિવર દૂર કરી રહ્યા છીએ...';

  @override
  String get removeCaregiverFailed =>
      'કેરગિવર દૂર કરવામાં નિષ્ફળ. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String get viewAccess => 'જુઓ ઍક્સેસ';

  @override
  String get fullAccess => 'પૂર્ણ ઍક્સેસ';

  @override
  String get viewOnly => 'માત્ર જુઓ';

  @override
  String get resendingInvitation => 'આમંત્રણ ફરી મોકલી રહ્યા છીએ...';

  @override
  String get invitationResent => 'આમંત્રણ ફરી મોકલ્યું';

  @override
  String get failedToResendInvitation => 'આમંત્રણ ફરી મોકલવામાં નિષ્ફળ';

  @override
  String get cancelingInvitation => 'આમંત્રણ રદ કરી રહ્યા છીએ...';

  @override
  String get invitationCanceled => 'આમંત્રણ રદ થયું';

  @override
  String get failedToCancelInvitation => 'આમંત્રણ રદ કરવામાં નિષ્ફળ';

  @override
  String get relationshipSon => 'પુત્ર';

  @override
  String get relationshipDaughter => 'પુત્રી';

  @override
  String get relationshipFriend => 'મિત્ર';

  @override
  String get relationshipSpousePartner => 'જીવનસાથી/સાથી';

  @override
  String get relationshipParent => 'માતાપિતા';

  @override
  String get relationshipChild => 'બાળક';

  @override
  String get relationshipFamilyMember => 'કુટુંબ સભ્ય';

  @override
  String get relationshipHealthcareProfessional => 'આરોગ્ય વ્યાવસાયિક';

  @override
  String get relationshipCaregiver => 'સંભાળ રાખનાર';

  @override
  String get relationshipSister => 'બહેન';

  @override
  String get relationshipBrother => 'ભાઈ';

  @override
  String get relationshipOther => 'અન્ય';

  @override
  String get visitActionTitle => 'તમે શું કરવા માંગો છો?';

  @override
  String get visitActionAudioTitle => 'ઑડિયો વાતચીત રેકોર્ડ કરો';

  @override
  String get visitActionAudioSubtitle =>
      'સ્વચાલિત સારાંશ માટે તમારી ડૉક્ટરની મુલાકાત રેકોર્ડ કરો';

  @override
  String get visitActionCaptureTitle => 'કેપ્ચર અને સ્કેન';

  @override
  String get visitActionCaptureSubtitle =>
      'રિપોર્ટ, દવાની બોટલો અને દસ્તાવેજોની ફોટો લો';

  @override
  String get inviteCaregiverDialogTitle => 'સંભાળ રાખનારને આમંત્રિત કરો';

  @override
  String get caregiverNameHint => 'સંભાળ રાખનારનું પૂરું નામ દાખલ કરો';

  @override
  String get caregiverEmailHint => 'સંભાળ રાખનારનું ઇમેઇલ સરનામું દાખલ કરો';

  @override
  String get relationshipLabel => 'સંબંધ';

  @override
  String get relationshipHint => 'દા.ત., પુત્ર, પુત્રી, મિત્ર, નર્સ';

  @override
  String get sendInvite => 'આમંત્રણ મોકલો';

  @override
  String get emailAndRoleRequired => 'ઇમેઇલ અને ભૂમિકા જરૂરી છે';

  @override
  String get summaryReadyTitle => 'તમારો મુલાકાત સારાંશ તૈયાર છે!';

  @override
  String get summaryReadyBody => 'શું તમે તે હમણાં જોવા માંગો છો?';

  @override
  String get later => 'પછી';

  @override
  String get viewSummary => 'સારાંશ જુઓ';

  @override
  String get noLabResultsYet => 'હજી સુધી કોઈ લેબ પરિણામો નથી';

  @override
  String get labResultsScanHint =>
      'પરિણામો અહીં જોવા કેપ્ચર અને સ્કેનથી લેબ રિપોર્ટ સ્કેન કરો.';

  @override
  String get captureAndScan => 'કેપ્ચર અને સ્કેન';

  @override
  String get noScannedDocsYet => 'હજી સુધી કોઈ સ્કેન કરેલા દસ્તાવેજો નથી';

  @override
  String get scannedDocsHint =>
      'તમારી મુલાકાતો દરમિયાન સ્કેન કરેલા દસ્તાવેજો અહીં દેખાશે.';

  @override
  String get selectAtLeastOneSummary => 'ઓછામાં ઓછું એક સારાંશ પસંદ કરો';

  @override
  String get failedToDeleteSummaries =>
      'સારાંશો કાઢી શકાયા નહીં. કૃપા કરીને ફરી પ્રયાસ કરો.';

  @override
  String get noCaregiverAddedYet => 'હજી સુધી કોઈ સંભાળ રાખનાર ઉમેરાયો નથી';

  @override
  String get summaryGenerationRestarted => 'સારાંશ જનરેશન ફરી શરૂ થયું';

  @override
  String retryFailed(String error) {
    return 'પુનઃપ્રયાસ નિષ્ફળ: $error';
  }

  @override
  String get generateSummary => 'સારાંશ બનાવો';

  @override
  String get discardRecording => 'રેકોર્ડિંગ કાઢી નાખો';

  @override
  String unableToStartRecording(String error) {
    return 'રેકોર્ડિંગ શરૂ થઈ શક્યું નહીં: $error';
  }

  @override
  String get recordingCompleted => 'રેકોર્ડિંગ પૂર્ણ!';

  @override
  String unableToStopRecording(String error) {
    return 'રેકોર્ડિંગ બંધ થઈ શક્યું નહીં: $error';
  }

  @override
  String get recordingDiscarded => 'રેકોર્ડિંગ કાઢી નાખ્યું';

  @override
  String get unableToOpenPrivacyPolicy => 'ગોપનીયતા નીતિ ખોલી શકાઈ નહીં.';

  @override
  String get noRecordingAvailable => 'કોઈ રેકોર્ડિંગ ઉપલબ્ધ નથી';

  @override
  String get uploadingAudio => 'ઑડિયો અપલોડ થઈ રહ્યું છે...';

  @override
  String failedToUploadAudio(String error) {
    return 'ઑડિયો અપલોડ નિષ્ફળ: $error';
  }

  @override
  String get stopRecordingTitle => 'રેકોર્ડિંગ બંધ કરો?';

  @override
  String get stopRecordingMessage =>
      'Are you sure you want to stop recording? This action cannot be undone.';

  @override
  String get continueRecording => 'રેકોર્ડિંગ ચાલુ રાખો';

  @override
  String get stopAndDiscard => 'બંધ કરો અને કાઢી નાખો';

  @override
  String get share => 'શેર કરો';

  @override
  String get cameraNotReady => 'કેમેરા તૈયાર નથી. ફરી પ્રયાસ કરો.';

  @override
  String failedToCaptureImage(String error) {
    return 'છબી કેપ્ચર નિષ્ફળ: $error';
  }

  @override
  String get unableToStartCamera => 'કેમેરા શરૂ થઈ શક્યો નહીં. ફરી પ્રયાસ કરો.';

  @override
  String get cameraReadyHint =>
      'કેમેરા તૈયાર. દસ્તાવેજ મૂકો અને કેપ્ચર ટેપ કરો.';

  @override
  String unableToStartScanning(String error) {
    return 'સ્કેન શરૂ થઈ શક્યું નહીં: $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'છબી અપલોડ નિષ્ફળ: $error';
  }

  @override
  String get noImageToProcess => 'પ્રોસેસ કરવા છબી નથી. ફરી કેપ્ચર કરો.';

  @override
  String get documentScannedSaved => 'દસ્તાવેજ સ્કેન અને સાચવ્યો!';

  @override
  String scanProcessingFailed(String error) {
    return 'સ્કેન પ્રોસેસિંગ નિષ્ફળ: $error';
  }

  @override
  String get scanSavedToHistory => 'સ્કેન તમારા મુલાકાત ઇતિહાસમાં સાચવ્યો';

  @override
  String localNotificationSchedulingFailed(String error) {
    return 'સ્થાનિક સૂચના શેડ્યૂલ નિષ્ફળ: $error';
  }

  @override
  String reminderRescheduleFailed(String error) {
    return 'રિમાઇન્ડર પુનઃશેડ્યૂલ નિષ્ફળ: $error';
  }

  @override
  String get authenticationErrorLoginAgain => 'પ્રમાણીકરણ ભૂલ. ફરી લૉગ ઇન કરો.';
}
