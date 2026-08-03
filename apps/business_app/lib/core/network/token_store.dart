import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory holder for the currently active session's access token.
///
/// Bridges the singleton [ApiClient] (constructed outside the provider
/// tree) and the Riverpod-based auth layer: [AuthNotifier] writes the
/// token after OTP verification and the auth-header interceptor reads it
/// before every request. Deliberately in-memory so a cold start always
/// begins without a token and re-authenticates via OTP.
class TokenStore {
  TokenStore();

  /// The shared app-wide instance consulted by [ApiClient].
  static final TokenStore instance = TokenStore();

  /// Access token for the currently active session, if any.
  String? accessToken;
}

/// App-wide [TokenStore] instance — the same object [ApiClient] reads so
/// tokens written by [AuthNotifier] are visible to every request.
final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore.instance);
