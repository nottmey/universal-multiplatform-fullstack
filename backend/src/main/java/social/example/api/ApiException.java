package social.example.api;

import lombok.Getter;

/** Maps domain failures to HTTP statuses and {@link ApiError} bodies. */
@Getter
public final class ApiException extends RuntimeException {
  private final int status;
  private final String code;

  private ApiException(final int status, final String code, final String message) {
    super(message);
    this.status = status;
    this.code = code;
  }

  public static ApiException invalidArgument(final String message) {
    return new ApiException(400, "INVALID_ARGUMENT", message);
  }

  public static ApiException unauthenticated(final String message) {
    return new ApiException(401, "UNAUTHENTICATED", message);
  }

  public static ApiException notFound(final String message) {
    return new ApiException(404, "NOT_FOUND", message);
  }

  public static ApiException unimplemented(final String message) {
    return new ApiException(501, "UNIMPLEMENTED", message);
  }

  public ApiError toError() {
    return new ApiError(code, getMessage());
  }
}
