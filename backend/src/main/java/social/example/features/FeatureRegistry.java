package social.example.features;

import com.rpl.rama.test.InProcessCluster;
import java.util.List;
import social.example.features.likes.LikesFeature;
import social.example.features.posts.PostFeature;
import social.example.features.timeline.TimelineFeature;

public final class FeatureRegistry {
  private static final List<InstallableFeature> FEATURES =
      List.of(new PostFeature(), new TimelineFeature(), new LikesFeature());

  private FeatureRegistry() {}

  public static List<InstalledFeature> installAll(final InProcessCluster cluster) {
    return FEATURES.stream()
        .map(installableFeature -> installableFeature.installOn(cluster))
        .toList();
  }
}
