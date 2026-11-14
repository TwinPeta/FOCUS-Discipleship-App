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
// Some plugins (file_picker 8.x) still compile against android-34, but
// flutter_plugin_android_lifecycle requires compileSdk 36+. Raise every
// Android library to at least 36. Compile-time only: minSdk and targetSdk
// (which devices can install the app) are unchanged.
val minPluginCompileSdk = 36
subprojects {
    afterEvaluate {
        extensions
            .findByType(com.android.build.gradle.LibraryExtension::class.java)
            ?.let { android ->
                if ((android.compileSdk ?: 0) < minPluginCompileSdk) {
                    android.compileSdk = minPluginCompileSdk
                }
            }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
