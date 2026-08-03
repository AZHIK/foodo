import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:foodlink_business/core/network/api_client.dart';

/// Sentinels for adapter results.
class _ConnectionError {
  const _ConnectionError();
}

const _connectionError = _ConnectionError();

/// Adapter that replays a fixed sequence of results (a [ResponseBody] or a
/// connection-error [DioException]) and records the number of calls made.
///
/// The connection error is built from the actual [RequestOptions] of each
/// attempt so interceptor bookkeeping (e.g. the `retryCount` extra) behaves
/// exactly as it does with a real network stack.
class _SequenceAdapter implements HttpClientAdapter {
  _SequenceAdapter(this._results);

  final List<Object> _results;
  int calls = 0;

  /// The [RequestOptions] of the most recent fetch attempt.
  RequestOptions? lastOptions;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final index = calls < _results.length ? calls : _results.length - 1;
    calls++;
    lastOptions = options;
    final result = _results[index];
    if (result is _ConnectionError) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'Connection refused',
      );
    }
    return result as ResponseBody;
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _json(int statusCode, String body) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('AuthHeaderInterceptor', () {
    Dio buildDio({
      required List<Object> results,
      required String? Function() accessToken,
    }) {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://test',
          responseType: ResponseType.plain,
        ),
      );
      dio.httpClientAdapter = _SequenceAdapter(results);
      dio.interceptors.add(AuthHeaderInterceptor(accessToken));
      return dio;
    }

    test('injects the Bearer header when a session token is available',
        () async {
      final dio = buildDio(
        results: [_json(200, '{"ok":true}')],
        accessToken: () => 'abc.def.ghi',
      );

      final response = await dio.get('/protected');

      expect(response.statusCode, equals(200));
      final adapter = dio.httpClientAdapter as _SequenceAdapter;
      expect(
        adapter.lastOptions!.headers['Authorization'],
        equals('Bearer abc.def.ghi'),
      );
    });

    test('omits the Authorization header when no token is available',
        () async {
      final dio = buildDio(
        results: [_json(200, '{"ok":true}')],
        accessToken: () => null,
      );

      await dio.get('/public');

      final adapter = dio.httpClientAdapter as _SequenceAdapter;
      expect(adapter.lastOptions!.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('TokenRefreshInterceptor', () {
    Dio buildDio({
      required List<Object> results,
      required Future<bool> Function() refresh,
    }) {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://test',
          responseType: ResponseType.plain,
        ),
      );
      dio.httpClientAdapter = _SequenceAdapter(results);
      dio.interceptors.add(TokenRefreshInterceptor(dio, refresh));
      return dio;
    }

    test('propagates the 401 when the refresh fails', () async {
      var refreshCalls = 0;
      final dio = buildDio(
        results: [_json(401, 'unauthorized')],
        refresh: () async {
          refreshCalls++;
          return false;
        },
      );

      await expectLater(
        dio.get('/protected'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            401,
          ),
        ),
      );
      expect(refreshCalls, equals(1));
    });

    test('retries the original request once when the refresh succeeds',
        () async {
      var refreshCalls = 0;
      final dio = buildDio(
        results: [
          _json(401, 'unauthorized'),
          _json(200, '{"ok":true}'),
        ],
        refresh: () async {
          refreshCalls++;
          return true;
        },
      );

      final response = await dio.get('/protected');

      expect(response.statusCode, equals(200));
      expect(refreshCalls, equals(1));
      expect((dio.httpClientAdapter as _SequenceAdapter).calls, equals(2));
    });

    test('does not trigger refresh for non-401 errors', () async {
      var refreshCalls = 0;
      final dio = buildDio(
        results: [_json(500, 'boom')],
        refresh: () async {
          refreshCalls++;
          return true;
        },
      );

      await expectLater(
        dio.get('/protected'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      expect(refreshCalls, equals(0));
    });
  });

  group('RetryInterceptor', () {
    Dio buildDio({
      required List<Object> results,
      Duration retryDelay = Duration.zero,
    }) {
      final dio = Dio(
        BaseOptions(
          baseUrl: 'http://test',
          responseType: ResponseType.plain,
        ),
      );
      dio.httpClientAdapter = _SequenceAdapter(results);
      dio.interceptors.add(RetryInterceptor(dio, retryDelay: retryDelay));
      return dio;
    }

    test('retries once on a connection error and then succeeds', () async {
      final dio = buildDio(results: [
        _connectionError,
        _json(200, '{"ok":true}'),
      ]);

      final response = await dio.get('/data');

      expect(response.statusCode, equals(200));
      expect((dio.httpClientAdapter as _SequenceAdapter).calls, equals(2));
    });

    test('only retries once before propagating the original error', () async {
      final dio = buildDio(results: [
        _connectionError,
        _connectionError,
      ]);

      await expectLater(
        dio.get('/data'),
        throwsA(
          isA<DioException>()
              .having((e) => e.type, 'type', DioExceptionType.connectionError),
        ),
      );
      expect((dio.httpClientAdapter as _SequenceAdapter).calls, equals(2));
    });

    test('does not retry non-transient errors', () async {
      final dio = buildDio(results: [_json(500, 'boom')]);

      await expectLater(
        dio.get('/data'),
        throwsA(
          isA<DioException>().having(
            (e) => e.response?.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      expect((dio.httpClientAdapter as _SequenceAdapter).calls, equals(1));
    });
  });
}
