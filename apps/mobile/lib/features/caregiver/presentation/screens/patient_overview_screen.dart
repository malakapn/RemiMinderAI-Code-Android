import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../patient/data/models/summary_item.dart';
import '../../data/services/caregiver_api_service.dart';

class PatientOverviewScreen extends StatefulWidget {
  const PatientOverviewScreen({super.key});

  @override
  State<PatientOverviewScreen> createState() => _PatientOverviewScreenState();
}

class _PatientOverviewScreenState extends State<PatientOverviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _patientId;
  String _patientName = '';
  bool _hasLoaded = false;
  bool _isLoading = true;
  String? _visitsError;
  String? _remindersError;

  List<Map<String, dynamic>> _visits = [];
  List<Map<String, dynamic>> _reminders = [];
  DateTime? _lastVisitDate;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasLoaded) return;

    final l10n = AppLocalizations.of(context)!;
    _patientName = l10n.defaultPatient;
    _patientId = GoRouterState.of(context).uri.queryParameters['patientId'];

    if (_patientId != null && _patientId!.isNotEmpty) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(_patientId)
          .get()
          .then((doc) {
        if (doc.exists && mounted) {
          setState(() {
            _patientName = (doc.data()?['displayName'] ??
                    doc.data()?['fullName'] ??
                    l10n.defaultPatient)
                .toString();
          });
        }
      });
    }

    _hasLoaded = true;
    _loadPatientData();

    final tab = GoRouterState.of(context).uri.queryParameters['tab'];
    if (tab == 'reminders') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tabController.index = 1;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPatientData() async {
    final l10n = AppLocalizations.of(context)!;

    if (_patientId == null || _patientId!.isEmpty) {
      setState(() {
        _visitsError = l10n.patientOverviewMissingPatientId;
        _remindersError = l10n.patientOverviewMissingPatientId;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _visitsError = null;
      _remindersError = null;
    });

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) throw Exception('Authentication required');
      final authToken = await firebaseUser.getIdToken(true);
      if (authToken == null) throw Exception('Failed to get auth token');

      final apiService = CaregiverApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: authToken,
      );

      try {
        await apiService.syncPatientAccess(_patientId!);
      } catch (e) {
        debugPrint('Patient access sync failed: $e');
      }

      final visits = await _loadVisits(apiService);
      final reminders = await _loadReminders(apiService);

      if (!mounted) return;
      setState(() {
        _visits = visits;
        _reminders = reminders;
        _lastVisitDate =
            _visits.isNotEmpty ? _visits.first['date'] as DateTime? : null;
        _isLoading = false;
      });

      if (_visitsError == null || _remindersError == null) {
        await _markPatientSynced();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _visitsError = e.toString();
        _remindersError = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _loadVisits(
    CaregiverApiService apiService,
  ) async {
    try {
      final summaries = await apiService.getPatientSummaries(_patientId!);
      if (mounted) setState(() => _visitsError = null);
      final l10n = AppLocalizations.of(context)!;
      return summaries
          .map((s) => _mapSummaryToVisit(s, l10n.doctorVisit))
          .toList();
    } catch (e) {
      if (mounted) {
        setState(() => _visitsError = _friendlyLoadError(e));
      }
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadReminders(
    CaregiverApiService apiService,
  ) async {
    try {
      final payload = await apiService.getPatientReminders(_patientId!);
      if (mounted) setState(() => _remindersError = null);
      return _flattenReminders(payload);
    } catch (e) {
      if (mounted) {
        setState(() => _remindersError = _friendlyLoadError(e));
      }
      return [];
    }
  }

  String _friendlyLoadError(Object error) {
    final message = error.toString();
    if (message.contains('403')) {
      return 'Unable to load patient data. Ask the patient to confirm your care team access.';
    }
    if (message.contains('404')) {
      return 'Patient data is not available yet.';
    }
    if (message.contains('401')) {
      if (message.contains('client does not have permission to')) {
        return 'Cannot reach the server right now. Try again in a moment.';
      }
      return 'Your session expired. Sign out and sign in again.';
    }
    if (message.contains('500')) {
      return 'Server error while loading patient data. Try again in a moment.';
    }
    return 'Could not load patient data. Pull to refresh or try again later.';
  }

  Future<void> _markPatientSynced() async {
    final caregiverId = FirebaseAuth.instance.currentUser?.uid;
    final patientId = _patientId;
    if (caregiverId == null || patientId == null || patientId.isEmpty) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(caregiverId)
          .collection('connectedPatients')
          .doc(patientId)
          .set(
        {'lastSyncedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('Failed to update patient sync timestamp: $e');
    }
  }

  List<Map<String, dynamic>> _flattenReminders(Map<String, dynamic> payload) {
    final sections = ['today', 'upcoming', 'past'];
    final flattened = <Map<String, dynamic>>[];

    for (final section in sections) {
      final items = payload[section];
      if (items is! List) continue;
      for (final item in items) {
        if (item is Map<String, dynamic>) {
          flattened.add(item);
        } else if (item is Map) {
          flattened.add(Map<String, dynamic>.from(item));
        }
      }
    }

    return flattened;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(
                  Icons.arrow_back,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () => context.go('/caregiver/patients'),
              ),
              title: Text(
                l10n.patientOverviewTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            SliverToBoxAdapter(child: _buildPatientHeader(l10n)),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      text: l10n.patientOverviewTabVisits,
                      icon: const Icon(Icons.medical_services),
                    ),
                    Tab(
                      text: l10n.patientOverviewTabReminders,
                      icon: const Icon(Icons.notifications),
                    ),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor:
                      Theme.of(context).colorScheme.secondary,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildVisitsTab(l10n),
            _buildRemindersTab(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientHeader(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.all(16),
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
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(36),
            ),
            child: Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
              size: 36,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _patientName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.patientOverviewCareTeam,
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${l10n.patientOverviewLastVisit}: ${_formatLastVisit(l10n)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisitsTab(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_visitsError != null) {
      return _buildErrorState(_visitsError!, l10n);
    }
    if (_visits.isEmpty) {
      return _buildRefreshable(
        child: _buildScrollableBody(
          child: Text(l10n.patientOverviewNoVisits),
        ),
      );
    }

    return _buildRefreshable(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _visits.length,
        itemBuilder: (context, index) {
        final visit = _visits[index];
        final primary = Theme.of(context).colorScheme.primary;
        final visitTitle = visit['displayTitle'] as String? ?? l10n.doctorVisit;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.medical_services, color: primary),
            ),
            title: Text(
              visitTitle,
              style: TextStyle(fontWeight: FontWeight.w600, color: primary),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatDate(visit['date'] as DateTime, l10n),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Text(
                  visit['summary'] as String? ?? '',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if ((visit['summary'] as String? ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'AI-generated summary. Not a substitute for professional medical advice.',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
            onTap: () => _viewVisitDetails(visit),
          ),
        );
      },
      ),
    );
  }

  Widget _buildRemindersTab(AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_remindersError != null) {
      return _buildErrorState(_remindersError!, l10n);
    }
    if (_reminders.isEmpty) {
      return _buildRefreshable(
        child: _buildScrollableBody(
          child: Text(l10n.patientOverviewNoReminders),
        ),
      );
    }

    return _buildRefreshable(
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _reminders.length,
        itemBuilder: (context, index) {
        final reminder = _reminders[index];
        final type = (reminder['reminder_type'] ?? reminder['type'] ?? '')
            .toString();
        final status =
            (reminder['display_status'] ?? reminder['status'] ?? 'pending')
                .toString();
        final scheduledTime = LocaleFormat.parseScheduledTime(reminder);
        final relativeTime = LocaleFormat.reminderRelativeTime(
          context,
          scheduledTime,
          l10n,
        );
        final statusLabel = LocaleFormat.reminderStatusLabel(l10n, status);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _getReminderTypeColor(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getReminderTypeIcon(type),
                color: _getReminderTypeColor(type),
              ),
            ),
            title: Text(
              (reminder['title'] ?? l10n.patientOverviewTabReminders)
                  .toString(),
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (relativeTime.isNotEmpty)
                  Text(
                    relativeTime,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  )
                else if (scheduledTime != null)
                  Text(
                    LocaleFormat.time(context, scheduledTime),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                Text(
                  l10n.patientOverviewScheduledReminder,
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .secondary
                        .withOpacity(0.8),
                  ),
                ),
              ],
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getReminderStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 10,
                  color: _getReminderStatusColor(status),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildRefreshable({required Widget child}) {
    return RefreshIndicator(
      onRefresh: _loadPatientData,
      child: child,
    );
  }

  Widget _buildScrollableBody({required Widget child}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.45,
          child: Center(child: child),
        ),
      ],
    );
  }

  Widget _buildErrorState(String message, AppLocalizations l10n) {
    return _buildRefreshable(
      child: _buildScrollableBody(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loadPatientData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewVisitDetails(Map<String, dynamic> visit) {
    final visitId = visit['id']?.toString();
    if (visitId == null || visitId.isEmpty || _patientId == null) return;

    final date = visit['date'] as DateTime?;
    final visitDate = date != null
        ? DateFormat('yyyy-MM-dd').format(date)
        : null;

    final params = <String, String>{
      'visitId': visitId,
      'patientId': _patientId!,
      if (visitDate != null) 'visitDate': visitDate,
    };

    context.push(
      Uri(
        path: '/caregiver/visit-details',
        queryParameters: params,
      ).toString(),
    );
  }

  Color _getReminderTypeColor(String type) {
    switch (type) {
      case 'medication':
        return Colors.blue;
      case 'appointment':
        return Colors.purple;
      case 'measurement':
        return Colors.green;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getReminderTypeIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.calendar_today;
      case 'measurement':
        return Icons.monitor_heart;
      default:
        return Icons.notifications;
    }
  }

  Color _getReminderStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('due') || normalized == 'active') {
      return Colors.green;
    }
    if (normalized.contains('upcoming') || normalized == 'pending') {
      return Colors.blue;
    }
    if (normalized.contains('missed') || normalized.contains('overdue')) {
      return Colors.red;
    }
    if (normalized.contains('complete')) {
      return Colors.grey;
    }
    return Colors.grey;
  }

  String _formatLastVisit(AppLocalizations l10n) {
    final date = _lastVisitDate;
    if (date == null) return l10n.patientOverviewNever;
    return _formatDate(date, l10n);
  }

  String _formatDate(DateTime date, AppLocalizations l10n) {
    return LocaleFormat.visitRelativeDate(context, date, l10n);
  }

  Map<String, dynamic> _mapSummaryToVisit(
    SummaryItem summary,
    String fallbackVisitLabel,
  ) {
    final dateSource = summary.visitDate ?? summary.summaryCreatedAt;
    final parsedDate = DateTime.tryParse(dateSource) ?? DateTime.now();
    return {
      'id': summary.visitId,
      'doctor': summary.doctorName,
      'specialty': summary.specialty,
      'date': parsedDate,
      'type': summary.specialty.isNotEmpty ? summary.specialty : 'Visit',
      'summary': summary.summaryPreview,
      'displayTitle': summary.visitDisplayLabel(fallbackVisitLabel),
    };
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
