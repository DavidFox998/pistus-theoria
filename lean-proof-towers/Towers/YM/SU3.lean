/-
# `Towers.YM.SU3` — the real Lie algebra `su(3)` as anti-Hermitian traceless 3×3 matrices

This file is **Branch C Step 1** of the YM tower work (see
`docs/ROADMAP.md` § 2): foundational algebra bricks for the `su(3)`
Lie algebra of the (eventual) Yang-Mills surface. It introduces the
concrete carrier set

  `su(3) := { A : Matrix (Fin 3) (Fin 3) ℂ | star A = -A ∧ trace A = 0 }`

and proves the three zero-effort bricks that any subsequent
`AddCommGroup` / `Submodule ℝ` / Lie-bracket structure will depend on:

* `su3_lie_algebra_def` — `rfl`-unfolding of the definition.
* `su3_mem_iff_anti_hermitian_traceless` — membership iff the two
  defining conditions.
* `su3_zero_mem` — `0 ∈ su(3)`. Required as the identity element
  for any later additive/module structure on `su(3)`.

The definition is in terms of the underlying matrix ring rather than
a `Subalgebra` / `LieSubalgebra` / `Submodule`, deliberately: each of
those wrappers is layered in a later batch once the membership API
and the closure-under-+/•/[·,·] bricks are in place. Keeping Step 1
to a plain `Set` means the three bricks here are pure `rfl` /
`Iff.rfl` / `simp`-closed terms — trio-clean by inspection, no
research-grade axioms.

## Honest scoping

This file does **not** advance the YM tower past `Status: Open` (see
`docs/ROADMAP.md` § 2). It defines the *carrier set* of the real
`su(3)` Lie algebra and proves the algebra is non-empty. It says
nothing about:

* the Yang-Mills Lagrangian `∫ ‖F_A‖²`,
* the YM Hamiltonian (still a concretized stand-in in
  `Towers.YM.MassGap`; see the Task #51 schema-concretization note),
* the mass-gap conjecture, eigenstates, or any QFT statement.

The downstream goal — replacing the stand-in `YMHamiltonian` in
`MassGap.lean` with a real operator on `L²(su(3))` — needs many more
bricks (the bracket `[·,·]`, the curvature `F_μν = ∂_μ A_ν - ∂_ν A_μ
+ [A_μ, A_ν]`, an `L²` norm on `su(3)`-valued functions, and a
finite-volume lattice discretization). Those land in later batches.
**Until that downstream chain closes with `axioms = []`, the YM
tower stays Open.** This file does not change that.
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Complex.Module

namespace TheoremaAureum
namespace Towers
namespace YM

/-- **The real Lie algebra `su(3)` as a set of 3×3 complex matrices.**

    `A : Matrix (Fin 3) (Fin 3) ℂ` lies in `su(3)` exactly when

      `star A = -A`  (anti-Hermitian)   and   `Matrix.trace A = 0`  (traceless).

    Concretely, the underlying real vector space of the compact Lie
    group `SU(3) = Matrix.specialUnitaryGroup (Fin 3) ℂ` — every
    element of `SU(3)` can be written as `exp (A)` for some
    `A ∈ su(3)`, and the real dimension of `su(3)` is `8` (one for
    each Gell-Mann matrix `i·λ_a / 2`).

    Defined as a plain `Set` rather than a `Submodule ℝ` / `LieSubalgebra`
    so that Step 1's three bricks (`su3_lie_algebra_def`,
    `su3_mem_iff_anti_hermitian_traceless`, `su3_zero_mem`) are all
    `rfl` / `Iff.rfl` / one-line membership proofs. Later batches
    will upgrade this to a `Submodule ℝ` (after closure under
    `+ / • / -` lemmas land), then to a `LieSubalgebra` (after the
    matrix commutator `[A, B] := A * B - B * A` lemmas land).

    Honest scope: this is the *carrier set only*. No additive,
    scalar, or bracket structure is asserted here — those are
    separate bricks in later batches. -/
