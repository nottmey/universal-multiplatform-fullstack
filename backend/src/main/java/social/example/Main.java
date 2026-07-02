package social.example;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.rpl.rama.test.InProcessCluster;
import io.javalin.Javalin;
import io.javalin.http.HandlerType;
import io.javalin.http.HttpStatus;
import io.javalin.json.JavalinJackson;
import io.javalin.openapi.plugin.OpenApiPlugin;
import java.util.List;
import lombok.RequiredArgsConstructor;
import lombok.extern.log4j.Log4j2;
import lombok.val;
import social.example.api.ApiError;
import social.example.api.ApiException;
import social.example.auth.FirebaseBootstrap;
import social.example.auth.HttpAuthenticator;
import social.example.auth.verifier.FirebaseIdTokenVerifier;
import social.example.eventbus.EventBusWebSocket;
import social.example.features.FeatureRegistry;
import social.example.features.InstalledFeature;
import social.example.logging.ApiLogging;
import social.example.utils.CloseQuietly;

@Log4j2
@RequiredArgsConstructor
public final class Main implements AutoCloseable {
  private static final int DEFAULT_PORT = 8080;

  // visible for testing
  final InProcessCluster cluster;
  final Javalin app;
  final int port;

  public static Main bootstrap(final String[] args) {
    FirebaseBootstrap.initialize();
    val port = args.length > 0 ? Integer.parseInt(args[0]) : DEFAULT_PORT;
    log.info("starting on port {}", port);
    val cluster = InProcessCluster.create();
    log.info("cluster started");
    val features = FeatureRegistry.installAll(cluster);
    log.info("features installed");
    val app = buildApp(FirebaseBootstrap.verifier(), features);
    log.info("app built");
    return new Main(cluster, app, port);
  }

  public static void main(final String[] args) throws Exception {
    try (val application = bootstrap(args)) {
      Runtime.getRuntime()
          .addShutdownHook(new Thread(application.app::stop, "javalin-server-shutdown"));
      application.app.start(application.port);
      log.info("server started, listening on http://127.0.0.1:{}", application.app.port());
      application.app.jettyServer().server().join();
    }
  }

  public static Javalin buildApp(
      final FirebaseIdTokenVerifier verifier, final List<InstalledFeature> installedFeatures) {
    val json = new ObjectMapper();
    val authenticator = new HttpAuthenticator(verifier);
    val app =
        Javalin.create(
            config -> {
              config.showJavalinBanner = false;
              config.jsonMapper(new JavalinJackson(json, false));
              config.bundledPlugins.enableCors(cors -> cors.addRule(rule -> rule.anyHost()));
              config.registerPlugin(
                  new OpenApiPlugin(openApi -> openApi.withDocumentationPath("/openapi")));
              config.requestLogger.http(ApiLogging::logHttp);
            });
    // CORS preflight requests carry no Authorization header; the CORS plugin answers them.
    app.before(
        "/posts",
        ctx -> {
          if (ctx.method() != HandlerType.OPTIONS) {
            authenticator.authenticateHttp(ctx);
          }
        });
    app.before(
        "/posts/*",
        ctx -> {
          if (ctx.method() != HandlerType.OPTIONS) {
            authenticator.authenticateHttp(ctx);
          }
        });
    app.wsBeforeUpgrade(EventBusWebSocket.PATH, authenticator::authenticateWsUpgrade);
    app.exception(ApiException.class, (e, ctx) -> ctx.status(e.getStatus()).json(e.toError()));
    app.exception(
        Exception.class,
        (e, ctx) -> {
          log.error("unexpected failure", e);
          ctx.status(HttpStatus.INTERNAL_SERVER_ERROR)
              .json(new ApiError("INTERNAL", e.getMessage()));
        });
    installedFeatures.forEach(
        installedFeature -> installedFeature.routeRegistrars().forEach(r -> r.accept(app)));
    EventBusWebSocket.fromSubscriptions(
            installedFeatures.stream()
                .flatMap(installedFeature -> installedFeature.subscriptionCases().stream())
                .toList(),
            json)
        .register(app);
    return app;
  }

  @Override
  public void close() {
    app.stop();
    CloseQuietly.close(cluster);
  }
}
