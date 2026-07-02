package social.example.features;

import io.javalin.Javalin;
import java.util.List;
import java.util.function.Consumer;
import lombok.RequiredArgsConstructor;
import org.junit.jupiter.api.extension.AfterEachCallback;
import org.junit.jupiter.api.extension.BeforeEachCallback;
import org.junit.jupiter.api.extension.ExtensionContext;
import social.example.ApiTestClient;
import social.example.HttpTestSupport;
import social.example.Main;
import social.example.auth.verifier.AcceptingIdTokenVerifier;

// assume fixture is only used in tests and always mounted correctly
@RequiredArgsConstructor
public class InputValidationFixture implements BeforeEachCallback, AfterEachCallback {
  private final Consumer<Javalin> routeRegistrar;
  private Javalin app;
  private ApiTestClient api;

  public ApiTestClient api() {
    return api;
  }

  @Override
  public void beforeEach(final ExtensionContext extensionContext) throws Exception {
    app =
        Main.buildApp(
                new AcceptingIdTokenVerifier(),
                List.of(new InstalledFeature(List.of(routeRegistrar), List.of())))
            .start(0);
    api = new ApiTestClient(app.port(), HttpTestSupport.TEST_USER_ID);
  }

  @Override
  public void afterEach(final ExtensionContext extensionContext) throws Exception {
    if (app != null) {
      app.stop();
      app = null;
    }
    api = null;
  }
}
