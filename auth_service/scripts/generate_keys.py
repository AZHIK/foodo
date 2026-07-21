"""Generate a 2048-bit RSA keypair for RS256 JWT signing.

Run once during local setup:
    uv run python scripts/generate_keys.py

This writes ``keys/private.pem`` and ``keys/public.pem``.
In production, these files are mounted as Docker secrets at
``/run/secrets/jwt_private.pem`` and ``/run/secrets/jwt_public.pem``;
the paths are configured in ``app/core/config.py``.
"""

from __future__ import annotations

from pathlib import Path

from cryptography.hazmat.primitives import serialization
from cryptography.hazmat.primitives.asymmetric import rsa


def main() -> None:
    keys_dir = Path(__file__).resolve().parent.parent / "keys"
    keys_dir.mkdir(exist_ok=True)

    private_path = keys_dir / "private.pem"
    public_path = keys_dir / "public.pem"

    if private_path.exists() and public_path.exists():
        print("Keypair already exists — skipping generation.")
        return

    key = rsa.generate_private_key(
        public_exponent=65537,
        key_size=2048,
    )

    private_pem = key.private_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PrivateFormat.TraditionalOpenSSL,
        encryption_algorithm=serialization.NoEncryption(),
    )
    private_path.write_bytes(private_pem)
    private_path.chmod(0o600)
    print(f"Wrote {private_path}")

    public_pem = key.public_key().public_bytes(
        encoding=serialization.Encoding.PEM,
        format=serialization.PublicFormat.SubjectPublicKeyInfo,
    )
    public_path.write_bytes(public_pem)
    print(f"Wrote {public_path}")

    print("Done — RSA 2048-bit keypair is ready for local development.")


if __name__ == "__main__":
    main()
