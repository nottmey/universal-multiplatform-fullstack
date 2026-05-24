package social.example.features;

import io.grpc.BindableService;
import java.util.List;
import social.example.eventbus.EventBusSubscription;

public record InstalledFeature(
    List<BindableService> grpcServices, List<EventBusSubscription> subscriptionCases) {}
