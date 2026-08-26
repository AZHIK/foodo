/// Request/response models for the Identity Service auth endpoints.
///
/// Decoupled from backend schemas so the app can evolve independently.
/// All shapes verified against the live identity-service backend.
library;

/// Request body for POST /auth/otp/request.
class OtpRequestInput {
  final String phone;

  OtpRequestInput({required this.phone});

  Map<String, dynamic> toJson() => {'phone': phone};
}

/// Request body for POST /auth/otp/verify.
class OtpVerifyInput {
  final String phone;
  final String code;

  OtpVerifyInput({
    required this.phone,
    required this.code,
  });

  Map<String, dynamic> toJson() => {
        'phone': phone,
        'code': code,
      };
}

/// Response from POST /auth/otp/verify, POST /auth/refresh, POST /auth/context/switch.
/// All three endpoints return the same shape (bearer tokens, no expiry/user_id in response).
/// Expiry and user_id are decoded from the JWT's `exp`/`sub` claims.
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
    );
  }
}

/// Response from GET /users/me/onboarding-status.
class OnboardingStatusOutput {
  final bool needsOnboarding;
  final String? businessId;
  final String? businessName;

  OnboardingStatusOutput({
    required this.needsOnboarding,
    this.businessId,
    this.businessName,
  });

  factory OnboardingStatusOutput.fromJson(Map<String, dynamic> json) {
    return OnboardingStatusOutput(
      needsOnboarding: json['needs_onboarding'] as bool? ?? false,
      businessId: json['business_id'] as String?,
      businessName: json['business_name'] as String?,
    );
  }
}

/// Request body for POST /auth/context/switch.
class ContextSwitchInput {
  final String businessId;

  ContextSwitchInput({required this.businessId});

  Map<String, dynamic> toJson() => {'business_id': businessId};
}

/// Request body for POST /auth/refresh.
class TokenRefreshInput {
  final String refreshToken;

  TokenRefreshInput({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}

/// Request body for POST /api/v1/businesses (business creation / onboarding).
class BusinessCreateInput {
  final String name;
  final String businessType;
  final String? email;
  final String? phone;
  final String? address;
  final String? city;
  final String? countryCode;
  final String? timezone;

  BusinessCreateInput({
    required this.name,
    required this.businessType,
    this.email,
    this.phone,
    this.address,
    this.city,
    this.countryCode,
    this.timezone,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'business_type': businessType,
    };
    if (email != null) map['email'] = email;
    if (phone != null) map['phone'] = phone;
    if (address != null) map['address'] = address;
    if (city != null) map['city'] = city;
    if (countryCode != null) map['country_code'] = countryCode;
    if (timezone != null) map['timezone'] = timezone;
    return map;
  }
}

/// Response from POST /api/v1/businesses.
/// The full response body has nested `business`, `roles_created`, `owner_role_name`, `note`.
/// We extract the key fields we need for app flow.
class BusinessCreateOutput {
  final String businessId;
  final String ownerRoleName;

  BusinessCreateOutput({
    required this.businessId,
    required this.ownerRoleName,
  });

  factory BusinessCreateOutput.fromJson(Map<String, dynamic> json) {
    final business = json['business'] as Map<String, dynamic>;
    return BusinessCreateOutput(
      businessId: business['id'] as String,
      ownerRoleName: json['owner_role_name'] as String? ?? 'Owner',
    );
  }
}

/// One store returned from GET /api/v1/businesses/{id}/stores.
class StoreDto {
  final String id;
  final bool isPrimary;
  final String name;

  StoreDto({
    required this.id,
    required this.isPrimary,
    required this.name,
  });

  factory StoreDto.fromJson(Map<String, dynamic> json) {
    return StoreDto(
      id: json['id'] as String,
      isPrimary: json['is_primary'] as bool? ?? false,
      name: json['name'] as String,
    );
  }
}
