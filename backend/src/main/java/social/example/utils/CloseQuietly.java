package social.example.utils;

import lombok.extern.log4j.Log4j2;

@Log4j2
public class CloseQuietly {
  private CloseQuietly() {}

  public static void close(final AutoCloseable closeable) {
    if (closeable == null) {
      return;
    }
    try {
      closeable.close();
    } catch (final Exception e) {
      log.warn("failed to close resource", e);
    }
  }
}
