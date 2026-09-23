/// Backend base URLs, centralized so they aren't duplicated (and drift)
/// across every Dio provider.
///
/// Local dev only for now — these mirror the host ports each service's
/// `docker-compose.yml` publishes. When per-environment (staging/prod)
/// endpoints are needed, this is the one place to switch to `--dart-define`
/// or a build-time config, without touching call sites.
abstract final class ApiConfig {
  static const identityServiceBaseUrl = 'http://10.65.203.68:8009/api/v1';
  static const inventoryServiceBaseUrl = 'http://10.65.203.68:8100/api/v1';
  static const posServiceBaseUrl = 'http://10.65.203.68:8200/api/v1';
}
