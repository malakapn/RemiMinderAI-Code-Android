import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter_timezone/flutter_timezone.dart';

import '../../../../core/config/environment.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../../core/l10n/localized_pickers.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/reminder_notification_sync.dart';
import '../../../shared/widgets/custom_time_picker_sheet.dart';
import '../../../shared/widgets/scroll_bottom_fade.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, this.openAddOnLaunch = false});

  /// When true (e.g. `/patient/reminders?add=1`), opens the new-reminder sheet once after first frame.
  final bool openAddOnLaunch;

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

  List<Map<String, dynamic>> get _filteredReminders {
    var reminders = _allReminders;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      reminders = reminders.where((reminder) {
        final title = reminder['title'].toLowerCase();
        final description = reminder['description'].toLowerCase();
        final query = _searchQuery.toLowerCase();
        return title.contains(query) || description.contains(query);
      }).toList();
    }

    // Apply tab filter
    switch (_tabController.index) {
      case 0: // All
        return reminders;
      case 1: // Today
        return reminders.where((reminder) {
          final scheduledTime = reminder['scheduledTime'] as DateTime;
          final today = DateTime.now();
          return scheduledTime.year == today.year &&
              scheduledTime.month == today.month &&
              scheduledTime.day == today.day;
        }).toList();
      case 2: // Pending / active
        return reminders.where((reminder) {
          final s = reminder['status']?.toString().toLowerCase() ?? '';
          return s == 'pending' ||
              s == 'upcoming' ||
              s == 'due now' ||
              s == 'snoozed';
        }).toList();
      case 3: // Completed / done
        return reminders.where((reminder) {
          final s = reminder['status']?.toString().toLowerCase() ?? '';
          return s == 'completed' || s == 'skipped' || s == 'missed';
        }).toList();
      default:
        return reminders;
    }
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
        if (mounted) _addNewReminder();
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
    final l10n = AppLocalizations.of(context)!;
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
        title: Text(
          l10n.remindersTitle,
          style: const TextStyle(
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
                tabs: [
                  Tab(text: l10n.tabAll),
                  Tab(text: l10n.tabToday),
                  Tab(text: l10n.tabPending),
                  Tab(text: l10n.tabCompleted),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // Search Bar (when active)
          if (_searchQuery.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: l10n.searchRemindersHint,
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

          // Reminders List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _hasError
                    ? Center(
                        child: TextButton(
                          onPressed: _loadReminders,
                          child: Text(l10n.failedToLoadRemindersRetry),
                        ),
                      )
                    : _filteredReminders.isEmpty
                        ? _buildEmptyState()
                        : ScrollBottomFade.builder(
                            fadeColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            builder: (context, controller) => ListView.builder(
                              controller: controller,
                              padding:
                                  const EdgeInsets.fromLTRB(16, 16, 16, 88),
                              itemCount: _filteredReminders.length,
                              itemBuilder: (context, index) {
                                final reminder = _filteredReminders[index];
                                return _buildReminderCard(reminder);
                              },
                            ),
                          ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewReminder,
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReminderCard(Map<String, dynamic> reminder) {
    final l10n = AppLocalizations.of(context)!;
    final scheduledTime = reminder['scheduledTime'] as DateTime;
    final status = reminder['status'] as String;
    final type = reminder['type'] as String;

    return Dismissible(
      key: Key(reminder['id']),
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
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.deleteReminderTitle),
            content: Text(l10n.deleteReminderMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: Text(l10n.delete),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteReminder(reminder['id']);
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
                // Header with type icon and status
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
                            reminder['title'],
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
                            reminder['description'],
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
                      onTap: () => _showEditReminderDialog(reminder),
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
                              l10n.edit,
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

                // Time and dosage info
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
                    if (reminder['dosage'] != null) ...[
                      const SizedBox(width: 16),
                      Icon(
                        Icons.medication,
                        size: 16,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        reminder['dosage'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ],
                ),

                if (status == 'snoozed' && reminder['snoozeUntil'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.snoozedUntil(_formatTime(reminder['snoozeUntil'])),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ],

                // Action buttons
                if (['pending', 'snoozed', 'upcoming', 'due now', 'missed']
                    .contains(status.toLowerCase())) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _markAsCompleted(reminder['id']),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          child: Text(l10n.markDone),
                        ),
                      ),
                      if (status.toLowerCase() != 'snoozed') ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _snoozeReminder(reminder['id']),
                            child: Text(l10n.snooze),
                          ),
                        ),
                      ],
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
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String text;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'completed':
        color = Colors.green;
        text = l10n.statusDone;
        icon = Icons.check_circle;
        break;
      case 'due now':
        color = Colors.red;
        text = l10n.statusDueNow;
        icon = Icons.alarm;
        break;
      case 'upcoming':
        color = Colors.blue;
        text = l10n.statusUpcoming;
        icon = Icons.schedule;
        break;
      case 'pending':
        color = Colors.blue;
        text = l10n.statusPending;
        icon = Icons.schedule;
        break;
      case 'active':
        color = Colors.blue;
        text = l10n.statusActive;
        icon = Icons.schedule;
        break;
      case 'missed':
        color = Colors.red;
        text = l10n.statusMissed;
        icon = Icons.warning_amber;
        break;
      case 'snoozed':
        color = Colors.orange;
        text = l10n.statusSnoozed;
        icon = Icons.snooze;
        break;
      case 'skipped':
        color = Colors.grey;
        text = l10n.statusSkipped;
        icon = Icons.skip_next;
        break;
      default:
        color = Colors.grey;
        text = status;
        icon = Icons.help;
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
    final l10n = AppLocalizations.of(context)!;
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
            _searchQuery.isEmpty
                ? l10n.noRemindersFound
                : l10n.noRemindersMatchSearch,
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.secondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isEmpty
                ? l10n.createFirstReminder
                : l10n.tryAdjustSearch,
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addNewReminder,
              icon: const Icon(Icons.add),
              label: Text(l10n.createReminder),
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
      case 'measurement':
        return Icons.monitor_heart;
      default:
        return Icons.notifications;
    }
  }

  String _formatTime(DateTime dateTime) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      final hours = difference.inHours.abs();
      final minutes = difference.inMinutes.abs() % 60;

      if (hours > 24) {
        return LocaleFormat.dateTimeMedium(context, dateTime);
      }
      if (hours > 0) {
        return LocaleFormat.localizeDigitsInText(
          context,
          l10n.timeHoursAgo(hours),
        );
      }
      return LocaleFormat.localizeDigitsInText(
        context,
        l10n.timeMinutesAgo(minutes),
      );
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final timeStr = LocaleFormat.time(context, dateTime);

    if (hours > 24) {
      return LocaleFormat.dateTimeMedium(context, dateTime);
    }
    if (hours > 0) {
      return LocaleFormat.localizeDigitsInText(
        context,
        l10n.timeInHours(hours, timeStr),
      );
    }
    if (minutes > 0) {
      return LocaleFormat.localizeDigitsInText(
        context,
        l10n.timeInMinutes(minutes, timeStr),
      );
    }
    return l10n.timeNow;
  }

  String _formatLocalizedDate(DateTime dateTime) {
    return LocaleFormat.dateShort(context, dateTime);
  }

  Future<TimeOfDay?> _showCustomTimePicker(
    BuildContext sheetContext, {
    required TimeOfDay initialTime,
  }) async {
    return CustomTimePickerSheet.show(
      sheetContext,
      initialTime: initialTime,
    );
  }

  void _toggleSearch() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _searchQuery = ' '; // Trigger search mode
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

  void _addNewReminder() {
    final l10n = AppLocalizations.of(context)!;
    final appLocale = Localizations.localeOf(context);
    final titleController = TextEditingController();
    var dosageText = '';
    String selectedType = 'medication';
    String selectedRecurrence = 'once';
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.newReminder,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                      labelText: l10n.reminderTitleLabel,
                      border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    labelText: l10n.dosageOptional,
                    hintText: l10n.dosageHint,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) => dosageText = v,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedType,
                  decoration: InputDecoration(
                      labelText: l10n.reminderTypeLabel,
                      border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(
                        value: 'medication', child: Text(l10n.medication)),
                    DropdownMenuItem(value: 'task', child: Text(l10n.task)),
                    DropdownMenuItem(
                        value: 'appointment', child: Text(l10n.appointment)),
                  ],
                  onChanged: (v) => setModal(() => selectedType = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedRecurrence,
                  decoration: InputDecoration(
                      labelText: l10n.repeatLabel,
                      border: const OutlineInputBorder()),
                  items: [
                    DropdownMenuItem(value: 'once', child: Text(l10n.once)),
                    DropdownMenuItem(value: 'daily', child: Text(l10n.daily)),
                    DropdownMenuItem(value: 'weekly', child: Text(l10n.weekly)),
                  ],
                  onChanged: (v) => setModal(() => selectedRecurrence = v!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_formatLocalizedDate(selectedDate)),
                        onPressed: () async {
                          final d = await showLocalizedDatePicker(
                            context,
                            locale: appLocale,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate:
                                DateTime.now().add(const Duration(days: 365)),
                          );
                          if (d != null)
                            setModal(() => selectedDate = DateTime(
                                d.year,
                                d.month,
                                d.day,
                                selectedTime.hour,
                                selectedTime.minute));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(selectedTime.format(context)),
                        onPressed: () async {
                          final t = await _showCustomTimePicker(
                            ctx,
                            initialTime: selectedTime,
                          );
                          if (t != null)
                            setModal(() {
                              selectedTime = t;
                              selectedDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  t.hour,
                                  t.minute);
                            });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4E59),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.pleaseEnterTitle)));
                        return;
                      }
                      final tzName = await FlutterTimezone.getLocalTimezone();
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      if (!mounted) return;
                      await _createReminderApi(
                        title: title,
                        type: selectedType,
                        scheduledTime: selectedDate,
                        recurrence: selectedRecurrence,
                        timezone: tzName,
                        dosage: dosageText.trim(),
                      );
                    },
                    child: Text(l10n.createReminder,
                        style: const TextStyle(color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _createReminderApi({
    required String title,
    required String type,
    required DateTime scheduledTime,
    required String recurrence,
    required String timezone,
    String dosage = '',
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final token = await _authService.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final payload = <String, dynamic>{
        'user_id': '',
        'reminder_type': type,
        'title': title,
        'scheduled_time': scheduledTime.toUtc().toIso8601String(),
        'timezone': timezone,
        'recurrence': recurrence,
      };
      if (dosage.isNotEmpty) {
        payload['context_data'] = {'dosage': dosage};
      }
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/api/reminders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode(payload),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final reminderId = data['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString();
        final serverMessage = data['message']?.toString().trim();

        // Schedule local notification immediately
        try {
          await NotificationService().scheduleFromReminderData(
            reminderId: reminderId,
            medicationName: title,
            dosage: dosage,
            scheduledTime: scheduledTime.toLocal(),
            reminderType: type,
            isRecurring: recurrence != 'once',
            recurrencePattern: recurrence,
            notificationBody: (serverMessage != null && serverMessage.isNotEmpty)
                ? serverMessage
                : null,
          );
        } catch (err) {
          debugPrint('Failed to schedule notification: $err');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.localNotificationSchedulingFailed('$err'))),
            );
          }
        }

        if (mounted)
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.reminderCreated)));
        _loadReminders();
      } else {
        throw Exception('Status ${response.statusCode}');
      }
    } catch (err) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToCreateReminder('$err'))));
    }
  }

  void _editReminder(Map<String, dynamic> reminder) {
    final id = reminder['id']?.toString();
    if (id == null || id.isEmpty) return;
    context.push('/patient/reminder/$id');
  }

  void _showEditReminderDialog(Map<String, dynamic> reminder) {
    final l10n = AppLocalizations.of(context)!;
    final appLocale = Localizations.localeOf(context);
    final id = reminder['id']?.toString() ?? '';
    if (id.isEmpty) return;

    final titleController =
        TextEditingController(text: reminder['title']?.toString() ?? '');
    DateTime selectedDate =
        (reminder['scheduledTime'] as DateTime?) ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(selectedDate);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.editReminder,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                      labelText: l10n.reminderTitleLabel,
                      border: const OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text(_formatLocalizedDate(selectedDate)),
                        onPressed: () async {
                          final d = await showLocalizedDatePicker(
                            context,
                            locale: appLocale,
                            initialDate: selectedDate,
                            firstDate: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            lastDate: DateTime.now()
                                .add(const Duration(days: 365)),
                          );
                          if (d != null) {
                            setModal(() => selectedDate = DateTime(
                                d.year,
                                d.month,
                                d.day,
                                selectedTime.hour,
                                selectedTime.minute));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: Text(selectedTime.format(context)),
                        onPressed: () async {
                          final t = await _showCustomTimePicker(
                            ctx,
                            initialTime: selectedTime,
                          );
                          if (t != null) {
                            setModal(() {
                              selectedTime = t;
                              selectedDate = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  t.hour,
                                  t.minute);
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4E59),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.pleaseEnterTitle)));
                        return;
                      }
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop();
                      final reminderType =
                          ReminderNotificationSync.readReminderType(reminder);
                      if (reminderType == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.cannotRescheduleMissingType),
                          ),
                        );
                        return;
                      }
                      await _updateReminderApi(
                          id: id,
                          title: title,
                          type: reminderType,
                          scheduledTime: selectedDate);
                    },
                    child: Text(l10n.saveChanges,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _updateReminderApi({
    required String id,
    required String title,
    required String type,
    required DateTime scheduledTime,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final token = await _authService.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final response = await http.put(
        Uri.parse('${Environment.apiBaseUrl}/api/reminders/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: json.encode({
          'title': title,
          'scheduled_time': scheduledTime.toUtc().toIso8601String(),
        }),
      );
      if (response.statusCode == 200) {
        // Reschedule local notification with new time
        try {
          await NotificationService().cancelFromReminderId(id);
          await NotificationService().scheduleFromReminderData(
            reminderId: id,
            medicationName: title,
            dosage: '',
            scheduledTime: scheduledTime.toLocal(),
            reminderType: type,
          );
        } catch (err) {
          debugPrint('Failed to reschedule notification: $err');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.reminderRescheduleFailed('$err'))),
            );
          }
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.reminderUpdated)));
          _loadReminders();
        }
      } else {
        throw Exception('Status ${response.statusCode}');
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.failedToUpdateReminder('$err'))));
      }
    }
  }

  void _markAsCompleted(String id) {
    _reminderAction(id, 'complete', success: AppLocalizations.of(context)!.reminderMarkedCompleted);
    // Cancel local notification for this reminder
    try {
      NotificationService().cancelFromReminderId(id);
    } catch (e) {
      debugPrint('Failed to cancel notification for completed reminder: $e');
    }
  }

  void _snoozeReminder(String id) {
    _reminderAction(id, 'snooze', success: AppLocalizations.of(context)!.reminderSnoozed30);
    // Cancel local notification for this reminder (will be rescheduled in snooze action)
    try {
      NotificationService().cancelFromReminderId(id);
    } catch (e) {
      debugPrint('Failed to cancel notification for snoozed reminder: $e');
    }
  }

  void _deleteReminder(String id) {
    _deleteReminderApi(id);
  }

  void _showAdherenceStats() {
    final l10n = AppLocalizations.of(context)!;
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
            // Header
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
                  Text(
                    l10n.medicationAdherence,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            // Stats Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overall adherence
                    _buildAdherenceStat(
                      l10n.thisWeek,
                      weekRate,
                      l10n.dosesCount(weekDone, weekReminders.length),
                    ),
                    const SizedBox(height: 16),
                    _buildAdherenceStat(
                      l10n.thisMonth,
                      monthRate,
                      l10n.dosesCount(monthDone, monthReminders.length),
                    ),
                    const SizedBox(height: 16),
                    _buildAdherenceStat(
                      l10n.overall,
                      overallRate,
                      l10n.dosesCount(totalDone, past.length),
                    ),

                    const SizedBox(height: 32),

                    if (medicationMap.isNotEmpty) ...[
                      Text(
                        l10n.byMedication,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...medicationMap.entries.map((entry) {
                        final rate = entry.value['total']! > 0
                            ? entry.value['done']! / entry.value['total']!
                            : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildMedicationAdherence(
                            entry.key,
                            rate,
                            l10n.dosesCount(
                                entry.value['done']!, entry.value['total']!),
                          ),
                        );
                      }),
                    ] else ...[
                      Center(
                        child: Text(
                          l10n.noPastRemindersAnalyze,
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Tips
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.lightbulb,
                                color: Colors.blue,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                l10n.adherenceTips,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            l10n.adherenceTipsBody,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: Colors.blue[700],
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
                LocaleFormat.percent(context, adherence * 100),
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
              LocaleFormat.percent(context, adherence * 100),
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

  Future<void> _loadReminders() async {
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
        return {
          'id': r['id']?.toString() ?? '',
          'title': r['title']?.toString() ?? 'Reminder',
          'description': r['message']?.toString() ?? '',
          'scheduledTime':
              (DateTime.tryParse(r['scheduled_time']?.toString() ?? '') ??
                      DateTime.now())
                  .toLocal(),
          'status':
              (r['display_status'] ?? r['status'])?.toString() ?? 'pending',
          'type': r['reminder_type']?.toString(),
          'dosage': null,
          'snoozeUntil': r['snooze_until'] != null
              ? DateTime.tryParse(r['snooze_until'].toString())
              : null,
          'snoozedCount': (r['snoozed_count'] as num?)?.toInt() ?? 0,
        };
      }).toList();
      if (!mounted) return;
      setState(() {
        _allReminders
          ..clear()
          ..addAll(mapped);
        _isLoading = false;
      });

      // Reschedule local notifications for all future pending reminders.
      await ReminderNotificationSync.syncPatientFromMapped(mapped);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  Future<void> _reminderAction(String id, String action,
      {required String success}) async {
    try {
      final token = await _authService.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final uri = action == 'snooze'
          ? Uri.parse(
              '${Environment.apiBaseUrl}/api/reminders/$id/snooze?snooze_minutes=30')
          : Uri.parse('${Environment.apiBaseUrl}/api/reminders/$id/$action');
      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );
      if (response.statusCode != 200) {
        if (action == 'snooze' && response.statusCode == 404 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.snoozeAlreadyUsed),
            ),
          );
          return;
        }
        throw Exception('Failed (${response.statusCode})');
      }
      await _loadReminders();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(success)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.actionFailed)));
    }
  }

  Future<void> _deleteReminderApi(String id) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final token = await _authService.getAccessToken();
      if (token == null) throw Exception('Authentication required');
      final response = await http.delete(
        Uri.parse('${Environment.apiBaseUrl}/api/reminders/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
      );
      if (response.statusCode != 204) throw Exception('Failed');
      await _loadReminders();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.reminderDeleted)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.deleteFailed)));
    }
  }
}
