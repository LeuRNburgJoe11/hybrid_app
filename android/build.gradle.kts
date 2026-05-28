import java.io.File

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val java17HomePath = System.getenv("JAVA_HOME_17") ?: System.getenv("JAVA_HOME")
val java17Home = java17HomePath?.let { File(it) }?.takeIf { it.exists() }
if (java17Home != null) {
    gradle.startParameter.javaHome = java17Home
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

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
