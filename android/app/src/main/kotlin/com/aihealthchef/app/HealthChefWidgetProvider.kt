package com.aihealthchef.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget écran d'accueil : macros du jour + streak. Les données sont écrites
 * par HomeWidgetService.update (lib/services/home_widget_service.dart),
 * déclenché à chaque ouverture du dashboard (voir homeWidgetReconcilerProvider
 * dans lib/providers/dashboard_provider.dart).
 */
class HealthChefWidgetProvider : HomeWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences,
    ) {
        val kcal = widgetData.getInt("kcal", 0)
        val targetKcal = widgetData.getInt("targetKcal", 0)
        val streak = widgetData.getInt("streak", 0)

        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.health_chef_widget).apply {
                setTextViewText(R.id.widget_kcal, "$kcal / $targetKcal kcal")
                setTextViewText(
                    R.id.widget_streak,
                    if (streak > 0) "🔥 $streak jours" else "Aucun repas loggé aujourd'hui",
                )
                setOnClickPendingIntent(
                    R.id.widget_container,
                    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
                )
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
}
