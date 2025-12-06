# Keep Nearby Connections classes
-keep class com.google.android.gms.nearby.** { *; }
-dontwarn com.google.android.gms.nearby.**

# Keep required Flutter JNI
-keep class io.flutter.embedding.** { *; }
