plugins {
    // Adiciona o plugin do Google Services que o Firebase exige
    id("com.google.gms.google-services") version "4.4.1" apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
        // Fallback sutil para plugins legados que ainda pedem jcenter
        maven { url = uri("https://maven.aliyun.com/repository/public") }
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

// Força o SDK 36 em todos os subprojetos (plugins) usando reflexão para evitar erros de tipo no Kotlin
subprojects {
    afterEvaluate {
        if (project.hasProperty("android")) {
            val androidExtension = project.extensions.findByName("android")
            try {
                // Busca o método compileSdkVersion dinamicamente para não travar a compilação do script
                val method = androidExtension?.javaClass?.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                method?.invoke(androidExtension, 36)
            } catch (e: Exception) {
                // Caso o plugin não suporte, ele ignora silenciosamente
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}