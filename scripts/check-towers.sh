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

# `lake update` is INTENTIONALLY skipped when the manifest + package
# working trees are already in place. In this environment the mathlib
# (and batteries / aesop / Qq / proofwidgets / ...) packages under
# `.lake/packages/` are committed as plain working trees WITHOUT their
# own `.git/` directories (Lake's git-dep clones were checked into the
# repo as files, not as nested git repos). Running `lake update` against
# such a tree makes Lake try to `git fetch` / `git checkout` inside a
# directory that has no `.git`, which in practice wipes
# `lakefile.lean` and leaves `HEAD` dangling — every subsequent
# `lake build` then fails with "could not resolve 'HEAD'".
#
# `lake-manifest.json` is committed and pins every transitive dep to
# an exact revision, so as long as the package directories exist we
# do NOT need `lake update` to resolve anything; `lake build` reads
# the manifest directly. Only fall back to `lake update` if mathlib
# is genuinely missing (fresh checkout that, for whatever reason,
# does not have the vendored package trees).
if [ -f ".lake/packages/mathlib/lakefile.lean" ]; then
  echo ">> lake update: SKIPPED (vendored mathlib working tree already present;" >&2
  echo "   manifest is pinned at lake-manifest.json. Running \`lake update\` here" >&2
  echo "   would wipe the .git-less mathlib working tree — see comment in" >&2
  echo "   scripts/check-towers.sh for the full story.)" >&2
else
  echo ">> lake update (resolve mathlib v4.12.0 manifest — vendored tree missing)" >&2
  lake update
fi

# `lake exe cache get` does a `git fetch` inside every dep package
# (batteries, aesop, importGraph, …). On this sandbox those package
# .git directories have repeatedly been observed to lose their object
# packs while the working tree + .lake/build oleans remain intact,
# causing `cache get` to fail with "could not resolve 'HEAD'" even
# though no fetch is actually needed. If the mathlib olean tree is
# already populated locally, skip the fetch entirely; otherwise run
# `cache get` as before. Either way, `lake build` below reads the
# manifest directly and uses the on-disk oleans.
# NB: avoid `find … | head -N | wc -l` here — under `set -o pipefail`
# the SIGPIPE from `head` closing early makes `find` exit non-zero and
# kills the whole script. We just need a "are there many oleans?" probe,
# not an exact count; check for one well-known olean path instead.
MATHLIB_OLEAN_PRESENT=0
if [ -f ".lake/packages/mathlib/.lake/build/lib/Mathlib.olean" ] \
   || [ -f ".lake/packages/mathlib/.lake/build/lib/Mathlib/Init.olean" ]; then
  MATHLIB_OLEAN_PRESENT=1
fi
if [ "$MATHLIB_OLEAN_PRESENT" = "1" ]; then
  echo ">> lake exe cache get: SKIPPED (mathlib oleans already on disk)" >&2
else
  echo ">> lake exe cache get (fetch ~2 GB prebuilt mathlib oleans)" >&2
  lake exe cache get
