import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/reminder.dart';
import '../../data/reminder_repository.dart';

/// Live reminders for the signed-in user (empty stream if signed out).
final remindersStreamProvider = StreamProvider<List<Reminder>>((ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    return Stream.value(const <Reminder>[]);
  }
  return ref.watch(reminderRepositoryProvider).getReminders(uid);
});
