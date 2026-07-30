/// Typed exception classes for network-layer failures.
///
/// These are intentionally lightweight — no stack traces are captured
/// for expected error paths.  The [Failure] sealed class in
/// `core/error/failure.dart` maps these into the app-wide error model.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode, this.responseBody});
  final String message;
  final int? statusCode;
  final dynamic responseBody;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class NetworkConnectionException extends ApiException {
  const NetworkConnectionException([super.message = 'No internet connection']);
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException([super.message = 'Unauthorized', super.statusCode = 401]);
}

class ServerErrorException extends ApiException {
  const ServerErrorException([
    super.message = 'Internal server error',
    super.statusCode = 500,
  ]);
}

class TimeoutException extends ApiException {
  const TimeoutException([super.message = 'Request timed out']);
}
