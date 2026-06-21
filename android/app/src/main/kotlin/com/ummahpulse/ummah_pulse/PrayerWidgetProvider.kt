package com.ummahpulse.ummah_pulse

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class PrayerWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val nextPrayer = widgetData.getString("next_prayer", "—") ?: "—"
        val countdown = widgetData.getString("countdown", "--:--") ?: "--:--"
        val date = widgetData.getString("date", "") ?: ""
        val allPrayers = widgetData.getString("all_prayers", "") ?: ""

        appWidgetIds.forEach { widgetId ->
            val layoutId = if (isMediumWidget(context, appWidgetManager, widgetId)) {
                R.layout.prayer_widget_medium
            } else {
                R.layout.prayer_widget_small
            }

            val views = RemoteViews(context.packageName, layoutId).apply {
                setTextViewText(R.id.widget_next_prayer, nextPrayer)
                setTextViewText(R.id.widget_countdown, countdown)
                setTextViewText(R.id.widget_date, date)
                if (layoutId == R.layout.prayer_widget_medium) {
                    setTextViewText(R.id.widget_all_prayers, formatAllPrayers(allPrayers))
                }
            }

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    private fun isMediumWidget(
        context: Context,
        manager: AppWidgetManager,
        widgetId: Int,
    ): Boolean {
        val options = manager.getAppWidgetOptions(widgetId)
        val minWidth = options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 0)
        return minWidth >= 180
    }

    private fun formatAllPrayers(raw: String): String {
        if (raw.isBlank()) return ""
        return raw.split(";").joinToString("\n") { part ->
            val pieces = part.split("|")
            if (pieces.size == 2) "${pieces[0]}  ${pieces[1]}" else part
        }
    }
}
