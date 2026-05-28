sealed class RecordingLifecycleEvent {}

final class OpenedBus extends RecordingLifecycleEvent {}

final class Subscribed extends RecordingLifecycleEvent {}

final class Unsubscribed extends RecordingLifecycleEvent {}

final class ClosedBus extends RecordingLifecycleEvent {}
