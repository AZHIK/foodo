"""Stateless UI-language support for backend messages.

Same contract as identity-service: `Accept-Language: en|sw` resolves via
[LocaleMiddleware] onto `request.state.lang`; [L] picks the message.
Nothing is stored — no database change.
"""

from __future__ import annotations

SUPPORTED = ("en", "sw")
DEFAULT = "en"

_CATALOG: dict[str, dict[str, str]] = {
    "sale.customer_missing": {
        "en": "Customer {customer_id} does not exist.",
        "sw": "Mteja {customer_id} haipo.",
    },
    "sale.reason_required": {
        "en": "A reason is required to void or refund a sale.",
        "sw": "Sababu inahitajika kubatilisha au kurejesha mauzo.",
    },
    "sale.already_final": {
        "en": "Sale is already {status} and cannot be changed.",
        "sw": "Mauzo tayari ni '{status}' hayawezi kubadilishwa.",
    },
    "finance.update_empty": {
        "en": "At least one field must be provided in an update.",
        "sw": "Angalau sehemu moja lazima itolewe kwenye sasisho.",
    },
    "finance.not_found": {
        "en": "Entry not found.",
        "sw": "Kiingilio hakikupatikana.",
    },
    "receipt.empty_file": {
        "en": "Uploaded file is empty.",
        "sw": "Faili lililopakiwa halina chochote.",
    },
    "auth.missing_header": {
        "en": "Missing or invalid Authorization header",
        "sw": "Kichwa cha Authorization hakipo au si sahihi",
    },
    "auth.token_expired": {
        "en": "Access token has expired",
        "sw": "Token ya ufikiaji imeisha muda wake",
    },
    "auth.token_invalid": {
        "en": "Invalid access token",
        "sw": "Token ya ufikiaji si sahihi",
    },
}


def parse_lang(accept_language: str | None) -> str:
    if not accept_language:
        return DEFAULT
    first = accept_language.split(",")[0].strip().lower()
    code = first.split(";")[0].strip().split("-")[0].strip()
    return code if code in SUPPORTED else DEFAULT


def request_lang(request) -> str:
    state_lang = getattr(getattr(request, "state", None), "lang", None)
    if state_lang in SUPPORTED:
        return state_lang
    headers = getattr(request, "headers", {}) or {}
    return parse_lang(headers.get("accept-language"))


def L(key: str, lang: str = DEFAULT, **kwargs) -> str:  # noqa: E743, N802
    entry = _CATALOG.get(key)
    if entry is None:
        return key
    template = entry.get(lang, entry[DEFAULT])
    try:
        return template.format(**kwargs)
    except (KeyError, IndexError):
        return template
