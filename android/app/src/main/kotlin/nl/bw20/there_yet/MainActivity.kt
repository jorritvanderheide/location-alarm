package nl.bw20.there_yet

import android.app.KeyguardManager
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val SCREEN_CHANNEL = "nl.bw20.there_yet/screen"
    private var wakeLock: PowerManager.WakeLock? = null
    private var screenChannel: MethodChannel? = null

    // Stores intent extras from ALARM_RING full-screen intent, consumed by Dart
    private var pendingAlarmAction: String? = null
    private var pendingAlarmId: Int = -1
    private var pendingAlarmTitle: String? = null
    private var pendingAlarmBody: String? = null


    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Register alarm notification method channel on main engine
        AlarmNotificationPlugin.registerChannel(applicationContext, flutterEngine)

        // Register proximity alert method channel
        ProximityAlertManager.registerChannel(applicationContext, flutterEngine)

        // Screen method channel
        screenChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SCREEN_CHANNEL)
        screenChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "showOverLockScreen" -> {
                    showOverLockScreen()
                    result.success(null)
                }
                "clearLockScreenFlags" -> {
                    clearLockScreenFlags()
                    result.success(null)
                }
                "finishAndRemoveTask" -> {
                    finishAndRemoveTask()
                    result.success(null)
                }
                "isScreenOff" -> {
                    val powerManager = getSystemService(POWER_SERVICE) as PowerManager
                    val keyguardManager = getSystemService(KEYGUARD_SERVICE) as KeyguardManager
                    val isOff = !powerManager.isInteractive || keyguardManager.isKeyguardLocked
                    result.success(isOff)
                }
                "getLaunchAlarmData" -> {
                    if (pendingAlarmAction == "ALARM_RING" && pendingAlarmId != -1) {
                        val data = mapOf(
                            "alarm_id" to pendingAlarmId,
                            "title" to (pendingAlarmTitle ?: ""),
                            "body" to (pendingAlarmBody ?: "")
                        )
                        // Clear pending data after consumption
                        pendingAlarmAction = null
                        pendingAlarmId = -1
                        pendingAlarmTitle = null
                        pendingAlarmBody = null
                        result.success(data)
                    } else {
                        result.success(null)
                    }
                }
                else -> result.notImplemented()
            }
        }

        // Check if launched via full-screen intent
        handleAlarmIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleAlarmIntent(intent)
        // Notify Dart side about the new alarm intent
        if (pendingAlarmAction == "ALARM_RING") {
            screenChannel?.invokeMethod("onAlarmRing", mapOf(
                "alarm_id" to pendingAlarmId,
                "title" to (pendingAlarmTitle ?: ""),
                "body" to (pendingAlarmBody ?: "")
            ))
        }
    }

    private fun handleAlarmIntent(intent: Intent?) {
        if (intent?.action == "ALARM_RING") {
            pendingAlarmAction = "ALARM_RING"
            pendingAlarmId = intent.getIntExtra("alarm_id", -1)
            pendingAlarmTitle = intent.getStringExtra("alarm_title")
            pendingAlarmBody = intent.getStringExtra("alarm_body")
            // Show over lock screen when launched via alarm
            showOverLockScreen()
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
                "ThereYet:AlarmWakeLock"
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
