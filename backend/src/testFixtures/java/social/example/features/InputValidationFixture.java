package social.example.features;

import static social.example.GrpcTestSupport.shutdown;

import io.grpc.BindableService;
import io.grpc.ManagedChannel;
import io.grpc.Server;
import io.grpc.inprocess.InProcessChannelBuilder;
import io.grpc.inprocess.InProcessServerBuilder;
import java.util.function.Function;
import lombok.RequiredArgsConstructor;
import lombok.val;
import org.junit.jupiter.api.extension.AfterEachCallback;
import org.junit.jupiter.api.extension.BeforeEachCallback;
import org.junit.jupiter.api.extension.ExtensionContext;

// assume fixture is only used in tests and always mounted correctly
@RequiredArgsConstructor
public class InputValidationFixture implements BeforeEachCallback, AfterEachCallback {
  private final BindableService service;
  private Server server;
  private ManagedChannel channel;

  public <S> S stub(final Function<ManagedChannel, S> stubFactory) {
    return stubFactory.apply(channel);
  }

  @Override
  public void beforeEach(final ExtensionContext extensionContext) throws Exception {
    val serverName = InProcessServerBuilder.generateName();
    server =
        InProcessServerBuilder.forName(serverName)
            .directExecutor()
            .addService(service)
            .build()
            .start();
    channel = InProcessChannelBuilder.forName(serverName).directExecutor().build();
  }

  @Override
  public void afterEach(final ExtensionContext extensionContext) throws Exception {
    if (channel != null || server != null) {
      shutdown(channel, server);
      channel = null;
      server = null;
    }
  }
}
