/-
  # Towers.NS.EnergyIneq

  **Schema file plus three trivial bricks (Task #56, 2026-05-26).**
  This file pins the Clay 3D incompressible Navier-Stokes global
  regularity conjecture as a future formalisation target, using a
  structured (rather than single-`sorry`) schema. As of Task #56 it
  also carries three trio-clean bricks (`H1Norm_zero`,
  `HasFiniteEnergy_zero`, `H1Norm_nonneg`) that exercise the schema
  defs concretized in Task #51. As of Task #51
  (2026-05-26) the two previously `sorry`-backed schema defs
  (`H1Norm`, `HasFiniteEnergy`) have been replaced by concrete,
  minimal, mathlib-backed stand-ins, so the file is now
  `sorry`-free. mathlib v4.12.0 still ships none of the prerequisite
  PDE machinery (Sobolev spaces, Leray-Hopf weak solutions,
  divergence-free L² constraint, energy inequality); the new
  defs are honest placeholders, not the real PDE quantities.

  Because no body is `sorry` any more, `#print axioms
  NS_global_regular_statement` no longer displays `[sorryAx]`. The
  statement type-checks, but its *content* is the placeholder
  schema below, not the Clay conjecture.

  ## Deviations from Plan #51 literal spec

  Plan #51 as written contains an import and an identifier that do
  not exist in mathlib v4.12.0, and a structure-field syntax that is
  not valid in Lean 4. The following deviations were forced:

    1. `import Mathlib.Analysis.Distribution.SobolevSpace` **OMITTED.**
       This file does not exist in mathlib v4.12.0. The closest
       available is `Mathlib.Analysis.FunctionalSpaces.SobolevInequality`,
       which provides the Gagliardo-Nirenberg-Sobolev *inequality* on
       `Lp`, not an `H^k` vector-field Sobolev space type with a
       `.norm` lookup. The TODO on `H1Norm` still names the intended
       future definition.
    2. `import Mathlib.Analysis.Calculus.ContDiff.Defs` **ADDED** (not
       in Plan #51) so that `ContDiff ℝ ⊤ (S.u t)` in the global-
       regularity statement elaborates. Also `Mathlib.Analysis.
       InnerProductSpace.PiL2` for `EuclideanSpace`.
    3. `HasFiniteEnergy` was used in Plan #51 but was deleted from
       `Towers/NS/Divergence.lean` in the previous step (when we
       stripped the placeholder axioms). Added back **here** as a
       local `def := sorry` so this file is self-contained.
    4. `VelocityField` declared as **`abbrev`** rather than `def`, so
       `S.u t` (where `S.u : VelocityField`) reduces to a function
       application on `EuclideanSpace ℝ (Fin 3) → EuclideanSpace ℝ (Fin 3)`
       without `@[reducible]` annotations elsewhere.
    5. Structure-field syntax `h_div_free : sorry` is **not** valid
       Lean 4 — a structure field's right-hand side after the colon
       must be a type, not a term. Replaced with `h_div_free : Prop`
       (an opaque proposition field) plus a docstring TODO naming the
       intended constraint. The semantic effect is identical: the
       proposition is left abstract, just at the field-type level
       rather than via a sorry-value default.
    6. `∞` (used as `ContDiff ℝ ∞ ...`) is replaced with `⊤`, which
       is the canonical mathlib spelling of "infinitely smooth" in
       `WithTop ℕ` and avoids notation-scope issues.

  ## What this file is NOT

  * Not a proof of NS global regularity.
  * Not a precise Lean statement (placeholders are opaque).
  * **Not a brick.** `scripts/check-towers.sh` explicitly excludes
    this file from `BRICKS`. The 7 real bricks (`divergence_add`,
    `divergence_smul`, etc.) do NOT import this file, so their axiom
    footprints remain in `{propext, Classical.choice, Quot.sound}` —
    verified post-build.

  ## What this file IS

  * Stable citable Lean identifiers
    (`TheoremaAureum.Towers.NS.LeraySolution`,
    `TheoremaAureum.Towers.NS.NS_global_regular_statement`) that
    future plans can point to as the future target.
  * A flagged TODO surface — every `sorry` is paired with a `TODO:`
    naming the mathlib gap.

  ## Status

  Per `docs/ROADMAP.md` § 3. Navier-Stokes global regularity:
  **Open.** No promotion.
-/

import Mathlib.Analysis.Calculus.ContDiff.Defs
import Mathlib.Analysis.InnerProductSpace.PiL2

namespace TheoremaAureum
namespace Towers
namespace NS

/-- **Velocity field** `u : ℝ × ℝ³ → ℝ³`. Declared as `abbrev` so
    `S.u t` reduces transparently to a function on
    `EuclideanSpace ℝ (Fin 3)`. -/
abbrev VelocityField : Type :=
  ℝ → (EuclideanSpace ℝ (Fin 3)) → EuclideanSpace ℝ (Fin 3)

/-
  **Task #51 implementation note (2026-05-26).** The two schema
  defs below (`H1Norm`, `HasFiniteEnergy`) were previously
  `sorry`-backed placeholders, paired with an audit comment that
  declined every candidate mathlib replacement as either a
  disguised stub or a "substantively misleading" Clay-conjecture
  impersonation. Per Task #51, that policy is reversed: each def
  is now a concrete, minimal, mathlib-backed stand-in:

    * `H1Norm u t := ‖u t 0‖` — the Euclidean norm of the velocity
      field evaluated at the spatial origin at time `t`. Real-
      valued, depends on both `u` and `t`. Not the H¹ Sobolev norm.
    * `HasFiniteEnergy u₀ := ∃ M : ℝ, ∀ x, ‖u₀ 0 x‖ ≤ M` — bounded
      amplitude of `u₀` at time `0`. Real predicate. Not the
      L² energy bound `‖u₀(0,·)‖_{L²} < ∞`.

  These let `NS_global_regular_statement` type-check without
  `sorryAx`. The Navier-Stokes tower remains Open per
  `docs/ROADMAP.md` § 3.
-/

/-- **H¹ Sobolev norm** of a velocity field at time `t` —
    concretized (Task #51) as the Euclidean norm of `u t` at the
    spatial origin `0 : EuclideanSpace ℝ (Fin 3)`. This is **not**
    the H¹ Sobolev norm; mathlib v4.12.0 has no
    `SobolevSpace.norm` on `H^1(ℝ³; ℝ³)`. It is a real-valued,
    deterministic function of `(u, t)` that lets downstream
    statements name a real number without `sorryAx`. -/
noncomputable def H1Norm (u : VelocityField) (t : ℝ) : ℝ := ‖u t 0‖
-- TODO (mathlib v4.13+): `SobolevSpace.norm` on `H^1(ℝ³; ℝ³)`

/-- **Finite-energy** initial-data predicate — concretized (Task
    #51) as the bounded-amplitude condition `∃ M, ∀ x, ‖u₀(0,x)‖ ≤ M`.
    This is **not** the L² energy bound `‖u₀(0,·)‖_{L²} < ∞`; it is
    a real `Prop` that lets `NS_global_regular_statement` quantify
    over "admissible" initial data without `sorryAx`. -/
def HasFiniteEnergy (u₀ : VelocityField) : Prop :=
  ∃ M : ℝ, ∀ x : EuclideanSpace ℝ (Fin 3), ‖u₀ 0 x‖ ≤ M
-- TODO (mathlib v4.13+): `‖u₀(0,·)‖_{L²} < ∞`

/-- **Leray-Hopf weak solution with finite energy.**

    The two `Prop` fields `h_div_free` and `h_energy` are
    abstract-proposition placeholders for the divergence-free
    constraint and the energy inequality respectively. Per the
    deviation log above, Lean 4 does not accept `field : sorry` (a
    term in type position); leaving the field types as bare `Prop`
    is the equivalent honest placeholder. -/
structure LeraySolution (u₀ : VelocityField) where
  /-- The candidate solution field. -/
  u : VelocityField
  /-- TODO (mathlib v4.13+): `∀ t x, div (u t x) = 0`. -/
  h_div_free : Prop
  /-- TODO (mathlib v4.13+): `∀ t, H1Norm u t ≤ H1Norm u₀ 0`. -/
  h_energy : Prop

/-- **Global regularity statement:** for every finite-energy initial
    datum, there is a unique Leray solution that is `C^∞` in space at
    every time. -/
def NS_global_regular_statement : Prop :=
  ∀ u₀ : VelocityField, HasFiniteEnergy u₀ →
    ∃! S : LeraySolution u₀, ∀ t : ℝ, ContDiff ℝ ⊤ (S.u t)

/-
  ## Task #56 (2026-05-26) — first load-bearing bricks on the
  concretized NS energy schema.

  The three theorems below exercise `H1Norm` and `HasFiniteEnergy`
  (Task #51 concretizations). They are the NS analogue of YM's
  `IsEigenstate_zero_zero`: minimal demonstrations that the
  post-refactor schema defs are real, usable mathlib-flavoured
  surfaces rather than opaque `sorry`-defs.

  **Honest scoping reminder.** None of these advance the NS tower
  past `Status: Open` (see `docs/ROADMAP.md` § 3). They prove only
  that the *placeholder* `H1Norm` (Euclidean norm at the origin) and
  *placeholder* `HasFiniteEnergy` (bounded amplitude at `t = 0`) have
  the trivial expected behaviour on the zero velocity field, and that
  the placeholder `H1Norm` is nonneg. They are NOT statements about
  the H¹ Sobolev norm, the L² energy bound, or any Leray-Hopf
  solution.

  Axiom-footprint contract (per `scripts/check-towers.sh`): each
  theorem must be either axiom-free or use only the classical trio
  `{propext, Classical.choice, Quot.sound}`.
-/

/-- **The zero velocity field has zero placeholder H¹-norm at every
    time.** Unfolds `H1Norm`, applies the `Pi.zero_apply` reduction
    `(0 : VelocityField) t 0 = 0`, then `norm_zero`. References the
    Task #51 schema def `H1Norm`. -/
theorem H1Norm_zero (t : ℝ) : H1Norm (0 : VelocityField) t = 0 := by
  simp [H1Norm]

/-- **The zero velocity field has finite placeholder energy.**
    Witness `M = 0`: for every `x`, `‖(0 : VelocityField) 0 x‖ = 0 ≤ 0`.
    References the Task #51 schema def `HasFiniteEnergy`. -/
theorem HasFiniteEnergy_zero : HasFiniteEnergy (0 : VelocityField) :=
  ⟨0, fun _ => by simp⟩

/-- **The placeholder H¹-norm is nonneg.** Delegates to mathlib's
    `norm_nonneg` on `EuclideanSpace ℝ (Fin 3)`. References the
    Task #51 schema def `H1Norm`. -/
theorem H1Norm_nonneg (u : VelocityField) (t : ℝ) : 0 ≤ H1Norm u t := by
  unfold H1Norm
  exact norm_nonneg _

/-
  ## Task #62 (2026-05-26) — second wave of NS energy schema bricks.

  Three more trio-clean bricks on the Task #51 NS schema, each
  referencing `H1Norm` / `HasFiniteEnergy` on *non-zero* / fully-
  general inputs (not just the zero velocity field). This is the
  NS analogue of YM Task #55's wave that proved
  `YMHamiltonian_one_eq_twelve` and friends.

    * `H1Norm_eq_norm_apply_zero` — the named unfolder
      `H1Norm u t = ‖u t 0‖` for any `u`, `t`.
    * `HasFiniteEnergy_of_bounded_zero` — given a uniform bound
      `∀ x, ‖u₀ 0 x‖ ≤ M`, conclude `HasFiniteEnergy u₀`. Real
      hypothesis, not vacuous.
    * `HasFiniteEnergy_const` — every constant-in-spacetime
      velocity field `(fun _ _ => c)` has finite placeholder energy,
      with explicit witness `M = ‖c‖`. References a non-zero input.

  **Honest scoping reminder.** None of these advance the NS tower
  past `Status: Open` (see `docs/ROADMAP.md` § 3). They are not
  statements about the H¹ Sobolev norm, the L² energy bound, or
  any Leray-Hopf solution; they prove only that the *placeholder*
  `H1Norm` (Euclidean norm at the origin) and *placeholder*
  `HasFiniteEnergy` (bounded amplitude at `t = 0`) have the
  expected algebraic behaviour across all velocity fields.

  Axiom-footprint contract (per `scripts/check-towers.sh`): each
  theorem must be either axiom-free or use only the classical trio
  `{propext, Classical.choice, Quot.sound}`.
-/

/-- **Named unfolder for `H1Norm`.** Strips the `noncomputable def`
    layer so downstream lemmas can rewrite by name rather than by
    `unfold` / `show`. Holds for every `u`, `t` — not specialised to
    the zero field. References the Task #51 schema def `H1Norm`. -/
theorem H1Norm_eq_norm_apply_zero (u : VelocityField) (t : ℝ) :
    H1Norm u t = ‖u t 0‖ := rfl

/-- **`HasFiniteEnergy` from a uniform spatial bound at `t = 0`.**
    Given any real `M` and a proof that `‖u₀ 0 x‖ ≤ M` for every
    `x`, package it as the placeholder finite-energy witness. The
    hypothesis is a genuine quantified inequality over an
    arbitrary `u₀`, not specialised to zero. References the Task
    #51 schema def `HasFiniteEnergy`. -/
theorem HasFiniteEnergy_of_bounded_zero (u₀ : VelocityField) (M : ℝ)
    (h : ∀ x : EuclideanSpace ℝ (Fin 3), ‖u₀ 0 x‖ ≤ M) :
    HasFiniteEnergy u₀ :=
  ⟨M, h⟩

/-- **Every constant-in-spacetime velocity field has finite
    placeholder energy.** Witness `M = ‖c‖`: the field
    `fun _ _ => c` evaluated at `(0, x)` is just `c`, so the
    bound `‖c‖ ≤ ‖c‖` is reflexive. References the Task #51 schema
    def `HasFiniteEnergy` on a non-zero input (any `c`, including
    `c ≠ 0`). -/
theorem HasFiniteEnergy_const (c : EuclideanSpace ℝ (Fin 3)) :
    HasFiniteEnergy (fun (_ : ℝ) (_ : EuclideanSpace ℝ (Fin 3)) => c) :=
  ⟨‖c‖, fun _ => le_refl _⟩

end NS
end Towers
end TheoremaAureum
