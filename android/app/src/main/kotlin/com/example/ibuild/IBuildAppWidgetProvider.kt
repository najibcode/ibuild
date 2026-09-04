package com.example.ibuild

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

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

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
    }

    companion object {
        const val PREFS_NAME = "ibuild_widget_preferences"
        const val KEY_ACTIVE_PROJECTS = "active_projects"
        const val KEY_TODAY_ATTENDANCE = "today_attendance"
        const val KEY_STREAK_DAYS = "streak_days"
        const val KEY_LAST_UPDATED = "last_updated"

        const val ACTION_OPEN_ATTENDANCE = "com.example.ibuild.ACTION_OPEN_ATTENDANCE"
        const val ACTION_OPEN_DPR = "com.example.ibuild.ACTION_OPEN_DPR"

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val activeProjects = prefs.getString(KEY_ACTIVE_PROJECTS, "8 Active") ?: "8 Active"
            val todayAttendance = prefs.getString(KEY_TODAY_ATTENDANCE, "42 / 48") ?: "42 / 48"
            val streakDays = prefs.getString(KEY_STREAK_DAYS, "14 Days") ?: "14 Days"
            val lastUpdated = prefs.getString(KEY_LAST_UPDATED, "Live Site Control") ?: "Live Site Control"

            val views = RemoteViews(context.packageName, R.layout.ibuild_appwidget).apply {
                setTextViewText(R.id.widget_active_projects, activeProjects)
                setTextViewText(R.id.widget_today_attendance, todayAttendance)
                setTextViewText(R.id.widget_site_streak, streakDays)
                setTextViewText(R.id.widget_last_updated, lastUpdated)

                // 1. Root click launches main app
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

                // 2. Attendance button click launches Attendance screen in app
                val attendanceIntent = Intent(context, MainActivity::class.java).apply {
                    action = ACTION_OPEN_ATTENDANCE
                    putExtra("route", "/attendance")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val attendancePendingIntent = PendingIntent.getActivity(
                    context,
                    1,
                    attendanceIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_btn_attendance, attendancePendingIntent)

                // 3. Quick DPR button click launches Projects / DPR screen in app
                val dprIntent = Intent(context, MainActivity::class.java).apply {
                    action = ACTION_OPEN_DPR
                    putExtra("route", "/projects")
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
                }
                val dprPendingIntent = PendingIntent.getActivity(
                    context,
                    2,
                    dprIntent,
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.widget_btn_dpr, dprPendingIntent)
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
