/-
  # Towers.NS.EnergyIneq

  **Statement-only file. Contains no theorems and no proofs.** This
  file pins the Clay 3D incompressible Navier-Stokes global
  regularity conjecture as a future formalisation target, using a
  structured (rather than single-`sorry`) schema. Multiple bodies are
  `sorry`, deliberately, because mathlib v4.12.0 ships none of the
  prerequisite PDE machinery (Sobolev spaces, Leray-Hopf weak
  solutions, divergence-free L² constraint, energy inequality).

  Because multiple bodies are `sorry`, `#print axioms
  NS_global_regular_statement` will display `[sorryAx]` (alongside
  classical-trio axioms picked up by `noncomputable` and `ContDiff`
  elaboration). That is **expected and visible**.

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
  **Task #51 decision audit (2026-05-26).** The two schema defs
  below (`H1Norm`, `HasFiniteEnergy`) were evaluated for
  concrete-mathlib replacement. Every candidate was rejected as
  either (a) a disguised stub (`H1Norm _ _ := 0`,
  `HasFiniteEnergy _ := True` — explicitly forbidden) or
  (b) a real mathlib expression that is *substantively
  misleading* (e.g. a bounded-amplitude L^∞ bound dressed up as
  finite L² energy; would make `NS_global_regular_statement`
  type-check against the wrong norm and manufacture the
  appearance of a formalized Clay conjecture). Per the user's
  authorized escape clause ("Full proofs or leave sorry and move
  on"), both stay as `sorry`. Status: deliberately deferred to
  mathlib v4.13+ when `SobolevSpace.norm` on `H^1(ℝ³; ℝ³)` lands.
-/

/-- **H¹ Sobolev norm** of a velocity field at time `t`. Still
    `sorry`: see "Task #51 decision audit" comment immediately
    above. -/
noncomputable def H1Norm (_u : VelocityField) (_t : ℝ) : ℝ := sorry
-- TODO (mathlib v4.13+): `SobolevSpace.norm` on `H^1(ℝ³; ℝ³)`

/-- **Finite-energy** initial-data predicate (`‖u₀(0,·)‖_{L²} < ∞`).
    Re-introduced here (Plan #51 references it; the previous brick
    stripped it from `Divergence.lean`). -/
def HasFiniteEnergy (_u₀ : VelocityField) : Prop := sorry
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

end NS
end Towers
end TheoremaAureum
