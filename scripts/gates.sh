#!/usr/bin/env bash
# Runs the checks of AGENTS.md; CI and the toolchain canary run this script, so
# the three cannot drift. Run `moon fmt` first: this only checks formatting.
set -euo pipefail
cd "$(dirname "$0")/.."

run() { echo "+ $*"; "$@"; }

run moon fmt --check
run moon check --target wasm --deny-warn
run moon test --target wasm
run moon build --target wasm --release
run moon check --target native --deny-warn
run moon test --target native
run moon build --target native
run moon run --target native . -- --help
run moon run scripts/docs_audit.mbtx
run moon info
# Only meaningful in CI: in a jj working copy `git diff` compares against the
# parent change, so uncommitted edits would look stale. Set CHECK_MBTI=1 to
# enforce locally.
if [ "${CI:-}" = true ] || [ "${CHECK_MBTI:-}" = 1 ]; then
  git diff --exit-code -- '*.mbti' || {
    echo "pkg.generated.mbti is stale: run 'moon info' and commit" >&2
    exit 1
  }
fi
echo "gates: OK"
