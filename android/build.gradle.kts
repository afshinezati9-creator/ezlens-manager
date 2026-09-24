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

// Force compileSdk 36 when Android plugin is applied (safe: runs during configuration, not afterEvaluate)
subprojects {
    pluginManager.withPlugin("com.android.library") {
        val android = extensions.getByName("android")
        try {
            android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                .invoke(android, 36)
        } catch (_: Exception) {
            try {
                android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    .invoke(android, 36)
            } catch (_: Exception) {
                // ignore
            }
        }
    }
    pluginManager.withPlugin("com.android.application") {
        val android = extensions.getByName("android")
        try {
            android.javaClass.getMethod("setCompileSdk", Int::class.javaPrimitiveType)
                .invoke(android, 36)
        } catch (_: Exception) {
            try {
                android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    .invoke(android, 36)
            } catch (_: Exception) {
                // ignore
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
