import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';
import '../../../../core/utils/locale_format.dart';
import '../../../../l10n/app_localizations.dart';

/// Medication / reminder detail opened from push notification deep link.
class ReminderDetailScreen extends StatefulWidget {
  const ReminderDetailScreen({super.key, required this.reminderId});

  final String reminderId;

  @override
  State<ReminderDetailScreen> createState() => _ReminderDetailScreenState();
}

class _ReminderDetailScreenState extends State<ReminderDetailScreen> {
  final AuthService _auth = AuthService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _reminder;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final token = await _auth.getAccessToken();
      if (token == null) throw Exception('sign_in_required');
      final res = await http.get(
        Uri.parse(
            '${Environment.apiBaseUrl}/api/reminders/${widget.reminderId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode != 200) {
        throw Exception('load_failed_${res.statusCode}');
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        _reminder = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _postAction(String action) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final token = await _auth.getAccessToken();
      if (token == null) return;
      final uri = action == 'snooze'
          ? Uri.parse(
              '${Environment.apiBaseUrl}/api/reminders/${widget.reminderId}/snooze?snooze_minutes=30')
          : Uri.parse(
              '${Environment.apiBaseUrl}/api/reminders/${widget.reminderId}/$action');
      final res = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({}),
      );
      if (res.statusCode != 200) {
        throw Exception('action_failed');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            action == 'complete'
                ? l10n.reminderMarkedCompleted
                : l10n.reminderSnoozed30,
          ),
        ),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotUpdateReminder)),
      );
    }
  }

  String _scheduledLabel(BuildContext context, Map<String, dynamic> reminder) {
    final scheduledRaw = reminder['scheduled_time']?.toString();
    final parsed = DateTime.tryParse(scheduledRaw ?? '')?.toLocal();
    if (parsed != null) {
      return LocaleFormat.dateTimeMedium(context, parsed);
    }
    final displayTime = reminder['display_time']?.toString().trim() ?? '';
    if (displayTime.isNotEmpty) {
      return LocaleFormat.localizeDigitsInText(context, displayTime);
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.defaultReminderTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/patient/reminders'),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _error!.contains('sign_in_required')
                              ? l10n.signInRequired
                              : l10n.failedToLoadRemindersRetry,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _load,
                          child: Text(l10n.retry),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildBody(context, l10n),
    );
  }

  Widget _buildBody(BuildContext context, AppLocalizations l10n) {
    final r = _reminder!;
    final title = LocaleFormat.reminderTitle(l10n, r['title']?.toString());
    final message = LocaleFormat.reminderCardDescription(
      l10n,
      title: r['title']?.toString(),
      description: r['message']?.toString(),
    );
    final type = LocaleFormat.reminderTypeLabel(
      l10n,
      r['reminder_type']?.toString(),
    );
    final status = LocaleFormat.reminderStatusLabel(
      l10n,
      (r['display_status'] ?? r['status'])?.toString() ?? '',
    );
    final scheduledLabel = _scheduledLabel(context, r);

    final rawStatus = (r['status']?.toString() ?? '').toLowerCase();
    final canAct = rawStatus == 'pending' || rawStatus == 'snoozed';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
          if (type.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              type,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
          const SizedBox(height: 16),
          if (message.isNotEmpty)
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          const SizedBox(height: 24),
          if (scheduledLabel.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: Text(l10n.statusScheduled),
              subtitle: Text(scheduledLabel),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag),
            title: Text(l10n.statusLabel),
            subtitle: Text(status),
          ),
          const SizedBox(height: 32),
          if (canAct) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _postAction('complete'),
                child: Text(l10n.markDone),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _postAction('snooze'),
                child: Text(l10n.snooze30Minutes),
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/patient/reminders'),
            child: Text(l10n.backToAllReminders),
          ),
        ],
      ),
    );
  }
}
