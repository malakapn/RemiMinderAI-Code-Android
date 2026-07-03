#!/usr/bin/env python3
"""Fix ICU placeholders in generated arb files (keep {name} tokens from English)."""

from __future__ import annotations

import json
import re
from pathlib import Path

ARB_DIR = Path(__file__).resolve().parent.parent / "lib" / "l10n"
EN_PATH = ARB_DIR / "app_en.arb"
PLACEHOLDER_RE = re.compile(r"\{[a-zA-Z_][a-zA-Z0-9_]*\}")


def fix_value(en_value: str, loc_value: str) -> str:
    en_parts = PLACEHOLDER_RE.split(en_value)
    en_tokens = PLACEHOLDER_RE.findall(en_value)
    if not en_tokens:
        return loc_value

    loc_parts = PLACEHOLDER_RE.split(loc_value)
    if len(loc_parts) != len(en_parts):
        # Rebuild using translated segments where possible.
        loc_parts = loc_parts + [""] * (len(en_parts) - len(loc_parts))

    out = []
    for i, part in enumerate(en_parts):
        if i < len(loc_parts) and loc_parts[i].strip():
            out.append(loc_parts[i])
        elif part:
            out.append(part)
        else:
            out.append(part)
        if i < len(en_tokens):
            out.append(en_tokens[i])
    return "".join(out)


def fix_arb(path: Path, en: dict) -> None:
    data = json.loads(path.read_text(encoding="utf-8"))
    changed = 0
    for key, value in list(data.items()):
        if key.startswith("@") or not isinstance(value, str):
            continue
        en_val = en.get(key)
        if not en_val or not isinstance(en_val, str):
            continue
        fixed = fix_value(en_val, value)
        if fixed != value:
            data[key] = fixed
            changed += 1
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Fixed {changed} entries in {path.name}")


def main() -> None:
    en = json.loads(EN_PATH.read_text(encoding="utf-8"))
    fix_arb(ARB_DIR / "app_gu.arb", en)
    fix_arb(ARB_DIR / "app_pa.arb", en)


if __name__ == "__main__":
    main()
