package com.wifimirror.wifi_mirror

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

class ScreenCaptureService : Service() {
    
    companion object {
        private var mediaProjectionResultCode: Int = 0
        private var mediaProjectionData: Intent? = null
        
        fun setMediaProjectionData(resultCode: Int, data: Intent) {
            mediaProjectionResultCode = resultCode
            mediaProjectionData = data
        }
        
        fun clearMediaProjectionData() {
            mediaProjectionResultCode = 0
            mediaProjectionData = null
        }
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        createNotificationChannel()
        
        val notification = NotificationCompat.Builder(this, "screen_capture_channel")
            .setContentTitle("Screen Sharing")
            .setContentText("Sharing your screen...")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setOngoing(true)
            .build()
        
        // For Android 14+ (API 34), we must have media projection permission before starting foreground
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            // The media projection permission was already obtained in MainActivity
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PROJECTION)
        } else {
            startForeground(1, notification)
        }
        
        return START_NOT_STICKY
    }

    override fun onDestroy() {
        super.onDestroy()
        clearMediaProjectionData()
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val serviceChannel = NotificationChannel(
                "screen_capture_channel",
                "Screen Capture Service",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(serviceChannel)
        }
    }
}
