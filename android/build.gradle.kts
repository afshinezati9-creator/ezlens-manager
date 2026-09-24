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

// Force every Android library/app module (including plugins) to compileSdk 36
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android")
        if (androidExt != null) {
            try {
                val method = androidExt.javaClass.methods.find { it.name == "setCompileSdkVersion" && it.parameterCount == 1 }
                if (method != null) {
                    method.invoke(androidExt, 36)
                } else {
                    // AGP 8+/9 property style
                    val compileSdkField = androidExt.javaClass.methods.find { it.name == "setCompileSdk" && it.parameterCount == 1 }
                    compileSdkField?.invoke(androidExt, 36)
                }
            } catch (_: Exception) {
                // ignore modules without standard android extension
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
