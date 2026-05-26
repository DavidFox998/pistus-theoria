# The Three Hard Lemmas

**Status:** open. **Repository wall:** 278 bricks, axiom footprint
`⊆ {propext, Classical.choice, Quot.sound}`. **Towers:**
`Status: Open` (`docs/ROADMAP.md` § 2, § 3).

This document is the companion to `docs/FOR_REFEREES.md`. Its job
is single-purpose and narrow: for each of the three load-bearing
lemmas left as honest conditionals at the end of Batch 17, state
plainly

1. what the real Millennium-scale statement is (in mathematics, not
   in Lean),
2. what mathematical objects would have to be formalized in this
   repository to even *state* it as a Lean theorem,
3. what proof strategy from the literature would have to be carried
   out,
4. what the current Lean conditional captures, and what it does
   not, and
5. the named tripwire that exists in the codebase to catch any
   future vacuous discharge.

The point of this document is to make it impossible for a future
reader — or for the author himself — to mistake the conditional
shape of these three lemmas for a discharge. If any of them is
ever closed for real, the closer should be able to point at the
exact paragraph here that named the missing object.

---

## Lemma 1 — `Perron_Frobenius_for_transfer`

**File:** `lean-proof-towers/Towers/YM/Transfer.lean` (Batch 17,
Track 1).

### Real Millennium statement

For SU(3) lattice Yang-Mills in four dimensions at sufficiently
small bare coupling `g > 0`, the transfer operator `T_g` on the
physical (Osterwalder-Schrader-reconstructed) transfer-Hilbert
space `H_phys` is bounded, self-adjoint, positive, and has
spectral radius `r(T_g) < 1` on the orthogonal complement of the
vacuum. Equivalently, the largest eigenvalue `λ_max(T_g) < 1`
strictly, which forces an exponential decay of the truncated
two-point function and is the standard route to the Clay
mass-gap claim
`m(g) := -log λ_max(T_g) > 0`.

### What would have to be formalized in this repository

None of the following objects exist anywhere in this codebase:

- The physical transfer-Hilbert space `H_phys` (requires
  Osterwalder-Schrader reconstruction from a reflection-positive
  Euclidean measure on connections).
- A reflection-positive lattice measure on the configuration space
  of SU(3) gauge connections.
- The transfer operator `T_g : H_phys → H_phys` as a bounded
  self-adjoint operator (the current `transfer_matrix_real` is the
  scalar reduction `WilsonAction 1` — a real number, not an
  operator).
- The spectrum / spectral radius of `T_g` (requires the spectral
  theorem for bounded self-adjoint operators on a separable
  Hilbert space — mathlib has pieces, but the application to a
  reconstructed YM transfer operator is not landed).

### Proof strategy from the literature

Reflection positivity ⇒ Osterwalder-Schrader reconstruction ⇒
`T_g` is self-adjoint and `0 ≤ T_g ≤ 1`. For small `g`, the
cluster (high-temperature / strong-coupling) expansion gives a
quantitative gap on the orthogonal complement of the vacuum:
`λ_max(T_g) ≤ 1 - c(g)` with `c(g) > 0`. This is classical for
the abelian case and for SU(N) at strong coupling; the open
problem is the continuum / weak-coupling regime, which is what
the Clay statement actually asks for.

### What the current Lean conditional captures

```lean
theorem Perron_Frobenius_for_transfer
    (_h_g : ∃ g : ℝ, 0 < g)
    (h_assume : ∃ lam : ℝ, 0 < lam ∧ lam < 1) :
    ∃ lam : ℝ, 0 < lam ∧ lam < 1 :=
  h_assume
```

This is a pass-through. The conclusion `∃ λ ∈ (0, 1)` is a real
number existential, not a spectral-radius statement. The Lean
theorem says exactly: *"if a real number `λ ∈ (0, 1)` exists, then
a real number `λ ∈ (0, 1)` exists."* The mathematical content of
the YM mass gap lives entirely in `h_assume`, which is a `Prop`
hypothesis the codebase does not unfold.

### Tripwire

`MassGap_YM4_Clay_conditional` in
`lean-proof-towers/Towers/YM/Spectrum.lean` is itself conditional
on the Batch-16 schema and on the antecedent shape of
`Perron_Frobenius_for_transfer`. Any future PR that replaces the
trivial-existence conclusion with a real `spectral_radius
T_g < 1` statement must do so by introducing `H_phys`, `T_g`, and
the spectral radius as real Lean objects — at which point the
`MassGap_YM4_Clay_*` chain becomes a genuine discharge, and the
YM tower can be promoted out of `Status: Open` in
`docs/ROADMAP.md`. Not before.

