import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum UpgradePromptReason {
  summaryLimit,
  voxLocked,
  caregiverLimit,
  trialExpired,
}

extension UpgradePromptReasonCopy on UpgradePromptReason {
  String get eventName {
    switch (this) {
      case UpgradePromptReason.summaryLimit:
        return 'summary_limit';
      case UpgradePromptReason.voxLocked:
        return 'vox_locked';
      case UpgradePromptReason.caregiverLimit:
        return 'caregiver_limit';
      case UpgradePromptReason.trialExpired:
        return 'trial_expired';
    }
  }

  String get title {
    switch (this) {
      case UpgradePromptReason.summaryLimit:
        return 'Keep your visit summaries going';
      case UpgradePromptReason.voxLocked:
        return 'Your trial has ended';
      case UpgradePromptReason.caregiverLimit:
        return 'Invite more caregivers';
      case UpgradePromptReason.trialExpired:
        return 'Your trial has ended';
    }
  }

  String get message {
    switch (this) {
      case UpgradePromptReason.summaryLimit:
        return "You've used your free doctor visit summaries. Upgrade to RemiMinderAI Premium to continue organizing your healthcare.";
      case UpgradePromptReason.voxLocked:
        return 'Your 14-day trial has ended. Subscribe to RemiMinderAI Premium to keep using all features, including Vox.';
      case UpgradePromptReason.caregiverLimit:
        return 'Premium lets you invite more caregivers so your loved ones can stay connected to your care.';
      case UpgradePromptReason.trialExpired:
        return 'Your 14-day trial has ended. Subscribe to RemiMinderAI Premium to keep using all features — summaries, caregivers, and Vox.';
    }
  }
}

Future<void> showUpgradePromptSheet(
  BuildContext context, {
  required UpgradePromptReason reason,
  required String screen,
}) async {
  if (!context.mounted) return;
  final theme = Theme.of(context);
  await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: Color(0xFFC9A84C),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.workspace_premium,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              reason.title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              reason.message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF2D2D2D),
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(sheetContext).pop(false);
                context.go('/upgrade');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('View Premium options'),
            ),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(true),
              child: const Text('Maybe later'),
            ),
          ],
        ),
      );
    },
  );
}
