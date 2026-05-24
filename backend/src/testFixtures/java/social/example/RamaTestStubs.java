package social.example;

import com.rpl.rama.Depot;
import com.rpl.rama.PState;
import java.lang.reflect.InvocationHandler;
import java.lang.reflect.Method;
import java.lang.reflect.Proxy;
import java.util.concurrent.CompletableFuture;

public final class RamaTestStubs {
  private RamaTestStubs() {}

  public static Depot throwingDepot() {
    return proxy(Depot.class, RamaTestStubs::handleDepotInvocation);
  }

  public static PState emptyPState() {
    return proxy(PState.class, RamaTestStubs::handlePStateInvocation);
  }

  @SuppressWarnings("unchecked")
  private static <T> T proxy(final Class<T> type, final InvocationHandler handler) {
    return (T) Proxy.newProxyInstance(type.getClassLoader(), new Class<?>[] {type}, handler);
  }

  private static Object handleDepotInvocation(
      final Object proxy, final Method method, final Object[] arguments) {
    return switch (method.getName()) {
      case "append", "appendAsync" ->
          throw new AssertionError("depot append not expected in input validation test");
      default -> nullOrCompletedFuture(method.getReturnType());
    };
  }

  private static Object handlePStateInvocation(
      final Object proxy, final Method method, final Object[] arguments) {
    return nullOrCompletedFuture(method.getReturnType());
  }

  @SuppressWarnings("FutureReturnValueIgnored")
  private static Object nullOrCompletedFuture(final Class<?> returnType) {
    if (CompletableFuture.class.isAssignableFrom(returnType)) {
      return CompletableFuture.completedFuture(null);
    }
    return null;
  }
}
