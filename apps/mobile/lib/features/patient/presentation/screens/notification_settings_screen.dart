import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/services/notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  // Notification preferences
  bool _medicationReminders = true;
  bool _appointmentReminders = true;
  bool _healthTips = false;
  bool _caregiverUpdates = true;
  bool _emergencyAlerts = true;
  bool _dailySummary = false;

  // Timing preferences
  TimeOfDay _morningReminder = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _eveningReminder = const TimeOfDay(hour: 20, minute: 0);
  int _reminderAdvanceMinutes = 15;

  // Sound preferences
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  double _volumeLevel = 0.8;

  @override
  Widget build(BuildContext context) {
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
          'Notifications',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Notification Types Section
              _buildSectionHeader('Notification Types'),
              const SizedBox(height: 16),
              _buildNotificationToggle(
                'Medication Reminders',
                'Get notified when it\'s time to take your medications',
                _medicationReminders,
                (value) => setState(() => _medicationReminders = value),
                Icons.medication,
                Colors.blue,
              ),
              _buildNotificationToggle(
                'Appointment Reminders',
                'Reminders for upcoming doctor visits and tests',
                _appointmentReminders,
                (value) => setState(() => _appointmentReminders = value),
                Icons.calendar_today,
                Colors.purple,
              ),
              _buildNotificationToggle(
                'Health Tips',
                'Daily tips for managing your health conditions',
                _healthTips,
                (value) => setState(() => _healthTips = value),
                Icons.health_and_safety,
                Colors.green,
              ),
              _buildNotificationToggle(
                'Caregiver Updates',
                'Notifications when caregivers view your information',
                _caregiverUpdates,
                (value) => setState(() => _caregiverUpdates = value),
                Icons.people,
                Colors.orange,
              ),
              _buildNotificationToggle(
                'Emergency Alerts',
                'Critical health alerts and emergency notifications',
                _emergencyAlerts,
                (value) => setState(() => _emergencyAlerts = value),
                Icons.emergency,
                Colors.red,
                enabled: false, // Always enabled for safety
              ),
              _buildNotificationToggle(
                'Daily Summary',
                'Evening summary of your day\'s health activities',
                _dailySummary,
                (value) => setState(() => _dailySummary = value),
                Icons.summarize,
                Colors.teal,
              ),

              const SizedBox(height: 32),

              // Timing Preferences Section
              _buildSectionHeader('Timing Preferences'),
              const SizedBox(height: 16),
              _buildTimePreference(
                'Morning Reminder Time',
                _morningReminder,
                (time) => setState(() => _morningReminder = time),
              ),
              _buildTimePreference(
                'Evening Reminder Time',
                _eveningReminder,
                (time) => setState(() => _eveningReminder = time),
              ),
              _buildAdvanceTimePreference(),

              const SizedBox(height: 32),

              // Sound & Alert Preferences Section
              _buildSectionHeader('Sound & Alerts'),
              const SizedBox(height: 16),
              _buildSoundToggle(),
              _buildVibrationToggle(),
              _buildVolumeSlider(),

              const SizedBox(height: 32),

              // Test Notifications
              _buildSectionHeader('Test Notifications'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _sendTestNotification,
                  icon: const Icon(Icons.notifications_active),
                  label: const Text('Send Test Notification'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildNotificationToggle(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
    Color color, {
    bool enabled = true,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.secondary.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeThumbColor: color,
          ),
        ],
      ),
    );
  }

  Widget _buildTimePreference(String title, TimeOfDay time, Function(TimeOfDay) onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final TimeOfDay? newTime = await showTimePicker(
                context: context,
                initialTime: time,
              );
              if (newTime != null) {
                onChanged(newTime);
              }
            },
            child: Text(
              time.format(context),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvanceTimePreference() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Reminder Advance Time',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          DropdownButton<int>(
            value: _reminderAdvanceMinutes,
            onChanged: (value) {
              if (value != null) {
                setState(() => _reminderAdvanceMinutes = value);
              }
            },
            items: const [
              DropdownMenuItem(value: 5, child: Text('5 min')),
              DropdownMenuItem(value: 10, child: Text('10 min')),
              DropdownMenuItem(value: 15, child: Text('15 min')),
              DropdownMenuItem(value: 30, child: Text('30 min')),
              DropdownMenuItem(value: 60, child: Text('1 hour')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSoundToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.volume_up,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Sound Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Switch(
            value: _soundEnabled,
            onChanged: (value) => setState(() => _soundEnabled = value),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildVibrationToggle() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.vibration,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Vibration',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          Switch(
            value: _vibrationEnabled,
            onChanged: (value) => setState(() => _vibrationEnabled = value),
            activeThumbColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildVolumeSlider() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.volume_down,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 16),
              Text(
                'Volume Level',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                '${(_volumeLevel * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _volumeLevel,
            onChanged: _soundEnabled
                ? (value) => setState(() => _volumeLevel = value)
                : null,
            activeColor: Theme.of(context).colorScheme.primary,
            inactiveColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Future<void> _sendTestNotification() async {
    try {
      final granted = await NotificationService().requestNotificationPermission();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Enable notifications in system settings to receive alerts.'),
          ),
        );
        return;
      }
      await NotificationService().showInstantNotification(
        notificationId: 90001,
        title: '💊 Test Notification',
        body: 'Notifications are working correctly! ✅',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Test notification sent!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Test notification failed: $e')),
      );
    }
  }
}
