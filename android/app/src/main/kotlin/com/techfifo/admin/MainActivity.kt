package com.techfifo.admin

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "audio_record_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startRecording" -> {
                        Log.d("AudioRecord", "startRecording called")
                        // You can implement actual recording logic here.
                        result.success("Recording started!")
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }
}
