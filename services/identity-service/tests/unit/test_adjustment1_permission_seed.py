import pytest
from sqlmodel import Session, SQLModel, create_engine, select

from app.core.permission_codes import PermissionCode, validate_permission_code
from app.db.seed_permissions import PERMISSION_SEEDS, seed_permissions
from app.models import Permission, PlatformRole, PlatformRolePermission


@pytest.fixture
def session() -> Session:
    engine = create_engine("sqlite:///:memory:")
    SQLModel.metadata.create_all(engine)
    with Session(engine) as session:
        yield session


def test_seeding_twice_produces_no_duplicates(session: Session) -> None:
    seed_permissions(session)
    seed_permissions(session)

    permissions = session.exec(select(Permission)).all()

    assert len(permissions) == len(PermissionCode)
    assert len({permission.code for permission in permissions}) == len(PermissionCode)

    roles = session.exec(select(PlatformRole)).all()
    assert len(roles) == 3
    assert {r.name for r in roles} == {"driver", "consumer", "admin"}

    platform_perms = session.exec(select(PlatformRolePermission)).all()
    pairs = {(prp.platform_role_id, prp.permission_code) for prp in platform_perms}
    assert len(platform_perms) == len(pairs)


def test_every_enum_member_has_corresponding_row_after_seeding(session: Session) -> None:
    seed_permissions(session)

    seeded_codes = {permission.code for permission in session.exec(select(Permission)).all()}

    assert seeded_codes == {code.value for code in PermissionCode}


def test_seed_defaults_are_derived_from_enum_metadata(session: Session) -> None:
    seed_permissions(session)

    permissions = {
        permission.code: permission for permission in session.exec(select(Permission)).all()
    }

    assert len(PERMISSION_SEEDS) == len(PermissionCode)
    assert permissions["ai.forecast.view"].is_ai_sensitive is True
    assert permissions["procurement.auto_order.enable"].is_ai_sensitive is True
    assert permissions["ai.recommendation.approve"].requires_human_approval is True
    assert permissions["procurement.approve"].requires_human_approval is True
    assert permissions["pos.write"].is_ai_sensitive is False


def test_unknown_permission_code_is_rejected_by_application_validator() -> None:
    with pytest.raises(ValueError):
        validate_permission_code("not.a.real.permission")
