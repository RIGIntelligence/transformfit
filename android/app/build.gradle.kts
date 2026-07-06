import java.util.Properties

val releaseKeystoreProperties = Properties()
val releaseKeystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseSigning = releaseKeystorePropertiesFile.exists()
if (hasReleaseSigning) {
    releaseKeystorePropertiesFile.inputStream().use { releaseKeystoreProperties.load(it) }
}

fun releaseKeystoreValue(key: String): String =
    releaseKeystoreProperties.getProperty(key)
        ?: error("Missing '$key' in android/key.properties")

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.rigintelligence.transformfitai"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.rigintelligence.transformfitai"
        // Health Connect / wearable integration requires API 26+ through the
        // Flutter health plugin.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseSigning) {
                keyAlias = releaseKeystoreValue("keyAlias")
                keyPassword = releaseKeystoreValue("keyPassword")
                storeFile = rootProject.file(releaseKeystoreValue("storeFile"))
                storePassword = releaseKeystoreValue("storePassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
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
