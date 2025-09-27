package com.example.medical_transcription

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.EventChannel
import android.content.Intent
import android.app.NotificationManager
import android.app.NotificationChannel
import android.app.Notification
import android.os.Build
import androidx.core.app.NotificationCompat

class MainActivity: FlutterActivity() {
    private val CHANNEL = "medical_transcription/native"
    private val AUDIO_LEVEL_CHANNEL = "medical_transcription/audio_level"
    private val NOTIFICATION_ID = 1001
    private val CHANNEL_ID = "medical_transcription_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        createNotificationChannel()
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "shareText" -> {
                    val text = call.argument<String>("text")
                    val subject = call.argument<String>("subject")
                    shareText(text, subject)
                    result.success(null)
                }
                "showNotification" -> {
                    val title = call.argument<String>("title")
                    val message = call.argument<String>("message")
                    val ongoing = call.argument<Boolean>("ongoing") ?: false
                    showNotification(title, message, ongoing)
                    result.success(null)
                }
                "hideNotification" -> {
                    hideNotification()
                    result.success(null)
                }
                "setAudioGain" -> {
                    val gain = call.argument<Double>("gain")
                    // Audio gain control would be implemented here
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun shareText(text: String?, subject: String?) {
        val intent = Intent().apply {
            action = Intent.ACTION_SEND
            putExtra(Intent.EXTRA_TEXT, text)
            putExtra(Intent.EXTRA_SUBJECT, subject)
            type = "text/plain"
        }
        startActivity(Intent.createChooser(intent, "Share Transcript"))
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                CHANNEL_ID,
                "Medical Transcription",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Recording notifications"
            }
            val notificationManager = getSystemService(NotificationManager::class.java)
            notificationManager.createNotificationChannel(channel)
        }
    }

    private fun showNotification(title: String?, message: String?, ongoing: Boolean) {
        val notification = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(message)
            .setSmallIcon(android.R.drawable.ic_media_play)
            .setOngoing(ongoing)
            .build()

        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.notify(NOTIFICATION_ID, notification)
    }

    private fun hideNotification() {
        val notificationManager = getSystemService(NotificationManager::class.java)
        notificationManager.cancel(NOTIFICATION_ID)
    }
}