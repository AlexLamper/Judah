package com.getjudah.app.widget

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.view.View
import android.widget.RemoteViews
import com.getjudah.app.MainActivity
import com.getjudah.app.R
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider
import org.json.JSONObject
import java.time.LocalDate
import java.time.LocalTime
import java.time.temporal.ChronoUnit

class JudahSmallWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray, data: SharedPreferences) =
        JudahWidgetRenderer.render(context, mgr, ids, data, R.layout.judah_widget_small)
}

class JudahMediumWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray, data: SharedPreferences) =
        JudahWidgetRenderer.render(context, mgr, ids, data, R.layout.judah_widget_medium)
}

class JudahLargeWidget : HomeWidgetProvider() {
    override fun onUpdate(context: Context, mgr: AppWidgetManager, ids: IntArray, data: SharedPreferences) =
        JudahWidgetRenderer.render(context, mgr, ids, data, R.layout.judah_widget_large)
}

/**
 * Mirrors the rules in lib/domain/judah_state.dart so the widget stays right
 * while the app is closed:
 * - scene: morning 5-11, day 11-17, evening 17-22, night 22-5
 * - mood: sleepy at night, sad when a whole day was skipped, otherwise happy
 * - verse: today's entry from the verses the app stored for the coming days
 */
object JudahWidgetRenderer {

    fun render(context: Context, mgr: AppWidgetManager, ids: IntArray, data: SharedPreferences, layout: Int) {
        val now = LocalTime.now()
        val today = LocalDate.now()
        val scene = when (now.hour) {
            in 5..10 -> "morning"
            in 11..16 -> "day"
            in 17..21 -> "evening"
            else -> "night"
        }
        val lastActive = data.getString("lastActive", "").orEmpty()
        val missing = lastActive.isNotEmpty() &&
            runCatching { ChronoUnit.DAYS.between(LocalDate.parse(lastActive), today) >= 2 }.getOrDefault(false)
        val mood = when {
            scene == "night" -> "sleepy"
            missing -> "sad"
            else -> "happy"
        }

        val isPro = data.getBoolean("pro", false)
        val (ref, text) = todayVerse(data, today)
        val streakDay = data.getString("streakDay", "").orEmpty()
        val streakAlive = streakDay.isNotEmpty() &&
            runCatching { ChronoUnit.DAYS.between(LocalDate.parse(streakDay), today) <= 1 }.getOrDefault(false)
        val streak = if (streakAlive) (data.all["streak"] as? Number)?.toInt() ?: 0 else 0

        for (id in ids) {
            val views = RemoteViews(context.packageName, layout)
            data.getString("img_${mood}_$scene", null)?.let { path ->
                BitmapFactory.decodeFile(path)?.let { views.setImageViewBitmap(R.id.judah_image, it) }
            }
            if (isPro) {
                views.setTextViewText(R.id.verse_text, text)
                views.setTextViewText(R.id.verse_ref, ref)
            } else {
                views.setTextViewText(R.id.verse_text, "Unlock Judah Pro to bring your daily verse here.")
                views.setTextViewText(R.id.verse_ref, "Tap to open Judah")
            }
            if (layout == R.layout.judah_widget_large) {
                views.setTextViewText(
                    R.id.streak,
                    if (streak > 0) "🔥 $streak day streak" else "Read today's verse to start a streak",
                )
                views.setViewVisibility(R.id.streak, if (isPro) View.VISIBLE else View.GONE)
            }
            views.setOnClickPendingIntent(
                R.id.widget_root,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
            mgr.updateAppWidget(id, views)
        }
    }

    private fun todayVerse(data: SharedPreferences, today: LocalDate): Pair<String, String> {
        val fallback = "Psalm 119:105" to "Thy word is a lamp unto my feet, and a light unto my path."
        val raw = data.getString("verses", null) ?: return fallback
        return runCatching {
            val all = JSONObject(raw)
            // Today's verse, or the newest one stored if the app was not opened for weeks.
            val key = today.toString().takeIf { all.has(it) }
                ?: all.keys().asSequence().filter { it <= today.toString() }.maxOrNull()
                ?: return fallback
            val v = all.getJSONObject(key)
            v.getString("ref") to v.getString("text")
        }.getOrDefault(fallback)
    }
}
