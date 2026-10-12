# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.

# ===== Xposed 入口必须保留（xposed_init 里是类名字符串，混淆后会对不上）=====
-keep class io.github.proify.lyricon.qmmiprovider.xposed.HookEntry { *; }
-keep class io.github.proify.lyricon.qmmiprovider.xposed.MiuiMusic { *; }
-keepnames class io.github.proify.lyricon.qmmiprovider.xposed.HookEntry
-keepnames class io.github.proify.lyricon.qmmiprovider.xposed.MiuiMusic
-keepclassmembers class io.github.proify.lyricon.qmmiprovider.** { *; }
-keepattributes *Annotation*, InnerClasses, Signature, Exceptions, SourceFile, LineNumberTable

# YukiHookAPI / KavaRef
-keep class com.highcapable.yukihookapi.** { *; }
-keep class com.highcapable.kavaref.** { *; }
-dontwarn com.highcapable.**

# Kotlin / 序列化
-keep class kotlin.Metadata { *; }
-keepclassmembers class kotlinx.serialization.json.** { *; }
-dontwarn kotlinx.serialization.**

# 按类名反射的目标 App 内部类（运行时才去加载，混淆期只报缺失）
-keep class com.tencent.qqmusiccommon.** { *; }
-dontwarn com.tencent.qqmusiccommon.**
-dontwarn com.miui.player.**