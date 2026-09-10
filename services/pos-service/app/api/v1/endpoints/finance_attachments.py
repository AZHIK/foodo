"""Receipt attachment upload/download endpoints.

An attachment is uploaded independently of the expense/income entry it will
end up referenced by — the offline client uploads it as soon as connectivity
allows and only then includes the returned ``id`` in the entry's sync
payload (see ``app/services/receipt_storage.py`` for the storage design and
its documented single-node/backup tradeoffs).
"""

from __future__ import annotations

from uuid import UUID, uuid4

import structlog
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import FileResponse
from sqlmodel import select
from sqlmodel.ext.asyncio.session import AsyncSession

from app.core.permission_codes import PermissionCode
from app.db.session import get_db
from app.deps.auth import get_current_claims, require_business_permission
from app.models.finance import FinanceAttachment
from app.schemas.finance import FinanceAttachmentRead
from app.services.receipt_storage import (
    ReceiptStorage,
    ReceiptValidationError,
    get_receipt_storage,
)

logger = structlog.get_logger(__name__)
router = APIRouter(tags=["finance"])


@router.post(
    "/businesses/{business_id}/finance/attachments",
    response_model=FinanceAttachmentRead,
    status_code=status.HTTP_201_CREATED,
)
async def upload_finance_attachment(
    business_id: UUID,
    file: UploadFile = File(...),
    session: AsyncSession = Depends(get_db),
    claims: dict = Depends(get_current_claims),
    storage: ReceiptStorage = Depends(get_receipt_storage),
    _active_business: str = Depends(
        require_business_permission(PermissionCode.FINANCE_ATTACHMENTS_UPLOAD)
    ),
) -> FinanceAttachmentRead:
    try:
        uploader_id = UUID(claims["sub"])
    except (ValueError, KeyError, TypeError):
        uploader_id = None

    attachment_id = uuid4()
    try:
        stored = await storage.save(
            business_id=business_id, attachment_id=attachment_id, upload=file,
        )
    except ReceiptValidationError as exc:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(exc)) from exc

    attachment = FinanceAttachment(
        id=attachment_id,
        business_id=business_id,
        storage_key=stored.storage_key,
        original_filename=stored.original_filename,
        content_type=stored.content_type,
        byte_size=stored.byte_size,
        checksum_sha256=stored.checksum_sha256,
        uploaded_by=uploader_id,
    )
    session.add(attachment)
    await session.commit()
    await session.refresh(attachment)

    logger.info(
        "finance_attachment_uploaded",
        business_id=str(business_id),
        attachment_id=str(attachment.id),
        byte_size=attachment.byte_size,
    )

    return FinanceAttachmentRead.model_validate(attachment, from_attributes=True)


@router.get("/businesses/{business_id}/finance/attachments/{attachment_id}")
async def download_finance_attachment(
    business_id: UUID,
    attachment_id: UUID,
    session: AsyncSession = Depends(get_db),
    storage: ReceiptStorage = Depends(get_receipt_storage),
    _active_business: str = Depends(require_business_permission(PermissionCode.FINANCE_VIEW)),
) -> FileResponse:
    attachment = (
        await session.exec(
            select(FinanceAttachment).where(FinanceAttachment.id == attachment_id)
        )
    ).first()
    # 404 (not 403) on a cross-business id — don't confirm existence across tenants.
    if attachment is None or attachment.business_id != business_id:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attachment not found")

    path = storage.resolve_path(attachment.storage_key)
    if not path.is_file():
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Attachment not found")

    return FileResponse(
        path,
        media_type=attachment.content_type,
        filename=attachment.original_filename,
        headers={
            "X-Content-Type-Options": "nosniff",
            "Cache-Control": "private, no-store",
        },
    )