def su3 : Set (Matrix (Fin 3) (Fin 3) ℂ) :=
  {A | star A = -A ∧ Matrix.trace A = 0}

/-- **Definitional unfolding of `su(3)` (first brick of Branch C Step 1).**

    Stated as a `simp`-friendly `rfl` equation between `su3` and its
    explicit set-builder form. Useful for downstream bricks that
    need to rewrite `A ∈ su3` into the two-conjunct condition
    without going through `Set.mem_setOf_eq` each time.

    Proof: `rfl` — `su3` is *defined* as this set-builder expression.

    Axiom footprint: empty / subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade axioms.

    **Honest scoping reminder.** A definitional equation, not a
    statement about Yang-Mills dynamics. Tower status unchanged: **Open**. -/
theorem su3_lie_algebra_def :
    su3 = {A : Matrix (Fin 3) (Fin 3) ℂ | star A = -A ∧ Matrix.trace A = 0} :=
  rfl

/-- **Membership in `su(3)` iff anti-Hermitian and traceless
    (second brick of Branch C Step 1).**

    For any `A : Matrix (Fin 3) (Fin 3) ℂ`,

      `A ∈ su(3)  ↔  star A = -A  ∧  Matrix.trace A = 0`.

    The forward direction unpacks the set-builder; the reverse
    packs the two conditions back. By `Iff.rfl` because `su3` is
    *defined* via the set-builder `{A | ...}`, and membership in a
    set-builder reduces definitionally to the predicate.

    This is the workhorse unpacker every downstream `su(3)` brick
    will use (closure under `+`, `-`, `•`, `[·,·]`, etc.).

    Axiom footprint: empty / subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade axioms.

    **Honest scoping reminder.** A definitional iff, not a statement
    about Yang-Mills dynamics. Tower status unchanged: **Open**. -/
theorem su3_mem_iff_anti_hermitian_traceless
    (A : Matrix (Fin 3) (Fin 3) ℂ) :
    A ∈ su3 ↔ star A = -A ∧ Matrix.trace A = 0 :=
  Iff.rfl

/-- **The zero matrix is in `su(3)` (third brick of Branch C Step 1).**

    `(0 : Matrix (Fin 3) (Fin 3) ℂ) ∈ su(3)`.

    The two conditions are immediate:

      * `star 0 = 0 = -0`           (`star_zero` + `neg_zero`)
      * `Matrix.trace 0 = 0`        (`Matrix.trace_zero`)

    This is what every later `AddCommGroup` / `AddSubmonoid` /
    `Submodule ℝ` upgrade on `su(3)` needs as its identity element
    — without this brick, the additive structure cannot be witnessed.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (the `simp` close-out
    uses only `star_zero`, `neg_zero`, `Matrix.trace_zero`). No
    research-grade axioms.

    **Honest scoping reminder.** A zero-element fact, not a statement
    about Yang-Mills dynamics. Tower status unchanged: **Open**. -/
theorem su3_zero_mem : (0 : Matrix (Fin 3) (Fin 3) ℂ) ∈ su3 := by
  refine ⟨?_, ?_⟩
  · simp
  · simp

/-! ### Branch C Step 2 — closure of `su(3)` under `+`, `-`, and ℝ-scalars

The four bricks below prove that the carrier set `su3` is closed
under the operations of a real vector space: `+`, `-` (both binary
subtraction and unary negation), and scalar multiplication by `ℝ`.

Together they pin down `su(3)` as a genuine real subspace of
`Matrix (Fin 3) (Fin 3) ℂ`. A subsequent (separate) brick can
bundle them into a `Submodule ℝ` instance, at which point all of
mathlib's `Submodule` API (free `AddCommGroup`, free `Module ℝ`,
`Submodule.span`, etc.) becomes available on the subtype `↥su3`.

Each proof is a 2–3 line rewrite chain:

* `su3_add_mem` — `star_add` + `Matrix.trace_add`.
* `su3_neg_mem` — `star_neg` + `Matrix.trace_neg`.
* `su3_sub_mem` — derived from `add_mem` and `neg_mem`.
* `su3_smul_mem` — `star_smul` + `star_trivial` (for `r : ℝ`,
  `star r = r`) + `Matrix.trace_smul`.

