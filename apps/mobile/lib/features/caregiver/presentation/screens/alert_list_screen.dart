import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/theme.dart';
import '../../../../core/widgets/remi_shell_ui.dart';
import '../../../../core/services/backend_api_service.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../../l10n/app_localizations.dart';

enum _AlertFilter { all, unread, read, highPriority }

class AlertListScreen extends StatefulWidget {
  const AlertListScreen({super.key});

  @override
  State<AlertListScreen> createState() => _AlertListScreenState();
}

class _AlertListScreenState extends State<AlertListScreen> {
  _AlertFilter _selectedFilter = _AlertFilter.all;
  bool _isLoading = true;
  String? _caregiverId;

  List<Map<String, dynamic>> _allAlerts = [];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      _caregiverId = uid;
      final alerts = await BackendApiService().getCaregiverAlerts(uid);
      if (!mounted) return;
      setState(() {
        _allAlerts = alerts.map(_normalizeAlert).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Map<String, dynamic> _normalizeAlert(Map<String, dynamic> raw) {
    final sentAt = raw['sent_at'] ?? raw['created_at'];
    DateTime timestamp = DateTime.now();
    if (sentAt != null) {
      timestamp = DateTime.tryParse(sentAt.toString()) ?? timestamp;
    }

    final patientId = raw['user_id'] ??
        raw['patient_id'] ??
        raw['patientId'] ??
        '';
    final alertType = raw['alert_type'] ?? raw['type'] ?? 'general';

    return {
      'id': raw['id']?.toString() ?? '',
      'type': alertType.toString(),
      'message': raw['message']?.toString() ?? raw['description']?.toString() ?? '',
      'patient': raw['patient_name'] ?? raw['patientName'] ?? 'Patient',
      'patientId': patientId.toString(),
      'timestamp': timestamp,
      'priority': raw['priority'] ?? 'medium',
      'isRead': raw['read'] == true || raw['is_read'] == true || raw['isRead'] == true,
      'actionRequired': raw['action_required'] == true || raw['actionRequired'] == true,
      'category': raw['category'] ?? alertType.toString(),
    };
  }

  // kept for backwards compat
  final List<Map<String, dynamic>> _mockAlerts = [
    {
      'id': '1',
      'type': 'medication',
      'message': 'John Doe missed Lisinopril 10mg medication - due 2 hours ago',
      'patient': 'John Doe',
      'patientId': '1',
      'timestamp': DateTime.now().subtract(const Duration(hours: 2)),
      'priority': 'high',
      'isRead': false,
      'actionRequired': true,
      'category': 'adherence',
    },
    {
      'id': '2',
      'type': 'appointment',
      'message': 'Sarah Johnson has cardiology appointment tomorrow at 2:30 PM',
      'patient': 'Sarah Johnson',
      'patientId': '2',
      'timestamp': DateTime.now().add(const Duration(hours: 6)),
      'priority': 'medium',
      'isRead': true,
      'actionRequired': false,
      'category': 'appointment',
    },
    {
      'id': '3',
      'type': 'measurement',
      'message': 'Mike Chen blood pressure reading is overdue - due yesterday',
      'patient': 'Mike Chen',
      'patientId': '3',
      'timestamp': DateTime.now().subtract(const Duration(hours: 26)),
      'priority': 'high',
      'isRead': false,
      'actionRequired': true,
      'category': 'monitoring',
    },
    {
      'id': '4',
      'type': 'medication',
      'message':
          'Elizabeth Wilson has low medication adherence - 65% this week',
      'patient': 'Elizabeth Wilson',
      'patientId': '4',
      'timestamp': DateTime.now().subtract(const Duration(hours: 4)),
      'priority': 'medium',
      'isRead': false,
      'actionRequired': true,
      'category': 'adherence',
    },
    {
      'id': '5',
      'type': 'visit',
      'message':
          'David Brown completed doctor visit - review summary available',
      'patient': 'David Brown',
      'patientId': '5',
      'timestamp': DateTime.now().subtract(const Duration(hours: 1)),
      'priority': 'low',
      'isRead': true,
      'actionRequired': false,
      'category': 'visit',
    },
    {
      'id': '6',
      'type': 'emergency',
      'message':
          'Robert Johnson reported chest discomfort - emergency contact notified',
      'patient': 'Robert Johnson',
      'patientId': '3',
      'timestamp': DateTime.now().subtract(const Duration(minutes: 30)),
      'priority': 'critical',
      'isRead': false,
      'actionRequired': true,
      'category': 'emergency',
    },
    {
      'id': '7',
      'type': 'lab',
      'message': 'Mary Smith lab results are ready for review',
      'patient': 'Mary Smith',
      'patientId': '2',
      'timestamp': DateTime.now().subtract(const Duration(hours: 8)),
      'priority': 'medium',
      'isRead': true,
      'actionRequired': false,
      'category': 'lab',
    },
    {
      'id': '8',
      'type': 'medication',
      'message': 'John Doe medication refill reminder - 5 days remaining',
      'patient': 'John Doe',
      'patientId': '1',
      'timestamp': DateTime.now().add(const Duration(days: 2)),
      'priority': 'low',
      'isRead': false,
      'actionRequired': false,
      'category': 'refill',
    },
  ];

  String _filterLabel(_AlertFilter filter, AppLocalizations l10n) {
    switch (filter) {
      case _AlertFilter.all:
        return l10n.tabAll;
      case _AlertFilter.unread:
        return l10n.filterUnread;
      case _AlertFilter.read:
        return l10n.filterRead;
      case _AlertFilter.highPriority:
        return l10n.filterHighPriority;
    }
  }

  List<Map<String, dynamic>> get _filteredAlerts {
    var alerts = _allAlerts;

    switch (_selectedFilter) {
      case _AlertFilter.unread:
        alerts = alerts.where((alert) => !alert['isRead']).toList();
        break;
      case _AlertFilter.read:
        alerts = alerts.where((alert) => alert['isRead']).toList();
        break;
      case _AlertFilter.highPriority:
        alerts = alerts
            .where((alert) =>
                alert['priority'] == 'high' || alert['priority'] == 'critical')
            .toList();
        break;
      case _AlertFilter.all:
        break;
    }

    // Sort by priority (critical > high > medium > low) then by timestamp (newest first)
    alerts.sort((a, b) {
      final priorityOrder = {'critical': 4, 'high': 3, 'medium': 2, 'low': 1};
      final aPriority = priorityOrder[a['priority']] ?? 0;
      final bPriority = priorityOrder[b['priority']] ?? 0;

      if (aPriority != bPriority) {
        return bPriority.compareTo(aPriority); // Higher priority first
      }

      // If same priority, sort by timestamp (newest first)
      return (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime);
    });

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return Scaffold(
        backgroundColor: RemiCareUiColors.bodyBackground,
        body: Column(
          children: [
            RemiShellUi.screenHeader(
              context: context,
              title: l10n.navOverview,
              subtitle: l10n.caregiverAlertsSubtitle,
            ),
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            ),
          ],
        ),
      );
    }
    final unreadCount = _allAlerts.where((alert) => !alert['isRead']).length;
    final filteredCount = _filteredAlerts.length;
    final alertsLabel = filteredCount == 1
        ? '1 ${l10n.alertSingular}'
        : '$filteredCount ${l10n.alertsPlural}';

    return Scaffold(
      backgroundColor: RemiCareUiColors.bodyBackground,
      body: Column(
        children: [
          RemiShellUi.screenHeader(
            context: context,
            title: l10n.navOverview,
            subtitle: l10n.caregiverAlertsSubtitle,
            trailing: unreadCount > 0
                ? IconButton(
                    icon: const Icon(Icons.done_all, color: Colors.white),
                    tooltip: l10n.markAllAlertsRead,
                    onPressed: _markAllAsRead,
                  )
                : null,
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: RemiCareUiColors.filterInactiveBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildFilterChip(_AlertFilter.all, l10n),
                _buildFilterChip(_AlertFilter.unread, l10n),
                _buildFilterChip(_AlertFilter.read, l10n),
                _buildFilterChip(_AlertFilter.highPriority, l10n),
              ],
            ),
          ),

          // Results Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  alertsLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Merriweather',
                    color: RemiCareUiColors.sectionHeaderText,
                  ),
                ),
                if (_selectedFilter != _AlertFilter.all) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getFilterColor(_selectedFilter).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _filterLabel(_selectedFilter, l10n),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getFilterColor(_selectedFilter),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                if (_selectedFilter != _AlertFilter.all)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedFilter = _AlertFilter.all;
                      });
                    },
                    child: Text(l10n.clearFilter),
                  ),
              ],
            ),
          ),

          // Alerts List
          Expanded(
            child: _filteredAlerts.isEmpty
                ? _buildEmptyState(l10n)
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: _filteredAlerts.length,
                    itemBuilder: (context, index) {
                      final alert = _filteredAlerts[index];
                      return _buildAlertCard(alert);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(_AlertFilter filter, AppLocalizations l10n) {
    final isSelected = _selectedFilter == filter;
    final count = _getFilterCount(filter);
    final label = _filterLabel(filter, l10n);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedFilter = filter;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? RemiCareUiColors.primaryDarkTeal
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected
                      ? Colors.white
                      : Theme.of(context).colorScheme.secondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              if (count > 0)
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 10,
                    color: isSelected
                        ? Colors.white.withOpacity(0.8)
                        : Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    final isRead = alert['isRead'] as bool;
    final priority = alert['priority'] as String;
    final type = alert['type'] as String;
    final actionRequired = alert['actionRequired'] as bool;

    return Dismissible(
      key: Key(alert['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: isRead ? Colors.blue : Colors.green,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          isRead ? Icons.markunread : Icons.done,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          _toggleReadStatus(alert['id']);
          return false; // Don't dismiss, just toggle read status
        }
        return false;
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: isRead ? 1 : 2,
        color: isRead ? Colors.white : Colors.blue.withOpacity(0.05),
        child: InkWell(
          onTap: () => _viewAlertDetails(alert),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  children: [
                    // Priority Indicator
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Alert Type Icon
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(type),
                        color: _getTypeColor(type),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Patient Name
                    Expanded(
                      child: Text(
                        alert['patient'],
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),

                    // Time and Status
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatTime(alert['timestamp']),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.7),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Alert Message
                Text(
                  alert['message'],
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                    height: 1.4,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 12),

                // Action Indicators
                Row(
                  children: [
                    // Priority Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: _getPriorityColor(priority),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Category Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        alert['category'].toString().toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Action Required Indicator
                    if (actionRequired)
                      const Row(
                        children: [
                          Icon(
                            Icons.warning,
                            size: 14,
                            color: Colors.orange,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Action Required',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),

                // Quick Actions
                if (!isRead) ...[
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _markAsRead(alert['id']),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          child: const Text('Mark Read',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _takeAction(alert),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                          ),
                          child: const Text('Take Action',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == _AlertFilter.all
                ? l10n.noAlertsAtThisTime
                : l10n.noAlertsMatchFilter,
            style: TextStyle(
              fontSize: 20,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == _AlertFilter.all
                ? l10n.allPatientActivitiesSmooth
                : l10n.tryAdjustingFilter,
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_selectedFilter != _AlertFilter.all) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedFilter = _AlertFilter.all;
                });
              },
              child: Text(l10n.viewAllAlerts),
            ),
          ],
        ],
      ),
    );
  }

  void _markAsRead(String alertId) {
    setState(() {
      final index = _allAlerts.indexWhere((alert) => alert['id'] == alertId);
      if (index != -1) {
        _allAlerts[index]['isRead'] = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.alertMarkedAsRead)),
    );
  }

  void _toggleReadStatus(String alertId) {
    setState(() {
      final index = _allAlerts.indexWhere((alert) => alert['id'] == alertId);
      if (index != -1) {
        final currentStatus = _allAlerts[index]['isRead'] as bool;
        _allAlerts[index]['isRead'] = !currentStatus;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Alert marked as ${!currentStatus ? 'read' : 'unread'}')),
        );
      }
    });
  }

  void _markAllAsRead() {
    final l10n = AppLocalizations.of(context)!;
    final unreadAlerts = _allAlerts.where((alert) => !alert['isRead']).toList();
    if (unreadAlerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.allAlertsAlreadyRead)),
      );
      return;
    }

    setState(() {
      for (var alert in unreadAlerts) {
        alert['isRead'] = true;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          LocaleFormat.localizeDigitsInText(
            context,
            l10n.alertsMarkedAsRead(unreadAlerts.length),
          ),
        ),
      ),
    );
  }

  int _getFilterCount(_AlertFilter filter) {
    switch (filter) {
      case _AlertFilter.unread:
        return _allAlerts.where((alert) => !alert['isRead']).length;
      case _AlertFilter.read:
        return _allAlerts.where((alert) => alert['isRead']).length;
      case _AlertFilter.highPriority:
        return _allAlerts
            .where((alert) =>
                alert['priority'] == 'high' || alert['priority'] == 'critical')
            .length;
      case _AlertFilter.all:
        return _allAlerts.length;
    }
  }

  void _takeAction(Map<String, dynamic> alert) {
    final type = alert['type'];
    final patientId = (alert['patientId'] ?? '').toString();

    if (patientId.isEmpty) {
      _viewAlertDetails(alert);
      return;
    }

    final overviewParams = {'patientId': patientId};
    final overviewUri = Uri(
      path: '/caregiver/patient-overview',
      queryParameters: overviewParams,
    ).toString();

    switch (type) {
      case 'medication':
      case 'measurement':
        context.go(
          Uri(
            path: '/caregiver/patient-overview',
            queryParameters: {...overviewParams, 'tab': 'reminders'},
          ).toString(),
        );
        break;
      case 'appointment':
      case 'visit':
        context.go(overviewUri);
        break;
      default:
        context.go(overviewUri);
    }
  }

  void _viewAlertDetails(Map<String, dynamic> alert) {
    final patientId = (alert['patientId'] ?? '').toString();
    if (patientId.isEmpty) return;

    context.go(
      Uri(
        path: '/caregiver/patient-overview',
        queryParameters: {'patientId': patientId},
      ).toString(),
    );
  }

  Color _getFilterColor(_AlertFilter filter) {
    switch (filter) {
      case _AlertFilter.unread:
        return Colors.blue;
      case _AlertFilter.read:
        return Colors.green;
      case _AlertFilter.highPriority:
        return Colors.red;
      case _AlertFilter.all:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'medication':
        return Colors.blue;
      case 'appointment':
        return Colors.purple;
      case 'measurement':
        return Colors.green;
      case 'visit':
        return Colors.teal;
      case 'lab':
        return Colors.indigo;
      case 'emergency':
        return Colors.red;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.calendar_today;
      case 'measurement':
        return Icons.monitor_heart;
      case 'visit':
        return Icons.medical_services;
      case 'lab':
        return Icons.science;
      case 'emergency':
        return Icons.emergency;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime timestamp) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.isNegative) {
      final hours = difference.inHours.abs().clamp(1, 999);
      return LocaleFormat.localizeDigitsInText(
        context,
        l10n.timeInHoursShort(hours),
      );
    }
    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes < 1 ? 1 : difference.inMinutes;
      return LocaleFormat.localizeDigitsInText(
        context,
        l10n.timeMinutesAgo(minutes),
      );
    }
    if (difference.inHours < 24) {
      return LocaleFormat.localizeDigitsInText(
        context,
        l10n.timeHoursAgo(difference.inHours),
      );
    }
    return LocaleFormat.localizeDigitsInText(
      context,
      l10n.timeDaysAgo(difference.inDays),
    );
  }
}
