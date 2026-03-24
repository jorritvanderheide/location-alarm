package nl.bw20.there_yet

import android.app.Application
import com.pravera.flutter_foreground_task.service.ForegroundService

class ThereYetApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        ForegroundService.addTaskLifecycleListener(AlarmNotificationPlugin(this))
    }
}
