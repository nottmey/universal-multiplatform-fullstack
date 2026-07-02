package social.example.api;

import io.javalin.openapi.OpenApiRequired;

public record ApiError(@OpenApiRequired String code, @OpenApiRequired String message) {}
