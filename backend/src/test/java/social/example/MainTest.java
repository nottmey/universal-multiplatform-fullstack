package social.example;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.google.firebase.FirebaseApp;
import com.linecorp.armeria.client.WebClient;
import com.linecorp.armeria.client.grpc.GrpcClients;
import com.linecorp.armeria.common.HttpHeaderNames;
import com.linecorp.armeria.common.HttpMethod;
import com.linecorp.armeria.common.HttpRequest;
import io.grpc.StatusRuntimeException;
import lombok.val;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.Test;
import social.example.auth.FirebaseAuthEmulatorClient;
import social.example.features.posts.grpc.CreatePostRequest;
import social.example.features.posts.grpc.PostServiceGrpc;

class MainTest {
  @AfterEach
  void deleteFirebaseApps() {
    FirebaseApp.getApps().forEach(FirebaseApp::delete);
  }

  @Test
  void bootstrap_devScenarioSmoke() {
    try (val application = Main.bootstrap(new String[] {"0"})) {
      val server = application.server;
      server.start().join();
      val serverUri = "http://127.0.0.1:" + server.activeLocalPort();

      val corsResponse =
          WebClient.of(serverUri)
              .execute(
                  HttpRequest.builder()
                      .method(HttpMethod.OPTIONS)
                      .path("/social.example.features.posts.grpc.PostService/CreatePost")
                      .header(HttpHeaderNames.ORIGIN, "http://localhost:3000")
                      .header(HttpHeaderNames.ACCESS_CONTROL_REQUEST_METHOD, "POST")
                      .build())
              .aggregate()
              .join();
      assertEquals("*", corsResponse.headers().get(HttpHeaderNames.ACCESS_CONTROL_ALLOW_ORIGIN));
      val allowedMethods = corsResponse.headers().get(HttpHeaderNames.ACCESS_CONTROL_ALLOW_METHODS);
      assertTrue(allowedMethods.contains("POST"));
      assertTrue(allowedMethods.contains("OPTIONS"));

      val unauthenticatedStub =
          GrpcClients.newClient(
              "gproto+" + serverUri, PostServiceGrpc.PostServiceBlockingStub.class);
      assertThrows(
          StatusRuntimeException.class,
          () ->
              unauthenticatedStub.createPost(
                  CreatePostRequest.newBuilder().setBody("blocked").build()));

      val idToken =
          FirebaseAuthEmulatorClient.signUpEmailPassword(
              FirebaseAuthEmulatorClient.uniqueEmail(), "password-123456");
      val authenticatedStub =
          GrpcClients.builder("gproto+" + serverUri)
              .addHeader("authorization", "Bearer " + idToken)
              .build(PostServiceGrpc.PostServiceBlockingStub.class);
      val post =
          authenticatedStub
              .createPost(CreatePostRequest.newBuilder().setBody("smoke").build())
              .getPost();
      assertFalse(post.getPostId().isBlank());
      assertEquals("smoke", post.getBody());
    }
  }
}
