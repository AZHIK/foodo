/// Result of a successful `POST /businesses` call.
///
/// Only the fields the app needs after creation are kept — the backend
/// response also carries `roles_created` and a note about business-context
/// switching, neither of which the onboarding flow consumes.
class BusinessCreateResult {
  const BusinessCreateResult({
    required this.id,
    required this.name,
    required this.ownerRoleName,
  });

  final String id;
  final String name;
  final String ownerRoleName;

  factory BusinessCreateResult.fromJson(Map<String, dynamic> json) {
    final business = json['business'];
    if (business is! Map<String, dynamic>) {
      throw const FormatException('Response has no business object.');
    }
    return BusinessCreateResult(
      id: business['id'] as String,
      name: business['name'] as String,
      ownerRoleName: (json['owner_role_name'] as String?) ?? '',
    );
  }
}
