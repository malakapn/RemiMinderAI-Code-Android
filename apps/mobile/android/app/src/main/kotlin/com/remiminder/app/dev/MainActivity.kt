package com.remiminder.app.dev

import android.app.NotificationManager
import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.remiminder.app.dev/google_auth",
        ).setMethodCallHandler { call, result ->
            if (call.method == "getWebClientId") {
                try {
                    val resId = resources.getIdentifier(
                        "default_web_client_id",
                        "string",
                        packageName,
                    )
                    if (resId != 0) {
                        result.success(resources.getString(resId))
                    } else {
                        result.success(null)
                    }
                } catch (e: Exception) {
                    result.error("err", e.message, null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
