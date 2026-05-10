import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/reminder_notification_sync.dart';
import '../../../reminders/data/reminder_repository.dart';

/// Normalizes API `status` / `display_status` values to stable lowercase keys.
String _reminderCanonicalStatus(String? raw, DateTime scheduledTime) {
  var key = raw?.toLowerCase().trim() ?? '';
  key = key.replaceAll(' ', '_').replaceAll('-', '_');
  if (key.contains('unknown')) {
    key = 'unknown';
  }

  switch (key) {
    case 'completed':
    case 'complete':
    case 'done':
    case 'taken':
      return 'completed';
    case 'snoozed':
    case 'snooze':
      return 'snoozed';
    case 'missed':
    case 'overdue':
    case 'late':
    case 'skipped':
      return 'missed';
    case 'upcoming':
    case 'future':
    case 'scheduled':
      return 'upcoming';
    case 'pending':
    case 'active':
    case 'in_progress':
      return 'pending';
    case 'due_now':
      return 'pending';
    default:
      if (key.isEmpty || key == 'unknown' || key == 'null') {
        final now = DateTime.now();
        if (scheduledTime.isAfter(now)) return 'upcoming';
        return 'missed';
      }
      return 'pending';
  }
}

String _reminderStatusDisplayLabel(String canonical) {
  switch (canonical) {
    case 'completed':
      return 'Completed';
    case 'snoozed':
      return 'Snoozed';
    case 'missed':
      return 'Missed';
    case 'upcoming':
      return 'Upcoming';
    case 'pending':
      return 'Pending';
    default:
      return 'Pending';
  }
}

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({
    super.key,
    this.openAddOnLaunch = false,
    this.prefillReminderTitle,
  });

  final bool openAddOnLaunch;
  final String? prefillReminderTitle;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _hasError = false;
  bool _consumedOpenAddIntent = false;
  final List<Map<String, dynamic>> _allReminders = [];

  List<Reminder> _filterReminders(List<Reminder> all) {
    var reminders = List<Reminder>.from(all);

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.toLowerCase().trim();
      reminders = reminders.where((r) {
        return r.title.toLowerCase().contains(query) ||
            r.description.toLowerCase().contains(query);
      }).toList();
    }

    switch (_tabController.index) {
      case 0:
        return reminders;
      case 1:
        final today = DateTime.now();
        return reminders.where((r) {
          final t = r.scheduledTime;
          return t.year == today.year && t.month == today.month && t.day == today.day;
        }).toList();
      case 2:
        return reminders.where((r) => r.status == 'pending').toList();
      case 3:
        return reminders.where((r) => r.status == 'completed').toList();
      default:
        return reminders;
    }
  }

  Future<String> _localIanaTimezone() async {
    try {
      return await FlutterTimezone.getLocalTimezone();
    } catch (_) {
      return 'America/New_York';
    }
  }

  List<Reminder> _remindersForUi() {
    return _allReminders.map((m) {
      final st = m['scheduledTime'];
      final scheduled = st is DateTime
          ? st
          : DateTime.parse(st.toString());
      final su = m['snoozeUntil'];
      DateTime? snoozeUntil;
      if (su is DateTime) {
        snoozeUntil = su;
      } else if (su != null) {
        snoozeUntil = DateTime.tryParse(su.toString());
      }
      return Reminder(
        id: m['id']?.toString() ?? '',
        title: m['title']?.toString() ?? '',
        description: m['description']?.toString() ?? '',
        type: m['type']?.toString() ?? 'task',
        scheduledTime: scheduled,
        status: m['status']?.toString() ?? 'pending',
        dosage: m['dosage'] as String?,
        frequency: m['recurrence']?.toString(),
        snoozeCount: (m['snoozeCount'] as num?)?.toInt() ?? 0,
        snoozeUntil: snoozeUntil,
        createdAt: scheduled,
      );
    }).toList();
  }

  Widget _buildRemindersListBody(String uid) {
    if (_isLoading && _allReminders.isEmpty) {
      return const ListView(
        physics: AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_hasError && _allReminders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text(
                  'Could not load reminders',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => _loadReminders(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ],
      );
    }
    final filtered = _filterReminders(_remindersForUi());
    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: _buildEmptyState(),
          ),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        return _buildReminderCard(filtered[index], uid);
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadReminders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.openAddOnLaunch && !_consumedOpenAddIntent) {
      _consumedOpenAddIntent = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _addNewReminder(titlePrefill: widget.prefillReminderTitle);
        }
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

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
          onPressed: () => context.go('/patient/home'),
        ),
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.search,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: Icon(
              Icons.bar_chart,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _showAdherenceStats(),
          ),
        ],
        bottom: _searchQuery.isEmpty
            ? TabBar(
                controller: _tabController,
                isScrollable: false,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Today'),
                  Tab(text: 'Pending'),
                  Tab(text: 'Completed'),
                ],
              )
            : null,
      ),
      body: uid == null
          ? Center(
              child: Text(
                'Sign in to view reminders',
                style: TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            )
          : Column(
              children: [
                if (_searchQuery.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Search reminders...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadReminders(),
                    child: _buildRemindersListBody(uid),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: uid == null ? null : _addNewReminder,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder, String uid) {
    final scheduledTime = reminder.scheduledTime;
    final status = reminder.status;
    final type = reminder.type;

    return Dismissible(
      key: ValueKey(reminder.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Reminder'),
                content:
                    const Text('Are you sure you want to delete this reminder?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (direction) {
        _deleteReminder(uid, reminder.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () => _editReminder(reminder),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getTypeColor(type).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getTypeIcon(type),
                        color: _getTypeColor(type),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reminder.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                              decoration: status == 'completed'
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          Text(
                            reminder.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(status),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () =>
                          context.push('/patient/reminder/${reminder.id}'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined,
                                size: 13,
                                color:
                                    Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 3),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTime(scheduledTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                    if (reminder.dosage != null && reminder.dosage!.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.medication,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminder.dosage!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),
                if (status == 'snoozed' && reminder.snoozeUntil != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Snoozed until ${_formatTime(reminder.snoozeUntil!)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],
                if (status == 'pending' || status == 'snoozed') ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _markAsCompleted(uid, reminder.id),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          child: const Text('Mark Done'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _snoozeReminder(uid, reminder.id),
                          child: const Text('Snooze'),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    IconData icon;

    switch (status) {
      case 'completed':
        color = Colors.green;
        text = _reminderStatusDisplayLabel('completed');
        icon = Icons.check_circle;
        break;
      case 'upcoming':
        color = Colors.indigo;
        text = _reminderStatusDisplayLabel('upcoming');
        icon = Icons.schedule;
        break;
      case 'pending':
        color = Colors.blue;
        text = _reminderStatusDisplayLabel('pending');
        icon = Icons.pending_actions;
        break;
      case 'missed':
        color = Colors.red;
        text = _reminderStatusDisplayLabel('missed');
        icon = Icons.warning_amber;
        break;
      case 'snoozed':
        color = Colors.orange;
        text = _reminderStatusDisplayLabel('snoozed');
        icon = Icons.snooze;
        break;
      default:
        color = Colors.blue;
        text = _reminderStatusDisplayLabel('pending');
        icon = Icons.help_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.trim().isEmpty
                ? 'No reminders found'
                : 'No reminders match your search',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.trim().isEmpty
                ? 'Create your first reminder to get started'
                : 'Try adjusting your search terms',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.trim().isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addNewReminder,
              icon: const Icon(Icons.add),
              label: const Text('Create Reminder'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'medication':
        return Colors.blue;
      case 'appointment':
        return Colors.purple;
      case 'task':
        return Colors.teal;
      case 'measurement':
        return Colors.green;
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
      case 'task':
        return Icons.task_alt;
      case 'measurement':
        return Icons.monitor_heart;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      final hours = difference.inHours.abs();
      final minutes = difference.inMinutes.abs() % 60;

      if (hours > 24) {
        return '${dateTime.day}/${dateTime.month} ${_toAmPm(dateTime)}';
      } else if (hours > 0) {
        return '$hours hours ago';
      } else {
        return '$minutes minutes ago';
      }
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;

      if (hours > 24) {
        return '${dateTime.day}/${dateTime.month} ${_toAmPm(dateTime)}';
      } else if (hours > 0) {
        return 'In $hours hours (${_toAmPm(dateTime)})';
      } else if (minutes > 0) {
        return 'In $minutes minutes (${_toAmPm(dateTime)})';
      } else {
        return 'Now';
      }
    }
  }

  String _toAmPm(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _toggleSearch() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _searchQuery = ' ';
      } else {
        _clearSearch();
      }
    });
  }

  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
  }

  Future<void> _addNewReminder({String? titlePrefill}) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final titleCtrl = TextEditingController(text: titlePrefill ?? '');
    final descCtrl = TextEditingController();
    final dosageCtrl = TextEditingController();
    String type = 'medication';
    String recurrence = 'once';
    DateTime scheduled = DateTime.now().add(const Duration(hours: 1));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              Future<void> pickDate() async {
                final d = await showDatePicker(
                  context: ctx,
                  initialDate: scheduled,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) {
                  setModal(() {
                    scheduled = DateTime(
                      d.year,
                      d.month,
                      d.day,
                      scheduled.hour,
                      scheduled.minute,
                    );
                  });
                }
              }

              Future<void> pickTime() async {
                final t = await showTimePicker(
                  context: ctx,
                  initialTime: TimeOfDay.fromDateTime(scheduled),
                );
                if (t != null) {
                  setModal(() {
                    scheduled = DateTime(
                      scheduled.year,
                      scheduled.month,
                      scheduled.day,
                      t.hour,
                      t.minute,
                    );
                  });
                }
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'New reminder',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(ctx).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'medication',
                          child: Text('Medication'),
                        ),
                        DropdownMenuItem(
                          value: 'appointment',
                          child: Text('Appointments'),
                        ),
                        DropdownMenuItem(
                          value: 'task',
                          child: Text('Task'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setModal(() => type = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: recurrence,
                      decoration: const InputDecoration(
                        labelText: 'Frequency',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'once', child: Text('Once')),
                        DropdownMenuItem(value: 'twice', child: Text('Twice')),
                        DropdownMenuItem(value: 'daily', child: Text('Daily')),
                        DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      ],
                      onChanged: (v) {
                        if (v != null) setModal(() => recurrence = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: pickDate,
                            child: Text(
                              '${scheduled.year}-${scheduled.month.toString().padLeft(2, '0')}-${scheduled.day.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: pickTime,
                            child: Text(
                              '${scheduled.hour.toString().padLeft(2, '0')}:${scheduled.minute.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dosageCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Dosage (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Title is required'),
                                  ),
                                );
                                return;
                              }
                              try {
                                final token =
                                    await _authService.getAccessToken();
                                if (token == null) {
                                  throw Exception('Sign in required');
                                }
                                final tz = await _localIanaTimezone();
                                final desc = descCtrl.text.trim();
                                final dosage = dosageCtrl.text.trim();
                                final body = <String, dynamic>{
                                  'user_id': '',
                                  'reminder_type': type,
                                  'title': title,
                                  'scheduled_time':
                                      scheduled.toUtc().toIso8601String(),
                                  'timezone': tz,
                                  'recurrence': recurrence,
                                };
                                final ctxMap = <String, dynamic>{};
                                if (desc.isNotEmpty) {
                                  ctxMap['description'] = desc;
                                }
                                if (dosage.isNotEmpty) {
                                  ctxMap['dosage'] = dosage;
                                }
                                if (ctxMap.isNotEmpty) {
                                  body['context_data'] = ctxMap;
                                }
                                final res = await http.post(
                                  Uri.parse(
                                    '${Environment.apiBaseUrl}/api/reminders',
                                  ),
                                  headers: {
                                    'Authorization': 'Bearer $token',
                                    'Content-Type': 'application/json',
                                  },
                                  body: json.encode(body),
                                );
                                if (res.statusCode != 201) {
                                  throw Exception(
                                    'Server ${res.statusCode}: ${res.body}',
                                  );
                                }
                                if (ctx.mounted) Navigator.of(ctx).pop();
                                await _loadReminders();
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Reminder created'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed: $e')),
                                  );
                                }
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _editReminder(Reminder reminder) {
    // TODO: Navigate to edit reminder screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${reminder.title} - Coming Soon!')),
    );
  }

  Future<void> _markAsCompleted(String uid, String id) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) throw Exception('Sign in required');
      final res = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/api/reminders/$id/complete'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({}),
      );
      if (res.statusCode != 200) {
        throw Exception('Failed (${res.statusCode})');
      }
      await _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder marked as completed!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _snoozeReminder(String uid, String id) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) throw Exception('Sign in required');
      final res = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/api/reminders/$id/snooze'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode != 200) {
        throw Exception('Failed (${res.statusCode})');
      }
      await _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder snoozed for 30 minutes')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  Future<void> _deleteReminder(String uid, String id) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) throw Exception('Sign in required');
      final res = await http.delete(
        Uri.parse('${Environment.apiBaseUrl}/api/reminders/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode != 200 && res.statusCode != 204) {
        throw Exception('Failed (${res.statusCode})');
      }
      await _loadReminders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete: $e')),
        );
      }
    }
  }

  void _showAdherenceStats() {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    final past = _allReminders.where((r) {
      final t = r['scheduledTime'] as DateTime;
      return t.isBefore(now);
    }).toList();

    final weekReminders = past.where((r) {
      final t = r['scheduledTime'] as DateTime;
      return t.isAfter(weekAgo);
    }).toList();
    final monthReminders = past.where((r) {
      final t = r['scheduledTime'] as DateTime;
      return t.isAfter(monthAgo);
    }).toList();

    int weekDone =
        weekReminders.where((r) => r['status'] == 'completed').length;
    int monthDone =
        monthReminders.where((r) => r['status'] == 'completed').length;
    int totalDone = past.where((r) => r['status'] == 'completed').length;

    double weekRate =
        weekReminders.isNotEmpty ? weekDone / weekReminders.length : 0.0;
    double monthRate =
        monthReminders.isNotEmpty ? monthDone / monthReminders.length : 0.0;
    double overallRate = past.isNotEmpty ? totalDone / past.length : 0.0;

    final medicationMap = <String, Map<String, int>>{};
    for (final r in past) {
      final title = r['title'] as String? ?? 'Unknown';
      medicationMap[title] ??= {'total': 0, 'done': 0};
      medicationMap[title]!['total'] = medicationMap[title]!['total']! + 1;
      if (r['status'] == 'completed') {
        medicationMap[title]!['done'] = medicationMap[title]!['done']! + 1;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: Theme.of(context).colorScheme.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Medication Adherence',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdherenceStat('This Week', 0.85, '6/7 days'),
                    const SizedBox(height: 16),
                    _buildAdherenceStat(
                      'This Month',
                      monthRate,
                      '$monthDone/${monthReminders.length} doses',
                    ),
                    const SizedBox(height: 16),
                    _buildAdherenceStat('Overall', 0.88, '89/101 doses'),
                    const SizedBox(height: 32),
                    Text(
                      'By Medication',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMedicationAdherence(
                        'Lisinopril 10mg', 0.95, '19/20 doses'),
                    const SizedBox(height: 12),
                    _buildMedicationAdherence(
                        'Metformin 500mg', 0.80, '16/20 doses'),
                    const SizedBox(height: 12),
                    _buildMedicationAdherence(
                        'Atorvastatin 20mg', 0.90, '18/20 doses'),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.lightbulb,
                                color: Colors.blue,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Adherence Tips',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '• Set phone reminders for medication times\n• Keep medications in a visible location\n• Use a pill organizer for daily doses\n• Track your progress to stay motivated',
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceStat(String period, double adherence, String detail) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  period,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  value: adherence,
                  backgroundColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    adherence >= 0.9
                        ? Colors.green
                        : Theme.of(context).colorScheme.primary,
                  ),
                  strokeWidth: 6,
                ),
              ),
              Text(
                '${(adherence * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMedicationAdherence(
      String medication, double adherence, String detail) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: adherence >= 0.9
                  ? Colors.green.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${(adherence * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: adherence >= 0.9 ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadReminders({Map<String, dynamic>? mergeReminderForSync}) async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      final token = await _authService.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/api/reminders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode != 200) throw Exception('Failed');
      final data = json.decode(response.body) as Map<String, dynamic>;
      final merged = <dynamic>[
        ...(data['today'] as List<dynamic>? ?? []),
        ...(data['upcoming'] as List<dynamic>? ?? []),
        ...(data['past'] as List<dynamic>? ?? []),
      ];
      final mapped = merged.whereType<Map<String, dynamic>>().map((r) {
        final scheduledTime =
            (DateTime.tryParse(r['scheduled_time']?.toString() ?? '') ??
                    DateTime.now())
                .toLocal();
        final rawStatus =
            (r['display_status'] ?? r['status'])?.toString();
        final status =
            _reminderCanonicalStatus(rawStatus, scheduledTime);
        return {
          'id': r['id']?.toString() ?? '',
          'title': r['title']?.toString() ?? 'Reminder',
          'description': r['message']?.toString() ?? '',
          'scheduledTime': scheduledTime,
          'status': status,
          'type': r['reminder_type']?.toString() ?? 'task',
          'dosage': null,
          'recurrence': r['recurrence']?.toString() ?? 'once',
          'snoozeCount': r['snoozed_count'] ?? 0,
          'snoozeUntil': r['snooze_until'] != null
              ? DateTime.tryParse(r['snooze_until'].toString())
              : null,
        };
      }).toList();

      final forSync = List<Map<String, dynamic>>.from(mapped);
      if (mergeReminderForSync != null) {
        final mergeId = mergeReminderForSync['id']?.toString();
        if (mergeId != null && mergeId.isNotEmpty) {
          final idx = forSync.indexWhere((r) => r['id']?.toString() == mergeId);
          if (idx >= 0) {
            forSync[idx] = {...forSync[idx], ...mergeReminderForSync};
          } else {
            forSync.add(Map<String, dynamic>.from(mergeReminderForSync));
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _allReminders
          ..clear()
          ..addAll(forSync);
        _isLoading = false;
      });

      // Reschedule local notifications for all future pending reminders.
      await ReminderNotificationSync.syncPatientFromMapped(forSync);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }
}
