import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../care_team/data/services/care_team_api_service.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';

  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _allPatients = [];

  DateTime? _lastActivityOf(Map<String, dynamic> patient) {
    final raw = patient['lastActivityAt'];
    if (raw == null) return null;
    if (raw is DateTime) return raw;
    return DateTime.tryParse(raw.toString());
  }

  List<Map<String, dynamic>> get _filteredPatients {
    var patients = _allPatients;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      patients = patients.where((patient) {
        final name = patient['name'].toLowerCase();
        final email = (patient['email'] as String).toLowerCase();
        final relationship = patient['relationship'].toLowerCase();
        final condition = patient['condition'].toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            email.contains(query) ||
            relationship.contains(query) ||
            condition.contains(query);
      }).toList();
    }

    // Apply status filter
    if (_selectedFilter != 'All') {
      patients = patients
          .where(
              (patient) => patient['status'] == _selectedFilter.toLowerCase())
          .toList();
    }

    patients.sort((a, b) {
      final da = _lastActivityOf(a);
      final db = _lastActivityOf(b);
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });

    return patients;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final rawPatients = await CareTeamApiService().getMyPatients();
      if (!mounted) return;

      final activeOnly = rawPatients.where((p) {
        final st = (p['membership_status'] ?? 'active').toString().toLowerCase();
        return st == 'active';
      });

      setState(() {
        _allPatients = activeOnly.map(_mapRawPatient).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => context.go('/caregiver/home'),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My Patients',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              'Assigned patients',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withOpacity(0.65),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.calendar_view_week,
              color: Theme.of(context).colorScheme.primary,
            ),
            tooltip: 'Reminder timeline',
            onPressed: () => context.go('/caregiver/reminders-timeline'),
          ),
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText:
                    'Search by name, email, relationship, or condition...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.withOpacity(0.1),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),

          // Results Count (avoid "0 Patients" flash while the list is still loading)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                if (_isLoading)
                  Text(
                    'Loading…',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                else
                  Text(
                    '${_filteredPatients.length} ${_filteredPatients.length == 1 ? 'Patient' : 'Patients'}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                if (!_isLoading && _selectedFilter != 'All') ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getFilterColor(_selectedFilter).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _selectedFilter,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getFilterColor(_selectedFilter),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (!_isLoading && _selectedFilter != 'All')
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 'All';
                      });
                    },
                    child: const Text('Clear Filter'),
                  ),
              ],
            ),
          ),

          // Patient List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildErrorState()
                    : _allPatients.isEmpty && _searchQuery.isEmpty
                        ? RefreshIndicator(
                            onRefresh: _loadPatients,
                            child: ListView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              children: [
                                SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height * 0.2,
                                ),
                                _buildRosterEmptyState(),
                              ],
                            ),
                          )
                        : _filteredPatients.isEmpty
                            ? _buildNoMatchesEmptyState()
                            : RefreshIndicator(
                                onRefresh: _loadPatients,
                                child: ListView.builder(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  itemCount: _filteredPatients.length,
                                  itemBuilder: (context, index) {
                                    final patient = _filteredPatients[index];
                                    return _buildPatientCard(patient);
                                  },
                                ),
                              ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/caregiver/accept-invitations'),
        tooltip: 'View invitations',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.mail_outline),
      ),
    );
  }

  Widget _buildRosterEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 80,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No patients yet',
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'When a patient invites you, accept the invite to see them here.',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () => context.go('/caregiver/accept-invitations'),
            icon: const Icon(Icons.inbox),
            label: const Text('View Invitations'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMatchesEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No patients match your search or filter',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or clear the filter',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              _error ?? 'Failed to load patients',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPatients,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPatientCard(Map<String, dynamic> patient) {
    final status = patient['status'] as String;
    final upcomingAppointments = patient['upcomingAppointments'] as int;
    final remindersDue = patient['remindersDueSoon'] as int;
    final unreadAlerts = patient['unreadAlerts'] as int;
    final lastVisitAt = patient['lastVisitAt'] as DateTime?;
    final patientId = patient['id'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () =>
            context.go('/caregiver/patient-overview?patientId=$patientId'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header Row
              Row(
                children: [
                  // Avatar with Status
                  Stack(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Icon(
                          Icons.person,
                          color: _getStatusColor(status),
                          size: 30,
                        ),
                      ),
                      if (unreadAlerts > 0)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unreadAlerts.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  // Patient Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                patient['name'],
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _getStatusColor(status),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if ((patient['email'] as String).isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            patient['email'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                        Text(
                          '${patient['relationship']} • Age ${patient['age']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        Text(
                          patient['condition'],
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
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Symptom log',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                        icon: Icon(
                          Icons.healing_outlined,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        onPressed: () => context.go(
                          '/caregiver/patient-overview?patientId=$patientId&tab=symptoms',
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.5),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Stats row (acceptance: last visit, reminders due, alert count)
              Row(
                children: [
                  _buildStatItem(
                    'Last visit',
                    _formatLastVisitNullable(lastVisitAt),
                    Theme.of(context).colorScheme.primary,
                  ),
                  _buildStatItem(
                    'Reminders due',
                    remindersDue.toString(),
                    remindersDue > 0 ? Colors.orange : Colors.grey,
                  ),
                  _buildStatItem(
                    'Alerts',
                    unreadAlerts.toString(),
                    unreadAlerts > 0 ? Colors.red : Colors.grey,
                  ),
                ],
              ),

              _buildRecentActivitiesSection(patient),

              // Quick Actions
              if (unreadAlerts > 0 ||
                  upcomingAppointments > 0 ||
                  remindersDue > 0) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (unreadAlerts > 0)
                      OutlinedButton.icon(
                        onPressed: () => _viewAlerts(patient),
                        icon: const Icon(Icons.notifications, size: 16),
                        label: Text(
                          'View $unreadAlerts alert${unreadAlerts == 1 ? '' : 's'}',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    if (remindersDue > 0)
                      OutlinedButton.icon(
                        onPressed: () => _viewRemindersDue(patient),
                        icon: const Icon(Icons.alarm, size: 16),
                        label: Text('$remindersDue reminders due'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    if (upcomingAppointments > 0)
                      OutlinedButton.icon(
                        onPressed: () => _viewAppointments(patient),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          '$upcomingAppointments appointment${upcomingAppointments == 1 ? '' : 's'}',
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection(Map<String, dynamic> patient) {
    final items = patient['recentActivities'] as List<dynamic>? ?? [];
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'No recent activity logged yet.',
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.75),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 14),
        Text(
          'Recent activity',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        ...items.map((raw) {
          if (raw is! Map) return const SizedBox.shrink();
          final e = Map<String, dynamic>.from(raw);
          return _buildActivityRow(e);
        }),
      ],
    );
  }

  Widget _buildActivityRow(Map<String, dynamic> e) {
    final type = e['type']?.toString() ?? 'event';
    final summary = e['summary']?.toString() ?? '';
    final at = DateTime.tryParse(e['occurred_at']?.toString() ?? '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            _activityIcon(type),
            size: 18,
            color: Theme.of(context).colorScheme.secondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  summary,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.25,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (at != null)
                  Text(
                    _formatActivityTimestamp(at),
                    style: TextStyle(
                      fontSize: 11,
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

  IconData _activityIcon(String type) {
    switch (type) {
      case 'alert':
        return Icons.notifications_active_outlined;
      case 'reminder':
        return Icons.alarm_on_outlined;
      case 'visit':
        return Icons.local_hospital_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  String _formatActivityTimestamp(DateTime at) {
    final local = at.toLocal();
    final now = DateTime.now();
    final sameDay = local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
    if (sameDay) {
      final t =
          '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
      return 'Today · $t';
    }
    return _formatLastVisit(local);
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Patients'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('All'),
            _buildFilterOption('Active'),
            _buildFilterOption('Attention'),
            _buildFilterOption('Critical'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(String filter) {
    return RadioListTile<String>(
      title: Text(filter),
      value: filter,
      groupValue: _selectedFilter,
      onChanged: (value) {
        setState(() {
          _selectedFilter = value!;
        });
        Navigator.of(context).pop();
      },
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  void _viewAlerts(Map<String, dynamic> patient) {
    final id = patient['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final name = Uri.encodeComponent(patient['name']?.toString() ?? 'Patient');
    context.go('/caregiver/alerts?patientId=$id&patientName=$name');
  }

  void _viewAppointments(Map<String, dynamic> patient) {
    final id = patient['id']?.toString() ?? '';
    if (id.isEmpty) return;
    context.go('/caregiver/reminders-timeline?patientId=$id&type=appointment');
  }

  void _viewRemindersDue(Map<String, dynamic> patient) {
    context.go(
      '/caregiver/reminders-timeline?patientId=${patient['id']}',
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
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

  Color _getFilterColor(String filter) {
    switch (filter.toLowerCase()) {
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

  String _formatLastVisitNullable(DateTime? lastVisit) {
    if (lastVisit == null) {
      return '—';
    }
    return _formatLastVisit(lastVisit);
  }

  String _formatLastVisit(DateTime lastVisit) {
    final now = DateTime.now();
    final difference = now.difference(lastVisit).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference < 7) {
      return '$difference days ago';
    } else if (difference < 30) {
      final weeks = (difference / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else {
      final months = (difference / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    }
  }

  Map<String, dynamic> _mapRawPatient(Map<String, dynamic> p) {
    final unread = (p['unread_alerts'] as num?)?.toInt() ?? 0;
    final dueSoon = (p['reminders_due_soon'] as num?)?.toInt() ?? 0;
    final status =
        (unread > 0 || dueSoon > 0) ? 'attention' : 'active';
    DateTime? lastAct;
    final la = p['last_activity_at'];
    if (la != null) {
      lastAct = DateTime.tryParse(la.toString());
    }
    DateTime? lastVisitAt;
    final lv = p['last_visit_at'];
    if (lv != null) {
      lastVisitAt = DateTime.tryParse(lv.toString());
    }
    final email = (p['email'] ?? '')?.toString() ?? '';
    return {
      'id': (p['id'] ?? p['patient_id'])?.toString() ?? '',
      'name':
          (p['full_name'] ?? p['name'] ?? p['email'] ?? 'Unknown')?.toString(),
      'email': email,
      'age': 0,
      'relationship': (p['relationship'] ?? 'Patient')?.toString(),
      'condition': 'Care team member',
      'status': status,
      'lastVisitAt': lastVisitAt,
      'lastActivityAt': lastAct,
      'medicationAdherence': (p['medication_adherence'] as num?)?.toInt() ?? 0,
      'upcomingAppointments':
          (p['upcoming_appointments'] as num?)?.toInt() ?? 0,
      'remindersDueSoon': dueSoon,
      'unreadAlerts': unread,
      'recentActivities': _parseRecentActivitiesJson(p['recent_activities']),
      'phone': '',
      'emergencyContact': '',
    };
  }

  /// Backend returns JSON array (or string) of `{type, summary, occurred_at}`.
  List<Map<String, dynamic>> _parseRecentActivitiesJson(dynamic raw) {
    if (raw == null) return [];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .toList();
    }
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded
              .whereType<Map>()
              .map((m) => Map<String, dynamic>.from(m))
              .toList();
        }
      } catch (_) {
        return [];
      }
    }
    return [];
  }
}
