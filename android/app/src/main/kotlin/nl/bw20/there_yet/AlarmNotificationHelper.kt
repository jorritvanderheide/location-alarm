package nl.bw20.there_yet

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat

object AlarmNotificationHelper {
    private const val CHANNEL_ID = "alarm_alert_channel"
    private const val CHANNEL_NAME = "Alarm Alerts"
    // Use alarm ID + offset as notification ID so multiple alarms don't collide.
    private const val NOTIFICATION_ID_OFFSET = 30000

    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                CHANNEL_NAME,
                NotificationManager.IMPORTANCE_HIGH
            ).apply {
                description = "Location alarm alerts"
                enableVibration(true)
                setBypassDnd(true)
                lockscreenVisibility = NotificationCompat.VISIBILITY_PUBLIC
            }
            val nm = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            nm.createNotificationChannel(channel)
        }
    }

    fun show(context: Context, alarmId: Int, title: String, body: String) {
        ensureChannel(context)

        // Dismiss action → BroadcastReceiver (no app launch)
        val dismissIntent = Intent(context, AlarmDismissReceiver::class.java).apply {
            action = "nl.bw20.there_yet.DISMISS_ALARM"
            putExtra("alarm_id", alarmId)
        }
        val dismissPending = PendingIntent.getBroadcast(
            context, alarmId, dismissIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        // Content + full-screen intent → launches MainActivity
        val launchIntent = Intent(context, MainActivity::class.java).apply {
            action = "ALARM_RING"
            putExtra("alarm_id", alarmId)
            putExtra("alarm_title", title)
            putExtra("alarm_body", body)
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val contentPending = PendingIntent.getActivity(
            context, alarmId, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val fullScreenPending = PendingIntent.getActivity(
            context, alarmId + 10000, launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )

        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle(title)
            .setContentText(body)
            .setContentIntent(contentPending)
            .setPriority(NotificationCompat.PRIORITY_MAX)
            .setCategory(NotificationCompat.CATEGORY_ALARM)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setOngoing(true)
            .setAutoCancel(false)
            .setFullScreenIntent(fullScreenPending, true)
            .addAction(0, "Dismiss", dismissPending)
            .build()

        try {
            NotificationManagerCompat.from(context).notify(alarmId + NOTIFICATION_ID_OFFSET, notification)
        } catch (_: SecurityException) {
            // Missing POST_NOTIFICATIONS permission on Android 13+
        }
    }

    fun cancel(context: Context, alarmId: Int) {
        NotificationManagerCompat.from(context).cancel(alarmId + NOTIFICATION_ID_OFFSET)
    }
}
