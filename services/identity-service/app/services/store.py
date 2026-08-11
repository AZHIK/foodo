import secrets
from uuid import UUID

from sqlmodel import Session

from app.core.exceptions import InvalidStoreTypeError
from app.models import Business, BusinessType, LocationType, Store, StoreSetting

ALLOWED_LOCATION_TYPES: dict[BusinessType, set[LocationType]] = {
    BusinessType.RESTAURANT: {
        LocationType.HEAD_OFFICE,
        LocationType.RESTAURANT_BRANCH,
        LocationType.KITCHEN,
    },
    BusinessType.SUPPLIER: {
        LocationType.HEAD_OFFICE,
        LocationType.WAREHOUSE,
        LocationType.DEPOT,
    },
    BusinessType.DISTRIBUTOR: {
        LocationType.HEAD_OFFICE,
        LocationType.WAREHOUSE,
        LocationType.DEPOT,
    },
    BusinessType.FARMER: {
        LocationType.HEAD_OFFICE,
        LocationType.FARM,
    },
    BusinessType.PLATFORM_OPERATOR: {
        LocationType.HEAD_OFFICE,
    },
}


def generate_store_token() -> str:
    """Return a unique store identifier.

    Plain identifier only — carries no authentication or authorization
    semantics anywhere in the codebase.
    """
    return secrets.token_urlsafe(24)


def validate_store_type(business_type: str, location_type: str) -> None:
    business_type_enum = BusinessType(business_type)
    location_type_enum = LocationType(location_type)
    allowed_types = ALLOWED_LOCATION_TYPES[business_type_enum]
    if location_type_enum not in allowed_types:
        allowed_values = ", ".join(sorted(location.value for location in allowed_types))
        raise InvalidStoreTypeError(
            f"Location type '{location_type}' is not valid for business type "
            f"'{business_type}'. Allowed location types: {allowed_values}."
        )


def _enum_value(value: str | BusinessType | LocationType) -> str:
    if isinstance(value, BusinessType | LocationType):
        return value.value
    return value


def create_store(
    session: Session,
    *,
    business: Business,
    name: str,
    location_type: LocationType,
    country_code: str = "TZ",
    city: str | None = None,
    address: str | None = None,
    timezone: str = "Africa/Dar_es_Salaam",
    is_primary: bool = False,
) -> Store:
    validate_store_type(_enum_value(business.business_type), _enum_value(location_type))
    store = Store(
        business_id=business.id,
        name=name,
        token=generate_store_token(),
        location_type=location_type,
        country_code=country_code,
        city=city,
        address=address,
        timezone=timezone,
        is_primary=is_primary,
    )
    session.add(store)
    session.flush()
    session.add(StoreSetting(store_id=store.id, active=True))
    session.commit()
    session.refresh(store)
    return store


def update_store_type(
    session: Session,
    *,
    business: Business,
    store_id: UUID,
    location_type: LocationType,
) -> Store:
    validate_store_type(_enum_value(business.business_type), _enum_value(location_type))
    store = session.get(Store, store_id)
    if store is None:
        raise InvalidStoreTypeError("Store does not exist.")
    store.location_type = location_type
    session.commit()
    session.refresh(store)
    return store
