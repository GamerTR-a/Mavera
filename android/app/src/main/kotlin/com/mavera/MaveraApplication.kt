package com.mavera

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * KARAR (R1/R2): Ana Flutter motoru süreç başlarken burada oluşturulur ve
 * önbelleğe alınır. Aktivite yok edilse (son uygulamalardan kaydırma) bile
 * motor ve Dart çekirdeği, ön plan servisi süreci canlı tuttuğu sürece çalışır.
 * Açılışta (BOOT_COMPLETED) süreç başlayınca da main() ekransız çalışır.
 */
class MaveraApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        if (FlutterEngineCache.getInstance().get(ENGINE_ID) != null) return
        val engine = FlutterEngine(this)
        SmsPlugin(this).register(engine.dartExecutor.binaryMessenger)
        SystemPlugin(this).register(engine.dartExecutor.binaryMessenger)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
    }

    companion object {
        const val ENGINE_ID = "guvenyuzuk_main"
    }
}
