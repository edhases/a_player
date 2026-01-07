import com.android.build.gradle.LibraryExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// FIX: Безпечне налаштування для застарілих плагінів
subprojects {
    val targetProject = this

    fun applyFixes() {
        if (targetProject.name == "on_audio_query_android" || targetProject.name == "equalizer_flutter") {
            val ns = if (targetProject.name == "on_audio_query_android") 
                "com.lucasferreira.on_audio_query_android" 
            else 
                "com.equalizer.flutter.equalizer_flutter"

            targetProject.pluginManager.withPlugin("com.android.library") {
                targetProject.extensions.configure<LibraryExtension> {
                    namespace = ns
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_17
                        targetCompatibility = JavaVersion.VERSION_17
                    }
                }
            }

            // Виправляємо версію JVM для Kotlin
            targetProject.tasks.withType<KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(JvmTarget.JVM_17)
                }
            }

            // ПАТЧ: Видаляємо 'package' з AndroidManifest.xml, бо AGP 8.0+ свариться
            targetProject.afterEvaluate {
                val manifestFile = file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    val content = manifestFile.readText()
                    if (content.contains("package=")) {
                        val newContent = content.replace(Regex("package=\"[^\"]*\""), "")
                        manifestFile.writeText(newContent)
                    }
                }
            }
        }
    }

    if (targetProject.state.executed) {
        applyFixes()
    } else {
        targetProject.afterEvaluate {
            applyFixes()
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
