// Top-level build file where you can add configuration options common to all sub-projects/modules.

plugins {
    // Google Services plugin — required for Firebase
    id("com.google.gms.google-services") version "4.4.1" apply false

    // Flutter plugin (required in modern Flutter setups)
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Configure custom build directory (Flutter requirement for new Gradle)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
