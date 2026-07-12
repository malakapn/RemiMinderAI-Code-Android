import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../config/environment.dart';

/// Resolves Firebase **Web** OAuth client ID for [GoogleSignIn.serverClientId].
///
/// On Android, prefers `default_web_client_id` injected by the Google Services
/// Gradle plugin from `google-services.json` so it always matches the Firebase
/// project—even when `.env` is missing or stale.
Future<String> resolveGoogleWebClientId() async {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    try {
      const channel =
          MethodChannel('com.remiminder.app/google_auth');
      final native = await channel.invokeMethod<String>('getWebClientId');
      final n = native?.trim();
      if (n != null && n.isNotEmpty) {
        return n;
      }
    } catch (e) {
      debugPrint('resolveGoogleWebClientId (Android native): $e');
    }
  }

  var id = Environment.googleWebClientId.trim();
  if (id.isEmpty) {
    id = Environment.defaultFirebaseWebClientId;
  }
  return id;
}
