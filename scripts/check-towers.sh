#!/usr/bin/env bash
# check-towers.sh — Build the opt-in Towers Lean library and verify
# axiom debt of the first-brick lemma `N_monotone_in_sigma` is empty.
#
# Cost (cold cache, no mathlib oleans on disk):
#   - `lake exe cache get` downloads ~2 GB of prebuilt mathlib oleans
#     from the Lean community CDN (`lake-packages.azureedge.net`).
#     Typically 5–15 min on a reasonable connection.
#   - `lake build Towers` then compiles the Towers library on top of
#     mathlib. Typically <1 min on warm cache.
#
# Cost (warm cache, mathlib oleans already on disk under
#       `lean-proof/.lake/packages/mathlib/.lake/build/`):
#   - 10–30 seconds total.
#
# This script is intentionally separate from `check-lean-proof.sh`,
# which verifies the structural / axiom-debt drift guard on the spine
# (`TheoremaAureum.main_theorem`, axioms = []) and is allowed to run
# in seconds without mathlib. The two checks together cover:
#   - `check-lean-proof.sh`  — fast spine drift guard (no mathlib)
#   - `check-towers.sh`      — slow Towers build + axiom check (mathlib)
#
# Behaviour when `lake` is missing or `lake update` / `lake exe cache get`
# fail (e.g. offline sandbox): the script exits non-zero with a clear
# message. There is no "soft skip" mode — the towers-build workflow is
# the canonical place to surface mathlib-availability problems.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LEAN_DIR="$REPO_ROOT/lean-proof"
cd "$LEAN_DIR"

if ! command -v lake >/dev/null 2>&1; then
  echo "error: \`lake\` (Lean 4) not on PATH." >&2
  echo "       Install Lean 4 via elan (https://leanprover.github.io/lean4/doc/setup.html)." >&2
  exit 127
fi

echo ">> lake update (resolve mathlib v4.12.0 manifest)" >&2
lake update

echo ">> lake exe cache get (fetch ~2 GB prebuilt mathlib oleans)" >&2
lake exe cache get

echo ">> lake build Towers" >&2
lake build Towers

echo ">> axiom-debt check: TheoremaAureum.Towers.RH.N_monotone_in_sigma" >&2
VERIFIER="$(mktemp -d)/VerifyTowers.lean"
cat > "$VERIFIER" <<'EOF'
import Towers.RH.ZeroDensity
#print axioms TheoremaAureum.Towers.RH.N_monotone_in_sigma
EOF
AXIOM_LOG="$(mktemp)"
trap 'rm -f "$AXIOM_LOG"; rm -rf "$(dirname "$VERIFIER")"' EXIT

if ! lake env lean "$VERIFIER" 2>&1 | tee "$AXIOM_LOG"; then
  echo "error: lake env lean on Towers verifier failed." >&2
  exit 1
fi

EXPECTED="'TheoremaAureum.Towers.RH.N_monotone_in_sigma' does not depend on any axioms"
if ! grep -qF "$EXPECTED" "$AXIOM_LOG"; then
  echo "error: axiom-debt check failed for N_monotone_in_sigma." >&2
  echo "       Expected line: $EXPECTED" >&2
  echo "       Got:" >&2
  cat "$AXIOM_LOG" >&2
  exit 2
fi

echo "ok: Towers library built; N_monotone_in_sigma has axiom debt = []." >&2
