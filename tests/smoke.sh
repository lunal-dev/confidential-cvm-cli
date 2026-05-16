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

# Test InferenceProvider jq queries resolve correctly for all three provider keys
tmp_oc=$(mktemp)
trap 'rm -f "$tmp_oc"' EXIT

# confai key (new, highest priority)
printf '{"models":{"providers":{"confai":{"baseUrl":"https://confai.example.com","apiKey":"tok-confai"}}}}' > "$tmp_oc"
got_endpoint=$(jq -r '.models.providers.confai.baseUrl // .models.providers.confidential.baseUrl // .models.providers.lunal.baseUrl // "not configured"' "$tmp_oc")
got_apikey=$(jq -r '.models.providers.confai.apiKey // .models.providers.confidential.apiKey // .models.providers.lunal.apiKey // empty' "$tmp_oc")
if [ "$got_endpoint" != "https://confai.example.com" ] || [ "$got_apikey" != "tok-confai" ]; then
  echo "FAIL: confai provider key not resolved (endpoint=$got_endpoint apikey=$got_apikey)" >&2; exit 1
fi

# confidential key (legacy fallback #1)
printf '{"models":{"providers":{"confidential":{"baseUrl":"https://conf.example.com","apiKey":"tok-conf"}}}}' > "$tmp_oc"
got_endpoint=$(jq -r '.models.providers.confai.baseUrl // .models.providers.confidential.baseUrl // .models.providers.lunal.baseUrl // "not configured"' "$tmp_oc")
got_apikey=$(jq -r '.models.providers.confai.apiKey // .models.providers.confidential.apiKey // .models.providers.lunal.apiKey // empty' "$tmp_oc")
if [ "$got_endpoint" != "https://conf.example.com" ] || [ "$got_apikey" != "tok-conf" ]; then
  echo "FAIL: confidential provider key not resolved (endpoint=$got_endpoint apikey=$got_apikey)" >&2; exit 1
fi

# lunal key (legacy fallback #2)
printf '{"models":{"providers":{"lunal":{"baseUrl":"https://lunal.example.com","apiKey":"tok-lunal"}}}}' > "$tmp_oc"
got_endpoint=$(jq -r '.models.providers.confai.baseUrl // .models.providers.confidential.baseUrl // .models.providers.lunal.baseUrl // "not configured"' "$tmp_oc")
got_apikey=$(jq -r '.models.providers.confai.apiKey // .models.providers.confidential.apiKey // .models.providers.lunal.apiKey // empty' "$tmp_oc")
if [ "$got_endpoint" != "https://lunal.example.com" ] || [ "$got_apikey" != "tok-lunal" ]; then
  echo "FAIL: lunal provider key not resolved (endpoint=$got_endpoint apikey=$got_apikey)" >&2; exit 1
fi

# no matching key → "not configured"
printf '{"models":{"providers":{}}}' > "$tmp_oc"
got_endpoint=$(jq -r '.models.providers.confai.baseUrl // .models.providers.confidential.baseUrl // .models.providers.lunal.baseUrl // "not configured"' "$tmp_oc")
if [ "$got_endpoint" != "not configured" ]; then
  echo "FAIL: missing provider key should return 'not configured' (got: $got_endpoint)" >&2; exit 1
fi

echo "smoke tests passed"
