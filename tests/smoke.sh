#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cli="$repo_root/ccvm"

bash -n "$cli"
bash -n "$repo_root/install.sh"

usage_output="$("$cli")"
if ! grep -q "Usage: ccvm <command> \[flags\]" <<<"$usage_output"; then
  echo "Expected default usage to advertise ccvm command shape" >&2
  exit 1
fi
if grep -q "cc vm" <<<"$usage_output"; then
  echo "Expected default usage not to advertise cc vm command shape" >&2
  exit 1
fi

compat_usage_output="$("$cli" vm)"
if ! grep -q "verify \[-v|--verbose\]" <<<"$compat_usage_output"; then
  echo "Expected compat vm usage to include verify" >&2
  exit 1
fi

info_output="$("$cli" info)"
if ! grep -q "^ccvm:" <<<"$info_output"; then
  echo "Expected ccvm info to print ccvm version label" >&2
  exit 1
fi

compat_info_output="$("$cli" vm info)"
if ! grep -q "^ccvm:" <<<"$compat_info_output"; then
  echo "Expected legacy vm info command to remain available" >&2
  exit 1
fi

echo "smoke tests passed"
