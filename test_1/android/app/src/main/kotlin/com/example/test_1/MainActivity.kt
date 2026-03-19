package com.example.test_1

import android.os.Build
import android.os.Bundle
import android.view.WindowManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.cardocard/refresh_rate"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "setHighRefreshRate" -> {
                    val success = setHighRefreshRate()
                    result.success(success)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun setHighRefreshRate(): Boolean {
        return try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Android 11+ - use newer API
                window.attributes.preferredDisplayModeId = 0 // 0 means highest available
            } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                // For Android 6.0+
                val windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
                val defaultDisplay = windowManager.defaultDisplay
                
                // Get the highest refresh rate
                val modes = defaultDisplay.supportedModes
                var maxRate = 60.0f
                
                for (mode in modes) {
                    val refreshRate = mode.refreshRate
                    if (refreshRate > maxRate) {
                        maxRate = refreshRate
                    }
                }
                
                // Set the refresh rate
                val layoutParams = window.attributes
                layoutParams.preferredRefreshRate = maxRate
                window.attributes = layoutParams
            }
            true
        } catch (e: Exception) {
            println("Error setting refresh rate: ${e.message}")
            false
        }
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Apply high refresh rate on app start
        setHighRefreshRate()
        
        // Make sure we're drawing edge-to-edge
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
        }
    }
}
