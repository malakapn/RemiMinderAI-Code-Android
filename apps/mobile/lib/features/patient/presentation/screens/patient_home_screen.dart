import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/data/models/auth_state.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/config/environment.dart';
import '../../../../core/config/theme.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/widgets/upgrade_prompt_sheet.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../../l10n/app_localizations.dart';
import '../../data/models/patient_task.dart';
import '../../data/services/patient_tasks_api_service.dart';
import '../../../shared/widgets/scroll_bottom_fade.dart';

// Home screen palette (iOS ASC parity)
const Color _teal = AppTheme.primaryColor;
const Color _tealMid = Color(0xFF2A5478);
const Color _cream = AppTheme.backgroundColor;
const Color _gold = Color(0xFFC9A84C);
const Color _goldLight = Color(0xFFF0D080);
const Color _white20 = Color(0x33FFFFFF);

class PatientHomeScreen extends ConsumerStatefulWidget {
  const PatientHomeScreen({super.key});

  @override
  ConsumerState<PatientHomeScreen> createState() => _PatientHomeScreenState();
}

class _PatientHomeScreenState extends ConsumerState<PatientHomeScreen>
    with WidgetsBindingObserver {
  final AuthService _authService = AuthService();
  final PatientTasksApiService _tasksApiService = PatientTasksApiService();
  List<PatientTask> _tasks = [];
  List<Map<String, dynamic>> _taskReminders = [];
  bool _isLoadingTasks = true;
  bool _isLoadingUpNext = true;
  List<Map<String, dynamic>> _scheduleReminders = [];
  bool _remindersError = false;
  bool _trialExpiredPromptInFlight = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshHomeData());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshHomeData();
    }
  }

  Future<void> _refreshHomeData() async {
    await Future.wait([_fetchTasks(), _fetchUpNextReminder()]);
  }

  bool _isTaskReminder(Map<String, dynamic> reminder) {
    final type =
        (reminder['reminder_type'] ?? reminder['type'] ?? '').toString();
    return type == 'task';
  }

  bool _isScheduleReminder(Map<String, dynamic> reminder) {
    if (_isTaskReminder(reminder)) return false;
    final type = (reminder['reminder_type'] ?? reminder['type'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    return type.isEmpty || type == 'medication' || type == 'appointment';
  }

  bool _isActiveReminder(Map<String, dynamic> reminder) {
    final status = (reminder['display_status'] ?? reminder['status'] ?? 'pending')
        .toString()
        .toLowerCase();
    return status != 'completed' &&
        status != 'complete' &&
        status != 'done' &&
        status != 'skipped' &&
        status != 'cancelled';
  }

  int _scheduledSortKey(Map<String, dynamic> reminder) {
    final scheduled = DateTime.tryParse(
          reminder['scheduled_time']?.toString() ?? '',
        ) ??
        DateTime.fromMillisecondsSinceEpoch(0);
    return scheduled.millisecondsSinceEpoch;
  }

  List<Map<String, dynamic>> _dedupeReminders(List<Map<String, dynamic>> items) {
    final seen = <String>{};
    final deduped = <Map<String, dynamic>>[];
    for (final reminder in items) {
      if (!_isActiveReminder(reminder)) continue;
      final id = reminder['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        if (seen.contains(id)) continue;
        seen.add(id);
      }
      deduped.add(reminder);
    }
    deduped.sort(
      (a, b) => _scheduledSortKey(a).compareTo(_scheduledSortKey(b)),
    );
    return deduped;
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
      var accessToken = await _authService.getAccessToken();
      if (accessToken == null) {
        await Future<void>.delayed(const Duration(milliseconds: 400));
        accessToken = await _authService.getAccessToken();
      }
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
        final upcoming = (data['upcoming'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        final today = (data['today'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        final past = (data['past'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .toList();
        final merged = [...today, ...upcoming, ...past];

        final taskReminders = <Map<String, dynamic>>[];
        final seenTaskIds = <String>{};
        for (final reminder in merged) {
          if (!_isTaskReminder(reminder) || !_isActiveReminder(reminder)) {
            continue;
          }
          final id = reminder['id']?.toString() ?? '';
          if (id.isNotEmpty && seenTaskIds.contains(id)) continue;
          if (id.isNotEmpty) seenTaskIds.add(id);
          taskReminders.add(reminder);
        }

        final scheduleList = _dedupeReminders(
          merged.where(_isScheduleReminder).toList(),
        );

        if (!mounted) return;
        setState(() {
          _scheduleReminders = scheduleList;
          _taskReminders = taskReminders;
          _isLoadingUpNext = false;
          _remindersError = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _scheduleReminders = [];
        _taskReminders = [];
        _isLoadingUpNext = false;
        _remindersError = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _scheduleReminders = [];
        _taskReminders = [];
        _isLoadingUpNext = false;
        _remindersError = true;
      });
    }
  }

  // ── UI-only helpers (used by build methods below) ──

  TextStyle _bodyStyle(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium!.copyWith(fontFamily: 'Poppins');

  TextStyle _headerStyle(BuildContext context) =>
      Theme.of(context).textTheme.headlineSmall!.copyWith(
            fontFamily: 'Merriweather',
            fontWeight: FontWeight.w700,
          );

  bool _isReminderDone(Map<String, dynamic> reminder) {
    final status =
        (reminder['display_status'] ?? reminder['status'] ?? '')
            .toString()
            .toLowerCase();
    return status == 'completed' ||
        status == 'complete' ||
        status == 'done';
  }

  bool _isTaskDone(PatientTask task) {
    return task.status.toLowerCase() == 'completed';
  }

  Color _reminderAccentColor(Map<String, dynamic> reminder) {
    final colorValue = reminder['color'];
    if (colorValue is int) {
      return Color(colorValue);
    }
    if (colorValue is String && colorValue.isNotEmpty) {
      var hex = colorValue.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      final parsed = int.tryParse(hex, radix: 16);
      if (parsed != null) {
        return Color(parsed);
      }
    }
    return _goldLight;
  }

  /// Active medication/appointment reminders from today onward (local calendar).
  List<Map<String, dynamic>> get _displayScheduleReminders =>
      _scheduleReminders.where((reminder) {
        final scheduled =
            _parseScheduledTimeLocal(reminder['scheduled_time']?.toString());
        if (scheduled == null) return true;
        return _isTodayOrFuture(scheduled);
      }).toList();

  int get _todayDoneCount => _scheduleReminders
      .where((reminder) {
        final scheduled =
            _parseScheduledTimeLocal(reminder['scheduled_time']?.toString());
        return scheduled != null &&
            _isScheduledToday(scheduled) &&
            _isReminderDone(reminder);
      })
      .length;

  int get _todayTotalCount => _scheduleReminders
      .where((reminder) {
        final scheduled =
            _parseScheduledTimeLocal(reminder['scheduled_time']?.toString());
        return scheduled != null && _isScheduledToday(scheduled);
      })
      .length;

  double get _todayProgressValue {
    if (_todayTotalCount == 0) return 0;
    return _todayDoneCount / _todayTotalCount;
  }

  int get _pendingTaskCount {
    final pendingTasks = _tasks.where((task) => !_isTaskDone(task)).length;
    final pendingTaskReminders =
        _taskReminders.where((reminder) => !_isReminderDone(reminder)).length;
    return pendingTasks + pendingTaskReminders;
  }

  String _timeBasedGreeting(AppLocalizations l10n) {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      return l10n.goodMorning;
    }
    if (hour >= 12 && hour < 17) {
      return l10n.goodAfternoon;
    }
    if (hour >= 17 && hour < 22) {
      return l10n.goodEvening;
    }
    return l10n.goodNight;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authNotifierProvider, (previous, next) {
      if (next.isAuthenticated && previous?.isAuthenticated != true) {
        _refreshHomeData();
      }
      _maybeShowTrialExpiredPrompt(next);
    });

    final authState = ref.watch(authNotifierProvider);
    final l10n = AppLocalizations.of(context)!;
    final userName = LocaleFormat.displayName(
      context,
      authState.profile?.fullName ?? '',
      fallback: l10n.defaultPatient,
    );
    final greeting = _timeBasedGreeting(l10n);
    final firstName = userName.split(' ').first;

    return ColoredBox(
      color: _cream,
      child: Column(
        children: [
          _buildHeader(
            greeting: greeting,
            firstName: firstName,
            l10n: l10n,
          ),
          Expanded(
            child: ScrollBottomFade.builder(
              fadeColor: _cream,
              builder: (context, controller) => RefreshIndicator(
                color: _teal,
                onRefresh: _refreshHomeData,
                child: SingleChildScrollView(
                  controller: controller,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildScheduleSectionHeader(l10n),
                      const SizedBox(height: 12),
                      _buildTodaysSchedule(l10n),
                      const SizedBox(height: 28),
                      _buildTasksSectionHeader(l10n),
                      const SizedBox(height: 12),
                      _buildTodoList(l10n),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _maybeShowTrialExpiredPrompt(AuthState authState) async {
    final profile = authState.profile;
    final userId = authState.user?.id;
    if (_trialExpiredPromptInFlight ||
        profile == null ||
        userId == null ||
        !profile.isExpired) {
      return;
    }
    _trialExpiredPromptInFlight = true;
    final prefs = await SharedPreferences.getInstance();
    final key = 'trial_expired_prompt_shown_$userId';
    if (prefs.getBool(key) == true || !mounted) {
      _trialExpiredPromptInFlight = false;
      return;
    }
    await prefs.setBool(key, true);
    if (!mounted) return;
    await showUpgradePromptSheet(
      context,
      reason: UpgradePromptReason.trialExpired,
      screen: 'patient_home',
    );
    _trialExpiredPromptInFlight = false;
  }

  Widget _buildHeader({
    required String greeting,
    required String firstName,
    required AppLocalizations l10n,
  }) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topPadding + 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_teal, _tealMid],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: _white20,
                child: Icon(
                  Icons.person_outline,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: _bodyStyle(context).copyWith(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$firstName ✨',
                      style: _headerStyle(context).copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.howAreYouFeeling,
                      style: _bodyStyle(context).copyWith(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildProgressCard(l10n),
        ],
      ),
    );
  }

  Widget _buildProgressCard(AppLocalizations l10n) {
    final done = _todayDoneCount;
    final total = _todayTotalCount;
    final percent = total == 0 ? 0 : ((done / total) * 100).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.todaysProgress,
                  style: _bodyStyle(context).copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  LocaleFormat.localizeDigitsInText(
                    context,
                    l10n.doneCount(done, total),
                  ),
                  style: _headerStyle(context).copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 58,
            height: 58,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator.adaptive(
                  value: _todayProgressValue,
                  strokeWidth: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  valueColor: const AlwaysStoppedAnimation<Color>(_goldLight),
                ),
                Text(
                  LocaleFormat.localizeDigitsInText(context, '$percent%'),
                  style: _bodyStyle(context).copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleSectionHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(Icons.access_time_rounded, color: _teal, size: 22),
        const SizedBox(width: 8),
        Text(
          l10n.yourSchedule,
          style: _headerStyle(context).copyWith(
            fontSize: 17,
            color: _teal,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: () => context.go('/patient/reminders'),
          style: TextButton.styleFrom(
            foregroundColor: _teal,
            padding: EdgeInsets.zero,
            minimumSize: const Size(44, 44),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.seeAll,
            style: _bodyStyle(context).copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _teal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTasksSectionHeader(AppLocalizations l10n) {
    return Row(
      children: [
        const Icon(Icons.check_circle_outline, color: _teal, size: 22),
        const SizedBox(width: 8),
        Text(
          l10n.myTasks,
          style: _headerStyle(context).copyWith(
            fontSize: 17,
            color: _teal,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            LocaleFormat.localizeDigitsInText(
              context,
              l10n.pendingCount(_pendingTaskCount),
            ),
            style: _bodyStyle(context).copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _teal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodaysSchedule(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_isLoadingUpNext)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: CircularProgressIndicator(color: _teal),
            )
          else if (_remindersError)
            _buildEmptyScheduleMessage(l10n.unableToLoadReminders)
          else if (_displayScheduleReminders.isEmpty)
            _buildEmptyScheduleMessage(l10n.nothingScheduledYet)
          else
            Column(
              children: [
                for (var i = 0; i < _displayScheduleReminders.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 20,
                      color: _teal.withValues(alpha: 0.06),
                    ),
                  _buildScheduleRow(_displayScheduleReminders[i], l10n),
                ],
              ],
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('/patient/reminders');
              },
              icon: const Icon(Icons.add_alert_outlined, color: _gold),
              label: Text(
                l10n.addReminder,
                style: _bodyStyle(context).copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScheduleMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        message,
        style: _bodyStyle(context).copyWith(
          fontSize: 14,
          color: _teal.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  Widget _buildScheduleRow(
    Map<String, dynamic> reminder,
    AppLocalizations l10n,
  ) {
    final title = reminder['title'] as String?;
    final message = reminder['message'] as String?;
    final scheduledTime = reminder['scheduled_time'] as String?;
    final label = title?.trim().isNotEmpty == true
        ? LocaleFormat.reminderTitle(l10n, title)
        : LocaleFormat.reminderCardDescription(
            l10n,
            title: title,
            description: message,
          );
    final isDone = _isReminderDone(reminder);
    final accent = _reminderAccentColor(reminder);
    final scheduledLocal = _parseScheduledTimeLocal(scheduledTime);
    final isFutureDay = scheduledLocal != null && !_isScheduledToday(scheduledLocal);

    return Opacity(
      opacity: isDone ? 0.55 : 1,
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 32,
            color: isDone ? accent : accent.withValues(alpha: 0.35),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: _bodyStyle(context).copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _teal,
                    decoration:
                        isDone ? TextDecoration.lineThrough : null,
                  ),
                ),
                if (LocaleFormat.scheduleTime(
                  context,
                  _parseScheduledTimeLocal(scheduledTime),
                  includeDate: isFutureDay,
                ).isNotEmpty)
                  Text(
                    LocaleFormat.scheduleTime(
                      context,
                      _parseScheduledTimeLocal(scheduledTime),
                      includeDate: isFutureDay,
                    ),
                    style: _bodyStyle(context).copyWith(
                      fontSize: 12,
                      color: _teal.withValues(alpha: 0.55),
                    ),
                  ),
              ],
            ),
          ),
          _buildStatusPill(
            label: isDone
                ? l10n.statusDone
                : (isFutureDay ? l10n.statusScheduled : l10n.statusUpcoming),
            background: isDone
                ? _teal.withValues(alpha: 0.1)
                : _gold.withValues(alpha: 0.15),
            foreground: isDone ? _teal : _tealMid,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill({
    required String label,
    required Color background,
    required Color foreground,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: _bodyStyle(context).copyWith(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildTodoList(AppLocalizations l10n) {
    final isLoading = _isLoadingTasks || _isLoadingUpNext;
    final hasTasks = _tasks.isNotEmpty || _taskReminders.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _teal.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: CircularProgressIndicator(color: _teal),
              ),
            )
          else if (!hasTasks)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                l10n.noTasksYet,
                style: _bodyStyle(context).copyWith(
                  fontSize: 14,
                  color: _teal.withValues(alpha: 0.6),
                ),
              ),
            )
          else
            Column(
              children: [
                for (final reminder in _taskReminders) ...[
                  _buildTodoItem(
                    title: (reminder['title'] as String?)?.trim().isNotEmpty ==
                            true
                        ? reminder['title'] as String
                        : (reminder['message'] as String? ?? 'Task'),
                    subtitle: LocaleFormat.dueLabel(
                      context,
                      _parseScheduledTimeLocal(
                        reminder['scheduled_time'] as String?,
                      ),
                      l10n,
                    ),
                    tag: l10n.reminder,
                    isCompleted: _isReminderDone(reminder),
                  ),
                  Divider(
                    height: 20,
                    color: _teal.withValues(alpha: 0.06),
                  ),
                ],
                for (final task in _tasks) ...[
                  _buildTodoItem(
                    title: task.title,
                    subtitle: task.createdAt != null
                        ? LocaleFormat.dateShort(context, task.createdAt!)
                        : l10n.timeNow,
                    tag: task.type.isNotEmpty ? task.type : l10n.task,
                    isCompleted: _isTaskDone(task),
                  ),
                  Divider(
                    height: 20,
                    color: _teal.withValues(alpha: 0.06),
                  ),
                ],
              ],
            ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                context.go('/patient/reminders');
              },
              icon: const Icon(Icons.add, color: _teal),
              label: Text(
                l10n.addTask,
                style: _bodyStyle(context).copyWith(
                  color: _teal,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: _teal,
                side: BorderSide(
                  color: _teal.withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodoItem({
    required String title,
    required String subtitle,
    required String tag,
    required bool isCompleted,
  }) {
    return Opacity(
      opacity: isCompleted ? 0.5 : 1,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            height: 44,
            child: Checkbox(
              value: isCompleted,
              onChanged: (value) {
                // TODO: Update todo status
              },
              activeColor: _teal,
              checkColor: Colors.white,
              side: BorderSide(
                color: _teal.withValues(alpha: 0.35),
                width: 1.5,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _bodyStyle(context).copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _teal,
                      decoration:
                          isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  Text(
                    'Due $subtitle',
                    style: _bodyStyle(context).copyWith(
                      fontSize: 12,
                      color: _teal.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _cream,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _teal.withValues(alpha: 0.12)),
            ),
            child: Text(
              tag,
              style: _bodyStyle(context).copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _tealMid,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime? _parseScheduledTimeLocal(String? scheduledTime) {
    if (scheduledTime == null || scheduledTime.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(scheduledTime)?.toLocal();
  }

  bool _isScheduledToday(DateTime scheduled) {
    final now = DateTime.now();
    return scheduled.year == now.year &&
        scheduled.month == now.month &&
        scheduled.day == now.day;
  }

  bool _isTodayOrFuture(DateTime scheduled) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final scheduledDay =
        DateTime(scheduled.year, scheduled.month, scheduled.day);
    return !scheduledDay.isBefore(startOfToday);
  }
}
