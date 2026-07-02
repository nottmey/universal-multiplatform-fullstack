package social.example.api;

import io.javalin.openapi.OpenApiRequired;
import java.util.List;

public record TimelineEvent(@OpenApiRequired List<String> postIds) {}
