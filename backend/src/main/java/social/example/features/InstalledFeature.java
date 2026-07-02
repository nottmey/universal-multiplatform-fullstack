package social.example.features;

import io.javalin.Javalin;
import java.util.List;
import java.util.function.Consumer;
import social.example.eventbus.EventBusSubscription;

public record InstalledFeature(
    List<Consumer<Javalin>> routeRegistrars, List<EventBusSubscription> subscriptionCases) {}
