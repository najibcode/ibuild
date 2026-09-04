package com.example.ibuild

import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ibuild/widget"
    private var initialRoute: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Capture route from widget intent
        initialRoute = intent?.getStringExtra("route")

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgetData" -> {
                    val activeProjects = call.argument<String>("activeProjects") ?: "8 Active"
                    val todayAttendance = call.argument<String>("todayAttendance") ?: "42 / 48"
                    val streakDays = call.argument<String>("streakDays") ?: "14 Days"
                    val lastUpdated = call.argument<String>("lastUpdated") ?: "Live Site Control"

                    val prefs = applicationContext.getSharedPreferences(
                        IBuildAppWidgetProvider.PREFS_NAME,
                        Context.MODE_PRIVATE
                    )
                    prefs.edit().apply {
                        putString(IBuildAppWidgetProvider.KEY_ACTIVE_PROJECTS, activeProjects)
                        putString(IBuildAppWidgetProvider.KEY_TODAY_ATTENDANCE, todayAttendance)
                        putString(IBuildAppWidgetProvider.KEY_STREAK_DAYS, streakDays)
                        putString(IBuildAppWidgetProvider.KEY_LAST_UPDATED, lastUpdated)
                        apply()
                    }

                    // Broadcast update to all instances of the home screen widget
                    IBuildAppWidgetProvider.updateAllWidgets(applicationContext)
                    result.success(true)
                }
                "getInitialRoute" -> {
                    result.success(initialRoute)
                    initialRoute = null
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val route = intent.getStringExtra("route")
        if (route != null && flutterEngine != null) {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onWidgetRoute", route)
        }
    }
}
