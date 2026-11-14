import java.util.Properties

plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.compose)
    alias(libs.plugins.kotlin.serialization)
}

// ---- 构建期配置注入（域名等来自 local.properties / 环境变量 / CI，绝不硬编码）----
val localProps = Properties().apply {
    val f = rootProject.file("local.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun conf(key: String, default: String = ""): String =
    (localProps.getProperty(key) ?: System.getenv(key.replace('.', '_').uppercase()) ?: default)

fun envOrProp(prop: String, env: String, default: String = ""): String =
    (localProps.getProperty(prop) ?: System.getenv(env) ?: default)

val apiBaseUrl: String = conf("apiBaseUrl", "https://your-host.example/api")
val apiAllowCleartext: Boolean = conf("apiAllowCleartext", "false").toBoolean()
val androidAppId: String = conf("androidAppId", "com.example.exammobile")
val registrationUrl: String = conf("registrationUrl", "")
val releaseStoreFile: String = envOrProp("releaseStoreFile", "RELEASE_STORE_FILE")
val hasReleaseKeystore: Boolean = releaseStoreFile.isNotBlank()

android {
    namespace = "com.example.exammobile"
    compileSdk = 34

    defaultConfig {
        applicationId = androidAppId
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0.0"
        vectorDrawables { useSupportLibrary = true }
        buildConfigField("String", "API_BASE_URL", "\"$apiBaseUrl\"")
        buildConfigField("boolean", "API_ALLOW_CLEARTEXT", "$apiAllowCleartext")
        buildConfigField("String", "CLIENT_TYPE", "\"ANDROID\"")
        buildConfigField("String", "REGISTRATION_URL", "\"$registrationUrl\"")
    }

    signingConfigs {
        getByName("debug") {}
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = file(releaseStoreFile)
                storePassword = envOrProp("releaseStorePassword", "RELEASE_STORE_PASSWORD")
                keyAlias = envOrProp("releaseKeyAlias", "RELEASE_KEY_ALIAS")
                keyPassword = envOrProp("releaseKeyPassword", "RELEASE_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        debug {
            isMinifyEnabled = false
            buildConfigField("boolean", "ENABLE_LOG", "true")
        }
        release {
            isMinifyEnabled = true
            isShrinkResources = true
            isDebuggable = false
            signingConfig = signingConfigs.getByName(if (hasReleaseKeystore) "release" else "debug")
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            buildConfigField("boolean", "ENABLE_LOG", "false")
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }

    buildFeatures {
        compose = true
        buildConfig = true
    }
    packaging { resources.excludes += "/META-INF/{AL2.0,LGPL2.1}" }
}

dependencies {
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.lifecycle.runtime.compose)
    implementation(libs.androidx.activity.compose)
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.ui)
    implementation(libs.androidx.ui.graphics)
    implementation(libs.androidx.material3)
    implementation(libs.androidx.material.icons.core)
    implementation(libs.androidx.navigation.compose)
    implementation(libs.kotlinx.coroutines.android)
    implementation(libs.kotlinx.serialization.json)
    implementation(libs.androidx.security.crypto)
    implementation(libs.okhttp)
    implementation(libs.okhttp.logging)
    implementation(libs.coil.compose)
    debugImplementation(libs.androidx.ui.tooling)
}
