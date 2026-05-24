package social.example.logging;

import com.linecorp.armeria.common.logging.LogWriter;
import com.linecorp.armeria.common.logging.RequestLog;
import com.linecorp.armeria.common.logging.RequestOnlyLog;
import lombok.extern.log4j.Log4j2;
import lombok.val;

@Log4j2
public class HttpLogging implements LogWriter {
  private static String shortPath(final String path) {
    return path.replace(".grpc.", ".").replace("social.example.", "");
  }

  @Override
  public void logRequest(final RequestOnlyLog request) {
    val headers = request.requestHeaders();
    val shortPath = shortPath(headers.path());
    log.debug("->     {} {}", headers.method(), shortPath);
  }

  @Override
  public void logResponse(final RequestLog requestLog) {
    val headers = requestLog.requestHeaders();
    val status = requestLog.responseStatus();
    val shortPath = shortPath(headers.path());
    if (status.isSuccess()) {
      log.debug("<- {} {} {}", status.code(), headers.method(), shortPath);
    } else {
      log.warn("<- {} {} {}", status.code(), headers.method(), shortPath);
    }
  }
}
