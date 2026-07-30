from uuid import UUID

import pytest
from sqlmodel import Session, SQLModel, create_engine

from app.core.exceptions import InvalidBusinessLocationTypeError
from app.models import Business, BusinessType, LocationType
from app.services.business_locations import (
    create_business_location,
    update_business_location_type,
)

OWNER_ID = UUID("00000000-0000-0000-0000-000000000001")


@pytest.fixture
def session() -> Session:
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session


@pytest.fixture
def restaurant(session: Session) -> Business:
    business = Business(
        name="Dar Kitchen",
        business_type=BusinessType.RESTAURANT,
        owner_user_id=OWNER_ID,
    )
    session.add(business)
    session.commit()
    session.refresh(business)
    return business


def test_creating_farm_location_under_restaurant_is_rejected(
    session: Session,
    restaurant: Business,
) -> None:
    with pytest.raises(InvalidBusinessLocationTypeError):
        create_business_location(
            session,
            business=restaurant,
            name="Invalid Farm",
            location_type=LocationType.FARM,
        )


def test_creating_restaurant_branch_under_restaurant_succeeds(
    session: Session,
    restaurant: Business,
) -> None:
    location = create_business_location(
        session,
        business=restaurant,
        name="Mikocheni Branch",
        location_type=LocationType.RESTAURANT_BRANCH,
    )

    assert location.business_id == restaurant.id
    assert location.location_type == LocationType.RESTAURANT_BRANCH


def test_updating_existing_location_to_invalid_type_is_rejected(
    session: Session,
    restaurant: Business,
) -> None:
    location = create_business_location(
        session,
        business=restaurant,
        name="Main Kitchen",
        location_type=LocationType.KITCHEN,
    )

    with pytest.raises(InvalidBusinessLocationTypeError):
        update_business_location_type(
            session,
            business=restaurant,
            location_id=location.id,
            location_type=LocationType.FARM,
        )
