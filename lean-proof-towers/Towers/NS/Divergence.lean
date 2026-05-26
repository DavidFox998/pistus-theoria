/-
  # Towers.NS.Divergence

  **This file does NOT prove Navier-Stokes global regularity, any
  blow-up criterion, or any energy estimate.** It establishes the
  trivial linearity of the divergence operator on smooth vector
  fields and pins the Clay-formulated global-regularity statement
  as a future target.

  Status (cf. `docs/ROADMAP.md` § 3. Navier-Stokes global regularity):

  - `V`                              — abbreviation for the 3D Euclidean
                                        space `EuclideanSpace ℝ (Fin 3)`,
                                        in which we work.
  - `stdBasis i`                     — the `i`-th standard unit vector
                                        of `V`.
  - `divergence v x`                 — minimal definition of the
                                        divergence of a vector field
                                        `v : V → V` at `x : V`, as the
                                        sum of the directional
                                        derivatives along the three
                                        coordinate axes of the
                                        corresponding components.
                                        Built on top of mathlib's
                                        `fderiv`. No fancy distribution
                                        theory; just the elementary
                                        Fréchet derivative.
  - `divergence_add`                 — trivial linearity-under-addition
                                        lemma, **proved**, conditional
                                        on `Differentiable ℝ v` and
                                        `Differentiable ℝ w` (so that
                                        `fderiv_add` applies). Axiom
                                        footprint = subset of mathlib's
                                        classical core
                                        `{propext, Classical.choice,
                                        Quot.sound}`, no research-grade
                                        axioms. (Verified by
                                        `scripts/check-towers.sh`.)
  - `NavierStokes_globalRegularity_statement`
                                     — **statement only.** A schema
                                        for the Clay-formulated 3D
                                        incompressible Navier-Stokes
                                        global-regularity conjecture,
                                        expressed in terms of opaque
                                        placeholder predicates. Closing
                                        it is the open Clay Millennium
                                        Problem.

  **Honest scoping reminder.** This file does **not** advance the NS
  tower past `Status: Open` (see `docs/ROADMAP.md` § 3). It moves NS
  from `Status: Open` to `Status: Open — first brick formalized
  (divergence-linearity in Lean, axiom footprint ⊆ classical trio)`.
  No promotion past `Open`. No claim of any PDE result.

  **Honesty note on the placeholder predicates.** Mathlib v4.12.0
  does not yet ship Sobolev spaces, the Leray projector, the
  Beale-Kato-Majda blow-up criterion, or the 3D incompressible
  Navier-Stokes PDE proper. We therefore cannot state the Clay
  conjecture in its precise classical form. The four placeholders
  `IsSmooth`, `IsDivergenceFree`, `HasFiniteEnergy`, and
  `IsGlobalSmoothSolutionOfNS` are declared as fresh *axioms*
  (opaque constants) at file scope, following the same pattern as
  the BSD brick (`Towers.BSD.MordellWeil`): this keeps
  `NavierStokes_globalRegularity_statement` from being trivially
  provable or trivially refutable by adversarial instantiation, and
  keeps the axioms confined to the schema (they do **not** appear
  in the axiom footprint of `divergence_add`, which is the brick
  verified by `scripts/check-towers.sh`). Closing the schema in its
  current form would itself require new axioms about the
  placeholders, which the surrounding check would catch on any
  derived theorem.
-/

import Mathlib.Analysis.Calculus.FDeriv.Add
import Mathlib.Analysis.Calculus.FDeriv.Mul
import Mathlib.Analysis.InnerProductSpace.EuclideanDist
import Mathlib.Analysis.InnerProductSpace.PiL2

namespace TheoremaAureum
namespace Towers
namespace NS

open scoped BigOperators

/-- 3D Euclidean space, the ambient space for the incompressible
    Navier-Stokes equations on `ℝ³`. -/
abbrev V : Type := EuclideanSpace ℝ (Fin 3)

/-- The `i`-th standard unit vector of `V = EuclideanSpace ℝ (Fin 3)`. -/
noncomputable def stdBasis (i : Fin 3) : V := EuclideanSpace.single i (1 : ℝ)

