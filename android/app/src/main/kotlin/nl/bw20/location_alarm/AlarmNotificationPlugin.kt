package nl.bw20.location_alarm

import android.content.Context
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AlarmNotificationPlugin(private val context: Context) :
    FlutterForegroundTaskLifecycleListener {

    companion object {
        const val CHANNEL = "nl.bw20.location_alarm/alarm_notification"

        fun registerChannel(context: Context, engine: FlutterEngine) {
            MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "showAlarm" -> {
                            val alarmId = call.argument<Int>("alarmId") ?: -1
                            val title = call.argument<String>("title") ?: ""
                            val body = call.argument<String>("body") ?: ""
                            AlarmNotificationHelper.show(context, alarmId, title, body)
                            result.success(null)
                        }
                        "dismissAlarm" -> {
                            AlarmNotificationHelper.cancel(context)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
        }
    }

    override fun onEngineCreate(flutterEngine: FlutterEngine?) {
        flutterEngine?.let { registerChannel(context, it) }
    }

    override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}
    override fun onTaskRepeatEvent() {}
    override fun onTaskDestroy() {}
    override fun onEngineWillDestroy() {}
}
