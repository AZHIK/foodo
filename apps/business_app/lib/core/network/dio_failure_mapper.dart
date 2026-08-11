import 'package:dio/dio.dart';

import '../error/failure.dart';

/// Maps a [DioException] to the app-wide [Failure] sealed type.
///
/// Shared by every feature API client (identity, business, …) so that a
/// network-layer error always surfaces to screens as the same [Failure]
/// variants, regardless of which service produced it.
Failure mapDioException(DioException e) {
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return Failure.network(message: e.message);
    default:
      final status = e.response?.statusCode;
      if (status == 400 || status == 422) {
        return Failure.validation(message: dioDetail(e));
      }
      if (status == 401) {
        return const Failure.auth(message: 'Unauthorized.');
      }
      return Failure.network(statusCode: status, message: dioDetail(e));
  }
}

/// Extracts the backend `detail` field from an error response body, falling
/// back to the transport-level message.
String dioDetail(DioException e) {
  final data = e.response?.data;
  if (data is Map<String, dynamic> && data['detail'] is String) {
    return data['detail'] as String;
  }
  return e.message ?? 'Request failed.';
}
