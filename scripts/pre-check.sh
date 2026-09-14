#!/usr/bin/env bash
# Local pre-check mirror of CI. Run before every push.
set -euo pipefail
cd "$(dirname "$0")/.."
mapfile -t sh_files < <(find host scripts -type f -name '*.sh' -print)

if ((${#sh_files[@]} > 0)); then
	echo ':: shfmt ::'
	shfmt -d "${sh_files[@]}"
	echo ':: shellcheck ::'
	shellcheck --severity=warning "${sh_files[@]}"
else
	echo ':: shell lint :: no shell scripts found, skipping'
fi

echo ':: configs ::'
python3 scripts/validate-configs.py
echo 'All local checks passed.'
