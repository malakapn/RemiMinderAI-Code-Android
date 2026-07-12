import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

/// Locale-aware formatting for numbers, dates, times, and common display names.
class LocaleFormat {
  LocaleFormat._();

  static String locale(BuildContext context) =>
      Localizations.localeOf(context).toString();

  static String number(BuildContext context, num value) {
    return NumberFormat.decimalPattern(locale(context)).format(value);
  }

  static String percent(BuildContext context, num value) {
    return localizeDigitsInText(
      context,
      '${number(context, value.round())}%',
    );
  }

  static String dateShort(BuildContext context, DateTime date) {
    return DateFormat.yMd(locale(context)).format(date.toLocal());
  }

  static String dateMedium(BuildContext context, DateTime date) {
    return DateFormat.yMMMd(locale(context)).format(date.toLocal());
  }

  static String dateMd(BuildContext context, DateTime date) {
    return DateFormat.Md(locale(context)).format(date.toLocal());
  }

  static String time(BuildContext context, DateTime date) {
    final loc = locale(context);
    final local = date.toLocal();
    if (loc.startsWith('en')) {
      return DateFormat.jm(loc).format(local);
    }
    final formatted = DateFormat('HH:mm', loc).format(local);
    return localizeDigitsInText(context, formatted);
  }

  static String timeOfDay(BuildContext context, TimeOfDay value) {
    final now = DateTime.now();
    return LocaleFormat.time(
      context,
      DateTime(now.year, now.month, now.day, value.hour, value.minute),
    );
  }

  static String dateTimeMedium(BuildContext context, DateTime date) {
    return '${dateMedium(context, date)} ${time(context, date)}';
  }

  static String durationMinutesSeconds(
    BuildContext context,
    Duration duration,
  ) {
    final loc = locale(context);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${NumberFormat('00', loc).format(minutes)}:'
        '${NumberFormat('00', loc).format(seconds)}';
  }

  /// Rewrites Western digits in [text] to the active locale's numeral system.
  static String localizeDigitsInText(BuildContext context, String text) {
    final formatter = NumberFormat.decimalPattern(locale(context));
    return text.replaceAllMapped(RegExp(r'\d+'), (match) {
      final value = int.parse(match.group(0)!);
      return formatter.format(value);
    });
  }

  /// Maps generic English role placeholders to localized labels.
  static String displayName(
    BuildContext context,
    String name, {
    required String fallback,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return fallback;

    final normalized = trimmed.toLowerCase();
    if (normalized == 'patient' || normalized == 'default patient') {
      return fallback;
    }
    if (normalized == 'caregiver' || normalized == 'default caregiver') {
      return fallback;
    }

    return trimmed;
  }

  /// Relative time label for invitation/card timestamps.
  static String timeAgo(
    BuildContext context,
    DateTime? timestamp,
    AppLocalizations l10n,
  ) {
    if (timestamp == null) return '';

    final diff = DateTime.now().difference(timestamp);
    final minutes = diff.inMinutes;
    if (minutes < 60) {
      final m = minutes < 1 ? 1 : minutes;
      return localizeDigitsInText(context, l10n.syncMinutesAgo(m));
    }
    final hours = diff.inHours;
    if (hours < 24) {
      return localizeDigitsInText(context, l10n.syncHoursAgo(hours));
    }
    return localizeDigitsInText(context, l10n.syncDaysAgo(diff.inDays));
  }

  /// Past relative time, falling back to a short date for older entries.
  static String relativePastOrDate(
    BuildContext context,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes < 1 ? 1 : diff.inMinutes.clamp(1, 59);
      return localizeDigitsInText(context, l10n.timeMinutesAgo(m));
    }
    if (diff.inHours < 24) {
      return localizeDigitsInText(context, l10n.timeHoursAgo(diff.inHours));
    }
    if (diff.inDays < 30) {
      return localizeDigitsInText(context, l10n.timeDaysAgo(diff.inDays));
    }
    return dateShort(context, date);
  }

  /// Smart date/time: minutes ago → today/yesterday with time → full date.
  static String smartDateTime(
    BuildContext context,
    DateTime dateTime,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes < 1 ? 1 : difference.inMinutes;
      return localizeDigitsInText(context, l10n.timeMinutesAgo(minutes));
    }

    final isSameDay = now.year == dateTime.year &&
        now.month == dateTime.month &&
        now.day == dateTime.day;
    if (isSameDay) {
      return l10n.timeToday(time(context, dateTime));
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (yesterday.year == dateTime.year &&
        yesterday.month == dateTime.month &&
        yesterday.day == dateTime.day) {
      return l10n.timeYesterday(time(context, dateTime));
    }

    return dateMedium(context, dateTime);
  }

