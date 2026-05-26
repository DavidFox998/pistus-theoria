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

end YM
end Towers
end TheoremaAureum
