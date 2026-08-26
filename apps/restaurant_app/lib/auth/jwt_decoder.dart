/// Simple JWT decoder for extracting claims client-side.
///
/// No signature verification — the token transport is already trusted
/// (received over TLS from login response, stored in secure storage).
/// Claims are used only for local bookkeeping (expiry check, user id),
/// not as a security boundary. The backend always re-validates the token
/// signature on every authenticated request.
library;

import 'dart:convert';

/// Decoded JWT payload claims for a business-user access token (RS256).
class JwtClaims {
  final String sub; // user UUID
  final int exp; // expiry as epoch seconds
  final String? activeBusinessId;

  JwtClaims({
    required this.sub,
    required this.exp,
    this.activeBusinessId,
  });

  /// Returns when this token expires as a DateTime.
  DateTime get expiresAt =>
      DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);

  /// True if the token is already expired (or expires within 1 second).
  bool get isExpired {
    final now = DateTime.now().toUtc();
    return now.isAfter(expiresAt.subtract(const Duration(seconds: 1)));
  }
}

/// Decodes the payload segment of a JWT without verifying the signature.
JwtClaims decodeAccessToken(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) {
      throw FormatException('JWT must have 3 parts (header.payload.signature)');
    }

    final payload = parts[1];
    // Add padding if needed (base64url drops trailing `=`).
    final padded = payload.padRight(payload.length + (4 - payload.length % 4) % 4, '=');
    final bytes = base64Url.decode(padded);
    final json = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;

    return JwtClaims(
      sub: json['sub'] as String? ?? '',
      exp: json['exp'] as int? ?? 0,
      activeBusinessId: json['active_business_id'] as String?,
    );
  } catch (e) {
    throw FormatException('Failed to decode JWT: $e');
  }
}
