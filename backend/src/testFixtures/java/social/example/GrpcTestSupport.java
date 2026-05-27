package social.example;

import static io.grpc.stub.MetadataUtils.newAttachHeadersInterceptor;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertInstanceOf;
import static org.junit.jupiter.api.Assertions.assertThrows;

import io.grpc.ManagedChannel;
import io.grpc.Metadata;
import io.grpc.Server;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.stub.AbstractStub;
import java.util.concurrent.TimeUnit;
import lombok.val;
import org.junit.jupiter.api.function.Executable;
import social.example.eventbus.grpc.ConnectionContext;

public final class GrpcTestSupport {
  public static final String TEST_USER_ID = "test-user";
  private static final long SHUTDOWN_TIMEOUT_MILLIS = 200L;
  private static final Metadata.Key<String> AUTHORIZATION_METADATA_KEY =
      Metadata.Key.of("authorization", Metadata.ASCII_STRING_MARSHALLER);

  private GrpcTestSupport() {}

  public static <T> T withTestUserId(final T stub) {
    return withUserId(stub, TEST_USER_ID);
  }

  @SuppressWarnings("unchecked")
  public static <T> T withUserId(final T stub, final String userId) {
    val headers = new Metadata();
    headers.put(AUTHORIZATION_METADATA_KEY, "Bearer " + userId);
    return (T) ((AbstractStub<?>) stub).withInterceptors(newAttachHeadersInterceptor(headers));
  }

  public static ConnectionContext context(final String id, final long epoch) {
    return ConnectionContext.newBuilder().setId(id).setEpoch(epoch).build();
  }

  public static void assertInvalidArgument(final Executable executable, final String description) {
    val thrown = assertThrows(StatusRuntimeException.class, executable);
    assertInvalidArgument(thrown, description);
  }

  public static void assertInvalidArgument(final Throwable throwable, final String description) {
    val thrown = assertInstanceOf(StatusRuntimeException.class, throwable);
    assertEquals(Status.INVALID_ARGUMENT.getCode(), thrown.getStatus().getCode());
    assertEquals(description, thrown.getStatus().getDescription());
  }

  public static void assertNotFound(final Executable executable) {
    val thrown = assertThrows(StatusRuntimeException.class, executable);
    assertEquals(Status.Code.NOT_FOUND, thrown.getStatus().getCode());
  }

  public static void shutdown(final ManagedChannel channel, final Server server) {
    if (channel != null) {
      shutdownChannel(channel);
    }
    if (server != null) {
      shutdownServer(server);
    }
  }

  public static void shutdownChannel(final ManagedChannel channel) {
    if (channel == null) {
      return;
    }
    channel.shutdown();
    awaitTermination(channel::awaitTermination, channel::shutdownNow);
  }

  public static void shutdownServer(final Server server) {
    if (server == null) {
      return;
    }
    server.shutdown();
    awaitTermination(server::awaitTermination, server::shutdownNow);
  }

  private static void awaitTermination(final AwaitTermination graceful, final Runnable forceful) {
    try {
      if (!graceful.await(SHUTDOWN_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS)) {
        forceful.run();
        graceful.await(SHUTDOWN_TIMEOUT_MILLIS, TimeUnit.MILLISECONDS);
      }
    } catch (final InterruptedException interrupted) {
      Thread.currentThread().interrupt();
      forceful.run();
    }
  }

  @FunctionalInterface
  private interface AwaitTermination {
    boolean await(long timeout, TimeUnit unit) throws InterruptedException;
  }
}
