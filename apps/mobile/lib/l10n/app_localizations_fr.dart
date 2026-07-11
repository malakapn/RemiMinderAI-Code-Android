// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'RemiMinder';

  @override
  String get login => 'Connexion';

  @override
  String get logout => 'Déconnexion';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get profileSettings => 'Paramètres du profil';

  @override
  String get languageSettings => 'Langue';

  @override
  String languagesAvailableCount(int count) {
    return '$count langues';
  }

  @override
  String get scrollForMoreLanguages =>
      'Faites défiler vers le bas pour voir toutes les langues';

  @override
  String languageUpdated(String language) {
    return 'Langue mise à jour. L\'application s\'affichera désormais en $language.';
  }

  @override
  String get navHome => 'Accueil';

  @override
  String get navVisits => 'Visites';

  @override
  String get navOverview => 'Aperçu';

  @override
  String get navCareTeam => 'Équipe';

  @override
  String get navProfile => 'Profil';

  @override
  String get navPatients => 'Patients';

  @override
  String get goodMorning => 'Bonjour';

  @override
  String get goodAfternoon => 'Bon après-midi';

  @override
  String get goodEvening => 'Bonsoir';

  @override
  String get goodNight => 'Bonne nuit';

  @override
  String get howAreYouFeeling => 'Comment vous sentez-vous aujourd\'hui ?';

  @override
  String get todaysProgress => 'Progrès du jour';

  @override
  String doneCount(int done, int total) {
    return '$done/$total terminés';
  }

  @override
  String get yourSchedule => 'Votre planning';

  @override
  String get seeAll => 'Tout voir →';

  @override
  String get nothingScheduledYet => 'Rien de prévu pour l\'instant';

  @override
  String get unableToLoadReminders => 'Impossible de charger les rappels';

  @override
  String get addReminder => 'Ajouter un rappel';

  @override
  String get myTasks => 'Mes tâches';

  @override
  String pendingCount(int count) {
    return '$count en attente';
  }

  @override
  String get noTasksYet => 'Aucune tâche pour l\'instant';

  @override
  String get addTask => 'Ajouter une tâche';

  @override
  String get statusUpcoming => 'À venir';

  @override
  String get statusScheduled => 'Planifié';

  @override
  String get statusDone => 'Fait';

  @override
  String get reminder => 'Rappel';

  @override
  String get task => 'Tâche';

  @override
  String get careTeamTitle => 'Équipe de soins';

  @override
  String get careTeamSubtitle =>
      'Vous gardez le contrôle. Consultez vos autorisations de partage ci-dessous.';

  @override
  String get sectionPending => 'EN ATTENTE';

  @override
  String get sectionAddNew => 'AJOUTER';

  @override
  String get inviteCaregiver => 'Inviter un aidant';

  @override
  String get inviteCaregiverSubtitle =>
      'Partager l\'accès à vos informations de santé';

  @override
  String get invitationPending => 'Invitation en attente';

  @override
  String get resend => 'Renvoyer';

  @override
  String get cancel => 'Annuler';

  @override
  String get activeCaregivers => 'Aidants actifs';

  @override
  String get noCaregiversYet => 'Aucun aidant ajouté';

  @override
  String get english => 'Anglais';

  @override
  String get spanish => 'Espagnol';

  @override
  String get hindi => 'Hindi';

  @override
  String get french => 'Français';

  @override
  String get portuguese => 'Portugais';

  @override
  String get german => 'Allemand';

  @override
  String get bangla => 'Bengali';

  @override
  String get tamil => 'Tamoul';

  @override
  String get gujarati => 'Gujarati';

  @override
  String get punjabi => 'Pendjabi';

  @override
  String get accountDetails => 'Détails du compte';

  @override
  String get accountDetailsSubtitle => 'Voir les informations de votre profil';

  @override
  String get accountSecurity => 'Sécurité du compte';

  @override
  String get accountSecuritySubtitle =>
      'Gérer le mot de passe et la confidentialité';

  @override
  String get notificationsLabel => 'Notifications';

  @override
  String get mobileLabel => 'Mobile';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get upgrade => 'Mettre à niveau';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountTitle => 'Supprimer le compte';

  @override
  String get deleteAccountMessage =>
      'Cela supprimera définitivement votre compte et toutes vos données. Cette action est irréversible. Êtes-vous sûr ?';

  @override
  String get delete => 'Supprimer';

  @override
  String get searchSummariesHint => 'Rechercher des résumés...';

  @override
  String get tabSummaries => 'RÉSUMÉS';

  @override
  String get tabLabResults => 'LABORATOIRE';

  @override
  String get tabScannedDocs => 'NUMÉRISÉS';

  @override
  String get noSummariesYet => 'Aucun résumé pour l\'instant';

  @override
  String get summariesWillAppearHere =>
      'Vos résumés de visite apparaîtront ici';

  @override
  String get failedToLoadSummaries => 'Échec du chargement des résumés';

  @override
  String get retry => 'Réessayer';

  @override
  String get shareLabel => 'Partager';

  @override
  String get doctorVisit => 'Visite médicale';

  @override
  String timeToday(String time) {
    return 'Aujourd\'hui, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'Hier, $time';
  }

  @override
  String get summaryProcessingHint =>
      'Tirez vers le bas pour actualiser. Cela prend généralement 30 à 60 secondes.';

  @override
  String get summaryCouldNotGenerate => 'Le résumé n\'a pas pu être généré';

  @override
  String get retrySummary => 'Réessayer le résumé';

  @override
  String get stuckRetrySummary => 'Bloqué ? Réessayer';

  @override
  String get scannedDocument => 'Document numérisé';

  @override
  String scannedOn(String date) {
    return 'Numérisé le $date';
  }

  @override
  String get visitDetails => 'Détails de la visite';

  @override
  String get healthVisitSummary => 'Résumé de visite médicale';

  @override
  String get refreshSummaryTooltip => 'Actualiser le résumé';

  @override
  String get preparingVisitSummary => 'Préparation du résumé de visite...';

  @override
  String get preparingVisitSubtitle => 'Cela peut prendre une minute.';

  @override
  String get unableToLoadVisitSummary => 'Impossible de charger le résumé';

  @override
  String get visitSummaryUnavailable => 'Résumé de visite indisponible';

  @override
  String get visitSummary => 'Résumé de visite';

  @override
  String get visitProcessingTitle => 'Votre visite est en cours de traitement';

  @override
  String get visitProcessingBody =>
      'Cela peut prendre 30 à 60 secondes.\nVous pouvez continuer à utiliser l\'application. Ouvrez Aperçu pour suivre la progression.';

  @override
  String get viewOverviewAction => 'Voir l\'aperçu';

  @override
  String get goToHome => 'Aller à l\'accueil';

  @override
  String get medication => 'Médicament';

  @override
  String get nextToDo => 'Prochaines étapes';

  @override
  String get conditionsDiscussed => 'Conditions discutées';

  @override
  String get followUp => 'Suivi';

  @override
  String get nameLabel => 'Nom';

  @override
  String get notSet => 'Non défini';

  @override
  String get appleIdHidden => 'Identifiant Apple (masqué)';

  @override
  String get accountType => 'Type de compte';

  @override
  String get patientRole => 'Patient';

  @override
  String get caregiverRole => 'Aidant';

  @override
  String get phoneLabel => 'Téléphone';

  @override
  String get edit => 'Modifier';

  @override
  String get add => 'Ajouter';

  @override
  String get planLabel => 'Forfait';

  @override
  String get planFree => 'Gratuit';

  @override
  String get planPremium => 'Premium';

  @override
  String get chooseYourRole => 'Choisissez votre rôle';

  @override
  String get chooseYourRoleSubtitle =>
      'Choisissez comment vous utiliserez RemiMinder';

  @override
  String get patientRoleCardDescription =>
      'Gérez vos médicaments, rendez-vous et dossiers de santé';

  @override
  String get caregiverRoleCardDescription =>
      'Aidez à gérer les médicaments et les soins de vos proches ou patients';

  @override
  String get continueButton => 'Continuer';

  @override
  String get usageLabel => 'Utilisation';

  @override
  String freePlanUsage(int used, int limit) {
    return '$used / $limit résumés utilisés';
  }

  @override
  String get unlimited => 'Illimité';

  @override
  String get editPhoneNumber => 'Modifier le numéro de téléphone';

  @override
  String get phoneNumber => 'Numéro de téléphone';

  @override
  String get save => 'Enregistrer';

  @override
  String get phoneMinLength => 'Le numéro doit comporter au moins 8 caractères';

  @override
  String get phoneUpdatedSuccess => 'Numéro de téléphone mis à jour';

  @override
  String phoneUpdateFailed(String error) {
    return 'Échec de la mise à jour : $error';
  }

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get changePasswordSubtitle =>
      'Mettez à jour votre mot de passe pour plus de sécurité';

  @override
  String get privacySettings => 'Paramètres de confidentialité';

  @override
  String get privacySettingsSubtitle =>
      'Gérer vos préférences de partage de données';

  @override
  String get managePrivacy => 'Gérer la confidentialité';

  @override
  String changePasswordProviderMessage(String provider) {
    return 'Vous vous êtes connecté avec $provider. Modifiez votre mot de passe dans votre compte $provider.';
  }

  @override
  String get ok => 'OK';

  @override
  String get selectDate => 'Choisir la date';

  @override
  String get changePasswordIntro =>
      'Mettez à jour votre mot de passe pour sécuriser votre compte.';

  @override
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get currentPasswordHint => 'Entrez votre mot de passe actuel';

  @override
  String get enterCurrentPassword =>
      'Veuillez entrer votre mot de passe actuel';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get newPasswordHint => 'Entrez votre nouveau mot de passe';

  @override
  String get enterNewPassword => 'Veuillez entrer un nouveau mot de passe';

  @override
  String get passwordMinLength =>
      'Le mot de passe doit comporter au moins 8 caractères';

  @override
  String get confirmNewPassword => 'Confirmer le nouveau mot de passe';

  @override
  String get confirmNewPasswordHint =>
      'Saisissez à nouveau votre nouveau mot de passe';

  @override
  String get confirmNewPasswordRequired =>
      'Veuillez confirmer votre nouveau mot de passe';

  @override
  String get passwordsDoNotMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get updatePassword => 'Mettre à jour le mot de passe';

  @override
  String get passwordUpdatedSuccess => 'Mot de passe mis à jour';

  @override
  String get passwordUpdateFailed => 'Échec de la mise à jour du mot de passe';

  @override
  String get wrongPassword => 'Le mot de passe actuel est incorrect';

  @override
  String get weakPassword => 'Le mot de passe est trop faible';

  @override
  String get requiresRecentLogin => 'Veuillez vous reconnecter et réessayer';

  @override
  String get checkInternetConnection => 'Vérifiez votre connexion Internet';

  @override
  String get dataSharing => 'Partage des données';

  @override
  String get allowCaregiverSummaries =>
      'Autoriser l\'aidant à voir les résumés';

  @override
  String get allowCaregiverMedications =>
      'Autoriser l\'aidant à voir les médicaments';

  @override
  String get allowCaregiverReminders =>
      'Autoriser l\'aidant à voir les rappels';

  @override
  String get allowAiImprovement =>
      'Autoriser l\'IA à utiliser mes données pour améliorer le produit';

  @override
  String get communicationAndConsent => 'Communication et consentement';

  @override
  String get allowEmailNotifications =>
      'Autoriser les notifications par e-mail';

  @override
  String get allowSmsNotifications => 'Autoriser les notifications par SMS';

  @override
  String get allowPushNotifications => 'Autoriser les notifications push';

  @override
  String get dataControl => 'Contrôle des données';

  @override
  String get exportMyData => 'Exporter mes données';

  @override
  String get deleteAllMedicalRecords => 'Supprimer tous mes dossiers médicaux';

  @override
  String get deleteMedicalRecordsTitle => 'Supprimer les dossiers médicaux';

  @override
  String get deleteMedicalRecordsMessage =>
      'Cela supprimera définitivement tous vos dossiers médicaux. Cette action est irréversible.';

  @override
  String get deleteRecords => 'Supprimer les dossiers';

  @override
  String get deleteMyAccount => 'Supprimer mon compte';

  @override
  String get legal => 'Mentions légales';

  @override
  String get viewPrivacyPolicy => 'Voir la politique de confidentialité';

  @override
  String get viewTermsOfService => 'Voir les conditions d\'utilisation';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get termsOfServiceBody =>
      'Conditions d\'utilisation de RemiMinder\n\n1. Acceptation des conditions\nEn utilisant RemiMinder, vous acceptez ces conditions.\n\n2. Utilisation du service\nRemiMinder est conçu pour aider à gérer les soins de santé et les rappels de médicaments.\n\n3. Confidentialité\nVotre vie privée est importante. Toutes les données de santé sont traitées de manière sécurisée.\n\nPour les conditions complètes, visitez notre site web.';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get privacyPolicyBody =>
      'Politique de confidentialité de RemiMinder\n\n1. Informations collectées\nNous collectons les informations que vous fournissez et les données d\'utilisation pour améliorer le service.\n\n2. Utilisation des informations\nLes informations sont utilisées pour fournir des services de gestion de santé.\n\n3. Partage des informations\nNous ne vendons pas vos informations personnelles.\n\nPour la politique complète, visitez notre site web.';

  @override
  String get close => 'Fermer';

  @override
  String featureComingSoon(String feature) {
    return '$feature bientôt disponible';
  }

  @override
  String get emailNotificationPreferenceMessage =>
      'Email notification preferences are managed by our support team. Contact privacy@remiminder.ai to update them.';

  @override
  String get pushNotificationsDisabled =>
      'Push notifications are disabled. Enable them in your device settings to receive alerts.';

  @override
  String get caregiverSharingEnabled => 'Partage avec l\'aidant activé';

  @override
  String get caregiverSharingDisabled => 'Partage avec l\'aidant désactivé';

  @override
  String get dataExport => 'Exportation des données';

  @override
  String get remindersTitle => 'Rappels';

  @override
  String get tabAll => 'Tous';

  @override
  String get tabToday => 'Aujourd\'hui';

  @override
  String get tabPending => 'En attente';

  @override
  String get tabCompleted => 'Terminés';

  @override
  String get searchRemindersHint => 'Rechercher des rappels...';

  @override
  String get failedToLoadRemindersRetry => 'Échec du chargement. Réessayer';

  @override
  String get deleteReminderTitle => 'Supprimer le rappel';

  @override
  String get deleteReminderMessage =>
      'Voulez-vous vraiment supprimer ce rappel ?';

  @override
  String get markDone => 'Marquer fait';

  @override
  String get snooze => 'Reporter';

  @override
  String snoozedUntil(String time) {
    return 'Reporté jusqu\'à $time';
  }

  @override
  String get statusDueNow => 'À faire';

  @override
  String get statusActive => 'Actif';

  @override
  String get statusMissed => 'Manqué';

  @override
  String get statusSnoozed => 'Reporté';

  @override
  String get statusSkipped => 'Ignoré';

  @override
  String get statusPending => 'En attente';

  @override
  String get noRemindersFound => 'Aucun rappel';

  @override
  String get noRemindersMatchSearch => 'Aucun rappel ne correspond';

  @override
  String get createFirstReminder => 'Créez votre premier rappel pour commencer';

  @override
  String get tryAdjustSearch => 'Essayez d\'autres termes';

  @override
  String get createReminder => 'Créer un rappel';

  @override
  String get newReminder => 'Nouveau rappel';

  @override
  String get editReminder => 'Modifier le rappel';

  @override
  String get reminderTitleLabel => 'Titre';

  @override
  String get dosageOptional => 'Dosage (optionnel)';

  @override
  String get dosageHint => 'ex. 10 mg une fois par jour';

  @override
  String get reminderTypeLabel => 'Type';

  @override
  String get appointment => 'Rendez-vous';

  @override
  String get repeatLabel => 'Répéter';

  @override
  String get once => 'Une fois';

  @override
  String get daily => 'Quotidien';

  @override
  String get weekly => 'Hebdomadaire';

  @override
  String get pleaseEnterTitle => 'Veuillez entrer un titre';

  @override
  String get reminderCreated => 'Rappel créé !';

  @override
  String failedToCreateReminder(String error) {
    return 'Échec de création : $error';
  }

  @override
  String get saveChanges => 'Enregistrer';

  @override
  String get cannotRescheduleMissingType =>
      'Impossible de replanifier : type manquant';

  @override
  String get reminderUpdated => 'Rappel mis à jour !';

  @override
  String failedToUpdateReminder(String error) {
    return 'Échec de mise à jour : $error';
  }

  @override
  String get reminderMarkedCompleted => 'Rappel marqué comme terminé !';

  @override
  String get reminderSnoozed30 => 'Rappel reporté de 30 minutes';

  @override
  String timeInHours(int hours, String time) {
    return 'Dans $hours h ($time)';
  }

  @override
  String timeInMinutes(int minutes, String time) {
    return 'Dans $minutes min ($time)';
  }

  @override
  String get timeNow => 'Maintenant';

  @override
  String timeHoursAgo(int hours) {
    return 'Il y a $hours h';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return 'Il y a $minutes min';
  }

  @override
  String timeInDays(int days) {
    return 'dans $days jours';
  }

  @override
  String timeInHoursShort(int hours) {
    return 'dans $hours h';
  }

  @override
  String timeInMinutesShort(int minutes) {
    return 'dans $minutes min';
  }

  @override
  String get selectTime => 'Choisir l\'heure';

  @override
  String get presetMorning => 'Matin (8:00)';

  @override
  String get presetNoon => 'Midi (12:00)';

  @override
  String get presetEvening => 'Soir (18:00)';

  @override
  String get presetNight => 'Nuit (20:00)';

  @override
  String get hourLabel => 'Heure';

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
    return 'Heure sélectionnée : $time';
  }

  @override
  String setForTime(String time) {
    return 'Définir $time ✓';
  }

  @override
  String get medicationAdherence => 'Observance médicamenteuse';

  @override
  String get thisWeek => 'Cette semaine';

  @override
  String get thisMonth => 'Ce mois';

  @override
  String get overall => 'Global';

  @override
  String dosesCount(int done, int total) {
    return '$done/$total doses';
  }

  @override
  String get byMedication => 'Par médicament';

  @override
  String get noPastRemindersAnalyze => 'Aucun rappel passé à analyser';

  @override
  String get adherenceTips => 'Conseils d\'observance';

  @override
  String get adherenceTipsBody =>
      '• Définissez des rappels sur le téléphone\n• Gardez les médicaments visibles\n• Utilisez un pilulier\n• Suivez vos progrès';

  @override
  String get actionFailed => 'Action échouée';

  @override
  String get snoozeAlreadyUsed => 'Ce rappel a déjà été reporté une fois';

  @override
  String get reminderDeleted => 'Rappel supprimé';

  @override
  String get deleteFailed => 'Échec de suppression';

  @override
  String get sectionRecentAlerts => 'Alertes récentes';

  @override
  String get viewAll => 'Tout voir';

  @override
  String get sectionInvitations => 'Invitations';

  @override
  String get summaryPatients => 'Patients';

  @override
  String get summaryAlerts => 'Alertes';

  @override
  String get summaryPending => 'En attente';

  @override
  String get noAlertsAtThisTime => 'Aucune alerte pour le moment';

  @override
  String get noPendingInvitations => 'Aucune invitation en attente';

  @override
  String get pendingInvitationsTitle => 'Invitations en attente';

  @override
  String invitationsWaiting(int count) {
    return '$count invitation(s) en attente';
  }

  @override
  String get reviewAcceptInvitations =>
      'Examinez et acceptez les invitations d\'aidants.';

  @override
  String get viewInvitations => 'Voir les invitations';

  @override
  String get defaultPatient => 'Patient';

  @override
  String get defaultCaregiver => 'Aidant';

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
    return 'Patient : $name • $time';
  }

  @override
  String timeDaysAgo(int days) {
    return 'il y a $days jours';
  }

  @override
  String get alertsTitle => 'Alertes';

  @override
  String get filterUnread => 'Non lues';

  @override
  String get filterRead => 'Lues';

  @override
  String get filterHighPriority => 'Haute priorité';

  @override
  String get filterActionRequired => 'Action requise';

  @override
  String get alertSingular => 'Alerte';

  @override
  String get alertsPlural => 'Alertes';

  @override
  String get clearFilter => 'Effacer le filtre';

  @override
  String get noAlertsMatchFilter => 'Aucune alerte ne correspond à ce filtre';

  @override
  String get allPatientActivitiesSmooth =>
      'Toutes les activités des patients se déroulent bien';

  @override
  String get tryAdjustingFilter =>
      'Essayez d\'ajuster le filtre pour voir plus d\'alertes';

  @override
  String get viewAllAlerts => 'Voir toutes les alertes';

  @override
  String get alertMarkedAsRead => 'Alerte marquée comme lue';

  @override
  String alertsMarkedAsRead(int count) {
    return '$count alertes marquées comme lues';
  }

  @override
  String get allAlertsAlreadyRead => 'Toutes les alertes sont déjà lues';

  @override
  String get markAllAlertsRead => 'Mark all read';

  @override
  String get myPatientsTitle => 'Mes patients';

  @override
  String get patientsConnectedSubtitle => 'Patients connectés à vous';

  @override
  String get myPatientsSection => 'Mes patients';

  @override
  String connectedCount(int count) {
    return '$count connectés';
  }

  @override
  String get searchPatientsHint => 'Rechercher des patients...';

  @override
  String get noPatientsMatchSearch =>
      'Aucun patient ne correspond à votre recherche.';

  @override
  String get noPatientsConnectedYet => 'Aucun patient connecté pour le moment';

  @override
  String get acceptInvitationToSeePatient =>
      'Acceptez une invitation pour voir un patient ici.';

  @override
  String get badgeNew => 'Nouveau';

  @override
  String joinedOn(String date) {
    return 'Rejoint le $date';
  }

  @override
  String get neverSynced => 'Pas encore chargé';

  @override
  String get privacyDataRequestMessage =>
      'Contactez privacy@remiminder.ai pour exporter ou supprimer vos données.';

  @override
  String syncMinutesAgo(int minutes) {
    return 'il y a $minutes min';
  }

  @override
  String syncHoursAgo(int hours) {
    return 'il y a $hours h';
  }

  @override
  String syncDaysAgo(int days) {
    return 'il y a $days j';
  }

  @override
  String get primaryCondition => 'Condition principale';

  @override
  String get lastSynced => 'Dernière synchro';

  @override
  String get allergiesLabel => 'Allergies';

  @override
  String get dateOfBirth => 'Date de naissance';

  @override
  String get currentMedications => 'Médicaments actuels';

  @override
  String get viewCarePlan => 'Voir le plan de soins';

  @override
  String get remindersButton => 'Rappels';

  @override
  String get caregiverCareTeamSubtitle =>
      'Invitez la famille ou le personnel médical';

  @override
  String get invitationsReceived => 'Invitations reçues';

  @override
  String pendingBadge(int count) {
    return '$count en attente';
  }

  @override
  String get patientOverviewTitle => 'Aperçu du patient';

  @override
  String get patientOverviewTabVisits => 'Visites';

  @override
  String get patientOverviewTabReminders => 'Rappels';

  @override
  String get patientOverviewNoVisits => 'Aucune visite disponible';

  @override
  String get patientOverviewNoReminders => 'Aucun rappel disponible';

  @override
  String get patientOverviewMissingPatientId =>
      'Informations patient manquantes';

  @override
  String get patientOverviewLastVisit => 'Dernière visite';

  @override
  String get patientOverviewCareTeam => 'Membre de l\'équipe de soins';

  @override
  String get patientOverviewScheduledReminder => 'Rappel programmé';

  @override
  String get patientOverviewNever => 'Jamais';

  @override
  String get patientOverviewYesterday => 'Hier';

  @override
  String get statusViewed => 'Vu';

  @override
  String get statusExpired => 'Expiré';

  @override
  String get statusJoined => 'Rejoint';

  @override
  String get noInvitationsToShow => 'Aucune invitation à afficher';

  @override
  String invitedByLabel(String name) {
    return 'Invité par : $name';
  }

  @override
  String get acceptInvitation => 'Accepter';

  @override
  String get declineInvitation => 'Refuser';

  @override
  String get invitationDeclined => 'Invitation refusée';

  @override
  String joinedCareTeamSnackbar(String patientName, String role) {
    return 'A rejoint l\'équipe de $patientName en tant que $role';
  }

  @override
  String get manageAccess => 'Gérer l\'accès';

  @override
  String get manageAccessDescription =>
      'Mettez à jour les autorisations ou supprimez l\'accès.';

  @override
  String get manage => 'Gérer';

  @override
  String get accessUpdatedSuccess => 'Accès mis à jour avec succès';

  @override
  String get accessUpdateFailed =>
      'Échec de la mise à jour de l\'accès. Veuillez réessayer.';

  @override
  String get removeCaregiverTitle => 'Retirer l\'aidant ?';

  @override
  String get removeCaregiverMessage =>
      'Voulez-vous vraiment retirer cet aidant ? Il perdra l\'accès immédiatement.';

  @override
  String get remove => 'Retirer';

  @override
  String get updatingAccess => 'Mise à jour de l\'accès...';

  @override
  String get removingCaregiver => 'Retrait de l\'aidant...';

  @override
  String get removeCaregiverFailed =>
      'Impossible de retirer l\'aidant. Veuillez réessayer.';

  @override
  String get viewAccess => 'Accès lecture';

  @override
  String get fullAccess => 'Accès complet';

  @override
  String get viewOnly => 'Lecture seule';

  @override
  String get resendingInvitation => 'Renvoi de l\'invitation...';

  @override
  String get invitationResent => 'Invitation renvoyée';

  @override
  String get failedToResendInvitation => 'Échec du renvoi de l\'invitation';

  @override
  String get cancelingInvitation => 'Annulation de l\'invitation...';

  @override
  String get invitationCanceled => 'Invitation annulée';

  @override
  String get failedToCancelInvitation =>
      'Échec de l\'annulation de l\'invitation';

  @override
  String get relationshipSon => 'Fils';

  @override
  String get relationshipDaughter => 'Fille';

  @override
  String get relationshipFriend => 'Ami(e)';

  @override
  String get relationshipSpousePartner => 'Conjoint(e)/Partenaire';

  @override
  String get relationshipParent => 'Parent';

  @override
  String get relationshipChild => 'Enfant';

  @override
  String get relationshipFamilyMember => 'Membre de la famille';

  @override
  String get relationshipHealthcareProfessional => 'Professionnel de santé';

  @override
  String get relationshipCaregiver => 'Aidant';

  @override
  String get relationshipSister => 'Sœur';

  @override
  String get relationshipBrother => 'Frère';

  @override
  String get relationshipOther => 'Autre';

  @override
  String get visitActionTitle => 'Que souhaitez-vous faire ?';

  @override
  String get visitActionAudioTitle => 'Enregistrer une conversation audio';

  @override
  String get visitActionAudioSubtitle =>
      'Enregistrez votre visite médicale pour un résumé automatique';

  @override
  String get visitActionCaptureTitle => 'Capturer et numériser';

  @override
  String get visitActionCaptureSubtitle =>
      'Prenez des photos de rapports, flacons de médicaments et documents';

  @override
  String get inviteCaregiverDialogTitle => 'Inviter un aidant';

  @override
  String get caregiverNameHint => 'Entrez le nom complet de l\'aidant';

  @override
  String get caregiverEmailHint => 'Entrez l\'adresse e-mail de l\'aidant';

  @override
  String get relationshipLabel => 'Relation';

  @override
  String get relationshipHint => 'ex. : Fils, Fille, Ami, Infirmière';

  @override
  String get sendInvite => 'Envoyer l\'invitation';

  @override
  String get emailAndRoleRequired => 'L\'e-mail et le rôle sont requis';

  @override
  String get summaryReadyTitle => 'Votre résumé de visite est prêt !';

  @override
  String get summaryReadyBody => 'Souhaitez-vous le consulter maintenant ?';

  @override
  String get later => 'Plus tard';

  @override
  String get viewSummary => 'Voir le résumé';

  @override
  String get noLabResultsYet => 'Pas encore de résultats de laboratoire';

  @override
  String get labResultsScanHint =>
      'Numérisez un rapport de laboratoire avec Capturer et numériser pour voir les résultats ici.';

  @override
  String get captureAndScan => 'Capturer et numériser';

  @override
  String get noScannedDocsYet => 'Pas encore de documents numérisés';

  @override
  String get scannedDocsHint =>
      'Les documents numérisés lors de vos visites apparaîtront ici.';

  @override
  String get selectAtLeastOneSummary => 'Sélectionnez au moins un résumé';

  @override
  String get failedToDeleteSummaries =>
      'Échec de la suppression des résumés. Veuillez réessayer.';

  @override
  String get noCaregiverAddedYet => 'Aucun aidant ajouté pour le moment';

  @override
  String get summaryGenerationRestarted =>
      'La génération du résumé a redémarré';

  @override
  String retryFailed(String error) {
    return 'Nouvelle tentative échouée : $error';
  }

  @override
  String get generateSummary => 'Générer le résumé';

  @override
  String get discardRecording => 'Supprimer l\'enregistrement';

  @override
  String unableToStartRecording(String error) {
    return 'Impossible de démarrer l\'enregistrement : $error';
  }

  @override
  String get recordingCompleted => 'Enregistrement terminé !';

  @override
  String unableToStopRecording(String error) {
    return 'Impossible d\'arrêter l\'enregistrement : $error';
  }

  @override
  String get recordingDiscarded => 'Enregistrement supprimé';

  @override
  String get unableToOpenPrivacyPolicy =>
      'Impossible d\'ouvrir la politique de confidentialité.';

  @override
  String get noRecordingAvailable => 'Aucun enregistrement disponible';

  @override
  String get uploadingAudio => 'Téléversement de l\'audio...';

  @override
  String failedToUploadAudio(String error) {
    return 'Échec du téléversement audio : $error';
  }

  @override
  String get stopRecordingTitle => 'Arrêter l\'enregistrement ?';

  @override
  String get stopRecordingMessage =>
      'Are you sure you want to stop recording? This action cannot be undone.';

  @override
  String get continueRecording => 'Continuer l\'enregistrement';

  @override
  String get stopAndDiscard => 'Arrêter et supprimer';

  @override
  String get share => 'Partager';

  @override
  String get cameraNotReady => 'Caméra non prête. Réessayez.';

  @override
  String failedToCaptureImage(String error) {
    return 'Échec de la capture : $error';
  }

  @override
  String get unableToStartCamera =>
      'Impossible de démarrer la caméra. Réessayez.';

  @override
  String get cameraReadyHint =>
      'Caméra prête. Placez votre document et appuyez sur capturer.';

  @override
  String unableToStartScanning(String error) {
    return 'Impossible de démarrer la numérisation : $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'Échec du téléversement de l\'image : $error';
  }

  @override
  String get noImageToProcess => 'Aucune image à traiter. Capturez à nouveau.';

  @override
  String get documentScannedSaved => 'Document numérisé et enregistré !';

  @override
  String scanProcessingFailed(String error) {
    return 'Échec du traitement de la numérisation : $error';
  }

  @override
  String get scanSavedToHistory =>
      'Numérisation enregistrée dans l\'historique des visites';

  @override
  String localNotificationSchedulingFailed(String error) {
    return 'Échec de la planification de notification : $error';
  }

  @override
  String reminderRescheduleFailed(String error) {
    return 'Échec de la reprogrammation du rappel : $error';
  }

  @override
  String get authenticationErrorLoginAgain =>
      'Erreur d\'authentification. Reconnectez-vous.';
}
