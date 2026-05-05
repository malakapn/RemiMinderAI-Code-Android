import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/environment.dart';
import '../../../../core/services/auth_service.dart';

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
      if (token == null) throw Exception('Sign in required');
      final res = await http.get(
        Uri.parse(
            '${Environment.apiBaseUrl}/api/reminders/${widget.reminderId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode != 200) {
        throw Exception('Could not load reminder (${res.statusCode})');
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
    try {
      final token = await _auth.getAccessToken();
      if (token == null) return;
      final res = await http.post(
        Uri.parse(
            '${Environment.apiBaseUrl}/api/reminders/${widget.reminderId}/$action'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode != 200) {
        throw Exception('Action failed');
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action == 'complete' ? 'Marked done' : 'Snoozed')),
      );
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update reminder')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminder'),
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
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            )),
                        const SizedBox(height: 16),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  ),
                )
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final r = _reminder!;
    final title = r['title']?.toString() ?? 'Reminder';
    final message = r['message']?.toString() ?? '';
    final type = r['reminder_type']?.toString() ?? '';
    final status = r['status']?.toString() ?? '';
    final scheduled = r['scheduled_time']?.toString() ?? '';
    final displayTime = r['display_time']?.toString();

    final canAct = status == 'pending' || status == 'snoozed';

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
              type.replaceAll('_', ' '),
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
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.schedule),
            title: const Text('Scheduled'),
            subtitle: Text(
              displayTime != null && displayTime.isNotEmpty
                  ? '$displayTime\n$scheduled'
                  : scheduled,
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.flag),
            title: const Text('Status'),
            subtitle: Text(status),
          ),
          const SizedBox(height: 32),
          if (canAct) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => _postAction('complete'),
                child: const Text('Mark done'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _postAction('snooze'),
                child: const Text('Snooze 30 minutes'),
              ),
            ),
          ],
          const SizedBox(height: 24),
          TextButton(
            onPressed: () => context.go('/patient/reminders'),
            child: const Text('Back to all reminders'),
          ),
        ],
      ),
    );
  }
}
