// android/app/src/main/kotlin/com/example/music_share_app/CurrentSongPlugin.kt
// Stub for Android platform channel implementation
package com.example.music_share_app

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class CurrentSongPlugin: FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var context : Context
    private lateinit var channel : MethodChannel
    private var activity: Activity? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "music_share_app/current_song")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method == "getCurrentSong") {
            try {
                var title = ""
                var artist = ""

                var debugInfo = mutableListOf<String>()
                try {
                    // Try to get from MediaSessionManager first
                    val context = activity ?: this.context
                    val mediaSessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as android.media.session.MediaSessionManager
                    val controllers = mediaSessionManager.getActiveSessions(null)
                    for (controller in controllers) {
                        val metadata = controller.metadata
                        val playbackState = controller.playbackState
                        val pkg = controller.packageName
                        debugInfo.add("Session: $pkg, Title: ${metadata?.getString(android.media.MediaMetadata.METADATA_KEY_TITLE)}, Artist: ${metadata?.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST)}, State: ${playbackState?.state}")
                        if (metadata != null && playbackState != null && playbackState.state == android.media.session.PlaybackState.STATE_PLAYING) {
                            title = metadata.getString(android.media.MediaMetadata.METADATA_KEY_TITLE) ?: ""
                            artist = metadata.getString(android.media.MediaMetadata.METADATA_KEY_ARTIST) ?: ""
                            break
                        }
                    }
                } catch (e: Exception) {
                    android.util.Log.e("CurrentSongPlugin", "MediaSessionManager failed: ${e.localizedMessage}")
                }

                // If not found, try SharedPreferences (from NotificationListener)
                if (title.isEmpty() && artist.isEmpty()) {
                    val prefs = context.getSharedPreferences("current_song", Context.MODE_PRIVATE)
                    title = prefs.getString("title", "") ?: ""
                    artist = prefs.getString("artist", "") ?: ""
                    android.util.Log.d("CurrentSongPlugin", "Read from prefs: title=$title, artist=$artist")
                }
                android.util.Log.d("CurrentSongPlugin", debugInfo.joinToString("\n"))
                val song = mapOf("title" to title, "artist" to artist)
                result.success(song)

            } catch (e: Exception) {
                result.error("ERROR", e.localizedMessage, null)
            }
        } else {
            result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    override fun onDetachedFromActivity() {
        activity = null
    }
}
