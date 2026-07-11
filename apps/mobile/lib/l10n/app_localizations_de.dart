// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'RemiMinder';

  @override
  String get login => 'Anmelden';

  @override
  String get logout => 'Abmelden';

  @override
  String get settings => 'Einstellungen';

  @override
  String get language => 'Sprache';

  @override
  String get profileSettings => 'Profileinstellungen';

  @override
  String get languageSettings => 'Sprache';

  @override
  String languagesAvailableCount(int count) {
    return '$count Sprachen';
  }

  @override
  String get scrollForMoreLanguages =>
      'Nach unten scrollen, um alle Sprachen zu sehen';

  @override
  String languageUpdated(String language) {
    return 'Sprache aktualisiert. Die App wird jetzt in $language angezeigt.';
  }

  @override
  String get navHome => 'Start';

  @override
  String get navVisits => 'Besuche';

  @override
  String get navOverview => 'Übersicht';

  @override
  String get navCareTeam => 'Team';

  @override
  String get navProfile => 'Profil';

  @override
  String get navPatients => 'Patienten';

  @override
  String get goodMorning => 'Guten Morgen';

  @override
  String get goodAfternoon => 'Guten Tag';

  @override
  String get goodEvening => 'Guten Abend';

  @override
  String get goodNight => 'Gute Nacht';

  @override
  String get howAreYouFeeling => 'Wie fühlen Sie sich heute?';

  @override
  String get todaysProgress => 'Heutiger Fortschritt';

  @override
  String doneCount(int done, int total) {
    return '$done/$total erledigt';
  }

  @override
  String get yourSchedule => 'Ihr Zeitplan';

  @override
  String get seeAll => 'Alle anzeigen →';

  @override
  String get nothingScheduledYet => 'Noch nichts geplant';

  @override
  String get unableToLoadReminders =>
      'Erinnerungen konnten nicht geladen werden';

  @override
  String get addReminder => 'Erinnerung hinzufügen';

  @override
  String get myTasks => 'Meine Aufgaben';

  @override
  String pendingCount(int count) {
    return '$count ausstehend';
  }

  @override
  String get noTasksYet => 'Noch keine Aufgaben';

  @override
  String get addTask => 'Aufgabe hinzufügen';

  @override
  String get statusUpcoming => 'Bevorstehend';

  @override
  String get statusScheduled => 'Geplant';

  @override
  String get statusDone => 'Erledigt';

  @override
  String get reminder => 'Erinnerung';

  @override
  String get task => 'Aufgabe';

  @override
  String get careTeamTitle => 'Betreuungsteam';

  @override
  String get careTeamSubtitle =>
      'Sie haben die Kontrolle. Überprüfen Sie unten Ihre Freigabeberechtigungen.';

  @override
  String get sectionPending => 'AUSSTEHEND';

  @override
  String get sectionAddNew => 'HINZUFÜGEN';

  @override
  String get inviteCaregiver => 'Betreuer einladen';

  @override
  String get inviteCaregiverSubtitle =>
      'Zugriff auf Ihre Gesundheitsinformationen teilen';

  @override
  String get invitationPending => 'Einladung ausstehend';

  @override
  String get resend => 'Erneut senden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get activeCaregivers => 'Aktive Betreuer';

  @override
  String get noCaregiversYet => 'Noch keine Betreuer hinzugefügt';

  @override
  String get english => 'Englisch';

  @override
  String get spanish => 'Spanisch';

  @override
  String get hindi => 'Hindi';

  @override
  String get french => 'Französisch';

  @override
  String get portuguese => 'Portugiesisch';

  @override
  String get german => 'Deutsch';

  @override
  String get bangla => 'Bengalisch';

  @override
  String get tamil => 'Tamil';

  @override
  String get gujarati => 'Gujarati';

  @override
  String get punjabi => 'Punjabi';

  @override
  String get accountDetails => 'Kontodetails';

  @override
  String get accountDetailsSubtitle => 'Profilinformationen anzeigen';

  @override
  String get accountSecurity => 'Kontosicherheit';

  @override
  String get accountSecuritySubtitle => 'Passwort und Datenschutz verwalten';

  @override
  String get notificationsLabel => 'Benachrichtigungen';

  @override
  String get mobileLabel => 'Mobil';

  @override
  String get emailLabel => 'E-Mail';

  @override
  String get upgrade => 'Upgrade';

  @override
  String get signOut => 'Abmelden';

  @override
  String get deleteAccount => 'Konto löschen';

  @override
  String get deleteAccountTitle => 'Konto löschen';

  @override
  String get deleteAccountMessage =>
      'Dadurch werden Ihr Konto und alle Ihre Daten dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden. Sind Sie sicher?';

  @override
  String get delete => 'Löschen';

  @override
  String get searchSummariesHint => 'Zusammenfassungen suchen...';

  @override
  String get tabSummaries => 'ZUSAMMENFASSUNGEN';

  @override
  String get tabLabResults => 'LABOR';

  @override
  String get tabScannedDocs => 'GESCANNT';

  @override
  String get noSummariesYet => 'Noch keine Zusammenfassungen';

  @override
  String get summariesWillAppearHere =>
      'Ihre Besuchszusammenfassungen erscheinen hier';

  @override
  String get failedToLoadSummaries =>
      'Zusammenfassungen konnten nicht geladen werden';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get shareLabel => 'Teilen';

  @override
  String get doctorVisit => 'Arztbesuch';

  @override
  String timeToday(String time) {
    return 'Heute, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'Gestern, $time';
  }

  @override
  String get summaryProcessingHint =>
      'Nach unten ziehen zum Aktualisieren. Dauert normalerweise 30–60 Sekunden.';

  @override
  String get summaryCouldNotGenerate =>
      'Zusammenfassung konnte nicht erstellt werden';

  @override
  String get retrySummary => 'Zusammenfassung erneut versuchen';

  @override
  String get stuckRetrySummary => 'Hängt? Erneut versuchen';

  @override
  String get scannedDocument => 'Gescanntes Dokument';

  @override
  String scannedOn(String date) {
    return 'Gescannt am $date';
  }

  @override
  String get visitDetails => 'Besuchsdetails';

  @override
  String get healthVisitSummary => 'Gesundheitsbesuch-Zusammenfassung';

  @override
  String get refreshSummaryTooltip => 'Zusammenfassung aktualisieren';

  @override
  String get preparingVisitSummary =>
      'Besuchszusammenfassung wird vorbereitet...';

  @override
  String get preparingVisitSubtitle => 'Dies kann eine Minute dauern.';

  @override
  String get unableToLoadVisitSummary =>
      'Zusammenfassung konnte nicht geladen werden';

  @override
  String get visitSummaryUnavailable =>
      'Besuchszusammenfassung nicht verfügbar';

  @override
  String get visitSummary => 'Besuchszusammenfassung';

  @override
  String get visitProcessingTitle => 'Ihr Besuch wird verarbeitet';

  @override
  String get visitProcessingBody =>
      'Dies kann 30–60 Sekunden dauern.\nSie können die App weiter nutzen. Öffnen Sie Übersicht, um den Fortschritt zu sehen.';

  @override
  String get viewOverviewAction => 'Übersicht anzeigen';

  @override
  String get goToHome => 'Zur Startseite';

  @override
  String get medication => 'Medikament';

  @override
  String get nextToDo => 'Nächste Schritte';

  @override
  String get conditionsDiscussed => 'Besprochene Erkrankungen';

  @override
  String get followUp => 'Nachsorge';

  @override
  String get nameLabel => 'Name';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get appleIdHidden => 'Apple-ID (verborgen)';

  @override
  String get accountType => 'Kontotyp';

  @override
  String get patientRole => 'Patient';

  @override
  String get caregiverRole => 'Betreuer';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get add => 'Hinzufügen';

  @override
  String get planLabel => 'Tarif';

  @override
  String get planFree => 'Kostenlos';

  @override
  String get planPremium => 'Premium';

  @override
  String get chooseYourRole => 'Wählen Sie Ihre Rolle';

  @override
  String get chooseYourRoleSubtitle => 'Wählen Sie, wie Sie RemiMinder nutzen';

  @override
  String get patientRoleCardDescription =>
      'Verwalten Sie Medikamente, Termine und Gesundheitsdaten';

  @override
  String get caregiverRoleCardDescription =>
      'Helfen Sie bei Medikamenten und Pflege für Familie oder Patienten';

  @override
  String get continueButton => 'Weiter';

  @override
  String get usageLabel => 'Nutzung';

  @override
  String freePlanUsage(int used, int limit) {
    return '$used / $limit Zusammenfassungen genutzt';
  }

  @override
  String get unlimited => 'Unbegrenzt';

  @override
  String get editPhoneNumber => 'Telefonnummer bearbeiten';

  @override
  String get phoneNumber => 'Telefonnummer';

  @override
  String get save => 'Speichern';

  @override
  String get phoneMinLength =>
      'Die Telefonnummer muss mindestens 8 Zeichen haben';

  @override
  String get phoneUpdatedSuccess => 'Telefonnummer erfolgreich aktualisiert';

  @override
  String phoneUpdateFailed(String error) {
    return 'Telefonnummer konnte nicht aktualisiert werden: $error';
  }

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get changePasswordSubtitle =>
      'Aktualisieren Sie Ihr Passwort für mehr Sicherheit';

  @override
  String get privacySettings => 'Datenschutzeinstellungen';

  @override
  String get privacySettingsSubtitle => 'Datenfreigabe-Einstellungen verwalten';

  @override
  String get managePrivacy => 'Datenschutz verwalten';

  @override
  String changePasswordProviderMessage(String provider) {
    return 'Sie haben sich mit $provider angemeldet. Ändern Sie Ihr Passwort in Ihrem $provider-Konto.';
  }

  @override
  String get ok => 'OK';

  @override
  String get selectDate => 'Datum wählen';

  @override
  String get changePasswordIntro =>
      'Aktualisieren Sie Ihr Passwort, um Ihr Konto zu schützen.';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get currentPasswordHint => 'Geben Sie Ihr aktuelles Passwort ein';

  @override
  String get enterCurrentPassword =>
      'Bitte geben Sie Ihr aktuelles Passwort ein';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get newPasswordHint => 'Geben Sie Ihr neues Passwort ein';

  @override
  String get enterNewPassword => 'Bitte geben Sie ein neues Passwort ein';

  @override
  String get passwordMinLength =>
      'Das Passwort muss mindestens 8 Zeichen haben';

  @override
  String get confirmNewPassword => 'Neues Passwort bestätigen';

  @override
  String get confirmNewPasswordHint =>
      'Geben Sie Ihr neues Passwort erneut ein';

  @override
  String get confirmNewPasswordRequired =>
      'Bitte bestätigen Sie Ihr neues Passwort';

  @override
  String get passwordsDoNotMatch => 'Passwörter stimmen nicht überein';

  @override
  String get updatePassword => 'Passwort aktualisieren';

  @override
  String get passwordUpdatedSuccess => 'Passwort erfolgreich aktualisiert';

  @override
  String get passwordUpdateFailed =>
      'Passwort konnte nicht aktualisiert werden';

  @override
  String get wrongPassword => 'Aktuelles Passwort ist falsch';

  @override
  String get weakPassword => 'Passwort ist zu schwach';

  @override
  String get requiresRecentLogin =>
      'Bitte melden Sie sich erneut an und versuchen Sie es';

  @override
  String get checkInternetConnection =>
      'Überprüfen Sie Ihre Internetverbindung';

  @override
  String get dataSharing => 'Datenfreigabe';

  @override
  String get allowCaregiverSummaries => 'Betreuer darf Zusammenfassungen sehen';

  @override
  String get allowCaregiverMedications => 'Betreuer darf Medikamente sehen';

  @override
  String get allowCaregiverReminders => 'Betreuer darf Erinnerungen sehen';

  @override
  String get allowAiImprovement =>
      'KI darf meine Daten zur Produktverbesserung nutzen';

  @override
  String get communicationAndConsent => 'Kommunikation & Einwilligung';

  @override
  String get allowEmailNotifications => 'E-Mail-Benachrichtigungen erlauben';

  @override
  String get allowSmsNotifications => 'SMS-Benachrichtigungen erlauben';

  @override
  String get allowPushNotifications => 'Push-Benachrichtigungen erlauben';

  @override
  String get dataControl => 'Datenkontrolle';

  @override
  String get exportMyData => 'Meine Daten exportieren';

  @override
  String get deleteAllMedicalRecords =>
      'Alle meine medizinischen Aufzeichnungen löschen';

  @override
  String get deleteMedicalRecordsTitle => 'Medizinische Aufzeichnungen löschen';

  @override
  String get deleteMedicalRecordsMessage =>
      'Dadurch werden alle Ihre medizinischen Aufzeichnungen dauerhaft gelöscht. Dies kann nicht rückgängig gemacht werden.';

  @override
  String get deleteRecords => 'Aufzeichnungen löschen';

  @override
  String get deleteMyAccount => 'Mein Konto löschen';

  @override
  String get legal => 'Rechtliches';

  @override
  String get viewPrivacyPolicy => 'Datenschutzrichtlinie anzeigen';

  @override
  String get viewTermsOfService => 'Nutzungsbedingungen anzeigen';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get termsOfServiceBody =>
      'Nutzungsbedingungen für RemiMinder\n\n1. Annahme der Bedingungen\nDurch die Nutzung von RemiMinder stimmen Sie diesen Bedingungen zu.\n\n2. Nutzung des Dienstes\nRemiMinder hilft bei der Verwaltung von Gesundheitsversorgung und Medikamentenerinnerungen.\n\n3. Datenschutz\nIhre Privatsphäre ist uns wichtig. Alle Gesundheitsdaten werden sicher behandelt.\n\nDie vollständigen Bedingungen finden Sie auf unserer Website.';

  @override
  String get privacyPolicy => 'Datenschutzrichtlinie';

  @override
  String get privacyPolicyBody =>
      'Datenschutzrichtlinie für RemiMinder\n\n1. Gesammelte Informationen\nWir erfassen von Ihnen bereitgestellte Informationen und Nutzungsdaten zur Verbesserung des Dienstes.\n\n2. Verwendung der Informationen\nInformationen werden zur Bereitstellung von Gesundheitsdiensten verwendet.\n\n3. Weitergabe von Informationen\nWir verkaufen Ihre persönlichen Daten nicht.\n\nDie vollständige Richtlinie finden Sie auf unserer Website.';

  @override
  String get close => 'Schließen';

  @override
  String featureComingSoon(String feature) {
    return '$feature demnächst verfügbar';
  }

  @override
  String get emailNotificationPreferenceMessage =>
      'Email notification preferences are managed by our support team. Contact privacy@remiminder.ai to update them.';

  @override
  String get pushNotificationsDisabled =>
      'Push notifications are disabled. Enable them in your device settings to receive alerts.';

  @override
  String get caregiverSharingEnabled => 'Freigabe für Betreuer aktiviert';

  @override
  String get caregiverSharingDisabled => 'Freigabe für Betreuer deaktiviert';

  @override
  String get dataExport => 'Datenexport';

  @override
  String get remindersTitle => 'Erinnerungen';

  @override
  String get tabAll => 'Alle';

  @override
  String get tabToday => 'Heute';

  @override
  String get tabPending => 'Ausstehend';

  @override
  String get tabCompleted => 'Erledigt';

  @override
  String get searchRemindersHint => 'Erinnerungen suchen...';

  @override
  String get failedToLoadRemindersRetry => 'Laden fehlgeschlagen. Erneut';

  @override
  String get deleteReminderTitle => 'Erinnerung löschen';

  @override
  String get deleteReminderMessage =>
      'Möchten Sie diese Erinnerung wirklich löschen?';

  @override
  String get markDone => 'Erledigt';

  @override
  String get snooze => 'Schlummern';

  @override
  String snoozedUntil(String time) {
    return 'Schlummern bis $time';
  }

  @override
  String get statusDueNow => 'Jetzt fällig';

  @override
  String get statusActive => 'Aktiv';

  @override
  String get statusMissed => 'Verpasst';

  @override
  String get statusSnoozed => 'Schlummernd';

  @override
  String get statusSkipped => 'Übersprungen';

  @override
  String get statusPending => 'Ausstehend';

  @override
  String get noRemindersFound => 'Keine Erinnerungen';

  @override
  String get noRemindersMatchSearch => 'Keine Treffer';

  @override
  String get createFirstReminder => 'Erstellen Sie Ihre erste Erinnerung';

  @override
  String get tryAdjustSearch => 'Andere Suchbegriffe versuchen';

  @override
  String get createReminder => 'Erinnerung erstellen';

  @override
  String get newReminder => 'Neue Erinnerung';

  @override
  String get editReminder => 'Erinnerung bearbeiten';

  @override
  String get reminderTitleLabel => 'Titel';

  @override
  String get dosageOptional => 'Dosierung (optional)';

  @override
  String get dosageHint => 'z.B. 10 mg einmal täglich';

  @override
  String get reminderTypeLabel => 'Typ';

  @override
  String get appointment => 'Termin';

  @override
  String get repeatLabel => 'Wiederholen';

  @override
  String get once => 'Einmal';

  @override
  String get daily => 'Täglich';

  @override
  String get weekly => 'Wöchentlich';

  @override
  String get pleaseEnterTitle => 'Bitte Titel eingeben';

  @override
  String get reminderCreated => 'Erinnerung erstellt!';

  @override
  String failedToCreateReminder(String error) {
    return 'Erstellen fehlgeschlagen: $error';
  }

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get cannotRescheduleMissingType =>
      'Neuplanung nicht möglich: Typ fehlt';

  @override
  String get reminderUpdated => 'Erinnerung aktualisiert!';

  @override
  String failedToUpdateReminder(String error) {
    return 'Aktualisierung fehlgeschlagen: $error';
  }

  @override
  String get reminderMarkedCompleted => 'Als erledigt markiert!';

  @override
  String get reminderSnoozed30 => '30 Minuten geschlummert';

  @override
  String timeInHours(int hours, String time) {
    return 'In $hours Std. ($time)';
  }

  @override
  String timeInMinutes(int minutes, String time) {
    return 'In $minutes Min. ($time)';
  }

  @override
  String get timeNow => 'Jetzt';

  @override
  String timeHoursAgo(int hours) {
    return 'Vor $hours Std.';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return 'Vor $minutes Min.';
  }

  @override
  String timeInDays(int days) {
    return 'in $days Tagen';
  }

  @override
  String timeInHoursShort(int hours) {
    return 'in $hours Std.';
  }

  @override
  String timeInMinutesShort(int minutes) {
    return 'in $minutes Min.';
  }

  @override
  String get selectTime => 'Uhrzeit wählen';

  @override
  String get presetMorning => 'Morgen (8:00)';

  @override
  String get presetNoon => 'Mittag (12:00)';

  @override
  String get presetEvening => 'Abend (18:00)';

  @override
  String get presetNight => 'Nacht (20:00)';

  @override
  String get hourLabel => 'Stunde';

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
    return 'Gewählte Zeit: $time';
  }

  @override
  String setForTime(String time) {
    return 'Setzen $time ✓';
  }

  @override
  String get medicationAdherence => 'Medikamenten-Adherence';

  @override
  String get thisWeek => 'Diese Woche';

  @override
  String get thisMonth => 'Dieser Monat';

  @override
  String get overall => 'Gesamt';

  @override
  String dosesCount(int done, int total) {
    return '$done/$total Dosen';
  }

  @override
  String get byMedication => 'Nach Medikament';

  @override
  String get noPastRemindersAnalyze => 'Keine vergangenen Erinnerungen';

  @override
  String get adherenceTips => 'Tipps zur Adherence';

  @override
  String get adherenceTipsBody =>
      '• Telefon-Erinnerungen einstellen\n• Medikamente sichtbar aufbewahren\n• Pillendose verwenden\n• Fortschritt verfolgen';

  @override
  String get actionFailed => 'Aktion fehlgeschlagen';

  @override
  String get snoozeAlreadyUsed =>
      'Diese Erinnerung wurde bereits einmal geschlummert';

  @override
  String get reminderDeleted => 'Erinnerung gelöscht';

  @override
  String get deleteFailed => 'Löschen fehlgeschlagen';

  @override
  String get sectionRecentAlerts => 'Aktuelle Warnungen';

  @override
  String get viewAll => 'Alle anzeigen';

  @override
  String get sectionInvitations => 'Einladungen';

  @override
  String get summaryPatients => 'Patienten';

  @override
  String get summaryAlerts => 'Warnungen';

  @override
  String get summaryPending => 'Ausstehend';

  @override
  String get noAlertsAtThisTime => 'Derzeit keine Warnungen';

  @override
  String get noPendingInvitations => 'Keine ausstehenden Einladungen';

  @override
  String get pendingInvitationsTitle => 'Ausstehende Einladungen';

  @override
  String invitationsWaiting(int count) {
    return '$count Einladung(en) ausstehend';
  }

  @override
  String get reviewAcceptInvitations =>
      'Pflegeeinladungen prüfen und annehmen.';

  @override
  String get viewInvitations => 'Einladungen anzeigen';

  @override
  String get defaultPatient => 'Patient';

  @override
  String get defaultCaregiver => 'Pflegekraft';

  @override
  String caregiverPatientTime(String name, String time) {
    return 'Patient: $name • $time';
  }

  @override
  String timeDaysAgo(int days) {
    return 'vor $days Tagen';
  }

  @override
  String get alertsTitle => 'Warnungen';

  @override
  String get filterUnread => 'Ungelesen';

  @override
  String get filterRead => 'Gelesen';

  @override
  String get filterHighPriority => 'Hohe Priorität';

  @override
  String get filterActionRequired => 'Aktion erforderlich';

  @override
  String get alertSingular => 'Warnung';

  @override
  String get alertsPlural => 'Warnungen';

  @override
  String get clearFilter => 'Filter löschen';

  @override
  String get noAlertsMatchFilter => 'Keine Warnungen entsprechen diesem Filter';

  @override
  String get allPatientActivitiesSmooth =>
      'Alle Patientenaktivitäten laufen reibungslos';

  @override
  String get tryAdjustingFilter =>
      'Passen Sie den Filter an, um mehr Warnungen zu sehen';

  @override
  String get viewAllAlerts => 'Alle Warnungen anzeigen';

  @override
  String get alertMarkedAsRead => 'Warnung als gelesen markiert';

  @override
  String alertsMarkedAsRead(int count) {
    return '$count Warnungen als gelesen markiert';
  }

  @override
  String get allAlertsAlreadyRead => 'Alle Warnungen sind bereits gelesen';

  @override
  String get myPatientsTitle => 'Meine Patienten';

  @override
  String get patientsConnectedSubtitle => 'Mit Ihnen verbundene Patienten';

  @override
  String get myPatientsSection => 'Meine Patienten';

  @override
  String connectedCount(int count) {
    return '$count verbunden';
  }

  @override
  String get searchPatientsHint => 'Patienten suchen...';

  @override
  String get noPatientsMatchSearch =>
      'Keine Patienten entsprechen Ihrer Suche.';

  @override
  String get noPatientsConnectedYet => 'Noch keine Patienten verbunden';

  @override
  String get acceptInvitationToSeePatient =>
      'Nehmen Sie eine Einladung an, um hier einen Patienten zu sehen.';

  @override
  String get badgeNew => 'Neu';

  @override
  String joinedOn(String date) {
    return 'Beigetreten am $date';
  }

  @override
  String get neverSynced => 'Noch nicht geladen';

  @override
  String get privacyDataRequestMessage =>
      'Kontaktieren Sie privacy@remiminder.ai, um Ihre Daten zu exportieren oder zu löschen.';

  @override
  String syncMinutesAgo(int minutes) {
    return 'vor $minutes Min.';
  }

  @override
  String syncHoursAgo(int hours) {
    return 'vor $hours Std.';
  }

  @override
  String syncDaysAgo(int days) {
    return 'vor $days T.';
  }

  @override
  String get primaryCondition => 'Hauptdiagnose';

  @override
  String get lastSynced => 'Zuletzt synchronisiert';

  @override
  String get allergiesLabel => 'Allergien';

  @override
  String get dateOfBirth => 'Geburtsdatum';

  @override
  String get currentMedications => 'Aktuelle Medikamente';

  @override
  String get viewCarePlan => 'Pflegeplan anzeigen';

  @override
  String get remindersButton => 'Erinnerungen';

  @override
  String get caregiverCareTeamSubtitle =>
      'Familie oder medizinisches Personal einladen';

  @override
  String get invitationsReceived => 'Erhaltene Einladungen';

  @override
  String pendingBadge(int count) {
    return '$count ausstehend';
  }

  @override
  String get patientOverviewTitle => 'Patientenübersicht';

  @override
  String get patientOverviewTabVisits => 'Besuche';

  @override
  String get patientOverviewTabReminders => 'Erinnerungen';

  @override
  String get patientOverviewNoVisits => 'Keine Besuche verfügbar';

  @override
  String get patientOverviewNoReminders => 'Keine Erinnerungen verfügbar';

  @override
  String get patientOverviewMissingPatientId => 'Patienteninformationen fehlen';

  @override
  String get patientOverviewLastVisit => 'Letzter Besuch';

  @override
  String get patientOverviewCareTeam => 'Pflegeteam-Mitglied';

  @override
  String get patientOverviewScheduledReminder => 'Geplante Erinnerung';

  @override
  String get patientOverviewNever => 'Nie';

  @override
  String get patientOverviewYesterday => 'Gestern';

  @override
  String get statusViewed => 'Angesehen';

  @override
  String get statusExpired => 'Abgelaufen';

  @override
  String get statusJoined => 'Beigetreten';

  @override
  String get noInvitationsToShow => 'Keine Einladungen anzuzeigen';

  @override
  String invitedByLabel(String name) {
    return 'Eingeladen von: $name';
  }

  @override
  String get acceptInvitation => 'Annehmen';

  @override
  String get declineInvitation => 'Ablehnen';

  @override
  String get invitationDeclined => 'Einladung abgelehnt';

  @override
  String joinedCareTeamSnackbar(String patientName, String role) {
    return 'Dem Betreuungsteam von $patientName als $role beigetreten';
  }

  @override
  String get manageAccess => 'Zugriff verwalten';

  @override
  String get manageAccessDescription =>
      'Berechtigung aktualisieren oder Zugriff entfernen.';

  @override
  String get manage => 'Verwalten';

  @override
  String get accessUpdatedSuccess => 'Zugriff erfolgreich aktualisiert';

  @override
  String get accessUpdateFailed =>
      'Zugriff konnte nicht aktualisiert werden. Bitte erneut versuchen.';

  @override
  String get removeCaregiverTitle => 'Betreuer entfernen?';

  @override
  String get removeCaregiverMessage =>
      'Möchten Sie diesen Betreuer wirklich entfernen? Der Zugriff endet sofort.';

  @override
  String get remove => 'Entfernen';

  @override
  String get updatingAccess => 'Zugriff wird aktualisiert...';

  @override
  String get removingCaregiver => 'Betreuer wird entfernt...';

  @override
  String get removeCaregiverFailed =>
      'Betreuer konnte nicht entfernt werden. Bitte erneut versuchen.';

  @override
  String get viewAccess => 'Lesezugriff';

  @override
  String get fullAccess => 'Voller Zugriff';

  @override
  String get viewOnly => 'Nur Lesen';

  @override
  String get resendingInvitation => 'Einladung wird erneut gesendet...';

  @override
  String get invitationResent => 'Einladung erneut gesendet';

  @override
  String get failedToResendInvitation =>
      'Einladung konnte nicht erneut gesendet werden';

  @override
  String get cancelingInvitation => 'Einladung wird storniert...';

  @override
  String get invitationCanceled => 'Einladung storniert';

  @override
  String get failedToCancelInvitation =>
      'Einladung konnte nicht storniert werden';

  @override
  String get relationshipSon => 'Sohn';

  @override
  String get relationshipDaughter => 'Tochter';

  @override
  String get relationshipFriend => 'Freund/in';

  @override
  String get relationshipSpousePartner => 'Ehepartner/in';

  @override
  String get relationshipParent => 'Elternteil';

  @override
  String get relationshipChild => 'Kind';

  @override
  String get relationshipFamilyMember => 'Familienmitglied';

  @override
  String get relationshipHealthcareProfessional => 'Medizinisches Fachpersonal';

  @override
  String get relationshipCaregiver => 'Betreuer/in';

  @override
  String get relationshipSister => 'Schwester';

  @override
  String get relationshipBrother => 'Bruder';

  @override
  String get relationshipOther => 'Andere';

  @override
  String get visitActionTitle => 'Was möchten Sie tun?';

  @override
  String get visitActionAudioTitle => 'Gespräch als Audio aufnehmen';

  @override
  String get visitActionAudioSubtitle =>
      'Nehmen Sie Ihren Arztbesuch für eine automatische Zusammenfassung auf';

  @override
  String get visitActionCaptureTitle => 'Erfassen und scannen';

  @override
  String get visitActionCaptureSubtitle =>
      'Fotografieren Sie Berichte, Medikamentenflaschen und Dokumente';

  @override
  String get inviteCaregiverDialogTitle => 'Betreuer einladen';

  @override
  String get caregiverNameHint => 'Vollständigen Namen des Betreuers eingeben';

  @override
  String get caregiverEmailHint => 'E-Mail-Adresse des Betreuers eingeben';

  @override
  String get relationshipLabel => 'Beziehung';

  @override
  String get relationshipHint =>
      'z. B. Sohn, Tochter, Freund, Krankenschwester';

  @override
  String get sendInvite => 'Einladung senden';

  @override
  String get emailAndRoleRequired => 'E-Mail und Rolle sind erforderlich';

  @override
  String get summaryReadyTitle => 'Ihre Besuchszusammenfassung ist fertig!';

  @override
  String get summaryReadyBody => 'Möchten Sie sie jetzt ansehen?';

  @override
  String get later => 'Später';

  @override
  String get viewSummary => 'Zusammenfassung anzeigen';

  @override
  String get noLabResultsYet => 'Noch keine Laborergebnisse';

  @override
  String get labResultsScanHint =>
      'Scannen Sie einen Laborbericht mit Erfassen und scannen, um die Ergebnisse hier zu sehen.';

  @override
  String get captureAndScan => 'Erfassen und scannen';

  @override
  String get noScannedDocsYet => 'Noch keine gescannten Dokumente';

  @override
  String get scannedDocsHint =>
      'Während Ihrer Besuche gescannte Dokumente erscheinen hier.';

  @override
  String get selectAtLeastOneSummary =>
      'Wählen Sie mindestens eine Zusammenfassung aus';

  @override
  String get failedToDeleteSummaries =>
      'Zusammenfassungen konnten nicht gelöscht werden. Bitte erneut versuchen.';

  @override
  String get noCaregiverAddedYet => 'Noch kein Betreuer hinzugefügt';

  @override
  String get summaryGenerationRestarted =>
      'Zusammenfassungserstellung neu gestartet';

  @override
  String retryFailed(String error) {
    return 'Wiederholung fehlgeschlagen: $error';
  }

  @override
  String get generateSummary => 'Zusammenfassung erstellen';

  @override
  String get discardRecording => 'Aufnahme verwerfen';

  @override
  String unableToStartRecording(String error) {
    return 'Aufnahme konnte nicht gestartet werden: $error';
  }

  @override
  String get recordingCompleted => 'Aufnahme abgeschlossen!';

  @override
  String unableToStopRecording(String error) {
    return 'Aufnahme konnte nicht gestoppt werden: $error';
  }

  @override
  String get recordingDiscarded => 'Aufnahme verworfen';

  @override
  String get unableToOpenPrivacyPolicy =>
      'Datenschutzrichtlinie konnte nicht geöffnet werden.';

  @override
  String get noRecordingAvailable => 'Keine Aufnahme verfügbar';

  @override
  String get uploadingAudio => 'Audio wird hochgeladen...';

  @override
  String failedToUploadAudio(String error) {
    return 'Audio-Upload fehlgeschlagen: $error';
  }

  @override
  String get stopRecordingTitle => 'Aufnahme stoppen?';

  @override
  String get stopRecordingMessage =>
      'Are you sure you want to stop recording? This action cannot be undone.';

  @override
  String get continueRecording => 'Aufnahme fortsetzen';

  @override
  String get stopAndDiscard => 'Stoppen und verwerfen';

  @override
  String get share => 'Teilen';

  @override
  String get cameraNotReady => 'Kamera nicht bereit. Bitte erneut versuchen.';

  @override
  String failedToCaptureImage(String error) {
    return 'Bildaufnahme fehlgeschlagen: $error';
  }

  @override
  String get unableToStartCamera =>
      'Kamera konnte nicht gestartet werden. Bitte erneut versuchen.';

  @override
  String get cameraReadyHint =>
      'Kamera bereit. Dokument positionieren und aufnehmen.';

  @override
  String unableToStartScanning(String error) {
    return 'Scan konnte nicht gestartet werden: $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'Bild-Upload fehlgeschlagen: $error';
  }

  @override
  String get noImageToProcess =>
      'Kein Bild zum Verarbeiten. Bitte erneut aufnehmen.';

  @override
  String get documentScannedSaved => 'Dokument gescannt und gespeichert!';

  @override
  String scanProcessingFailed(String error) {
    return 'Scan-Verarbeitung fehlgeschlagen: $error';
  }

  @override
  String get scanSavedToHistory => 'Scan im Besuchsverlauf gespeichert';

  @override
  String localNotificationSchedulingFailed(String error) {
    return 'Lokale Benachrichtigung fehlgeschlagen: $error';
  }

  @override
  String reminderRescheduleFailed(String error) {
    return 'Erinnerung neu planen fehlgeschlagen: $error';
  }

  @override
  String get authenticationErrorLoginAgain =>
      'Authentifizierungsfehler. Bitte erneut anmelden.';
}