---

## Lemma 2 — `gap_uniform_in_Lambda_v2`

**File:** `lean-proof-towers/Towers/Spectral/OperatorV2.lean`
(Batch 17, Track 2).

### Real Millennium statement

For the IR-cutoff lattice Hamiltonian `H_Λ` (the spatial generator
of the SU(3) YM transfer operator restricted to a finite cube of
side `Λ` with periodic or Dirichlet boundary conditions), the
first non-zero Neumann eigenvalue satisfies
`μ_1(H_Λ) ≥ δ_0 > 0` uniformly in `Λ` as `Λ → ∞`. The
`Λ`-independence is the load-bearing claim: without it, the
infrared limit `H_∞` may have spectrum accumulating at `0` and
the mass gap closes.

### What would have to be formalized in this repository

- The IR-cutoff Hamiltonian `H_Λ` as a self-adjoint operator on
  the finite-volume Hilbert space `L²(SU(3)^{|Λ|}, dμ_Λ)` (where
  `dμ_Λ` is the heat-kernel measure or Haar product).
- The Neumann boundary condition for `H_Λ` (the lattice analog of
  zero normal derivative on `∂Λ`).
- The first non-zero eigenvalue `μ_1(H_Λ)` via the min-max
  characterization on the orthogonal complement of the constants.
- A uniform-in-`Λ` lower bound, which requires a Poincaré-Steklov
  inequality with `Λ`-independent constants on the relevant
  function space.

The current `Poincare_inequality_IR_lattice` and
`Neumann_eigenvalue_lower_bound_Λ` are Batch-16 `Prop` schemas;
the Batch-17 `Poincare_inequality_IR_lattice_v2` lands the
inequality only on `Fin 1` (a one-point lattice, on which the
inequality is `0 ≤ C · 0` and proves nothing about the IR limit).

### Proof strategy from the literature

The classical route: a uniform Poincaré inequality on the
lattice gives a uniform lower bound on `μ_1(H_Λ)` via the
Rayleigh quotient. The Poincaré constant for the lattice
Laplacian on a cube of side `Λ` is `Θ(1/Λ²)`, which is *not*
uniform — so the naive route fails. A `Λ`-independent gap
requires either (a) a real mass term in `H_Λ` of the form
`m² ∑_x φ_x²` for `m > 0`, which begs the question, or (b) a
non-perturbative gap mechanism such as confinement, which is
itself part of the Clay problem.

### What the current Lean conditional captures

```lean
theorem gap_uniform_in_Lambda_v2
    (_h_schemas :
      Poincare_inequality_IR_lattice ∧
        Neumann_eigenvalue_lower_bound_Λ ∧
        IR_cutoff_gap_estimate)
    (δ₀ : ℝ) (hδ : 0 < δ₀) :
    ∃ δ : ℝ, 0 < δ ∧ δ ≤ δ₀ + 1 :=
  ⟨δ₀, hδ, by linarith⟩
```

The hypothesis is a conjunction of three `Prop` schemas; the
conclusion is `∃ δ ∈ (0, δ₀ + 1]`, which is a real-number
existential trivially witnessed by `δ₀` itself. The lemma does
not state, and does not prove, `μ_1(H_Λ) ≥ δ_0` for any real
operator `H_Λ`.

### Tripwire

`MassGap_YM_operator_promotion_v2` in the same file is the
conditional promotion to a `MassGap` predicate on
`Hamiltonian_operator_v2 0` (the zero-dimensional /
`Fin 0`-vector placeholder). Any future PR that wants to promote
this out of `Status: Open` must first replace
`Hamiltonian_operator_v2` with a real `H_Λ` on a real
`L²(SU(3)^{|Λ|})` space, and the `_h_schemas` antecedent with a
real uniform Poincaré-Steklov inequality. Until then,
`MassGap_YM_operator` is a schema, not a theorem.

---

## Lemma 3 — `enstrophy_bound_global`

**File:** `lean-proof-towers/Towers/NS/EnergyV2.lean` (Batch 17,
Track 3).

### Real Millennium statement

