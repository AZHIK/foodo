/// Locale propagation for backend calls — the UI half of the Swahili plan.
///
/// Every request carries `Accept-Language: en|sw` (read synchronously from
/// [L10n.code], so it always matches the visible UI). Backends use it to pick
/// the `detail` message language; they always also return a stable `code`
/// the UI can map when it needs its own wording. No language is ever stored
/// server-side — the header is stateless, so no database change was needed.
///
/// Failures with no usable `detail` (offline, timeouts) surface
/// [AppStrings.apiRequestFailed] in the UI language instead of a hardcoded
/// English literal.
library;

import 'package:dio/dio.dart';

import '../constants/app_strings.dart';
import '../l10n/l10n.dart';

/// Request interceptor: stamps the active UI language on every call.
class LocaleInterceptor extends Interceptor {
  const LocaleInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = L10n.localeCode;
    handler.next(options);
  }
}

/// Extracts the human message from a failed response: localized `detail`
/// first, Dio's own message next, localized generic fallback last.
String apiErrorMessage(DioException e) {
  final data = e.response?.data;
  final detail = data is Map ? data['detail'] : null;
  return detail?.toString() ?? e.message ?? AppStrings.apiRequestFailed;
}
