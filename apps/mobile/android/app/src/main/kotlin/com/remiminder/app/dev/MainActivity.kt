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
            "com.remiminder.app.dev/full_screen_intent",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "canUseFullScreenIntent" -> {
                    if (Build.VERSION.SDK_INT < 34) {
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    val nm = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
                    result.success(nm.canUseFullScreenIntent())
                }
                else -> result.notImplemented()
            }
        }
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.remiminder.app.dev/google_auth",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getWebClientId" -> result.notImplemented()
                else -> result.notImplemented()
            }
        }
    }
}
