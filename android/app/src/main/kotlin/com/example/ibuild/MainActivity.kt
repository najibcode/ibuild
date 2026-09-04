package com.example.ibuild

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.ibuild/widget"
    private var initialRoute: String? = null
    private var refreshReceiver: BroadcastReceiver? = null

    override fun getInitialRoute(): String {
        return "/dashboard"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Capture target screen from widget intent
        initialRoute = intent?.getStringExtra("target_screen") ?: intent?.getStringExtra("route")

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidgetData" -> {
                    val portfolioValue = call.argument<String>("portfolioValue") ?: "₹0"
                    val totalSpent = call.argument<String>("totalSpent") ?: "₹0"
                    val budgetUtilizationPct = call.argument<Int>("budgetUtilizationPct") ?: 0
                    val activeProjects = call.argument<String>("activeProjects") ?: "0 Active"
                    val totalProjects = call.argument<String>("totalProjects") ?: "0 Total"
                    val todayAttendance = call.argument<String>("todayAttendance") ?: "0 / 0"
                    val attendancePct = call.argument<String>("attendancePct") ?: "0% On-Site"
                    val streakDays = call.argument<String>("streakDays") ?: "14 Days"
                    val streakSub = call.argument<String>("streakSub") ?: "Zero Incidents"
                    val lastUpdated = call.argument<String>("lastUpdated") ?: "Last sync: Just now"

                    val prefs = applicationContext.getSharedPreferences(
                        IBuildAppWidgetProvider.PREFS_NAME,
                        Context.MODE_PRIVATE
                    )
                    prefs.edit().apply {
                        putString(IBuildAppWidgetProvider.KEY_PORTFOLIO_VALUE, portfolioValue)
                        putString(IBuildAppWidgetProvider.KEY_TOTAL_SPENT, totalSpent)
                        putInt(IBuildAppWidgetProvider.KEY_BUDGET_UTILIZATION_PCT, budgetUtilizationPct)
                        putString(IBuildAppWidgetProvider.KEY_ACTIVE_PROJECTS, activeProjects)
                        putString(IBuildAppWidgetProvider.KEY_TOTAL_PROJECTS, totalProjects)
                        putString(IBuildAppWidgetProvider.KEY_TODAY_ATTENDANCE, todayAttendance)
                        putString(IBuildAppWidgetProvider.KEY_ATTENDANCE_PCT, attendancePct)
                        putString(IBuildAppWidgetProvider.KEY_STREAK_DAYS, streakDays)
                        putString(IBuildAppWidgetProvider.KEY_STREAK_SUB, streakSub)
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

        // Register receiver for on-demand widget refresh click
        refreshReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                channel.invokeMethod("onRefreshRequested", null)
            }
        }
        val filter = IntentFilter(IBuildAppWidgetProvider.ACTION_WIDGET_REFRESH_REQUESTED)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(refreshReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
        } else {
            registerReceiver(refreshReceiver, filter)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        val target = intent.getStringExtra("target_screen") ?: intent.getStringExtra("route")
        if (target != null && flutterEngine != null) {
            MethodChannel(flutterEngine!!.dartExecutor.binaryMessenger, CHANNEL).invokeMethod("onWidgetRoute", target)
        }
    }

    override fun onDestroy() {
        refreshReceiver?.let {
            try {
                unregisterReceiver(it)
            } catch (e: Exception) {
                // Receiver may already be unregistered
            }
        }
        super.onDestroy()
    }
}
