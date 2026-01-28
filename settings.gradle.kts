pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "my_app"
include(":app")

// This settings file was created by the Flutter tool
// to accommodate Flutter's build system.
// Include any additional generated files in the future.
include(":flutter_module_registrant")