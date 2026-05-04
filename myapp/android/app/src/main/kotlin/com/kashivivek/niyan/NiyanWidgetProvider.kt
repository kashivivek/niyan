package com.kashivivek.niyan

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class NiyanWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.niyan_widget).apply {
                val overdue = widgetData.getString("overdue_count", "0")
                val upcoming = widgetData.getString("upcoming_count", "0")
                val lastUpdated = widgetData.getString("last_updated", "Updated now")

                setTextViewText(R.id.overdue_count, overdue)
                setTextViewText(R.id.upcoming_count, upcoming)
                setTextViewText(R.id.last_updated, lastUpdated)
            }
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
