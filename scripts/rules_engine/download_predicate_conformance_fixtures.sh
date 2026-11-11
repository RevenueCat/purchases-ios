#!/usr/bin/env bash
set -euo pipefail

khepri_ref="${1:?A full Khepri commit SHA is required}"
destination="${2:?A destination file is required}"
if [[ ! "$khepri_ref" =~ ^[0-9a-f]{40}$ ]]; then
  echo 'Expected a full Khepri commit SHA' >&2
  exit 1
fi

checkout_dir="$(mktemp -d)"
trap 'rm -rf "$checkout_dir"; rm -f "${download_file:-}"' EXIT
git init -q "$checkout_dir"
git -C "$checkout_dir" fetch -q --depth 1 git@github.com:RevenueCat/khepri.git "$khepri_ref"
git -C "$checkout_dir" show FETCH_HEAD:khepri/services/audience/fixtures/predicate_conformance_v1.json > "$checkout_dir/cases.json"
python3 - "$checkout_dir/cases.json" <<'PY'
import json
import sys

with open(sys.argv[1]) as source:
    payload = json.load(source)
if payload.get('schema_version') != 1 or payload.get('kind') != 'audience_predicate':
    raise SystemExit('Unsupported conformance fixture format')
cases = payload.get('fixtures')
if not isinstance(cases, list) or not cases:
    raise SystemExit('Expected nonempty conformance cases')
print(f'Downloaded {len(cases)} Khepri conformance cases')
PY
mkdir -p "$(dirname "$destination")"
download_file="$(mktemp "${destination}.XXXXXX")"
cp "$checkout_dir/cases.json" "$download_file"
mv "$download_file" "$destination"
