package com.example.music_share_app

import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class NotificationListener : NotificationListenerService() {
    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val extras = sbn.notification.extras
        val title = extras.getString("android.title") ?: ""
        val text = extras.getString("android.text") ?: ""
        Log.d("NotificationListener", "Title: $title, Text: $text, Package: ${sbn.packageName}")
        // Only process Tidal notifications
        if (sbn.packageName == "com.aspiro.tidal") {
            // Save to shared preferences for Dart side to read
            val prefs = applicationContext.getSharedPreferences("current_song", Context.MODE_PRIVATE)
            prefs.edit()
                .putString("title", title)
                .putString("artist", text)
                .apply()
            Log.d("NotificationListener", "Wrote to prefs: title=$title, artist=$text")
        }
    }
}