fi

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
  # 2026-05-26 Branch C Step 2 (Task #55 continuation): closure of
  # `su(3)` under +, -, and ℝ-scalars. Together with `su3_zero_mem`
  # from Step 1, these four are the algebra-closure facts needed
  # to upgrade `su3` to a `Submodule ℝ` in a later (separate)
  # brick. Wall: 29 → 33. None advance YM past Status: Open — see
  # the `### Branch C Step 2` section header in `Towers/YM/SU3.lean`.
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_add_mem"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_neg_mem"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_sub_mem"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_smul_mem"
  # 2026-05-26 Branch C Step 2.5: bundle the Step 2 closure lemmas
  # into a real `Submodule ℝ` (`su3_submodule`), add the carrier
  # unpacker, and ratify the two mathlib-derived typeclass
  # instances (`AddCommGroup ↥su3_submodule`, `Module ℝ ↥su3_submodule`)
  # under named handles so the axiom-footprint check pins them.
  # Wall: 36 → 40. None advance YM past Status: Open — these are
  # algebra-bundling moves, not YM dynamics. The next batch (a
  # separate brick wave) adds an `InnerProductSpace ℝ ↥su3_submodule`
  # so we can build `L²(Fin n, ↥su3_submodule)` on a finite lattice.
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_submodule"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.su3_submodule_mem_iff"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.instance_addcommgroup_su3"
  "Towers.YM.SU3|TheoremaAureum.Towers.YM.instance_module_real_su3"
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
  # Task #56 (2026-05-26): first load-bearing bricks on the NS energy
  # schema concretized by Task #51 (`H1Norm`, `HasFiniteEnergy` in
  # `Towers/NS/EnergyIneq.lean`). NS analogue of YM's
  # `IsEigenstate_zero_zero`: zero velocity field has zero placeholder
  # H¹-norm, has finite placeholder energy, and the placeholder
  # H¹-norm is nonneg. NS tower status unchanged: Open
  # (`docs/ROADMAP.md` § 3). These are NOT statements about the H¹
  # Sobolev norm, the L² energy bound, or any Leray-Hopf solution.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.H1Norm_zero"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_zero"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.H1Norm_nonneg"
  # Task #62 (2026-05-26): second wave of NS energy schema bricks
  # on the Task #51 concretizations of `H1Norm` / `HasFiniteEnergy`,
  # this time referencing fully-general / non-zero inputs (not just
  # the zero velocity field). NS analogue of the YM Task #55 wave:
  # `H1Norm_eq_norm_apply_zero` is the named unfolder for arbitrary
  # `(u, t)`; `HasFiniteEnergy_of_bounded_zero` packages any uniform
  # `∀ x, ‖u₀ 0 x‖ ≤ M` bound into the placeholder finite-energy
  # witness; `HasFiniteEnergy_const` proves every constant-in-
  # spacetime field `(fun _ _ => c)` has finite placeholder energy
  # via `M = ‖c‖`. NS tower status unchanged: Open
  # (`docs/ROADMAP.md` § 3). These are NOT statements about the H¹
  # Sobolev norm, the L² energy bound, or any Leray-Hopf solution.
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.H1Norm_eq_norm_apply_zero"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_of_bounded_zero"
  "Towers.NS.EnergyIneq|TheoremaAureum.Towers.NS.HasFiniteEnergy_const"
  # Task #55 (Branch A witness, 2026-05-26): infinite-dimensionality
  # witness for `HilbertSpace = lp (fun _ : ℕ => ℂ) 2`. The canonical
  # `lp.single`-at-`1` family indexed by ℕ is orthonormal (norm-one
  # from `lp.norm_single`; pairwise inner zero from
  # `lp.inner_single_left` + `lp.single_apply_ne`), hence linearly
  # independent, hence `HilbertSpace` is NOT finite-dimensional over
  # ℂ (via `Module.Finite.not_linearIndependent_of_infinite`). Three
  # bricks: the family def, the orthonormality theorem, and the
  # non-finite-dim conclusion. Her tri-parallel ask included two
  # other branches (`SymmetricFockSpace` over `L² ⊗ su(3)`; subtype
  # `{f // MemLp f 2 volume}`); neither is landable on mathlib
  # v4.12.0 — Fock-space machinery absent; the raw `MemLp`-subtype
  # is only a semi-inner-product (no a.e.-quotient). So this lands
  # the witness on the existing ∞-dim ℓ²(ℕ,ℂ) carrier. YM tower
  # status unchanged: Open (`docs/ROADMAP.md` § 2). This brick says
  # NOTHING about the YM physical-state Hilbert space.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.hilbertCanonicalFamily"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.hilbertCanonicalFamily_orthonormal"
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.HilbertSpace_not_finiteDimensional"

  # ---------------------------------------------------------------
  # Task #56 Path B batch 1 (2026-05-26): the 8 anti-Hermitian
  # Gell-Mann generators `iλ₁ … iλ₈` of su(3), each proven to lie in
  # `su3_submodule`. Unnormalised `iλ₈ = diag(I, 0, -I)` (no √3)
  # chosen so every membership proof closes via
  # `ext + fin_cases + simp` on the matrix-literal unfolders +
  # `Complex.conj_I`. These are the foundation for batch 2
  # (`su3_basis_def` via `Basis.ofEquivFun`, plus
  # `su3_basis_linearIndependent` and `su3_basis_spans` as 1-line
  # `.linearIndependent` / `.span_eq` wrappers) and batch 3
  # (`instance_inner_product_space_su3_euclidean` via
  # `InnerProductSpace.Core`). The bricks claim ONLY:
  # anti-Hermitian + traceless. No statement about YM dynamics, the
  # YM Hamiltonian, or the mass-gap conjecture. YM tower status
  # remains **Open** (`docs/ROADMAP.md` § 2).
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₁_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₂_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₃_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₄_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₅_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₆_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₇_mem"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.gellMann₈_mem"
  # Task #61 (2026-05-26): the first *uniform* `∀ A, _ ≤ _` bound on
  # the YM Hamiltonian schema. Proves `|YMHamiltonian A| ≤ 12` by
  # bounding each diagonal entry of an SU(3) matrix by 1 (rows of a
  # unitary matrix are unit vectors), hence `|trace.re| ≤ 3` per
  # component, hence `≤ 4 · 3 = 12` summed. Genuine inequality, not
  # a point value or contradiction. YM tower status unchanged: Open
  # (`docs/ROADMAP.md` § 2). Still a bound on the placeholder
  # sum-of-traces schema, NOT the YM field energy.
  "Towers.YM.MassGap|TheoremaAureum.Towers.YM.YMHamiltonian_abs_le_twelve"
  # Task #56 Path B batch 2 v2 (2026-05-26): the explicit
  # `↥su3_submodule ≃ₗ[ℝ] (Fin 8 → ℝ)` equiv, the Gell-Mann basis
  # packaging via `Basis.ofEquivFun`, plus the linear-independence
  # and span_eq theorems. Concrete `toFun`/`invFun` pair avoids the
  # `LinearMap.smulRight` combinator chain that exceeded mathlib's
  # heartbeat budget in v1; `set_option maxHeartbeats 4000000` covers
  # the 9-entry × 2-component matrix-equality elaboration in
  # `left_inv`. Bricks 5+6 (NormedSpace/InnerProductSpace instances)
  # deferred to Path B batch 3 — `InnerProductSpace.induced` does not
  # exist in mathlib v4.12.0, so batch 3 must build the structure via
  # `InnerProductSpace.Core` pulled back through the equiv.
  # YM tower status unchanged: Open (`docs/ROADMAP.md` § 2).
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.su3_equiv_fin8_def"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.su3_basis_def"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.su3_basis_linearIndependent"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.su3_basis_spans"
  # Task #56 Path B batch 3 (2026-05-26): the `InnerProductSpace.Core
  # ℝ ↥su3_submodule`, built by hand because mathlib v4.12.0 has no
  # `InnerProductSpace.induced` (only `InnerProductSpace.ofCore`).
  # Six bricks: (1) `inner_su3` — the Euclidean inner product on
  # `↥su3_submodule` pulled back through `su3_equiv_fin8_def`;
  # (2) `norm_su3` — `Real.sqrt (inner_su3 x x)`; (3) `conj_symm`,
  # (4) `add_left`, (5) `smul_left` — the three algebraic axioms an
  # `InnerProductSpace.Core` field over ℝ needs; (6)
  # `instance_inner_product_space_su3_core` — the packaged Core
  # record (inner + conj_symm + nonneg_re + definite + add_left +
  # smul_left), NOT registered as a global `instance` to avoid
  # constraining downstream lattice-YM bricks that may want a
  # different normalisation. This is the unnormalised Gell-Mann
  # coordinate inner product (no `1/√3` on λ₈, no `tr(A* B)/2`); it
  # is *a* real inner product on the 8-dim ℝ-vector space, NOT the
  # physics-normalised Killing form / Frobenius inner product. YM
  # tower status unchanged: Open (`docs/ROADMAP.md` § 2).
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.inner_su3"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.norm_su3"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.inner_su3_conj_symm"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.inner_su3_add_left"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.inner_su3_smul_left"
  "Towers.YM.SU3Basis|TheoremaAureum.Towers.YM.instance_inner_product_space_su3_core"
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
