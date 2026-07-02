package social.example.api;

import io.javalin.openapi.OpenApiRequired;

public record PostSubscriptionRequest(@OpenApiRequired String postId) {}
