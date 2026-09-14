import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de signature release, générée localement (voir README > Build de
// l'APK). Le fichier key.properties et le .jks ne sont jamais commités
// (voir .gitignore) — le build release retombe sur la clé debug s'ils
// sont absents, pour que `flutter run --release` continue de fonctionner
// sans configuration sur les machines qui n'ont pas ces secrets.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.aihealthchef.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requis par flutter_local_notifications (rappels de repas).
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aihealthchef.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // minSdk fixé à 30 (au lieu du défaut Flutter) : requis par
        // flutter_gemma_litertlm (libLiteRtLm.so dépend d'appels système
        // Bionic absents sur les versions Android plus anciennes).
        minSdk = 30
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // L'inférence .litertlm (IA locale) n'est prise en charge qu'en
        // arm64-v8a par flutter_gemma_litertlm.
        ndk {
            abiFilters += "arm64-v8a"
        }
    }

    signingConfigs {
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Signe avec la vraie clé release si key.properties est présent,
            // sinon retombe sur la clé debug (ex. CI sans les secrets).
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Requis par flutter_local_notifications (rappels de repas), voir
    // isCoreLibraryDesugaringEnabled ci-dessus.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
