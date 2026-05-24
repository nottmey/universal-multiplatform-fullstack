package social.example.features.timeline;

import com.rpl.rama.test.InProcessCluster;
import com.rpl.rama.test.LaunchConfig;
import java.util.List;
import lombok.val;
import social.example.features.InstallableFeature;
import social.example.features.InstalledFeature;

public class TimelineFeature implements InstallableFeature {
  @Override
  public InstalledFeature installOn(final InProcessCluster cluster) {
    cluster.launchModule(new TimelineModule(), new LaunchConfig(1, 1));
    val pState = cluster.clusterPState(TimelineModule.NAME, TimelineModule.TIMELINE_PSTATE);
    return new InstalledFeature(List.of(), List.of(new TimelineSubscription(pState)));
  }
}
