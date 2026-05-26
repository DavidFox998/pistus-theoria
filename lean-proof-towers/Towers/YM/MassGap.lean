/-
  # Towers.YM.MassGap

  **Mostly-statement file. As of the Task #51 + Task #55 merge
  (2026-05-26) all three previously `sorry`-backed schema defs
  (`HilbertSpace`, `YMHamiltonian`, `IsEigenstate`) have been
  replaced by concrete, mathlib-backed types** so the file is now
  `sorry`-free.

  Task #55 (Branch A) upgraded `HilbertSpace` to `lp (fun _ : ℕ
  => ℂ) 2`, the canonical separable infinite-dim ℓ²(ℕ,ℂ). Task
  #51 concretized `YMHamiltonian` as `∑ i : Fin 4, ((A
  i).1).trace.re` and `IsEigenstate H ψ` as `∃ μ : ℝ, ∀ A, H A =
  μ * (‖ψ‖ * ‖ψ‖)`. The schema is still **not** the real Clay
  Yang-Mills surface (no Wightman axioms, no Sobolev spaces, no
  trace-of-the-curvature-2-form, no Osterwalder–Schrader
  reconstruction). It is a typed, inhabited stand-in whose only
  purpose is to let downstream bricks reference a Hilbert space,
  a real-valued "Hamiltonian" function on `SU3Connection`, and
  an eigenstate predicate without tripping over `sorryAx`. This
  file pins the Clay Yang-Mills mass-gap conjecture as a future
  formalisation target, using a structured (rather than
  single-`sorry`) schema.

  The seven trio-clean SU(3) bricks proved below are:
  `SU3Connection_one_mul`, `SU3Connection_component_unitary`,
  `SU3Connection_component_det_one`, `SU3Connection_mul_one`,
  `SU3Connection_one_one`, `SU3Connection_component_mul_unitary`,
  `SU3Connection_component_mul_det_one`. Each is real SU(3)
  monoid / submonoid algebra (no `TrivialConfiguration` shortcut)
  with axiom footprint a subset of `{propext, Classical.choice,
  Quot.sound}`. None of them advances the YM tower past
  `Status: Open` (see `docs/ROADMAP.md` § 2); they are foundation
  bricks under the schema, not Millennium claims.

  ## Status of the schema after the Plan #52 MassGap refactor

  As of this refactor, the previously-opaque `SU3Connection : Type
  := sorry` has been replaced by a **concrete, sorry-free type**:

      abbrev SU3Connection : Type :=
        Fin 4 → Matrix.specialUnitaryGroup (Fin 3) ℂ

  This is the **trivial-bundle constant-coefficient case** of an
  SU(3) gauge connection on `ℝ⁴`: four constant SU(3)-valued fields,
  one per spacetime direction. It is **not** a connection on a
  non-trivial principal bundle — that would need
  `Mathlib.Geometry.Manifold.VectorBundle.Basic` and a `Connection`
  type, neither of which is plumbed up to where we need them in
  mathlib v4.12.0. But it is a real, inhabited, sorry-free type
  that future YM bricks can prove things about, using the real
  `Matrix.specialUnitaryGroup` API from
  `Mathlib/LinearAlgebra/UnitaryGroup.lean`.

  **Correction to a prior internal note.** An earlier comment in
  this file (and in a planning message) claimed
  `Mathlib.LinearAlgebra.Matrix.SpecialUnitaryGroup` was missing
  from mathlib v4.12.0. That was *technically* correct (no file by
  that name) but *substantively misleading*: `Matrix.specialUnitaryGroup`
  itself **does exist**, as an `abbrev` in
  `Mathlib/LinearAlgebra/UnitaryGroup.lean` (line 180):

      abbrev specialUnitaryGroup := unitaryGroup n α ⊓ MonoidHom.mker detMonoidHom

  This refactor uses it directly. The earlier "OMITTED" line about
  the SpecialUnitaryGroup file is preserved below for historical
  honesty, with a corrected pointer to where the type actually lives.

  ## Concretized schema defs (NOT the Clay surface)

    * `HilbertSpace      := lp (fun _ : ℕ => ℂ) 2`
    * `YMHamiltonian A   := ∑ i : Fin 4, ((A i).1).trace.re`
    * `IsEigenstate H ψ  := ∃ μ : ℝ, ∀ A, H A = μ * (‖ψ‖ * ‖ψ‖)`

  These are honest, mathlib-backed stand-ins, not the Clay
  surface. `HilbertSpace` is ℓ²(ℕ,ℂ) — a real separable
  infinite-dim complex Hilbert space, but NOT the Osterwalder–
  Schrader-reconstructed YM physical state space (which does not
  exist in mathlib v4.12.0 and is itself open research).
  `YMHamiltonian` is a sum of traces of connection components,
  NOT `∫ tr(F_A ∧ ★F_A)`. `IsEigenstate` is a quantitative
  scaling predicate that captures the *form* of "H has constant
  value μ‖ψ‖² on every connection", NOT the spectral-eigenvector
  property of an operator on the physical Hilbert space.

  Because these defs are now concrete (no `sorry`), `#print axioms
  YM_mass_gap_statement` no longer displays `[sorryAx]`. The statement
  type-checks, but its *content* is the placeholder above — not the
  Clay conjecture. `YM_mass_gap_statement` remains NOT a brick, is
  NOT in `scripts/check-towers.sh BRICKS`, and is NOT imported by
  any of the bricks that ARE in BRICKS.

  ## What this file IS now (post-refactor)

  * Seven real trio-clean SU(3) bricks (listed above) using the
    concrete `SU3Connection` type and the real
    `Matrix.specialUnitaryGroup (Fin 3) ℂ` monoid structure.
    Axiom footprint of each = subset of mathlib's classical trio.
  * Stable citable Lean identifiers for future plans to point at.
  * A flagged TODO surface: every remaining `sorry` is paired with a
    `TODO:` comment naming the mathlib module that would replace it.

  ## Status

  Per `docs/ROADMAP.md` § 2. Yang-Mills mass gap: **Open.** No
  promotion. The fact that `SU3Connection`, `HilbertSpace`,
  `YMHamiltonian`, and `IsEigenstate` are now all concrete and
  the file is `sorry`-free does NOT change the tower's status. The
  concretizations are honest stand-ins (ℓ²(ℕ,ℂ) Hilbert space,
  sum-of-traces "Hamiltonian", scaling-form eigenstate predicate),
  not the Clay surface — even with `HilbertSpace = ℓ²(ℕ,ℂ)` the
  resulting `YM_mass_gap_statement` is a statement about ℓ²(ℕ,ℂ),
  NOT the real YM Hilbert space, which requires an Osterwalder–
  Schrader reconstruction not present in mathlib v4.12.0. The
  mass gap is not proved, not stated precisely as Yang-Mills
  physics, and not in sight.
-/

import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Data.Complex.Basic
import Mathlib.Analysis.InnerProductSpace.l2Space
import Mathlib.Data.Fintype.BigOperators

namespace TheoremaAureum
namespace Towers
namespace YM

/-- **SU(3) gauge field, trivial-bundle constant-coefficient case.**

    A `SU3Connection` is a 4-tuple of constant `SU(3)` matrices, one
    per spacetime direction. This is the trivial-bundle special case
    of an honest YM connection — no base manifold, no bundle, no
    differential structure — but it is a real, inhabited, sorry-free
    type that the brick `SU3Connection_one_mul` below can prove
    things about using the real `Matrix.specialUnitaryGroup` API. -/
abbrev SU3Connection : Type := Fin 4 → Matrix.specialUnitaryGroup (Fin 3) ℂ
-- TODO (mathlib v4.13+): replace with
--   Connection (Bundle ℝ ℝ⁴) (Matrix.specialUnitaryGroup (Fin 3) ℂ)
-- once `Mathlib.Geometry.Manifold.VectorBundle.Basic` exposes Connection.
-- (Note: `Matrix.specialUnitaryGroup` itself lives in
--  `Mathlib/LinearAlgebra/UnitaryGroup.lean`, not in a separate
--  `Mathlib.LinearAlgebra.Matrix.SpecialUnitaryGroup` file.)

/-
  **Task #51 + Task #55 merge note (2026-05-26).** The three
  schema defs below (`HilbertSpace`, `YMHamiltonian`,
  `IsEigenstate`) were previously `sorry`-backed placeholders.

  Task #55 (Branch A) replaced `HilbertSpace` with `lp (fun _ : ℕ
  => ℂ) 2`, the canonical separable infinite-dim ℓ²(ℕ,ℂ). Branches
  B (symmetric Fock space) and C (su(3)-valued L²) were deferred
  because (B) mathlib v4.12.0 has no `SymmetricFockSpace` / no
  Hilbert-completion of a tensor algebra / no second-quantization
  machinery; (C) requires first defining `𝔰𝔲(3)` as a subtype
  with `InnerProductSpace ℝ` instances and lifting to `Lp`.

  Task #51 then replaced `YMHamiltonian` with `∑ i : Fin 4, ((A
  i).1).trace.re` (a real-valued, deterministic function of the
  four SU(3) components, computed from the genuine `Matrix.trace`
  of each connection component — NOT `∫ tr(F ∧ ★F)`) and
  `IsEigenstate H ψ` with `∃ μ : ℝ, ∀ A, H A = μ * (‖ψ‖ * ‖ψ‖)`
  (the "H scales uniformly by μ times the squared norm of ψ"
  predicate — NOT the spectral-eigenvector property of an operator
  on the physical Hilbert space).

  **Honest-scoping rule that survives both upgrades.** ℓ²(ℕ,ℂ)
  is THE canonical separable infinite-dimensional complex Hilbert
  space, but it is NOT the Yang-Mills physical Hilbert space. The
  actual YM Hilbert space is built by an Osterwalder–Schrader
  reconstruction from a constructed Euclidean YM measure that does
  not exist in mathlib v4.12.0 (and is itself an open research
  problem for 4D pure YM). `YM_mass_gap_statement` below now
  type-checks without `sorryAx`, but THAT TYPE-CHECKING IS NOT A
  FORMALIZATION OF THE CLAY CONJECTURE — it is a Prop about
  ℓ²(ℕ,ℂ) and the placeholder Hamiltonian / eigenstate predicate
  above, vacuous as Yang-Mills physics. Tower status: **Open**
  (see `docs/ROADMAP.md` § 2). Promoting past `Open` requires the
  real YM Hilbert space and Hamiltonian, neither of which is
  plumbed up. See `IsEigenstate_zero_zero` below for the first
  downstream brick that uses the post-merge schema.
-/

/-- **Hilbert space placeholder for the schema.**

    Defined as `lp (fun _ : ℕ => ℂ) 2`, the canonical separable
    infinite-dimensional complex Hilbert space (ℓ²(ℕ, ℂ)) —
    `NormedAddCommGroup`, `InnerProductSpace ℂ`, and `CompleteSpace`
    all come from mathlib's `Mathlib.Analysis.InnerProductSpace.l2Space`.

    **This is NOT the Yang-Mills physical state space.** It is a
    real, infinite-dimensional, mathlib-backed Hilbert space chosen
    so the schema below (`YM_mass_gap_statement`) typechecks against
    something real instead of a `sorry`. The actual YM Hilbert space
    requires an Osterwalder–Schrader reconstruction from a
    constructed 4D Euclidean YM measure, which is not in mathlib
    v4.12.0 and is itself an open research problem. See the
    "Task #51 + Task #55 merge note" block immediately above for
    the full honest-scoping argument. -/
abbrev HilbertSpace : Type := lp (fun _ : ℕ => ℂ) 2
-- TODO (mathlib v4.13+ / OS-reconstruction): replace with the actual
-- physical-state Hilbert space of the YM Hamiltonian.

/-- **Yang-Mills Hamiltonian** — concretized (Task #51) as the sum
    of real parts of the matrix traces of the four SU(3) components.
    This is **not** the gauge-invariant field energy
    `∫ tr(F_A ∧ ★F_A)`; it is a real-valued, deterministic function
    of `A` that exercises the genuine `Matrix.trace` API on each
    component. -/
noncomputable def YMHamiltonian (A : SU3Connection) : ℝ :=
  (Finset.univ : Finset (Fin 4)).sum (fun i => ((A i).1).trace.re)
-- TODO (mathlib v4.13+): ∫ tr(F_A ∧ ★F_A) using Distribution.SobolevSpace

/-- **Eigenstate predicate** — concretized (Task #51) as the
    "uniform scaling by μ · ‖ψ‖²" form. `IsEigenstate H ψ` holds
    iff there exists a real scalar `μ` such that for every
    connection `A`, `H A = μ * (‖ψ‖ * ‖ψ‖)`. This is **not** the
    spectral-eigenvector property of an operator on a physical
    Hilbert space; it is the minimal real `Prop` that captures the
    *form* of "H is a constant multiple of ψ's squared norm" and
    lets downstream bricks state eigenstate-flavoured claims
    without `sorryAx`. -/
def IsEigenstate (H : SU3Connection → ℝ) (ψ : HilbertSpace) : Prop :=
  ∃ μ : ℝ, ∀ A : SU3Connection, H A = μ * (‖ψ‖ * ‖ψ‖)
-- TODO (mathlib v4.13+): ψ is a true eigenstate of H as a self-adjoint
-- operator on the YM physical-state Hilbert space.

/-- **Mass gap statement:** `∃ Δ > 0, ∀ eigenstates ψ, E_ψ ≥ Δ`.
    This is NOT a theorem — it is the Clay conjecture restated in
    Lean using the placeholder defs above. It is not in BRICKS.
    With the Task #51 concretizations in place, this now
    type-checks without `sorryAx`, but its *content* is still the
    placeholder schema (finite-dim Hilbert space, sum-of-traces
    Hamiltonian, scaling-form eigenstate predicate), not the Clay
    YM mass gap. -/
def YM_mass_gap_statement : Prop :=
  ∃ Δ : ℝ, 0 < Δ ∧ ∀ (A : SU3Connection) (ψ : HilbertSpace),
    IsEigenstate YMHamiltonian ψ → YMHamiltonian A ≥ Δ

/-- **The zero state is a (trivial) eigenstate of the zero Hamiltonian
    (eighth brick in `MassGap.lean`, first brick to use the Task #51
    concretized schema).**

    For the constant-zero "Hamiltonian" `fun _ => 0` and the zero
    vector `0 : HilbertSpace`, the predicate `IsEigenstate` holds —
    witnessed by `μ = 0`, since `0 = 0 * (‖(0 : HilbertSpace)‖ *
    ‖(0 : HilbertSpace)‖)` by `zero_mul`.

    This brick exists to demonstrate that the concretized
    `HilbertSpace` and `IsEigenstate` are not dead schema: they
    expose enough API (norm, zero vector, multiplication on `ℝ`)
    that a downstream proof can actually mention them by name and
    discharge a genuine Prop. The mathematics is intentionally
    trivial — `0 = 0` — but the *types* (real `EuclideanSpace ℂ
    (Fin 3)` for `ψ`, real `SU3Connection → ℝ` for `H`) are the
    post-Task-#51 schema.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    says only that the zero vector trivially satisfies the
    placeholder eigenstate predicate against the zero Hamiltonian.
    No claim about the YM Hamiltonian, mass gap, or any QFT
    statement. -/
theorem IsEigenstate_zero_zero :
    IsEigenstate (fun _ : SU3Connection => (0 : ℝ)) (0 : HilbertSpace) :=
  ⟨0, fun _ => (zero_mul _).symm⟩

/-- **Identity acts trivially on each component of an SU(3) connection
    (first real trio-clean brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`,

      `(1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * A i = A i`.

    The proof is a one-line delegation to mathlib's `one_mul` on the
    monoid structure of `Matrix.specialUnitaryGroup (Fin 3) ℂ`
    (which `specialUnitaryGroup` inherits as a `Submonoid` of
    `Matrix (Fin 3) (Fin 3) ℂ` via `Submonoid.toMonoid`).

    This is **not** new mathematics — it is the trivial left-identity
    law of the SU(3) monoid, applied to one component of the
    trivial-bundle SU(3) connection schema. Its purpose is to be
    the **first real demonstration** that the post-refactor
    `SU3Connection` type is a usable mathlib-flavoured surface,
    rather than an opaque `sorry`-def.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves *nothing* about the Yang-Mills mass gap, the YM
    Hamiltonian, the physical-state Hilbert space, or any QFT
    statement. It says only that `1 * x = x` in the SU(3) monoid,
    on one component of a placeholder connection. -/
