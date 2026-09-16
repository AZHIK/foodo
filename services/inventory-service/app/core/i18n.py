"""Stateless UI-language support for backend messages.

Same contract as identity-service: `Accept-Language: en|sw` resolves via
[LocaleMiddleware] onto `request.state.lang`; [L] picks the message.
Nothing is stored — no database change.
"""

from __future__ import annotations

SUPPORTED = ("en", "sw")
DEFAULT = "en"

_CATALOG: dict[str, dict[str, str]] = {
    "recipe.wrong_type": {
        "en": "Item '{name}' is item_type '{actual}', expected a sellable menu item.",
        "sw": "Kitu '{name}' ni aina '{actual}', ilitarajiwa kiwe chakula kinachouzika.",
    },
    "recipe.ingredient_missing": {
        "en": "Ingredient item {item_id} does not exist.",
        "sw": "Kiungo chenye kitambulisho {item_id} hakipo.",
    },
    "ops.reason_short": {
        "en": "Reason must be at least 3 characters.",
        "sw": "Sababu lazima iwe na herufi 3 angalau.",
    },
    "ops.quantity_positive": {
        "en": "Quantity must be positive.",
        "sw": "Kiasi lazima kizidi sifuri.",
    },
    "ops.same_store": {
        "en": "Source and destination stores must be different.",
        "sw": "Duka la chanzo na la kupokea lazima vitofautiane.",
    },
    "reorder.no_unit": {
        "en": "Item has no unit assigned. Assign a unit before reordering.",
        "sw": "Kitu hiki hakina kipimo. Weka kipimo kabla ya kuagiza.",
    },
    "reorder.bad_status": {
        "en": "Reorder is already {status}, cannot receive it.",
        "sw": "Agizo tayari ni '{status}', haliwezi kupokelewa.",
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
