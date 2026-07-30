from uuid import UUID

from sqlmodel import Session

from app.core.exceptions import InvalidBusinessLocationTypeError
from app.models import Business, BusinessLocation, BusinessType, LocationType

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


def validate_location_type(business_type: str, location_type: str) -> None:
    business_type_enum = BusinessType(business_type)
    location_type_enum = LocationType(location_type)
    allowed_types = ALLOWED_LOCATION_TYPES[business_type_enum]
    if location_type_enum not in allowed_types:
        allowed_values = ", ".join(sorted(location.value for location in allowed_types))
        raise InvalidBusinessLocationTypeError(
            f"Location type '{location_type}' is not valid for business type "
            f"'{business_type}'. Allowed location types: {allowed_values}."
        )


def _enum_value(value: str | BusinessType | LocationType) -> str:
    if isinstance(value, BusinessType | LocationType):
        return value.value
    return value


def create_business_location(
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
) -> BusinessLocation:
    validate_location_type(_enum_value(business.business_type), _enum_value(location_type))
    location = BusinessLocation(
        business_id=business.id,
        name=name,
        location_type=location_type,
        country_code=country_code,
        city=city,
        address=address,
        timezone=timezone,
        is_primary=is_primary,
    )
    session.add(location)
    session.commit()
    session.refresh(location)
    return location


def update_business_location_type(
    session: Session,
    *,
    business: Business,
    location_id: UUID,
    location_type: LocationType,
) -> BusinessLocation:
    validate_location_type(_enum_value(business.business_type), _enum_value(location_type))
    location = session.get(BusinessLocation, location_id)
    if location is None:
        raise InvalidBusinessLocationTypeError("Business location does not exist.")
    location.location_type = location_type
    session.commit()
    session.refresh(location)
    return location
