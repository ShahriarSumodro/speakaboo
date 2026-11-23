# Flutter Wrapper Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Audio and Record plugin protections
-dontwarn com.ryanheise.audioservice.**
-keep class com.ryanheise.audioservice.** { *; }
-keep class xyz.luan.audioplayers.** { *; }
-keep class com.llfbandit.record.** { *; }

# OkHttp & Network Keep Rules
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# Keep data models / JSON serialization
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
