// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'RemiMinder';

  @override
  String get login => 'Iniciar sesión';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get settings => 'Configuración';

  @override
  String get language => 'Idioma';

  @override
  String get profileSettings => 'Configuración de perfil';

  @override
  String get languageSettings => 'Idioma';

  @override
  String languageUpdated(String language) {
    return 'Idioma actualizado. La aplicación ahora se mostrará en $language.';
  }

  @override
  String get navHome => 'Inicio';

  @override
  String get navVisits => 'Visitas';

  @override
  String get navOverview => 'Resumen';

  @override
  String get navCareTeam => 'Equipo';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navPatients => 'Pacientes';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get goodNight => 'Buenas noches';

  @override
  String get howAreYouFeeling => '¿Cómo te sientes hoy?';

  @override
  String get todaysProgress => 'Progreso de hoy';

  @override
  String doneCount(int done, int total) {
    return '$done/$total completados';
  }

  @override
  String get yourSchedule => 'Tu horario';

  @override
  String get seeAll => 'Ver todo →';

  @override
  String get nothingScheduledYet => 'Nada programado aún';

  @override
  String get unableToLoadReminders => 'No se pudieron cargar los recordatorios';

  @override
  String get addReminder => 'Agregar recordatorio';

  @override
  String get myTasks => 'Mis tareas';

  @override
  String pendingCount(int count) {
    return '$count pendientes';
  }

  @override
  String get noTasksYet => 'Sin tareas aún';

  @override
  String get addTask => 'Agregar tarea';

  @override
  String get statusUpcoming => 'Próximo';

  @override
  String get statusScheduled => 'Programado';

  @override
  String get statusDone => 'Hecho';

  @override
  String get reminder => 'Recordatorio';

  @override
  String get task => 'Tarea';

  @override
  String get careTeamTitle => 'Equipo de cuidado';

  @override
  String get careTeamSubtitle =>
      'Tú tienes el control. Revisa tus permisos de compartir a continuación.';

  @override
  String get sectionPending => 'PENDIENTE';

  @override
  String get sectionAddNew => 'AGREGAR NUEVO';

  @override
  String get inviteCaregiver => 'Invitar a un cuidador';

  @override
  String get inviteCaregiverSubtitle =>
      'Comparte acceso a tu información de salud';

  @override
  String get invitationPending => 'Invitación pendiente';

  @override
  String get resend => 'Reenviar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get activeCaregivers => 'Cuidadores activos';

  @override
  String get noCaregiversYet => 'Aún no hay cuidadores agregados';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get hindi => 'Hindi';

  @override
  String get french => 'Francés';

  @override
  String get portuguese => 'Portugués';

  @override
  String get german => 'Alemán';

  @override
  String get bangla => 'Bengalí';

  @override
  String get tamil => 'Tamil';

  @override
  String get gujarati => 'Gujarati';

  @override
  String get punjabi => 'Punjabi';

  @override
  String get accountDetails => 'Detalles de la cuenta';

  @override
  String get accountDetailsSubtitle => 'Ver tu información de perfil';

  @override
  String get accountSecurity => 'Seguridad de la cuenta';

  @override
  String get accountSecuritySubtitle => 'Administrar contraseña y privacidad';

  @override
  String get notificationsLabel => 'Notificaciones';

  @override
  String get mobileLabel => 'Móvil';

  @override
  String get emailLabel => 'Correo';

  @override
  String get upgrade => 'Mejorar';

  @override
  String get signOut => 'Salir';

  @override
  String get deleteAccount => 'Eliminar cuenta';

  @override
  String get deleteAccountTitle => 'Eliminar cuenta';

  @override
  String get deleteAccountMessage =>
      'Esto eliminará permanentemente tu cuenta y todos tus datos. Esta acción no se puede deshacer. ¿Estás seguro?';

  @override
  String get delete => 'Eliminar';

  @override
  String get searchSummariesHint => 'Buscar resúmenes...';

  @override
  String get tabSummaries => 'RESÚMENES';

  @override
  String get tabLabResults => 'LABORATORIO';

  @override
  String get tabScannedDocs => 'ESCANEADOS';

  @override
  String get noSummariesYet => 'Sin resúmenes aún';

  @override
  String get summariesWillAppearHere =>
      'Tus resúmenes de visitas aparecerán aquí';

  @override
  String get failedToLoadSummaries => 'No se pudieron cargar los resúmenes';

  @override
  String get retry => 'Reintentar';

  @override
  String get shareLabel => 'Compartir';

  @override
  String get doctorVisit => 'Visita médica';

  @override
  String timeToday(String time) {
    return 'Hoy, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'Ayer, $time';
  }

  @override
  String get summaryProcessingHint =>
      'Desliza hacia abajo para actualizar. Suele tardar 30–60 segundos.';

  @override
  String get summaryCouldNotGenerate => 'No se pudo generar el resumen';

  @override
  String get retrySummary => 'Reintentar resumen';

  @override
  String get stuckRetrySummary => '¿Atascado? Reintentar';

  @override
  String get scannedDocument => 'Documento escaneado';

  @override
  String scannedOn(String date) {
    return 'Escaneado $date';
  }

  @override
  String get visitDetails => 'Detalles de la visita';

  @override
  String get healthVisitSummary => 'Resumen de visita médica';

  @override
  String get refreshSummaryTooltip => 'Actualizar resumen';

  @override
  String get preparingVisitSummary => 'Preparando resumen de visita...';

  @override
  String get preparingVisitSubtitle => 'Esto puede tardar un minuto.';

  @override
  String get unableToLoadVisitSummary => 'No se pudo cargar el resumen';

  @override
  String get visitSummaryUnavailable => 'Resumen de visita no disponible';

  @override
  String get visitSummary => 'Resumen de visita';

  @override
  String get visitProcessingTitle => 'Tu visita se está procesando';

  @override
  String get visitProcessingBody =>
      'Puede tardar 30–60 segundos.\nPuedes seguir usando la app. Abre Resumen para ver el progreso.';

  @override
  String get viewOverviewAction => 'Ver resumen';

  @override
  String get goToHome => 'Ir al inicio';

  @override
  String get medication => 'Medicación';

  @override
  String get nextToDo => 'Próximos pasos';

  @override
  String get conditionsDiscussed => 'Condiciones discutidas';

  @override
  String get followUp => 'Seguimiento';

  @override
  String get nameLabel => 'Nombre';

  @override
  String get notSet => 'No establecido';

  @override
  String get appleIdHidden => 'ID de Apple (oculto)';

  @override
  String get accountType => 'Tipo de cuenta';

  @override
  String get patientRole => 'Paciente';

  @override
  String get caregiverRole => 'Cuidador';

  @override
  String get phoneLabel => 'Teléfono';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Agregar';

  @override
  String get planLabel => 'Plan';

  @override
  String get planFree => 'Gratis';

  @override
  String get planPremium => 'Premium';

  @override
  String get usageLabel => 'Uso';

  @override
  String freePlanUsage(int used, int limit) {
    return 'Plan gratis — $used / $limit resúmenes usados';
  }

  @override
  String get unlimited => 'Ilimitado';

  @override
  String get editPhoneNumber => 'Editar número de teléfono';

  @override
  String get phoneNumber => 'Número de teléfono';

  @override
  String get save => 'Guardar';

  @override
  String get phoneMinLength => 'El número debe tener al menos 8 caracteres';

  @override
  String get phoneUpdatedSuccess => 'Número actualizado correctamente';

  @override
  String phoneUpdateFailed(String error) {
    return 'No se pudo actualizar el teléfono: $error';
  }

  @override
  String get changePassword => 'Cambiar contraseña';

  @override
  String get changePasswordSubtitle =>
      'Actualiza tu contraseña para mayor seguridad';

  @override
  String get privacySettings => 'Configuración de privacidad';

  @override
  String get privacySettingsSubtitle => 'Administra tus preferencias de datos';

  @override
  String get managePrivacy => 'Administrar privacidad';

  @override
  String changePasswordProviderMessage(String provider) {
    return 'Iniciaste sesión con $provider. Cambia tu contraseña en tu cuenta de $provider.';
  }

  @override
  String get ok => 'Aceptar';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get changePasswordIntro =>
      'Actualiza tu contraseña para mantener tu cuenta segura.';

  @override
  String get currentPassword => 'Contraseña actual';

  @override
  String get currentPasswordHint => 'Ingresa tu contraseña actual';

  @override
  String get enterCurrentPassword => 'Ingresa tu contraseña actual';

  @override
  String get newPassword => 'Nueva contraseña';

  @override
  String get newPasswordHint => 'Ingresa tu nueva contraseña';

  @override
  String get enterNewPassword => 'Ingresa una nueva contraseña';

  @override
  String get passwordMinLength =>
      'La contraseña debe tener al menos 8 caracteres';

  @override
  String get confirmNewPassword => 'Confirmar nueva contraseña';

  @override
  String get confirmNewPasswordHint => 'Vuelve a ingresar tu nueva contraseña';

  @override
  String get confirmNewPasswordRequired => 'Confirma tu nueva contraseña';

  @override
  String get passwordsDoNotMatch => 'Las contraseñas no coinciden';

  @override
  String get updatePassword => 'Actualizar contraseña';

  @override
  String get passwordUpdatedSuccess => 'Contraseña actualizada correctamente';

  @override
  String get passwordUpdateFailed => 'No se pudo actualizar la contraseña';

  @override
  String get wrongPassword => 'La contraseña actual es incorrecta';

  @override
  String get weakPassword => 'La contraseña es demasiado débil';

  @override
  String get requiresRecentLogin => 'Inicia sesión de nuevo e inténtalo';

  @override
  String get checkInternetConnection => 'Verifica tu conexión a internet';

  @override
  String get dataSharing => 'Compartir datos';

  @override
  String get allowCaregiverSummaries =>
      'Permitir que el cuidador vea resúmenes';

  @override
  String get allowCaregiverMedications =>
      'Permitir que el cuidador vea medicamentos';

  @override
  String get allowCaregiverReminders =>
      'Permitir que el cuidador vea recordatorios';

  @override
  String get allowAiImprovement =>
      'Permitir que la IA use mis datos para mejorar el producto';

  @override
  String get communicationAndConsent => 'Comunicación y consentimiento';

  @override
  String get allowEmailNotifications => 'Permitir notificaciones por correo';

  @override
  String get allowSmsNotifications => 'Permitir notificaciones por SMS';

  @override
  String get allowPushNotifications => 'Permitir notificaciones push';

  @override
  String get dataControl => 'Control de datos';

  @override
  String get exportMyData => 'Exportar mis datos';

  @override
  String get deleteAllMedicalRecords => 'Eliminar todos mis registros médicos';

  @override
  String get deleteMedicalRecordsTitle => 'Eliminar registros médicos';

  @override
  String get deleteMedicalRecordsMessage =>
      'Esto eliminará permanentemente todos tus registros médicos. Esta acción no se puede deshacer.';

  @override
  String get deleteRecords => 'Eliminar registros';

  @override
  String get deleteMyAccount => 'Eliminar mi cuenta';

  @override
  String get legal => 'Legal';

  @override
  String get viewPrivacyPolicy => 'Ver política de privacidad';

  @override
  String get viewTermsOfService => 'Ver términos de servicio';

  @override
  String get termsOfService => 'Términos de servicio';

  @override
  String get termsOfServiceBody =>
      'Términos de servicio de RemiMinder\n\n1. Aceptación de términos\nAl usar RemiMinder, aceptas estos términos.\n\n2. Uso del servicio\nRemiMinder está diseñado para ayudar a gestionar la salud y recordatorios de medicación.\n\n3. Privacidad\nTu privacidad es importante. Todos los datos de salud se manejan de forma segura.\n\nPara los términos completos, visita nuestro sitio web.';

  @override
  String get privacyPolicy => 'Política de privacidad';

  @override
  String get privacyPolicyBody =>
      'Política de privacidad de RemiMinder\n\n1. Información que recopilamos\nRecopilamos la información que proporcionas y datos de uso para mejorar el servicio.\n\n2. Cómo usamos la información\nLa información se usa para brindar servicios de gestión de salud.\n\n3. Compartir información\nNo vendemos tu información personal.\n\nPara la política completa, visita nuestro sitio web.';

  @override
  String get close => 'Cerrar';

  @override
  String featureComingSoon(String feature) {
    return '$feature próximamente';
  }

  @override
  String get caregiverSharingEnabled => 'Compartir con cuidador activado';

  @override
  String get caregiverSharingDisabled => 'Compartir con cuidador desactivado';

  @override
  String get dataExport => 'Exportación de datos';

  @override
  String get remindersTitle => 'Recordatorios';

  @override
  String get tabAll => 'Todos';

  @override
  String get tabToday => 'Hoy';

  @override
  String get tabPending => 'Pendientes';

  @override
  String get tabCompleted => 'Completados';

  @override
  String get searchRemindersHint => 'Buscar recordatorios...';

  @override
  String get failedToLoadRemindersRetry => 'No se pudieron cargar. Reintentar';

  @override
  String get deleteReminderTitle => 'Eliminar recordatorio';

  @override
  String get deleteReminderMessage =>
      '¿Seguro que deseas eliminar este recordatorio?';

  @override
  String get markDone => 'Marcar hecho';

  @override
  String get snooze => 'Posponer';

  @override
  String snoozedUntil(String time) {
    return 'Pospuesto hasta $time';
  }

  @override
  String get statusDueNow => 'Vence ahora';

  @override
  String get statusActive => 'Activo';

  @override
  String get statusMissed => 'Perdido';

  @override
  String get statusSnoozed => 'Pospuesto';

  @override
  String get statusSkipped => 'Omitido';

  @override
  String get statusPending => 'Pendiente';

  @override
  String get noRemindersFound => 'No hay recordatorios';

  @override
  String get noRemindersMatchSearch => 'Ningún recordatorio coincide';

  @override
  String get createFirstReminder => 'Crea tu primer recordatorio para empezar';

  @override
  String get tryAdjustSearch => 'Prueba otros términos de búsqueda';

  @override
  String get createReminder => 'Crear recordatorio';

  @override
  String get newReminder => 'Nuevo recordatorio';

  @override
  String get editReminder => 'Editar recordatorio';

  @override
  String get reminderTitleLabel => 'Título';

  @override
  String get dosageOptional => 'Dosis (opcional)';

  @override
  String get dosageHint => 'p. ej. 10 mg una vez al día';

  @override
  String get reminderTypeLabel => 'Tipo';

  @override
  String get appointment => 'Cita';

  @override
  String get repeatLabel => 'Repetir';

  @override
  String get once => 'Una vez';

  @override
  String get daily => 'Diario';

  @override
  String get weekly => 'Semanal';

  @override
  String get pleaseEnterTitle => 'Ingresa un título';

  @override
  String get reminderCreated => '¡Recordatorio creado!';

  @override
  String failedToCreateReminder(String error) {
    return 'No se pudo crear: $error';
  }

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get cannotRescheduleMissingType =>
      'No se puede reprogramar: falta el tipo';

  @override
  String get reminderUpdated => '¡Recordatorio actualizado!';

  @override
  String failedToUpdateReminder(String error) {
    return 'No se pudo actualizar: $error';
  }

  @override
  String get reminderMarkedCompleted => '¡Recordatorio completado!';

  @override
  String get reminderSnoozed30 => 'Recordatorio pospuesto 30 minutos';

  @override
  String timeInHours(int hours, String time) {
    return 'En $hours h ($time)';
  }

  @override
  String timeInMinutes(int minutes, String time) {
    return 'En $minutes min ($time)';
  }

  @override
  String get timeNow => 'Ahora';

  @override
  String timeHoursAgo(int hours) {
    return 'Hace $hours h';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return 'Hace $minutes min';
  }

  @override
  String timeInDays(int days) {
    return 'en $days días';
  }

  @override
  String timeInHoursShort(int hours) {
    return 'en $hours h';
  }

  @override
  String timeInMinutesShort(int minutes) {
    return 'en $minutes min';
  }

  @override
  String get selectTime => 'Seleccionar hora';

  @override
  String get presetMorning => 'Mañana (8:00 AM)';

  @override
  String get presetNoon => 'Mediodía (12:00 PM)';

  @override
  String get presetEvening => 'Tarde (6:00 PM)';

  @override
  String get presetNight => 'Noche (8:00 PM)';

  @override
  String get hourLabel => 'Hora';

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
    return 'Hora seleccionada: $time';
  }

  @override
  String setForTime(String time) {
    return 'Fijar $time ✓';
  }

  @override
  String get medicationAdherence => 'Adherencia a medicación';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get thisMonth => 'Este mes';

  @override
  String get overall => 'General';

  @override
  String dosesCount(int done, int total) {
    return '$done/$total dosis';
  }

  @override
  String get byMedication => 'Por medicamento';

  @override
  String get noPastRemindersAnalyze => 'No hay recordatorios pasados';

  @override
  String get adherenceTips => 'Consejos de adherencia';

  @override
  String get adherenceTipsBody =>
      '• Configura recordatorios en el teléfono\n• Mantén los medicamentos visibles\n• Usa un pastillero diario\n• Sigue tu progreso';

  @override
  String get actionFailed => 'Acción fallida';

  @override
  String get snoozeAlreadyUsed => 'Este recordatorio ya se pospuso una vez';

  @override
  String get reminderDeleted => 'Recordatorio eliminado';

  @override
  String get deleteFailed => 'Error al eliminar';

  @override
  String get sectionRecentAlerts => 'Alertas recientes';

  @override
  String get viewAll => 'Ver todo';

  @override
  String get sectionInvitations => 'Invitaciones';

  @override
  String get summaryPatients => 'Pacientes';

  @override
  String get summaryAlerts => 'Alertas';

  @override
  String get summaryPending => 'Pendiente';

  @override
  String get noAlertsAtThisTime => 'No hay alertas en este momento';

  @override
  String get noPendingInvitations => 'No hay invitaciones pendientes';

  @override
  String get pendingInvitationsTitle => 'Invitaciones pendientes';

  @override
  String invitationsWaiting(int count) {
    return '$count invitación(es) en espera';
  }

  @override
  String get reviewAcceptInvitations =>
      'Revise y acepte invitaciones de cuidadores.';

  @override
  String get viewInvitations => 'Ver invitaciones';

  @override
  String get defaultPatient => 'Paciente';

  @override
  String get defaultCaregiver => 'Cuidador';

  @override
  String caregiverPatientTime(String name, String time) {
    return 'Paciente: $name • $time';
  }

  @override
  String timeDaysAgo(int days) {
    return 'hace $days días';
  }

  @override
  String get alertsTitle => 'Alertas';

  @override
  String get filterUnread => 'No leídas';

  @override
  String get filterRead => 'Leídas';

  @override
  String get filterHighPriority => 'Alta prioridad';

  @override
  String get filterActionRequired => 'Acción requerida';

  @override
  String get alertSingular => 'Alerta';

  @override
  String get alertsPlural => 'Alertas';

  @override
  String get clearFilter => 'Borrar filtro';

  @override
  String get noAlertsMatchFilter => 'Ninguna alerta coincide con este filtro';

  @override
  String get allPatientActivitiesSmooth =>
      'Todas las actividades del paciente van bien';

  @override
  String get tryAdjustingFilter =>
      'Pruebe ajustar el filtro para ver más alertas';

  @override
  String get viewAllAlerts => 'Ver todas las alertas';

  @override
  String get alertMarkedAsRead => 'Alerta marcada como leída';

  @override
  String alertsMarkedAsRead(int count) {
    return '$count alertas marcadas como leídas';
  }

  @override
  String get allAlertsAlreadyRead => 'Todas las alertas ya están leídas';

  @override
  String get myPatientsTitle => 'Mis pacientes';

  @override
  String get patientsConnectedSubtitle => 'Pacientes conectados a usted';

  @override
  String get myPatientsSection => 'Mis pacientes';

  @override
  String connectedCount(int count) {
    return '$count conectados';
  }

  @override
  String get searchPatientsHint => 'Buscar pacientes...';

  @override
  String get noPatientsMatchSearch =>
      'Ningún paciente coincide con su búsqueda.';

  @override
  String get noPatientsConnectedYet => 'Aún no hay pacientes conectados';

  @override
  String get acceptInvitationToSeePatient =>
      'Acepte una invitación para ver un paciente aquí.';

  @override
  String get badgeNew => 'Nuevo';

  @override
  String joinedOn(String date) {
    return 'Se unió el $date';
  }

  @override
  String get neverSynced => 'Aún no cargado';

  @override
  String get privacyDataRequestMessage =>
      'Contacte a privacy@remiminder.ai para exportar o eliminar sus datos.';

  @override
  String syncMinutesAgo(int minutes) {
    return 'hace $minutes min';
  }

  @override
  String syncHoursAgo(int hours) {
    return 'hace $hours h';
  }

  @override
  String syncDaysAgo(int days) {
    return 'hace $days d';
  }

  @override
  String get primaryCondition => 'Condición principal';

  @override
  String get lastSynced => 'Última sincronización';

  @override
  String get allergiesLabel => 'Alergias';

  @override
  String get dateOfBirth => 'Fecha de nacimiento';

  @override
  String get currentMedications => 'Medicamentos actuales';

  @override
  String get viewCarePlan => 'Ver plan de cuidado';

  @override
  String get remindersButton => 'Recordatorios';

  @override
  String get caregiverCareTeamSubtitle =>
      'Invite a familiares o personal médico';

  @override
  String get invitationsReceived => 'Invitaciones recibidas';

  @override
  String pendingBadge(int count) {
    return '$count pendientes';
  }

  @override
  String get patientOverviewTitle => 'Resumen del paciente';

  @override
  String get patientOverviewTabVisits => 'Visitas';

  @override
  String get patientOverviewTabReminders => 'Recordatorios';

  @override
  String get patientOverviewNoVisits => 'No hay visitas disponibles';

  @override
  String get patientOverviewNoReminders => 'No hay recordatorios disponibles';

  @override
  String get patientOverviewMissingPatientId =>
      'Falta información del paciente';

  @override
  String get patientOverviewLastVisit => 'Última visita';

  @override
  String get patientOverviewCareTeam => 'Miembro del equipo de cuidado';

  @override
  String get patientOverviewScheduledReminder => 'Recordatorio programado';

  @override
  String get patientOverviewNever => 'Nunca';

  @override
  String get patientOverviewYesterday => 'Ayer';

  @override
  String get statusViewed => 'Visto';

  @override
  String get statusExpired => 'Expirado';

  @override
  String get statusJoined => 'Unido';

  @override
  String get noInvitationsToShow => 'No hay invitaciones para mostrar';

  @override
  String invitedByLabel(String name) {
    return 'Invitado por: $name';
  }

  @override
  String get acceptInvitation => 'Aceptar';

  @override
  String get declineInvitation => 'Rechazar';

  @override
  String get invitationDeclined => 'Invitación rechazada';

  @override
  String joinedCareTeamSnackbar(String patientName, String role) {
    return 'Se unió al equipo de $patientName como $role';
  }

  @override
  String get manageAccess => 'Administrar acceso';

  @override
  String get manageAccessDescription =>
      'Actualice el permiso del cuidador o elimine el acceso.';

  @override
  String get manage => 'Administrar';

  @override
  String get accessUpdatedSuccess => 'Acceso actualizado correctamente';

  @override
  String get accessUpdateFailed =>
      'No se pudo actualizar el acceso. Inténtelo de nuevo.';

  @override
  String get removeCaregiverTitle => '¿Eliminar cuidador?';

  @override
  String get removeCaregiverMessage =>
      '¿Está seguro de que desea eliminar a este cuidador? Perderá el acceso de inmediato.';

  @override
  String get remove => 'Eliminar';

  @override
  String get updatingAccess => 'Actualizando acceso...';

  @override
  String get removingCaregiver => 'Eliminando cuidador...';

  @override
  String get removeCaregiverFailed =>
      'No se pudo eliminar al cuidador. Inténtelo de nuevo.';

  @override
  String get viewAccess => 'Acceso de lectura';

  @override
  String get fullAccess => 'Acceso completo';

  @override
  String get viewOnly => 'Solo lectura';

  @override
  String get resendingInvitation => 'Reenviando invitación...';

  @override
  String get invitationResent => 'Invitación reenviada';

  @override
  String get failedToResendInvitation => 'No se pudo reenviar la invitación';

  @override
  String get cancelingInvitation => 'Cancelando invitación...';

  @override
  String get invitationCanceled => 'Invitación cancelada';

  @override
  String get failedToCancelInvitation => 'No se pudo cancelar la invitación';

  @override
  String get relationshipSon => 'Hijo';

  @override
  String get relationshipDaughter => 'Hija';

  @override
  String get relationshipFriend => 'Amigo/a';

  @override
  String get relationshipSpousePartner => 'Cónyuge/Pareja';

  @override
  String get relationshipParent => 'Padre/Madre';

  @override
  String get relationshipChild => 'Hijo/a';

  @override
  String get relationshipFamilyMember => 'Familiar';

  @override
  String get relationshipHealthcareProfessional => 'Profesional de salud';

  @override
  String get relationshipCaregiver => 'Cuidador';

  @override
  String get relationshipSister => 'Hermana';

  @override
  String get relationshipBrother => 'Hermano';

  @override
  String get relationshipOther => 'Otro';
}
