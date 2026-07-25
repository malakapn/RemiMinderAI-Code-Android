enum MonetizationPlan {
  trial,
  free,
  premium,
  expired;

  static MonetizationPlan fromString(String value) {
    switch (value.trim().toUpperCase()) {
      case 'TRIAL':
        return MonetizationPlan.trial;
      case 'PREMIUM':
        return MonetizationPlan.premium;
      case 'EXPIRED':
        return MonetizationPlan.expired;
      case 'FREE':
      default:
        return MonetizationPlan.free;
    }
  }

  String get apiValue {
    switch (this) {
      case MonetizationPlan.trial:
        return 'TRIAL';
      case MonetizationPlan.free:
        return 'FREE';
      case MonetizationPlan.premium:
        return 'PREMIUM';
      case MonetizationPlan.expired:
        return 'EXPIRED';
    }
  }
}

class MonetizationLimits {
  static const int trialSummaryLimit = 3;
  static const int freeSummaryLimit = 2;
  static const int trialVoxInteractionLimit = 2;
  static const int freeCaregiverLimit = 1;
  static const int trialCaregiverLimit = 1;
  static const int premiumCaregiverLimit = 5;
}

class MonetizationStatus {
  final MonetizationPlan plan;
  final bool trialActive;
  final DateTime? trialStartDate;
  final DateTime? trialEndDate;
  final int trialDaysRemaining;
  final int summaryCount;
  final int remivoxInteractionCount;
  final String? subscriptionSource;

  const MonetizationStatus({
    required this.plan,
    required this.trialActive,
    this.trialStartDate,
    this.trialEndDate,
    required this.trialDaysRemaining,
    required this.summaryCount,
    required this.remivoxInteractionCount,
    this.subscriptionSource,
  });

  factory MonetizationStatus.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    return MonetizationStatus(
      plan: MonetizationPlan.fromString(json['plan']?.toString() ?? 'FREE'),
      trialActive: json['trial_active'] == true,
      trialStartDate: parseDate(json['trial_start_date']),
      trialEndDate: parseDate(json['trial_end_date']),
      trialDaysRemaining: (json['trial_days_remaining'] as num?)?.toInt() ?? 0,
      summaryCount: (json['summary_count'] as num?)?.toInt() ?? 0,
      remivoxInteractionCount:
          (json['remivox_interaction_count'] as num?)?.toInt() ?? 0,
      subscriptionSource: json['subscription_source'] as String?,
    );
  }

  bool get isTrial => plan == MonetizationPlan.trial && trialActive;
  bool get isPremium => plan == MonetizationPlan.premium;
  bool get isFree => plan == MonetizationPlan.free;
  bool get isExpired => plan == MonetizationPlan.expired;

  bool get canUseVox =>
      isPremium ||
      (isTrial &&
          remivoxInteractionCount <
              MonetizationLimits.trialVoxInteractionLimit);

  bool get canGenerateSummary {
    if (isPremium) return true;
    if (isTrial) {
      return summaryCount < MonetizationLimits.trialSummaryLimit;
    }
    return summaryCount < MonetizationLimits.freeSummaryLimit;
  }

  int? get summaryLimit {
    if (isPremium) return null;
    return isTrial
        ? MonetizationLimits.trialSummaryLimit
        : MonetizationLimits.freeSummaryLimit;
  }
}
