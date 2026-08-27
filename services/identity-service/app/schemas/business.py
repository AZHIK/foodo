"""Schemas for the Business model.

business_type is validated by the BusinessType enum at the schema level —
any value not in the enum is rejected before reaching the service layer.
"""

from __future__ import annotations

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, ConfigDict

from app.models.business import BusinessStatus, BusinessType
from app.schemas.validators import NormalizedEmailStr, PhoneStr


class BusinessBase(BaseModel):
    """Shared fields for business schemas."""

    name: str
    business_type: BusinessType
    owner_user_id: UUID
    organization_id: UUID | None = None
    tax_id: str | None = None
    registration_number: str | None = None
    email: NormalizedEmailStr | None = None
    phone: PhoneStr | None = None
    address: str | None = None
    status: BusinessStatus = BusinessStatus.ACTIVE
    logo: str | None = None
    license_document_url: str | None = None
    cuisine_type: str | None = None
    country_code: str = "TZ"
    city: str | None = None
    timezone: str = "Africa/Dar_es_Salaam"


class BusinessCreate(BusinessBase):
    """Fields required to create a business.

    business_type must be one of: restaurant, supplier, farmer, distributor, platform_operator.
    Other values are rejected at the schema level by the BusinessType enum.
    """


class BusinessCreateRequest(BaseModel):
    """API request body for POST /businesses — no owner_user_id (set server-side)."""

    name: str
    business_type: BusinessType
    organization_id: UUID | None = None
    tax_id: str | None = None
    registration_number: str | None = None
    email: NormalizedEmailStr | None = None
    phone: PhoneStr | None = None
    address: str | None = None
    status: BusinessStatus = BusinessStatus.ACTIVE
    logo: str | None = None
    license_document_url: str | None = None
    cuisine_type: str | None = None
    country_code: str = "TZ"
    city: str | None = None
    timezone: str = "Africa/Dar_es_Salaam"


class BusinessUpdate(BaseModel):
    """Fields that may be updated on a business (partial update)."""

    name: str | None = None
    business_type: BusinessType | None = None
    organization_id: UUID | None = None
    tax_id: str | None = None
    registration_number: str | None = None
    email: NormalizedEmailStr | None = None
    phone: PhoneStr | None = None
    address: str | None = None
    status: BusinessStatus | None = None
    logo: str | None = None
    license_document_url: str | None = None
    cuisine_type: str | None = None
    country_code: str | None = None
    city: str | None = None
    timezone: str | None = None


class BusinessRead(BusinessBase):
    """Full business representation returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: UUID
    created_at: datetime
    updated_at: datetime


class BusinessCreateResponse(BaseModel):
    """Response returned after a successful business creation."""

    business: BusinessRead
    roles_created: list[str]
    owner_role_name: str
    note: str = (
        "Your current access token does not yet reflect this business. "
        "Call POST /auth/context/switch with this business_id to obtain "
        "a token scoped to the new business."
    )
