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

// --- file_picker 11.0.3 Android registration fix -------------------------
// file_picker's own android/build.gradle only applies the Kotlin Android
// Gradle plugin when AGP < 9 (it assumes AGP's built-in Kotlin support
// handles compilation on AGP 9+). This project uses AGP 9.1.0, but
// android.builtInKotlin is (correctly) set to false in gradle.properties,
// since enabling true built-in Kotlin requires Flutter 3.47+ and this
// project is on Flutter 3.44.6. With neither mechanism active, file_picker's
// Kotlin sources (FilePickerPlugin.kt) never get compiled, so the
// auto-generated GeneratedPluginRegistrant.java fails with
// "cannot find symbol: class FilePickerPlugin".
//
// Fix: force-apply the Kotlin Android plugin (already declared with a
// version in settings.gradle.kts) to file_picker's native module only, so
// it compiles under this project's current AGP/Flutter combination. This
// does not affect any other module, dependency, or Career Matrix feature.
subprojects {
    if (project.name == "file_picker") {
        project.pluginManager.withPlugin("com.android.library") {
            project.pluginManager.apply("org.jetbrains.kotlin.android")
        }
    }
}
subprojects {
    if (project.name == "file_picker") {
        project.tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
