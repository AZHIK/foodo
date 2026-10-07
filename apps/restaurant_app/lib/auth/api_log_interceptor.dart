/// Debug logging for API traffic that stays quiet around binary payloads.
///
/// A plain `LogInterceptor(requestBody: true, responseBody: true)` prints
/// every response body verbatim — fine while every payload was JSON, but a
/// single product-photo download then dumps megabytes of byte values
/// (`223, 197, 113, …` with `255, 0` JPEG stuffing pairs) into the
/// terminal. This interceptor logs the same method/URL/headers/status for
/// every call, full bodies for JSON, and a one-line `<binary …>` / `<multipart
/// …>` summary for photos and uploads instead.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiLogInterceptor extends Interceptor {
  const ApiLogInterceptor();

  static bool _isBinaryBody(Object? data) =>
      data is FormData || data is List<int> || data is Uint8List;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('--> ${options.method} ${options.uri}');
    final data = options.data;
    if (data == null) {
      handler.next(options);
      return;
    }
    if (data is FormData) {
      debugPrint('<multipart ${data.files.length} file(s), '
          '${data.fields.length} field(s)>');
    } else if (_isBinaryBody(data)) {
      debugPrint('<binary ${(data as List).length} bytes>');
    } else {
      debugPrint(data.toString());
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '<-- ${response.statusCode} ${response.requestOptions.uri}',
    );
    final data = response.data;
    if (_isBinaryBody(data)) {
      debugPrint('<binary ${(data as List).length} bytes>');
    } else {
      debugPrint(data.toString());
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    // One short line: backend `detail` when present, else the status, else
    // the transport cause — never Dio's multi-line status-code lecture.
    final status = err.response?.statusCode;
    final data = err.response?.data;
    final detail =
        data is Map && data['detail'] is String ? data['detail'] as String : null;
    final cause = detail ??
        (status != null
            ? 'HTTP $status'
            : '${err.type}${err.error == null ? '' : ': ${err.error}'}');
    debugPrint('<-- ERROR $cause ${err.requestOptions.uri}');
    handler.next(err);
  }
}
