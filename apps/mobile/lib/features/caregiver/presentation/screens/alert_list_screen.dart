import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';

class AlertListScreen extends StatefulWidget {
  final String? initialPatientId;
  final String? initialPatientName;

  const AlertListScreen({
    super.key,
    this.initialPatientId,
    this.initialPatientName,
  });

  @override
  State<AlertListScreen> createState() => _AlertListScreenState();
}

class _AlertListScreenState extends State<AlertListScreen> {
  String _selectedFilter = 'All';
  List<Map<String, dynamic>> _allAlerts = [];
  bool _isLoading = true;
  String? _error;
  String? _caregiverId;

  void _goBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/caregiver/home');
    }
  }

  String? get _patientIdFilter {
    final v = widget.initialPatientId?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
  }

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final user = await AuthService().getCurrentUser();
      if (user == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final caregiverId = user.authUid ?? user.id;
      _caregiverId = caregiverId;

      final headers = await AuthService().getAuthHeaders();
      final response = await http.get(
        Uri.parse(
            '${Environment.apiBaseUrl}/api/caregivers/$caregiverId/alerts'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        // Do not bulk-mark alerts read on load — that clears unread immediately,
        // makes "Mark all as read" useless, and hides which items still need attention.
        final List<dynamic> alertData = jsonDecode(response.body);
        final alerts = alertData
            .map((item) => _mapAlert(item as Map<String, dynamic>))
            .toList();
        setState(() {
          _allAlerts = alerts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load alerts (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _mapAlert(Map<String, dynamic> raw) {
    final alertType = (raw['alert_type'] as String? ?? 'general').toLowerCase();
    final isRead = raw['read'] as bool? ?? false;
    final serverPriority = (raw['priority'] as String?)?.toLowerCase().trim();

    DateTime timestamp;
    try {
      timestamp = DateTime.parse(raw['sent_at'] as String);
    } catch (_) {
      timestamp = DateTime.now();
    }

    return {
      'id': raw['id'] as String,
      'type': alertType,
      'message': raw['message'] as String? ?? '',
      'patient': 'Patient',
      'patientId': raw['user_id'] as String? ?? '',
      'timestamp': timestamp,
      'priority': (serverPriority != null &&
              {'critical', 'high', 'medium', 'low'}.contains(serverPriority))
          ? serverPriority
          : _priorityFromType(alertType),
      'isRead': isRead,
      'actionRequired': !isRead && _isActionRequired(alertType),
      'category': alertType,
    };
  }

  String _priorityFromType(String type) {
    if (type.contains('missed') || type.contains('emergency')) return 'high';
    if (type.contains('medication') || type.contains('reminder'))
      return 'medium';
    return 'low';
  }

  bool _isActionRequired(String type) {
    return type.contains('missed') ||
        type.contains('emergency') ||
        type.contains('medication');
  }

  List<Map<String, dynamic>> get _filteredAlerts {
    var alerts = _allAlerts;

    final patientId = _patientIdFilter;
    if (patientId != null) {
      alerts = alerts.where((a) => (a['patientId']?.toString() ?? '') == patientId).toList();
    }

    switch (_selectedFilter) {
      case 'Unread':
        alerts = alerts.where((alert) => !alert['isRead']).toList();
        break;
      case 'Read':
        alerts = alerts.where((alert) => alert['isRead']).toList();
        break;
      case 'High Priority':
        alerts = alerts
            .where((alert) =>
                alert['priority'] == 'high' || alert['priority'] == 'critical')
            .toList();
        break;
      case 'Action Required':
        alerts = alerts.where((alert) => alert['actionRequired']).toList();
        break;
      case 'All':
      default:
        break;
    }

    alerts.sort((a, b) {
      final priorityOrder = {'critical': 4, 'high': 3, 'medium': 2, 'low': 1};
      final aPriority = priorityOrder[a['priority']] ?? 0;
      final bPriority = priorityOrder[b['priority']] ?? 0;
      if (aPriority != bPriority) return bPriority.compareTo(aPriority);
      return (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime);
    });

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _allAlerts.where((alert) => !alert['isRead']).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back,
              color: Theme.of(context).colorScheme.primary),
          onPressed: _goBack,
        ),
        title:
            Text(
              _patientIdFilter == null
                  ? 'Alerts'
                  : 'Alerts · ${widget.initialPatientName?.trim().isNotEmpty == true ? widget.initialPatientName!.trim() : 'Patient'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
        actions: [
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(12)),
              child: Text('$unreadCount',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold)),
            ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadAlerts),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          _buildFilterChip('All'),
                          _buildFilterChip('Unread'),
                          _buildFilterChip('Read'),
                          _buildFilterChip('High Priority'),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text(
                            '${_filteredAlerts.length} ${_filteredAlerts.length == 1 ? 'Alert' : 'Alerts'}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          if (_selectedFilter != 'All') ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getFilterColor(_selectedFilter)
                                    .withOpacity(0.1),
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
                          if (_selectedFilter != 'All')
                            TextButton(
                              onPressed: () =>
                                  setState(() => _selectedFilter = 'All'),
                              child: const Text('Clear Filter'),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _filteredAlerts.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                MediaQuery.of(context).padding.bottom + 180,
                              ),
                              itemCount: _filteredAlerts.length,
                              itemBuilder: (context, index) =>
                                  _buildAlertCard(_filteredAlerts[index]),
                            ),
                    ),
                  ],
                ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        // Keep FABs above the shared rounded bottom nav shell.
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 108),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FloatingActionButton(
              onPressed: _markAllAsRead,
              backgroundColor: Theme.of(context).colorScheme.primary,
              tooltip: 'Mark all as read',
              child: const Icon(Icons.done_all),
            ),
            const SizedBox(height: 12),
            FloatingActionButton(
              onPressed: _createNewAlert,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              tooltip: 'New Alert',
              child: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(_error ?? 'Something went wrong',
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadAlerts, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filter) {
    final isSelected = _selectedFilter == filter;
    final count = _getFilterCount(filter);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedFilter = filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          margin: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                filter,
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
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        final shouldDelete = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Delete alert'),
                content: const Text(
                  'Are you sure you want to delete this alert?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
        if (!shouldDelete) return false;
        return await _deleteAlert(alert['id'] as String);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: _getPriorityColor(priority),
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(_getTypeIcon(type),
                          color: _getTypeColor(type), size: 16),
                    ),
                    const SizedBox(width: 8),
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
                                color: Colors.blue, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
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
                Row(
                  children: [
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
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Spacer(),
                    if (actionRequired)
                      const Row(
                        children: [
                          Icon(Icons.warning, size: 14, color: Colors.orange),
                          SizedBox(width: 4),
                          Text('Action Required',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                  ],
                ),
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
                              padding: const EdgeInsets.symmetric(vertical: 6)),
                          child: const Text('Mark Read',
                              style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _takeAction(alert),
                          style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 6)),
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

  void _createNewAlert() {
    context.go('/caregiver/alerts/create');
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none,
              size: 80,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(
            _selectedFilter == 'All'
                ? 'No alerts at this time'
                : 'No alerts match this filter',
            style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'All'
                ? 'All patient activities are running smoothly'
                : 'Try adjusting your filter to see more alerts',
            style: TextStyle(
                fontSize: 16,
                color:
                    Theme.of(context).colorScheme.secondary.withOpacity(0.7)),
            textAlign: TextAlign.center,
          ),
          if (_selectedFilter != 'All') ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => setState(() => _selectedFilter = 'All'),
              child: const Text('View All Alerts'),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _markAsRead(String alertId) async {
    if (_caregiverId == null) return;

    try {
      final headers = await AuthService().getAuthHeaders();
      final response = await http.patch(
        Uri.parse(
            '${Environment.apiBaseUrl}/api/caregivers/alerts/$alertId/read?caregiver_id=$_caregiverId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _allAlerts.indexWhere((a) => a['id'] == alertId);
          if (index != -1) {
            _allAlerts[index]['isRead'] = true;
            _allAlerts[index]['actionRequired'] = false;
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Alert marked as read')));
        }
      }
    } catch (_) {
      setState(() {
        final index = _allAlerts.indexWhere((a) => a['id'] == alertId);
        if (index != -1) _allAlerts[index]['isRead'] = true;
      });
    }
  }

  Future<bool> _deleteAlert(String alertId) async {
    if (_caregiverId == null) return false;
    try {
      final headers = await AuthService().getAuthHeaders();
      final response = await http.delete(
        Uri.parse(
            '${Environment.apiBaseUrl}/api/caregivers/alerts/$alertId?caregiver_id=$_caregiverId'),
        headers: headers,
      );

      if (response.statusCode == 204) {
        setState(() {
          _allAlerts.removeWhere((a) => a['id'] == alertId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Alert deleted')),
          );
        }
        return true;
      }
      throw Exception('Failed to delete alert');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete alert: $e')),
        );
      }
      return false;
    }
  }

  Future<void> _markAllAsRead() async {
    final unreadAlerts = _allAlerts.where((a) => !a['isRead']).toList();
    if (unreadAlerts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No unread alerts. Tap refresh for new ones, or Mark read per alert.',
          ),
        ),
      );
      return;
    }
    for (final alert in unreadAlerts) {
      await _markAsRead(alert['id'] as String);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked ${unreadAlerts.length} alerts as read')),
      );
    }
  }

  void _takeAction(Map<String, dynamic> alert) {
    final type = alert['type'];
    final patientId = alert['patientId'];
    switch (type) {
      case 'medication':
      case 'measurement':
      case 'appointment':
        context.go('/caregiver/patient-overview?patientId=$patientId');
        break;
      default:
        _viewAlertDetails(alert);
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Taking action on $type alert')));
  }

  void _viewAlertDetails(Map<String, dynamic> alert) {
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${alert['type']} alert details')));
  }

  int _getFilterCount(String filter) {
    switch (filter) {
      case 'Unread':
        return _allAlerts.where((a) => !a['isRead']).length;
      case 'Read':
        return _allAlerts.where((a) => a['isRead']).length;
      case 'High Priority':
        return _allAlerts
            .where(
                (a) => a['priority'] == 'high' || a['priority'] == 'critical')
            .length;
      case 'Action Required':
        return _allAlerts.where((a) => a['actionRequired']).length;
      default:
        return _allAlerts.length;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'critical':
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
    if (type.contains('medication') || type.contains('med')) return Colors.blue;
    if (type.contains('appointment')) return Colors.purple;
    if (type.contains('measurement') || type.contains('monitor'))
      return Colors.green;
    if (type.contains('visit')) return Colors.teal;
    if (type.contains('lab')) return Colors.indigo;
    if (type.contains('emergency')) return Colors.red;
    return Theme.of(context).colorScheme.primary;
  }

  Color _getFilterColor(String filter) {
    switch (filter) {
      case 'Unread':
        return Colors.blue;
      case 'Read':
        return Colors.green;
      case 'High Priority':
        return Colors.red;
      case 'Action Required':
        return Colors.orange;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getTypeIcon(String type) {
    if (type.contains('medication') || type.contains('med'))
      return Icons.medication;
    if (type.contains('appointment')) return Icons.calendar_today;
    if (type.contains('measurement') || type.contains('monitor'))
      return Icons.monitor_heart;
    if (type.contains('visit')) return Icons.medical_services;
    if (type.contains('lab')) return Icons.science;
    if (type.contains('emergency')) return Icons.emergency;
    return Icons.notifications;
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    if (difference.isNegative) {
      final hours = difference.inHours.abs();
      return 'In $hours${hours == 1 ? 'hr' : 'hrs'}';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
