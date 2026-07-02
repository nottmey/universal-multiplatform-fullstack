package social.example.features.posts;

import com.rpl.rama.AckLevel;
import com.rpl.rama.Depot;
import com.rpl.rama.PState;
import com.rpl.rama.Path;
import io.javalin.Javalin;
import io.javalin.http.Context;
import io.javalin.openapi.HttpMethod;
import io.javalin.openapi.OpenApi;
import io.javalin.openapi.OpenApiContent;
import io.javalin.openapi.OpenApiParam;
import io.javalin.openapi.OpenApiRequestBody;
import io.javalin.openapi.OpenApiResponse;
import io.javalin.openapi.OpenApiSecurity;
import java.util.Optional;
import java.util.UUID;
import lombok.RequiredArgsConstructor;
import lombok.val;
import social.example.api.ApiError;
import social.example.api.ApiException;
import social.example.api.CreatePostRequest;
import social.example.api.EditPostRequest;
import social.example.api.PostResponse;

@RequiredArgsConstructor
public class PostController {
  private final Depot postsDepot;
  private final PState postsPState;

  public void registerRoutes(final Javalin app) {
    app.post("/posts", this::createPost);
    app.put("/posts/{postId}", this::editPost);
    app.delete("/posts/{postId}", this::deletePost);
  }

  @OpenApi(
      path = "/posts",
      methods = HttpMethod.POST,
      operationId = "createPost",
      summary = "Create a post",
      tags = "posts",
      security = @OpenApiSecurity(name = "bearerAuth"),
      requestBody =
          @OpenApiRequestBody(
              required = true,
              content = @OpenApiContent(from = CreatePostRequest.class)),
      responses = {
        @OpenApiResponse(status = "200", content = @OpenApiContent(from = PostResponse.class)),
        @OpenApiResponse(status = "400", content = @OpenApiContent(from = ApiError.class)),
        @OpenApiResponse(status = "401", content = @OpenApiContent(from = ApiError.class)),
        @OpenApiResponse(status = "500", content = @OpenApiContent(from = ApiError.class))
      })
  private void createPost(final Context ctx) {
    val request = ctx.bodyAsClass(CreatePostRequest.class);
    val body = request.body();
    if (body == null || body.isBlank()) {
      throw ApiException.invalidArgument("body is required");
    }
    val ack =
        postsDepot.append(
            new RamaPostEvent(
                UUID.randomUUID().toString(), body, System.currentTimeMillis(), false),
            AckLevel.ACK);
    val created = (RamaPostEvent) ack.get(PostsModule.POSTS_STREAM);
    ctx.json(new PostResponse(created.toApi()));
  }

  @OpenApi(
      path = "/posts/{postId}",
      methods = HttpMethod.PUT,
      operationId = "editPost",
      summary = "Replace the body of a post",
      tags = "posts",
      security = @OpenApiSecurity(name = "bearerAuth"),
      pathParams = @OpenApiParam(name = "postId", required = true, type = String.class),
      requestBody =
          @OpenApiRequestBody(
              required = true,
              content = @OpenApiContent(from = EditPostRequest.class)),
      responses = {
        @OpenApiResponse(status = "200", content = @OpenApiContent(from = PostResponse.class)),
        @OpenApiResponse(status = "400", content = @OpenApiContent(from = ApiError.class)),
        @OpenApiResponse(status = "401", content = @OpenApiContent(from = ApiError.class)),
        @OpenApiResponse(status = "404", content = @OpenApiContent(from = ApiError.class)),
        @OpenApiResponse(status = "500", content = @OpenApiContent(from = ApiError.class))
      })
  private void editPost(final Context ctx) {
    val postId = ctx.pathParam("postId");
    val request = ctx.bodyAsClass(EditPostRequest.class);
    val body = request.body();
    if (body == null || body.isBlank()) {
      throw ApiException.invalidArgument("body is required");
    }
    if (findPostView(postId).isEmpty()) {
      throw ApiException.notFound("post not found");
    }
    val ack =
        postsDepot.append(
            new RamaPostEvent(postId, body, System.currentTimeMillis(), false), AckLevel.ACK);
    val updated = (RamaPostEvent) ack.get(PostsModule.POSTS_STREAM);
    ctx.json(new PostResponse(updated.toApi()));
  }

  @OpenApi(
      path = "/posts/{postId}",
      methods = HttpMethod.DELETE,
      operationId = "deletePost",
      summary = "Delete a post",
      tags = "posts",
      security = @OpenApiSecurity(name = "bearerAuth"),
      pathParams = @OpenApiParam(name = "postId", required = true, type = String.class),
      responses = {
        @OpenApiResponse(status = "204"),
        @OpenApiResponse(status = "400", content = @OpenApiContent(from = ApiError.class)),
        @OpenApiResponse(status = "401", content = @OpenApiContent(from = ApiError.class)),
        @OpenApiResponse(status = "404", content = @OpenApiContent(from = ApiError.class)),
        @OpenApiResponse(status = "500", content = @OpenApiContent(from = ApiError.class))
      })
  private void deletePost(final Context ctx) {
    val postId = ctx.pathParam("postId");
    if (findPostView(postId).isEmpty()) {
      throw ApiException.notFound("post not found");
    }
    postsDepot.append(
        new RamaPostEvent(postId, "", System.currentTimeMillis(), true), AckLevel.ACK);
    ctx.status(204);
  }

  private Optional<RamaPostView> findPostView(final String postId) {
    val view = (RamaPostView) postsPState.selectOne(Path.key(postId));
    return Optional.ofNullable(view);
  }
}
