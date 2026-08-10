plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

// The native .so and the generated Kotlin bindings are staged by
// scripts/build-aar.sh before this module is assembled (see the root README).
android {
    namespace = "dev.grouse.roamcore"
    compileSdk = 34

    defaultConfig {
        minSdk = 26
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }
}

// uniffi's Kotlin bindings call the native lib through JNA; the @aar variant
// carries the Android-friendly natives and skips the desktop ones.
dependencies {
    implementation("net.java.dev.jna:jna:5.14.0@aar")
}
