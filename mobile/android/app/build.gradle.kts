import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Assinatura de release lida de um arquivo FORA do repositorio.
//
// O caminho vem de SGSST_KEYSTORE_PROPERTIES (ou ~/.sgsst-keystore/credenciais-keystore.txt).
// Sem o arquivo, o build de release cai na chave de debug, para nao quebrar
// quem so quer testar.
val arquivoKeystore = file(
    System.getenv("SGSST_KEYSTORE_PROPERTIES")
        ?: "${System.getProperty("user.home")}/.sgsst-keystore/credenciais-keystore.txt"
)
val propsKeystore = Properties().apply {
    if (arquivoKeystore.exists()) {
        FileInputStream(arquivoKeystore).use { load(it) }
    }
}
val jks = file(
    System.getenv("SGSST_KEYSTORE_FILE")
        ?: "${System.getProperty("user.home")}/.sgsst-keystore/sgsst-release.jks"
)
val temAssinatura = jks.exists() && !propsKeystore.getProperty("SGSST_KEYSTORE_PASSWORD").isNullOrBlank()

android {
    namespace = "br.com.senac.sgsst.app_sgsst"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "br.com.senac.sgsst.app_sgsst"
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

    signingConfigs {
        if (temAssinatura) {
            create("release") {
                storeFile = jks
                storePassword = propsKeystore.getProperty("SGSST_KEYSTORE_PASSWORD")
                keyAlias = propsKeystore.getProperty("SGSST_KEY_ALIAS") ?: "sgsst"
                keyPassword = propsKeystore.getProperty("SGSST_KEYSTORE_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (temAssinatura) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
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
