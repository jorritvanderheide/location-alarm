package nl.bw20.there_yet

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.pravera.flutter_foreground_task.service.ForegroundService

class AlarmDismissReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val alarmId = intent.getIntExtra("alarm_id", -1)
        if (alarmId == -1) return

        AlarmNotificationHelper.cancel(context, alarmId)
        // Stop audio directly — covers the case where the FGS is dead
        // and the Dart-side stop call won't reach.
        AlarmNotificationPlugin.stopAlarmSound()

        // Send dismiss command to the background Dart isolate.
        // Triggers LocationTaskHandler.onReceiveData() which deactivates
        // the alarm in the database. May fail if FGS is dead — the alarm
        // stays active in DB and will be re-evaluated on next service start.
        try {
            ForegroundService.sendData("""{"type":"dismiss","id":$alarmId}""")
        } catch (_: Exception) {
            // FGS not running — alarm stays active, will self-heal on restart.
        }
    }
}
