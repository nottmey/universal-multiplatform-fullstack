package social.example.api;

import io.javalin.openapi.OpenApiRequired;

public record PostResponse(@OpenApiRequired Post post) {}
