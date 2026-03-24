package nl.bw20.there_yet

import android.content.Context
import android.media.AudioAttributes
import android.media.MediaPlayer
import android.media.RingtoneManager
import com.pravera.flutter_foreground_task.FlutterForegroundTaskLifecycleListener
import com.pravera.flutter_foreground_task.FlutterForegroundTaskStarter
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class AlarmNotificationPlugin(private val context: Context) :
    FlutterForegroundTaskLifecycleListener {

    companion object {
        const val CHANNEL = "nl.bw20.there_yet/alarm_notification"
        const val AUDIO_CHANNEL = "nl.bw20.there_yet/alarm_audio"

        private var mediaPlayer: MediaPlayer? = null

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
                            val alarmId = call.argument<Int>("alarmId") ?: -1
                            AlarmNotificationHelper.cancel(context, alarmId)
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }

            MethodChannel(engine.dartExecutor.binaryMessenger, AUDIO_CHANNEL)
                .setMethodCallHandler { call, result ->
                    when (call.method) {
                        "play" -> {
                            playAlarmSound(context)
                            result.success(null)
                        }
                        "stop" -> {
                            stopAlarmSound()
                            result.success(null)
                        }
                        else -> result.notImplemented()
                    }
                }
        }

        fun playAlarmSound(context: Context) {
            stopAlarmSound()

            val uri = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)

            val attrs = AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_ALARM)
                .setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION)
                .build()

            val player = MediaPlayer()
            player.setAudioAttributes(attrs)

            try {
                player.setDataSource(context, uri)
                player.isLooping = true
                player.prepare()
                player.start()
                mediaPlayer = player
            } catch (e: Exception) {
                player.release()
            }
        }

        fun stopAlarmSound() {
            mediaPlayer?.let {
                try {
                    if (it.isPlaying) it.stop()
                    it.release()
                } catch (_: Exception) {}
            }
            mediaPlayer = null
        }
    }

    override fun onEngineCreate(flutterEngine: FlutterEngine?) {
        flutterEngine?.let {
            registerChannel(context, it)
            ProximityAlertManager.registerChannel(context, it)
        }
    }

    override fun onTaskStart(starter: FlutterForegroundTaskStarter) {}
    override fun onTaskRepeatEvent() {}
    override fun onTaskDestroy() {
        stopAlarmSound()
    }
    override fun onEngineWillDestroy() {}
}
