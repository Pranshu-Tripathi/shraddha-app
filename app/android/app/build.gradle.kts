plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
val releaseKeystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
val releaseKeyAlias = System.getenv("ANDROID_KEY_ALIAS")
val releaseKeyPassword = System.getenv("ANDROID_KEY_PASSWORD")
val releaseSigningVars = mapOf(
    "ANDROID_KEYSTORE_PATH" to releaseKeystorePath,
    "ANDROID_KEYSTORE_PASSWORD" to releaseKeystorePassword,
    "ANDROID_KEY_ALIAS" to releaseKeyAlias,
    "ANDROID_KEY_PASSWORD" to releaseKeyPassword,
)
val releaseBuildRequested = gradle.startParameter.taskNames.any { task ->
    task.contains("Release", ignoreCase = true)
}
val missingReleaseSigningVars = releaseSigningVars
    .filterValues { it.isNullOrBlank() }
    .keys

if (releaseBuildRequested && missingReleaseSigningVars.isNotEmpty()) {
    throw GradleException(
        "Release signing is required. Missing environment variables: " +
            missingReleaseSigningVars.joinToString(", "),
    )
}

android {
    namespace = "com.shraddha.shanti"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.shraddha.shanti"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (!releaseKeystorePath.isNullOrBlank()) {
                storeFile = file(releaseKeystorePath)
            }
            storePassword = releaseKeystorePassword
            keyAlias = releaseKeyAlias
            keyPassword = releaseKeyPassword
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
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
