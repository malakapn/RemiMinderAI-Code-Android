// Reminder Repository - Adapted from Phase 1 PatientReminders.js API calls
// Original: Direct API calls in PatientReminders.js (lines 51-150)
//
// Changes from Phase 1:
// - Direct fetch() calls → Repository pattern using shared API service
// - Inline error handling → Centralized repository methods
// - Supabase auth → Firebase auth headers
// - Manual response parsing → Structured data models

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mediminder_shared/models/reminder.dart';
import 'package:mediminder_shared/services/api_service.dart';
import 'package:mediminder_shared/constants/api_endpoints.dart';

class ReminderRepository {
  final ApiService _apiService;

  ReminderRepository(this._apiService);

  // In-memory cache (per app process)
  static CacheEntry<ReminderListResponse>? _remindersCache;

  static ReminderListResponse? getCachedReminders() {
    return _remindersCache?.data;
  }

  static void setCachedReminders(ReminderListResponse data) {
    _remindersCache = CacheEntry(data, DateTime.now());
  }

  // Adapted from Phase 1 getReminders() function (lines 51-100)
  Future<ReminderListResponse> getReminders(Map<String, String> headers) async {
    try {
      final response = await _apiService.get(
        ApiEndpoints.patientReminders,
        headers: headers,
      );

      return ReminderListResponse.fromJson(response);
    } catch (e) {
      throw Exception('Failed to load reminders: $e');
    }
  }

  // Adapted from Phase 1 createReminder logic
  Future<Reminder> createReminder(
    CreateReminderRequest request,
    Map<String, String> headers,
  ) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.createReminder,
        headers: headers,
        body: request.toJson(),
      );

      return Reminder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create reminder: $e');
    }
  }

  // Adapted from Phase 1 completeReminder function
  Future<void> completeReminder(String reminderId, Map<String, String> headers) async {
    try {
      await _apiService.put(
        ApiEndpoints.buildUrl(ApiEndpoints.completeReminder, {'id': reminderId}),
        headers: headers,
      );
    } catch (e) {
      throw Exception('Failed to complete reminder: $e');
    }
  }

  // Adapted from Phase 1 snoozeReminder function
  Future<void> snoozeReminder(String reminderId, Map<String, String> headers) async {
    try {
      // Default 30-minute snooze (adapted from Phase 1 default)
      const snoozeRequest = SnoozeReminderRequest(snoozeMinutes: 30);

      await _apiService.put(
        ApiEndpoints.buildUrl(ApiEndpoints.snoozeReminder, {'id': reminderId}),
        headers: headers,
        body: snoozeRequest.toJson(),
      );
    } catch (e) {
      throw Exception('Failed to snooze reminder: $e');
    }
  }

  // Adapted from Phase 1 deleteReminder function
  Future<void> deleteReminder(String reminderId, Map<String, String> headers) async {
    try {
      await _apiService.delete(
        ApiEndpoints.buildUrl(ApiEndpoints.deleteReminder, {'id': reminderId}),
        headers: headers,
      );
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }

  // Adapted from Phase 1 updateReminder function
  Future<Reminder> updateReminder(
    String reminderId,
    UpdateReminderRequest request,
    Map<String, String> headers,
  ) async {
    try {
      final response = await _apiService.put(
        ApiEndpoints.buildUrl(ApiEndpoints.updateReminder, {'id': reminderId}),
        headers: headers,
        body: request.toJson(),
      );

      return Reminder.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }
}

class CacheEntry<T> {
  final T data;
  final DateTime fetchedAt;

  const CacheEntry(this.data, this.fetchedAt);
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReminderRepository(apiService);
});

// Supporting providers
final apiServiceProvider = Provider<ApiService>((ref) {
  // In a real app, this would be configured based on environment
  return ApiService(baseUrl: ApiEndpoints.devUrl);
});