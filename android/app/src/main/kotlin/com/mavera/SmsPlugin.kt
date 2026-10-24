package com.mavera

import android.app.Activity
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.telephony.SmsManager
import androidx.core.content.ContextCompat
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.atomic.AtomicInteger

/**
 * SMS yedeği: MethodChannel("guvenyuzuk/sms"), send(phones, text) → bool.
 * Her parçanın gönderim sonucu PendingIntent ile alınır; hepsi başarılıysa true.
 */
class SmsPlugin(private val context: Context) {
    fun register(messenger: BinaryMessenger) {
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method != "send") {
                result.notImplemented()
                return@setMethodCallHandler
            }
            val phones = call.argument<List<String>>("phones") ?: emptyList()
            val text = call.argument<String>("text") ?: ""
            if (ContextCompat.checkSelfPermission(context, android.Manifest.permission.SEND_SMS)
                != PackageManager.PERMISSION_GRANTED
            ) {
                result.error("NO_PERMISSION", "SEND_SMS izni yok", null)
                return@setMethodCallHandler
            }
            send(phones.filter { it.isNotBlank() }, text) { ok -> result.success(ok) }
        }
    }

    private fun smsManager(): SmsManager =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            context.getSystemService(SmsManager::class.java)
        } else {
            @Suppress("DEPRECATION")
            SmsManager.getDefault()
        }

    private fun send(phones: List<String>, text: String, done: (Boolean) -> Unit) {
        if (phones.isEmpty()) {
            done(false)
            return
        }
        val manager = smsManager()
        val parts = manager.divideMessage(text)
        val action = "com.mavera.SMS_SENT_${System.nanoTime()}"
        val expected = phones.size * parts.size
        val remaining = AtomicInteger(expected)
        var allOk = true
        var finished = false
        val handler = Handler(Looper.getMainLooper())

        lateinit var receiver: BroadcastReceiver
        fun finish() {
            if (finished) return
            finished = true
            try {
                context.unregisterReceiver(receiver)
            } catch (_: Exception) {
            }
            done(allOk)
        }
        receiver = object : BroadcastReceiver() {
            override fun onReceive(c: Context?, intent: Intent?) {
                if (resultCode != Activity.RESULT_OK) allOk = false
                if (remaining.decrementAndGet() <= 0) finish()
            }
        }
        ContextCompat.registerReceiver(
            context, receiver, IntentFilter(action), ContextCompat.RECEIVER_NOT_EXPORTED,
        )
        // Sonuç gelmezse 60 sn sonra başarısız say.
        handler.postDelayed({
            if (!finished) {
                allOk = false
                finish()
            }
        }, 60_000)

        var requestCode = 0
        for (phone in phones) {
            val intents = ArrayList<PendingIntent>()
            for (i in parts.indices) {
                val intent = Intent(action).setPackage(context.packageName)
                intents.add(
                    PendingIntent.getBroadcast(
                        context, requestCode++, intent,
                        PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_ONE_SHOT,
                    ),
                )
            }
            try {
                manager.sendMultipartTextMessage(phone, null, parts, intents, null)
            } catch (e: Exception) {
                allOk = false
                repeat(parts.size) {
                    if (remaining.decrementAndGet() <= 0) handler.post { finish() }
                }
            }
        }
    }

    companion object {
        const val CHANNEL = "guvenyuzuk/sms"
    }
}
