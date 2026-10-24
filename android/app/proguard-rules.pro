# flutter_local_notifications (Gson ile zamanlanmış bildirim serileştirme)
-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# flutter_foreground_task servis ve alıcıları
-keep class com.pravera.flutter_foreground_task.** { *; }

# Uygulamanın kendi kanalları
-keep class com.mavera.** { *; }
