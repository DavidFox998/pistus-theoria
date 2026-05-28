/-
================================================================
Batch 178.1 / SLinkDef — link action S_link (preparatory def)
================================================================

DEFINITION ONLY. Real `Finset.sum` of `plaquetteEnergy` over the
plaquette index type. No CLM. No norm claims. No `S_link_nonneg`
(that needs the SU(2) trace bound `Re tr ≤ 2`, NOT in mathlib
v4.12.0 — see Batch 177.1 header tripwire). Surface #1 OPEN.
No wall gain claimed.

Corrections applied to the shawlocked snippet (all required for
the file to even elaborate):

* (1) **Import.** Snippet imported
  `Towers.YM.LatticeGauge.PlaquetteEnergy`, which does not exist —
  the module path is flat `Towers.YM.PlaquetteEnergy` (namespace
  ≠ directory in this tower). Moreover `Plaquette` is declared in
  `Towers.YM.KoteckyPreissRealKP` (Batch 177.2), NOT in
  `PlaquetteEnergy`. Import `KoteckyPreissRealKP` (which
  transitively re-exports `PlaquetteEnergy`) so both `Plaquette`
  and `plaquetteEnergy` are in scope.

* (2) **`[NeZero L]`.** `plaquetteEnergy` carries `[NeZero L]`
  (PlaquetteEnergy.lean:108); the snippet's `S_link` /
  `S_link_const_one` omitted it, so the calls would not resolve.
  Added to all three declarations.

* (3) **`plaquetteEnergy` arity.** Snippet wrote
  `plaquetteEnergy p`, but the function takes `(U x μ ν)`
  (a gauge config plus a site and two directions). Pivoted to
  `plaquetteEnergy U p.1 p.2.1 p.2.2`, the exact projection form
  already used in `kotecky_preiss_real_kp` (Batch 177.2) — `.1`
  / `.2` resolve through the `Plaquette` `def` barrier.

* (4) **`Fintype` instance.** `unfold Plaquette` alone leaves
  `Fintype (Lattice d L × …)`; `Lattice` is itself a `def`
  (`Fin d → Fin L`), so typeclass search stalls at the second
  barrier. Added `Lattice` to the `unfold` list — the resulting
  `Fintype ((Fin d → Fin L) × Fin d × Fin d)` resolves via
  `Pi.fintype` (`DecidableEq (Fin d)` + `Fintype (Fin L)`).

* (5) **`S_link_const_one` proof.** Snippet used `simp [S_link,
  plaquetteEnergy_const_one, Finset.sum_const_zero]`. Pivoted to
  the explicit `Finset.sum_eq_zero` route closing each summand
  with `plaquetteEnergy_const_one d L p.1 p.2.1 p.2.2` (Batch
  177.1) — the established Dirac-support equality pattern
  (`configRefl_const_one` 169.1, `wilson_*_const_one` 170.2 /
  171.2). Matches `T_real := 0`: the action vanishes at the
  Dirac-support point `U ≡ const 1`.

NOTE — UNVERIFIED PENDING TASK #208. The mathlib olean cache is
absent (0 oleans; `towers-build` hangs on
`Mathlib.Algebra.BigOperators.Group.Finset`, `lake exe cache get`
fails to fetch). This file therefore CANNOT be compiled or
`#print axioms`-checked yet, and is deliberately NOT wired into
`lakefile.lean` or `scripts/check-towers.sh` — adding an
unverified root could break the entire build graph on
cache-restore. Wire + BRICKS-register + axiom-check happen once
#208 restores the cache. Wall stays 542. No brick counted.
================================================================
-/

import Towers.YM.KoteckyPreissRealKP

namespace TheoremaAureum.Towers.YM.LatticeGauge

open scoped BigOperators

/-- `Fintype` instance for the plaquette index type. `Plaquette`
    and `Lattice` are both `def`s, so both must be unfolded before
    instance search can see `(Fin d → Fin L) × Fin d × Fin d`. -/
instance instFintypePlaquette {d L : ℕ} : Fintype (Plaquette d L) := by
  unfold Plaquette Lattice
  infer_instance

/-- **`S_link β U`** — total Wilson link action: the real
    `Finset.sum` of the per-plaquette energy `plaquetteEnergy`
    (Batch 177.1) over every plaquette of the lattice. Preparatory
    definition; no operator / no norm claim. -/
noncomputable def S_link {d L : ℕ} [NeZero L] (β : ℝ) (U : GaugeConfig d L) : ℝ :=
  ∑ p : Plaquette d L, plaquetteEnergy U p.1 p.2.1 p.2.2

/-- **Brick (`S_link_const_one`).** At the constant-1 gauge
    configuration `U ≡ (1 : G)` the total action vanishes: every
    summand is `0` by `plaquetteEnergy_const_one` (Batch 177.1),
    so the sum is `0` by `Finset.sum_eq_zero`. Dirac-support
    equality consistent with `T_real := 0`; does NOT prove
    `S_link_nonneg` (needs the deferred SU(2) trace bound). -/
theorem S_link_const_one {d L : ℕ} [NeZero L] (β : ℝ) :
    S_link β (fun _ : Link d L => (1 : G)) = 0 := by
  unfold S_link
  apply Finset.sum_eq_zero
  intro p _
  exact plaquetteEnergy_const_one d L p.1 p.2.1 p.2.2

end TheoremaAureum.Towers.YM.LatticeGauge
