package social.example;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import lombok.val;
import social.example.api.CreatePostRequest;
import social.example.api.EditPostRequest;
import social.example.api.Post;
import social.example.api.PostResponse;

public final class ApiTestClient {
  private static final HttpClient HTTP_CLIENT =
      HttpClient.newBuilder().connectTimeout(Duration.ofSeconds(5)).build();

  private final URI baseUri;
  private final String bearerToken;

  public ApiTestClient(final int port, final String bearerToken) {
    this.baseUri = URI.create("http://127.0.0.1:" + port);
    this.bearerToken = bearerToken;
  }

  public Post createPost(final String body) {
    val response = tryCreatePost(body);
    assertEquals(200, response.statusCode(), response::body);
    return readPost(response);
  }

  public Post editPost(final String postId, final String body) {
    val response = tryEditPost(postId, body);
    assertEquals(200, response.statusCode(), response::body);
    return readPost(response);
  }

  public void deletePost(final String postId) {
    val response = tryDeletePost(postId);
    assertEquals(204, response.statusCode(), response::body);
  }

  public HttpResponse<String> tryCreatePost(final String body) {
    return send("POST", "/posts", new CreatePostRequest(body));
  }

  public HttpResponse<String> tryEditPost(final String postId, final String body) {
    return send("PUT", "/posts/" + postId, new EditPostRequest(body));
  }

  public HttpResponse<String> tryDeletePost(final String postId) {
    return send("DELETE", "/posts/" + postId, null);
  }

  public HttpResponse<String> send(final String method, final String path, final Object body) {
    try {
      val bodyPublisher =
          body == null
              ? HttpRequest.BodyPublishers.noBody()
              : HttpRequest.BodyPublishers.ofString(HttpTestSupport.JSON.writeValueAsString(body));
      val request =
          HttpRequest.newBuilder(baseUri.resolve(path))
              .timeout(Duration.ofSeconds(5))
              .header("Content-Type", "application/json")
              .header("Authorization", "Bearer " + bearerToken)
              .method(method, bodyPublisher)
              .build();
      return HTTP_CLIENT.send(request, HttpResponse.BodyHandlers.ofString());
    } catch (final InterruptedException interrupted) {
      Thread.currentThread().interrupt();
      throw new AssertionError("interrupted while calling " + method + " " + path, interrupted);
    } catch (final Exception e) {
      throw new AssertionError("failed calling " + method + " " + path, e);
    }
  }

  private static Post readPost(final HttpResponse<String> response) {
    try {
      return HttpTestSupport.JSON.readValue(response.body(), PostResponse.class).post();
    } catch (final Exception e) {
      throw new AssertionError("unparseable PostResponse body: " + response.body(), e);
    }
  }
}
