package com.oxideplayer.app

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.content.Intent
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class HomeWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        appWidgetIds.forEach { widgetId ->
            val views = RemoteViews(context.packageName, R.layout.widget_layout).apply {
                val title = widgetData.getString("title", "Not Playing")
                val artist = widgetData.getString("artist", "Oxide Player")
                val isPlaying = widgetData.getBoolean("isPlaying", false)

                setTextViewText(R.id.tv_title, title)
                setTextViewText(R.id.tv_artist, artist)

                // Update Play/Pause icon
                // Note: R.drawable.ic_media_play/pause might vary by Android version, 
                // but standard android:drawable resources are safe.
                // However, accessing them from Kotlin requires standard resource IDs.
                // For simplicity in this MVP, we use standard android system drawables via resource lookup
                // or just rely on the XML initially. 
                // But to toggle, we need to set the image resource.
                
                if (isPlaying) {
                    setImageViewResource(R.id.bt_play, android.R.drawable.ic_media_pause)
                } else {
                    setImageViewResource(R.id.bt_play, android.R.drawable.ic_media_play)
                }

                // Setup PendingIntents for buttons
                val packageName = context.packageName
                
                // Helper to create pending intent
                fun getPendingIntent(action: String): android.app.PendingIntent {
                    val intent = android.content.Intent(context, HomeWidgetProvider::class.java).apply {
                        this.action = action
                    }
                    return android.app.PendingIntent.getBroadcast(
                        context, 
                        0, 
                        intent, 
                        android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                    )
                }

                setOnClickPendingIntent(R.id.bt_prev, getPendingIntent("ACTION_PREV"))
                setOnClickPendingIntent(R.id.bt_play, getPendingIntent("ACTION_TOGGLE"))
                setOnClickPendingIntent(R.id.bt_next, getPendingIntent("ACTION_NEXT"))
                
                // Open App on click cover/title
                val appIntent = android.content.Intent(context, MainActivity::class.java)
                val appPendingIntent = android.app.PendingIntent.getActivity(
                    context, 
                    0, 
                    appIntent, 
                    android.app.PendingIntent.FLAG_UPDATE_CURRENT or android.app.PendingIntent.FLAG_IMMUTABLE
                )
                setOnClickPendingIntent(R.id.iv_cover, appPendingIntent)
                setOnClickPendingIntent(R.id.tv_title, appPendingIntent)
            }
            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }
    
    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        // We can pass these actions to the HomeWidgetBackgroundReceiver 
        // OR we can just forward them to Dart via HomeWidget.
        // For now, let's assume we use HomeWidget.backgroundCallback logic or AudioService.
        
        // BETTER: Send to HomeWidget.
        // But since we are in the Provider, we can't easily execute Dart code directly without the BackgroundService started.
        // However, es.antonborri.home_widget handles this via HomeWidgetBackgroundReceiver.
        
        // Wait, strictly speaking, HomeWidget package provides a receiver that we should use in the manifest 
        // if we want `HomeWidget.registerInteractivityCallback`.
        // But here I'm overriding `onReceive` in MY provider. 
        // I should forward to `es.antonborri.home_widget.HomeWidgetBackgroundReceiver`?
        
        // SIMPLER: Use direct specific PendingIntents that target HomeWidgetBackgroundReceiver in the setup?
        // Let's stick to the plan: Use HomeWidget API.
        // But to make it work, I need to know HOW HomeWidget expects intents.
        
        // Taking a safer bet for MVP:
        // Use HomeWidget.interactiveCallback.
        // The standard way is using HomeWidget.registerInteractivityCallback in Dart.
        // In Kotlin, we just need to use `HomeWidgetLaunchIntent.getActivity` or similar?
        // HomeWidget docs say: use `HomeWidget.backgroundCallback` and setup intents to `HomeWidgetBackgroundReceiver`.
        
        // Let's defer strict background logic optimization and implement direct handling if needed.
        // Actually, if I just want to control AudioService, sending a MediaButton intent is cleaner.
        // But let's follow the HomeWidget pattern first.
        
        // Actually, for this MVP step, I will forward the intents to the AudioService if possible, or leave hooks for Dart.
        // Since I don't want to overcomplicate, I'll assume we handle it in Dart via HomeWidget's callback.
        // For that, the PendingIntent must be directed to HomeWidgetBackgroundReceiver?
        // No, let's keep it simple. Broadcast to THIS provider, and then push to Dart?
        
        if (intent.action != null) {
            when (intent.action) {
                "ACTION_PREV" -> sendMediaButton(context, android.view.KeyEvent.KEYCODE_MEDIA_PREVIOUS)
                "ACTION_TOGGLE" -> sendMediaButton(context, android.view.KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE)
                "ACTION_NEXT" -> sendMediaButton(context, android.view.KeyEvent.KEYCODE_MEDIA_NEXT)
            }
        }
    }

    private fun sendMediaButton(context: Context, keyCode: Int) {
        val downIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
        val downEvent = android.view.KeyEvent(android.view.KeyEvent.ACTION_DOWN, keyCode)
        downIntent.putExtra(Intent.EXTRA_KEY_EVENT, downEvent)
        context.sendBroadcast(downIntent)

        val upIntent = Intent(Intent.ACTION_MEDIA_BUTTON)
        val upEvent = android.view.KeyEvent(android.view.KeyEvent.ACTION_UP, keyCode)
        upIntent.putExtra(Intent.EXTRA_KEY_EVENT, upEvent)
        context.sendBroadcast(upIntent)
    }
}
