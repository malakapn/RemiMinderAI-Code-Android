import 'dart:io' show Platform;

/// iOS uses `com.remiminderai.app` in Info.plist; Android production uses `com.remiminder.app`.
String defaultBillingUrlScheme() {
  if (Platform.isIOS) return 'com.remiminderai.app';
  return 'com.remiminder.app';
}
