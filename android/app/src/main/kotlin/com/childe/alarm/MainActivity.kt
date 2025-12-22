package com.childe.alarm

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "com.childe.alarm/screen_unlock"
    private val TAG = "AlarmMainActivity"
    private var methodChannel: MethodChannel? = null
    private var screenUnlockReceiver: BroadcastReceiver? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        Log.d(TAG, "✅ MainActivity onCreate called")
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        Log.d(TAG, "✅ Configuring Flutter Engine")
        
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        Log.d(TAG, "✅ Method Channel created: $CHANNEL")
        
        registerScreenUnlockReceiver()
    }

    private fun registerScreenUnlockReceiver() {
        Log.d(TAG, "📡 Registering screen unlock receiver...")
        
        screenUnlockReceiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                val action = intent?.action ?: "unknown"
                Log.d(TAG, "📱 BroadcastReceiver triggered! Action: $action")
                
                when (action) {
                    Intent.ACTION_USER_PRESENT -> {
                        Log.d(TAG, "🔓🔓🔓 SCREEN UNLOCKED DETECTED! 🔓🔓🔓")
                        methodChannel?.invokeMethod("onScreenUnlocked", null)
                    }
                    Intent.ACTION_SCREEN_ON -> {
                        Log.d(TAG, "💡 Screen turned ON (may be locked)")
                        methodChannel?.invokeMethod("onScreenOn", null)
                    }
                    Intent.ACTION_SCREEN_OFF -> {
                        Log.d(TAG, "🌙 Screen turned OFF")
                    }
                }
            }
        }

        val filter = IntentFilter().apply {
            addAction(Intent.ACTION_USER_PRESENT)
            addAction(Intent.ACTION_SCREEN_ON)
            addAction(Intent.ACTION_SCREEN_OFF)
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            registerReceiver(screenUnlockReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            Log.d(TAG, "✅ Receiver registered (Android 13+)")
        } else {
            registerReceiver(screenUnlockReceiver, filter)
            Log.d(TAG, "✅ Receiver registered (Legacy)")
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "🧹 MainActivity onDestroy called")
        super.onDestroy()
        try {
            screenUnlockReceiver?.let {
                unregisterReceiver(it)
                Log.d(TAG, "✅ Screen unlock receiver unregistered")
            }
        } catch (e: Exception) {
            Log.e(TAG, "⚠️ Error unregistering receiver: ${e.message}")
        }
    }

    override fun onResume() {
        super.onResume()
        Log.d(TAG, "📱 MainActivity onResume")
    }

    override fun onPause() {
        super.onPause()
        Log.d(TAG, "📱 MainActivity onPause")
    }
}