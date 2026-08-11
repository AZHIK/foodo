import 'business_type.dart';

/// Default country and timezone for new businesses.
///
/// Matches the platform's existing defaults for Tanzania (see the backend
/// `BusinessBase` schema: `country_code="TZ"`,
/// `timezone="Africa/Dar_es_Salaam"`).
const String defaultBusinessCountryCode = 'TZ';
const String defaultBusinessTimezone = 'Africa/Dar_es_Salaam';

/// Immutable request body for `POST /businesses`.
///
/// Mirrors the backend `BusinessCreateRequest` schema exactly — no
/// `owner_user_id` (set server-side), `organization_id` and `tax_id`
/// nullable, and Tanzania defaults for `country_code` / `timezone`.
class BusinessCreateRequest {
  const BusinessCreateRequest({
    required this.name,
    this.businessType = BusinessType.restaurant,
    this.organizationId,
    this.taxId,
    this.countryCode = defaultBusinessCountryCode,
    required this.city,
    this.timezone = defaultBusinessTimezone,
  });

  final String name;
  final BusinessType businessType;
  final String? organizationId;
  final String? taxId;
  final String countryCode;
  final String city;
  final String timezone;

  Map<String, dynamic> toJson() => {
        'name': name,
        'business_type': businessType.apiValue,
        if (organizationId != null) 'organization_id': organizationId,
        if (taxId != null) 'tax_id': taxId,
        'country_code': countryCode,
        'city': city,
        'timezone': timezone,
      };

  @override
  String toString() => 'BusinessCreateRequest(name: $name, '
      'businessType: ${businessType.apiValue}, city: $city, '
      'countryCode: $countryCode)';
}
