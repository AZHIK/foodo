import 'package:flutter_test/flutter_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:foodlink_business/core/network/api_client.dart';
import 'package:foodlink_business/core/network/api_endpoints.dart';

const _testEnvContent = '''
IDENTITY_BASE_URL=http://localhost:8009
INVENTORY_BASE_URL=http://localhost:8100
POS_BASE_URL=http://localhost:8200
''';

void main() {
  group('ApiClient health-check', () {
    late ApiClient apiClient;

    setUp(() {
      dotenv.loadFromString(envString: _testEnvContent);
      apiClient = ApiClient.instance;
    });

    test('can call Identity Service /health endpoint and parse 200 response',
        () async {
      // This test requires Identity Service to be running locally
      // via docker-compose at the configured base URL.
      //
      // If the service is not running, the test will throw a
      // DioException (connection refused) rather than fail silently.
      //
      // Run the test with:
      //   flutter test test/core/network/api_client_test.dart
      // after starting: docker compose up -d  (from services/identity-service/)

      try {
        final response = await apiClient.dio.get(ApiEndpoints.identityHealth);

        expect(response.statusCode, equals(200));
        expect(response.data, isA<Map<String, dynamic>>());

        final body = response.data as Map<String, dynamic>;
        expect(body, containsPair('status', 'ok'));
        expect(body.containsKey('service'), isTrue);
        expect(body.containsKey('version'), isTrue);
      } on DioException catch (e) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.connectionError) {
          fail(
            'Identity Service is not reachable at ${ApiEndpoints.identityBase}.\n'
            'Start it with:\n'
            '  cd services/identity-service && docker compose up -d\n'
            'Then re-run this test.',
          );
        }
        rethrow;
      }
    });
  });
}
