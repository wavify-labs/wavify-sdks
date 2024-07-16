pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        mavenLocal() {
            url = uri("file://${rootDir}/../kotlin/wavify/lib/build/repo")
        }
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        mavenLocal {
            url = uri("file://${rootDir}/../kotlin/wavify/lib/build/repo")
        }
    }
}

rootProject.name = "Wavify"
include(":app")