/-- **Divergence of a vector field on `ℝ³`** (minimal definition).

    For a vector field `v : V → V` and a point `x : V`, the
    divergence is the sum over the three coordinate axes of the
    `i`-th component of the Fréchet derivative `fderiv ℝ v x`
    applied to the `i`-th standard unit vector:

      `(div v)(x) = ∑ i, (Dᵢ v(x))ᵢ`

    This matches the classical definition `div v = ∂₁v₁ + ∂₂v₂ +
    ∂₃v₃` whenever the component partial derivatives exist. We use
    `fderiv` (rather than a coordinate-wise `deriv`) so we can
    invoke `fderiv_add` directly in the linearity lemma below
    without reaching for `Function.partialDeriv` (which mathlib
    v4.12.0 does not provide under that name).

    No multiplicity-of-zero or distributional theory is invoked.
    This is the elementary divergence on smooth vector fields, and
    nothing more. -/
noncomputable def divergence (v : V → V) (x : V) : ℝ :=
  ∑ i : Fin 3, (fderiv ℝ v x (stdBasis i)) i

/-- **Linearity of divergence under addition (trivial brick).**

    For any two `Differentiable ℝ` vector fields `v, w : V → V` and
    any point `x : V`,

      `div (v + w) (x) = div v (x) + div w (x)`.

    The proof is a one-line reduction to mathlib's `fderiv_add`
    plus finite-sum linearity. This lemma is **not** new
    mathematics — it is the trivial linearity of the Fréchet
    derivative wrapped in a divergence-flavoured name so future NS
    plans have a stable hook to invoke instead of dropping into the
    raw `fderiv` API.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms; in
    particular this lemma does **not** depend on any of the
    placeholder axioms `IsSmooth`, `IsDivergenceFree`,
    `HasFiniteEnergy`, or `IsGlobalSmoothSolutionOfNS` declared
    below for the schema. -/
theorem divergence_add (v w : V → V)
    (hv : Differentiable ℝ v) (hw : Differentiable ℝ w) (x : V) :
    divergence (v + w) x = divergence v x + divergence w x := by
  simp only [divergence]
  have hsum : (v + w) = (fun y => v y + w y) := rfl
  rw [hsum, fderiv_add (hv x) (hw x)]
  simp only [ContinuousLinearMap.add_apply, PiLp.add_apply]
  exact Finset.sum_add_distrib

/-- **Linearity of divergence under scalar multiplication (trivial second brick).**

    For any real scalar `c : ℝ`, any `Differentiable ℝ` vector field
    `v : V → V`, and any point `x : V`,

      `div (c • v) (x) = c * div v (x)`.

    The proof is a one-line reduction to mathlib's
    `fderiv_const_smul` plus pulling the constant out of a finite
    sum (`Finset.mul_sum`). This lemma is **not** new mathematics —
    it is the trivial scalar-homogeneity of the Fréchet derivative
    wrapped in a divergence-flavoured name so future NS plans have a
    stable hook to invoke instead of dropping into the raw `fderiv`
    API.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms; in
    particular this lemma does **not** depend on any of the
    placeholder axioms `IsSmooth`, `IsDivergenceFree`,
    `HasFiniteEnergy`, or `IsGlobalSmoothSolutionOfNS` declared
    below for the schema. -/
theorem divergence_smul (c : ℝ) (v : V → V)
    (hv : Differentiable ℝ v) (x : V) :
    divergence (c • v) x = c * divergence v x := by
  simp only [divergence]
  have hsmul : (c • v) = (fun y => c • v y) := rfl
  rw [hsmul, fderiv_const_smul (hv x) c]
  simp only [ContinuousLinearMap.smul_apply, PiLp.smul_apply, smul_eq_mul]
  rw [← Finset.mul_sum]

/-- Placeholder for "the vector field `u` is smooth", in the sense
    required by the Clay statement (typically `C^∞` and Schwartz, or
    at least `H^k` for all `k`).

    **TODO** (open mathlib-scale work, separate from NS itself):
    replace this axiom with the real notion once mathlib defines
    Sobolev spaces and `C^∞` for vector fields on `ℝ³`.

    Declared as a fresh axiom (not as `def ... := True` or
    `def ... := False`) so that `NavierStokes_globalRegularity_statement`
    below is not closeable by instantiating this predicate
    trivially. -/
