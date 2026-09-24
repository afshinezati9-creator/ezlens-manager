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

// Force compileSdk 36 on every Android module (app + plugins like file_picker).
// Do NOT use evaluationDependsOn(":app") — that evaluates early and breaks afterEvaluate.
subprojects {
    afterEvaluate {
        val android = extensions.findByName("android") ?: return@afterEvaluate
        try {
            val setCompileSdk = android.javaClass.methods.find {
                it.name == "setCompileSdk" && it.parameterCount == 1
            }
            if (setCompileSdk != null) {
                setCompileSdk.invoke(android, 36)
            } else {
                android.javaClass.methods.find {
                    it.name == "setCompileSdkVersion" && it.parameterCount == 1
                }?.invoke(android, 36)
            }
        } catch (_: Exception) {
            // non-android modules
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
