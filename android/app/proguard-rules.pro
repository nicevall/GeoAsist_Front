# ⚡ OPTIMIZED: Proguard rules según BUENAS_PRACTICAS_FLUTTER.md para máxima compatibilidad con Claude Code

# =======================================
# 🚀 FLUTTER CORE RULES (ESENCIALES)
# =======================================

# Mantener clases Flutter esenciales
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Mantener métodos nativos de Flutter
-keepclassmembers class * {
    @io.flutter.plugin.common.MethodCall *;
    @io.flutter.plugin.common.PluginRegistry.Registrar *;
}

# =======================================
# 🔥 FIREBASE RULES (REQUERIDAS)
# =======================================

# Mantener clases Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepnames class com.firebase.** { *; }
-keepnames class com.google.firebase.** { *; }

# =======================================
# 📍 GEOLOCATION & LOCATION SERVICES
# =======================================

# Mantener clases de ubicación
-keep class android.location.** { *; }
-keep class com.google.android.gms.location.** { *; }

# =======================================
# 🔔 NOTIFICATION SERVICES  
# =======================================

# Mantener clases de notificaciones
-keep class android.app.NotificationManager { *; }
-keep class androidx.core.app.NotificationCompat** { *; }

# =======================================
# 📊 DATA MODELS (APP ESPECÍFICO)
# =======================================

# Mantener modelos de datos de la aplicación para serialización JSON
-keep class ec.edu.uide.geo_asist_front.models.** { *; }
-keepclassmembers class ec.edu.uide.geo_asist_front.models.** { *; }

# Mantener entidades de dominio
-keep class * extends ec.edu.uide.geo_asist_front.src.features.**.entities.** { *; }

# =======================================
# 🏗️ GSON/JSON SERIALIZATION
# =======================================

# Mantener anotaciones Gson si se usa
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Mantener clases genéricas
-keepattributes Signature
-keep class * implements java.io.Serializable { *; }

# =======================================
# 🚫 LOG REMOVAL (OPTIMIZACIÓN RELEASE)
# =======================================

# Remover logs en release para mejor rendimiento
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

# =======================================
# 🛡️ REFLECTION & DYNAMIC CODE
# =======================================

# Mantener clases que usan reflection
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Mantener constructores por defecto
-keepclassmembers public class * {
    public <init>(...);
}

# =======================================
# 🔒 SECURITY & OBFUSCATION
# =======================================

# No ofuscar nombres de archivos de recursos
-keepnames class * { *; }
-adaptresourcefilenames **.properties,**.xml,**.txt,**.json

# Mantener números de línea para debugging (útil para crash reports)
-keepattributes SourceFile,LineNumberTable

# =======================================
# ⚠️ SUPPRESSION DE WARNINGS
# =======================================

# Suprimir warnings comunes que no afectan funcionalidad
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn kotlin.jvm.internal.**
-dontwarn org.jetbrains.annotations.**