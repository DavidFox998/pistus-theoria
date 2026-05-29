# Morning Star Project · Theorema Aureum 143 (Volume I)

**For Batches 1–177 + Tasks #188/#189 see `docs/CHANGELOG.md`**
(also: full per-batch wall-jump tables, tactic notes, proof
sketches, drift footnotes, env var docs, stack, where-things-live,
user preferences, gotchas, pointers — all rolled into CHANGELOG by
the Wall-510 / Wall-539 / Wall-542 trims).

- **Wall:** 543 BRICKS (script-reported by `scripts/check-towers.sh`)
- **YM Surface #1:** Open
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem`
  (`#print axioms` returns `[]`; also `[]` on `H2_WeilTransfer` and
  `M9_WeilTransfer_All`)
- **Mathlib:** v4.12.0 only · trio axioms only
  `{propext, Classical.choice, Quot.sound}` · no `sorry` / `admit`
  in any landed brick · YM and NS towers stay `Status: Open` in
  `docs/ROADMAP.md`

## Locked invariants (every batch must hold these)

- Axiom footprint = classical trio
  `{propext, Classical.choice, Quot.sound}`; no new research-grade
  axioms.
- Mathlib v4.12.0 only; no `sorry` / `admit` in any landed brick.
- YM and NS towers stay `Status: Open` in `docs/ROADMAP.md`;
  Surface #1 and Surface #2 stay OPEN. "Surface #1 CLOSED" /
  "μ > 0" / "removes the Attempts sorry" / "Mass Gap proven"
  claims are REFUSED — every YM Measure-surface brick is trivially
  or vacuously true under the Dirac haar stand-in
  (`T_OS = 0` / `T_real = 0`), NOT under any real Wilson transfer
  operator.
- `kotecky_preiss_criterion` remains a `sorry` in
  `Towers/Attempts/ClusterExpansion.lean` (invariant-locked).

## Pending / in-flight (not yet landed)

- **Wall 571-B / [YM1-LB-Core]** — `Towers/YM/LatticePositivity.lean`
  written + VERIFIED (`namespace TheoremaAureum.YM_MassGap`). Pure-core
  (no mathlib, no imports, `Int`/`Nat` only): `lattice_positivity`
  proves a finite sum of integer squares is `≥ 0` and `= 0` iff every
  term is `0` — the trivial discrete shadow of "H ≥ 0", NOTHING more.
  `#print axioms …lattice_positivity` = [] (strictly empty) via direct
  `lean` (lake-free). Registered as [YM1-LB-Core], NOT [YM1]; makes NO
  mass-gap / μ>0 / Surface-#1 claim — Surface #1 stays OPEN, YM Status
  Open. NOT in `scripts/check-towers.sh` BRICKS (that path is
  lake-gated → script-reported wall unchanged). ℝ companion now
  landed as Wall 572 / [YM1-LB-Real] (see next entry).

- **Wall 572 / [YM1-LB-Real]** — `Towers/YM/LatticePositivityReal.lean`
  written + VERIFIED (`namespace TheoremaAureum.YM_MassGap`). ℝ
  companion of Wall 571-B: `hamiltonian_pos` proves, for the IDENTITY
  stand-in `H = 1` on the finite real ℓ² space `PiLp 2 (fun _ : Fin n
  => ℝ)`, that `0 ≤ ⟪ψ, H ψ⟫_ℝ` with equality iff `ψ = 0`
  (`real_inner_self_nonneg` + `inner_self_eq_zero`) — the trivial
  Hilbert-space shadow of "H ≥ 0", NOTHING more. `H` is NOT the
  Wilson / Yang–Mills transfer operator. `#print axioms
  …hamiltonian_pos` = `[propext, Classical.choice, Quot.sound]`
  (classical trio — accepted criterion, NOT []) via `lake env lean`.
  Registered as [YM1-LB-Real], NOT [YM1]; makes NO mass-gap / μ>0 /
  spectral-gap / Surface-#1 claim — Surface #1 stays OPEN, YM Status
  Open. Real (non-identity) `H` and any gap statement deferred to
  Wall 573. NOT in `scripts/check-towers.sh` BRICKS (lake-gated →
  script-reported wall unchanged). Verify: see the file's
  honest-scope header.

- **Wall 573 / [YM1-GR]** — `Towers/YM/GapReduction.lean` written +
  VERIFIED (`namespace TheoremaAureum.YM_MassGap`). REDUCTION/SCAFFOLD
  ONLY: `gap_reduction` proves that for any `A : H → H` and `m : ℝ`,
  IF `A` is coercive (`hco : ∀ ψ, m * ‖ψ‖^2 ≤ ⟪ψ, A ψ⟫_ℝ`, taken as a
  HYPOTHESIS) THEN `A` is bounded below (`∀ ψ, m * ‖ψ‖ ≤ ‖A ψ‖`) — via
  Cauchy–Schwarz (`real_inner_le_norm`) + `nlinarith`. `A`, `m`, `hco`
  are ALL free variables/hypotheses: this constructs NO Hamiltonian,
  proves NO `m > 0` exists, and proves NO spectral gap — only the
  trivial direction "assumed gap ⟹ bounded below" (operator-level
  shadow of "a gap forbids soft modes"). `#print axioms
  …gap_reduction` = `[propext, Classical.choice, Quot.sound]`
  (classical trio) via `lake env lean`; no `sorry`. Registered as
  [YM1-GR], NOT [YM1]; makes NO mass-gap / μ>0 / Surface-#1-CLOSED
  claim — Surface #1 stays OPEN, YM Status: Open. The EXISTENCE of `m`
  for the real YM transfer Hamiltonian is the open problem, untouched
  (next: Task #208 to unblock the real `H` construction). NOT in
  `scripts/check-towers.sh` BRICKS (lake-gated → wall unchanged).
  Verify: see the file's honest-scope header.

- **Batch 178.1 / SLinkDef** — `Towers/YM/SLinkDef.lean` written
  (`S_link` + brick `S_link_const_one`), NOT registered to
  `lakefile.lean` / `scripts/check-towers.sh` BRICKS array, no wall
  gain claimed. Verification blocked by the task #208 cache wipe
  (the `lake update` re-clone race). Clean verify sequence once the
  cache is stable: `lake exe cache get` → `lake build Towers`
  (produces dependency oleans incl. `KoteckyPreissRealKP.olean`) →
  `lake env lean Towers/YM/SLinkDef.lean` + `#print axioms
  TheoremaAureum.Towers.YM.LatticeGauge.S_link_const_one`.

## Gotcha — do NOT run `towers-build` / `lake update` casually

The `towers-build` workflow (and any `lake update`) re-clones the
vendored mathlib checkout and wipes its oleans, requiring a
`lake-recovery` (`lake exe cache get`) pass. Verify bricks via
direct `lake env lean <file>` + `#print axioms` instead.