  static DateTime? parseScheduledTime(Map<String, dynamic> reminder) {
    final raw = reminder['scheduled_time'] ?? reminder['scheduledTime'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  static DateTime? tryParseDate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    return DateTime.tryParse(raw)?.toLocal();
  }

  /// Localized reminder status from backend [display_status] values.
  static String reminderStatusLabel(AppLocalizations l10n, String status) {
    switch (status.toLowerCase().trim()) {
      case 'due now':
        return l10n.statusDueNow;
      case 'upcoming':
        return l10n.statusUpcoming;
      case 'missed':
      case 'overdue':
        return l10n.statusMissed;
      case 'completed':
        return l10n.statusDone;
      case 'snoozed':
        return l10n.statusSnoozed;
      case 'skipped':
        return l10n.statusSkipped;
      case 'pending':
        return l10n.statusPending;
      case 'active':
        return l10n.statusActive;
      case 'scheduled':
        return l10n.statusScheduled;
      default:
        return status;
    }
  }

  /// Localized relative time for reminders (past and future).
  static String reminderRelativeTime(
    BuildContext context,
    DateTime? scheduledTime,
    AppLocalizations l10n,
  ) {
    if (scheduledTime == null) return '';

    final now = DateTime.now();
    final scheduled = scheduledTime.toLocal();
    final delta = scheduled.difference(now);

    // Due right now (not overdue — past times have negative delta).
    if (delta.inSeconds >= 0 && delta.inMinutes < 1) {
      return l10n.timeNow;
    }

    if (delta.isNegative) {
      final past = now.difference(scheduled);
      final days = past.inDays;
      if (days > 0) {
        return localizeDigitsInText(context, l10n.timeDaysAgo(days));
      }
      final hours = past.inHours;
      if (hours > 0) {
        return localizeDigitsInText(context, l10n.timeHoursAgo(hours));
      }
      final minutes = past.inMinutes < 1 ? 1 : past.inMinutes;
      return localizeDigitsInText(context, l10n.timeMinutesAgo(minutes));
    }

    final days = delta.inDays;
    if (days > 0) {
      return localizeDigitsInText(context, l10n.timeInDays(days));
    }
    final hours = delta.inHours;
    if (hours > 0) {
      return localizeDigitsInText(context, l10n.timeInHoursShort(hours));
    }
    final minutes = delta.inMinutes < 1 ? 1 : delta.inMinutes;
    return localizeDigitsInText(context, l10n.timeInMinutesShort(minutes));
  }

  /// Due label for tasks/reminders (future relative or short date).
  static String dueLabel(
    BuildContext context,
    DateTime? scheduled,
    AppLocalizations l10n,
  ) {
    if (scheduled == null) {
      return l10n.timeNow;
    }
    final now = DateTime.now();
    final diff = scheduled.difference(now);
    if (diff.inDays >= 7) {
      return dateMd(context, scheduled);
    }
    return reminderRelativeTime(context, scheduled, l10n);
  }

  /// Schedule row time; optionally prefixes with month/day.
  static String scheduleTime(
    BuildContext context,
    DateTime? scheduled, {
    bool includeDate = false,
  }) {
    if (scheduled == null) return '';
    final formattedTime = time(context, scheduled);
    if (!includeDate) return formattedTime;
    return '${dateMd(context, scheduled)} · $formattedTime';
  }

  static bool _isEnglishReminderPlaceholder(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty || normalized == 'reminder';
  }

  /// Localized reminder title; replaces API English placeholder "Reminder".
  static String reminderTitle(AppLocalizations l10n, String? title) {
    final raw = title?.trim() ?? '';
    if (_isEnglishReminderPlaceholder(raw)) {
      return l10n.defaultReminderTitle;
    }
    return raw;
  }

  /// Localized reminder description; strips English API "Reminder:" prefix.
  static String reminderCardDescription(
    AppLocalizations l10n, {
    String? title,
    String? description,
  }) {
    final displayTitle = reminderTitle(l10n, title);
    final raw = description?.trim() ?? '';

    if (raw.isEmpty) {
      return l10n.reminderDescription(displayTitle);
    }

    final englishPrefix = RegExp(r'^reminder:\s*', caseSensitive: false);
    if (englishPrefix.hasMatch(raw)) {
      final body = raw.replaceFirst(englishPrefix, '').trim();
      return l10n.reminderDescription(
        _isEnglishReminderPlaceholder(body) ? displayTitle : body,
      );
    }

    if (_isEnglishReminderPlaceholder(raw)) {
      return l10n.reminderDescription(displayTitle);
    }

    return raw;
  }

  /// Clock label for reminder cards: today shows time only, else date + time.
  static String reminderScheduleLabel(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final local = dateTime.toLocal();
    final isToday = now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;
    if (isToday) {
      return time(context, local);
    }
    return dateTimeMedium(context, local);
  }

  /// Visit / last-sync style date: today, yesterday, N days ago, or short date.
  static String visitRelativeDate(
    BuildContext context,
    DateTime date,
    AppLocalizations l10n,
  ) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return l10n.tabToday;
    }
    if (difference == 1) {
      return l10n.patientOverviewYesterday;
    }
    if (difference < 7) {
      return localizeDigitsInText(context, l10n.timeDaysAgo(difference));
    }
    return dateShort(context, date);
  }
}
