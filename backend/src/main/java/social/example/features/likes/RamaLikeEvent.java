package social.example.features.likes;

import com.rpl.rama.RamaSerializable;

public record RamaLikeEvent(String postId) implements RamaSerializable {}
