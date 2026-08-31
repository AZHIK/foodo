# Store Management Feature Implementation

## Overview

This document outlines the comprehensive store management feature implemented for business owners to perform CRUD operations on stores with full API integration and frontend UI support.

## Backend Implementation (Identity Service)

### Endpoints Implemented

#### 1. List Stores
```
GET /api/v1/businesses/{business_id}/stores
```
- **Auth**: Requires active business context
- **Returns**: List of all stores for the business
- **Restrictions**: `business_store_staff` users cannot access this endpoint (store-scoped only)

#### 2. Create Store
```
POST /api/v1/businesses/{business_id}/stores
```
- **Auth**: Requires `STORES_CREATE` permission
- **Body**:
  ```json
  {
    "name": "Store Name",
    "address": "123 Main St",
    "city": "San Francisco",
    "country_code": "US",
    "timezone": "America/Los_Angeles",
    "is_primary": false,
    "status": "active",
    "location_type": "dine_in"
  }
  ```
- **Returns**: Created store object with ID

#### 3. Get Store Details
```
GET /api/v1/businesses/{business_id}/stores/{store_id}
```
- **Auth**: Requires business context
- **Returns**: Complete store details
- **Restrictions**: `business_store_staff` users can only access their assigned store

#### 4. Update Store
```
PATCH /api/v1/businesses/{business_id}/stores/{store_id}
```
- **Auth**: Requires `STORES_UPDATE` permission
- **Body**: Partial update (only changed fields)
- **Returns**: Updated store object

#### 5. Get Store Settings
```
GET /api/v1/businesses/{business_id}/stores/{store_id}/settings
```
- **Returns**: Store-specific settings (tax, currency, hours, etc.)

#### 6. Update Store Settings
```
PATCH /api/v1/businesses/{business_id}/stores/{store_id}/settings
```
- **Auth**: Requires `STORES_UPDATE` permission
- **Body**:
  ```json
  {
    "tax_rate": 0.0825,
    "tax_inclusive": false,
    "service_charge_rate": 0.0,
    "currency": "USD",
    "receipt_prefix": "INV-",
    "auto_print_receipt": true,
    "hours": [...]
  }
  ```

#### 7. Assign Staff to Store
```
POST /api/v1/businesses/{business_id}/stores/{store_id}/staff
```
- **Auth**: Requires `USER_STORE_ROLES_ASSIGN` permission
- **Body**:
  ```json
  {
    "business_role_id": "role-uuid",
    "user_id": "user-uuid",  // Optional if creating new
    "phone": "+1234567890"    // Required if user_id not provided
  }
  ```
- **Returns**: Confirmation of role assignment

#### 8. List Store Staff
```
GET /api/v1/businesses/{business_id}/stores/{store_id}/staff
```
- **Auth**: Requires `USER_STORE_ROLES_VIEW` permission
- **Returns**: List of staff members assigned to store with their roles

#### 9. Revoke Staff Role
```
DELETE /api/v1/businesses/{business_id}/stores/{store_id}/staff/{user_id}/roles/{role_id}
```
- **Auth**: Requires `USER_STORE_ROLES_REVOKE` permission
- **Returns**: 204 No Content on success

### Store Scope Enforcement

The following guards are implemented:

1. **Store-Scoped Matching**: In `stores.py`, all store detail endpoints (get, update, settings) check that if the caller has an `active_store_id` (business_store_staff), the path store_id must match.

2. **Business-Wide Operations Block**: `business_store_staff` users cannot:
   - List all stores (`list_stores`)
   - Create new stores (`create_store`)
   - Access business-level store operations

3. **Store-Staff Category Check**: New endpoints for store-staff assignment require `BUSINESS_STAFF` category (business owners can assign staff), and prevent `business_store_staff` users from making assignments themselves.

## Frontend Implementation (Flutter App)

### New Service Layer

**File**: `lib/services/store_api_service.dart`

Provides API client methods for all store operations:
- `listStores()` - Fetch all stores
- `getStore()` - Get single store details
- `createStore()` - Create new store
- `updateStore()` - Update store information
- `deleteStore()` - Delete a store
- `getStoreSettings()` - Get store settings
- `updateStoreSettings()` - Update settings
- `assignStaffToStore()` - Assign staff with roles
- `listStoreStaff()` - List store staff
- `revokeStaffFromStore()` - Remove staff role

All methods accept `accessToken` for authentication and handle HTTP communication (placeholder for actual HTTP implementation).

### Provider Integration

**File**: `lib/providers/store_api_provider.dart`

