# ---- kotlinx.serialization ----
-allowaccessmodification
-keep class com.example.exammobile.core.model.** { *; }
-keep class kotlinx.serialization.** { *; }
-keepattributes *Annotation*, InnerClasses
-dontnote kotlinx.serialization.**
-keepclassmembers class com.example.exammobile.core.model.** {
    *** Companion;
    kotlinx.serialization.KSerializer serializer(...);
}
-keep,includedescriptorclasses class com.example.exammobile.core.model.**$$serializer { *; }
-keepclassmembers class com.example.exammobile.** {
    @kotlinx.serialization.Serializable <fields>;
}

# ---- OkHttp ----
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }

# ---- 安全存储 ----
-keep class androidx.security.crypto.** { *; }

# 保留行号用于崩溃定位，但不在日志打印敏感字段
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile

# R8 full mode: optional / transitively referenced classes
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-dontwarn javax.annotation.**
-dontwarn kotlinx.serialization.**
-dontwarn coil.**
-dontwarn okio.**

# Tink (security-crypto) 编译期注解，运行期不需要
-dontwarn com.google.errorprone.annotations.**
