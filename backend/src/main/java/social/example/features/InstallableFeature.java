package social.example.features;

import com.rpl.rama.test.InProcessCluster;

public interface InstallableFeature {
  InstalledFeature installOn(InProcessCluster cluster);
}
