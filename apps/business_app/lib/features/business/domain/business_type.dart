/// Self-registrable business categories.
///
/// This app is for restaurants only. The backend `BusinessType` enum
/// includes supplier/farmer/distributor/platform_operator but they are
/// not available in this app.
enum BusinessType {
  restaurant('restaurant', 'Restaurant');

  const BusinessType(this.apiValue, this.label);

  /// The value sent to `POST /businesses` (`business_type`).
  final String apiValue;

  /// Human-readable label shown in the onboarding UI.
  final String label;

  /// Only restaurants are self-registrable in this app.
  static const List<BusinessType> selfRegistrable = [BusinessType.restaurant];
}