theorem SU3Connection_one_mul (A : SU3Connection) (i : Fin 4) :
    (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * A i = A i :=
  one_mul (A i)

/-- **Each component of an SU(3) connection is unitary
    (second real brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`, the underlying `3×3` complex matrix of `A i`
    satisfies the unitarity equation

      `(A i).1 * star ((A i).1) = 1`

    where `.1` extracts the underlying `Matrix (Fin 3) (Fin 3) ℂ`
    from the `specialUnitaryGroup` subtype.

    The proof unfolds membership through mathlib's
    `Matrix.mem_specialUnitaryGroup_iff`
    (`A ∈ specialUnitaryGroup n α ↔ A ∈ unitaryGroup n α ∧ A.det = 1`)
    to extract the unitarity component, then unfolds that through
    `Matrix.mem_unitaryGroup_iff`
    (`A ∈ unitaryGroup n α ↔ A * star A = 1`).

    Unlike `SU3Connection_one_mul` (which only used the abstract
    monoid identity), this brick is **substantive**: it proves the
    defining property of the unitary subgroup — `M M* = I` — using
    the real mathlib `Matrix.unitaryGroup` API, instantiated at the
    SU(3) connection components of our trivial-bundle schema.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves only that each constant SU(3)-matrix in the trivial-bundle
    schema is in fact unitary — which it is by typing. No claim
    about the YM Hamiltonian, mass gap, eigenstates, or any QFT
    statement. `HilbertSpace`, `YMHamiltonian`, and `IsEigenstate`
    are all concrete (Task #55 + Task #51 merge), but the
    concretizations are honest stand-ins, NOT the YM physical
    surface (see the "Task #51 + Task #55 merge note" block). -/
theorem SU3Connection_component_unitary (A : SU3Connection) (i : Fin 4) :
    (A i).1 * star (A i).1 = 1 := by
  have h := Matrix.mem_specialUnitaryGroup_iff.mp (A i).2
  exact Matrix.mem_unitaryGroup_iff.mp h.1

/-- **Each component of an SU(3) connection has determinant 1
    (third real brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`, the underlying `3×3` complex matrix of `A i` has
    determinant `1`:

      `(A i).1.det = 1`.

    This is the *special* in **S**U(3) — the determinant-one
    constraint that distinguishes the special unitary group from
    the full unitary group. The proof unfolds membership through
    mathlib's `Matrix.mem_specialUnitaryGroup_iff`
    (`A ∈ specialUnitaryGroup n α ↔ A ∈ unitaryGroup n α ∧ A.det = 1`)
    and projects out the determinant component.

    Together with `SU3Connection_component_unitary` (just above),
    this completes the pair of defining properties of the SU(3)
    subgroup acting on each component of our trivial-bundle
    connection schema: each component matrix is *unitary* AND has
    *determinant one*. These two bricks are the most informative
    use so far of the post-refactor `MassGap.lean` surface —
    actually proving things about the SU(3) structure, not just
    abstract monoid identities.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves only that each constant SU(3)-matrix in the trivial-bundle
    schema has det 1 — which it does by typing. No claim about the
    YM Hamiltonian, mass gap, eigenstates, or any QFT statement. -/
theorem SU3Connection_component_det_one (A : SU3Connection) (i : Fin 4) :
    (A i).1.det = 1 :=
  (Matrix.mem_specialUnitaryGroup_iff.mp (A i).2).2

/-- **Right-identity for SU(3) connection components
    (fourth brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`,

      `A i * (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) = A i`.

    The proof is a one-line delegation to mathlib's `mul_one` on
    the monoid structure of `Matrix.specialUnitaryGroup (Fin 3) ℂ`.
    This is the right-identity companion to `SU3Connection_one_mul`
    (left-identity); together they say the SU(3) monoid identity
    fixes every component on both sides.

    This is **not** new mathematics — it is the trivial right-identity
    law of the SU(3) monoid, applied to one component of the
    trivial-bundle SU(3) connection schema.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}` (verified by
    `scripts/check-towers.sh`). No research-grade axioms.

    **Honest scoping reminder.** This still does **not** advance the
    YM tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It
    proves *nothing* about the Yang-Mills mass gap, the YM
    Hamiltonian, the physical-state Hilbert space, or any QFT
    statement. It says only that `x * 1 = x` in the SU(3) monoid,
    on one component of a placeholder connection. -/
theorem SU3Connection_mul_one (A : SU3Connection) (i : Fin 4) :
    A i * (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) = A i :=
  mul_one (A i)

/-- **The SU(3) monoid identity squares to itself
    (fifth brick in `MassGap.lean`).**

    `(1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * 1 = 1`.

    A one-line `mul_one 1` on the SU(3) submonoid. Trivial as
    monoid arithmetic, but the *type* is real SU(3) — not a stub,
    not a placeholder. The lemma exists to give downstream proofs
    a stable rewrite for `1 * 1` simplifications on SU(3) elements.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It says
    only that `1 * 1 = 1` in the SU(3) submonoid. No claim about
    the YM Hamiltonian, mass gap, eigenstates, or any QFT
    statement. -/
theorem SU3Connection_one_one :
    (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ) * 1 = 1 :=
  mul_one 1

/-- **Product of two SU(3)-connection components is unitary
    (sixth brick in `MassGap.lean`).**

    For any two SU(3) connections `A B : SU3Connection` and any
    spacetime direction `i : Fin 4`,

      `(A i).1 * (B i).1 ∈ Matrix.unitaryGroup (Fin 3) ℂ`.

    The proof invokes `Submonoid.mul_mem` on the unitary submonoid:
    if `A i` is unitary and `B i` is unitary, their matrix product
    is unitary. The unitarity of each factor is `component_unitary`
    extracted via `Matrix.mem_specialUnitaryGroup_iff.mp _ |>.1`.

    Genuine algebraic content: it exercises submonoid closure of
    `Matrix.unitaryGroup` under multiplication, a real mathlib
    structure result, not just a definitional unfolding.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It says
    only that U(3) is closed under matrix multiplication — true by
    definition of the unitary group. No claim about Yang-Mills
    dynamics, mass gap, or any QFT result. -/
theorem SU3Connection_component_mul_unitary
    (A B : SU3Connection) (i : Fin 4) :
    (A i).1 * (B i).1 ∈ Matrix.unitaryGroup (Fin 3) ℂ :=
  (Matrix.unitaryGroup (Fin 3) ℂ).mul_mem
    (Matrix.mem_specialUnitaryGroup_iff.mp (A i).2).1
    (Matrix.mem_specialUnitaryGroup_iff.mp (B i).2).1

/-- **Product of two SU(3)-connection components still has determinant 1
    (seventh brick in `MassGap.lean`).**

    For any two SU(3) connections `A B : SU3Connection` and any
    spacetime direction `i : Fin 4`,

      `((A i).1 * (B i).1).det = 1`.

    The proof uses `Matrix.det_mul` (the genuine multiplicative
    property of the determinant — a real mathlib theorem, not a
    definitional unfolding) together with `component_det_one` on
    each factor; `mul_one` finishes.

    Genuine algebraic content: it exercises `Matrix.det_mul`,
    which is the key fact that `det : Matrix n n R → R` is a
    monoid homomorphism. This is the closure-under-multiplication
    proof for the determinant-1 hyperplane, the SL-side of the
    SU(3) algebraic structure (companion to
    `SU3Connection_component_mul_unitary`, the U-side).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`. No research-grade
    axioms.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2). It says
    only that SL(3) ⊃ SU(3) is closed under matrix multiplication
    — true by multiplicativity of the determinant. No claim about
    the Yang-Mills mass gap, dynamics, or any QFT result. -/
theorem SU3Connection_component_mul_det_one
    (A B : SU3Connection) (i : Fin 4) :
    ((A i).1 * (B i).1).det = 1 := by
  rw [Matrix.det_mul, SU3Connection_component_det_one,
      SU3Connection_component_det_one, mul_one]

/-- **Associativity of multiplication on SU(3) connection components
    (eighth real brick in `MassGap.lean`).**

    For any three `SU3Connection`s `A`, `B`, `C` and any spacetime
    direction `i : Fin 4`, the component-wise product is associative:

      `(A i * B i) * C i = A i * (B i * C i)`.

    This is the associativity law of the
    `Matrix.specialUnitaryGroup (Fin 3) ℂ` monoid, instantiated at
    the connection components. It completes the standard set of
    monoid laws (`one_mul`, `mul_one`, `mul_assoc`) on the
    trivial-bundle SU(3) schema.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This does **not** advance the YM
    tower past `Status: Open`. It is a monoid identity, not a
    statement about Yang-Mills dynamics. -/
theorem SU3Connection_mul_assoc (A B C : SU3Connection) (i : Fin 4) :
    (A i * B i) * C i = A i * (B i * C i) :=
  mul_assoc (A i) (B i) (C i)

/-- **Left-unitary law on SU(3) connection components
    (ninth real brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`, the underlying `3×3` complex matrix satisfies the
    *other* side of the unitary law:

      `star (A i).1 * (A i).1 = 1`.

    Companion to `SU3Connection_component_unitary`, which proves
    `(A i).1 * star (A i).1 = 1`. The pair together is the full
    two-sided unitary law on each component matrix; for unitary
    matrices, `star` IS the inverse (`A⁻¹ = star A`), so this is
    the inverse-cancellation law in disguise. We state it directly
    at the matrix level via `star` rather than via `⁻¹` because
    `Matrix.specialUnitaryGroup (Fin 3) ℂ` is a `Submonoid` (no
    `Group` / `Inv` instance) in mathlib v4.12.0 — the closure of
    the determinant-one constraint under inverse is true but not
    instantiated. Working through `star` on the underlying matrix
    sidesteps that and keeps the proof one line.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** A unitary-matrix identity, not a
    statement about YM dynamics. Tower status unchanged: **Open**. -/
theorem SU3Connection_component_star_mul_self
    (A : SU3Connection) (i : Fin 4) :
    star (A i).1 * (A i).1 = 1 := by
  have h := Matrix.mem_specialUnitaryGroup_iff.mp (A i).2
  exact Matrix.mem_unitaryGroup_iff'.mp h.1

/-- **The star of an SU(3) connection component still has
    determinant 1 (tenth real brick in `MassGap.lean`).**

    For any `SU3Connection` `A` and any spacetime direction
    `i : Fin 4`:

      `(star (A i).1).det = 1`.

    Concretely, the conjugate-transpose of an SU(3) matrix is
    again an SU(3) matrix — it is unitary (the companion brick
    `SU3Connection_component_star_mul_self` is one half of that)
    and its determinant is `star 1 = 1`. The proof uses
    `Matrix.det_conjTranspose` (`(star A).det = star A.det`) plus
    `SU3Connection_component_det_one`.

    This brick + `SU3Connection_component_star_mul_self` together
    witness in proof-text that `star (A i).1 ∈ SU(3)`, recovering
    the "closed under inverse" content of an SU(3) group structure
    without needing an `Inv` instance on `specialUnitaryGroup`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** A determinant identity, not a
    statement about YM dynamics. Tower status unchanged: **Open**. -/
theorem SU3Connection_component_star_det_one
    (A : SU3Connection) (i : Fin 4) :
    (star (A i).1).det = 1 := by
  -- `star` on a complex matrix is definitionally `Matrix.conjTranspose`,
  -- but `rw` needs the syntactic `·ᴴ.det` shape, so reshape the goal
  -- first, then apply `Matrix.det_conjTranspose`.
  show (Matrix.conjTranspose (A i).1).det = 1
  rw [Matrix.det_conjTranspose, SU3Connection_component_det_one, star_one]

/-! ### Task #55: load-bearing bricks on the concretized YM schema

    The four bricks below each reference at least one of the
    Task #51 + Task #55 concretized schema defs (`HilbertSpace`,
    `YMHamiltonian`, `IsEigenstate`) — and three of them reference
    at least two — proving the schema is genuinely load-bearing
    rather than window dressing. None of them advances the YM
    tower past `Status: Open` (see `docs/ROADMAP.md` § 2); they
    are foundation bricks under the placeholder schema. -/

/-- **The all-ones SU(3) connection has Hamiltonian value 12
    (Task #55, brick on `YMHamiltonian`).**

    For the constant SU(3) connection `A = fun _ => 1` (the identity
    matrix in every spacetime direction):

      `YMHamiltonian A = 12`.

    Proof: each component contributes `((1 : SU(3)).1).trace.re`.
    The coercion `(1 : SU(3)).1` is the `3×3` identity matrix
    (`Submonoid.coe_one`), whose trace equals `Fintype.card (Fin 3) = (3 : ℂ)`
    via `Matrix.trace_one`, whose real part is `3`. Summing over the
    four spacetime directions gives `4 * 3 = 12`.

    This brick exercises the *value* of `YMHamiltonian` on a concrete
    input — proving the def is not just a typed shell but actually
    computes against the genuine `Matrix.trace` API. It is the first
    brick in `MassGap.lean` to extract a numerical answer from the
    Task #51 concretization.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This is a trace-of-identity
    calculation, not a Yang-Mills field-energy computation. The
    answer `12 = 4 * 3` is `(# spacetime dimensions) * (dim SU(3)
    fundamental rep)`, an artefact of the placeholder schema, NOT
    the YM ground-state energy. Tower status unchanged: **Open**. -/
theorem YMHamiltonian_one_eq_twelve :
    YMHamiltonian (fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ))
      = 12 := by
  simp [YMHamiltonian, Submonoid.coe_one, Matrix.trace_one]
  norm_num

/-- **The constant-zero Hamiltonian has every Hilbert-space vector
    as an eigenstate (Task #55, brick on `HilbertSpace` +
    `IsEigenstate`).**

    For any `ψ : HilbertSpace` (= `lp (fun _ : ℕ => ℂ) 2`):

      `IsEigenstate (fun _ : SU3Connection => (0 : ℝ)) ψ`.

    Witnessed by `μ = 0`, since `0 = 0 * (‖ψ‖ * ‖ψ‖)` by `zero_mul`,
    for every connection `A`.

    This generalises `IsEigenstate_zero_zero` (which fixed `ψ = 0`)
    to *every* vector in the placeholder Hilbert space — i.e. the
    zero Hamiltonian is degenerate on all of ℓ²(ℕ,ℂ). The brick
    exercises both concretized types (`HilbertSpace` and
    `IsEigenstate`) on an arbitrary `ψ`, proving the schema's
    `ψ`-slot is not vacuously specialised to `0`.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This says only that the trivial
    "always 0" map satisfies the placeholder scaling-form
    eigenstate predicate against every ℓ²(ℕ,ℂ) vector — vacuous
    as Yang-Mills physics. Tower status unchanged: **Open**. -/
theorem IsEigenstate_zero_const (ψ : HilbertSpace) :
    IsEigenstate (fun _ : SU3Connection => (0 : ℝ)) ψ :=
  ⟨0, fun _ => (zero_mul _).symm⟩

/-- **Any Hamiltonian that is identically zero satisfies the
    eigenstate predicate against every Hilbert-space vector
    (Task #55, brick on `HilbertSpace` + `IsEigenstate`).**

    For any `H : SU3Connection → ℝ` with `∀ A, H A = 0` and any
    `ψ : HilbertSpace`:

      `IsEigenstate H ψ`.

    Witnessed by `μ = 0`: `H A = 0 = 0 * (‖ψ‖ * ‖ψ‖)`. Generalises
    `IsEigenstate_zero_const` (above) from the literal `fun _ => 0`
    to *any* extensionally-zero Hamiltonian. Useful as a rewrite
    target downstream: if a proof reduces some Hamiltonian to the
    zero function pointwise, this brick discharges the eigenstate
    goal in one step.

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** A statement about the placeholder
    eigenstate predicate, not the Yang-Mills spectrum. Tower
    status unchanged: **Open**. -/
theorem IsEigenstate_of_forall_zero
    (H : SU3Connection → ℝ) (hH : ∀ A, H A = 0) (ψ : HilbertSpace) :
    IsEigenstate H ψ :=
  ⟨0, fun A => by rw [hH A, zero_mul]⟩

/-- **The Yang-Mills Hamiltonian is NOT an eigenstate at the zero
    Hilbert-space vector (Task #55, brick combining all three
    concretized defs: `HilbertSpace`, `YMHamiltonian`,
    `IsEigenstate`).**

      `¬ IsEigenstate YMHamiltonian (0 : HilbertSpace)`.

    Proof: if `IsEigenstate YMHamiltonian 0` held, there would be a
    `μ : ℝ` with `∀ A, YMHamiltonian A = μ * (‖(0 : HilbertSpace)‖ *
    ‖0‖) = μ * 0 = 0`. Instantiating at `A = fun _ => 1` and
    invoking `YMHamiltonian_one_eq_twelve` (just above) gives
    `(12 : ℝ) = 0`, a contradiction via `norm_num`.

    This is the most substantive brick in `MassGap.lean` so far on
    the post-Task-#51 schema: it references **all three** concretized
    defs (`HilbertSpace`, `YMHamiltonian`, `IsEigenstate`) and the
    previous brick (`YMHamiltonian_one_eq_twelve`), and derives a
    genuine `False` from the conjunction. Concretely it says the
    placeholder Hamiltonian is non-trivial: it does NOT satisfy the
    placeholder eigenstate predicate at the zero vector, because the
    Hamiltonian itself is non-zero (at the all-ones connection).

    Axiom footprint: subset of mathlib's classical core
    `{propext, Classical.choice, Quot.sound}`.

    **Honest scoping reminder.** This is a statement about the
    placeholder schema, not the YM physical Hamiltonian on the YM
    physical Hilbert space. The "Hamiltonian" is a sum of matrix
    traces, the "Hilbert space" is ℓ²(ℕ,ℂ), and the "eigenstate"
    predicate is the scaling-form `Prop`. The brick is honest
    about the schema being non-trivial; it makes no Yang-Mills
    physics claim. Tower status unchanged: **Open**. -/
theorem YMHamiltonian_not_isEigenstate_zero :
    ¬ IsEigenstate YMHamiltonian (0 : HilbertSpace) := by
  rintro ⟨μ, h⟩
  have h1 := h (fun _ : Fin 4 => (1 : Matrix.specialUnitaryGroup (Fin 3) ℂ))
  rw [YMHamiltonian_one_eq_twelve, norm_zero, mul_zero, mul_zero] at h1
  norm_num at h1

end YM
end Towers
end TheoremaAureum
