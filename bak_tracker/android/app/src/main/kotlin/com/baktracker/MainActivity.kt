package com.baktracker

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import android.content.Intent

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleIntent(intent)
    }

    private fun handleIntent(intent: Intent) {
        // Handle widget click intents or other types of intents here
        val data = intent.getStringExtra("some_data_key")
        // Process the intent data as necessary
    }
}