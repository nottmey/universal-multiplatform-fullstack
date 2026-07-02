package social.example.api;

import com.fasterxml.jackson.annotation.JsonInclude;

/** Payload for a post subscription update; {@code post} is absent when the post was deleted. */
@JsonInclude(JsonInclude.Include.NON_NULL)
public record PostEvent(Post post) {}
