# Morning Star Project · Theorema Aureum 143 (Volume I)

**For Batches 1–177 + Tasks #188/#189 see `docs/CHANGELOG.md`**
(also: full per-batch wall-jump tables, tactic notes, proof
sketches, drift footnotes, env var docs, stack, where-things-live,
user preferences, gotchas, pointers — all rolled into CHANGELOG by
the Wall-510 / Wall-539 / Wall-542 trims).

- **Wall:** 539 BRICKS (`${#BRICKS[@]}` in `scripts/check-towers.sh`;
  528 + 3 from **Task #217** + 1 from **Task #218** + 3 from
  **Task #219** + 7 from **Task #255** below. Was 545 pre-deferral — prior
  `543` headline was stale by 2. See **Task #208** below for the −29-entry /
  24-module
  deferral.)
  - Rebase note (Task #208): the `LatticeGauge.lean` `G`/`GaugeConfig`
    substrate was kept RESTORED (mathlib imports + defs) rather than
    left trimmed — additive, wall unchanged at 516; the deferred
    dependents stay out of `lakefile.lean` roots. `SpectralBound`
    resolves to the `spectrum.spectralRadius_le_nnnorm` proof form.
- **YM Surface #1:** Open
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem`
  (`#print axioms` returns `[]`; also `[]` on `H2_WeilTransfer` and
  `M9_WeilTransfer_All`)
- **Mathlib:** v4.12.0 only · trio axioms only
  `{propext, Classical.choice, Quot.sound}` · no `sorry` / `admit`
  in any landed brick · YM and NS towers stay `Status: Open` in
  `docs/ROADMAP.md`

## Tower Status — 2026-05-29 12:47 PDT

- **GREEN: 539 bricks** (`scripts/check-towers.sh` `BRICKS`; +3 from
  Task #219; +7 from Task #255 — strict Wilson action positivity, see
  section below).
