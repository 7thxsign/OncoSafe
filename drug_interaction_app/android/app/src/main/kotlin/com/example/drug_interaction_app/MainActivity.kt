package com.example.drug_interaction_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.os.Build

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.drug_interaction_app/network"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "checkNetworkConnectivity") {
                val connectivityManager = context.getSystemService(CONNECTIVITY_SERVICE) as ConnectivityManager
                var isConnected = false

                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                    val network = connectivityManager.activeNetwork
                    if (network != null) {
                        val capabilities = connectivityManager.getNetworkCapabilities(network)
                        isConnected = capabilities?.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET) == true
                    }
                } else {
                    @Suppress("DEPRECATION")
                    val networkInfo = connectivityManager.activeNetworkInfo
                    isConnected = networkInfo?.isConnected == true
                }

                result.success(isConnected)
            } else {
                result.notImplemented()
            }
        }
    }
}