For smooth, divergence-free initial data `u_0 ∈ H¹(ℝ³)` and the
3D incompressible Navier-Stokes equations with viscosity `ν > 0`,
the Leray-Hopf weak solution `u(·, t)` satisfies
`∫_0^∞ ‖∇u(·, t)‖_{L²}² dt < ∞`, equivalently the global
enstrophy bound `sup_{t ≥ 0} ‖∇u(·, t)‖_{L²} < ∞`. The
Beale-Kato-Majda criterion then promotes this to global smoothness,
which is the Clay statement.

### What would have to be formalized in this repository

- The Sobolev space `H¹(ℝ³; ℝ³)` with its divergence-free
  subspace.
- Leray-Hopf weak solutions of the Navier-Stokes equations
  (existence is classical; uniqueness in 3D is itself an open
  problem and is *part* of the Clay statement).
- The `L²` norm of `∇u(·, t)` as a function of `t`.
- The time integral `∫_0^∞ ‖∇u‖_{L²}² dt` on the appropriate
  measurable function space.

The current `Enstrophy` is a placeholder real-valued function on
`(ℝ, ℝ)`. `vorticity_L2_energy_identity` witnesses
`∃ K, Enstrophy 0 0 = K` (trivially `Enstrophy 0 0`).
`Ladyzhenskaya_4D_sharp` is the inequality `0 ≤ C · E · 0` (the
zero-norm degenerate case). None of these objects is `H¹(ℝ³)`.

### Proof strategy from the literature

The 2D case is closed by Leray-Hopf: `‖∇u‖_{L²}` is bounded
because the enstrophy decreases monotonically in 2D. The 3D case
is the Clay problem and is open. The standard route would be:
energy identity ⇒ enstrophy ODE
`d/dt ½‖∇u‖² + ν‖Δu‖² ≤ |⟨(u · ∇)u, Δu⟩|` ⇒ Ladyzhenskaya /
Gagliardo-Nirenberg bound on the right-hand side ⇒ Grönwall ⇒
global control. The step that fails in 3D is the Ladyzhenskaya
estimate: in 3D the critical exponent is borderline and Grönwall
gives only local-in-time control.

### What the current Lean conditional captures

```lean
theorem enstrophy_bound_global
    (_h_boot : enstrophy_bootstrap_strong)   -- shape
    (h_M : ∃ M : ℝ, 0 < M) :
    ∃ M : ℝ, 0 < M :=
  h_M
```

(Names elided; full form in the source file.) The conclusion is
`∃ M > 0`, witnessed by `h_M`. No `L²` norm, no `∇u`, no time
integral. The Clay statement is the antecedent shape, taken as a
`Prop` hypothesis the codebase does not unfold.

### Tripwire

`NavierStokes_global_regular_promotion_v2` in the same file is
the conditional promotion. Any future PR that wants to promote
the NS tower out of `Status: Open` must first introduce
`H¹(ℝ³)`, Leray-Hopf solutions, and the real time-integrated
enstrophy as Lean objects, and then close the 3D
Ladyzhenskaya-Grönwall gap. Until then,
`NavierStokes_global_regular` is a schema, not a theorem.

---

## Closing note

The author has been explicit, in `replit.md`, in
`docs/ROADMAP.md`, in `docs/FOR_REFEREES.md`, and now here, that
none of these three lemmas is a proof of its English-language
headline. The Lean conditionals exist to give the spine
something concrete to typecheck against and to act as named
tripwires against accidental future overclaim.

If, in some future batch, one of the three is closed for real —
in the sense that the real Millennium statement is stated and
proved against real formalized objects, with axiom footprint
still `⊆ {propext, Classical.choice, Quot.sound}` and with no
`sorry` — that PR should:

1. Cite the relevant section of this document.
2. Update `docs/ROADMAP.md` to promote the corresponding tower
   out of `Status: Open`, with a `Status: Closed (Lean theorem
   <name> at commit <sha>)` line.
3. Update `docs/FOR_REFEREES.md` to remove the corresponding
   "what this is not" disclaimer.
4. Add a `## Closed` section to this document recording the date,
   the closing theorem, and the strategy that finally worked.

Until that PR exists, all three lemmas remain conditional, all
three towers remain `Status: Open`, and the publishable artifact
is "278 bricks, 0 research axioms, 3 named open problems," not a
Millennium discharge.

— Morning Star Project
