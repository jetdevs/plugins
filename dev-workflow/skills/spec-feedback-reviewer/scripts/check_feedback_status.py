#!/usr/bin/env python3

import argparse
from pathlib import Path


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate that all feedback bullets are prefixed with a required status (e.g. UNRESOLVED:)."
    )
    parser.add_argument("path", help="Path to feedback markdown file")
    parser.add_argument(
        "--prefix",
        default="UNRESOLVED:",
        help="Required status prefix (default: UNRESOLVED:)",
    )
    args = parser.parse_args()

    path = Path(args.path)
    prefix = str(args.prefix)

    text = path.read_text(encoding="utf-8")
    bad_lines: list[tuple[int, str]] = []
    for line_no, line in enumerate(text.splitlines(), 1):
        if line.startswith("- ") and prefix not in line:
            bad_lines.append((line_no, line))

    if not bad_lines:
        print(f"OK: all bullet items include {prefix!r} ({path})")
        return 0

    print(f"FAIL: {len(bad_lines)} bullet item(s) missing {prefix!r} ({path})")
    for line_no, line in bad_lines[:50]:
        print(f"{line_no}: {line}")
    if len(bad_lines) > 50:
        print(f"... ({len(bad_lines) - 50} more)")
    return 1


if __name__ == "__main__":
    raise SystemExit(main())
