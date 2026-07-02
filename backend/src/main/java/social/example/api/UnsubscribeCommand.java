package social.example.api;

import io.javalin.openapi.OpenApiRequired;

public record UnsubscribeCommand(@OpenApiRequired String subscriptionId) {}
