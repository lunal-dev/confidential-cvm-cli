#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cli="$repo_root/cc"

bash -n "$cli"

usage_output="$("$cli")"
if ! grep -q "Usage: cc vm <command> \[flags\]" <<<"$usage_output"; then
  echo "Expected default usage to advertise cc vm command shape" >&2
  exit 1
fi

vm_usage_output="$("$cli" vm)"
if ! grep -q "vm verify \[-v|--verbose\]" <<<"$vm_usage_output"; then
  echo "Expected cc vm usage to include vm verify" >&2
  exit 1
fi

info_output="$("$cli" vm info)"
if ! grep -q "^cc:" <<<"$info_output"; then
  echo "Expected cc vm info to print cc version label" >&2
  exit 1
fi

compat_info_output="$("$cli" info)"
if ! grep -q "^cc:" <<<"$compat_info_output"; then
  echo "Expected legacy single-level info command to remain available" >&2
  exit 1
fi

echo "smoke tests passed"
