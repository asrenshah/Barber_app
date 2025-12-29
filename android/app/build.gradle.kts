import org.gradle.internal.os.OperatingSystem

plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    id "com.google.gms.google-services"
}

def localProperties = new Properties()
def localPropertiesFile = rootProject.file('local.properties')
if (localPropertiesFile.exists()) {
    localPropertiesFile.withReader('UTF-8') { reader ->
        localProperties.load(reader)
    }
}

def flutterVersionCode = localProperties.getProperty('flutter.versionCode')
if (flutterVersionCode == null) {
    flutterVersionCode = '1'
}

def flutterVersionName = localProperties.getProperty('flutter.versionName')
if (flutterVersionName == null) {
    flutterVersionName = '1.0'
}

android {
    namespace "com.example.barber_app"
    compileSdkVersion flutter.compileSdkVersion
    ndkVersion flutter.ndkVersion

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = '17'
    }

    sourceSets {
        main.java.srcDirs += 'src/main/kotlin'
    }

    defaultConfig {
        applicationId "com.example.barber_app"
        // MIN SDK 21 untuk support local_auth dan Firebase
        minSdkVersion 21
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
        
        // MULTIDEX SUPPORT (untuk Firebase)
        multiDexEnabled true
        
        // MANIFEST PLACEHOLDERS untuk Google Maps
        manifestPlaceholders += [
            MAPS_API_KEY: localProperties.getProperty('MAPS_API_KEY', '')
        ]
    }

    buildTypes {
        debug {
            // DEBUG: Allow cleartext traffic untuk development
            manifestPlaceholders += [
                usesCleartextTraffic: "true"
            ]
            signingConfig signingConfigs.debug
        }
        release {
            // RELEASE: No cleartext traffic
            manifestPlaceholders += [
                usesCleartextTraffic: "false"
            ]
            signingConfig signingConfigs.debug
            
            // Enable code shrinking, obfuscation, and optimization
            minifyEnabled true
            shrinkResources true
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    // FLAVOR DIMENSIONS (optional untuk future)
    flavorDimensions "default"
    productFlavors {
        dev {
            dimension "default"
            applicationIdSuffix ".dev"
            versionNameSuffix "-dev"
            resValue "string", "app_name", "Barber App Dev"
        }
        prod {
            dimension "default"
            resValue "string", "app_name", "Barber App"
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    // MULTIDEX SUPPORT (wajib untuk Firebase)
    implementation 'androidx.multidex:multidex:2.0.1'
    
    // BIOMETRIC SUPPORT
    implementation 'androidx.biometric:biometric:1.1.0'
    
    // FIREBASE CORE
    implementation platform('com.google.firebase:firebase-bom:32.7.0')
    implementation 'com.google.firebase:firebase-analytics'
    
    // ANDROX CORE (untuk compatibility)
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
}

// TASK UNTUK CLEAN BUILD
task cleanBuild(type: Delete) {
    delete rootProject.buildDir
}