import java.io.FileInputStream
import java.util.Properties
import org.gradle.api.GradleException

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystorePropertiesFile = keystorePropertiesFile.exists()
if (hasKeystorePropertiesFile) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

fun resolveSigningValue(propKey: String, envKey: String): String? {
    val fromProp = keystoreProperties.getProperty(propKey)?.trim()
    if (!fromProp.isNullOrEmpty()) return fromProp
    val fromEnv = System.getenv(envKey)?.trim()
    return if (fromEnv.isNullOrEmpty()) null else fromEnv
}

val releaseStoreFilePath = resolveSigningValue("storeFile", "ORUV_KEYSTORE_PATH")
val releaseStorePassword = resolveSigningValue("storePassword", "ORUV_KEYSTORE_PASSWORD")
val releaseKeyAlias = resolveSigningValue("keyAlias", "ORUV_KEY_ALIAS")
val releaseKeyPassword = resolveSigningValue("keyPassword", "ORUV_KEY_PASSWORD")

val hasReleaseSigning = !releaseStoreFilePath.isNullOrEmpty() &&
    !releaseStorePassword.isNullOrEmpty() &&
    !releaseKeyAlias.isNullOrEmpty() &&
    !releaseKeyPassword.isNullOrEmpty()

android {
    namespace = "app.iftekarhossain.oruv"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFilePath!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
            }
        }
    }

    defaultConfig {
        applicationId = "app.iftekarhossain.oruv"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Fail closed rather than falling back to debug signing when release
            // credentials are absent.
            signingConfig = signingConfigs.findByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

gradle.taskGraph.whenReady {
    val buildingRelease = allTasks.any { task ->
        task.name.contains("Release", ignoreCase = false)
    }
    if (buildingRelease && !hasReleaseSigning) {
        throw GradleException(
            "Android release builds require signing credentials in android/key.properties " +
                "or ORUV_KEYSTORE_PATH / ORUV_KEYSTORE_PASSWORD / ORUV_KEY_ALIAS / ORUV_KEY_PASSWORD."
        )
    }
}

flutter {
    source = "../.."
}
