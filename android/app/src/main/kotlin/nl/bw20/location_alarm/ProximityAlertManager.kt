package nl.bw20.location_alarm

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.location.LocationManager
import android.util.Log
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlin.math.max

object ProximityAlertManager {
    private const val TAG = "ProximityAlert"
    private const val CHANNEL = "nl.bw20.location_alarm/proximity_alert"
    private const val PREFS_NAME = "proximity_alert_ids"
    private const val KEY_IDS = "registered_ids"
    // Offset to avoid PendingIntent collision with notification intents.
    private const val REQUEST_CODE_OFFSET = 20000
    // Buffer added to alarm radius so the wake-up fires before the user
    // reaches the actual trigger zone, giving GPS time to get a precise fix.
    private const val RADIUS_BUFFER_METERS = 200f
    private const val MIN_RADIUS_METERS = 300f

    fun registerChannel(context: Context, engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "register" -> {
                        val id = call.argument<Int>("id") ?: -1
                        val lat = call.argument<Double>("lat") ?: 0.0
                        val lng = call.argument<Double>("lng") ?: 0.0
                        val radius = call.argument<Double>("radius")?.toFloat() ?: 500f
                        register(context, id, lat, lng, radius)
                        result.success(null)
                    }
                    "unregister" -> {
                        val id = call.argument<Int>("id") ?: -1
                        unregister(context, id)
                        result.success(null)
                    }
                    "unregisterAll" -> {
                        unregisterAll(context)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    fun register(context: Context, alarmId: Int, lat: Double, lng: Double, radius: Float) {
        if (alarmId == -1) return

        // Unregister existing alert for this alarm first.
        unregister(context, alarmId)

        val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val intent = createPendingIntent(context, alarmId)
        val alertRadius = max(radius + RADIUS_BUFFER_METERS, MIN_RADIUS_METERS)

        try {
            @Suppress("MissingPermission") // Permissions are checked on the Dart side.
            lm.addProximityAlert(lat, lng, alertRadius, -1, intent)
            persistAdd(context, alarmId)
            Log.d(TAG, "Registered alarm $alarmId at ($lat, $lng) radius ${alertRadius}m")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to register alarm $alarmId: $e")
        }
    }

    fun unregister(context: Context, alarmId: Int) {
        val ids = loadIds(context)
        if (!ids.remove(alarmId)) return
        saveIds(context, ids)

        val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val intent = createPendingIntent(context, alarmId)
        try {
            lm.removeProximityAlert(intent)
            Log.d(TAG, "Unregistered alarm $alarmId")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to unregister alarm $alarmId: $e")
        }
    }

    fun unregisterAll(context: Context) {
        val ids = loadIds(context)
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        for (id in ids) {
            val intent = createPendingIntent(context, id)
            try {
                lm.removeProximityAlert(intent)
                Log.d(TAG, "Unregistered alarm $id")
            } catch (e: Exception) {
                Log.e(TAG, "Failed to unregister alarm $id: $e")
            }
        }
        saveIds(context, mutableSetOf())
    }

    private fun persistAdd(context: Context, alarmId: Int) {
        val ids = loadIds(context)
        ids.add(alarmId)
        saveIds(context, ids)
    }

    private fun loadIds(context: Context): MutableSet<Int> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        return prefs.getStringSet(KEY_IDS, emptySet())
            ?.mapNotNull { it.toIntOrNull() }
            ?.toMutableSet()
            ?: mutableSetOf()
    }

    private fun saveIds(context: Context, ids: MutableSet<Int>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        prefs.edit().putStringSet(KEY_IDS, ids.map { it.toString() }.toSet()).apply()
    }

    private fun createPendingIntent(context: Context, alarmId: Int): PendingIntent {
        val intent = Intent(context, ProximityAlertReceiver::class.java).apply {
            action = "nl.bw20.location_alarm.PROXIMITY_ALERT"
            putExtra("alarm_id", alarmId)
        }
        return PendingIntent.getBroadcast(
            context,
            alarmId + REQUEST_CODE_OFFSET,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
        )
    }
}
