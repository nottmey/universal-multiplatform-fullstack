package social.example.api;

import io.javalin.openapi.OpenApiRequired;

public record CreatePostRequest(@OpenApiRequired String body) {}
