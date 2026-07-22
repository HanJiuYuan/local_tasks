package com.example.local_tasks

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val countdownSoundChannel = "local_tasks/countdown_sound"
    private var toneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            countdownSoundChannel,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playCountdown" -> {
                    playCountdownTone()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun playCountdownTone() {
        if (toneGenerator == null) {
            toneGenerator = ToneGenerator(AudioManager.STREAM_MUSIC, 100)
        }
        toneGenerator?.startTone(ToneGenerator.TONE_PROP_BEEP, 160)
    }

    override fun onDestroy() {
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }
}
