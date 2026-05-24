package social.example.features.likes;

import com.rpl.rama.test.InProcessCluster;
import com.rpl.rama.test.LaunchConfig;
import java.util.List;
import lombok.val;
import social.example.features.InstallableFeature;
import social.example.features.InstalledFeature;

public class LikesFeature implements InstallableFeature {
  @Override
  public InstalledFeature installOn(final InProcessCluster cluster) {
    cluster.launchModule(new LikesModule(), new LaunchConfig(1, 1));
    val depot = cluster.clusterDepot(LikesModule.NAME, LikesModule.LIKES_DEPOT);
    val pState = cluster.clusterPState(LikesModule.NAME, LikesModule.LIKES_PSTATE);
    return new InstalledFeature(
        List.of(new LikesService(depot)), List.of(new LikesSubscription(pState)));
  }
}
