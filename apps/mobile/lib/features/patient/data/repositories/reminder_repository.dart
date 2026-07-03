import '../models/models.dart';

abstract class ReminderRepository {
  Future<List<Reminder>> getReminders();
  Future<Reminder?> getReminder(String id);
  Future<Reminder> createReminder(Reminder reminder);
  Future<Reminder> updateReminder(Reminder reminder);
  Future<void> deleteReminder(String id);
  Future<List<Reminder>> getTodaysReminders();
  Future<List<Reminder>> getPendingReminders();
  Future<List<Reminder>> getCompletedReminders();
  Future<List<Reminder>> getRemindersForDate(DateTime date);
  Future<void> markReminderCompleted(String id);
  Future<void> snoozeReminder(String id, Duration snoozeDuration);
  Stream<List<Reminder>> watchReminders();
  Stream<List<Reminder>> watchTodaysReminders();
  Stream<List<Reminder>> watchPendingReminders();
}
