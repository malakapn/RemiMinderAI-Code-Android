import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/reminder_provider.dart';

/// Legacy list route — prefer [RemindersScreen] under the patient shell.
class ReminderListScreen extends ConsumerWidget {
  const ReminderListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(remindersStreamProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Reminders')),
      body: async.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final r = list[i];
            return ListTile(
              title: Text(r.title),
              subtitle: Text(r.description),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }
}
