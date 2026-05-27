package social.example.auth;

import static io.grpc.stub.MetadataUtils.newAttachHeadersInterceptor;
import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static social.example.GrpcTestSupport.shutdown;

import io.grpc.Metadata;
import io.grpc.Status;
import io.grpc.StatusRuntimeException;
import io.grpc.inprocess.InProcessChannelBuilder;
import io.grpc.inprocess.InProcessServerBuilder;
import io.grpc.stub.StreamObserver;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;
import lombok.val;
import org.junit.jupiter.api.Test;
import social.example.auth.verifier.RejectingIdTokenVerifier;
import social.example.eventbus.grpc.Event;
import social.example.eventbus.grpc.EventBusRequest;
import social.example.eventbus.grpc.EventBusServiceGrpc;

class FirebaseAuthenticationInterceptorTest {

  @Test
  void interceptCall_rejectsMissingAuthorizationHeader() throws Exception {
    val serverName = InProcessServerBuilder.generateName();
    val server =
        InProcessServerBuilder.forName(serverName)
            .directExecutor()
            .addService(
                new EventBusServiceGrpc.EventBusServiceImplBase() {
                  @Override
                  public void eventBus(
                      final EventBusRequest request, final StreamObserver<Event> responseObserver) {
                    responseObserver.onCompleted();
                  }
                })
            .intercept(new FirebaseAuthenticationInterceptor(new RejectingIdTokenVerifier()))
            .build();
    server.start();
    val channel = InProcessChannelBuilder.forName(serverName).directExecutor().build();
    try {
      val stub = EventBusServiceGrpc.newStub(channel);
      val errorReference = new AtomicReference<Throwable>();
      val completed = new CountDownLatch(1);

      stub.eventBus(
          EventBusRequest.getDefaultInstance(),
          new StreamObserver<Event>() {
            @Override
            public void onNext(final Event event) {}

            @Override
            public void onError(final Throwable throwable) {
              errorReference.set(throwable);
              completed.countDown();
            }

            @Override
            public void onCompleted() {
              completed.countDown();
            }
          });

      assertEquals(true, completed.await(2L, TimeUnit.SECONDS));
      val thrown =
          assertThrows(
              StatusRuntimeException.class,
              () -> {
                throw errorReference.get();
              });
      assertEquals(Status.Code.UNAUTHENTICATED, thrown.getStatus().getCode());
      assertEquals("missing authorization bearer token", thrown.getStatus().getDescription());
    } finally {
      shutdown(channel, server);
    }
  }

  @Test
  void interceptCall_rejectsInvalidBearerToken() throws Exception {
    val serverName = InProcessServerBuilder.generateName();
    val server =
        InProcessServerBuilder.forName(serverName)
            .directExecutor()
            .addService(
                new EventBusServiceGrpc.EventBusServiceImplBase() {
                  @Override
                  public void eventBus(
                      final EventBusRequest request, final StreamObserver<Event> responseObserver) {
                    responseObserver.onCompleted();
                  }
                })
            .intercept(new FirebaseAuthenticationInterceptor(new RejectingIdTokenVerifier()))
            .build();
    server.start();
    val channel = InProcessChannelBuilder.forName(serverName).directExecutor().build();
    try {
      val stub = EventBusServiceGrpc.newStub(channel);
      val metadata = new Metadata();
      metadata.put(
          Metadata.Key.of("authorization", Metadata.ASCII_STRING_MARSHALLER),
          "Bearer not-a-valid-token");
      val errorReference = new AtomicReference<Throwable>();
      val completed = new CountDownLatch(1);

      stub.withInterceptors(newAttachHeadersInterceptor(metadata))
          .eventBus(
              EventBusRequest.getDefaultInstance(),
              new StreamObserver<Event>() {
                @Override
                public void onNext(final Event event) {}

                @Override
                public void onError(final Throwable throwable) {
                  errorReference.set(throwable);
                  completed.countDown();
                }

                @Override
                public void onCompleted() {
                  completed.countDown();
                }
              });

      assertEquals(true, completed.await(2L, TimeUnit.SECONDS));
      val thrown =
          assertThrows(
              StatusRuntimeException.class,
              () -> {
                throw errorReference.get();
              });
      assertEquals(Status.Code.UNAUTHENTICATED, thrown.getStatus().getCode());
      assertEquals("invalid firebase id token", thrown.getStatus().getDescription());
    } finally {
      shutdown(channel, server);
    }
  }
}
