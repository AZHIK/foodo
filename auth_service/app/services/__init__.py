"""Business logic service layer.

Each service is a stateless class (or set of functions) that:
    - Receives a DB session (and other deps) via dependency injection
    - Orchestrates calls to repositories
    - Raises domain-specific exceptions (defined in core/exceptions.py — TBD)
    - Returns domain objects or schemas

Services do NOT depend on FastAPI directly; they depend on the
repository layer and core primitives.

Planned services:
    - AuthService    (signup, login, refresh, logout)
    - OTPService     (send, verify OTP codes)
    - SessionService (active session tracking, revocation)
    - StaffService   (staff PIN login)
"""
