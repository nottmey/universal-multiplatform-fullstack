import java.io.File
import net.ltgt.gradle.errorprone.errorprone

fun javaLanguageVersionFromDotfile(projectDirectory: File): JavaLanguageVersion {
    val dotJavaVersion = projectDirectory.resolve(".java-version")
    require(dotJavaVersion.isFile) { "Missing ${dotJavaVersion.path}" }
    return JavaLanguageVersion.of(dotJavaVersion.readText().trim().toInt())
}

group = "social.example"
version = "0.1.0-SNAPSHOT"

plugins {
    java
    jacoco
    `java-test-fixtures`
    checkstyle
    alias(libs.plugins.spotless)
    alias(libs.plugins.errorprone)
}

java {
    toolchain {
        languageVersion.set(javaLanguageVersionFromDotfile(projectDir))
    }
}

val backendJvmArgs =
    listOf(
        "-ea",
        "-Dzookeeper.maxCnxns=200",
        "--enable-native-access=ALL-UNNAMED",
        "--sun-misc-unsafe-memory-access=allow",
    )

val ramaNettyVersion =
    configurations
        .detachedConfiguration(
            dependencies.create(versionCatalogs.named("libs").findLibrary("rama").get().get()),
        )
        .apply { isTransitive = true }
        .resolvedConfiguration.resolvedArtifacts
        .map { it.moduleVersion.id }
        .first { it.group == "io.netty" && it.name == "netty-all" }
        .version

dependencies {
    val nettyBom = enforcedPlatform("io.netty:netty-bom:$ramaNettyVersion")

    compileOnly(libs.lombok)
    annotationProcessor(libs.lombok)
    testCompileOnly(libs.lombok)
    testAnnotationProcessor(libs.lombok)
    testFixturesCompileOnly(libs.lombok)
    testFixturesAnnotationProcessor(libs.lombok)

    errorprone(libs.errorprone.core)
    implementation(nettyBom)
    testImplementation(nettyBom)
    testFixturesImplementation(nettyBom)
    implementation(libs.log4j.api)

    implementation(libs.rama)
    implementation(libs.rama.helpers)
    implementation(libs.jackson.module.scala213)

    implementation(libs.javalin)
    implementation(libs.javalin.openapi.plugin)
    implementation(libs.jackson.databind)
    annotationProcessor(libs.openapi.annotation.processor)
    implementation(libs.firebase.admin)
    runtimeOnly(libs.bundles.logging)

    testFixturesImplementation(libs.javalin)
    testFixturesImplementation(libs.jackson.databind)
    testFixturesImplementation(libs.rama)
    testFixturesImplementation(libs.junit.jupiter)
    testFixturesImplementation(libs.firebase.admin)
    testFixturesImplementation(sourceSets.main.get().output)
    testImplementation(testFixtures(project(":")))
    testImplementation(libs.junit.jupiter)
    testRuntimeOnly(libs.bundles.logging)
    testRuntimeOnly(libs.junit.platform.launcher)
}

// The annotation processor emits paths/components at compile time; info and securitySchemes are
// runtime plugin config in javalin-openapi, so inject them here to keep the committed spec whole.
val exportOpenApi by tasks.registering {
    description = "Exports the compile-time generated OpenAPI spec to the committed spec/ directory."
    dependsOn(tasks.compileJava)
    val generatedSpec =
        sourceSets.main.get().output.classesDirs.asFileTree.matching {
            include("openapi-plugin/openapi-*.json")
        }
    val outputSpec = layout.projectDirectory.file("../spec/openapi.json")
    val specVersion = version.toString()
    inputs.files(generatedSpec)
    outputs.file(outputSpec)
    doLast {
        val specFile = generatedSpec.singleFile
        @Suppress("UNCHECKED_CAST")
        val spec = groovy.json.JsonSlurper().parse(specFile) as MutableMap<String, Any?>
        spec["info"] = mapOf("title" to "Social Example API", "version" to specVersion)
        @Suppress("UNCHECKED_CAST")
        val components =
            spec.getOrPut("components") { mutableMapOf<String, Any?>() } as MutableMap<String, Any?>
        components["securitySchemes"] =
            mapOf("bearerAuth" to mapOf("type" to "http", "scheme" to "bearer", "bearerFormat" to "JWT"))
        outputSpec.asFile.writeText(groovy.json.JsonOutput.prettyPrint(groovy.json.JsonOutput.toJson(spec)) + "\n")
    }
}

configurations.configureEach {
    exclude(group = "ch.qos.logback", module = "logback-classic")
    exclude(group = "ch.qos.logback", module = "logback-core")
    exclude(group = "io.netty", module = "netty-all")
}

tasks.withType<Test>().configureEach {
    useJUnitPlatform()
    jvmArgs(backendJvmArgs)
    // see https://firebase.google.com/docs/emulator-suite/connect_auth#admin_sdks
    environment("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
}

tasks.jacocoTestReport {
    reports {
        html.required.set(false)
        xml.required.set(true)
    }
}

tasks.named<Test>("test") {
    finalizedBy(tasks.jacocoTestReport)
}

checkstyle {
    toolVersion = libs.versions.checkstyle.get()
    configDirectory = layout.projectDirectory.dir("config/checkstyle")
}

tasks.withType<Checkstyle>().configureEach {
    isIgnoreFailures = true
    exclude {
        val normalized =
            it.file.absolutePath.replace(File.separatorChar, '/')
        normalized.contains("/build/generated/")
    }
}

tasks.withType<JavaCompile>().configureEach {
    options.errorprone {
        allErrorsAsWarnings.set(true)
        excludedPaths.set(".*/build/generated/.*")
    }
}

tasks.named("check") { dependsOn(tasks.spotlessCheck) }

tasks.register("format") {
    group = "formatting"
    description = "Apply google-java-format via Spotless (writes Java sources under backend/src)."
    dependsOn(tasks.spotlessApply)
}

spotless {
    java {
        googleJavaFormat(libs.versions.googleJavaFormat.get())
            .reflowLongStrings(true)
            .reorderImports(true)
            .formatJavadoc(true)
        target("src/**/*.java")
    }
}

tasks.register<JavaExec>("runBackend") {
    group = "application"
    description = "Runs local backend, requires auth emulator to be running" 
    mainClass.set("social.example.Main")
    classpath = sourceSets["main"].runtimeClasspath
    args("8080")
    jvmArgs(backendJvmArgs)
    environment("FIREBASE_AUTH_EMULATOR_HOST", "127.0.0.1:9099")
}
