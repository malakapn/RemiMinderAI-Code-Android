import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../shared/utilities/greeting_utils.dart';
import '../../data/models/patient_task.dart';
import '../../data/services/patient_tasks_api_service.dart';
import '../widgets/widgets.dart';

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen> {
  final AuthService _authService = AuthService();
  final PatientTasksApiService _tasksApiService = PatientTasksApiService();
  List<PatientTask> _tasks = [];
  bool _isLoadingTasks = true;
  bool _isLoadingUpNext = true;
  Map<String, dynamic>? _upNextReminder;
  List<Map<String, dynamic>> _todayReminders = [];
  bool _remindersError = false;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _fetchUpNextReminder();
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
          _upNextReminder =
              upcoming.isNotEmpty ? upcoming.first as Map<String, dynamic> : null;
          _todayReminders = today
              .whereType<Map<String, dynamic>>()
              .toList();
          _isLoadingUpNext = false;
          _remindersError = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _upNextReminder = null;
        _todayReminders = [];
        _isLoadingUpNext = false;
        _remindersError = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _upNextReminder = null;
        _todayReminders = [];
        _isLoadingUpNext = false;
        _remindersError = true;
      });
    }
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Coming soon')),
                  );
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
    final previewText = title?.trim().isNotEmpty == true ? title! : (message ?? '');
    final scheduledTime = reminder?['scheduled_time'] as String?;
    final screenHeight = MediaQuery.of(context).size.height;
    final maxPreviewHeight = screenHeight < 700
        ? 120.0
        : screenHeight < 850
            ? 160.0
            : 220.0;

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
            // Long AI-generated preview text can exceed card height.
            // Keep it readable by allowing vertical scrolling inside the card.
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxPreviewHeight),
              child: SingleChildScrollView(
                child: Text(
                  previewText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: reminder == null
                      ? null
                      : () {
                    // TODO: Mark as taken
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Marked as taken!')),
                    );
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
                onPressed: reminder == null
                    ? null
                    : () {
                  // TODO: Snooze reminder
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Reminder snoozed for 1 hour')),
                  );
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
          else if (_todayReminders.isEmpty)
            Text(
              'Nothing scheduled for today',
                  style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.secondary,
              ),
            )
          else
            Column(
              children: _todayReminders.map((reminder) {
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
                                  color:
                                      Theme.of(context).colorScheme.primary,
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('/patient/reminders');
              },
              icon: const Icon(Icons.add_alert_outlined),
              label: const Text('Add Reminder'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoList() {
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
          : _tasks.isEmpty
              ? const Center(
                  child: Text(
                    'No tasks yet',
                    style: TextStyle(fontSize: 14),
                  ),
                )
              : Column(
                  children: [
                    ..._tasks.map((task) {
                      return Column(
                        children: [
                          _buildTodoItem(
                            task.title,
                            _formatTaskCreatedAt(task.createdAt),
                            false,
                          ),
                          const Divider(height: 12),
                        ],
                      );
                    }),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Navigate to full todo list
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Task'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
    final scheduled = DateTime.tryParse(scheduledTime);
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
    final scheduled = DateTime.tryParse(scheduledTime);
    if (scheduled == null) {
      return scheduledTime;
    }
    final hour = scheduled.hour;
    final minute = scheduled.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour % 12 == 0 ? 12 : hour % 12;
    return '$hour12:$minute $period';
  }

}
