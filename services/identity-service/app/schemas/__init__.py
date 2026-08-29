"""SQLModel table=False / Pydantic schemas (API request/response shapes).

These are NOT backed by DB tables.  Use them for:
    - Request body validation
    - Response serialization (to avoid leaking DB internals)
    - Internal DTOs where `from_attributes` mode is needed

When a schema matches the DB model exactly, reuse the model (with
response_model_exclude_unset where appropriate).  When it diverges,
define a separate schema here.

Available modules (one file per model or logical group):
    validators          — shared PhoneStr, NormalizedEmailStr, StrongPassword,
                          BusinessPassword, OTPCodeStr
    user                — User CRUD (+ UserPhoneChangeRequest, UserStatusUpdate)
    organization        — Organization CRUD
    business            — Business CRUD
    store               — Store CRUD
    store_setting       — StoreSetting CRUD (1:1 with store; no standalone POST)
    permission          — PermissionRead (seed-only, no Create/Update)
    rbac                — Group, Role, RolePermission, UserGroup, UserRole,
                          PlatformRole, UserPlatformRole
    business_rbac       — BusinessRole, BusinessRolePermission, UserBusinessRole,
                          UserStoreRole, UserBusinessPermission
    role_template       — RoleTemplate, RoleTemplatePermission
    auth_security       — Read-only: VerificationCode, RefreshToken, UserSession,
                          TrustedDevice, LoginAttempt, AuthRiskEvent
    auth                — Authentication flows: register, OTP, login, password reset,
                          token claims, business-context switching
"""