- **Registered YM walls** (tagged, landed as files — the lake-gated
  `[YM1-*]` walls, NOT counted in the BRICKS array; now FOUR after
  Task #248 Step 5, registered in `scripts/check-towers.sh`):
  571-B `[YM1-LB-Core]` (`lattice_positivity`, axioms `[]`), 572
  `[YM1-LB-Real]` (`hamiltonian_pos` / `hamiltonian_self_inner_eq`,
  real `H U = wilsonAction U • ψ`, classical trio), 573 `[YM1-GR]`
  (`gap_reduction`, classical trio), 575 `[YM1-SB]` (`spectrum_bound`
  + `spectrum_bound_H_iff`: `spectrum_bound (H U) m ↔ m ≤
  wilsonAction U`, classical trio).
- **Wall 574 `[YM1]`** in `Towers/YM/MassGap574.lean` — now ELABORATES
  against the real Step-4/5 `H` / `spectrum_bound` (Task #248 Step 5
  wiring) and carries `(hpos : 0 < wilsonAction U)` so the statement is
  honest (not vacuum-false). Still carries `sorry`; INVARIANT-LOCKED;
  NOT in BRICKS, not a lakefile root. No mass-gap claim.
- **Deferred:** 24 OS/KP modules unregistered (Task #208). `.lean`
  files kept on disk; await Wall 570+/574 with the real SU(3) `H`.
- **Surface #1: OPEN.** No `m > 0` claim while the `sorry` stands.
- **Infra:** mathlib cache self-heal **LANDED** — Task #213 MERGED
  (`scripts/fetch-mathlib-oleans.sh`: authoritative `lake exe cache get`,
  no from-source fallback, heals a corrupt/partial cache); follow-up
  #245 was **CANCELLED** (folded into #213, not a separate task). Trio
  audits for `hamiltonian_pos` / `gap_reduction` remain cached from the
  Wall 572/573 GREEN landings (files byte-identical since); a live
  `#print axioms` re-run is now possible via the resilient
  `towers-build` once it completes a clean clone+cache cycle.

## Task #248 — Real Wilson Transfer Hamiltonian (COMPLETE — 2026-05-29 14:40 PDT)

- YM mass gap reduced to strict action positivity:
  `∃ m>0, spectrum_bound (H U) m ↔ 0 < wilsonAction U`.
- Scalar shadow `H = wilsonAction U • 𝟙` now replaces the id placeholder.
- Surface #1 OPEN. YM Status: Open. No μ>0 claim.
- Next: prove `0 < wilsonAction U` for `U ≠ const 1`.
- Axioms: all new bricks trio-only. Only `sorry` in `MassGap574.lean`.
- **Full per-step detail + Tasks #208–#218 →** `docs/CHANGELOG.md`.

## Task #255 — Strict Wilson Action Positivity (COMPLETE — 2026-05-29)

- NEW file `Towers/YM/WilsonPositivity.lean` (namespace
  `TheoremaAureum.Towers.YM.LatticeGauge`; imports `Towers.YM.WilsonAction`
  + `Towers.YM.PeterWeylHeatVaradhan`). Registered: `lakefile.lean` root
  + 7 BRICKS in `scripts/check-towers.sh` (wall 532 → **539**).
- Headline brick `wilsonAction_pos_of_nontrivial`:
  `∀ U, (∃ x μ ν, wilsonPlaquette U x μ ν ≠ 1) → 0 < wilsonAction U`.
  The bare ordered-pair SU(3) Wilson plaquette action is strictly
  positive off the vacuum — a finite triple sum of non-negative
  per-plaquette energies (`plaquetteEnergy_nonneg`) with ≥1 strictly
  positive term (`plaquetteEnergy_pos_iff`), via `Finset.sum_pos'` at
  each level.
- 7 bricks (all sorry-free, axioms = classical trio
  `[propext, Classical.choice, Quot.sound]`, verified live via
  `lake build` + `#print axioms`): `hsNormSq_eq_zero_iff`,
  `traceRe_le_three`, `traceRe_eq_three_iff`,
  `wilsonPlaquette_star_mul_self`, `plaquetteEnergy_nonneg`,
  `plaquetteEnergy_pos_iff`, `wilsonAction_pos_of_nontrivial`.
- INVARIANT-LOCKED: makes NO mass-gap / μ>0 / Surface-#1 claim. This is
  scalar-sector ACTION positivity only — `wilsonAction : GaugeConfig → ℝ`,
  NOT the real Wilson transfer Hamiltonian. Wall 574 / `MassGap574.lean`
  UNTOUCHED (still carries its `sorry`). Surface #1 stays OPEN, YM
  Status: Open.
- Verify-note gotcha (logged for next session): the Towers oleans on
  disk were STALE after the env-wipe + `restore-lake-git.sh` recovery
  (`WilsonAction.olean` predated the Task #248 genuine-SU(3) defs).
  `lake build Towers.YM.WilsonPositivity` rebuilt the stale chain
  (LatticeGauge/WilsonAction) from source against the freshly-fetched
  mathlib cache. `lake exe cache get` succeeded on a direct foreground
  run (the backgrounded fetch had been SIGKILL'd mid cache-exe compile).

## Task #219 — carry the wider t-range through to continuum + mass-gap envelope (2026-05-29)

Routed the Task #194 upper-widened strip bound
`Heat_kernel_envelope_real_le_varadhan_widened_upper` (retuned amplitude
`varadhan_C_widened`, valid `t`-window up to
`varadhan_t_top_widened = 2·varadhan_t_top`) through the continuum schema
slot and into the mass-gap envelope constant. Both downstream files
previously routed through the *original* strip bound
`Heat_kernel_envelope_real_le_varadhan`, so they did not benefit from the
widened window. Three additive bricks (+3 → wall 535):

- **`Towers/YM/ContinuumHookup.lean`** (imports + opens
  `Towers.YM.VaradhanStripWidened`):
  - **`continuum_heat_envelope_bound_widened_upper`** — widened-signature
    companion of `continuum_heat_envelope_bound`: for `varadhan_t_lo ≤ t
    ≤ varadhan_t_top_widened`, `Heat_kernel_envelope_real t ≤
    varadhan_C_widened · exp(-(varadhan_c/t)) / t^4`. Delegates to the
    upper-widened strip bound; lattice inputs `(a, A)` discarded.
  - **`continuum_heat_envelope_pos_widened`** — positivity of the widened
    RHS on the widened window.
- **`Towers/YM/MassGapEnvelope.lean`** (imports + opens
  `Towers.YM.VaradhanStripWidened`):
  - **`mass_gap_envelope_constant_widened`** (def) +
    **`mass_gap_envelope_constant_widened_pos`** — the widened envelope
    constant `varadhan_C_widened / varadhan_t_top_widened^4 > 0`. Honest
    positive-real constant, NO spectral content (no widened `IsMassGap`
    closure added).

- **+3 BRICKS** (532 → 535) registered in `scripts/check-towers.sh`.
- **Verified:** `lake build Towers.YM.ContinuumHookup
  Towers.YM.MassGapEnvelope` = exit 0 (full Towers lib green on the
  rehydrated warm cache: `restore-lake-git.sh` + `fetch-mathlib-oleans.sh`
  `cache get` → 4845 oleans). `#print axioms` on all three new bricks =
  `[propext, Classical.choice, Quot.sound]` (classical trio), no `sorry`.
- Makes NO mass-gap / μ>0 / Surface-#1/#2/#3 claim — pure plumbing of an
  existing bounded-`t` STRIP bound through the placeholder continuum
  schema. Surfaces #1/#2/#3 stay OPEN, YM **Status: Open**.

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

- **Wall 574 / [YM1] — mass-gap TARGET scaffold (2026-05-29)** —
  `Towers/YM/MassGap574.lean` written. DOCUMENTATION STUB ONLY, **NOT a
  proof**: states `theorem YM_mass_gap : ∃ m > 0, spectrum_bound H m`
  carrying a single `sorry`. References two **unbuilt** symbols — `H`
  (the real Wilson / Yang–Mills transfer Hamiltonian, NOT the `H = 1`
  stand-in of Wall 572 `hamiltonian_pos`) and `spectrum_bound` (the
  spectral-gap predicate). Because both are undefined, the file does
  NOT elaborate; it is deliberately NOT a `lakefile.lean` root and
  **NOT registered in `scripts/check-towers.sh` BRICKS** (a
  `sorry`-bearing decl must never enter the wall). INVARIANT-LOCKED:
  makes NO mass-gap / μ>0 / Surface-#1-CLOSED claim while the `sorry`
  stands — **Surface #1 stays OPEN**, YM Status: Open. Script-reported
  wall **unchanged at 528** (Task #211's +7 already landed; this stub
  adds 0). The real `H` construction = a FUTURE task (the already-merged
  Task #208 was the build-unblock + OS deferral, NOT the real-H build).
  - **Drift note:** the dictated ledger line said "GREEN at 521 / real
    H = Task #208"; corrected to the machine truth — wall = **528**
    (post-#211), and real-H is a not-yet-created task, not #208.
  - **Verify note:** `lattice_positivity` re-printed live this session
    (`= []`, plain `lean`, pure-core). Live re-print of `hamiltonian_pos`
    was BLOCKED — a `lake env lean` invocation tripped the corrupt-`.git`
    re-clone gotcha (wiped the mathlib worktree), and the `towers-build`
    self-heal currently FAILS on partial-cache recovery (the exact
    in-flight bug of Tasks #213/#245); repopulating the worktree needs
    `git checkout -f`, disallowed for the main agent. `hamiltonian_pos`
    / `gap_reduction` = classical trio stands from the last green run
    (files byte-identical since landing `0cd8741` / `77a53f4`).

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
