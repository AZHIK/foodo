/// API base URL configuration.
///
/// Values are loaded from environment ([flutter_dotenv]) with sensible
/// fallbacks for local development against the docker-compose'd services.
/// In CI/CD, override via `--dart-define` compile-time variables.
abstract final class ApiEndpoints {
  ApiEndpoints._();

  static const String identityBase = 'http://10.0.2.2:8000';
  static const String inventoryBase = 'http://10.0.2.2:8100';
  static const String posBase = 'http://10.0.2.2:8200';

  // ── Health endpoints ─────────────────────────────────────────
  static const String identityHealth = '/health';
  static const String inventoryHealth = '/health';
  static const String posHealth = '/health';
}
