package social.example.api;

import io.javalin.openapi.OpenApiRequired;

public record Post(
    @OpenApiRequired String postId, @OpenApiRequired String body, long postedAtMillis) {}
