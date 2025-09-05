// android/app/build.gradle.kts

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    // 🔥 FIREBASE: Agregar Google Services plugin
    id("com.google.gms.google-services")
}

android {
    namespace = "ec.edu.uide.geo_asist_front"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // ⚡ OPTIMIZED: JDK 21 para compatibilidad 2025 según BUENAS_PRACTICAS_FLUTTER.md
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        // ✅ HABILITAR: Desugaring para flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "ec.edu.uide.geo_asist_front"
        minSdk = flutter.minSdkVersion  // Android 5.0+ for location services
        targetSdk = 34  // Android 14 for Play Store compliance
        compileSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        
        // Android-specific optimizations
        multiDexEnabled = true
        vectorDrawables.useSupportLibrary = true
        
        // Architecture filters for Play Store optimization
        ndk {
            abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
        }
        
        // Build config fields for runtime optimization
        buildConfigField("boolean", "ENABLE_PERFORMANCE_MONITORING", "true")
        buildConfigField("String", "BUILD_VARIANT", "\"debug\"")
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // ⚡ OPTIMIZED: Release optimizations según BUENAS_PRACTICAS_FLUTTER.md
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ AGREGAR: Dependencia de desugaring requerida por flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // 🔥 FIREBASE: Dependencias Firebase
    implementation(platform("com.google.firebase:firebase-bom:34.2.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-messaging")
}
