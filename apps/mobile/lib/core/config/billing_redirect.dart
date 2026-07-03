import 'dart:io' show Platform;

/// iOS uses `com.remiminderai.app` in Info.plist; Android dev uses `com.remiminder.app.dev`.
String defaultBillingUrlScheme() {
  if (Platform.isIOS) return 'com.remiminderai.app';
  return 'com.remiminder.app.dev';
}