**Honest scoping reminder.** These are algebra closure facts on
the *carrier set* `su3`. They make no claim about Yang-Mills
dynamics, the YM Hamiltonian, the mass-gap conjecture, or any QFT
statement. Tower status remains **Open** in `docs/ROADMAP.md` § 2.
-/

/-- **Closure of `su(3)` under addition (Branch C Step 2 brick 1).**

    If `A` and `B` lie in `su(3)`, so does `A + B`.

    Anti-Hermitian: `star (A + B) = star A + star B = (-A) + (-B)
    = -(A + B)` (via `star_add`, the hypotheses, and `neg_add`).
    Traceless:      `trace (A + B) = trace A + trace B = 0 + 0 = 0`
    (via `Matrix.trace_add` and the hypotheses).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No new axioms. -/
theorem su3_add_mem {A B : Matrix (Fin 3) (Fin 3) ℂ}
    (hA : A ∈ su3) (hB : B ∈ su3) : A + B ∈ su3 := by
  refine ⟨?_, ?_⟩
  · rw [star_add, hA.1, hB.1, neg_add]
  · rw [Matrix.trace_add, hA.2, hB.2, add_zero]

/-- **Closure of `su(3)` under negation (Branch C Step 2 brick 2).**

    If `A` lies in `su(3)`, so does `-A`.

    Anti-Hermitian: `star (-A) = -star A = -(-A)` (via `star_neg`
    and the hypothesis).
    Traceless:      `trace (-A) = -trace A = -0 = 0` (via
    `Matrix.trace_neg` and the hypothesis).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No new axioms. -/
theorem su3_neg_mem {A : Matrix (Fin 3) (Fin 3) ℂ}
    (hA : A ∈ su3) : -A ∈ su3 := by
  refine ⟨?_, ?_⟩
  · rw [star_neg, hA.1]
  · rw [Matrix.trace_neg, hA.2, neg_zero]

/-- **Closure of `su(3)` under subtraction (Branch C Step 2 brick 3).**

    If `A` and `B` lie in `su(3)`, so does `A - B`. Direct corollary
    of `su3_add_mem` and `su3_neg_mem` via `sub_eq_add_neg`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No new axioms. -/
theorem su3_sub_mem {A B : Matrix (Fin 3) (Fin 3) ℂ}
    (hA : A ∈ su3) (hB : B ∈ su3) : A - B ∈ su3 := by
  rw [sub_eq_add_neg]
  exact su3_add_mem hA (su3_neg_mem hB)

/-- **Closure of `su(3)` under ℝ-scalar multiplication
    (Branch C Step 2 brick 4).**

    For any `r : ℝ` and `A ∈ su(3)`, the real-scalar multiple
    `r • A` is again in `su(3)`. The ℝ-module structure on
    `Matrix (Fin 3) (Fin 3) ℂ` comes from `ℂ` being an `ℝ`-algebra
    (via `Mathlib.Data.Complex.Module`), so `r • A` is well-typed.

    Anti-Hermitian: `star (r • A) = star r • star A = r • star A
    = r • (-A) = -(r • A)` (via `star_smul`, `star_trivial` on `ℝ`,
    the hypothesis, and `smul_neg`).
    Traceless:      `trace (r • A) = r • trace A = r • 0 = 0` (via
    `Matrix.trace_smul`, the hypothesis, and `smul_zero`).

    Together with the additive closure bricks, this is the last
    fact needed to upgrade `su3` to a `Submodule ℝ` in a later
    (separate) brick.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No new axioms. -/
theorem su3_smul_mem (r : ℝ) {A : Matrix (Fin 3) (Fin 3) ℂ}
    (hA : A ∈ su3) : r • A ∈ su3 := by
  refine ⟨?_, ?_⟩
  · rw [star_smul, star_trivial, hA.1, smul_neg]
  · rw [Matrix.trace_smul, hA.2, smul_zero]

end YM
end Towers
end TheoremaAureum
