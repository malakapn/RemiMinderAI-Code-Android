// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RemiMinder';

  @override
  String get login => 'Login';

  @override
  String get logout => 'Logout';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get languageSettings => 'Language Settings';

  @override
  String languagesAvailableCount(int count) {
    return '$count languages';
  }

  @override
  String get scrollForMoreLanguages => 'Scroll down to see all languages';

  @override
  String languageUpdated(String language) {
    return 'Language updated. The app will now display in $language.';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navVisits => 'Visits';

  @override
  String get navOverview => 'Overview';

  @override
  String get navCareTeam => 'Care Team';

  @override
  String get navProfile => 'Profile';

  @override
  String get navPatients => 'Patients';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get goodNight => 'Good night';

  @override
  String get howAreYouFeeling => 'How are you feeling today?';

  @override
  String get todaysProgress => 'Today\'s Progress';

  @override
  String doneCount(int done, int total) {
    return '$done/$total done';
  }

  @override
  String get yourSchedule => 'Your Schedule';

  @override
  String get seeAll => 'See all →';

  @override
  String get nothingScheduledYet => 'Nothing scheduled yet';

  @override
  String get unableToLoadReminders => 'Unable to load reminders';

  @override
  String get addReminder => 'Add Reminder';

  @override
  String get myTasks => 'My Tasks';

  @override
  String pendingCount(int count) {
    return '$count pending';
  }

  @override
  String get noTasksYet => 'No tasks yet';

  @override
  String get addTask => 'Add Task';

  @override
  String get statusUpcoming => 'Upcoming';

  @override
  String get statusScheduled => 'Scheduled';

  @override
  String get statusDone => 'Done';

  @override
  String get reminder => 'Reminder';

  @override
  String get task => 'Task';

  @override
  String get careTeamTitle => 'Care Team';

  @override
  String get careTeamSubtitle =>
      'You are in control. Review your sharing permissions below.';

  @override
  String get sectionPending => 'PENDING';

  @override
  String get sectionAddNew => 'ADD NEW';

  @override
  String get inviteCaregiver => 'Invite a caregiver';

  @override
  String get inviteCaregiverSubtitle =>
      'Share access to your health information';

  @override
  String get invitationPending => 'Invitation Pending';

  @override
  String get resend => 'Resend';

  @override
  String get cancel => 'Cancel';

  @override
  String get activeCaregivers => 'Active Caregivers';

  @override
  String get noCaregiversYet => 'No caregivers added yet';

  @override
  String get english => 'English';

  @override
  String get spanish => 'Spanish';

  @override
  String get hindi => 'Hindi';

  @override
  String get french => 'French';

  @override
  String get portuguese => 'Portuguese';

  @override
  String get german => 'German';

  @override
  String get bangla => 'Bangla';

  @override
  String get tamil => 'Tamil';

  @override
  String get gujarati => 'Gujarati';

  @override
  String get punjabi => 'Punjabi';

  @override
  String get accountDetails => 'Account Details';

  @override
  String get accountDetailsSubtitle => 'View your profile information';

  @override
  String get accountSecurity => 'Account Security';

  @override
  String get accountSecuritySubtitle => 'Manage password and privacy';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get mobileLabel => 'Mobile';

  @override
  String get emailLabel => 'Email';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get signOut => 'Sign Out';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountMessage =>
      'This will permanently delete your account and all your data. This cannot be undone. Are you sure?';

  @override
  String get delete => 'Delete';

  @override
  String get searchSummariesHint => 'Search summaries...';

  @override
  String get tabSummaries => 'SUMMARIES';

  @override
  String get tabLabResults => 'LAB RESULTS';

  @override
  String get tabScannedDocs => 'SCANNED DOCS';

  @override
  String get noSummariesYet => 'No summaries yet';

  @override
  String get summariesWillAppearHere => 'Your visit summaries will appear here';

  @override
  String get failedToLoadSummaries => 'Failed to load summaries';

  @override
  String get retry => 'Retry';

  @override
  String get shareLabel => 'Share';

  @override
  String get doctorVisit => 'Doctor Visit';

  @override
  String timeToday(String time) {
    return 'Today, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'Yesterday, $time';
  }

  @override
  String get summaryProcessingHint =>
      'Pull down to refresh. This usually takes 30–60 seconds.';

  @override
  String get summaryCouldNotGenerate => 'Summary could not be generated';

  @override
  String get retrySummary => 'Retry summary';

  @override
  String get stuckRetrySummary => 'Stuck? Retry summary';

  @override
  String get scannedDocument => 'Scanned document';

  @override
  String scannedOn(String date) {
    return 'Scanned $date';
  }

  @override
  String get visitDetails => 'Visit Details';

  @override
  String get healthVisitSummary => 'Health Visit Summary';

  @override
  String get refreshSummaryTooltip => 'Refresh summary';

  @override
  String get preparingVisitSummary => 'Preparing visit summary...';

  @override
  String get preparingVisitSubtitle => 'This may take a minute.';

  @override
  String get unableToLoadVisitSummary => 'Unable to load visit summary';

  @override
  String get visitSummaryUnavailable => 'Visit summary is unavailable';

  @override
  String get visitSummary => 'Visit Summary';

  @override
  String get visitProcessingTitle => 'Your visit is being processed';

  @override
  String get visitProcessingBody =>
      'This may take 30–60 seconds.\nYou can continue using the app. Open Overview to see progress.';

  @override
  String get viewOverviewAction => 'View Overview';

  @override
  String get goToHome => 'Go to Home';

  @override
  String get medication => 'Medication';

  @override
  String get nextToDo => 'Next To Do';

  @override
  String get conditionsDiscussed => 'Conditions discussed';

  @override
  String get followUp => 'Follow up';

  @override
  String get nameLabel => 'Name';

  @override
  String get notSet => 'Not set';

  @override
  String get appleIdHidden => 'Apple ID (hidden)';

  @override
  String get accountType => 'Account Type';

  @override
  String get patientRole => 'Patient';

  @override
  String get caregiverRole => 'Caregiver';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get edit => 'Edit';

  @override
  String get add => 'Add';

  @override
  String get planLabel => 'Plan';

  @override
  String get planFree => 'Free';

  @override
  String get planPremium => 'Premium';

  @override
  String get chooseYourRole => 'Choose Your Role';

  @override
  String get chooseYourRoleSubtitle => 'Select how you\'ll be using RemiMinder';

  @override
  String get patientRoleCardDescription =>
      'Manage your own medications, appointments, and health records';

  @override
  String get caregiverRoleCardDescription =>
      'Help manage medications and care for family members or patients';

  @override
  String get continueButton => 'Continue';

  @override
  String get usageLabel => 'Usage';

  @override
  String freePlanUsage(int used, int limit) {
    return '$used / $limit summaries used';
  }

  @override
  String get unlimited => 'Unlimited';

  @override
  String get editPhoneNumber => 'Edit Phone Number';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get save => 'Save';

  @override
  String get phoneMinLength =>
      'Phone number must be at least 8 characters long';

  @override
  String get phoneUpdatedSuccess => 'Phone number updated successfully';

  @override
  String phoneUpdateFailed(String error) {
    return 'Failed to update phone number: $error';
  }

  @override
  String get changePassword => 'Change Password';

  @override
  String get changePasswordSubtitle =>
      'Update your account password for security';

  @override
  String get privacySettings => 'Privacy Settings';

  @override
  String get privacySettingsSubtitle => 'Manage your data sharing preferences';

  @override
  String get managePrivacy => 'Manage Privacy';

  @override
  String changePasswordProviderMessage(String provider) {
    return 'You signed in using $provider. Please change your password in your $provider account.';
  }

  @override
  String get ok => 'OK';

  @override
  String get selectDate => 'Select date';

  @override
  String get changePasswordIntro =>
      'Update your password to keep your account secure.';

  @override
  String get currentPassword => 'Current Password';

  @override
  String get currentPasswordHint => 'Enter your current password';

  @override
  String get enterCurrentPassword => 'Please enter your current password';

  @override
  String get newPassword => 'New Password';

  @override
  String get newPasswordHint => 'Enter your new password';

  @override
  String get enterNewPassword => 'Please enter a new password';

  @override
  String get passwordMinLength => 'Password must be at least 8 characters';

  @override
  String get confirmNewPassword => 'Confirm New Password';

  @override
  String get confirmNewPasswordHint => 'Re-enter your new password';

  @override
  String get confirmNewPasswordRequired => 'Please confirm your new password';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get passwordUpdatedSuccess => 'Password updated successfully';

  @override
  String get passwordUpdateFailed => 'Failed to update password';

  @override
  String get wrongPassword => 'Current password is incorrect';

  @override
  String get weakPassword => 'Password is too weak';

  @override
  String get requiresRecentLogin => 'Please log in again and try';

  @override
  String get checkInternetConnection => 'Check your internet connection';

  @override
  String get dataSharing => 'Data Sharing';

  @override
  String get allowCaregiverSummaries => 'Allow caregiver to view summaries';

  @override
  String get allowCaregiverMedications => 'Allow caregiver to view medications';

  @override
  String get allowCaregiverReminders => 'Allow caregiver to view reminders';

  @override
  String get allowAiImprovement =>
      'Allow AI to use my data to improve the product';

  @override
  String get communicationAndConsent => 'Communication & Consent';

  @override
  String get allowEmailNotifications => 'Allow email notifications';

  @override
  String get allowSmsNotifications => 'Allow SMS notifications';

  @override
  String get allowPushNotifications => 'Allow push notifications';

  @override
  String get dataControl => 'Data Control';

  @override
  String get exportMyData => 'Export my data';

  @override
  String get deleteAllMedicalRecords => 'Delete all my medical records';

  @override
  String get deleteMedicalRecordsTitle => 'Delete Medical Records';

  @override
  String get deleteMedicalRecordsMessage =>
      'This will permanently delete all your medical records. This action cannot be undone.';

  @override
  String get deleteRecords => 'Delete Records';

  @override
  String get deleteMyAccount => 'Delete my account';

  @override
  String get legal => 'Legal';

  @override
  String get viewPrivacyPolicy => 'View Privacy Policy';

  @override
  String get viewTermsOfService => 'View Terms of Service';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get termsOfServiceBody =>
      'Terms of Service for RemiMinder\n\n1. Acceptance of Terms\nBy using RemiMinder, you agree to these terms.\n\n2. Use of Service\nRemiMinder is designed to help manage healthcare and medication reminders.\n\n3. Privacy\nYour privacy is important to us. All health data is handled securely.\n\nFor the complete Terms of Service, please visit our website.';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicyBody =>
      'Privacy Policy for RemiMinder\n\n1. Information We Collect\nWe collect information you provide and usage data to improve our service.\n\n2. How We Use Information\nInformation is used to provide healthcare management services.\n\n3. Information Sharing\nWe do not sell your personal information.\n\nFor the complete Privacy Policy, please visit our website.';

  @override
  String get close => 'Close';

  @override
  String featureComingSoon(String feature) {
    return '$feature coming soon';
  }

  @override
  String get caregiverSharingEnabled => 'Caregiver sharing enabled';

  @override
  String get caregiverSharingDisabled => 'Caregiver sharing disabled';

  @override
  String get dataExport => 'Data export';

  @override
  String get remindersTitle => 'Reminders';

  @override
  String get tabAll => 'All';

  @override
  String get tabToday => 'Today';

  @override
  String get tabPending => 'Pending';

  @override
  String get tabCompleted => 'Completed';

  @override
  String get searchRemindersHint => 'Search reminders...';

  @override
  String get failedToLoadRemindersRetry => 'Failed to load reminders. Retry';

  @override
  String get deleteReminderTitle => 'Delete Reminder';

  @override
  String get deleteReminderMessage =>
      'Are you sure you want to delete this reminder?';

  @override
  String get markDone => 'Mark Done';

  @override
  String get snooze => 'Snooze';

  @override
  String snoozedUntil(String time) {
    return 'Snoozed until $time';
  }

  @override
  String get statusDueNow => 'Due Now';

  @override
  String get statusActive => 'Active';

  @override
  String get statusMissed => 'Missed';

  @override
  String get statusSnoozed => 'Snoozed';

  @override
  String get statusSkipped => 'Skipped';

  @override
  String get statusPending => 'Pending';

  @override
  String get noRemindersFound => 'No reminders found';

  @override
  String get noRemindersMatchSearch => 'No reminders match your search';

  @override
  String get createFirstReminder => 'Create your first reminder to get started';

  @override
  String get tryAdjustSearch => 'Try adjusting your search terms';

  @override
  String get createReminder => 'Create Reminder';

  @override
  String get newReminder => 'New Reminder';

  @override
  String get editReminder => 'Edit Reminder';

  @override
  String get reminderTitleLabel => 'Title';

  @override
  String get dosageOptional => 'Dosage (optional)';

  @override
  String get dosageHint => 'e.g. 10 mg once daily';

  @override
  String get reminderTypeLabel => 'Type';

  @override
  String get appointment => 'Appointment';

  @override
  String get repeatLabel => 'Repeat';

  @override
  String get once => 'Once';

  @override
  String get daily => 'Daily';

  @override
  String get weekly => 'Weekly';

  @override
  String get pleaseEnterTitle => 'Please enter a title';

  @override
  String get reminderCreated => 'Reminder created!';

  @override
  String failedToCreateReminder(String error) {
    return 'Failed to create reminder: $error';
  }

  @override
  String get saveChanges => 'Save Changes';

  @override
  String get cannotRescheduleMissingType =>
      'Cannot reschedule: reminder type is missing';

  @override
  String get reminderUpdated => 'Reminder updated!';

  @override
  String failedToUpdateReminder(String error) {
    return 'Failed to update: $error';
  }

  @override
  String get reminderMarkedCompleted => 'Reminder marked as completed!';

  @override
  String get reminderSnoozed30 => 'Reminder snoozed for 30 minutes';

  @override
  String timeInHours(int hours, String time) {
    return 'In $hours hours ($time)';
  }

  @override
  String timeInMinutes(int minutes, String time) {
    return 'In $minutes minutes ($time)';
  }

  @override
  String get timeNow => 'Now';

  @override
  String timeHoursAgo(int hours) {
    return '$hours hours ago';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return '$minutes minutes ago';
  }

  @override
  String timeInDays(int days) {
    return 'in $days days';
  }

  @override
  String timeInHoursShort(int hours) {
    return 'in $hours hours';
  }

  @override
  String timeInMinutesShort(int minutes) {
    return 'in $minutes minutes';
  }

  @override
  String get selectTime => 'Select time';

  @override
  String get presetMorning => 'Morning (8:00 AM)';

  @override
  String get presetNoon => 'Noon (12:00 PM)';

  @override
  String get presetEvening => 'Evening (6:00 PM)';

  @override
  String get presetNight => 'Night (8:00 PM)';

  @override
  String get hourLabel => 'Hour';

  @override
  String get minuteLabel => 'Min';

  @override
  String get amPmLabel => 'AM / PM';

  @override
  String get amLabel => 'AM';

  @override
  String get pmLabel => 'PM';

  @override
  String selectedTimeLabel(String time) {
    return 'Selected time: $time';
  }

  @override
  String setForTime(String time) {
    return 'Set for $time ✓';
  }

  @override
  String get medicationAdherence => 'Medication Adherence';

  @override
  String get thisWeek => 'This Week';

  @override
  String get thisMonth => 'This Month';

  @override
  String get overall => 'Overall';

  @override
  String dosesCount(int done, int total) {
    return '$done/$total doses';
  }

  @override
  String get byMedication => 'By Medication';

  @override
  String get noPastRemindersAnalyze => 'No past reminders to analyze';

  @override
  String get adherenceTips => 'Adherence Tips';

  @override
  String get adherenceTipsBody =>
      '• Set phone reminders for medication times\n• Keep medications in a visible location\n• Use a pill organizer for daily doses\n• Track your progress to stay motivated';

  @override
  String get actionFailed => 'Action failed';

  @override
  String get snoozeAlreadyUsed => 'This reminder was already snoozed once';

  @override
  String get reminderDeleted => 'Reminder deleted';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get sectionRecentAlerts => 'Recent Alerts';

  @override
  String get viewAll => 'View All';

  @override
  String get sectionInvitations => 'Invitations';

  @override
  String get summaryPatients => 'Patients';

  @override
  String get summaryAlerts => 'Alerts';

  @override
  String get summaryPending => 'Pending';

  @override
  String get noAlertsAtThisTime => 'No alerts at this time';

  @override
  String get noPendingInvitations => 'No pending invitations';

  @override
  String get pendingInvitationsTitle => 'Pending Invitations';

  @override
  String invitationsWaiting(int count) {
    return '$count invitation(s) waiting';
  }

  @override
  String get reviewAcceptInvitations =>
      'Review and accept caregiver invitations.';

  @override
  String get viewInvitations => 'View Invitations';

  @override
  String get defaultPatient => 'Patient';

  @override
  String get defaultCaregiver => 'Caregiver';

  @override
  String caregiverPatientTime(String name, String time) {
    return 'Patient: $name • $time';
  }

  @override
  String timeDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get alertsTitle => 'Alerts';

  @override
  String get filterUnread => 'Unread';

  @override
  String get filterRead => 'Read';

  @override
  String get filterHighPriority => 'High Priority';

  @override
  String get filterActionRequired => 'Action Required';

  @override
  String get alertSingular => 'Alert';

  @override
  String get alertsPlural => 'Alerts';

  @override
  String get clearFilter => 'Clear Filter';

  @override
  String get noAlertsMatchFilter => 'No alerts match this filter';

  @override
  String get allPatientActivitiesSmooth =>
      'All patient activities are running smoothly';

  @override
  String get tryAdjustingFilter =>
      'Try adjusting your filter to see more alerts';

  @override
  String get viewAllAlerts => 'View All Alerts';

  @override
  String get alertMarkedAsRead => 'Alert marked as read';

  @override
  String alertsMarkedAsRead(int count) {
    return 'Marked $count alerts as read';
  }

  @override
  String get allAlertsAlreadyRead => 'All alerts are already read';

  @override
  String get myPatientsTitle => 'My Patients';

  @override
  String get patientsConnectedSubtitle => 'Patients connected to you';

  @override
  String get myPatientsSection => 'My patients';

  @override
  String connectedCount(int count) {
    return '$count connected';
  }

  @override
  String get searchPatientsHint => 'Search patients...';

  @override
  String get noPatientsMatchSearch => 'No patients match your search.';

  @override
  String get noPatientsConnectedYet => 'No patients connected yet';

  @override
  String get acceptInvitationToSeePatient =>
      'Accept an invitation to see a patient here.';

  @override
  String get badgeNew => 'New';

  @override
  String joinedOn(String date) {
    return 'Joined $date';
  }

  @override
  String get neverSynced => 'Not loaded yet';

  @override
  String get privacyDataRequestMessage =>
      'Contact privacy@remiminder.ai to export or delete your data.';

  @override
  String syncMinutesAgo(int minutes) {
    return '${minutes}m ago';
  }

  @override
  String syncHoursAgo(int hours) {
    return '${hours}h ago';
  }

  @override
  String syncDaysAgo(int days) {
    return '${days}d ago';
  }

  @override
  String get primaryCondition => 'Primary condition';

  @override
  String get lastSynced => 'Last synced';

  @override
  String get allergiesLabel => 'Allergies';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get currentMedications => 'Current medications';

  @override
  String get viewCarePlan => 'View care plan';

  @override
  String get remindersButton => 'Reminders';

  @override
  String get caregiverCareTeamSubtitle => 'Invite family or medical staff';

  @override
  String get invitationsReceived => 'Invitations received';

  @override
  String pendingBadge(int count) {
    return '$count pending';
  }

  @override
  String get patientOverviewTitle => 'Patient Overview';

  @override
  String get patientOverviewTabVisits => 'Visits';

  @override
  String get patientOverviewTabReminders => 'Reminders';

  @override
  String get patientOverviewNoVisits => 'No visits available';

  @override
  String get patientOverviewNoReminders => 'No reminders available';

  @override
  String get patientOverviewMissingPatientId => 'Missing patient information';

  @override
  String get patientOverviewLastVisit => 'Last visit';

  @override
  String get patientOverviewCareTeam => 'Care team member';

  @override
  String get patientOverviewScheduledReminder => 'Scheduled reminder';

  @override
  String get patientOverviewNever => 'Never';

  @override
  String get patientOverviewYesterday => 'Yesterday';

  @override
  String get statusViewed => 'Viewed';

  @override
  String get statusExpired => 'Expired';

  @override
  String get statusJoined => 'Joined';

  @override
  String get noInvitationsToShow => 'No invitations to show';

  @override
  String invitedByLabel(String name) {
    return 'Invited by: $name';
  }

  @override
  String get acceptInvitation => 'Accept';

  @override
  String get declineInvitation => 'Decline';

  @override
  String get invitationDeclined => 'Invitation declined';

  @override
  String joinedCareTeamSnackbar(String patientName, String role) {
    return 'Joined $patientName\'s care team as $role';
  }

  @override
  String get manageAccess => 'Manage Access';

  @override
  String get manageAccessDescription =>
      'Update caregiver permission or remove access.';

  @override
  String get manage => 'Manage';

  @override
  String get accessUpdatedSuccess => 'Access updated successfully';

  @override
  String get accessUpdateFailed => 'Failed to update access. Please try again.';

  @override
  String get removeCaregiverTitle => 'Remove caregiver?';

  @override
  String get removeCaregiverMessage =>
      'Are you sure you want to remove this caregiver? They will lose access immediately.';

  @override
  String get remove => 'Remove';

  @override
  String get updatingAccess => 'Updating access...';

  @override
  String get removingCaregiver => 'Removing caregiver...';

  @override
  String get removeCaregiverFailed =>
      'Failed to remove caregiver. Please try again.';

  @override
  String get viewAccess => 'View Access';

  @override
  String get fullAccess => 'Full Access';

  @override
  String get viewOnly => 'View Only';

  @override
  String get resendingInvitation => 'Resending invitation...';

  @override
  String get invitationResent => 'Invitation resent';

  @override
  String get failedToResendInvitation => 'Failed to resend invitation';

  @override
  String get cancelingInvitation => 'Canceling invitation...';

  @override
  String get invitationCanceled => 'Invitation canceled';

  @override
  String get failedToCancelInvitation => 'Failed to cancel invitation';

  @override
  String get relationshipSon => 'Son';

  @override
  String get relationshipDaughter => 'Daughter';

  @override
  String get relationshipFriend => 'Friend';

  @override
  String get relationshipSpousePartner => 'Spouse/Partner';

  @override
  String get relationshipParent => 'Parent';

  @override
  String get relationshipChild => 'Child';

  @override
  String get relationshipFamilyMember => 'Family Member';

  @override
  String get relationshipHealthcareProfessional => 'Healthcare Professional';

  @override
  String get relationshipCaregiver => 'Caregiver';

  @override
  String get relationshipSister => 'Sister';

  @override
  String get relationshipBrother => 'Brother';

  @override
  String get relationshipOther => 'Other';

  @override
  String get visitActionTitle => 'What would you like to do?';

  @override
  String get visitActionAudioTitle => 'Audio Record Conversation';

  @override
  String get visitActionAudioSubtitle =>
      'Record your doctor visit for automatic summary';

  @override
  String get visitActionCaptureTitle => 'Capture & Scan';

  @override
  String get visitActionCaptureSubtitle =>
      'Take photos of reports, pill bottles, and documents';

  @override
  String get inviteCaregiverDialogTitle => 'Invite Caregiver';

  @override
  String get caregiverNameHint => 'Enter caregiver\'s full name';

  @override
  String get caregiverEmailHint => 'Enter caregiver\'s email address';

  @override
  String get relationshipLabel => 'Relationship';

  @override
  String get relationshipHint => 'e.g., Son, Daughter, Friend, Nurse';

  @override
  String get sendInvite => 'Send Invite';

  @override
  String get emailAndRoleRequired => 'Email and role are required';

  @override
  String get summaryReadyTitle => 'Your visit summary is ready!';

  @override
  String get summaryReadyBody => 'Would you like to view it now?';

  @override
  String get later => 'Later';

  @override
  String get viewSummary => 'View Summary';

  @override
  String get noLabResultsYet => 'No lab results yet';

  @override
  String get labResultsScanHint =>
      'Scan a lab report using Capture & Scan to see results here.';

  @override
  String get captureAndScan => 'Capture & Scan';

  @override
  String get noScannedDocsYet => 'No scanned documents yet';

  @override
  String get scannedDocsHint =>
      'Documents scanned during your visits will appear here.';

  @override
  String get selectAtLeastOneSummary => 'Select at least one summary';

  @override
  String get failedToDeleteSummaries =>
      'Failed to delete summaries. Please try again.';

  @override
  String get noCaregiverAddedYet => 'No caregiver added yet';

  @override
  String get summaryGenerationRestarted => 'Summary generation restarted';

  @override
  String retryFailed(String error) {
    return 'Retry failed: $error';
  }

  @override
  String get generateSummary => 'Generate Summary';

  @override
  String get discardRecording => 'Discard Recording';

  @override
  String unableToStartRecording(String error) {
    return 'Unable to start recording: $error';
  }

  @override
  String get recordingCompleted => 'Recording completed!';

  @override
  String unableToStopRecording(String error) {
    return 'Unable to stop recording: $error';
  }

  @override
  String get recordingDiscarded => 'Recording discarded';

  @override
  String get unableToOpenPrivacyPolicy => 'Unable to open the Privacy Policy.';

  @override
  String get noRecordingAvailable => 'No recording available';

  @override
  String get uploadingAudio => 'Uploading audio...';

  @override
  String failedToUploadAudio(String error) {
    return 'Failed to upload audio: $error';
  }

  @override
  String get stopRecordingTitle => 'Stop Recording?';

  @override
  String get stopRecordingMessage =>
      'Are you sure you want to stop recording? This action cannot be undone.';

  @override
  String get continueRecording => 'Continue Recording';

  @override
  String get stopAndDiscard => 'Stop & Discard';

  @override
  String get share => 'Share';

  @override
  String get cameraNotReady => 'Camera not ready. Please try again.';

  @override
  String failedToCaptureImage(String error) {
    return 'Failed to capture image: $error';
  }

  @override
  String get unableToStartCamera =>
      'Unable to start the camera. Please try again.';

  @override
  String get cameraReadyHint =>
      'Camera ready. Position your document and tap capture.';

  @override
  String unableToStartScanning(String error) {
    return 'Unable to start scanning: $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'Failed to upload image: $error';
  }

  @override
  String get noImageToProcess => 'No image to process. Please capture again.';

  @override
  String get documentScannedSaved => 'Document scanned and saved!';

  @override
  String scanProcessingFailed(String error) {
    return 'Scan processing failed: $error';
  }

  @override
  String get scanSavedToHistory => 'Scan saved to your visit history';

  @override
  String localNotificationSchedulingFailed(String error) {
    return 'Local notification scheduling failed: $error';
  }

  @override
  String reminderRescheduleFailed(String error) {
    return 'Reminder reschedule failed: $error';
  }

  @override
  String get authenticationErrorLoginAgain =>
      'Authentication error. Please log in again.';
}