Implements Riverpod providers for async store operations:

#### State Management
- `storeOperationProvider` - Tracks loading, error, and success states for operations
- `StoreOperationNotifier` - Manages operation state with `setLoading()`, `setError()`, `setSuccess()`, and `reset()` methods

#### CRUD Providers

**Create Store**
```dart
final createStoreProvider = FutureProvider.family<StoreLocation?, Map<String, dynamic>>(
  (ref, params) async { ... }
);
```
Usage:
```dart
final result = await ref.read(createStoreProvider({
  'businessId': 'bus-123',
  'name': 'Downtown Store',
  'address': '123 Main St',
  'city': 'San Francisco',
  'countryCode': 'US',
  'timezone': 'America/Los_Angeles',
  'isPrimary': false,
  'status': 'active',
  'locationType': 'dine_in',
}).future);
```

**Update Store**
```dart
final updateStoreProvider = FutureProvider.family<StoreLocation?, Map<String, dynamic>>(
  (ref, params) async { ... }
);
```
Usage:
```dart
final result = await ref.read(updateStoreProvider({
  'businessId': 'bus-123',
  'storeId': 'st-01',
  'name': 'Updated Name',
}).future);
```

**Delete Store**
```dart
final deleteStoreProvider = FutureProvider.family<bool, Map<String, dynamic>>(
  (ref, params) async { ... }
);
```

**Assign Staff**
```dart
final assignStaffToStoreProvider = FutureProvider.family<bool, Map<String, dynamic>>(
  (ref, params) async { ... }
);
```

**Revoke Staff**
```dart
final revokeStaffFromStoreProvider = FutureProvider.family<bool, Map<String, dynamic>>(
  (ref, params) async { ... }
);
```

### Existing UI Components

The app already has comprehensive store management UI that integrates with these new APIs:

1. **Store Management Screen** (`lib/screens/settings/store_management_screen.dart`)
   - Lists all stores with sorting and filtering
   - Summary metrics (total, active, staff count)
   - Row actions for edit, activate/deactivate, delete
   - Confirmation dialogs for destructive operations

2. **Location Form Dialog** (`lib/screens/settings/location_form_dialog.dart`)
   - Add/edit store information
   - Store name, address, phone, staff count
   - Manager assignment dropdown
   - Active/inactive toggle
   - Validation for unique names
   - Support for current store enforcement (cannot deactivate/delete)

### New Screens (Framework)

**File**: `lib/screens/stores/store_details_screen.dart`

Comprehensive store detail screen with three tabs:

1. **Overview Tab**
   - Display store information
   - Show operational status
   - Display operation feedback (loading, errors, success)

2. **Settings Tab**
   - Hours of operation configuration
   - Tax & pricing settings
   - Receipt settings and preferences

3. **Staff Tab**
   - List store-assigned staff
   - Add staff with role assignment
   - Remove staff roles
   - Display staff count

## Permission Codes

The following permission codes are used for store management:

- `STORES_CREATE` - Create new stores
- `STORES_READ` / `STORES_VIEW` - View store details
- `STORES_UPDATE` - Update store information and settings
- `STORES_DELETE` - Delete stores
- `USER_STORE_ROLES_ASSIGN` - Assign staff to stores
- `USER_STORE_ROLES_VIEW` - View store staff assignments
- `USER_STORE_ROLES_REVOKE` - Remove staff roles from stores

## Authentication & Authorization

### Flow

1. **Business Owner (business_staff)**
   - Logs in and switches to a business context
   - Receives token with `active_business_id`
   - Can access all store operations for their business
   - Can assign staff to stores

2. **Store Manager (business_store_staff)**
   - Logs in automatically assigned to one store
   - Receives token with `active_store_id` and `active_business_id`
   - Can view their assigned store details
   - Cannot create/delete stores or access other stores
   - Cannot assign staff (limited to their store)

3. **Staff Scoping**
   - Store-scoped endpoints automatically enforce `active_store_id` matching
   - Business-wide endpoints check `user_category` and block store-staff
   - Cross-service validation via `require_store_permission()` in inventory and POS services

## Database Models

### Store Model (Backend)
- `id` (UUID) - Primary key
- `business_id` (UUID) - Foreign key to Business
- `name` (String) - Store name
- `address` (String) - Physical address
- `city` (String) - City/locality
- `country_code` (String) - ISO 3166-1 alpha-2
- `timezone` (String) - IANA timezone
- `token` (String) - Internal store identifier
- `location_type` (Enum) - dine_in, takeout, delivery_hub, etc.
- `status` (String) - active, inactive
- `is_primary` (Boolean) - Flagship store flag
- `created_at`, `updated_at` - Timestamps

