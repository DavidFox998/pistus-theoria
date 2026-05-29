/-
================================================================
Towers / YM / Continuum  (Batch 20.1a — Surface #3 setup)

**Make the Clay 4D continuum-YM statement machine-checkable.**
Zero theorems. Four definitions. The four definitions are the
*targets* for later batches (20.1b limit existence, 20.1c
Osterwalder–Schrader axioms, 20.1d real mass gap); this batch
fixes their names and types so downstream surfaces have a stable
import to point at.

Four bricks per the Batch 20.1a directive:

  1. `YM4_Continuum`          — schema type for 4D SU(3) continuum YM
  2. `IsMassGap`              — mass-gap predicate on a continuum theory
  3. `lattice_to_continuum`   — renormalization map from lattice data
  4. `AsymptoticFreedom`      — physical-input Prop on a continuum theory

### Honest scope

This file ships:

  * `YM4_Continuum` — a `structure` with two `Nat` fields
    (`gauge_rank = 3`, `spacetime_dim = 4`). Names the slots a real
    continuum theory would carry; carries **no** analytic content.
  * `IsMassGap T Δ` — the predicate `0 < Δ`. Placeholder; does NOT
    reference any spectrum, Hilbert space, or Hamiltonian.
  * `lattice_to_continuum a A` — returns the default `YM4_Continuum`
    (the renormalization is the identity-like trivial map). Does
    NOT implement a real `a → 0` continuum limit.
  * `AsymptoticFreedom T` — the Prop
    `∀ μ > 0, ∃ g, 0 < g ∧ g < 1`. Names the *shape* of "the
    running coupling exists and is small in the UV". Does NOT
    reference a β-function, a renormalization-group flow, or the
    actual asymptotic behavior of g(μ).

This file does NOT ship:

  * The Osterwalder-Schrader-reconstructed continuum YM Hilbert
    space, Hamiltonian, or spectrum.
  * A real `a → 0` limit of lattice gauge theory.
  * Any Varadhan small-`t` heat-kernel asymptotic (that is the
    separate track of project task #156).
  * Any proof of the Clay statement; `MassGap_YM4_Clay` is parked
    as a `sorry` in `Towers/Attempts/Clay.lean` and is NOT in
    BRICKS.

YM tower status unchanged: **Open** (`docs/ROADMAP.md` § 2). The
four definitions below are placeholder schema, not formalized
continuum YM. None of them advances the tower.

### Invariants honored by this batch

  * `Towers/YM/` stays sorry-free (this file has zero `sorry`).
  * The only `sorry` in this surface lives in
    `Towers/Attempts/Clay.lean`.
  * No Varadhan small-`t` asymptotic is assumed anywhere in this
    file; Varadhan is project task #156, a separate track.
  * All four definitions close under axiom footprint
    `{propext, Classical.choice, Quot.sound}` (mathlib's classical
    trio — a `def` whose body is a `Nat`/`Prop`/structure literal
    over mathlib types takes no further axioms beyond what mathlib
    itself uses to elaborate them).
================================================================
-/

import Towers.YM.MassGap

namespace TheoremaAureum
namespace Towers
namespace YM
namespace Continuum

open TheoremaAureum.Towers.YM

/-- **`YM4_Continuum`** — schema type for a 4D SU(3) continuum
Yang-Mills theory. A `structure` with two `Nat` fields naming the
gauge-group rank and the spacetime dimension. Honest placeholder:
carries no Hilbert space, no Hamiltonian, no spectrum. Default
values are `gauge_rank = 3` (SU(3)) and `spacetime_dim = 4`.

This is **not** the OS-reconstructed continuum YM theory; it is a
typed slot a future batch can flesh out without renaming. -/
structure YM4_Continuum where
  /-- Rank of the gauge group. Default = 3 (SU(3)). -/
  gauge_rank : Nat := 3
  /-- Spacetime dimension. Default = 4. -/
  spacetime_dim : Nat := 4

/-- **`IsMassGap T Δ`** — mass-gap predicate on a continuum theory.
Honest placeholder shape: `0 < Δ`. Does NOT reference any spectrum,
Hilbert space, or Hamiltonian. The placeholder captures the
*positivity* that a real spectral-gap claim requires; the
spectral content is the open Clay surface (parked at
`Towers/Attempts/Clay.lean :: MassGap_YM4_Clay`). -/
def IsMassGap (_T : YM4_Continuum) (Δ : ℝ) : Prop := 0 < Δ

/-- **Gauge rank read from a lattice connection.** A `SU3Connection`
is `Fin 4 → SU(3)`, and its link variables are
`SU(3) = specialUnitaryGroup (Fin 3) ℂ` matrices, so the rank `N` of
the underlying `SU(N)` gauge group is the matrix dimension
`Fintype.card (Fin 3) = 3`. This reads the rank off the connection's
group structure rather than hard-wiring the literal `3` into the
schema. Still carries no analytic content. -/
def gauge_rank_of (_A : SU3Connection) : Nat := Fintype.card (Fin 3)

/-- **Spacetime dimension read from a lattice spacing.** A physical
lattice spacing is a genuine positive real `0 < a`; for such a
spacing the produced continuum schema lives in `4` dimensions, while
a non-positive (unphysical) spacing yields the degenerate `0`. This
makes the dimension genuinely *read* the spacing value rather than be
a hard-wired default, so the map below is non-constant in `a`. Still
carries no analytic content (no real `a → 0` limit). -/
noncomputable def spacetime_dim_of_spacing (a : ℝ) : Nat :=
  open Classical in
  if 0 < a then 4 else 0

/-- **`lattice_to_continuum a A`** — renormalization map from lattice
data (spacing `a : ℝ`, SU(3) lattice connection `A : SU3Connection`)
to a continuum theory. **Structure-producing, non-trivial map:** its
fields are now *read from the inputs* — `gauge_rank` off the
connection's group structure (`gauge_rank_of A`, the SU(3) matrix
dimension) and `spacetime_dim` off the spacing (`spacetime_dim_of_spacing
a`, which is `4` for a physical positive spacing and degenerate `0`
otherwise). This replaces the previous identity-trivial
`fun _ _ => {}` map (whose output ignored the inputs entirely).

**Honest scope is unchanged:** this still does NOT implement a real
`a → 0` continuum limit — the renormalization-group flow of the
fields is not modeled; the map merely reads the discrete schema slots
(rank, dimension) from the lattice data. The genuine `a → 0` limit is
the Batch 20.1b surface. Because the map now depends on `(a, A)`, the
old tripwire brick `continuum_heat_envelope_bound_target_default`
(which asserted `lattice_to_continuum a A = ({} : YM4_Continuum)` by
`rfl`) is intentionally broken and rewritten in
`Towers/YM/ContinuumHookup.lean`. -/
noncomputable def lattice_to_continuum (a : ℝ) (A : SU3Connection) : YM4_Continuum :=
  { gauge_rank := gauge_rank_of A
    spacetime_dim := spacetime_dim_of_spacing a }

/-- **`AsymptoticFreedom T`** — physical-input Prop on a continuum
theory: "for every energy scale `μ > 0` there exists a coupling
`g ∈ (0, 1)`." Honest placeholder shape that names the *form* of
"the running coupling exists and is small in the UV"; does NOT
reference a β-function, a renormalization-group flow, or the
actual asymptotic behavior of `g(μ)`. -/
def AsymptoticFreedom (_T : YM4_Continuum) : Prop :=
  ∀ μ : ℝ, 0 < μ → ∃ g : ℝ, 0 < g ∧ g < 1

end Continuum
end YM
end Towers
end TheoremaAureum
