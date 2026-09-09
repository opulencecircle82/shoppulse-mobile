package com.shoppulse.shoppulse_mobile

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "shoppulse/location_service"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            when (call.method) {
                "startTracking" -> {
                    val token = call.argument<String>("token")
                    val apiUrl = call.argument<String>("apiUrl")
                    val intent = Intent(this, LocationTrackingService::class.java).apply {
                        action = LocationTrackingService.ACTION_START
                        putExtra(LocationTrackingService.EXTRA_TOKEN, token)
                        putExtra(LocationTrackingService.EXTRA_API_URL, apiUrl)
                    }
                    startForegroundService(intent)
                    result.success(null)
                }
                "stopTracking" -> {
                    val intent = Intent(this, LocationTrackingService::class.java).apply {
                        action = LocationTrackingService.ACTION_STOP
                    }
                    startService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
