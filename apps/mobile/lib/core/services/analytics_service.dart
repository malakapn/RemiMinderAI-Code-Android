import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  AnalyticsService._();

  static final AnalyticsService instance = AnalyticsService._();
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }

  Future<void> trialStarted() => logEvent('trial_started');

  Future<void> trialExpired() => logEvent('trial_expired');

  Future<void> trialConverted() => logEvent('trial_converted');

  Future<void> subscriptionStarted({String? productId}) => logEvent(
        'subscription_started',
        parameters: {
          if (productId != null) 'product_id': productId,
        },
      );

  Future<void> subscriptionPlanSelected(String plan) => logEvent(
        'subscription_plan_selected',
        parameters: {'plan': plan},
      );

  Future<void> upgradePromptShown(String prompt, String screen) => logEvent(
        'upgrade_prompt_shown',
        parameters: {'prompt': prompt, 'screen': screen},
      );

  Future<void> upgradePromptDismissed(String prompt, String screen) => logEvent(
        'upgrade_prompt_dismissed',
        parameters: {'prompt': prompt, 'screen': screen},
      );

  Future<void> featureGated(String feature, String plan) => logEvent(
        'feature_gated',
        parameters: {'feature': feature, 'plan': plan},
      );

  Future<void> summaryGenerated(int count) => logEvent(
        'summary_generated',
        parameters: {'count': count},
      );

  Future<void> voxInteraction(int count) => logEvent(
        'vox_interaction',
        parameters: {'count': count},
      );
}
