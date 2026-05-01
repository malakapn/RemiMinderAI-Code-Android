import 'dart:io' show Platform;

/// iOS uses `com.remiminder.app` in Info.plist; Android dev uses `com.remiminder.app.dev`.
String defaultBillingUrlScheme() {
  if (Platform.isIOS) return 'com.remiminder.app';
  return 'com.remiminder.app.dev';
}
