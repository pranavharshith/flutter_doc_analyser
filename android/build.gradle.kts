allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Default Flutter layout: outputs under project build/ so `flutter run` can
// find app-debug.apk. (The old LOCALAPPDATA redirect was for OneDrive locks;
// this tree is on D:\vortex and does not need that.)
val newBuildDir = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

allprojects {
    tasks.withType<JavaCompile>().configureEach {
        options.compilerArgs.addAll(
            listOf("-Xlint:-options", "-Xlint:-unchecked", "-Xlint:-deprecation"),
        )
    }
}
