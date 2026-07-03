import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_gu.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_pa.dart';
import 'app_localizations_pt.dart';
import 'app_localizations_ta.dart';

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
    Locale('bn'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('gu'),
    Locale('hi'),
    Locale('pa'),
    Locale('pt'),
    Locale('ta')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'RemiMinder'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @languageSettings.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettings;

  /// No description provided for @languageUpdated.
  ///
  /// In en, this message translates to:
  /// **'Language updated. The app will now display in {language}.'**
  String languageUpdated(String language);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get navVisits;

  /// No description provided for @navOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navOverview;

  /// No description provided for @navCareTeam.
  ///
  /// In en, this message translates to:
  /// **'Care Team'**
  String get navCareTeam;

  /// No description provided for @navProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// No description provided for @navPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get navPatients;

  /// No description provided for @goodMorning.
  ///
  /// In en, this message translates to:
  /// **'Good morning'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In en, this message translates to:
  /// **'Good afternoon'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In en, this message translates to:
  /// **'Good evening'**
  String get goodEvening;

  /// No description provided for @goodNight.
  ///
  /// In en, this message translates to:
  /// **'Good night'**
  String get goodNight;

  /// No description provided for @howAreYouFeeling.
  ///
  /// In en, this message translates to:
  /// **'How are you feeling today?'**
  String get howAreYouFeeling;

  /// No description provided for @todaysProgress.
  ///
  /// In en, this message translates to:
  /// **'Today\'s Progress'**
  String get todaysProgress;

  /// No description provided for @doneCount.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} done'**
  String doneCount(int done, int total);

  /// No description provided for @yourSchedule.
  ///
  /// In en, this message translates to:
  /// **'Your Schedule'**
  String get yourSchedule;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all →'**
  String get seeAll;

  /// No description provided for @nothingScheduledYet.
  ///
  /// In en, this message translates to:
  /// **'Nothing scheduled yet'**
  String get nothingScheduledYet;

  /// No description provided for @unableToLoadReminders.
  ///
  /// In en, this message translates to:
  /// **'Unable to load reminders'**
  String get unableToLoadReminders;

  /// No description provided for @addReminder.
  ///
  /// In en, this message translates to:
  /// **'Add Reminder'**
  String get addReminder;

  /// No description provided for @myTasks.
  ///
  /// In en, this message translates to:
  /// **'My Tasks'**
  String get myTasks;

  /// No description provided for @pendingCount.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingCount(int count);

  /// No description provided for @noTasksYet.
  ///
  /// In en, this message translates to:
  /// **'No tasks yet'**
  String get noTasksYet;

  /// No description provided for @addTask.
  ///
  /// In en, this message translates to:
  /// **'Add Task'**
  String get addTask;

  /// No description provided for @statusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get statusUpcoming;

  /// No description provided for @statusScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get statusScheduled;

  /// No description provided for @statusDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get statusDone;

  /// No description provided for @reminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get reminder;

  /// No description provided for @task.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get task;

  /// No description provided for @careTeamTitle.
  ///
  /// In en, this message translates to:
  /// **'Care Team'**
  String get careTeamTitle;

  /// No description provided for @careTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You are in control. Review your sharing permissions below.'**
  String get careTeamSubtitle;

  /// No description provided for @sectionPending.
  ///
  /// In en, this message translates to:
  /// **'PENDING'**
  String get sectionPending;

  /// No description provided for @sectionAddNew.
  ///
  /// In en, this message translates to:
  /// **'ADD NEW'**
  String get sectionAddNew;

  /// No description provided for @inviteCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Invite a caregiver'**
  String get inviteCaregiver;

  /// No description provided for @inviteCaregiverSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Share access to your health information'**
  String get inviteCaregiverSubtitle;

  /// No description provided for @invitationPending.
  ///
  /// In en, this message translates to:
  /// **'Invitation Pending'**
  String get invitationPending;

  /// No description provided for @resend.
  ///
  /// In en, this message translates to:
  /// **'Resend'**
  String get resend;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @activeCaregivers.
  ///
  /// In en, this message translates to:
  /// **'Active Caregivers'**
  String get activeCaregivers;

  /// No description provided for @noCaregiversYet.
  ///
  /// In en, this message translates to:
  /// **'No caregivers added yet'**
  String get noCaregiversYet;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @spanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get spanish;

  /// No description provided for @hindi.
  ///
  /// In en, this message translates to:
  /// **'Hindi'**
  String get hindi;

  /// No description provided for @french.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// No description provided for @portuguese.
  ///
  /// In en, this message translates to:
  /// **'Portuguese'**
  String get portuguese;

  /// No description provided for @german.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get german;

  /// No description provided for @bangla.
  ///
  /// In en, this message translates to:
  /// **'Bangla'**
  String get bangla;

  /// No description provided for @tamil.
  ///
  /// In en, this message translates to:
  /// **'Tamil'**
  String get tamil;

  /// No description provided for @gujarati.
  ///
  /// In en, this message translates to:
  /// **'Gujarati'**
  String get gujarati;

  /// No description provided for @punjabi.
  ///
  /// In en, this message translates to:
  /// **'Punjabi'**
  String get punjabi;

  /// No description provided for @accountDetails.
  ///
  /// In en, this message translates to:
  /// **'Account Details'**
  String get accountDetails;

  /// No description provided for @accountDetailsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your profile information'**
  String get accountDetailsSubtitle;

  /// No description provided for @accountSecurity.
  ///
  /// In en, this message translates to:
  /// **'Account Security'**
  String get accountSecurity;

  /// No description provided for @accountSecuritySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage password and privacy'**
  String get accountSecuritySubtitle;

  /// No description provided for @notificationsLabel.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsLabel;

  /// No description provided for @mobileLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile'**
  String get mobileLabel;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @upgrade.
  ///
  /// In en, this message translates to:
  /// **'Upgrade'**
  String get upgrade;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign Out'**
  String get signOut;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete your account and all your data. This cannot be undone. Are you sure?'**
  String get deleteAccountMessage;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @searchSummariesHint.
  ///
  /// In en, this message translates to:
  /// **'Search summaries...'**
  String get searchSummariesHint;

  /// No description provided for @tabSummaries.
  ///
  /// In en, this message translates to:
  /// **'SUMMARIES'**
  String get tabSummaries;

  /// No description provided for @tabLabResults.
  ///
  /// In en, this message translates to:
  /// **'LAB RESULTS'**
  String get tabLabResults;

  /// No description provided for @tabScannedDocs.
  ///
  /// In en, this message translates to:
  /// **'SCANNED DOCS'**
  String get tabScannedDocs;

  /// No description provided for @noSummariesYet.
  ///
  /// In en, this message translates to:
  /// **'No summaries yet'**
  String get noSummariesYet;

  /// No description provided for @summariesWillAppearHere.
  ///
  /// In en, this message translates to:
  /// **'Your visit summaries will appear here'**
  String get summariesWillAppearHere;

  /// No description provided for @failedToLoadSummaries.
  ///
  /// In en, this message translates to:
  /// **'Failed to load summaries'**
  String get failedToLoadSummaries;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @doctorVisit.
  ///
  /// In en, this message translates to:
  /// **'Doctor Visit'**
  String get doctorVisit;

  /// No description provided for @timeToday.
  ///
  /// In en, this message translates to:
  /// **'Today, {time}'**
  String timeToday(String time);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday, {time}'**
  String timeYesterday(String time);

  /// No description provided for @summaryProcessingHint.
  ///
  /// In en, this message translates to:
  /// **'Pull down to refresh. This usually takes 30–60 seconds.'**
  String get summaryProcessingHint;

  /// No description provided for @summaryCouldNotGenerate.
  ///
  /// In en, this message translates to:
  /// **'Summary could not be generated'**
  String get summaryCouldNotGenerate;

  /// No description provided for @retrySummary.
  ///
  /// In en, this message translates to:
  /// **'Retry summary'**
  String get retrySummary;

  /// No description provided for @stuckRetrySummary.
  ///
  /// In en, this message translates to:
  /// **'Stuck? Retry summary'**
  String get stuckRetrySummary;

  /// No description provided for @scannedDocument.
  ///
  /// In en, this message translates to:
  /// **'Scanned document'**
  String get scannedDocument;

  /// No description provided for @scannedOn.
  ///
  /// In en, this message translates to:
  /// **'Scanned {date}'**
  String scannedOn(String date);

  /// No description provided for @visitDetails.
  ///
  /// In en, this message translates to:
  /// **'Visit Details'**
  String get visitDetails;

  /// No description provided for @healthVisitSummary.
  ///
  /// In en, this message translates to:
  /// **'Health Visit Summary'**
  String get healthVisitSummary;

  /// No description provided for @refreshSummaryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Refresh summary'**
  String get refreshSummaryTooltip;

  /// No description provided for @preparingVisitSummary.
  ///
  /// In en, this message translates to:
  /// **'Preparing visit summary...'**
  String get preparingVisitSummary;

  /// No description provided for @preparingVisitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This may take a minute.'**
  String get preparingVisitSubtitle;

  /// No description provided for @unableToLoadVisitSummary.
  ///
  /// In en, this message translates to:
  /// **'Unable to load visit summary'**
  String get unableToLoadVisitSummary;

  /// No description provided for @visitSummaryUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Visit summary is unavailable'**
  String get visitSummaryUnavailable;

  /// No description provided for @visitSummary.
  ///
  /// In en, this message translates to:
  /// **'Visit Summary'**
  String get visitSummary;

  /// No description provided for @visitProcessingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your visit is being processed'**
  String get visitProcessingTitle;

  /// No description provided for @visitProcessingBody.
  ///
  /// In en, this message translates to:
  /// **'This may take 30–60 seconds.\nYou can continue using the app. Open Overview to see progress.'**
  String get visitProcessingBody;

  /// No description provided for @viewOverviewAction.
  ///
  /// In en, this message translates to:
  /// **'View Overview'**
  String get viewOverviewAction;

  /// No description provided for @goToHome.
  ///
  /// In en, this message translates to:
  /// **'Go to Home'**
  String get goToHome;

  /// No description provided for @medication.
  ///
  /// In en, this message translates to:
  /// **'Medication'**
  String get medication;

  /// No description provided for @nextToDo.
  ///
  /// In en, this message translates to:
  /// **'Next To Do'**
  String get nextToDo;

  /// No description provided for @conditionsDiscussed.
  ///
  /// In en, this message translates to:
  /// **'Conditions discussed'**
  String get conditionsDiscussed;

  /// No description provided for @followUp.
  ///
  /// In en, this message translates to:
  /// **'Follow up'**
  String get followUp;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @notSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// No description provided for @appleIdHidden.
  ///
  /// In en, this message translates to:
  /// **'Apple ID (hidden)'**
  String get appleIdHidden;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @patientRole.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get patientRole;

  /// No description provided for @caregiverRole.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get caregiverRole;

  /// No description provided for @phoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @planLabel.
  ///
  /// In en, this message translates to:
  /// **'Plan'**
  String get planLabel;

  /// No description provided for @planFree.
  ///
  /// In en, this message translates to:
  /// **'Free'**
  String get planFree;

  /// No description provided for @planPremium.
  ///
  /// In en, this message translates to:
  /// **'Premium'**
  String get planPremium;

  /// No description provided for @usageLabel.
  ///
  /// In en, this message translates to:
  /// **'Usage'**
  String get usageLabel;

  /// No description provided for @freePlanUsage.
  ///
  /// In en, this message translates to:
  /// **'Free plan — {used} / {limit} summaries used'**
  String freePlanUsage(int used, int limit);

  /// No description provided for @unlimited.
  ///
  /// In en, this message translates to:
  /// **'Unlimited'**
  String get unlimited;

  /// No description provided for @editPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Edit Phone Number'**
  String get editPhoneNumber;

  /// No description provided for @phoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @phoneMinLength.
  ///
  /// In en, this message translates to:
  /// **'Phone number must be at least 8 characters long'**
  String get phoneMinLength;

  /// No description provided for @phoneUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Phone number updated successfully'**
  String get phoneUpdatedSuccess;

  /// No description provided for @phoneUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update phone number: {error}'**
  String phoneUpdateFailed(String error);

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @changePasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Update your account password for security'**
  String get changePasswordSubtitle;

  /// No description provided for @privacySettings.
  ///
  /// In en, this message translates to:
  /// **'Privacy Settings'**
  String get privacySettings;

  /// No description provided for @privacySettingsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manage your data sharing preferences'**
  String get privacySettingsSubtitle;

  /// No description provided for @managePrivacy.
  ///
  /// In en, this message translates to:
  /// **'Manage Privacy'**
  String get managePrivacy;

  /// No description provided for @changePasswordProviderMessage.
  ///
  /// In en, this message translates to:
  /// **'You signed in using {provider}. Please change your password in your {provider} account.'**
  String changePasswordProviderMessage(String provider);

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @changePasswordIntro.
  ///
  /// In en, this message translates to:
  /// **'Update your password to keep your account secure.'**
  String get changePasswordIntro;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current Password'**
  String get currentPassword;

  /// No description provided for @currentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your current password'**
  String get currentPasswordHint;

  /// No description provided for @enterCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter your current password'**
  String get enterCurrentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your new password'**
  String get newPasswordHint;

  /// No description provided for @enterNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get enterNewPassword;

  /// No description provided for @passwordMinLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Re-enter your new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @confirmNewPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get confirmNewPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @passwordUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully'**
  String get passwordUpdatedSuccess;

  /// No description provided for @passwordUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update password'**
  String get passwordUpdateFailed;

  /// No description provided for @wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get wrongPassword;

  /// No description provided for @weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get weakPassword;

  /// No description provided for @requiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'Please log in again and try'**
  String get requiresRecentLogin;

  /// No description provided for @checkInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection'**
  String get checkInternetConnection;

  /// No description provided for @dataSharing.
  ///
  /// In en, this message translates to:
  /// **'Data Sharing'**
  String get dataSharing;

  /// No description provided for @allowCaregiverSummaries.
  ///
  /// In en, this message translates to:
  /// **'Allow caregiver to view summaries'**
  String get allowCaregiverSummaries;

  /// No description provided for @allowCaregiverMedications.
  ///
  /// In en, this message translates to:
  /// **'Allow caregiver to view medications'**
  String get allowCaregiverMedications;

  /// No description provided for @allowCaregiverReminders.
  ///
  /// In en, this message translates to:
  /// **'Allow caregiver to view reminders'**
  String get allowCaregiverReminders;

  /// No description provided for @allowAiImprovement.
  ///
  /// In en, this message translates to:
  /// **'Allow AI to use my data to improve the product'**
  String get allowAiImprovement;

  /// No description provided for @communicationAndConsent.
  ///
  /// In en, this message translates to:
  /// **'Communication & Consent'**
  String get communicationAndConsent;

  /// No description provided for @allowEmailNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow email notifications'**
  String get allowEmailNotifications;

  /// No description provided for @allowSmsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow SMS notifications'**
  String get allowSmsNotifications;

  /// No description provided for @allowPushNotifications.
  ///
  /// In en, this message translates to:
  /// **'Allow push notifications'**
  String get allowPushNotifications;

  /// No description provided for @dataControl.
  ///
  /// In en, this message translates to:
  /// **'Data Control'**
  String get dataControl;

  /// No description provided for @exportMyData.
  ///
  /// In en, this message translates to:
  /// **'Export my data'**
  String get exportMyData;

  /// No description provided for @deleteAllMedicalRecords.
  ///
  /// In en, this message translates to:
  /// **'Delete all my medical records'**
  String get deleteAllMedicalRecords;

  /// No description provided for @deleteMedicalRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Medical Records'**
  String get deleteMedicalRecordsTitle;

  /// No description provided for @deleteMedicalRecordsMessage.
  ///
  /// In en, this message translates to:
  /// **'This will permanently delete all your medical records. This action cannot be undone.'**
  String get deleteMedicalRecordsMessage;

  /// No description provided for @deleteRecords.
  ///
  /// In en, this message translates to:
  /// **'Delete Records'**
  String get deleteRecords;

  /// No description provided for @deleteMyAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteMyAccount;

  /// No description provided for @legal.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legal;

  /// No description provided for @viewPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'View Privacy Policy'**
  String get viewPrivacyPolicy;

  /// No description provided for @viewTermsOfService.
  ///
  /// In en, this message translates to:
  /// **'View Terms of Service'**
  String get viewTermsOfService;

  /// No description provided for @termsOfService.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// No description provided for @termsOfServiceBody.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service for RemiMinder\n\n1. Acceptance of Terms\nBy using RemiMinder, you agree to these terms.\n\n2. Use of Service\nRemiMinder is designed to help manage healthcare and medication reminders.\n\n3. Privacy\nYour privacy is important to us. All health data is handled securely.\n\nFor the complete Terms of Service, please visit our website.'**
  String get termsOfServiceBody;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @privacyPolicyBody.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy for RemiMinder\n\n1. Information We Collect\nWe collect information you provide and usage data to improve our service.\n\n2. How We Use Information\nInformation is used to provide healthcare management services.\n\n3. Information Sharing\nWe do not sell your personal information.\n\nFor the complete Privacy Policy, please visit our website.'**
  String get privacyPolicyBody;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @featureComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{feature} coming soon'**
  String featureComingSoon(String feature);

  /// No description provided for @caregiverSharingEnabled.
  ///
  /// In en, this message translates to:
  /// **'Caregiver sharing enabled'**
  String get caregiverSharingEnabled;

  /// No description provided for @caregiverSharingDisabled.
  ///
  /// In en, this message translates to:
  /// **'Caregiver sharing disabled'**
  String get caregiverSharingDisabled;

  /// No description provided for @dataExport.
  ///
  /// In en, this message translates to:
  /// **'Data export'**
  String get dataExport;

  /// No description provided for @remindersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersTitle;

  /// No description provided for @tabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tabAll;

  /// No description provided for @tabToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get tabToday;

  /// No description provided for @tabPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get tabPending;

  /// No description provided for @tabCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tabCompleted;

  /// No description provided for @searchRemindersHint.
  ///
  /// In en, this message translates to:
  /// **'Search reminders...'**
  String get searchRemindersHint;

  /// No description provided for @failedToLoadRemindersRetry.
  ///
  /// In en, this message translates to:
  /// **'Failed to load reminders. Retry'**
  String get failedToLoadRemindersRetry;

  /// No description provided for @deleteReminderTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Reminder'**
  String get deleteReminderTitle;

  /// No description provided for @deleteReminderMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this reminder?'**
  String get deleteReminderMessage;

  /// No description provided for @markDone.
  ///
  /// In en, this message translates to:
  /// **'Mark Done'**
  String get markDone;

  /// No description provided for @snooze.
  ///
  /// In en, this message translates to:
  /// **'Snooze'**
  String get snooze;

  /// No description provided for @snoozedUntil.
  ///
  /// In en, this message translates to:
  /// **'Snoozed until {time}'**
  String snoozedUntil(String time);

  /// No description provided for @statusDueNow.
  ///
  /// In en, this message translates to:
  /// **'Due Now'**
  String get statusDueNow;

  /// No description provided for @statusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get statusActive;

  /// No description provided for @statusMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get statusMissed;

  /// No description provided for @statusSnoozed.
  ///
  /// In en, this message translates to:
  /// **'Snoozed'**
  String get statusSnoozed;

  /// No description provided for @statusSkipped.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get statusSkipped;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get statusPending;

  /// No description provided for @noRemindersFound.
  ///
  /// In en, this message translates to:
  /// **'No reminders found'**
  String get noRemindersFound;

  /// No description provided for @noRemindersMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No reminders match your search'**
  String get noRemindersMatchSearch;

  /// No description provided for @createFirstReminder.
  ///
  /// In en, this message translates to:
  /// **'Create your first reminder to get started'**
  String get createFirstReminder;

  /// No description provided for @tryAdjustSearch.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your search terms'**
  String get tryAdjustSearch;

  /// No description provided for @createReminder.
  ///
  /// In en, this message translates to:
  /// **'Create Reminder'**
  String get createReminder;

  /// No description provided for @newReminder.
  ///
  /// In en, this message translates to:
  /// **'New Reminder'**
  String get newReminder;

  /// No description provided for @editReminder.
  ///
  /// In en, this message translates to:
  /// **'Edit Reminder'**
  String get editReminder;

  /// No description provided for @reminderTitleLabel.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get reminderTitleLabel;

  /// No description provided for @dosageOptional.
  ///
  /// In en, this message translates to:
  /// **'Dosage (optional)'**
  String get dosageOptional;

  /// No description provided for @dosageHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 10 mg once daily'**
  String get dosageHint;

  /// No description provided for @reminderTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get reminderTypeLabel;

  /// No description provided for @appointment.
  ///
  /// In en, this message translates to:
  /// **'Appointment'**
  String get appointment;

  /// No description provided for @repeatLabel.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get repeatLabel;

  /// No description provided for @once.
  ///
  /// In en, this message translates to:
  /// **'Once'**
  String get once;

  /// No description provided for @daily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get daily;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @pleaseEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Please enter a title'**
  String get pleaseEnterTitle;

  /// No description provided for @reminderCreated.
  ///
  /// In en, this message translates to:
  /// **'Reminder created!'**
  String get reminderCreated;

  /// No description provided for @failedToCreateReminder.
  ///
  /// In en, this message translates to:
  /// **'Failed to create reminder: {error}'**
  String failedToCreateReminder(String error);

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// No description provided for @cannotRescheduleMissingType.
  ///
  /// In en, this message translates to:
  /// **'Cannot reschedule: reminder type is missing'**
  String get cannotRescheduleMissingType;

  /// No description provided for @reminderUpdated.
  ///
  /// In en, this message translates to:
  /// **'Reminder updated!'**
  String get reminderUpdated;

  /// No description provided for @failedToUpdateReminder.
  ///
  /// In en, this message translates to:
  /// **'Failed to update: {error}'**
  String failedToUpdateReminder(String error);

  /// No description provided for @reminderMarkedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Reminder marked as completed!'**
  String get reminderMarkedCompleted;

  /// No description provided for @reminderSnoozed30.
  ///
  /// In en, this message translates to:
  /// **'Reminder snoozed for 30 minutes'**
  String get reminderSnoozed30;

  /// No description provided for @timeInHours.
  ///
  /// In en, this message translates to:
  /// **'In {hours} hours ({time})'**
  String timeInHours(int hours, String time);

  /// No description provided for @timeInMinutes.
  ///
  /// In en, this message translates to:
  /// **'In {minutes} minutes ({time})'**
  String timeInMinutes(int minutes, String time);

  /// No description provided for @timeNow.
  ///
  /// In en, this message translates to:
  /// **'Now'**
  String get timeNow;

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours} hours ago'**
  String timeHoursAgo(int hours);

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes} minutes ago'**
  String timeMinutesAgo(int minutes);

  /// No description provided for @timeInDays.
  ///
  /// In en, this message translates to:
  /// **'in {days} days'**
  String timeInDays(int days);

  /// No description provided for @timeInHoursShort.
  ///
  /// In en, this message translates to:
  /// **'in {hours} hours'**
  String timeInHoursShort(int hours);

  /// No description provided for @timeInMinutesShort.
  ///
  /// In en, this message translates to:
  /// **'in {minutes} minutes'**
  String timeInMinutesShort(int minutes);

  /// No description provided for @selectTime.
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// No description provided for @presetMorning.
  ///
  /// In en, this message translates to:
  /// **'Morning (8:00 AM)'**
  String get presetMorning;

  /// No description provided for @presetNoon.
  ///
  /// In en, this message translates to:
  /// **'Noon (12:00 PM)'**
  String get presetNoon;

  /// No description provided for @presetEvening.
  ///
  /// In en, this message translates to:
  /// **'Evening (6:00 PM)'**
  String get presetEvening;

  /// No description provided for @presetNight.
  ///
  /// In en, this message translates to:
  /// **'Night (8:00 PM)'**
  String get presetNight;

  /// No description provided for @hourLabel.
  ///
  /// In en, this message translates to:
  /// **'Hour'**
  String get hourLabel;

  /// No description provided for @minuteLabel.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get minuteLabel;

  /// No description provided for @amPmLabel.
  ///
  /// In en, this message translates to:
  /// **'AM / PM'**
  String get amPmLabel;

  /// No description provided for @amLabel.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get amLabel;

  /// No description provided for @pmLabel.
  ///
  /// In en, this message translates to:
  /// **'PM'**
  String get pmLabel;

  /// No description provided for @selectedTimeLabel.
  ///
  /// In en, this message translates to:
  /// **'Selected time: {time}'**
  String selectedTimeLabel(String time);

  /// No description provided for @setForTime.
  ///
  /// In en, this message translates to:
  /// **'Set for {time} ✓'**
  String setForTime(String time);

  /// No description provided for @medicationAdherence.
  ///
  /// In en, this message translates to:
  /// **'Medication Adherence'**
  String get medicationAdherence;

  /// No description provided for @thisWeek.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get thisWeek;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get thisMonth;

  /// No description provided for @overall.
  ///
  /// In en, this message translates to:
  /// **'Overall'**
  String get overall;

  /// No description provided for @dosesCount.
  ///
  /// In en, this message translates to:
  /// **'{done}/{total} doses'**
  String dosesCount(int done, int total);

  /// No description provided for @byMedication.
  ///
  /// In en, this message translates to:
  /// **'By Medication'**
  String get byMedication;

  /// No description provided for @noPastRemindersAnalyze.
  ///
  /// In en, this message translates to:
  /// **'No past reminders to analyze'**
  String get noPastRemindersAnalyze;

  /// No description provided for @adherenceTips.
  ///
  /// In en, this message translates to:
  /// **'Adherence Tips'**
  String get adherenceTips;

  /// No description provided for @adherenceTipsBody.
  ///
  /// In en, this message translates to:
  /// **'• Set phone reminders for medication times\n• Keep medications in a visible location\n• Use a pill organizer for daily doses\n• Track your progress to stay motivated'**
  String get adherenceTipsBody;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed'**
  String get actionFailed;

  /// No description provided for @snoozeAlreadyUsed.
  ///
  /// In en, this message translates to:
  /// **'This reminder was already snoozed once'**
  String get snoozeAlreadyUsed;

  /// No description provided for @reminderDeleted.
  ///
  /// In en, this message translates to:
  /// **'Reminder deleted'**
  String get reminderDeleted;

  /// No description provided for @deleteFailed.
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// No description provided for @sectionRecentAlerts.
  ///
  /// In en, this message translates to:
  /// **'Recent Alerts'**
  String get sectionRecentAlerts;

  /// No description provided for @viewAll.
  ///
  /// In en, this message translates to:
  /// **'View All'**
  String get viewAll;

  /// No description provided for @sectionInvitations.
  ///
  /// In en, this message translates to:
  /// **'Invitations'**
  String get sectionInvitations;

  /// No description provided for @summaryPatients.
  ///
  /// In en, this message translates to:
  /// **'Patients'**
  String get summaryPatients;

  /// No description provided for @summaryAlerts.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get summaryAlerts;

  /// No description provided for @summaryPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get summaryPending;

  /// No description provided for @noAlertsAtThisTime.
  ///
  /// In en, this message translates to:
  /// **'No alerts at this time'**
  String get noAlertsAtThisTime;

  /// No description provided for @noPendingInvitations.
  ///
  /// In en, this message translates to:
  /// **'No pending invitations'**
  String get noPendingInvitations;

  /// No description provided for @pendingInvitationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending Invitations'**
  String get pendingInvitationsTitle;

  /// No description provided for @invitationsWaiting.
  ///
  /// In en, this message translates to:
  /// **'{count} invitation(s) waiting'**
  String invitationsWaiting(int count);

  /// No description provided for @reviewAcceptInvitations.
  ///
  /// In en, this message translates to:
  /// **'Review and accept caregiver invitations.'**
  String get reviewAcceptInvitations;

  /// No description provided for @viewInvitations.
  ///
  /// In en, this message translates to:
  /// **'View Invitations'**
  String get viewInvitations;

  /// No description provided for @defaultPatient.
  ///
  /// In en, this message translates to:
  /// **'Patient'**
  String get defaultPatient;

  /// No description provided for @defaultCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get defaultCaregiver;

  /// No description provided for @caregiverPatientTime.
  ///
  /// In en, this message translates to:
  /// **'Patient: {name} • {time}'**
  String caregiverPatientTime(String name, String time);

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days} days ago'**
  String timeDaysAgo(int days);

  /// No description provided for @alertsTitle.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsTitle;

  /// No description provided for @filterUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get filterUnread;

  /// No description provided for @filterRead.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get filterRead;

  /// No description provided for @filterHighPriority.
  ///
  /// In en, this message translates to:
  /// **'High Priority'**
  String get filterHighPriority;

  /// No description provided for @filterActionRequired.
  ///
  /// In en, this message translates to:
  /// **'Action Required'**
  String get filterActionRequired;

  /// No description provided for @alertSingular.
  ///
  /// In en, this message translates to:
  /// **'Alert'**
  String get alertSingular;

  /// No description provided for @alertsPlural.
  ///
  /// In en, this message translates to:
  /// **'Alerts'**
  String get alertsPlural;

  /// No description provided for @clearFilter.
  ///
  /// In en, this message translates to:
  /// **'Clear Filter'**
  String get clearFilter;

  /// No description provided for @noAlertsMatchFilter.
  ///
  /// In en, this message translates to:
  /// **'No alerts match this filter'**
  String get noAlertsMatchFilter;

  /// No description provided for @allPatientActivitiesSmooth.
  ///
  /// In en, this message translates to:
  /// **'All patient activities are running smoothly'**
  String get allPatientActivitiesSmooth;

  /// No description provided for @tryAdjustingFilter.
  ///
  /// In en, this message translates to:
  /// **'Try adjusting your filter to see more alerts'**
  String get tryAdjustingFilter;

  /// No description provided for @viewAllAlerts.
  ///
  /// In en, this message translates to:
  /// **'View All Alerts'**
  String get viewAllAlerts;

  /// No description provided for @alertMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'Alert marked as read'**
  String get alertMarkedAsRead;

  /// No description provided for @alertsMarkedAsRead.
  ///
  /// In en, this message translates to:
  /// **'Marked {count} alerts as read'**
  String alertsMarkedAsRead(int count);

  /// No description provided for @allAlertsAlreadyRead.
  ///
  /// In en, this message translates to:
  /// **'All alerts are already read'**
  String get allAlertsAlreadyRead;

  /// No description provided for @myPatientsTitle.
  ///
  /// In en, this message translates to:
  /// **'My Patients'**
  String get myPatientsTitle;

  /// No description provided for @patientsConnectedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Patients connected to you'**
  String get patientsConnectedSubtitle;

  /// No description provided for @myPatientsSection.
  ///
  /// In en, this message translates to:
  /// **'My patients'**
  String get myPatientsSection;

  /// No description provided for @connectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} connected'**
  String connectedCount(int count);

  /// No description provided for @searchPatientsHint.
  ///
  /// In en, this message translates to:
  /// **'Search patients...'**
  String get searchPatientsHint;

  /// No description provided for @noPatientsMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No patients match your search.'**
  String get noPatientsMatchSearch;

  /// No description provided for @noPatientsConnectedYet.
  ///
  /// In en, this message translates to:
  /// **'No patients connected yet'**
  String get noPatientsConnectedYet;

  /// No description provided for @acceptInvitationToSeePatient.
  ///
  /// In en, this message translates to:
  /// **'Accept an invitation to see a patient here.'**
  String get acceptInvitationToSeePatient;

  /// No description provided for @badgeNew.
  ///
  /// In en, this message translates to:
  /// **'New'**
  String get badgeNew;

  /// No description provided for @joinedOn.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String joinedOn(String date);

  /// No description provided for @neverSynced.
  ///
  /// In en, this message translates to:
  /// **'Not loaded yet'**
  String get neverSynced;

  /// No description provided for @privacyDataRequestMessage.
  ///
  /// In en, this message translates to:
  /// **'Contact privacy@remiminder.ai to export or delete your data.'**
  String get privacyDataRequestMessage;

  /// No description provided for @syncMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{minutes}m ago'**
  String syncMinutesAgo(int minutes);

  /// No description provided for @syncHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{hours}h ago'**
  String syncHoursAgo(int hours);

  /// No description provided for @syncDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{days}d ago'**
  String syncDaysAgo(int days);

  /// No description provided for @primaryCondition.
  ///
  /// In en, this message translates to:
  /// **'Primary condition'**
  String get primaryCondition;

  /// No description provided for @lastSynced.
  ///
  /// In en, this message translates to:
  /// **'Last synced'**
  String get lastSynced;

  /// No description provided for @allergiesLabel.
  ///
  /// In en, this message translates to:
  /// **'Allergies'**
  String get allergiesLabel;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @currentMedications.
  ///
  /// In en, this message translates to:
  /// **'Current medications'**
  String get currentMedications;

  /// No description provided for @viewCarePlan.
  ///
  /// In en, this message translates to:
  /// **'View care plan'**
  String get viewCarePlan;

  /// No description provided for @remindersButton.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get remindersButton;

  /// No description provided for @caregiverCareTeamSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Invite family or medical staff'**
  String get caregiverCareTeamSubtitle;

  /// No description provided for @invitationsReceived.
  ///
  /// In en, this message translates to:
  /// **'Invitations received'**
  String get invitationsReceived;

  /// No description provided for @pendingBadge.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingBadge(int count);

  /// No description provided for @patientOverviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Patient Overview'**
  String get patientOverviewTitle;

  /// No description provided for @patientOverviewTabVisits.
  ///
  /// In en, this message translates to:
  /// **'Visits'**
  String get patientOverviewTabVisits;

  /// No description provided for @patientOverviewTabReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get patientOverviewTabReminders;

  /// No description provided for @patientOverviewNoVisits.
  ///
  /// In en, this message translates to:
  /// **'No visits available'**
  String get patientOverviewNoVisits;

  /// No description provided for @patientOverviewNoReminders.
  ///
  /// In en, this message translates to:
  /// **'No reminders available'**
  String get patientOverviewNoReminders;

  /// No description provided for @patientOverviewMissingPatientId.
  ///
  /// In en, this message translates to:
  /// **'Missing patient information'**
  String get patientOverviewMissingPatientId;

  /// No description provided for @patientOverviewLastVisit.
  ///
  /// In en, this message translates to:
  /// **'Last visit'**
  String get patientOverviewLastVisit;

  /// No description provided for @patientOverviewCareTeam.
  ///
  /// In en, this message translates to:
  /// **'Care team member'**
  String get patientOverviewCareTeam;

  /// No description provided for @patientOverviewScheduledReminder.
  ///
  /// In en, this message translates to:
  /// **'Scheduled reminder'**
  String get patientOverviewScheduledReminder;

  /// No description provided for @patientOverviewNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get patientOverviewNever;

  /// No description provided for @patientOverviewYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get patientOverviewYesterday;

  /// No description provided for @statusViewed.
  ///
  /// In en, this message translates to:
  /// **'Viewed'**
  String get statusViewed;

  /// No description provided for @statusExpired.
  ///
  /// In en, this message translates to:
  /// **'Expired'**
  String get statusExpired;

  /// No description provided for @statusJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get statusJoined;

  /// No description provided for @noInvitationsToShow.
  ///
  /// In en, this message translates to:
  /// **'No invitations to show'**
  String get noInvitationsToShow;

  /// No description provided for @invitedByLabel.
  ///
  /// In en, this message translates to:
  /// **'Invited by: {name}'**
  String invitedByLabel(String name);

  /// No description provided for @acceptInvitation.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptInvitation;

  /// No description provided for @declineInvitation.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineInvitation;

  /// No description provided for @invitationDeclined.
  ///
  /// In en, this message translates to:
  /// **'Invitation declined'**
  String get invitationDeclined;

  /// No description provided for @joinedCareTeamSnackbar.
  ///
  /// In en, this message translates to:
  /// **'Joined {patientName}\'s care team as {role}'**
  String joinedCareTeamSnackbar(String patientName, String role);

  /// No description provided for @manageAccess.
  ///
  /// In en, this message translates to:
  /// **'Manage Access'**
  String get manageAccess;

  /// No description provided for @manageAccessDescription.
  ///
  /// In en, this message translates to:
  /// **'Update caregiver permission or remove access.'**
  String get manageAccessDescription;

  /// No description provided for @manage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get manage;

  /// No description provided for @accessUpdatedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Access updated successfully'**
  String get accessUpdatedSuccess;

  /// No description provided for @accessUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to update access. Please try again.'**
  String get accessUpdateFailed;

  /// No description provided for @removeCaregiverTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove caregiver?'**
  String get removeCaregiverTitle;

  /// No description provided for @removeCaregiverMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove this caregiver? They will lose access immediately.'**
  String get removeCaregiverMessage;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @updatingAccess.
  ///
  /// In en, this message translates to:
  /// **'Updating access...'**
  String get updatingAccess;

  /// No description provided for @removingCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Removing caregiver...'**
  String get removingCaregiver;

  /// No description provided for @removeCaregiverFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to remove caregiver. Please try again.'**
  String get removeCaregiverFailed;

  /// No description provided for @viewAccess.
  ///
  /// In en, this message translates to:
  /// **'View Access'**
  String get viewAccess;

  /// No description provided for @fullAccess.
  ///
  /// In en, this message translates to:
  /// **'Full Access'**
  String get fullAccess;

  /// No description provided for @viewOnly.
  ///
  /// In en, this message translates to:
  /// **'View Only'**
  String get viewOnly;

  /// No description provided for @resendingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Resending invitation...'**
  String get resendingInvitation;

  /// No description provided for @invitationResent.
  ///
  /// In en, this message translates to:
  /// **'Invitation resent'**
  String get invitationResent;

  /// No description provided for @failedToResendInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to resend invitation'**
  String get failedToResendInvitation;

  /// No description provided for @cancelingInvitation.
  ///
  /// In en, this message translates to:
  /// **'Canceling invitation...'**
  String get cancelingInvitation;

  /// No description provided for @invitationCanceled.
  ///
  /// In en, this message translates to:
  /// **'Invitation canceled'**
  String get invitationCanceled;

  /// No description provided for @failedToCancelInvitation.
  ///
  /// In en, this message translates to:
  /// **'Failed to cancel invitation'**
  String get failedToCancelInvitation;

  /// No description provided for @relationshipSon.
  ///
  /// In en, this message translates to:
  /// **'Son'**
  String get relationshipSon;

  /// No description provided for @relationshipDaughter.
  ///
  /// In en, this message translates to:
  /// **'Daughter'**
  String get relationshipDaughter;

  /// No description provided for @relationshipFriend.
  ///
  /// In en, this message translates to:
  /// **'Friend'**
  String get relationshipFriend;

  /// No description provided for @relationshipSpousePartner.
  ///
  /// In en, this message translates to:
  /// **'Spouse/Partner'**
  String get relationshipSpousePartner;

  /// No description provided for @relationshipParent.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get relationshipParent;

  /// No description provided for @relationshipChild.
  ///
  /// In en, this message translates to:
  /// **'Child'**
  String get relationshipChild;

  /// No description provided for @relationshipFamilyMember.
  ///
  /// In en, this message translates to:
  /// **'Family Member'**
  String get relationshipFamilyMember;

  /// No description provided for @relationshipHealthcareProfessional.
  ///
  /// In en, this message translates to:
  /// **'Healthcare Professional'**
  String get relationshipHealthcareProfessional;

  /// No description provided for @relationshipCaregiver.
  ///
  /// In en, this message translates to:
  /// **'Caregiver'**
  String get relationshipCaregiver;

  /// No description provided for @relationshipSister.
  ///
  /// In en, this message translates to:
  /// **'Sister'**
  String get relationshipSister;

  /// No description provided for @relationshipBrother.
  ///
  /// In en, this message translates to:
  /// **'Brother'**
  String get relationshipBrother;

  /// No description provided for @relationshipOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get relationshipOther;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
        'bn',
        'de',
        'en',
        'es',
        'fr',
        'gu',
        'hi',
        'pa',
        'pt',
        'ta'
      ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'gu':
      return AppLocalizationsGu();
    case 'hi':
      return AppLocalizationsHi();
    case 'pa':
      return AppLocalizationsPa();
    case 'pt':
      return AppLocalizationsPt();
    case 'ta':
      return AppLocalizationsTa();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
