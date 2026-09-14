#!/usr/bin/env python3
"""Validate all YAML and JSON files tracked by git.

Exit 0 if every file parses; exit 1 with a printed list of offenders.
Included in CI (`config-lint`) because a broken GitHub Actions YAML fails
*silently* (GitHub just reports "no workflow"), which is hard to notice.
"""
import json
import subprocess
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML is required (pip install pyyaml / apt python3-yaml)")
    sys.exit(2)


def tracked_files():
    out = subprocess.run(
        ["git", "ls-files"], capture_output=True, text=True, check=True
    ).stdout.splitlines()
    return [Path(f) for f in out if Path(f).suffix in {".yml", ".yaml", ".json"}]


def main() -> int:
    failures = []
    files = tracked_files()
    if not files:
        print("No YAML/JSON files tracked yet — nothing to validate.")
        return 0
    for path in files:
        try:
            text = path.read_text(encoding="utf-8")
            if path.suffix == ".json":
                json.loads(text)
            else:
                yaml.safe_load(text)
        except Exception as e:  # noqa: BLE001 — report first parse error per file
            failures.append(f"{path}: {e}")
    if failures:
        print("Invalid files:")
        print("\n".join(failures))
        return 1
    print(f"OK: {len(files)} YAML/JSON file(s) valid.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
