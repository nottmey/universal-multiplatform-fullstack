package social.example.logging;

import com.google.protobuf.MessageOrBuilder;
import com.google.protobuf.TextFormat;
import io.grpc.ForwardingServerCall;
import io.grpc.ForwardingServerCallListener;
import io.grpc.Metadata;
import io.grpc.ServerCall;
import io.grpc.ServerCallHandler;
import io.grpc.ServerInterceptor;
import lombok.extern.log4j.Log4j2;
import lombok.val;

@Log4j2
public class GrpcLogging implements ServerInterceptor {
  private static String payloadToCompactLine(final Object payload) {
    if (payload instanceof MessageOrBuilder messageOrBuilder) {
      return TextFormat.printer().emittingSingleLine(true).printToString(messageOrBuilder);
    }
    return String.valueOf(payload);
  }

  @Override
  public <ReqT, RespT> ServerCall.Listener<ReqT> interceptCall(
      final ServerCall<ReqT, RespT> call,
      final Metadata headers,
      final ServerCallHandler<ReqT, RespT> next) {
    val method = call.getMethodDescriptor().getBareMethodName();
    val loggingCall =
        new ForwardingServerCall.SimpleForwardingServerCall<ReqT, RespT>(call) {
          @Override
          public void sendMessage(final RespT message) {
            log.debug("<- {} {}", method, payloadToCompactLine(message));
            super.sendMessage(message);
          }
        };
    val listener = next.startCall(loggingCall, headers);
    return new ForwardingServerCallListener.SimpleForwardingServerCallListener<ReqT>(listener) {
      @Override
      public void onMessage(final ReqT message) {
        log.debug("-> {} {}", method, payloadToCompactLine(message));
        super.onMessage(message);
      }
    };
  }
}
