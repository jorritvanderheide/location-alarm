package nl.bw20.there_yet

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.location.LocationManager
import android.util.Log
import com.pravera.flutter_foreground_task.service.ForegroundService

class ProximityAlertReceiver : BroadcastReceiver() {
    companion object {
        private const val TAG = "ProximityAlert"
    }

    override fun onReceive(context: Context, intent: Intent) {
        val entering = intent.getBooleanExtra(
            LocationManager.KEY_PROXIMITY_ENTERING, false
        )
        val alarmId = intent.getIntExtra("alarm_id", -1)
        if (alarmId == -1) return

        Log.d(TAG, "Proximity event for alarm $alarmId (entering: $entering)")

        if (!entering) return

        // Try to wake the Dart foreground service for a precision GPS check.
        // If the service is alive, this feeds into the AlarmChecker pipeline.
        try {
            ForegroundService.sendData(
                """{"type":"proximity_wake","id":$alarmId}"""
            )
        } catch (e: Exception) {
            // Foreground service is dead — trigger alarm directly from native.
            // This is the fallback path for when Android killed the process.
            Log.w(TAG, "FGS unavailable, triggering alarm natively: $e")
            AlarmNotificationPlugin.playAlarmSound(context)
            AlarmNotificationHelper.show(
                context, alarmId, "There Yet", "You are near your destination"
            )
        }
    }
}
