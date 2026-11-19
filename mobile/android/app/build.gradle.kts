plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "org.focusuganda.fcu"
    // 37: flutter_local_notifications and permission_handler require it
    // (compile-time only; minSdk/targetSdk are unchanged).
    compileSdk = maxOf(flutter.compileSdkVersion, 37)
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // flutter_local_notifications needs Java 8+ library desugaring.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Needed by flutter_local_notifications.
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "org.focusuganda.fcu"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // One fixed key for every CI build, so a newer APK installs over an
    // older one (in-app updates from GitHub Releases). CI writes the key from
    // the repository secrets; locally (no env) Android's debug key is used.
    val fcuKeystore = System.getenv("FCU_KEYSTORE_PATH")?.let { file(it) }
    val hasFcuKey = fcuKeystore != null && fcuKeystore.exists()
    signingConfigs {
        if (hasFcuKey) {
            create("fcu") {
                storeFile = fcuKeystore
                storePassword = System.getenv("FCU_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("FCU_KEY_ALIAS")
                keyPassword = System.getenv("FCU_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        debug {
            if (hasFcuKey) signingConfig = signingConfigs.getByName("fcu")
        }
        release {
            // TODO: a real release key before any store upload.
            signingConfig = signingConfigs.getByName(if (hasFcuKey) "fcu" else "debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
