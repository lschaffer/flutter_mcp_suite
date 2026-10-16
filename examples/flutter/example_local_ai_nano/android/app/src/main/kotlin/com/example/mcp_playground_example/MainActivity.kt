package com.example.mcp_playground_example

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.BatteryManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.mcp_playground/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "getBatteryInfo" -> {
                    try {
                        val bm = getSystemService(Context.BATTERY_SERVICE) as? BatteryManager
                        val level = bm?.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY) ?: -1
                        val ifilter = IntentFilter(Intent.ACTION_BATTERY_CHANGED)
                        val batteryStatus: Intent? = registerReceiver(null, ifilter)
                        val status: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_STATUS, -1) ?: -1
                        val isCharging: Boolean = status == BatteryManager.BATTERY_STATUS_CHARGING ||
                                status == BatteryManager.BATTERY_STATUS_FULL
                        val chargePlug: Int = batteryStatus?.getIntExtra(BatteryManager.EXTRA_PLUGGED, -1) ?: -1
                        val plugType = when (chargePlug) {
                            BatteryManager.BATTERY_PLUGGED_USB -> "USB Cable"
                            BatteryManager.BATTERY_PLUGGED_AC -> "AC Fast Charger"
                            BatteryManager.BATTERY_PLUGGED_WIRELESS -> "Wireless Fast Charger"
                            else -> if (isCharging) "Charging" else "Unplugged (On Battery)"
                        }
                        val rawTemp = batteryStatus?.getIntExtra(BatteryManager.EXTRA_TEMPERATURE, 0) ?: 0
                        val temp = rawTemp / 10.0
                        val healthInt = batteryStatus?.getIntExtra(BatteryManager.EXTRA_HEALTH, BatteryManager.BATTERY_HEALTH_UNKNOWN) ?: -1
                        val health = when (healthInt) {
                            BatteryManager.BATTERY_HEALTH_GOOD -> "Good"
                            BatteryManager.BATTERY_HEALTH_OVERHEAT -> "Overheat"
                            BatteryManager.BATTERY_HEALTH_DEAD -> "Dead"
                            BatteryManager.BATTERY_HEALTH_OVER_VOLTAGE -> "Over Voltage"
                            else -> "Normal"
                        }

                        result.success(mapOf(
                            "level" to level,
                            "isCharging" to isCharging,
                            "plugType" to plugType,
                            "temp" to temp,
                            "health" to health,
                            "model" to Build.MODEL,
                            "manufacturer" to Build.MANUFACTURER,
                            "device" to Build.DEVICE
                        ))
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                "getDeviceTelemetry" -> {
                    try {
                        val cores = Runtime.getRuntime().availableProcessors()
                        val maxMemoryMb = Runtime.getRuntime().maxMemory() / (1024 * 1024)
                        val totalMemoryMb = Runtime.getRuntime().totalMemory() / (1024 * 1024)
                        val freeMemoryMb = Runtime.getRuntime().freeMemory() / (1024 * 1024)

                        val soc = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                            Build.SOC_MODEL
                        } else {
                            "Qualcomm Snapdragon 8 Elite"
                        }

                        result.success(mapOf(
                            "model" to Build.MODEL,
                            "manufacturer" to Build.MANUFACTURER,
                            "device" to Build.DEVICE,
                            "brand" to Build.BRAND,
                            "hardware" to Build.HARDWARE,
                            "socModel" to soc,
                            "androidVersion" to Build.VERSION.RELEASE,
                            "sdkInt" to Build.VERSION.SDK_INT,
                            "cores" to cores,
                            "maxMemoryMb" to maxMemoryMb,
                            "usedMemoryMb" to (totalMemoryMb - freeMemoryMb)
                        ))
                    } catch (e: Exception) {
                        result.error("ERROR", e.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
