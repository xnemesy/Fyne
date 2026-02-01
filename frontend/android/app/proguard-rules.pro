# Isar
-keep class * extends isar.IsarObject { *; }
-keep class com.isar.** { *; }
-dontwarn com.isar.**

# Crypto (BouncyCastle & PointyCastle)
-keep class org.bouncycastle.** { *; }
-dontwarn org.bouncycastle.**

# Prevent stripping of @ignored fields (transient decrypted data)
-keepclassmembers class * {
    @isar.Ignore <fields>;
}

# Flutter Secure Storage
-keep class com.it_nomads.fluttersecurestorage.** { *; } 
