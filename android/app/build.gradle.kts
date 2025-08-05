plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    compileSdk = 35
    ndkVersion = "27.0.12077973"
    namespace = "com.example.practice"

    defaultConfig {
        applicationId = "com.example.practice"
        minSdk = 21
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true  // still useful if using Java 8+ APIs
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Optional for dev builds
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Required if you're using Java 8+ features (keep for safety with shared_preferences)
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
