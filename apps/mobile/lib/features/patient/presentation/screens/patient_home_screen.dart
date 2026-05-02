import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../shared/utilities/greeting_utils.dart';
import '../../data/models/patient_task.dart';
import '../../data/models/summary_item.dart';
import '../../data/services/patient_api_service.dart';
import '../../data/services/patient_tasks_api_service.dart';
import '../widgets/widgets.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen>
    with WidgetsBindingObserver {
  static const Color _visitTodoMedColor = Color(0xFF00897B);
  static const Color _visitTodoFollowColor = Color(0xFFC9A227);
  static const Color _visitTodoLifestyleColor = Color(0xFF1976D2);

  final AuthService _authService = AuthService();
  final PatientTasksApiService _tasksApiService = PatientTasksApiService();
  List<PatientTask> _tasks = [];
  bool _isLoadingTasks = true;
  bool _isLoadingUpNext = true;
  Map<String, dynamic>? _upNextReminder;
  List<Map<String, dynamic>> _todayReminders = [];
  List<Map<String, dynamic>> _upcomingReminders = [];
  bool _remindersError = false;
  bool _showAllTodoItems = false;

  bool _loadingVisitSummaryTodos = true;
  List<String> _visitSummaryMedications = [];
  List<String> _visitSummaryFollowUps = [];
  List<String> _visitSummaryLifestyle = [];
  final Set<String> _checkedVisitSummaryKeys = {};
  String? _visitSummarySourceLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchTasks();
    _fetchUpNextReminder();
    _fetchVisitSummaryTodos();
    _requestNotificationPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchTasks();
      _fetchUpNextReminder();
      _fetchVisitSummaryTodos();
    }
  }

  Future<void> _requestNotificationPermissions() async {
    final svc = NotificationService();
    await svc.requestPermissions();
    await svc.requestExactAlarmPermission();
  }

  Future<void> _rescheduleAllNotifications(List<dynamic> reminders) async {
    final svc = NotificationService();
    final now = DateTime.now();
    for (final raw in reminders) {
      if (raw is! Map) continue;
      final scheduledStr = raw['scheduled_time']?.toString() ?? '';
      final scheduledTime = DateTime.tryParse(scheduledStr)?.toLocal();
      if (scheduledTime == null || scheduledTime.isBefore(now)) continue;
      final id = raw['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      try {
        await svc.scheduleFromReminderData(
          reminderId: id,
          medicationName: raw['title']?.toString() ?? 'Reminder',
          dosage: '',
          scheduledTime: scheduledTime,
          notificationBody: raw['message']?.toString(),
        );
      } catch (_) {}
    }
  }

  Future<void> _fetchTasks() async {
    try {
      final tasks = await _tasksApiService.fetchTasks();
      if (!mounted) return;
      setState(() {
        _tasks = tasks;
        _isLoadingTasks = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _tasks = [];
        _isLoadingTasks = false;
      });
    }
  }

  Future<void> _fetchUpNextReminder() async {
    try {
      final accessToken = await _authService.getAccessToken();
      if (accessToken == null) {
        throw Exception('Authentication required');
      }

      final uri = Uri.parse('${Environment.apiBaseUrl}/api/reminders');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final upcoming = data['upcoming'] as List<dynamic>? ?? [];
        final today = data['today'] as List<dynamic>? ?? [];
        if (!mounted) return;
        setState(() {
          _upNextReminder = upcoming.isNotEmpty
              ? upcoming.first as Map<String, dynamic>
              : null;
          _todayReminders = today.whereType<Map<String, dynamic>>().toList();
          _upcomingReminders =
              upcoming.whereType<Map<String, dynamic>>().toList();
          _isLoadingUpNext = false;
          _remindersError = false;
        });
        // Reschedule notifications immediately on login so nothing is missed
        _rescheduleAllNotifications([...upcoming, ...today]);
        return;
      }
      if (!mounted) return;
      setState(() {
        _upNextReminder = null;
        _todayReminders = [];
        _upcomingReminders = [];
        _isLoadingUpNext = false;
        _remindersError = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _upNextReminder = null;
        _todayReminders = [];
        _upcomingReminders = [];
        _isLoadingUpNext = false;
        _remindersError = true;
      });
    }
  }

  Future<void> _fetchVisitSummaryTodos() async {
    try {
      final accessToken = await _authService.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        if (!mounted) return;
        setState(() {
          _loadingVisitSummaryTodos = false;
          _visitSummaryMedications = [];
          _visitSummaryFollowUps = [];
          _visitSummaryLifestyle = [];
          _visitSummarySourceLabel = null;
        });
        return;
      }

      final api = PatientApiService(
        baseUrl: Environment.apiBaseUrl,
        authToken: accessToken,
      );
      final summaries = await api.getSummaries();
      if (summaries.isEmpty) {
        if (!mounted) return;
        setState(() {
          _visitSummaryMedications = [];
          _visitSummaryFollowUps = [];
          _visitSummaryLifestyle = [];
          _loadingVisitSummaryTodos = false;
          _visitSummarySourceLabel = null;
        });
        return;
      }

      final visitId = summaries.first.visitId;
      final sourceSummary = summaries.first;
      final structured = await api.getVisitSummaryStructured(visitId);
      if (!mounted) return;

      if (structured['status'] == 'processing') {
        setState(() {
          _visitSummaryMedications = [];
          _visitSummaryFollowUps = [];
          _visitSummaryLifestyle = [];
          _loadingVisitSummaryTodos = false;
          _visitSummarySourceLabel =
              _formatVisitSourceLine(sourceSummary);
        });
        return;
      }

      setState(() {
        _visitSummaryMedications =
            _toSummaryStringList(structured['medications']);
        _visitSummaryFollowUps =
            _toSummaryStringList(structured['decisions']);
        _visitSummaryLifestyle = _toSummaryStringList(structured['actions']);
        _loadingVisitSummaryTodos = false;
        _visitSummarySourceLabel = _formatVisitSourceLine(sourceSummary);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingVisitSummaryTodos = false;
        _visitSummaryMedications = [];
        _visitSummaryFollowUps = [];
        _visitSummaryLifestyle = [];
        _visitSummarySourceLabel = null;
      });
    }
  }

  List<String> _toSummaryStringList(dynamic value) {
    if (value is List) {
      return value
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return [value.trim()];
    }
    return [];
  }

  /// e.g. "From: Medical Visit · May 2, 2026"
  String _formatVisitSourceLine(SummaryItem s) {
    final title = (s.title?.trim().isNotEmpty == true)
        ? s.title!.trim()
        : '${s.specialty} Visit';
    DateTime? dt;
    final vd = s.visitDate;
    if (vd != null && vd.trim().isNotEmpty) {
      dt = DateTime.tryParse(vd.trim());
    }
    dt ??= DateTime.tryParse(s.summaryCreatedAt);
    final datePart =
        dt != null ? DateFormat('MMM d, y').format(dt.toLocal()) : '';
    if (datePart.isEmpty) {
      return 'From: $title';
    }
    return 'From: $title · $datePart';
  }

  void _toggleVisitSummaryCheck(String key) {
    setState(() {
      if (_checkedVisitSummaryKeys.contains(key)) {
        _checkedVisitSummaryKeys.remove(key);
      } else {
        _checkedVisitSummaryKeys.add(key);
      }
    });
  }

  void _openSetReminderFromSummary(String medicationLine) {
    final encoded = Uri.encodeComponent(medicationLine);
    context.go('/patient/reminders?add=1&prefill_title=$encoded');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final userName = authState.profile?.fullName ?? 'Patient';
    final greeting =
        GreetingUtils.getTimeBasedGreeting(); // Just the greeting part
    final firstName = userName.split(' ').first; // Extract first name only

    return Column(
      children: [
        // App Bar equivalent - convert to a regular Container
        Container(
          color: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0)
              .copyWith(top: MediaQuery.of(context).padding.top + 16.0),
          child: Row(
            children: [
              // Enhanced User Avatar with Gradient (compact)
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
                  Icons.person,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              // Enhanced Welcome Text (greeting + name layout)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Greeting line
                    Text(
                      greeting,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    // First name with sparkle
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
                    // Subtitle
                    Text(
                      'How are you feeling today?',
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
                onPressed: () {
                  context.go('/patient/notifications');
                },
              ),
            ],
          ),
        ),

        // Main content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),

                // Up Next Card
                _buildUpNextCard(),

                const SizedBox(height: 32),

                // Today's Schedule
                const SectionHeader(
                  title: 'Today\'s Schedule',
                  icon: Icons.schedule,
                ),
                const SizedBox(height: 16),
                _buildTodaysSchedule(),

                const SizedBox(height: 32),

                // Visit summary checklist (latest AI summary)
                const SectionHeader(
                  title: 'After-visit to-dos',
                  icon: Icons.health_and_safety_outlined,
                ),
                const SizedBox(height: 16),
                _buildVisitSummaryTodos(),

                const SizedBox(height: 32),

                // To-do List
                const SectionHeader(
                  title: 'To-do List',
                  icon: Icons.checklist,
                ),
                const SizedBox(height: 16),
                _buildTodoList(),

                // Extra space for bottom navigation - this will be handled by the app shell
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpNextCard() {
    final reminder = _upNextReminder;
    final title = reminder?['title'] as String?;
    final message = reminder?['message'] as String?;
    final scheduledTime = reminder?['scheduled_time'] as String?;

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
                Icons.alarm,
                color: Colors.white,
                size: 28,
              ),
              const SizedBox(width: 12),
              Text(
                'Up Next',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoadingUpNext)
            const Center(child: CircularProgressIndicator())
          else if (reminder == null)
            Text(
              'No upcoming reminders',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            )
          else ...[
            Text(
              title?.trim().isNotEmpty == true ? title! : (message ?? ''),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatDueText(scheduledTime),
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
          ],
          const SizedBox(height: 20),
          if (reminder == null)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/patient/reminders?add=1'),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add Reminder',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      _handleReminderAction(
                          reminder['id']?.toString(), 'complete');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text(
                      'Take Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  onPressed: () {
                    _handleReminderAction(
                        reminder['id']?.toString(), 'snooze');
                  },
                  icon: const Icon(Icons.snooze, color: Colors.white),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.2),
                    padding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildTodaysSchedule() {
    final scheduleReminders = _todayReminders.where((reminder) {
      final rawType = (reminder['reminder_type'] ?? reminder['type'] ?? '')
          .toString()
          .trim()
          .toLowerCase();
      return rawType == 'medication' || rawType == 'appointment';
    }).toList();

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
        children: [
          if (_isLoadingUpNext)
            const Center(child: CircularProgressIndicator())
          else if (_remindersError)
            Text(
              'Nothing scheduled for today',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
            )
          else if (scheduleReminders.isEmpty)
            Text(
              'Nothing scheduled for today',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
            )
          else
            Column(
              children: scheduleReminders.map((reminder) {
                final title = reminder['title'] as String?;
                final message = reminder['message'] as String?;
                final scheduledTime = reminder['scheduled_time'] as String?;
                return Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .secondary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.schedule,
                            color: Theme.of(context).colorScheme.secondary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title?.trim().isNotEmpty == true
                                    ? title!
                                    : (message ?? ''),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                _formatScheduleTime(scheduledTime),
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
                    ),
                    const Divider(height: 12),
                  ],
                );
              }).toList(),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.go('/patient/reminders');
                  },
                  child: const Text('View All'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    context.go('/patient/reminders?add=1');
                  },
                  child: const Text('Add Item'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisitSummaryTodos() {
    final hasItems = _visitSummaryMedications.isNotEmpty ||
        _visitSummaryFollowUps.isNotEmpty ||
        _visitSummaryLifestyle.isNotEmpty;

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
      child: _loadingVisitSummaryTodos
          ? const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: CircularProgressIndicator(),
              ),
            )
          : !hasItems
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_visitSummarySourceLabel != null) ...[
                      Text(
                        _visitSummarySourceLabel!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      'When your latest visit summary is ready, medications, follow-ups, and lifestyle actions will show here.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_visitSummarySourceLabel != null) ...[
                      Text(
                        _visitSummarySourceLabel!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (_visitSummaryMedications.isNotEmpty) ...[
                      Text(
                        'Medications',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _visitTodoMedColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._visitSummaryMedications.asMap().entries.map((e) {
                        final key = 'med:${e.key}';
                        final done = _checkedVisitSummaryKeys.contains(key);
                        return _visitSummaryTodoTile(
                          keyId: key,
                          label: e.value,
                          isDone: done,
                          accentColor: _visitTodoMedColor,
                          trailing: TextButton.icon(
                            onPressed: () =>
                                _openSetReminderFromSummary(e.value),
                            icon: const Icon(Icons.add_alarm, size: 18),
                            label: const Text('+ Set reminder'),
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    if (_visitSummaryFollowUps.isNotEmpty) ...[
                      Text(
                        'Follow-up appointments & decisions',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _visitTodoFollowColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._visitSummaryFollowUps.asMap().entries.map((e) {
                        final key = 'follow:${e.key}';
                        final done = _checkedVisitSummaryKeys.contains(key);
                        return _visitSummaryTodoTile(
                          keyId: key,
                          label: e.value,
                          isDone: done,
                          accentColor: _visitTodoFollowColor,
                          trailing: null,
                        );
                      }),
                      const SizedBox(height: 16),
                    ],
                    if (_visitSummaryLifestyle.isNotEmpty) ...[
                      Text(
                        'Lifestyle actions',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _visitTodoLifestyleColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ..._visitSummaryLifestyle.asMap().entries.map((e) {
                        final key = 'life:${e.key}';
                        final done = _checkedVisitSummaryKeys.contains(key);
                        return _visitSummaryTodoTile(
                          keyId: key,
                          label: e.value,
                          isDone: done,
                          accentColor: _visitTodoLifestyleColor,
                          trailing: null,
                        );
                      }),
                    ],
                  ],
                ),
    );
  }

  Widget _visitSummaryTodoTile({
    required String keyId,
    required String label,
    required bool isDone,
    required Color accentColor,
    Widget? trailing,
  }) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: accentColor.withOpacity(0.07),
            border: Border(
              left: BorderSide(width: 4, color: accentColor),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: isDone,
                activeColor: accentColor,
                onChanged: (_) => _toggleVisitSummaryCheck(keyId),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      decoration:
                          isDone ? TextDecoration.lineThrough : null,
                      color: isDone
                          ? Theme.of(context)
                              .colorScheme
                              .secondary
                              .withOpacity(0.6)
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              if (trailing != null) trailing,
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTodoList() {
    final allReminderTasks = [..._todayReminders, ..._upcomingReminders];
    final reminderTasks = allReminderTasks
        .where((r) {
          final rawType = (r['reminder_type'] ?? r['type'] ?? '')
              .toString()
              .trim()
              .toLowerCase();
          return rawType == 'task';
        })
        .toList();
    final hasAnyTodos = _tasks.isNotEmpty || reminderTasks.isNotEmpty;
    final todoRows = <Map<String, String>>[
      ..._tasks.map((task) => {
            'title': task.title,
            'due': _formatTaskCreatedAt(task.createdAt),
          }),
      ...reminderTasks.map((taskReminder) {
        final title = (taskReminder['title'] as String?)?.trim().isNotEmpty ==
                true
            ? taskReminder['title'] as String
            : 'Task reminder';
        final due = _formatDueText(
          taskReminder['scheduled_time']?.toString(),
        );
        return {
          'title': title,
          'due': due,
        };
      }),
    ];
    final visibleTodoRows =
        _showAllTodoItems ? todoRows : todoRows.take(3).toList();
    final hasHiddenRows = todoRows.length > 3;

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
      child: _isLoadingTasks
          ? const Center(child: CircularProgressIndicator())
          : !hasAnyTodos
              ? const Center(
                  child: Text(
                    'No tasks yet',
                    style: TextStyle(fontSize: 14),
                  ),
                )
              : Column(
                  children: [
                    ...visibleTodoRows.map((row) {
                      return Column(
                        children: [
                          _buildTodoItem(
                            row['title'] ?? 'Task',
                            row['due'] ?? 'Upcoming',
                            false,
                          ),
                          const Divider(height: 12),
                        ],
                      );
                    }),
                    if (hasHiddenRows)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _showAllTodoItems = !_showAllTodoItems;
                            });
                          },
                          icon: Icon(
                            _showAllTodoItems
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          label: Text(
                            _showAllTodoItems ? 'Show less' : 'Show more',
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }

  Widget _buildTodoItem(String title, String dueDate, bool isCompleted) {
    return Row(
      children: [
        Checkbox(
          value: isCompleted,
          onChanged: (value) {
            // TODO: Update todo status
          },
          activeColor: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isCompleted
                      ? Theme.of(context).colorScheme.secondary.withOpacity(0.6)
                      : Theme.of(context).colorScheme.primary,
                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                ),
              ),
              Text(
                dueDate,
                style: TextStyle(
                  fontSize: 12,
                  color:
                      Theme.of(context).colorScheme.secondary.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
        if (isCompleted)
          const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 20,
          ),
      ],
    );
  }

  String _formatTaskCreatedAt(DateTime? createdAt) {
    if (createdAt == null) {
      return 'Added recently';
    }
    return 'Added ${createdAt.month}/${createdAt.day}/${createdAt.year}';
  }

  String _formatDueText(String? scheduledTime) {
    if (scheduledTime == null || scheduledTime.trim().isEmpty) {
      return 'Upcoming';
    }
    final scheduled = DateTime.tryParse(scheduledTime)?.toLocal();
    if (scheduled == null) {
      return 'Upcoming';
    }
    final now = DateTime.now();
    final diff = scheduled.difference(now);
    if (diff.inMinutes <= 0) {
      return 'Due now';
    }
    if (diff.inMinutes < 60) {
      return 'Due in ${diff.inMinutes} min';
    }
    if (diff.inHours < 24) {
      return 'Due in ${diff.inHours} hours';
    }
    if (diff.inDays < 7) {
      return 'Due in ${diff.inDays} days';
    }
    return 'Due ${scheduled.month}/${scheduled.day}';
  }

  String _formatScheduleTime(String? scheduledTime) {
    if (scheduledTime == null || scheduledTime.trim().isEmpty) {
      return '';
    }
    final scheduled = DateTime.tryParse(scheduledTime)?.toLocal();
    if (scheduled == null) {
      return scheduledTime;
    }
    final hour = scheduled.hour;
    final minute = scheduled.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
  }

  Future<void> _handleReminderAction(String? reminderId, String action) async {
    if (reminderId == null || reminderId.isEmpty) return;
    try {
      final accessToken = await _authService.getAccessToken();
      if (accessToken == null) throw Exception('Authentication required');
      final response = await http.post(
        Uri.parse(
            '${Environment.apiBaseUrl}/api/reminders/$reminderId/$action'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode != 200) throw Exception('Action failed');
      await _fetchUpNextReminder();
      if (!mounted) return;
      final actionText = action == 'complete' ? 'taken' : 'snoozed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder $actionText')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update reminder')),
      );
    }
  }

}
