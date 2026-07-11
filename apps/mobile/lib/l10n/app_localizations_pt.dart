// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'RemiMinder';

  @override
  String get login => 'Entrar';

  @override
  String get logout => 'Sair';

  @override
  String get settings => 'Configurações';

  @override
  String get language => 'Idioma';

  @override
  String get profileSettings => 'Configurações do perfil';

  @override
  String get languageSettings => 'Idioma';

  @override
  String languagesAvailableCount(int count) {
    return '$count idiomas';
  }

  @override
  String get scrollForMoreLanguages =>
      'Role para baixo para ver todos os idiomas';

  @override
  String languageUpdated(String language) {
    return 'Idioma atualizado. O app agora será exibido em $language.';
  }

  @override
  String get navHome => 'Início';

  @override
  String get navVisits => 'Visitas';

  @override
  String get navOverview => 'Resumo';

  @override
  String get navCareTeam => 'Equipe';

  @override
  String get navProfile => 'Perfil';

  @override
  String get navPatients => 'Pacientes';

  @override
  String get goodMorning => 'Bom dia';

  @override
  String get goodAfternoon => 'Boa tarde';

  @override
  String get goodEvening => 'Boa noite';

  @override
  String get goodNight => 'Boa noite';

  @override
  String get howAreYouFeeling => 'Como você está se sentindo hoje?';

  @override
  String get todaysProgress => 'Progresso de hoje';

  @override
  String doneCount(int done, int total) {
    return '$done/$total concluídos';
  }

  @override
  String get yourSchedule => 'Sua agenda';

  @override
  String get seeAll => 'Ver tudo →';

  @override
  String get nothingScheduledYet => 'Nada agendado ainda';

  @override
  String get unableToLoadReminders => 'Não foi possível carregar os lembretes';

  @override
  String get addReminder => 'Adicionar lembrete';

  @override
  String get myTasks => 'Minhas tarefas';

  @override
  String pendingCount(int count) {
    return '$count pendentes';
  }

  @override
  String get noTasksYet => 'Nenhuma tarefa ainda';

  @override
  String get addTask => 'Adicionar tarefa';

  @override
  String get statusUpcoming => 'Em breve';

  @override
  String get statusScheduled => 'Agendado';

  @override
  String get statusDone => 'Concluído';

  @override
  String get reminder => 'Lembrete';

  @override
  String get task => 'Tarefa';

  @override
  String get careTeamTitle => 'Equipe de cuidados';

  @override
  String get careTeamSubtitle =>
      'Você está no controle. Revise suas permissões de compartilhamento abaixo.';

  @override
  String get sectionPending => 'PENDENTE';

  @override
  String get sectionAddNew => 'ADICIONAR';

  @override
  String get inviteCaregiver => 'Convidar um cuidador';

  @override
  String get inviteCaregiverSubtitle =>
      'Compartilhar acesso às suas informações de saúde';

  @override
  String get invitationPending => 'Convite pendente';

  @override
  String get resend => 'Reenviar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get activeCaregivers => 'Cuidadores ativos';

  @override
  String get noCaregiversYet => 'Nenhum cuidador adicionado';

  @override
  String get english => 'Inglês';

  @override
  String get spanish => 'Espanhol';

  @override
  String get hindi => 'Hindi';

  @override
  String get french => 'Francês';

  @override
  String get portuguese => 'Português';

  @override
  String get german => 'Alemão';

  @override
  String get bangla => 'Bengali';

  @override
  String get tamil => 'Tâmil';

  @override
  String get gujarati => 'Guzerate';

  @override
  String get punjabi => 'Punjabi';

  @override
  String get accountDetails => 'Detalhes da conta';

  @override
  String get accountDetailsSubtitle => 'Ver informações do seu perfil';

  @override
  String get accountSecurity => 'Segurança da conta';

  @override
  String get accountSecuritySubtitle => 'Gerenciar senha e privacidade';

  @override
  String get notificationsLabel => 'Notificações';

  @override
  String get mobileLabel => 'Celular';

  @override
  String get emailLabel => 'E-mail';

  @override
  String get upgrade => 'Atualizar';

  @override
  String get signOut => 'Sair';

  @override
  String get deleteAccount => 'Excluir conta';

  @override
  String get deleteAccountTitle => 'Excluir conta';

  @override
  String get deleteAccountMessage =>
      'Isso excluirá permanentemente sua conta e todos os seus dados. Esta ação não pode ser desfeita. Tem certeza?';

  @override
  String get delete => 'Excluir';

  @override
  String get searchSummariesHint => 'Buscar resumos...';

  @override
  String get tabSummaries => 'RESUMOS';

  @override
  String get tabLabResults => 'LABORATÓRIO';

  @override
  String get tabScannedDocs => 'DIGITALIZADOS';

  @override
  String get noSummariesYet => 'Nenhum resumo ainda';

  @override
  String get summariesWillAppearHere =>
      'Seus resumos de visita aparecerão aqui';

  @override
  String get failedToLoadSummaries => 'Falha ao carregar resumos';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get shareLabel => 'Compartilhar';

  @override
  String get doctorVisit => 'Consulta médica';

  @override
  String timeToday(String time) {
    return 'Hoje, $time';
  }

  @override
  String timeYesterday(String time) {
    return 'Ontem, $time';
  }

  @override
  String get summaryProcessingHint =>
      'Puxe para baixo para atualizar. Geralmente leva 30–60 segundos.';

  @override
  String get summaryCouldNotGenerate => 'Não foi possível gerar o resumo';

  @override
  String get retrySummary => 'Tentar resumo novamente';

  @override
  String get stuckRetrySummary => 'Travou? Tentar novamente';

  @override
  String get scannedDocument => 'Documento digitalizado';

  @override
  String scannedOn(String date) {
    return 'Digitalizado em $date';
  }

  @override
  String get visitDetails => 'Detalhes da visita';

  @override
  String get healthVisitSummary => 'Resumo da consulta médica';

  @override
  String get refreshSummaryTooltip => 'Atualizar resumo';

  @override
  String get preparingVisitSummary => 'Preparando resumo da visita...';

  @override
  String get preparingVisitSubtitle => 'Isso pode levar um minuto.';

  @override
  String get unableToLoadVisitSummary => 'Não foi possível carregar o resumo';

  @override
  String get visitSummaryUnavailable => 'Resumo da visita indisponível';

  @override
  String get visitSummary => 'Resumo da visita';

  @override
  String get visitProcessingTitle => 'Sua visita está sendo processada';

  @override
  String get visitProcessingBody =>
      'Isso pode levar 30–60 segundos.\nVocê pode continuar usando o app. Abra Resumo para ver o progresso.';

  @override
  String get viewOverviewAction => 'Ver resumo';

  @override
  String get goToHome => 'Ir para o início';

  @override
  String get medication => 'Medicamento';

  @override
  String get nextToDo => 'Próximos passos';

  @override
  String get conditionsDiscussed => 'Condições discutidas';

  @override
  String get followUp => 'Acompanhamento';

  @override
  String get nameLabel => 'Nome';

  @override
  String get notSet => 'Não definido';

  @override
  String get appleIdHidden => 'ID Apple (oculto)';

  @override
  String get accountType => 'Tipo de conta';

  @override
  String get patientRole => 'Paciente';

  @override
  String get caregiverRole => 'Cuidador';

  @override
  String get phoneLabel => 'Telefone';

  @override
  String get edit => 'Editar';

  @override
  String get add => 'Adicionar';

  @override
  String get planLabel => 'Plano';

  @override
  String get planFree => 'Gratuito';

  @override
  String get planPremium => 'Premium';

  @override
  String get chooseYourRole => 'Escolha seu papel';

  @override
  String get chooseYourRoleSubtitle => 'Selecione como você usará o RemiMinder';

  @override
  String get patientRoleCardDescription =>
      'Gerencie seus medicamentos, consultas e registros de saúde';

  @override
  String get caregiverRoleCardDescription =>
      'Ajude a gerenciar medicamentos e cuidados de familiares ou pacientes';

  @override
  String get continueButton => 'Continuar';

  @override
  String get usageLabel => 'Uso';

  @override
  String freePlanUsage(int used, int limit) {
    return '$used / $limit resumos usados';
  }

  @override
  String get unlimited => 'Ilimitado';

  @override
  String get editPhoneNumber => 'Editar número de telefone';

  @override
  String get phoneNumber => 'Número de telefone';

  @override
  String get save => 'Salvar';

  @override
  String get phoneMinLength => 'O número deve ter pelo menos 8 caracteres';

  @override
  String get phoneUpdatedSuccess => 'Número atualizado com sucesso';

  @override
  String phoneUpdateFailed(String error) {
    return 'Falha ao atualizar o telefone: $error';
  }

  @override
  String get changePassword => 'Alterar senha';

  @override
  String get changePasswordSubtitle =>
      'Atualize sua senha para maior segurança';

  @override
  String get privacySettings => 'Configurações de privacidade';

  @override
  String get privacySettingsSubtitle =>
      'Gerenciar preferências de compartilhamento de dados';

  @override
  String get managePrivacy => 'Gerenciar privacidade';

  @override
  String changePasswordProviderMessage(String provider) {
    return 'Você entrou com $provider. Altere sua senha na sua conta $provider.';
  }

  @override
  String get ok => 'OK';

  @override
  String get selectDate => 'Selecionar data';

  @override
  String get changePasswordIntro =>
      'Atualize sua senha para manter sua conta segura.';

  @override
  String get currentPassword => 'Senha atual';

  @override
  String get currentPasswordHint => 'Digite sua senha atual';

  @override
  String get enterCurrentPassword => 'Digite sua senha atual';

  @override
  String get newPassword => 'Nova senha';

  @override
  String get newPasswordHint => 'Digite sua nova senha';

  @override
  String get enterNewPassword => 'Digite uma nova senha';

  @override
  String get passwordMinLength => 'A senha deve ter pelo menos 8 caracteres';

  @override
  String get confirmNewPassword => 'Confirmar nova senha';

  @override
  String get confirmNewPasswordHint => 'Digite novamente sua nova senha';

  @override
  String get confirmNewPasswordRequired => 'Confirme sua nova senha';

  @override
  String get passwordsDoNotMatch => 'As senhas não coincidem';

  @override
  String get updatePassword => 'Atualizar senha';

  @override
  String get passwordUpdatedSuccess => 'Senha atualizada com sucesso';

  @override
  String get passwordUpdateFailed => 'Falha ao atualizar a senha';

  @override
  String get wrongPassword => 'A senha atual está incorreta';

  @override
  String get weakPassword => 'A senha é muito fraca';

  @override
  String get requiresRecentLogin => 'Faça login novamente e tente';

  @override
  String get checkInternetConnection => 'Verifique sua conexão com a internet';

  @override
  String get dataSharing => 'Compartilhamento de dados';

  @override
  String get allowCaregiverSummaries => 'Permitir que o cuidador veja resumos';

  @override
  String get allowCaregiverMedications =>
      'Permitir que o cuidador veja medicamentos';

  @override
  String get allowCaregiverReminders =>
      'Permitir que o cuidador veja lembretes';

  @override
  String get allowAiImprovement =>
      'Permitir que a IA use meus dados para melhorar o produto';

  @override
  String get communicationAndConsent => 'Comunicação e consentimento';

  @override
  String get allowEmailNotifications => 'Permitir notificações por e-mail';

  @override
  String get allowSmsNotifications => 'Permitir notificações por SMS';

  @override
  String get allowPushNotifications => 'Permitir notificações push';

  @override
  String get dataControl => 'Controle de dados';

  @override
  String get exportMyData => 'Exportar meus dados';

  @override
  String get deleteAllMedicalRecords =>
      'Excluir todos os meus registros médicos';

  @override
  String get deleteMedicalRecordsTitle => 'Excluir registros médicos';

  @override
  String get deleteMedicalRecordsMessage =>
      'Isso excluirá permanentemente todos os seus registros médicos. Esta ação não pode ser desfeita.';

  @override
  String get deleteRecords => 'Excluir registros';

  @override
  String get deleteMyAccount => 'Excluir minha conta';

  @override
  String get legal => 'Legal';

  @override
  String get viewPrivacyPolicy => 'Ver política de privacidade';

  @override
  String get viewTermsOfService => 'Ver termos de serviço';

  @override
  String get termsOfService => 'Termos de serviço';

  @override
  String get termsOfServiceBody =>
      'Termos de serviço do RemiMinder\n\n1. Aceitação dos termos\nAo usar o RemiMinder, você concorda com estes termos.\n\n2. Uso do serviço\nO RemiMinder foi projetado para ajudar a gerenciar cuidados de saúde e lembretes de medicamentos.\n\n3. Privacidade\nSua privacidade é importante. Todos os dados de saúde são tratados com segurança.\n\nPara os termos completos, visite nosso site.';

  @override
  String get privacyPolicy => 'Política de privacidade';

  @override
  String get privacyPolicyBody =>
      'Política de privacidade do RemiMinder\n\n1. Informações que coletamos\nColetamos as informações que você fornece e dados de uso para melhorar o serviço.\n\n2. Como usamos as informações\nAs informações são usadas para fornecer serviços de gestão de saúde.\n\n3. Compartilhamento de informações\nNão vendemos suas informações pessoais.\n\nPara a política completa, visite nosso site.';

  @override
  String get close => 'Fechar';

  @override
  String featureComingSoon(String feature) {
    return '$feature em breve';
  }

  @override
  String get emailNotificationPreferenceMessage =>
      'Email notification preferences are managed by our support team. Contact privacy@remiminder.ai to update them.';

  @override
  String get pushNotificationsDisabled =>
      'Push notifications are disabled. Enable them in your device settings to receive alerts.';

  @override
  String get caregiverSharingEnabled => 'Compartilhamento com cuidador ativado';

  @override
  String get caregiverSharingDisabled =>
      'Compartilhamento com cuidador desativado';

  @override
  String get dataExport => 'Exportação de dados';

  @override
  String get remindersTitle => 'Lembretes';

  @override
  String get tabAll => 'Todos';

  @override
  String get tabToday => 'Hoje';

  @override
  String get tabPending => 'Pendentes';

  @override
  String get tabCompleted => 'Concluídos';

  @override
  String get searchRemindersHint => 'Buscar lembretes...';

  @override
  String get failedToLoadRemindersRetry =>
      'Falha ao carregar. Tentar novamente';

  @override
  String get deleteReminderTitle => 'Excluir lembrete';

  @override
  String get deleteReminderMessage =>
      'Tem certeza de que deseja excluir este lembrete?';

  @override
  String get markDone => 'Marcar feito';

  @override
  String get snooze => 'Adiar';

  @override
  String snoozedUntil(String time) {
    return 'Adiado até $time';
  }

  @override
  String get statusDueNow => 'Vence agora';

  @override
  String get statusActive => 'Ativo';

  @override
  String get statusMissed => 'Perdido';

  @override
  String get statusSnoozed => 'Adiado';

  @override
  String get statusSkipped => 'Ignorado';

  @override
  String get statusPending => 'Pendente';

  @override
  String get noRemindersFound => 'Nenhum lembrete';

  @override
  String get noRemindersMatchSearch => 'Nenhum lembrete corresponde';

  @override
  String get createFirstReminder => 'Crie seu primeiro lembrete para começar';

  @override
  String get tryAdjustSearch => 'Tente outros termos de busca';

  @override
  String get createReminder => 'Criar lembrete';

  @override
  String get newReminder => 'Novo lembrete';

  @override
  String get editReminder => 'Editar lembrete';

  @override
  String get reminderTitleLabel => 'Título';

  @override
  String get dosageOptional => 'Dosagem (opcional)';

  @override
  String get dosageHint => 'ex. 10 mg uma vez ao dia';

  @override
  String get reminderTypeLabel => 'Tipo';

  @override
  String get appointment => 'Consulta';

  @override
  String get repeatLabel => 'Repetir';

  @override
  String get once => 'Uma vez';

  @override
  String get daily => 'Diário';

  @override
  String get weekly => 'Semanal';

  @override
  String get pleaseEnterTitle => 'Digite um título';

  @override
  String get reminderCreated => 'Lembrete criado!';

  @override
  String failedToCreateReminder(String error) {
    return 'Falha ao criar: $error';
  }

  @override
  String get saveChanges => 'Salvar alterações';

  @override
  String get cannotRescheduleMissingType =>
      'Não é possível reagendar: tipo ausente';

  @override
  String get reminderUpdated => 'Lembrete atualizado!';

  @override
  String failedToUpdateReminder(String error) {
    return 'Falha ao atualizar: $error';
  }

  @override
  String get reminderMarkedCompleted => 'Lembrete concluído!';

  @override
  String get reminderSnoozed30 => 'Lembrete adiado por 30 minutos';

  @override
  String timeInHours(int hours, String time) {
    return 'Em $hours h ($time)';
  }

  @override
  String timeInMinutes(int minutes, String time) {
    return 'Em $minutes min ($time)';
  }

  @override
  String get timeNow => 'Agora';

  @override
  String timeHoursAgo(int hours) {
    return 'Há $hours h';
  }

  @override
  String timeMinutesAgo(int minutes) {
    return 'Há $minutes min';
  }

  @override
  String timeInDays(int days) {
    return 'em $days dias';
  }

  @override
  String timeInHoursShort(int hours) {
    return 'em $hours h';
  }

  @override
  String timeInMinutesShort(int minutes) {
    return 'em $minutes min';
  }

  @override
  String get selectTime => 'Selecionar horário';

  @override
  String get presetMorning => 'Manhã (8:00)';

  @override
  String get presetNoon => 'Meio-dia (12:00)';

  @override
  String get presetEvening => 'Tarde (18:00)';

  @override
  String get presetNight => 'Noite (20:00)';

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
    return 'Horário selecionado: $time';
  }

  @override
  String setForTime(String time) {
    return 'Definir $time ✓';
  }

  @override
  String get medicationAdherence => 'Adesão à medicação';

  @override
  String get thisWeek => 'Esta semana';

  @override
  String get thisMonth => 'Este mês';

  @override
  String get overall => 'Geral';

  @override
  String dosesCount(int done, int total) {
    return '$done/$total doses';
  }

  @override
  String get byMedication => 'Por medicamento';

  @override
  String get noPastRemindersAnalyze => 'Sem lembretes passados';

  @override
  String get adherenceTips => 'Dicas de adesão';

  @override
  String get adherenceTipsBody =>
      '• Configure lembretes no telefone\n• Mantenha medicamentos visíveis\n• Use um organizador de pílulas\n• Acompanhe seu progresso';

  @override
  String get actionFailed => 'Ação falhou';

  @override
  String get snoozeAlreadyUsed => 'Este lembrete já foi adiado uma vez';

  @override
  String get reminderDeleted => 'Lembrete excluído';

  @override
  String get deleteFailed => 'Falha ao excluir';

  @override
  String get sectionRecentAlerts => 'Alertas recentes';

  @override
  String get viewAll => 'Ver tudo';

  @override
  String get sectionInvitations => 'Convites';

  @override
  String get summaryPatients => 'Pacientes';

  @override
  String get summaryAlerts => 'Alertas';

  @override
  String get summaryPending => 'Pendente';

  @override
  String get noAlertsAtThisTime => 'Nenhum alerta no momento';

  @override
  String get noPendingInvitations => 'Nenhum convite pendente';

  @override
  String get pendingInvitationsTitle => 'Convites pendentes';

  @override
  String invitationsWaiting(int count) {
    return '$count convite(s) aguardando';
  }

  @override
  String get reviewAcceptInvitations =>
      'Revise e aceite convites de cuidadores.';

  @override
  String get viewInvitations => 'Ver convites';

  @override
  String get defaultPatient => 'Paciente';

  @override
  String get defaultCaregiver => 'Cuidador';

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
    return 'Paciente: $name • $time';
  }

  @override
  String timeDaysAgo(int days) {
    return 'há $days dias';
  }

  @override
  String get alertsTitle => 'Alertas';

  @override
  String get filterUnread => 'Não lidas';

  @override
  String get filterRead => 'Lidas';

  @override
  String get filterHighPriority => 'Alta prioridade';

  @override
  String get filterActionRequired => 'Ação necessária';

  @override
  String get alertSingular => 'Alerta';

  @override
  String get alertsPlural => 'Alertas';

  @override
  String get clearFilter => 'Limpar filtro';

  @override
  String get noAlertsMatchFilter => 'Nenhum alerta corresponde a este filtro';

  @override
  String get allPatientActivitiesSmooth =>
      'Todas as atividades dos pacientes estão normais';

  @override
  String get tryAdjustingFilter =>
      'Tente ajustar o filtro para ver mais alertas';

  @override
  String get viewAllAlerts => 'Ver todos os alertas';

  @override
  String get alertMarkedAsRead => 'Alerta marcado como lido';

  @override
  String alertsMarkedAsRead(int count) {
    return '$count alertas marcados como lidos';
  }

  @override
  String get allAlertsAlreadyRead => 'Todos os alertas já foram lidos';

  @override
  String get markAllAlertsRead => 'Mark all read';

  @override
  String get myPatientsTitle => 'Meus pacientes';

  @override
  String get patientsConnectedSubtitle => 'Pacientes conectados a você';

  @override
  String get myPatientsSection => 'Meus pacientes';

  @override
  String connectedCount(int count) {
    return '$count conectados';
  }

  @override
  String get searchPatientsHint => 'Buscar pacientes...';

  @override
  String get noPatientsMatchSearch =>
      'Nenhum paciente corresponde à sua busca.';

  @override
  String get noPatientsConnectedYet => 'Nenhum paciente conectado ainda';

  @override
  String get acceptInvitationToSeePatient =>
      'Aceite um convite para ver um paciente aqui.';

  @override
  String get badgeNew => 'Novo';

  @override
  String joinedOn(String date) {
    return 'Entrou em $date';
  }

  @override
  String get neverSynced => 'Ainda não carregado';

  @override
  String get privacyDataRequestMessage =>
      'Entre em contato com privacy@remiminder.ai para exportar ou excluir seus dados.';

  @override
  String syncMinutesAgo(int minutes) {
    return 'há $minutes min';
  }

  @override
  String syncHoursAgo(int hours) {
    return 'há $hours h';
  }

  @override
  String syncDaysAgo(int days) {
    return 'há $days d';
  }

  @override
  String get primaryCondition => 'Condição principal';

  @override
  String get lastSynced => 'Última sincronização';

  @override
  String get allergiesLabel => 'Alergias';

  @override
  String get dateOfBirth => 'Data de nascimento';

  @override
  String get currentMedications => 'Medicamentos atuais';

  @override
  String get viewCarePlan => 'Ver plano de cuidado';

  @override
  String get remindersButton => 'Lembretes';

  @override
  String get caregiverCareTeamSubtitle => 'Convide família ou equipe médica';

  @override
  String get invitationsReceived => 'Convites recebidos';

  @override
  String pendingBadge(int count) {
    return '$count pendentes';
  }

  @override
  String get patientOverviewTitle => 'Visão geral do paciente';

  @override
  String get patientOverviewTabVisits => 'Consultas';

  @override
  String get patientOverviewTabReminders => 'Lembretes';

  @override
  String get patientOverviewNoVisits => 'Nenhuma consulta disponível';

  @override
  String get patientOverviewNoReminders => 'Nenhum lembrete disponível';

  @override
  String get patientOverviewMissingPatientId =>
      'Informações do paciente ausentes';

  @override
  String get patientOverviewLastVisit => 'Última consulta';

  @override
  String get patientOverviewCareTeam => 'Membro da equipe de cuidados';

  @override
  String get patientOverviewScheduledReminder => 'Lembrete agendado';

  @override
  String get patientOverviewNever => 'Nunca';

  @override
  String get patientOverviewYesterday => 'Ontem';

  @override
  String get statusViewed => 'Visualizado';

  @override
  String get statusExpired => 'Expirado';

  @override
  String get statusJoined => 'Entrou';

  @override
  String get noInvitationsToShow => 'Nenhum convite para mostrar';

  @override
  String invitedByLabel(String name) {
    return 'Convidado por: $name';
  }

  @override
  String get acceptInvitation => 'Aceitar';

  @override
  String get declineInvitation => 'Recusar';

  @override
  String get invitationDeclined => 'Convite recusado';

  @override
  String joinedCareTeamSnackbar(String patientName, String role) {
    return 'Entrou na equipe de $patientName como $role';
  }

  @override
  String get manageAccess => 'Gerenciar acesso';

  @override
  String get manageAccessDescription =>
      'Atualize a permissão do cuidador ou remova o acesso.';

  @override
  String get manage => 'Gerenciar';

  @override
  String get accessUpdatedSuccess => 'Acesso atualizado com sucesso';

  @override
  String get accessUpdateFailed =>
      'Falha ao atualizar o acesso. Tente novamente.';

  @override
  String get removeCaregiverTitle => 'Remover cuidador?';

  @override
  String get removeCaregiverMessage =>
      'Tem certeza de que deseja remover este cuidador? O acesso será revogado imediatamente.';

  @override
  String get remove => 'Remover';

  @override
  String get updatingAccess => 'Atualizando acesso...';

  @override
  String get removingCaregiver => 'Removendo cuidador...';

  @override
  String get removeCaregiverFailed =>
      'Falha ao remover cuidador. Tente novamente.';

  @override
  String get viewAccess => 'Acesso de visualização';

  @override
  String get fullAccess => 'Acesso total';

  @override
  String get viewOnly => 'Somente visualização';

  @override
  String get resendingInvitation => 'Reenviando convite...';

  @override
  String get invitationResent => 'Convite reenviado';

  @override
  String get failedToResendInvitation => 'Falha ao reenviar convite';

  @override
  String get cancelingInvitation => 'Cancelando convite...';

  @override
  String get invitationCanceled => 'Convite cancelado';

  @override
  String get failedToCancelInvitation => 'Falha ao cancelar convite';

  @override
  String get relationshipSon => 'Filho';

  @override
  String get relationshipDaughter => 'Filha';

  @override
  String get relationshipFriend => 'Amigo(a)';

  @override
  String get relationshipSpousePartner => 'Cônjuge/Parceiro(a)';

  @override
  String get relationshipParent => 'Pai/Mãe';

  @override
  String get relationshipChild => 'Filho(a)';

  @override
  String get relationshipFamilyMember => 'Membro da família';

  @override
  String get relationshipHealthcareProfessional => 'Profissional de saúde';

  @override
  String get relationshipCaregiver => 'Cuidador';

  @override
  String get relationshipSister => 'Irmã';

  @override
  String get relationshipBrother => 'Irmão';

  @override
  String get relationshipOther => 'Outro';

  @override
  String get visitActionTitle => 'O que você gostaria de fazer?';

  @override
  String get visitActionAudioTitle => 'Gravar conversa em áudio';

  @override
  String get visitActionAudioSubtitle =>
      'Grave sua consulta médica para um resumo automático';

  @override
  String get visitActionCaptureTitle => 'Capturar e digitalizar';

  @override
  String get visitActionCaptureSubtitle =>
      'Tire fotos de relatórios, frascos de remédios e documentos';

  @override
  String get inviteCaregiverDialogTitle => 'Convidar cuidador';

  @override
  String get caregiverNameHint => 'Digite o nome completo do cuidador';

  @override
  String get caregiverEmailHint => 'Digite o e-mail do cuidador';

  @override
  String get relationshipLabel => 'Relacionamento';

  @override
  String get relationshipHint => 'ex.: Filho, Filha, Amigo, Enfermeira';

  @override
  String get sendInvite => 'Enviar convite';

  @override
  String get emailAndRoleRequired => 'E-mail e função são obrigatórios';

  @override
  String get summaryReadyTitle => 'Seu resumo da visita está pronto!';

  @override
  String get summaryReadyBody => 'Gostaria de visualizá-lo agora?';

  @override
  String get later => 'Mais tarde';

  @override
  String get viewSummary => 'Ver resumo';

  @override
  String get noLabResultsYet => 'Ainda não há resultados de laboratório';

  @override
  String get labResultsScanHint =>
      'Digitalize um relatório de laboratório com Capturar e digitalizar para ver os resultados aqui.';

  @override
  String get captureAndScan => 'Capturar e digitalizar';

  @override
  String get noScannedDocsYet => 'Ainda não há documentos digitalizados';

  @override
  String get scannedDocsHint =>
      'Documentos digitalizados durante suas visitas aparecerão aqui.';

  @override
  String get selectAtLeastOneSummary => 'Selecione pelo menos um resumo';

  @override
  String get failedToDeleteSummaries =>
      'Falha ao excluir resumos. Tente novamente.';

  @override
  String get noCaregiverAddedYet => 'Nenhum cuidador adicionado ainda';

  @override
  String get summaryGenerationRestarted => 'A geração do resumo foi reiniciada';

  @override
  String retryFailed(String error) {
    return 'Nova tentativa falhou: $error';
  }

  @override
  String get generateSummary => 'Gerar resumo';

  @override
  String get discardRecording => 'Descartar gravação';

  @override
  String unableToStartRecording(String error) {
    return 'Não foi possível iniciar a gravação: $error';
  }

  @override
  String get recordingCompleted => 'Gravação concluída!';

  @override
  String unableToStopRecording(String error) {
    return 'Não foi possível parar a gravação: $error';
  }

  @override
  String get recordingDiscarded => 'Gravação descartada';

  @override
  String get unableToOpenPrivacyPolicy =>
      'Não foi possível abrir a Política de Privacidade.';

  @override
  String get noRecordingAvailable => 'Nenhuma gravação disponível';

  @override
  String get uploadingAudio => 'Enviando áudio...';

  @override
  String failedToUploadAudio(String error) {
    return 'Falha ao enviar áudio: $error';
  }

  @override
  String get stopRecordingTitle => 'Parar gravação?';

  @override
  String get stopRecordingMessage =>
      'Are you sure you want to stop recording? This action cannot be undone.';

  @override
  String get continueRecording => 'Continuar gravando';

  @override
  String get stopAndDiscard => 'Parar e descartar';

  @override
  String get share => 'Compartilhar';

  @override
  String get cameraNotReady => 'Câmera não está pronta. Tente novamente.';

  @override
  String failedToCaptureImage(String error) {
    return 'Falha ao capturar imagem: $error';
  }

  @override
  String get unableToStartCamera =>
      'Não foi possível iniciar a câmera. Tente novamente.';

  @override
  String get cameraReadyHint =>
      'Câmera pronta. Posicione o documento e toque em capturar.';

  @override
  String unableToStartScanning(String error) {
    return 'Não foi possível iniciar a digitalização: $error';
  }

  @override
  String failedToUploadImage(String error) {
    return 'Falha ao enviar imagem: $error';
  }

  @override
  String get noImageToProcess =>
      'Nenhuma imagem para processar. Capture novamente.';

  @override
  String get documentScannedSaved => 'Documento digitalizado e salvo!';

  @override
  String scanProcessingFailed(String error) {
    return 'Falha no processamento da digitalização: $error';
  }

  @override
  String get scanSavedToHistory =>
      'Digitalização salva no histórico de visitas';

  @override
  String localNotificationSchedulingFailed(String error) {
    return 'Falha ao agendar notificação local: $error';
  }

  @override
  String reminderRescheduleFailed(String error) {
    return 'Falha ao reagendar lembrete: $error';
  }

  @override
  String get authenticationErrorLoginAgain =>
      'Erro de autenticação. Faça login novamente.';
}
