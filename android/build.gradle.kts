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

val dipiNdkVersion: String =
    (project.findProperty("dipiNdkVersion") as String?).orEmpty().trim()

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Every Android module (plugins included) is pinned to the NDK revision from
    // android/gradle.properties. Without this, plugin modules fall back to the
    // Flutter SDK default NDK, which may not be installed on this machine.
    if (dipiNdkVersion.isNotEmpty()) {
        afterEvaluate {
            val androidExtension = extensions.findByName("android")
            if (androidExtension != null) {
                val setter = androidExtension.javaClass.methods.firstOrNull { method ->
                    method.name == "setNdkVersion" &&
                        method.parameterCount == 1 &&
                        method.parameterTypes[0] == String::class.java
                }
                setter?.invoke(androidExtension, dipiNdkVersion)
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
