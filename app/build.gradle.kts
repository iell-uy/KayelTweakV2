plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.iyell.kayeltweak"
    compileSdk = 34

    defaultConfig {
        applicationId = "com.iyell.kayeltweak"
        minSdk = 30          // Wireless debugging pairing butuh Android 11+ (API 30)
        targetSdk = 34
        versionCode = 1
        versionName = "3.0.0-max"
    }
    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
    buildFeatures { viewBinding = false }
}

dependencies {
    implementation("androidx.core:core-ktx:1.13.1")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("com.google.android.material:material:1.12.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.8.1")
    // Klien ADB open-source (Apache/MIT) untuk pairing & shell Wireless Debugging.
    // Ini BUKAN root, levelnya sama seperti yang dipakai AxManager/Shizuku: hak shell lewat ADB.
    implementation("com.flyfishxu:kadb:2.1.1")
}
