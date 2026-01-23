# Flutter R8/ProGuard Rules

# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Drift / Sqlite
-keep class androidx.sqlite.db.framework.FrameworkSQLiteOpenHelperFactory { *; }
-keep class androidx.sqlite.db.SupportSQLiteOpenHelper$Factory { *; }

# Just Audio Background
-keep class com.ryanheise.just_audio_background.** { *; }

# General
-dontwarn io.flutter.**
-keepattributes SourceFile,LineNumberTable
