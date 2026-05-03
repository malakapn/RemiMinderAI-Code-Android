import 'dart:io' show Platform;

/// iOS and Android use `com.remiminder.app` (redirect / billing URL scheme).
String defaultBillingUrlScheme() {
  if (Platform.isIOS) return 'com.remiminder.app';
  return 'com.remiminder.app';
}
