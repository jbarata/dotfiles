#!/usr/bin/env python3
"""Add stable GUIDs to each note in an Anki .txt export.

Idempotent: re-running preserves existing GUIDs. New rows get a fresh GUID
prepended as the first column. The header is rewritten so Anki recognises
the GUID, tag, and column layout.
"""
from __future__ import annotations

import secrets
import string
import sys
from pathlib import Path

GUID_LEN = 10
ALPHABET = string.ascii_letters + string.digits
DEFAULT_PATH = Path(__file__).resolve().parent.parent / "anki-dotfiles-toolbox.txt"


def looks_like_guid(value: str) -> bool:
    return len(value) == GUID_LEN and all(c in ALPHABET for c in value)


def fresh_guid(taken: set[str]) -> str:
    while True:
        candidate = "".join(secrets.choice(ALPHABET) for _ in range(GUID_LEN))
        if candidate not in taken:
            taken.add(candidate)
            return candidate


def rewrite(path: Path) -> tuple[int, int]:
    lines = path.read_text(encoding="utf-8").splitlines()
    seen: set[str] = set()

    for line in lines:
        if not line or line.startswith("#"):
            continue
        fields = line.split("\t")
        if len(fields) >= 4 and looks_like_guid(fields[0]):
            seen.add(fields[0])

    out: list[str] = []
    header_open = True
    directives_written = False
    added = 0

    def flush_directives() -> None:
        nonlocal directives_written
        if directives_written:
            return
        out.append("#guid column:1")
        out.append("#tags column:4")
        out.append("#columns:guid\tFront\tBack\tTags")
        directives_written = True

    for line in lines:
        if header_open and line.startswith("#"):
            # Skip directives we are about to rewrite; keep the others.
            if line.startswith(("#guid column:", "#tags column:", "#columns:", "#Front")):
                continue
            out.append(line)
            continue

        if header_open:
            flush_directives()
            header_open = False

        if not line.strip() or line.startswith("#"):
            out.append(line)
            continue

        fields = line.split("\t")
        if len(fields) >= 4 and looks_like_guid(fields[0]):
            out.append(line)
            continue

        guid = fresh_guid(seen)
        out.append(f"{guid}\t{line}")
        added += 1

    if header_open:
        flush_directives()

    path.write_text("\n".join(out) + "\n", encoding="utf-8")
    return added, len(seen)


def main(argv: list[str]) -> int:
    path = Path(argv[1]) if len(argv) > 1 else DEFAULT_PATH
    if not path.exists():
        print(f"File not found: {path}", file=sys.stderr)
        return 1
    added, total = rewrite(path)
    print(f"{path}: added {added} GUID(s); total notes now {total}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
