package com.example.ibuild

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class IBuildAppWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)

        if (intent.action == ACTION_REFRESH) {
            val now = SimpleDateFormat("hh:mm a", Locale.getDefault()).format(Date())
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            prefs.edit().putString(KEY_LAST_UPDATED, "Last sync: $now").apply()

            // Update UI immediately with refreshed timestamp
            updateAllWidgets(context)

            // Broadcast refresh request to MainActivity so Flutter syncs live Supabase stats if active
            val syncIntent = Intent(ACTION_WIDGET_REFRESH_REQUESTED).apply {
                setPackage(context.packageName)
            }
            context.sendBroadcast(syncIntent)
        }
    }

    companion object {
        const val PREFS_NAME = "ibuild_widget_preferences"
        const val KEY_PORTFOLIO_VALUE = "portfolio_value"
        const val KEY_TOTAL_SPENT = "total_spent"
        const val KEY_BUDGET_UTILIZATION_PCT = "budget_utilization_pct"
        const val KEY_ACTIVE_PROJECTS = "active_projects"
        const val KEY_TOTAL_PROJECTS = "total_projects"
        const val KEY_TODAY_ATTENDANCE = "today_attendance"
        const val KEY_ATTENDANCE_PCT = "attendance_pct"
        const val KEY_STREAK_DAYS = "streak_days"
        const val KEY_STREAK_SUB = "streak_sub"
        const val KEY_LAST_UPDATED = "last_updated"

        const val ACTION_REFRESH = "com.example.ibuild.ACTION_REFRESH"
        const val ACTION_WIDGET_REFRESH_REQUESTED = "com.example.ibuild.ACTION_WIDGET_REFRESH_REQUESTED"
        const val ACTION_OPEN_ATTENDANCE = "com.example.ibuild.ACTION_OPEN_ATTENDANCE"
        const val ACTION_OPEN_PROJECTS = "com.example.ibuild.ACTION_OPEN_PROJECTS"
        const val ACTION_OPEN_DPR = "com.example.ibuild.ACTION_OPEN_DPR"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val portfolioValue = prefs.getString(KEY_PORTFOLIO_VALUE, "₹0") ?: "₹0"
            val totalSpent = prefs.getString(KEY_TOTAL_SPENT, "₹0") ?: "₹0"
            val budgetUtilizationPct = prefs.getInt(KEY_BUDGET_UTILIZATION_PCT, 0)
            val activeProjects = prefs.getString(KEY_ACTIVE_PROJECTS, "0 Active") ?: "0 Active"
            val totalProjects = prefs.getString(KEY_TOTAL_PROJECTS, "0 Total") ?: "0 Total"
            val todayAttendance = prefs.getString(KEY_TODAY_ATTENDANCE, "0 / 0") ?: "0 / 0"
            val attendancePct = prefs.getString(KEY_ATTENDANCE_PCT, "0% On-Site") ?: "0% On-Site"
            val streakDays = prefs.getString(KEY_STREAK_DAYS, "0 At-Risk") ?: "0 At-Risk"
            val streakSub = prefs.getString(KEY_STREAK_SUB, "All Sites Normal") ?: "All Sites Normal"
            val lastUpdated = prefs.getString(KEY_LAST_UPDATED, "Last sync: Just now") ?: "Last sync: Just now"

            val views = RemoteViews(context.packageName, R.layout.ibuild_appwidget).apply {
                // Header
                setTextViewText(R.id.widget_last_updated, lastUpdated)

                // Financial Summary Bar
                setTextViewText(R.id.widget_portfolio_value, portfolioValue)
                setTextViewText(R.id.widget_total_spent, totalSpent)
                setTextViewText(R.id.widget_utilization_pct, "$budgetUtilizationPct%")
                setProgressBar(R.id.widget_budget_progress, 100, budgetUtilizationPct.coerceIn(0, 100), false)

                // Operations Triad
                setTextViewText(R.id.widget_active_projects, activeProjects)
                setTextViewText(R.id.widget_total_projects, totalProjects)
                setTextViewText(R.id.widget_today_attendance, todayAttendance)
                setTextViewText(R.id.widget_attendance_pct, attendancePct)
                setTextViewText(R.id.widget_site_streak, streakDays)
                setTextViewText(R.id.widget_streak_sub, streakSub)

                // 1. Root click launches main app dashboard
                val rootIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val rootPendingIntent = PendingIntent.getActivity(
                    context,
                    0,
                    rootIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_root, rootPendingIntent)

                // 2. TradingView-style Refresh Button click
                val refreshIntent = Intent(context, IBuildAppWidgetProvider::class.java).apply {
                    action = ACTION_REFRESH
                }
                val refreshPendingIntent = PendingIntent.getBroadcast(
                    context,
                    99,
                    refreshIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_btn_refresh, refreshPendingIntent)

                // 3. Projects box click launches Projects screen
                val projectsIntent = Intent(context, MainActivity::class.java).apply {
                    action = ACTION_OPEN_PROJECTS
                    putExtra("target_screen", "projects")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val projectsPendingIntent = PendingIntent.getActivity(
                    context,
                    3,
                    projectsIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_box_projects, projectsPendingIntent)

                // 4. Attendance button & box click launch Attendance
                val attendanceIntent = Intent(context, MainActivity::class.java).apply {
                    action = ACTION_OPEN_ATTENDANCE
                    putExtra("target_screen", "attendance")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val attendancePendingIntent = PendingIntent.getActivity(
                    context,
                    1,
                    attendanceIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_btn_attendance, attendancePendingIntent)
                setOnClickPendingIntent(R.id.widget_box_attendance, attendancePendingIntent)

                // 5. Quick DPR button & health box launch Daily DPR
                val dprIntent = Intent(context, MainActivity::class.java).apply {
                    action = ACTION_OPEN_DPR
                    putExtra("target_screen", "dpr")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val dprPendingIntent = PendingIntent.getActivity(
                    context,
                    2,
                    dprIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_btn_dpr, dprPendingIntent)
                setOnClickPendingIntent(R.id.widget_box_streak, dprPendingIntent)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val thisWidget = ComponentName(context, IBuildAppWidgetProvider::class.java)
            val allWidgetIds = appWidgetManager.getAppWidgetIds(thisWidget)
            for (widgetId in allWidgetIds) {
                updateAppWidget(context, appWidgetManager, widgetId)
            }
        }
    }
}
