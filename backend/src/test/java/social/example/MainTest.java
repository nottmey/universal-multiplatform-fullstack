package social.example;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

import com.linecorp.armeria.client.WebClient;
import com.linecorp.armeria.client.grpc.GrpcClients;
import com.linecorp.armeria.common.HttpHeaderNames;
import com.linecorp.armeria.common.HttpMethod;
import com.linecorp.armeria.common.HttpRequest;
import java.util.List;
import lombok.val;
import org.junit.jupiter.api.Test;
import social.example.features.posts.grpc.CreatePostRequest;
import social.example.features.posts.grpc.PostServiceGrpc;

class MainTest {

  @Test
  void bootstrap_exposesCorsAndServesGrpcOverHttp() {
    try (val application = Main.bootstrap(List.of("0").toArray(String[]::new))) {
      val server = application.server;
      server.start().join();
      val serverUri = "http://127.0.0.1:" + server.activeLocalPort();
      val webClient = WebClient.of(serverUri);

      val corsResponse =
          webClient
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

      val postsStub =
          GrpcClients.newClient(
              "gproto+" + serverUri, PostServiceGrpc.PostServiceBlockingStub.class);
      val post =
          postsStub.createPost(CreatePostRequest.newBuilder().setBody("smoke").build()).getPost();
      assertFalse(post.getPostId().isBlank());
      assertEquals("smoke", post.getBody());
    }
  }
}
