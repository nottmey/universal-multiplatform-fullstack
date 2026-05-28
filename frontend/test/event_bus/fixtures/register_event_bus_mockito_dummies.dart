import 'package:frontend/proto/event_bus.pbgrpc.dart';
import 'package:frontend/proto/posts.pb.dart';
import 'package:grpc/grpc.dart';
import 'package:mockito/mockito.dart';

void registerEventBusMockitoDummies() {
  provideDummy<EventBusRequest>(EventBusRequest());
  provideDummy<CallOptions>(CallOptions());
  provideDummy<SubscribeRequest>(
    SubscribeRequest(
      subscription: Subscription(post: SubscribePostRequest(postId: '')),
    ),
  );
  provideDummy<Subscription>(
    Subscription(post: SubscribePostRequest(postId: '')),
  );
  provideDummy<UnsubscribeRequest>(UnsubscribeRequest(subscriptionId: ''));
}
