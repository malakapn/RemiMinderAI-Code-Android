#!/usr/bin/env python3
"""Generate app_gu.arb and app_pa.arb preserving ICU {placeholders}."""

from __future__ import annotations

import json
import re
import time
from pathlib import Path

from deep_translator import GoogleTranslator

ARB_DIR = Path(__file__).resolve().parent.parent / "lib" / "l10n"
EN_PATH = ARB_DIR / "app_en.arb"
HI_PATH = ARB_DIR / "app_hi.arb"
PLACEHOLDER_RE = re.compile(r"(\{[a-zA-Z_][a-zA-Z0-9_]*\})")

SKIP_VALUES = {"RemiMinder", "RemiMinder.ai"}


def translate_segment(text: str, target: str, translator: GoogleTranslator) -> str:
    if not text or not text.strip():
        return text
    if text.strip() in SKIP_VALUES:
        return text
    try:
        result = translator.translate(text)
        return result if isinstance(result, str) else text
    except Exception as exc:  # noqa: BLE001
        print(f"  warn: {exc}")
        return text


def translate_preserving_placeholders(text: str, target: str) -> str:
    if "{" not in text:
        return translate_segment(text, target, GoogleTranslator(source="en", target=target))

    translator = GoogleTranslator(source="en", target=target)
    out: list[str] = []
    last = 0
    for match in PLACEHOLDER_RE.finditer(text):
        if match.start() > last:
            out.append(translate_segment(text[last : match.start()], target, translator))
        out.append(match.group(0))
        last = match.end()
    if last < len(text):
        out.append(translate_segment(text[last:], target, translator))
    return "".join(out)


def build_arb(target: str) -> dict:
    en = json.loads(EN_PATH.read_text(encoding="utf-8"))
    hi = json.loads(HI_PATH.read_text(encoding="utf-8"))

    out: dict = {}
    keys = [k for k in hi.keys() if not k.startswith("@")]
    total = len(keys)

    for i, key in enumerate(keys, 1):
        src = en.get(key, hi.get(key, ""))
        if isinstance(src, str):
            out[key] = translate_preserving_placeholders(src, target)
        else:
            out[key] = src

        meta = f"@{key}"
        if meta in en:
            out[meta] = en[meta]
        elif meta in hi:
            out[meta] = hi[meta]

        if i % 20 == 0:
            print(f"  {target}: {i}/{total}")
            time.sleep(0.2)

    out["gujarati"] = "ગુજરાતી"
    out["punjabi"] = "ਪੰਜਾਬੀ"
    return out


def main() -> None:
    for target in ("gu", "pa"):
        print(f"Generating {target}...")
        data = build_arb(target)
        path = ARB_DIR / f"app_{target}.arb"
        path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        print(f"Wrote {path}")
        time.sleep(1)


if __name__ == "__main__":
    main()
