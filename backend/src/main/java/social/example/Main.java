package social.example;

import com.linecorp.armeria.common.HttpHeaderNames;
import com.linecorp.armeria.common.HttpMethod;
import com.linecorp.armeria.server.Server;
import com.linecorp.armeria.server.cors.CorsService;
import com.linecorp.armeria.server.grpc.GrpcService;
import com.linecorp.armeria.server.logging.LoggingService;
import com.rpl.rama.test.InProcessCluster;
import io.grpc.BindableService;
import io.grpc.ServerInterceptor;
import io.grpc.protobuf.services.ProtoReflectionServiceV1;
import java.time.Duration;
import java.util.List;
import java.util.stream.Stream;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import lombok.val;
import social.example.auth.FirebaseBootstrap;
import social.example.eventbus.EventBusService;
import social.example.features.FeatureRegistry;
import social.example.features.InstalledFeature;
import social.example.logging.GrpcLogging;
import social.example.logging.HttpLogging;
import social.example.utils.CloseQuietly;

@Log4j2
@RequiredArgsConstructor
public final class Main implements AutoCloseable {
  private static final int DEFAULT_PORT = 8080;

  // visible for testing
  final InProcessCluster cluster;
  final Server server;

  public static Main bootstrap(final String[] args) {
    FirebaseBootstrap.initialize();
    val port = args.length > 0 ? Integer.parseInt(args[0]) : DEFAULT_PORT;
    log.info("starting on port {}", port);
    val cluster = InProcessCluster.create();
    log.info("cluster started");
    val features = FeatureRegistry.installAll(cluster);
    log.info("features installed");
    val server = buildServer(port, FirebaseBootstrap.interceptor(), services(features));
    log.info("server built");
    return new Main(cluster, server);
  }

  public static void main(final String[] args) throws Exception {
    try (val application = bootstrap(args)) {
      Runtime.getRuntime()
          .addShutdownHook(new Thread(application.server::close, "armeria-server-shutdown"));
      application.server.start().join();
      val port = application.server.activeLocalPort();
      log.info("server started, listening on http://127.0.0.1:{}", port);
      application.server.blockUntilShutdown();
    }
  }

  public static List<BindableService> services(final List<InstalledFeature> installedFeatures) {
    return Stream.concat(
            installedFeatures.stream()
                .flatMap(installedFeature -> installedFeature.grpcServices().stream()),
            Stream.of(
                EventBusService.fromSubscriptions(
                    installedFeatures.stream()
                        .flatMap(installedFeature -> installedFeature.subscriptionCases().stream())
                        .toList()),
                ProtoReflectionServiceV1.newInstance()))
        .toList();
  }

  @Override
  public void close() {
    server.close();
    CloseQuietly.close(cluster);
  }

  private static Server buildServer(
      final int port,
      final ServerInterceptor authInterceptor,
      final List<BindableService> bindableServices) {
    return Server.builder()
        .http(port)
        .service(
            GrpcService.builder()
                .intercept(authInterceptor)
                .intercept(new GrpcLogging())
                .addServices(bindableServices)
                .build(),
            CorsService.builderForAnyOrigin()
                .allowRequestMethods(HttpMethod.GET, HttpMethod.POST, HttpMethod.OPTIONS)
                .allowAllRequestHeaders(true)
                .exposeHeaders(
                    HttpHeaderNames.of("grpc-status"),
                    HttpHeaderNames.of("grpc-message"),
                    HttpHeaderNames.CONTENT_TYPE)
                .maxAge(Duration.ofHours(1))
                .newDecorator(),
            LoggingService.builder().logWriter(new HttpLogging()).newDecorator())
        .build();
  }
}
