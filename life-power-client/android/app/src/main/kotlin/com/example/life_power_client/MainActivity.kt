package com.example.life_power_client

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.Calendar

class MainActivity: FlutterActivity(), SensorEventListener {
    private val CHANNEL = "com.example.life_power/health"
    private var sensorManager: SensorManager? = null
    private var stepCounterSensor: Sensor? = null
    private var currentSteps = 0

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        sensorManager = getSystemService(Context.SENSOR_SERVICE) as SensorManager
        stepCounterSensor = sensorManager?.getDefaultSensor(Sensor.TYPE_STEP_COUNTER)
        
        // Register sensor listener
        stepCounterSensor?.let {
            sensorManager?.registerListener(this, it, SensorManager.SENSOR_DELAY_UI)
        }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "hasUsageStatsPermission" -> {
                    result.success(hasUsageStatsPermission())
                }
                "openUsageStatsSettings" -> {
                    startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                    result.success(true)
                }
                "getSleepDuration" -> {
                    val duration = getSleepDurationFromUsage()
                    result.success(duration)
                }
                "getTodaySteps" -> {
                    result.success(getTodaySteps())
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun hasUsageStatsPermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun getSleepDurationFromUsage(): Double {
        if (!hasUsageStatsPermission()) return 0.0
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        val endTime = calendar.timeInMillis
        calendar.add(Calendar.DAY_OF_YEAR, -1)
        calendar.set(Calendar.HOUR_OF_DAY, 21)
        calendar.set(Calendar.MINUTE, 0)
        val startTime = calendar.timeInMillis
        val events = usageStatsManager.queryEvents(startTime, endTime)
        val event = UsageEvents.Event()
        val eventTimes = mutableListOf<Long>()
        eventTimes.add(startTime)
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            eventTimes.add(event.timeStamp)
        }
        eventTimes.add(endTime)
        eventTimes.sort()
        var maxGap = 0L
        for (i in 0 until eventTimes.size - 1) {
            val gap = eventTimes[i+1] - eventTimes[i]
            if (gap > maxGap) maxGap = gap
        }
        val hours = maxGap.toDouble() / (1000 * 60 * 60)
        if (hours < 3.0) return 0.0
        return Math.min(hours, 12.0)
    }

    // --- Native Step Counter Logic ---

    override fun onSensorChanged(event: SensorEvent?) {
        if (event?.sensor?.type == Sensor.TYPE_STEP_COUNTER) {
            currentSteps = event.values[0].toInt()
            updateBaseStepsIfNeeded(currentSteps)
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) {}

    private fun getTodaySteps(): Int {
        val prefs = getSharedPreferences("health_prefs", Context.MODE_PRIVATE)
        val baseSteps = prefs.getInt("base_steps_${getTodayKey()}", -1)
        
        if (baseSteps == -1) return 0
        
        // If current sensor reading is 0, we might be waiting for first event
        if (currentSteps == 0) return 0
        
        val todaySteps = currentSteps - baseSteps
        return if (todaySteps > 0) todaySteps else 0
    }

    private fun updateBaseStepsIfNeeded(steps: Int) {
        val prefs = getSharedPreferences("health_prefs", Context.MODE_PRIVATE)
        val key = "base_steps_${getTodayKey()}"
        val baseSteps = prefs.getInt(key, -1)
        
        if (baseSteps == -1 && steps > 0) {
            prefs.edit().putInt(key, steps).apply()
        }
    }

    private fun getTodayKey(): String {
        val cal = Calendar.getInstance()
        return "${cal.get(Calendar.YEAR)}_${cal.get(Calendar.DAY_OF_YEAR)}"
    }
}
