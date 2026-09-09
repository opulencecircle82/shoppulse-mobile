package com.shoppulse.shoppulse_mobile

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.os.Build
import android.os.IBinder
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import com.google.android.gms.location.FusedLocationProviderClient
import com.google.android.gms.location.LocationCallback
import com.google.android.gms.location.LocationRequest
import com.google.android.gms.location.LocationResult
import com.google.android.gms.location.LocationServices
import com.google.android.gms.location.Priority
import java.net.HttpURLConnection
import java.net.URL
import org.json.JSONObject

/**
 * Runs as a foreground service (persistent notification, per Android
 * requirements for background location) so a technician's position keeps
 * reporting to Live Field Map even with the app backgrounded or the
 * screen locked - unlike the WebView's own GPS capture, which browsers
 * pause once the tab isn't visible.
 *
 * Started/stopped from Flutter (see MainActivity's MethodChannel), which
 * itself is driven by JS messages the /tech web page sends after sign-in
 * / sign-out.
 */
class LocationTrackingService : Service() {

    companion object {
        const val ACTION_START = "com.shoppulse.shoppulse_mobile.action.START_TRACKING"
        const val ACTION_STOP = "com.shoppulse.shoppulse_mobile.action.STOP_TRACKING"
        const val EXTRA_TOKEN = "token"
        const val EXTRA_API_URL = "apiUrl"
        private const val NOTIFICATION_CHANNEL_ID = "location_tracking"
        private const val NOTIFICATION_ID = 4201
        private const val UPDATE_INTERVAL_MS = 30000L
    }

    private lateinit var fusedLocationClient: FusedLocationProviderClient
    private var apiUrl: String = ""
    private var token: String = ""

    private val locationCallback = object : LocationCallback() {
        override fun onLocationResult(result: LocationResult) {
            result.lastLocation?.let { postLocation(it) }
        }
    }

    override fun onCreate() {
        super.onCreate()
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                stopTracking()
                return START_NOT_STICKY
            }
            ACTION_START -> {
                token = intent.getStringExtra(EXTRA_TOKEN) ?: ""
                apiUrl = intent.getStringExtra(EXTRA_API_URL) ?: ""
                if (token.isEmpty() || apiUrl.isEmpty()) {
                    stopSelf()
                    return START_NOT_STICKY
                }
                startForeground(NOTIFICATION_ID, buildNotification())
                startLocationUpdates()
            }
        }
        return START_STICKY
    }

    private fun startLocationUpdates() {
        val hasPermission = ActivityCompat.checkSelfPermission(
            this,
            android.Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

        if (!hasPermission) {
            stopSelf()
            return
        }

        val request = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, UPDATE_INTERVAL_MS)
            .setMinUpdateIntervalMillis(UPDATE_INTERVAL_MS)
            .build()

        fusedLocationClient.requestLocationUpdates(
            request,
            locationCallback,
            mainLooper
        )
    }

    private fun stopTracking() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    private fun postLocation(location: Location) {
        Thread {
            try {
                val body = JSONObject().apply {
                    put("token", token)
                    put("lat", location.latitude)
                    put("lng", location.longitude)
                    put("accuracy", location.accuracy)
                }

                val connection = URL(apiUrl).openConnection() as HttpURLConnection
                connection.requestMethod = "POST"
                connection.setRequestProperty("Content-Type", "application/json")
                connection.doOutput = true
                connection.connectTimeout = 10000
                connection.readTimeout = 10000
                connection.outputStream.use { it.write(body.toString().toByteArray()) }
                connection.responseCode // triggers the request
                connection.disconnect()
            } catch (_: Exception) {
                // Best-effort: a dropped ping just means the next one (30s
                // later) catches up. Not worth surfacing to the technician.
            }
        }.start()
    }

    private fun buildNotification(): Notification {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Location sharing",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Shows while ShopPulse is sharing your location with your shop"
            }
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }

        val openAppIntent = packageManager.getLaunchIntentForPackage(packageName)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            openAppIntent,
            PendingIntent.FLAG_IMMUTABLE
        )

        return NotificationCompat.Builder(this, NOTIFICATION_CHANNEL_ID)
            .setContentTitle("ShopPulse is sharing your location")
            .setContentText("Your shop can see you on the field map while you're on shift.")
            .setSmallIcon(android.R.drawable.ic_menu_mylocation)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .build()
    }

    override fun onDestroy() {
        fusedLocationClient.removeLocationUpdates(locationCallback)
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
}
