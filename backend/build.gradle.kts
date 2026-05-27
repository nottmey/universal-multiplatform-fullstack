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
    alias(libs.plugins.protobuf)
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
    implementation(libs.protobuf.java)
    implementation(libs.javax.annotation.api)
    implementation(libs.grpc.stub)
    implementation(libs.grpc.protobuf)
    implementation(libs.log4j.api)

    implementation(libs.rama)
    implementation(libs.rama.helpers)
    implementation(libs.jackson.module.scala213)

    implementation(platform(libs.armeria.bom))
    implementation(libs.armeria)
    implementation(libs.armeria.grpc)
    implementation(libs.grpc.services)
    implementation(libs.firebase.admin)
    runtimeOnly(libs.bundles.logging)

    testFixturesImplementation(libs.grpc.stub)
    testFixturesImplementation(libs.grpc.protobuf)
    testFixturesImplementation(libs.rama)
    testFixturesImplementation(libs.junit.jupiter)
    testFixturesImplementation("io.grpc:grpc-inprocess:${libs.versions.grpc.get()}")
    testFixturesImplementation("org.mockito:mockito-core:5.14.2")
    testFixturesImplementation(libs.firebase.admin)
    testFixturesImplementation(sourceSets.main.get().output)
    testImplementation(testFixtures(project(":")))
    testImplementation(libs.junit.jupiter)
    testImplementation("io.grpc:grpc-inprocess:${libs.versions.grpc.get()}")
    testRuntimeOnly(libs.bundles.logging)
    testRuntimeOnly(libs.junit.platform.launcher)
}

protobuf {
    protoc {
        artifact = "com.google.protobuf:protoc:${libs.versions.protoc.get()}"
    }
    plugins {
        create("grpc") {
            artifact = "io.grpc:protoc-gen-grpc-java:${libs.versions.grpc.get()}"
        }
    }
    generateProtoTasks {
        all().configureEach {
            plugins {
                create("grpc")
            }
        }
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
