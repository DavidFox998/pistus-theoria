#!/usr/bin/env bash
# check-towers.sh — Build the opt-in Towers Lean library (mathlib-backed
# first bricks for the open towers: RH, BSD, Navier-Stokes,
# Yang-Mills) and verify each named brick's axiom debt is either
# empty or a subset of mathlib's classical core
# {propext, Classical.choice, Quot.sound}.
#
# This script targets the SIBLING package at `lean-proof-towers/`. The
# main spine package `lean-proof/` is deliberately untouched: it stays
# mathlib-free so the fast spine drift guard (`check-lean-proof.sh`)
# keeps running in seconds.
#
# Cost (cold cache, no mathlib oleans on disk):
#   - `lake update` resolves the mathlib v4.12.0 git dep (sources).
#   - `lake exe cache get` downloads ~2 GB of prebuilt mathlib oleans
#     from the Lean community CDN. Typically 5–15 min on a reasonable
#     connection.
#   - `lake build Towers` then compiles the Towers library on top of
#     mathlib. Typically <1 min on warm cache.
#
# Cost (warm cache, mathlib oleans already on disk under
#       `lean-proof-towers/.lake/packages/mathlib/.lake/build/`):
#   - 10–30 seconds total.
#
# Behaviour when `lake` is missing or the cache fetch fails (e.g.
# offline sandbox): exits non-zero with a clear message. There is no
# "soft skip" mode — the towers-build workflow is the canonical place
# to surface mathlib-availability problems.
#
# Adding a new brick:
#   1. Add a `lean_lib` root in `lean-proof-towers/lakefile.lean`.
#   2. Append a pair `"<Towers module>|<fully-qualified theorem>"` to
#      the BRICKS array below. The script will build a tiny verifier
#      file per pair and run the axiom-footprint check.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOWERS_DIR="$REPO_ROOT/lean-proof-towers"
cd "$TOWERS_DIR"

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

# ------------------------------------------------------------------
# Per-brick axiom-footprint check.
#
# Each entry is "<lean import path>|<fully qualified theorem name>".
# The lean import path is the dot-separated module name that mathlib's
# Lean elaborator expects in `import <...>` (e.g. `Towers.RH.ZeroDensity`).
# The theorem name is what `#print axioms` will receive.
#
# Acceptable axiom footprint per brick:
#   (a) truly no axioms ("does not depend on any axioms"), OR
#   (b) a subset of mathlib's classical core
#       {propext, Classical.choice, Quot.sound}.
# Any other axiom name — `sorryAx`, a user-declared `axiom`, etc. —
# is rejected and the script exits non-zero on the first failure.
# ------------------------------------------------------------------
BRICKS=(
  "Towers.RH.ZeroDensity|TheoremaAureum.Towers.RH.N_monotone_in_sigma"
  "Towers.BSD.MordellWeil|TheoremaAureum.Towers.BSD.MordellWeilGroup.add_comm"
  "Towers.BSD.MordellWeil|TheoremaAureum.Towers.BSD.MordellWeilGroup.eq_zero_of_isRankZero"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_add"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_smul"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_zero"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_neg"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_sub"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_const"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_add_const"
  "Towers.NS.Divergence|TheoremaAureum.Towers.NS.divergence_sub_const"
  # NOTE: The six `gauge_action_*` bricks (one_smul, mul_smul,
  # inv_smul, smul_inv, inv_inv, pow_zero) on `TrivialConfiguration`
  # were retired in the 2026-05-26 retirement (Task #50, Option A).
  # The `TrivialConfiguration` scalar action was `· • A := A`, so
  # every `gauge_action_*` lemma reduced definitionally on both
  # sides to `A`, exercising neither group multiplication nor the
  # action — hollow even by trivial-brick standards. Removing them
  # drops the wall from 24 → 18 but enforces the user-locked rule
  # "no `gauge_action_*` on TrivialConfiguration anymore (only real
  # SU(3))" consistently. YM bricks now live exclusively in
  # `Towers.YM.MassGap` against the real `Matrix.specialUnitaryGroup`
  # API. See git history for the withdrawn theorems.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_one_mul"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_unitary"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_det_one"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_mul_one"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_one_one"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_mul_unitary"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_mul_det_one"
  # Task #51 (2026-05-26): the three schema defs `HilbertSpace`,
  # `YMHamiltonian`, `IsEigenstate` in `Towers.YM.MassGap` were
  # concretized from `sorry` to minimal mathlib-backed types
  # (`EuclideanSpace ℂ (Fin 3)`, sum-of-component-traces, scaling-
  # form predicate). The new brick `IsEigenstate_zero_zero` below
  # is the first downstream use proving the schema is no longer
  # dead weight. Same Open status for YM (`docs/ROADMAP.md` § 2).
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.IsEigenstate_zero_zero"
  # 2026-05-26 brick wave (no associated task #; "Shawlocked" walk):
  # extend the trivial-bundle SU(3) laws on connection components.
  # `mul_assoc` completes the standard monoid laws (`one_mul`,
  # `mul_one`, `mul_assoc`). `_component_star_mul_self` is the
  # other side of `_component_unitary` (full two-sided unitary
  # law at the matrix level via `star`). `_component_star_det_one`
  # shows the conjugate-transpose is also det 1, so `star (A i).1`
  # is again in SU(3) — recovering "closed under inverse" content
  # without an `Inv` instance on `specialUnitaryGroup` (which is a
  # `Submonoid` in mathlib v4.12.0, no `Group` instance). Wall:
  # 19 → 22. None advance YM past Status: Open.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_mul_assoc"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_star_mul_self"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.SU3Connection_component_star_det_one"
  # 2026-05-26 Branch C Step 1 (Task #55 continuation): open the real
  # `su(3)` Lie algebra surface as a plain `Set` of anti-Hermitian
  # traceless 3×3 ℂ-matrices in the new file `Towers/YM/SU3.lean`.
  # Three foundation bricks that every later batch (closure under
  # `+/-/•`, bracket `[·,·]`, `L²(su(3))` Hilbert space) will depend
  # on. Wall: 22 → 25. None advance YM past Status: Open — see the
  # honest-scope block at the top of `Towers/YM/SU3.lean`.
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_lie_algebra_def"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_mem_iff_anti_hermitian_traceless"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_zero_mem"
  # Task #55 (2026-05-26): four load-bearing bricks on the now-real
  # YM schema concretized by Task #51 (`HilbertSpace`,
  # `YMHamiltonian`, `IsEigenstate`). Three of them reference at
  # least two of those defs; one references all three. They prove
  # the schema is genuinely load-bearing — e.g. `YMHamiltonian
  # (fun _ => 1) = 12` is the first numerical answer extracted from
  # the def, and `¬ IsEigenstate YMHamiltonian (0 : HilbertSpace)`
  # combines all three. Wall: 25 → 29. YM status still Open.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonian_one_eq_twelve"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.IsEigenstate_zero_const"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.IsEigenstate_of_forall_zero"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonian_not_isEigenstate_zero"
)

