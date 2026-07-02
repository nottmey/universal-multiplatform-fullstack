package social.example.logging;

import io.javalin.http.Context;
import lombok.extern.log4j.Log4j2;
import lombok.val;

@Log4j2
public final class ApiLogging {
  private ApiLogging() {}

  /** Logs method, path and status only — never the query string, which may carry an id token. */
  public static void logHttp(final Context ctx, final Float executionTimeMs) {
    val status = ctx.statusCode();
    if (status < 400) {
      log.debug("<- {} {} {}", status, ctx.method(), ctx.path());
    } else {
      log.warn("<- {} {} {}", status, ctx.method(), ctx.path());
    }
  }
}
