from uuid import UUID

import pytest
from sqlmodel import Session, SQLModel, create_engine, select

from app.core.exceptions import InvalidStoreTypeError
from app.models import Business, BusinessType, LocationType, StoreSetting
from app.services.store import create_store, update_store_type

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


def test_creating_farm_store_under_restaurant_is_rejected(
    session: Session,
    restaurant: Business,
) -> None:
    with pytest.raises(InvalidStoreTypeError):
        create_store(
            session,
            business=restaurant,
            name="Invalid Farm",
            location_type=LocationType.FARM,
        )


def test_creating_restaurant_branch_under_restaurant_succeeds(
    session: Session,
    restaurant: Business,
) -> None:
    store = create_store(
        session,
        business=restaurant,
        name="Mikocheni Branch",
        location_type=LocationType.RESTAURANT_BRANCH,
    )

    assert store.business_id == restaurant.id
    assert store.location_type == LocationType.RESTAURANT_BRANCH


def test_creating_store_also_creates_default_settings_row(
    session: Session,
    restaurant: Business,
) -> None:
    store = create_store(
        session,
        business=restaurant,
        name="With Settings",
        location_type=LocationType.KITCHEN,
    )

    setting = (
        session.exec(select(StoreSetting).where(StoreSetting.store_id == store.id))
    ).one_or_none()
    assert setting is not None
    assert setting.active is True


def test_store_has_unique_token(
    session: Session,
    restaurant: Business,
) -> None:
    first = create_store(
        session,
        business=restaurant,
        name="Token One",
        location_type=LocationType.KITCHEN,
    )
    second = create_store(
        session,
        business=restaurant,
        name="Token Two",
        location_type=LocationType.KITCHEN,
    )
    assert first.token
    assert first.token != second.token


def test_updating_existing_store_to_invalid_type_is_rejected(
    session: Session,
    restaurant: Business,
) -> None:
    store = create_store(
        session,
        business=restaurant,
        name="Main Kitchen",
        location_type=LocationType.KITCHEN,
    )

    with pytest.raises(InvalidStoreTypeError):
        update_store_type(
            session,
            business=restaurant,
            store_id=store.id,
            location_type=LocationType.FARM,
        )