axiom IsSmooth : (V → V) → Prop

/-- Placeholder for "the vector field `u` is divergence-free", the
    incompressibility constraint of the Navier-Stokes system.

    **TODO**: replace with the real `divergence u = 0` once we
    upgrade `divergence` above to take a function-valued argument
    (rather than a pointwise scalar) and integrate with mathlib's
    eventual PDE machinery.

    Declared as a fresh axiom for the same reason as `IsSmooth`. -/
axiom IsDivergenceFree : (V → V) → Prop

/-- Placeholder for "the initial data `u₀` has finite kinetic
    energy", i.e. `u₀ ∈ L²(ℝ³)`.

    **TODO**: replace with the real `‖u₀‖_{L²} < ∞` once mathlib
    has Bochner integration for vector fields on `ℝ³` set up in a
    convenient form.

    Declared as a fresh axiom for the same reason as `IsSmooth`. -/
axiom HasFiniteEnergy : (V → V) → Prop

/-- Placeholder for "`u : ℝ → V → V` is a global smooth solution of
    the 3D incompressible Navier-Stokes equations with initial data
    `u₀ : V → V`". This is the heart of the Clay statement.

    **TODO**: replace with the real definition once mathlib defines
    (a) the Navier-Stokes operator (`∂_t u + (u · ∇) u - Δ u + ∇p =
    0`, `div u = 0`), (b) the notion of a global-in-time smooth
    solution on `[0, ∞) × ℝ³`, and (c) the matching-initial-data
    condition `u(0, ·) = u₀`.

    Declared as a fresh axiom for the same reason as `IsSmooth`. -/
axiom IsGlobalSmoothSolutionOfNS : (ℝ → V → V) → (V → V) → Prop

/-- **Statement** of the Clay-formulated global-regularity
    conjecture for the 3D incompressible Navier-Stokes equations,
    expressed in terms of the placeholder axioms `IsSmooth`,
    `IsDivergenceFree`, `HasFiniteEnergy`, and
    `IsGlobalSmoothSolutionOfNS`.

    Classical form (see e.g. Fefferman, *Existence and smoothness
    of the Navier-Stokes equation*, Clay Mathematics Institute
    Millennium Problem description, 2000): for every smooth,
    divergence-free, finite-energy initial datum `u₀ : ℝ³ → ℝ³`,
    there exists a global smooth solution
    `u : [0, ∞) × ℝ³ → ℝ³` of the incompressible Navier-Stokes
    equations matching that initial datum.

    Schema form below: for every `u₀ : V → V` satisfying `IsSmooth
    u₀`, `IsDivergenceFree u₀`, and `HasFiniteEnergy u₀`, there
    exists a vector-field-valued function `u : ℝ → V → V` such that
    `IsGlobalSmoothSolutionOfNS u u₀`.

    **Statement only. Do NOT close with `True.intro`, `trivial`,
    `sorry`, or any tautology.** With the four placeholder axioms
    above declared as opaque constants, this schema is not
    closeable by any structural trick — proving or refuting it
    would require new axioms about the placeholders (and the
    surrounding `check-towers.sh` axiom-footprint check would catch
    any such misuse on a derived theorem).

    Proving this — or even stating it precisely — requires both a
    formal Navier-Stokes operator and Sobolev-space machinery in
    mathlib (open mathlib-scale work) and the Clay-NS proof itself
    (a Clay Millennium Problem, open since 2000). The schema below
    is the *future target*, not a theorem. -/
def NavierStokes_globalRegularity_statement : Prop :=
  ∀ u₀ : V → V,
    IsSmooth u₀ → IsDivergenceFree u₀ → HasFiniteEnergy u₀ →
      ∃ u : ℝ → V → V, IsGlobalSmoothSolutionOfNS u u₀

end NS
end Towers
end TheoremaAureum
