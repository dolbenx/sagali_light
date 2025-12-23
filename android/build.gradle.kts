allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    // This listens for any Android plugin being applied to a subproject
    plugins.withType<com.android.build.gradle.api.AndroidBasePlugin>().configureEach {
        // We cast the extension to access the namespace property
        val android = project.extensions.getByType<com.android.build.gradle.BaseExtension>()
        
        // Specifically fix bdk_flutter
        if (project.name == "bdk_flutter") {
            android.namespace = "org.bitcoindevkit.bdk_flutter"
        }
        
        // Optional: Fallback for any other old packages with the same issue
        if (android.namespace == null) {
            android.namespace = "com.example.fallback" 
        }
    }
}
