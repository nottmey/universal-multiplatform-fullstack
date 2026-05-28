import 'package:grpc/grpc.dart' hide ClientChannel;
// ignore: implementation_imports
import 'package:grpc/src/client/channel.dart' show ClientChannel;
import 'package:mocktail/mocktail.dart';

class MockClientChannel extends Mock implements ClientChannel {
  MockClientChannel.empty() {
    when(() => shutdown()).thenAnswer((_) async {});
    when(() => terminate()).thenAnswer((_) async {});
    when(
      () => onConnectionStateChanged,
    ).thenAnswer((_) => Stream<ConnectionState>.empty());
  }
}
