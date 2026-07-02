package social.example.api;

import io.javalin.openapi.OpenApiRequired;

public record EditPostRequest(@OpenApiRequired String body) {}
