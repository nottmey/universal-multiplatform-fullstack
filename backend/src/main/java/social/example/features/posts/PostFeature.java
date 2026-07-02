package social.example.features.posts;

import com.rpl.rama.test.InProcessCluster;
import com.rpl.rama.test.LaunchConfig;
import java.util.List;
import lombok.val;
import social.example.features.InstallableFeature;
import social.example.features.InstalledFeature;

public class PostFeature implements InstallableFeature {
  @Override
  public InstalledFeature installOn(final InProcessCluster cluster) {
    cluster.launchModule(new PostsModule(), new LaunchConfig(1, 1));
    val postsDepot = cluster.clusterDepot(PostsModule.NAME, PostsModule.POSTS_DEPOT);
    val postsPState = cluster.clusterPState(PostsModule.NAME, PostsModule.POSTS_PSTATE);
    val postController = new PostController(postsDepot, postsPState);
    return new InstalledFeature(
        List.of(postController::registerRoutes), List.of(new PostSubscription(postsPState)));
  }
}
