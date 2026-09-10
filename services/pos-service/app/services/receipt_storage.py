"""Local-disk storage for finance receipt uploads.

MVP transport: files are written to a local directory (see
``Settings.receipt_storage_root``), not an S3/MinIO bucket — no cloud
storage infra exists anywhere in this repo yet, and standing one up isn't
justified for a single-file-per-entry receipt feature. Behind the
``ReceiptStorage`` protocol so a future S3/MinIO backend is a new class,
not a rewrite of every call site.

Known tradeoff (documented, not hidden): local disk pins this service to a
single node — no horizontal scaling, no rolling deploy across hosts — and
the receipts volume must be included in the backup story (a Postgres dump
alone is no longer a complete backup once receipts exist). Revisit before
either becomes a real requirement.

Security posture:
- The client-supplied filename is NEVER used to build a filesystem path —
  only to populate ``original_filename`` (sanitized) for display/download.
  The on-disk name is always ``{attachment_id}{ext}``.
- Content-type is checked against an allowlist AND sniffed from the first
  bytes of the upload — a client can lie about ``Content-Type``.
- ``resolve_path`` asserts the resolved path stays inside the storage root
  before returning, as a second line of defense against a corrupted or
  tampered ``storage_key``.
"""

from __future__ import annotations

import hashlib
import os
import re
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Protocol
from uuid import UUID

from fastapi import UploadFile

from app.core.config import get_settings
from app.core.exceptions import DomainError

# content-type -> (file extension, magic-byte sniffer)
_MAGIC_JPEG = (b"\xff\xd8\xff",)
_MAGIC_PNG = (b"\x89PNG\r\n\x1a\n",)
_MAGIC_WEBP_RIFF = b"RIFF"
_MAGIC_WEBP_TAG = b"WEBP"
_MAGIC_PDF = (b"%PDF-",)

ALLOWED_CONTENT_TYPES: dict[str, str] = {
    "image/jpeg": ".jpg",
    "image/png": ".png",
    "image/webp": ".webp",
    "application/pdf": ".pdf",
}

_SAFE_FILENAME_RE = re.compile(r"[^A-Za-z0-9._ -]")


class ReceiptStorageError(DomainError):
    """Base for all receipt storage errors."""


class ReceiptValidationError(ReceiptStorageError):
    """The uploaded file failed a validation check (type, size, content)."""


@dataclass(frozen=True)
class StoredReceipt:
    storage_key: str
    original_filename: str
    content_type: str
    byte_size: int
    checksum_sha256: str


def _sniff_content_type(head: bytes, declared_content_type: str) -> bool:
    """Return True if *head* (the first bytes of the upload) matches the
    magic bytes expected for *declared_content_type*."""
    if declared_content_type == "image/jpeg":
        return any(head.startswith(sig) for sig in _MAGIC_JPEG)
    if declared_content_type == "image/png":
        return any(head.startswith(sig) for sig in _MAGIC_PNG)
    if declared_content_type == "image/webp":
        return head.startswith(_MAGIC_WEBP_RIFF) and head[8:12] == _MAGIC_WEBP_TAG
    if declared_content_type == "application/pdf":
        return any(head.startswith(sig) for sig in _MAGIC_PDF)
    return False


def _sanitize_original_filename(filename: str | None) -> str:
    base = os.path.basename(filename or "receipt")
    cleaned = _SAFE_FILENAME_RE.sub("_", base).strip() or "receipt"
    return cleaned[:255]


class ReceiptStorage(Protocol):
    async def save(
        self,
        *,
        business_id: UUID,
        attachment_id: UUID,
        upload: UploadFile,
    ) -> StoredReceipt: ...

    def resolve_path(self, storage_key: str) -> Path: ...


class LocalDiskReceiptStorage:
    """Writes receipts under ``{root}/{business_id}/{YYYY}/{MM}/{attachment_id}{ext}``."""

    def __init__(self, root: str | Path) -> None:
        self._root = Path(root).resolve()

    async def save(
        self,
        *,
        business_id: UUID,
        attachment_id: UUID,
        upload: UploadFile,
    ) -> StoredReceipt:
        settings = get_settings()
        declared_content_type = upload.content_type or ""
        if declared_content_type not in ALLOWED_CONTENT_TYPES:
            raise ReceiptValidationError(
                f"Unsupported content type '{declared_content_type}'. "
                f"Allowed: {', '.join(sorted(ALLOWED_CONTENT_TYPES))}"
            )
        ext = ALLOWED_CONTENT_TYPES[declared_content_type]

        now = datetime.now(UTC)
        rel_dir = Path(str(business_id)) / f"{now:%Y}" / f"{now:%m}"
        target_dir = self._root / rel_dir
        target_dir.mkdir(parents=True, exist_ok=True)

        rel_path = rel_dir / f"{attachment_id}{ext}"
        final_path = self._root / rel_path
        tmp_path = target_dir / f".{attachment_id}.part"

        hasher = hashlib.sha256()
        byte_size = 0
        head = b""
        max_bytes = settings.receipt_max_bytes

        try:
            with open(tmp_path, "wb") as tmp_file:
                while chunk := await upload.read(1024 * 64):
                    byte_size += len(chunk)
                    if byte_size > max_bytes:
                        raise ReceiptValidationError(
                            f"File exceeds the {max_bytes} byte upload limit"
                        )
                    if len(head) < 32:
                        head += chunk
                    hasher.update(chunk)
                    tmp_file.write(chunk)

            if byte_size == 0:
                raise ReceiptValidationError("Uploaded file is empty")
            if not _sniff_content_type(head, declared_content_type):
                raise ReceiptValidationError(
                    "File content does not match its declared content type"
                )

            os.replace(tmp_path, final_path)
        except Exception:
            tmp_path.unlink(missing_ok=True)
            raise

        return StoredReceipt(
            storage_key=str(rel_path),
            original_filename=_sanitize_original_filename(upload.filename),
            content_type=declared_content_type,
            byte_size=byte_size,
            checksum_sha256=hasher.hexdigest(),
        )

    def resolve_path(self, storage_key: str) -> Path:
        candidate = (self._root / storage_key).resolve()
        if self._root not in candidate.parents and candidate != self._root:
            raise ReceiptStorageError(
                f"Refusing to resolve path outside storage root: {storage_key}"
            )
        return candidate


def get_receipt_storage() -> ReceiptStorage:
    """FastAPI dependency — overridable in tests via ``app.dependency_overrides``."""
    settings = get_settings()
    return LocalDiskReceiptStorage(settings.receipt_storage_root)
