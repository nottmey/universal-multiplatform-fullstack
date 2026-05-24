pluginManagement {
    repositories {
        gradlePluginPortal()
        mavenCentral()
    }
}

plugins {
    // auto-download of matching JDK if no matching one is present
    id("org.gradle.toolchains.foojay-resolver-convention") version "1.0.0"
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        mavenCentral()
        maven {
            name = "RedPlanetLabs"
            url = uri("https://nexus.redplanetlabs.com/repository/maven-public-releases")
        }
        maven {
            name = "Clojars"
            url = uri("https://repo.clojars.org/")
        }
    }
}
