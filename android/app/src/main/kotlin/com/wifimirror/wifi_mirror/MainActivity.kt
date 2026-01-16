package com.wifimirror.wifi_mirror

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.media.projection.MediaProjectionManager
import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.wifimirror/service"
    private val MEDIA_PROJECTION_REQUEST_CODE = 1001
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "startForegroundService" -> {
                    // For Android 14+, we need to request media projection permission first
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
                        pendingResult = result
                        requestMediaProjectionPermission()
                    } else {
                        // For older versions, start the service directly
                        startScreenCaptureService(null, 0)
                        result.success(null)
                    }
                }
                "stopForegroundService" -> {
                    val intent = Intent(this, ScreenCaptureService::class.java)
                    stopService(intent)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun requestMediaProjectionPermission() {
        val mediaProjectionManager = getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager
        val captureIntent = mediaProjectionManager.createScreenCaptureIntent()
        startActivityForResult(captureIntent, MEDIA_PROJECTION_REQUEST_CODE)
    }

    private fun startScreenCaptureService(data: Intent?, resultCode: Int) {
        val intent = Intent(this, ScreenCaptureService::class.java).apply {
            if (data != null) {
                putExtra("resultCode", resultCode)
                putExtra("data", data)
            }
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            startForegroundService(intent)
        } else {
            startService(intent)
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == MEDIA_PROJECTION_REQUEST_CODE) {
            if (resultCode == Activity.RESULT_OK && data != null) {
                // Store the permission data and start the service with it
                ScreenCaptureService.setMediaProjectionData(resultCode, data)
                startScreenCaptureService(data, resultCode)
                pendingResult?.success(null)
            } else {
                pendingResult?.error("PERMISSION_DENIED", "User denied screen capture permission", null)
            }
            pendingResult = null
        }
    }
}
