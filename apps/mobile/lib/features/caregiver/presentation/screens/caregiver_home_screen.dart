import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/reminder_notification_sync.dart';
import '../../../../shared/utilities/greeting_utils.dart';
import '../../../patient/presentation/widgets/widgets.dart';
import '../../../care_team/data/models/care_team_invitation.dart';
import '../../../care_team/data/services/care_team_api_service.dart';
import '../../data/models/caregiver_alert.dart';
import '../../data/services/caregiver_alert_api_service.dart';

/// Dashboard counts refresh on pull-to-refresh, resume, periodic timer while visible,
/// tab switches (shell rebuilds home), and when returning from patient overview.
/// Optional: wire FCM data messages on new caregiver_alerts for instant updates.
class CaregiverHomeScreen extends ConsumerStatefulWidget {
  const CaregiverHomeScreen({super.key});

  @override
  ConsumerState<CaregiverHomeScreen> createState() =>
      _CaregiverHomeScreenState();
}

class _CaregiverHomeScreenState extends ConsumerState<CaregiverHomeScreen>
    with WidgetsBindingObserver {
  List<CareTeamInvitation> _invitations = [];
  bool _isLoadingInvitations = true;
  List<Map<String, dynamic>> _patients = [];
  bool _isLoadingPatients = true;

  List<CaregiverAlert> _recentAlerts = [];
  bool _isLoadingAlerts = true;
  int _unreadAlertsTotal = 0;

  List<Map<String, dynamic>> _homeReminders = [];
  List<Map<String, dynamic>> _homeAppointments = [];
  List<Map<String, dynamic>> _homeNotes = [];
  bool _isLoadingHomeReminders = false;

  static const Duration _dashboardRefreshInterval = Duration(minutes: 2);
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrapHome();
      _startPeriodicRefresh();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDashboard(silent: true);
    }
  }

  void _startPeriodicRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(_dashboardRefreshInterval, (_) {
      if (!mounted) return;
      _refreshDashboard(silent: true);
    });
  }

  Future<void> _bootstrapHome() async {
    await Future.wait([_loadInvitations(), _loadPatients()]);
    if (!mounted) return;
    await Future.wait([_loadAlertPreview(), _loadTopPatientReminders()]);
  }

  Future<void> _refreshDashboard({bool silent = false}) async {
    if (silent) {
      // Background refresh: update data without showing loading spinners
      await Future.wait([_loadInvitationsSilent(), _loadPatientsSilent()]);
      if (!mounted) return;
      await Future.wait([_loadAlertPreviewSilent(), _loadTopPatientReminders(silent: true)]);
    } else {
      await _bootstrapHome();
    }
  }

  // Silent versions — same logic but never touch loading flags
  Future<void> _loadAlertPreviewSilent() async {
    final user = ref.read(authNotifierProvider).user;
    final cid = user?.authUid ?? user?.id;
    if (cid == null || cid.isEmpty) return;
    try {
      final alerts = await CaregiverAlertApiService().getAlerts(caregiverId: cid);
      final sorted = List<CaregiverAlert>.from(alerts)..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      final unread = sorted.where((a) => !a.read).length;
      if (!mounted) return;
      setState(() {
        _recentAlerts = sorted.take(5).toList();
        _unreadAlertsTotal = unread;
      });
    } catch (_) {}
  }

  Future<void> _loadInvitationsSilent() async {
    try {
      final invitations = await CareTeamApiService().getMyInvitations();
      final pendingInvitations = invitations
          .where((i) => i.status.toLowerCase() == 'pending')
          .toList();
      if (!mounted) return;
      setState(() => _invitations = pendingInvitations);
    } catch (_) {}
  }

  Future<void> _loadPatientsSilent() async {
    try {
      final patients = await CareTeamApiService().getMyPatients();
      if (!mounted) return;
      setState(() => _patients = patients);
    } catch (_) {}
  }

  Future<void> _loadAlertPreview() async {
    final user = ref.read(authNotifierProvider).user;
    final cid = user?.authUid ?? user?.id;
    if (cid == null || cid.isEmpty) {
      if (mounted) setState(() => _isLoadingAlerts = false);
      return;
    }
    if (mounted) setState(() => _isLoadingAlerts = true);
    try {
      final alerts =
          await CaregiverAlertApiService().getAlerts(caregiverId: cid);
      final sorted = List<CaregiverAlert>.from(alerts)
        ..sort((a, b) => b.sentAt.compareTo(a.sentAt));
      final unread = sorted.where((a) => !a.read).length;
      if (!mounted) return;
      setState(() {
        _recentAlerts = sorted.take(5).toList();
        _unreadAlertsTotal = unread;
        _isLoadingAlerts = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingAlerts = false);
    }
  }

  String _patientDisplayNameForId(String patientId) {
    for (final p in _patients) {
      if (p['patient_id']?.toString() == patientId) {
        final n = (p['full_name'] as String?)?.trim();
        if (n != null && n.isNotEmpty) return n;
        return (p['email'] as String?)?.trim() ?? 'Patient';
      }
    }
    return 'Patient';
  }

  void _appendReminderBucket(
    dynamic bucket,
    String patientId,
    String patientName,
    List<Map<String, dynamic>> out,
  ) {
    if (bucket is! List) return;
    for (final item in bucket) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        m['_patient_id'] = patientId;
        m['_patient_name'] = patientName;
        out.add(m);
      }
    }
  }

  Future<void> _loadTopPatientReminders({bool silent = false}) async {
    final ids = _patients
        .map((p) => p['patient_id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .take(5)
        .toList();
    if (ids.isEmpty) {
      if (mounted) {
        setState(() {
          _homeReminders = [];
          _homeAppointments = [];
          _homeNotes = [];
          _isLoadingHomeReminders = false;
        });
      }
      return;
    }
    if (!silent && mounted) setState(() => _isLoadingHomeReminders = true);
    try {
      final svc = CareTeamApiService();
      final merged = <Map<String, dynamic>>[];
      final mergedNotes = <Map<String, dynamic>>[];
      final headers = await AuthService().getAuthHeaders();
      for (final pid in ids) {
        try {
          final data = await svc.getPatientReminderList(pid);
          final pname = _patientDisplayNameForId(pid);
          _appendReminderBucket(data['today'], pid, pname, merged);
          _appendReminderBucket(data['upcoming'], pid, pname, merged);
          final notesResp = await http.get(
            Uri.parse(
                '${Environment.apiBaseUrl}/api/caregiver-notes?patient_id=$pid'),
            headers: headers,
          );
          if (notesResp.statusCode == 200) {
            final body = jsonDecode(notesResp.body);
            if (body is List) {
              for (final item in body) {
                if (item is Map) {
                  final note = Map<String, dynamic>.from(item);
                  note['_patient_id'] = pid;
                  note['_patient_name'] = pname;
                  mergedNotes.add(note);
                }
              }
            }
          }
        } catch (_) {}
      }
      merged.sort((a, b) {
        final ta = DateTime.tryParse(a['scheduled_time']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final tb = DateTime.tryParse(b['scheduled_time']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return ta.compareTo(tb);
      });
      mergedNotes.sort((a, b) {
        final ta = DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final tb = DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });
      final appts = merged
          .where(
              (r) => (r['reminder_type'] ?? '').toString() == 'appointment')
          .take(4)
          .toList();
      if (!mounted) return;
      setState(() {
        _homeReminders = merged
            .where(
                (r) => (r['reminder_type'] ?? '').toString() != 'appointment')
            .take(6)
            .toList();
        _homeAppointments = appts;
        _homeNotes = mergedNotes.take(4).toList();
        _isLoadingHomeReminders = false;
      });

      await ReminderNotificationSync.syncCaregiverFromMergedList(merged);
    } catch (_) {
      if (mounted) setState(() => _isLoadingHomeReminders = false);
    }
  }

  int get _unreadSumFromPatients => _patients.fold<int>(
      0, (s, p) => s + ((p['unread_alerts'] as num?)?.toInt() ?? 0));

  int get _dueSoonSumFromPatients => _patients.fold<int>(
      0, (s, p) => s + ((p['reminders_due_soon'] as num?)?.toInt() ?? 0));

  Future<void> _loadInvitations() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoadingInvitations = true;
      });
      final invitations = await CareTeamApiService().getMyInvitations();
      if (!mounted) return;
      setState(() {
        _invitations = invitations
            .where((i) => i.status.toLowerCase() == 'pending')
            .toList();
        _isLoadingInvitations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInvitations = false;
      });
    }
  }

  Future<void> _loadPatients() async {
    try {
      if (!mounted) return;
      setState(() {
        _isLoadingPatients = true;
      });
      final patients = await CareTeamApiService().getMyPatients();
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _isLoadingPatients = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingPatients = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final profileName = authState.profile?.fullName?.trim();
    final userFullName = authState.user?.fullName?.trim();
    final userDisplayName = authState.user?.displayName.trim();
    final userEmail = authState.user?.email.trim();
    final userName = (profileName != null && profileName.isNotEmpty)
        ? profileName
        : (userFullName != null && userFullName.isNotEmpty)
            ? userFullName
            : (userDisplayName != null && userDisplayName.isNotEmpty)
                ? userDisplayName
                : (userEmail != null && userEmail.isNotEmpty)
                    ? userEmail.split('@').first
                    : 'Caregiver';
    final greeting = GreetingUtils.getTimeBasedGreeting();
    final firstName = userName.split(' ').first;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          Container(
            color: Colors.transparent,
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)
                    .copyWith(top: MediaQuery.of(context).padding.top + 16.0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        greeting,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              firstName,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            '✨',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                      Text(
                        'Caregiver dashboard',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.secondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: () => context.go('/caregiver/alerts'),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isLoadingInvitations && _invitations.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildInvitationsSection(),
                    const SizedBox(height: 32),
                  ],
                  const SectionHeader(
                    title: 'Recent Alerts',
                    icon: Icons.notifications,
                  ),
                  const SizedBox(height: 16),
                  _buildAlertsSection(),
                  const SizedBox(height: 32),
                  const SectionHeader(
                    title: 'My Patients',
                    icon: Icons.people,
                  ),
                  const SizedBox(height: 16),
                  _buildPatientList(),
                  const SizedBox(height: 32),
                  const SectionHeader(
                    title: 'Today\'s Care Items',
                    icon: Icons.task,
                  ),
                  const SizedBox(height: 16),
                  _buildCareTasks(),
                  const SizedBox(height: 32),
                  const SectionHeader(
                    title: 'Upcoming Appointments',
                    icon: Icons.calendar_today,
                  ),
                  const SizedBox(height: 16),
                  _buildUpcomingAppointments(),
                  const SizedBox(height: 32),
                  const SectionHeader(
                    title: 'Quick Actions',
                    icon: Icons.flash_on,
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(),
                  const SizedBox(height: 32),
                  const SectionHeader(
                    title: 'Care Summary',
                    icon: Icons.analytics,
                  ),
                  const SizedBox(height: 16),
                  _buildCaregiverStats(),
                  const SizedBox(height: 120),
                ],
              ),
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvitationsSection() {
    final pendingInvitations = _invitations.length;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1A4D4D), // Dark teal-green
            Color(0xFF051818), // Very dark green/black
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: const Border(
          top: BorderSide(
            color: Colors.white,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mail,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Pending Invitations',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '$pendingInvitations invitation${pendingInvitations > 1 ? 's' : ''} waiting',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Review and accept caregiver invitations.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go('/caregiver/accept-invitations'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: const Text(
              'View Invitations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isLoadingAlerts
                      ? 'Alerts'
                      : 'Alerts ($_unreadAlertsTotal unread)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/caregiver/alerts'),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingAlerts)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_recentAlerts.isEmpty)
            Text(
              'No alerts yet. Skips and other events will appear here.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontSize: 14,
              ),
            )
          else
            Column(
              children: _recentAlerts.map((a) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        a.read ? Icons.notifications_none : Icons.circle,
                        size: 14,
                        color: a.read
                            ? Theme.of(context).colorScheme.secondary
                            : Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.message,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${a.alertType} · ${_formatShortTime(a.sentAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.go('/caregiver/alerts'),
              child: const Text('Open Alerts'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatShortTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.month}/${local.day} ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  // Section headers use shared SectionHeader widget for consistency

  Widget _buildPatientList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoadingPatients
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_patients.isEmpty)
                  Text(
                    'No patients yet',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  )
                else
                  ...(_patients.take(3).toList().asMap().entries.map((entry) {
                    final p = entry.value;
                    final name = (p['full_name'] as String?)?.trim().isNotEmpty == true
                        ? p['full_name'] as String
                        : (p['email'] as String?) ?? 'Unknown';
                    final relationship =
                        p['relationship']?.toString() ?? 'Patient';
                    final unread =
                        (p['unread_alerts'] as num?)?.toInt() ?? 0;
                    final dueSoon =
                        (p['reminders_due_soon'] as num?)?.toInt() ?? 0;
                    final statusType =
                        (unread > 0 || dueSoon > 0) ? 'attention' : 'active';
                    final parts = <String>[];
                    if (dueSoon > 0) {
                      parts.add(
                          '$dueSoon reminder${dueSoon == 1 ? '' : 's'} due soon');
                    }
                    if (unread > 0) {
                      parts.add(
                          '$unread unread alert${unread == 1 ? '' : 's'}');
                    }
                    if (parts.isEmpty) {
                      parts.add('All caught up');
                    }
                    final statusText = parts.join(' · ');
                    final pid = p['patient_id']?.toString() ?? '';
                    final lastActivity = _parseLastActivityAt(p['last_activity_at']);
                    final lastVisitLine = lastActivity != null
                        ? 'Last activity · ${_formatRelativeActivity(lastActivity)}'
                        : 'Last activity · —';
                    return Column(
                      children: [
                        if (entry.key > 0) const Divider(height: 16),
                        _buildPatientCard(
                          name: name,
                          relationship: relationship,
                          status: statusText,
                          statusType: statusType,
                          patientId: pid.isEmpty ? null : pid,
                          lastVisitLine: lastVisitLine,
                          remindersDueSoon: dueSoon,
                          alertCount: unread,
                        ),
                      ],
                    );
                  })),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => context.go('/caregiver/patients'),
                  child: Text(
                    'View All Patients',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  DateTime? _parseLastActivityAt(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  /// Same relative phrasing as patient list "Last visit" row (PRD: last visit / recent activity).
  String _formatRelativeActivity(DateTime lastVisit) {
    final now = DateTime.now();
    final difference = now.difference(lastVisit).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    }
    final months = (difference / 30).floor();
    return '$months month${months > 1 ? 's' : ''} ago';
  }

  Widget _buildPatientCard({
    required String name,
    required String relationship,
    required String status,
    required String statusType,
    String? patientId,
    required String lastVisitLine,
    required int remindersDueSoon,
    required int alertCount,
  }) {
    return InkWell(
      onTap: patientId == null || patientId.isEmpty
          ? null
          : () async {
              await context.push(
                  '/caregiver/patient-overview?patientId=$patientId');
              if (mounted) await _refreshDashboard();
            },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            // Patient Avatar with Status Indicator
            Stack(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: _getStatusColor(statusType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Icon(
                    Icons.person,
                    color: _getStatusColor(statusType),
                    size: 24,
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _getStatusIndicatorColor(statusType),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      _getStatusIcon(statusType),
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Patient Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    relationship,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lastVisitLine,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reminders due (48h): $remindersDueSoon · Alerts (unread): $alertCount',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 12,
                            color: _getStatusTextColor(statusType),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String statusType) {
    switch (statusType) {
      case 'active':
        return Colors.green;
      case 'attention':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  Color _getStatusIndicatorColor(String statusType) {
    switch (statusType) {
      case 'active':
        return Colors.green;
      case 'attention':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusTextColor(String statusType) {
    switch (statusType) {
      case 'active':
        return Colors.green;
      case 'attention':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  IconData _getStatusIcon(String statusType) {
    switch (statusType) {
      case 'active':
        return Icons.check;
      case 'attention':
        return Icons.warning;
      case 'critical':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Widget _buildCareTasks() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoadingHomeReminders
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          : _homeReminders.isEmpty && _homeNotes.isEmpty
              ? Text(
                  'No upcoming tasks or notes for your top patients.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                )
              : Column(
                  children: [
                    if (_homeReminders.isNotEmpty)
                      ..._homeReminders.asMap().entries.map((e) {
                        final r = e.value;
                        final title =
                            (r['title'] as String?)?.trim().isNotEmpty == true
                                ? r['title'] as String
                                : 'Reminder';
                        final st = (DateTime.tryParse(
                                    r['scheduled_time']?.toString() ?? '') ??
                                DateTime.now())
                            .toLocal();
                        final patient =
                            (r['_patient_name'] as String?)?.trim() ?? 'Patient';
                        final type = (r['reminder_type'] ?? 'task').toString();
                        return Column(
                          children: [
                            if (e.key > 0) const Divider(height: 16),
                            _buildTaskItemReadOnly(
                              title: title,
                              details: '$patient · $type',
                              time: _formatShortTime(st),
                            ),
                          ],
                        );
                      }),
                    if (_homeNotes.isNotEmpty) ...[
                      if (_homeReminders.isNotEmpty) const Divider(height: 20),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Recent notes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ),
                      ),
                      ..._homeNotes.asMap().entries.map((e) {
                        final n = e.value;
                        final title =
                            (n['title'] as String?)?.trim().isNotEmpty == true
                                ? n['title'] as String
                                : 'Private note';
                        final content = (n['content'] as String?)?.trim() ?? '';
                        final patient =
                            (n['_patient_name'] as String?)?.trim() ?? 'Patient';
                        final createdAt = (DateTime.tryParse(
                                    n['created_at']?.toString() ?? '') ??
                                DateTime.now())
                            .toLocal();
                        return Column(
                          children: [
                            if (e.key > 0) const Divider(height: 16),
                            _buildTaskItemReadOnly(
                              title: title,
                              details: '$patient · ${content.isEmpty ? 'Note' : content}',
                              time: _formatShortTime(createdAt),
                            ),
                          ],
                        );
                      }),
                    ],
                  ],
                ),
    );
  }

  Widget _buildTaskItemReadOnly({
    required String title,
    required String details,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.schedule,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                details,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context)
                      .colorScheme
                      .secondary
                      .withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingAppointments() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: _isLoadingHomeReminders
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          : _homeAppointments.isEmpty
              ? Text(
                  'No appointment-type reminders in the next two weeks.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                )
              : Column(
                  children: _homeAppointments.asMap().entries.map((e) {
                    final r = e.value;
                    final patient =
                        (r['_patient_name'] as String?)?.trim() ?? 'Patient';
                    final title =
                        (r['title'] as String?)?.trim().isNotEmpty == true
                            ? r['title'] as String
                            : 'Appointment';
                    final st = (DateTime.tryParse(
                                r['scheduled_time']?.toString() ?? '') ??
                            DateTime.now())
                        .toLocal();
                    final msg = (r['message'] as String?)?.trim() ?? '';
                    return Column(
                      children: [
                        if (e.key > 0) const SizedBox(height: 16),
                        _buildAppointmentItem(
                          patient,
                          title,
                          _formatShortTime(st),
                          msg.isNotEmpty ? msg : 'Reminder',
                        ),
                      ],
                    );
                  }).toList(),
                ),
    );
  }

  Widget _buildAppointmentItem(String patient, String appointmentType,
      String dateTime, String location) {
    return Row(
      children: [
        // Calendar Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.calendar_today,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        // Appointment Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                patient,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                appointmentType,
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              Text(
                '$dateTime • $location',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionItem(
          'Add Patient',
          Icons.person_add,
          () {},
        ),
        _buildQuickActionItem(
          'Schedule',
          Icons.schedule,
          () => context.go('/caregiver/reminders-timeline'),
        ),
        _buildQuickActionItem(
          'Messages',
          Icons.message,
          () {},
        ),
        _buildQuickActionItem(
          'Reports',
          Icons.bar_chart,
          () {},
        ),
      ],
    );
  }

  Widget _buildQuickActionItem(
      String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCaregiverStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStat(
            'Active Patients',
            _isLoadingPatients ? '…' : _patients.length.toString(),
            Icons.people,
          ),
          _buildStat(
            'Unread alerts',
            _unreadSumFromPatients.toString(),
            Icons.notifications_active,
          ),
          _buildStat(
            'Due soon',
            _dueSoonSumFromPatients.toString(),
            Icons.task_alt,
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
