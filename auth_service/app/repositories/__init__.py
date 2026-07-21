"""Data access (repository) layer.

Each repository wraps a single SQLModel table and provides CRUD
operations.  Repositories accept an AsyncSession and return domain
models (SQLModel instances), never raw dicts.

Naming convention:
    UserRepository   → User model
    SessionRepository → Session model
    OTPCodeRepository → OTPCode model

Planned repositories:
    - UserRepository
    - SessionRepository
    - OTPCodeRepository
    - RoleRepository
"""
