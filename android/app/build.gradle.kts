plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "ashir.developer.sync_event"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Upgrade to Java 17 (required for latest Android Gradle Plugin)
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    defaultConfig {
        applicationId = "ashir.developer.sync_event"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystoreFile = file("../upload-keystore.jks")
            // Only set signing config if keystore file exists
            if (keystoreFile.exists()) {
                keyAlias = "upload"
                keyPassword = "ashirhash"
                storeFile = keystoreFile
                storePassword = "ashirhash"
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = true
            isShrinkResources = true
            
            // Only use release signing if keystore exists
            val keystoreFile = file("../upload-keystore.jks")
            if (keystoreFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            }

            //  Add ProGuard config to handle Razorpay & Flutter issues
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        getByName("debug") {
            // REMOVED: Don't use release signing for debug builds
            // Debug builds will use the default debug signing automatically
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:34.3.0"))
    implementation("com.google.firebase:firebase-analytics")
    // Add Razorpay dependency if not already in pubspec.yaml native side
    implementation("com.razorpay:checkout:1.6.33")
}