VERIFIER_DIR="$(mktemp -d)"
AXIOM_LOG="$(mktemp)"
trap 'rm -f "$AXIOM_LOG"; rm -rf "$VERIFIER_DIR"' EXIT

check_brick() {
  local module="$1"
  local thm="$2"
  local thm_escaped
  thm_escaped="$(printf '%s' "$thm" | sed 's/[.]/\\./g')"

  local verifier="$VERIFIER_DIR/Verify_${thm//./_}.lean"
  cat > "$verifier" <<EOF
import $module
#print axioms $thm
EOF

  echo ">> axiom-debt check: $thm" >&2
  if ! lake env lean "$verifier" 2>&1 | tee "$AXIOM_LOG" >&2; then
    echo "error: lake env lean on verifier for $thm failed." >&2
    return 1
  fi

  local zero_line="'$thm' does not depend on any axioms"
  # Flatten the log first: `#print axioms` wraps long axiom lists across
  # multiple lines, but grep -E does not span lines. Collapsing
  # newlines+whitespace to single spaces lets the regex below match
  # both the single-line case (short axiom names) and the wrapped case
  # (e.g. three classical-trio axioms spread across three lines).
  local flat
  flat="$(tr '\n' ' ' < "$AXIOM_LOG" | tr -s '[:space:]' ' ')"
  local trio_re="'${thm_escaped}' depends on axioms: \[((propext|Classical\.choice|Quot\.sound)(, (propext|Classical\.choice|Quot\.sound)){0,2})\]"

  if grep -qF "$zero_line" "$AXIOM_LOG"; then
    echo "ok: $thm has axiom debt = [] (no axioms used at all)." >&2
  elif printf '%s\n' "$flat" | grep -qE "$trio_re"; then
    echo "ok: $thm axiom footprint = subset of mathlib's classical trio" >&2
    echo "    {propext, Classical.choice, Quot.sound}. No research-grade axioms." >&2
  else
    echo "error: axiom-debt check failed for $thm." >&2
    echo "       Allowed: (a) no axioms at all, or" >&2
    echo "                (b) a subset of {propext, Classical.choice, Quot.sound}." >&2
    echo "       Got:" >&2
    cat "$AXIOM_LOG" >&2
    return 2
  fi
}

for entry in "${BRICKS[@]}"; do
  module="${entry%%|*}"
  thm="${entry#*|}"
  check_brick "$module" "$thm"
done

echo "ok: Towers library built; all ${#BRICKS[@]} brick(s) passed the axiom-footprint check." >&2
