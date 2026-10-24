package com.mavera

import android.app.NotificationManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/** guvenyuzuk/system: tam ekran bildirim izni, üretici ve Bluetooth ayarları. */
class SystemPlugin(private val context: Context) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "canUseFullScreenIntent" -> {
                    val nm = context.getSystemService(NotificationManager::class.java)
                    val ok = if (Build.VERSION.SDK_INT >= 34) nm.canUseFullScreenIntent() else true
                    result.success(ok)
                }
                "openManufacturerSettings" -> {
                    openManufacturer()
                    result.success(null)
                }
                "openBluetoothSettings" -> {
                    start(Intent(Settings.ACTION_BLUETOOTH_SETTINGS))
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun start(intent: Intent): Boolean = try {
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
        true
    } catch (_: Exception) {
        false
    }

    private fun openManufacturer() {
        val brand = Build.MANUFACTURER.lowercase()
        val candidates = mutableListOf<ComponentName>()
        when {
            brand.contains("xiaomi") || brand.contains("redmi") || brand.contains("poco") ->
                candidates += ComponentName(
                    "com.miui.securitycenter",
                    "com.miui.permcenter.autostart.AutoStartManagementActivity",
                )
            brand.contains("samsung") -> {
                candidates += ComponentName(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.battery.ui.BatteryActivity",
                )
                candidates += ComponentName(
                    "com.samsung.android.lool",
                    "com.samsung.android.sm.ui.battery.BatteryActivity",
                )
            }
            brand.contains("oppo") || brand.contains("realme") || brand.contains("oneplus") -> {
                candidates += ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.permission.startup.StartupAppListActivity",
                )
                candidates += ComponentName(
                    "com.coloros.safecenter",
                    "com.coloros.safecenter.startupapp.StartupAppListActivity",
                )
                candidates += ComponentName(
                    "com.oplus.battery",
                    "com.oplus.powermanager.fuelgaue.PowerUsageModelActivity",
                )
            }
            brand.contains("huawei") || brand.contains("honor") ->
                candidates += ComponentName(
                    "com.huawei.systemmanager",
                    "com.huawei.systemmanager.startupmgr.ui.StartupNormalAppListActivity",
                )
            brand.contains("vivo") ->
                candidates += ComponentName(
                    "com.vivo.permissionmanager",
                    "com.vivo.permissionmanager.activity.BgStartUpManagerActivity",
                )
        }
        for (c in candidates) {
            if (start(Intent().setComponent(c))) return
        }
        start(
            Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", context.packageName, null)),
        )
    }

    companion object {
        const val CHANNEL = "guvenyuzuk/system"
    }
}
