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

// FIX: Безпечне налаштування on_audio_query_android
subprojects {
    val targetProject = this

    // Функція, яка застосовує фікси
    fun applyFixes() {
        if (targetProject.name == "on_audio_query_android") {
            // Виправляємо версію Java в Android розширенні
            targetProject.pluginManager.withPlugin("com.android.library") {
                targetProject.extensions.configure<LibraryExtension> {
                    namespace = "com.lucasferreira.on_audio_query_android"
                    compileOptions {
                        sourceCompatibility = JavaVersion.VERSION_21
                        targetCompatibility = JavaVersion.VERSION_21
                    }
                }
            }

            // Виправляємо версію JVM для Kotlin
            targetProject.tasks.withType<KotlinCompile>().configureEach {
                compilerOptions {
                    jvmTarget.set(JvmTarget.JVM_21)
                }
            }
        }
    }

    // ГОЛОВНЕ: Перевіряємо стан проекту перед тим, як лізти
    if (targetProject.state.executed) {
        applyFixes() // Проект вже готовий, застосовуємо одразу
    } else {
        targetProject.afterEvaluate {
            applyFixes() // Проект ще не готовий, чекаємо
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
