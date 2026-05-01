plugins {
    id("com.android.application") version "8.9.1" apply false
    id("com.android.library") version "8.9.1" apply false
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.camera:camera-core:1.3.4")
            force("androidx.camera:camera-camera2:1.3.4")
            force("androidx.camera:camera-lifecycle:1.3.4")
            force("androidx.camera:camera-video:1.3.4")
            force("androidx.camera:camera-view:1.3.4")
            force("androidx.camera:camera-extensions:1.3.4")
            force("androidx.camera.featurecombinationquery:featurecombinationquery:1.3.4")

            force("androidx.activity:activity:1.8.2")
            force("androidx.activity:activity-ktx:1.8.2")
        }
    }
}
