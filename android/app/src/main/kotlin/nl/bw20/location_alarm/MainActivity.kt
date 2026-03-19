package nl.bw20.location_alarm

import android.app.KeyguardManager
import android.os.Build
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "nl.bw20.location_alarm/screen"
    private var wakeLock: PowerManager.WakeLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "showOverLockScreen" -> {
                    showOverLockScreen()
                    result.success(null)
                }
                "clearLockScreenFlags" -> {
                    clearLockScreenFlags()
                    result.success(null)
                }
                "isScreenOff" -> {
                    val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                    val keyguardManager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
                    val isOff = !powerManager.isInteractive || keyguardManager.isKeyguardLocked
                    result.success(isOff)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        }
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        if (wakeLock == null) {
            val powerManager = getSystemService(POWER_SERVICE) as PowerManager
            wakeLock = powerManager.newWakeLock(
                PowerManager.FULL_WAKE_LOCK or
                PowerManager.ACQUIRE_CAUSES_WAKEUP or
                PowerManager.ON_AFTER_RELEASE,
                "LocationAlarm:AlarmWakeLock"
            )
            wakeLock?.acquire(10 * 60 * 1000L)
        }
    }

    private fun clearLockScreenFlags() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(false)
            setTurnScreenOn(false)
        }
        window.clearFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        wakeLock?.let {
            if (it.isHeld) it.release()
        }
        wakeLock = null
    }
}
