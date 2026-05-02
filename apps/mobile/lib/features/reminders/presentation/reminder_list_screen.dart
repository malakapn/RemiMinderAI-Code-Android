// Flutter adaptation of PatientReminders.js from Phase 1
// Original: apps/web/frontend/src/patient/PatientReminders.js
//
// Changes from Phase 1:
// - React hooks → Riverpod state management
// - JSX → Flutter widgets
// - Browser APIs → Flutter platform APIs
// - Supabase auth → Firebase auth
// - Direct API calls → Repository pattern with shared API service

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediminder_shared/models/reminder.dart';
import 'package:mediminder_shared/constants/api_endpoints.dart';
import '../data/reminder_repository.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/reminder_provider.dart';
import '../../../shared/widgets/reminder_card.dart';
import '../../../shared/widgets/loading_shimmer.dart';

class ReminderListScreen extends ConsumerStatefulWidget {
  const ReminderListScreen({super.key});

  @override
  ConsumerState<ReminderListScreen> createState() => _ReminderListScreenState();
}

class _ReminderListScreenState extends ConsumerState<ReminderListScreen> {
  // State management (adapted from Phase 1 useState)
  bool _isLoading = true;
  String? _error;
  ReminderListResponse? _reminderData;

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  // Adapted from Phase 1 getAuthHeaders function
  Future<Map<String, String>> _getAuthHeaders() async {
    final authState = ref.read(authProvider);
    final token = authState.user?.idToken;
    return token != null ? {'Authorization': 'Bearer $token'} : {};
  }

  // Adapted from Phase 1 loadReminders function (lines 51-150)
  Future<void> _loadReminders() async {
    try {
      final cached = ReminderRepository.getCachedReminders();
      if (cached != null && mounted) {
        setState(() {
          _reminderData = cached;
          _isLoading = false;
          _error = null;
        });
      } else {
        setState(() {
          _isLoading = true;
          _error = null;
        });
      }

      final headers = await _getAuthHeaders();
      final response =
          await ref.read(reminderRepositoryProvider).getReminders(headers);

      ReminderRepository.setCachedReminders(response);
      if (_remindersChanged(response)) {
        setState(() {
          _reminderData = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  bool _remindersChanged(ReminderListResponse next) {
    final current = _reminderData;
    if (current == null) {
      return true;
    }
    if (current.overview.total != next.overview.total) {
      return true;
    }
    if (current.today.length != next.today.length ||
        current.upcoming.length != next.upcoming.length ||
        current.past.length != next.past.length) {
      return true;
    }
    if (current.today.isNotEmpty && next.today.isNotEmpty) {
      return current.today.first.id != next.today.first.id;
    }
    return false;
  }

  // Adapted from Phase 1 handleCreateReminder
  void _handleCreateReminder() {
    Navigator.of(context).pushNamed('/create-reminder');
  }

  // Adapted from Phase 1 handleCompleteReminder
  Future<void> _handleCompleteReminder(String reminderId) async {
    try {
      final headers = await _getAuthHeaders();
      await ref
          .read(reminderRepositoryProvider)
          .completeReminder(reminderId, headers);
      await _loadReminders(); // Refresh list
      // Cancel local notification for completed reminder
      try {
        NotificationService().cancelFromReminderId(reminderId);
      } catch (e) {
        debugPrint('Failed to cancel notification for completed reminder: $e');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete reminder: $e')),
      );
    }
  }

  // Adapted from Phase 1 handleSnoozeReminder
  Future<void> _handleSnoozeReminder(String reminderId) async {
    try {
      // Cancel existing local notification first
      try {
        NotificationService().cancelFromReminderId(reminderId);
      } catch (e) {
        debugPrint('Failed to cancel notification for snoozed reminder: $e');
      }
      
      final headers = await _getAuthHeaders();
      await ref.read(reminderRepositoryProvider).snoozeReminder(reminderId, headers);
      await _loadReminders(); // Refresh list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to snooze reminder: $e')),
      );
    }
  }
  }

  @override
  Widget build(BuildContext context) {
    // Adapted from Phase 1 render function (lines 400-600)
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Reminders'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _handleCreateReminder,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const LoadingShimmer();
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: $_error'),
            ElevatedButton(
              onPressed: _loadReminders,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_reminderData == null) {
      return const Center(child: Text('No reminders found'));
    }

    return RefreshIndicator(
      onRefresh: _loadReminders,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overview section (adapted from Phase 1 overview display)
          _buildOverviewSection(),

          const SizedBox(height: 24),

          // Today's reminders (adapted from Phase 1 "now" section)
          if (_reminderData!.today.isNotEmpty) ...[
            _buildSectionHeader('Today', _reminderData!.today.length),
            ..._reminderData!.today.map(
              (reminder) => ReminderCard(
                reminder: reminder,
                onComplete: () => _handleCompleteReminder(reminder.id),
                onSnooze: () => _handleSnoozeReminder(reminder.id),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Upcoming reminders (adapted from Phase 1 "upcoming" section)
          if (_reminderData!.upcoming.isNotEmpty) ...[
            _buildSectionHeader('Upcoming', _reminderData!.upcoming.length),
            ..._reminderData!.upcoming.map(
              (reminder) => ReminderCard(reminder: reminder),
            ),
            const SizedBox(height: 24),
          ],

          // Past reminders (adapted from Phase 1 "past" section)
          if (_reminderData!.past.isNotEmpty) ...[
            _buildSectionHeader('Past', _reminderData!.past.length),
            ..._reminderData!.past.map(
              (reminder) =>
                  ReminderCard(reminder: reminder, showActions: false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    // Adapted from Phase 1 overview display (lines 200-250)
    final overview = _reminderData!.overview;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildOverviewItem('Total', overview.total.toString()),
            _buildOverviewItem('Today', overview.activeToday.toString(),
                color: Colors.blue),
            _buildOverviewItem('Upcoming', overview.upcoming.toString(),
                color: Colors.orange),
            _buildOverviewItem('Past', overview.past.toString(),
                color: Colors.green),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color ?? Colors.grey[700],
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        '$title ($count)',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