### Store Settings Model (Backend)
- `id` (UUID) - Primary key
- `store_id` (UUID) - Foreign key to Store
- `tax_rate` (Float) - Tax percentage
- `tax_inclusive` (Boolean) - Whether prices include tax
- `service_charge_rate` (Float) - Service charge percentage
- `currency` (String) - ISO 4217 currency code
- `receipt_prefix` (String) - Receipt numbering prefix
- `auto_print_receipt` (Boolean) - Auto-print flag
- `hours` (JSON) - Weekly operating hours

### Store Location Model (Frontend)
```dart
class StoreLocation {
  final String id;
  final String name;
  final String address;
  final String phone;
  final String? managerId;
  final int staffCount;
  final bool isActive;
  final bool isCurrent;
}
```

### Store Settings Model (Frontend)
```dart
class StoreSettings {
  final double taxRate;
  final bool taxInclusive;
  final double serviceChargeRate;
  final Currency currency;
  final OrderType defaultOrderType;
  final String receiptPrefix;
  final bool autoPrintReceipt;
  final List<DayHours> hours;
}
```

## Integration Points

### With Inventory Service
- Store validation in stock transfers
- Store-scoped inventory queries
- Transfer destination listing filtered by store status

### With POS Service
- Store selection for sessions
- Store-specific settings applied to transactions
- Receipt generation using store-specific settings

### With Auth Service
- Token generation includes `active_store_id` for store-staff
- Store context validation on protected endpoints
- Cross-service store scope verification

## Error Handling

The implementation provides comprehensive error handling:

1. **Frontend Error States**
   - Loading indicators during operations
   - Error messages displayed via snackbars
   - Success confirmation for completed operations
   - Validation errors on form submission

2. **Backend Error Responses**
   - 403 Forbidden - Permission denied or scope mismatch
   - 404 Not Found - Store or business not found
   - 409 Conflict - Duplicate store name or staff assignment exists
   - 400 Bad Request - Invalid store type or user category
   - 422 Unprocessable Entity - Invalid permission codes

3. **Business Logic Validation**
   - Cannot delete the last active store
   - Cannot deactivate/delete current terminal's store
   - Cannot assign users with wrong category to stores
   - Cannot create duplicate store names within a business

## Testing Checklist

### Backend Tests
- [ ] Test store CRUD operations with valid business context
- [ ] Test store scope enforcement for store-staff users
- [ ] Test business-wide operation blocks for store-staff
- [ ] Test staff assignment with role permissions
- [ ] Test permission-based access control
- [ ] Test cross-service store scope validation

### Frontend Tests
- [ ] Test store list display and sorting
- [ ] Test store creation with validation
- [ ] Test store update operations
- [ ] Test store deletion with confirmation
- [ ] Test loading and error states
- [ ] Test staff assignment UI
- [ ] Test responsive layout on different screen sizes

### Integration Tests
- [ ] End-to-end flow: login → create store → assign staff → verify
- [ ] Store-staff login → automatic store assignment → scope enforcement
- [ ] Cross-service validation: POS/Inventory can verify store scope
- [ ] Permission changes reflected immediately in UI

## Future Enhancements

1. **Bulk Operations**
   - Bulk staff assignments
   - Bulk store status updates
   - Batch settings apply to multiple stores

2. **Store Analytics**
   - Per-store sales dashboards
   - Store performance comparisons
   - Staff productivity by store

3. **Advanced Settings**
   - Delivery zones per store
   - Store-specific menu items
   - Regional tax configurations

4. **Staff Management**
   - Store transfer workflows
   - Schedule management per store
   - Store-specific permissions

5. **Multi-Location Support**
   - Store groups/chains
   - Centralized configuration
   - Regional variations

## Deployment Notes

### Database Migrations
- Ensure `Store` and `StoreSetting` tables exist
- Verify `UserStoreRole` junction table is in place
- Check indexes on `store_id` and `business_id`

### API Deployment
- Deploy identity-service with new endpoints
- Update inventory-service and POS-service deps
- Verify RSA keys are accessible
- Test API endpoints before release

### Frontend Deployment
- Update pubspec.yaml if new packages needed
- Run `flutter pub get` to resolve dependencies
- Test on target platforms
- Verify API endpoints are reachable

## References

- [Auth Integration Status](./auth_integration_status.md)
- [Business Auth Plan](./bussiness_auth_plan.md)
- API Documentation: See identity-service README
