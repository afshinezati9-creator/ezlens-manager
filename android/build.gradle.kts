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

// Force compileSdk 36 on plugin modules (file_picker, etc.)
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        try {
            val setCompileSdk = androidExt.javaClass.methods.find {
                it.name == "setCompileSdk" && it.parameterCount == 1
            }
            if (setCompileSdk != null) {
                setCompileSdk.invoke(androidExt, 36)
            } else {
                androidExt.javaClass.methods.find {
                    it.name == "setCompileSdkVersion" && it.parameterCount == 1
                }?.invoke(androidExt, 36)
            }
        } catch (_: Exception) {
            // ignore
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
