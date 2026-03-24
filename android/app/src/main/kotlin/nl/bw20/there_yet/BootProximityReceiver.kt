package nl.bw20.there_yet

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/** Sets a flag on boot so the Dart foreground service re-registers
 *  all proximity alerts when it starts. Proximity alerts are cleared
 *  by Android on device reboot. */
class BootProximityReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED) return

        Log.d("ProximityAlert", "Boot completed — flagging for re-registration")

        context.getSharedPreferences(
            "FlutterSharedPreferences", Context.MODE_PRIVATE
        ).edit()
            .putBoolean("flutter.proximity_needs_reregister", true)
            .apply()
    }
}
