# Morning Star Project · Theorema Aureum 143 (Volume I)

**For Batches 1–177 + Tasks #188/#189 see `docs/CHANGELOG.md`**
(also: full per-batch wall-jump tables, tactic notes, proof
sketches, drift footnotes, env var docs, stack, where-things-live,
user preferences, gotchas, pointers — all rolled into CHANGELOG by
the Wall-510 / Wall-539 / Wall-542 trims).

- **Wall:** 528 BRICKS (`${#BRICKS[@]}` in `scripts/check-towers.sh`;
  521 + 7 from **Task #211** below. Was 545 pre-deferral — prior `543`
  headline was stale by 2. See **Task #208** below for the −29-entry /
  24-module deferral.)
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

- **GREEN: 528 bricks** (`scripts/check-towers.sh` `BRICKS`).
- **Registered YM walls** (tagged, landed as files — these three are
  the lake-gated `[YM1-*]` walls, NOT counted in the 528 BRICKS array):
  571-B `[YM1-LB-Core]` (`lattice_positivity`, axioms `[]`), 572
  `[YM1-LB-Real]` (`hamiltonian_pos`, classical trio), 573 `[YM1-GR]`
  (`gap_reduction`, classical trio).
- **Wall 574 `[YM1]`** scaffolded in `Towers/YM/MassGap574.lean`.
  INVARIANT-LOCKED. Carries `sorry`. NOT in BRICKS, not a lakefile
  root, does not elaborate.
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
- **Drift corrections:** (1) wall is **528**, not 521 (Task #211's +7
  landed). (2) The real Wilson transfer Hamiltonian `H` construction
  (replacing the `H = 1` stand-in in `MassGap574.lean`) is a **FUTURE
  task**, NOT Task #208 — #208 already MERGED (build-unblock + OS
  deferral). The currently in-progress task is **#214** (real
  per-plaquette polymer activity weights), a different surface.

## Task #211 — SU(3) distance: chordal → genuine geodesic via matrix exp (2026-05-29)

Upgraded `Towers/YM/RiemannianGeometry.lean` from the Task #189 chordal
(Hilbert–Schmidt) `d_SU3` to a genuine **geodesic** (Riemannian) distance
**`d_SU3_geodesic`** built from mathlib's *real* matrix exponential
`NormedSpace.exp ℂ` (the "minimal exp-map dev" the brief asked for —
reusing the Banach-algebra exp from
`Mathlib.Analysis.Normed.Algebra.MatrixExponential` rather than vendoring a
bespoke one). Definitions added:

- **`IsSU3Lie X`** — membership in 𝔰𝔲(3): `star X = -X` (skew-Hermitian) ∧
  `Matrix.trace X = 0` (traceless).
- **`geodesicLengths g h`** — the set `{ √(hsNormSq X) : X ∈ 𝔰𝔲(3),
  exp X = ↑gᴴ↑h }` of Killing/HS lengths of Lie-algebra logarithms of
  `g⁻¹h`.
- **`d_SU3_geodesic g h := sInf (geodesicLengths g h)`** — the bi-invariant
  geodesic distance `inf { ‖X‖_HS : exp X = g⁻¹h }`.

Genuine (non-vacuous) constructible clauses proved:
- **`d_SU3_geodesic_nonneg`** (`Real.sInf_nonneg`; every length is a `√`),
- **`d_SU3_geodesic_self`** (`X = 0` is a real log: `exp 0 = 1 = ↑gᴴ↑g` by
  unitarity, `√0 = 0`),
- **`d_SU3_geodesic_symm`** (the genuine involution `X ↦ -X`:
  `exp(-X) = (exp X)⁻¹ = ↑hᴴ↑g` via `Matrix.exp_neg` +
  `Matrix.inv_eq_right_inv`, length-preserving by `hsNormSq_neg`, so the
  length sets are *equal*),
- **`d_SU3_geodesic_le_of_mem`** (the genuine infimum property).

Relating / comparability bricks:
- **`d_SU3_eq_chordal_id`** — `d_SU3 g h = √(hsNormSq (↑gᴴ↑h - 1))`
  (bi-invariance reduction of the chordal distance to the identity),
- **`d_SU3_geodesic_eq_d_SU3_diag`** — both distances agree (= 0) on the
  diagonal (unconditional comparability point),
- **`d_SU3_le_geodesic_of_contracts`** — the genuine comparability **bound**
  `d_SU3 g h ≤ d_SU3_geodesic g h`, a *reduction* from two explicit honest
  hypotheses (NOT `sorry`): `ChordalContractsExp` (the contraction estimate
  `‖exp X - 1‖_HS ≤ ‖X‖_HS` on 𝔰𝔲(3)) and `(geodesicLengths g h).Nonempty`
  (existence of a Lie-algebra log = surjectivity of `exp` on compact SU(3)).

**Remaining tripwire (locked).** The two hypotheses of the comparability
bound are exactly the open analytic inputs: the spectral theorem for
skew-Hermitian matrices (for `ChordalContractsExp`) and surjectivity of
`exp` on compact connected Lie groups (for nonemptiness) — neither in
mathlib v4.12.0. Without nonemptiness `sInf ∅ = 0`, so `d_SU3_geodesic` is
honestly only a pseudo-distance lower scaffold off the diagonal; the
triangle inequality / cut-locus analysis stays open. `d_SU3` is unchanged
(still the chordal distance); the geodesic distance is an additive sibling.

- **+7 BRICKS** (521 → 528) registered in `scripts/check-towers.sh`:
  `d_SU3_geodesic_nonneg`, `d_SU3_geodesic_self`, `d_SU3_geodesic_symm`,
  `d_SU3_geodesic_le_of_mem`, `d_SU3_eq_chordal_id`,
  `d_SU3_geodesic_eq_d_SU3_diag`, `d_SU3_le_geodesic_of_contracts`.
- **Verified:** `#print axioms` on all seven = `[propext,
  Classical.choice, Quot.sound]` (classical trio) via `lake env lean` on a
  self-contained copy (mathlib-only); full-file `lake env lean
  Towers/YM/RiemannianGeometry.lean` exits 0, and the consumer
  `Towers/YM/PeterWeylHeatVaradhan.lean` still exits 0. The wiping
  `towers-build` / `check-towers.sh` was NOT run (lake-update re-clone
  gotcha below). New imports: `Mathlib.Analysis.Normed.Algebra.MatrixExponential`,
  `Mathlib.LinearAlgebra.Matrix.NonsingularInverse`,
  `Mathlib.Data.Real.Archimedean`.
- Makes NO mass-gap / μ>0 / Surface-#1 / Surface-#2 claim — Surface #1
  and #2 stay OPEN, YM **Status: Open**.

## Task #210 — genuine off-diagonal SU(3) heat-kernel envelope (strip form) (2026-05-29)

Removed the diagonal gate `hx : d_SU3 x 1 = 0` from the geometric
Varadhan brick. The original
`Heat_kernel_envelope_real_le_varadhan_geometric` only bounded the
heat-kernel envelope on the diagonal locus (where the decay factor
`exp(-(d_SU3 x 1)²/4t) = 1`). The new headline brick
**`Heat_kernel_envelope_real_le_varadhan_geometric_offdiag`** holds for
EVERY `x : SU3` (including the off-diagonal locus `d_SU3 x 1 > 0`),
carrying the genuine `exp(-(d_SU3 x 1)²/4t)` decay factor. All landed in
`Towers/YM/PeterWeylHeatVaradhan.lean` (original gated brick kept
intact). Added:

- **`hsNormSq_nonneg`** — generic `0 ≤ hsNormSq M` for any `M : Matrix
  (Fin 3) (Fin 3) ℂ` (sum of `Complex.normSq` entries via
  `trace_fin_three` + `normSq_eq_conj_mul_self`; finished with
  `linarith` over the 9 `normSq_nonneg` facts since `positivity` lacks a
  `normSq` extension).
- **`d_SU3_sq_le_twelve`** — `(d_SU3 x 1)² ≤ 12` for all `x : SU3`. Key
  bound: from `hsNormSq (↑x - 1) = 6 - 2·Re(tr ↑x)` and
  `hsNormSq (↑x + 1) = 6 + 2·Re(tr ↑x) ≥ 0` (via `hsNormSq_nonneg`),
  so `Re(tr ↑x) ≥ -3`, hence `(d_SU3 x 1)² = 6 - 2·Re(tr ↑x) ≤ 12`.
  Helper rewrites `hsNormSq_sub_one_eq`, `hsNormSq_add_one_eq` use the
  unitary relation `star ↑x * ↑x = 1` and manual ring expansion
  (`sub_mul`/`mul_sub` + `abel`; `noncomm_ring` not imported).
- **`varadhan_C_offdiag`** / **`varadhan_C_offdiag_pos`** — recalibrated
  amplitude carrying `exp(12/(4·t_lo))` (vs the original `varadhan_C`'s
  `exp(1/t_lo)`), the constant needed to absorb the now-genuine decay
  factor uniformly on the strip.

The bound is the STRIP form only (`t ∈ [t_lo, t_top]`) — NOT the
small-`t` Varadhan / Molchanov asymptotic (false in the literal
unrestricted shape as `t → 0⁺`), and `d_SU3` remains the chordal
pseudo-distance, NOT the geodesic distance.

- **+3 BRICKS** (518 → 521) registered in `scripts/check-towers.sh`:
  `hsNormSq_nonneg`, `d_SU3_sq_le_twelve`,
  `Heat_kernel_envelope_real_le_varadhan_geometric_offdiag`.
- **Verified:** `#print axioms` on all three = `[propext,
  Classical.choice, Quot.sound]` (classical trio) via `lake env lean`
  on the live file (warm oleans, lake-free of the wiping `towers-build`
  / `check-towers.sh` per the gotcha). Full-file `lake env lean
  Towers/YM/PeterWeylHeatVaradhan.lean` exits 0.
- Makes NO mass-gap / μ>0 / Surface-#1 / Surface-#2 claim — Surface #1
  and #2 stay OPEN, YM **Status: Open**.

## Task #209 — SU(3) distance: pseudo-distance → metric predicate + tripwire (2026-05-29)

Strengthened the SU(3) distance machinery in
`Towers/YM/RiemannianGeometry.lean` from a pseudo-distance to a real
*metric* **predicate** (no real geodesic distance constructed). Added:

- **`IsMetricOnSU3 d`** — `IsPseudoDistOnSU3 d ∧ separation
  (`d g h = 0 → g = h`) ∧ triangle inequality`. Makes the two axioms a
  pseudo-distance is missing (separation, triangle) explicit.
- **`cWit`** — concrete non-identity SU(3) element `diag(-1,-1,1)`,
  built via the proven `diagNegOneOneMat` `!![…]` +
  `mem_specialUnitaryGroup_iff` + `fin_cases`/`simp` idiom from
  `MassGap.lean`. Brick **`cWit_ne_one`** : `cWit ≠ (1 : SU3)` (from the
  `(0,0)` entry `-1 ≠ 1`).
- **Tripwire `not_IsMetricOnSU3_const_zero`** — PROVES the `d ≡ 0`
  stand-in (`fun _ _ => 0`) FAILS `IsMetricOnSU3`: its separation clause
  applied to `cWit, 1` would force `cWit = 1`, contradicting
  `cWit_ne_one`. Honestly records that the current Task #189 chordal
  `d_SU3` (and the older `d_SU3 ≡ 0` stand-in) is only a
  pseudo-distance, NOT a metric.

Imports added: `Mathlib.LinearAlgebra.Matrix.Determinant.Basic`,
`Mathlib.Data.Matrix.Notation`. **+2 BRICKS** (516 → 518) registered in
`scripts/check-towers.sh`. Constructs NO real distance, makes NO
mass-gap / μ>0 / Surface-#1 claim — Surface #1 stays OPEN, YM
**Status: Open**.

- **Drift note:** the task brief referenced the stale `d_SU3 ≡ 0`
  stand-in; the live `d_SU3` is now the Task #189 chordal distance, so
  the tripwire targets the explicit `fun _ _ => 0` (documented in the
  file docstring) rather than `d_SU3` itself.
- **Verified:** `#print axioms` on BOTH `cWit_ne_one` and
  `not_IsMetricOnSU3_const_zero` = `[propext, Classical.choice,
  Quot.sound]` (classical trio), via `lake env lean` on a self-contained
  copy of the file (mathlib-only imports, no Towers deps). The wiping
  `towers-build` / `check-towers.sh` was NOT run (lake-update re-clone
  gotcha below).
- **Env-recovery note:** an earlier verify attempt that ran
  `lake env lean` from a *workflow* (after an environment reset had left
  `.lake/packages/mathlib/.git` corrupt) triggered a mathlib re-fetch
  that wiped the vendored worktree + build oleans. Recovered with
  `scripts/restore-lake-git.sh` → `git checkout -f <pinned-rev>` (to
  repopulate the mathlib worktree, which the restore script's
  wrong-rev branch does NOT do on its own) → `lake exe cache get`. The
  warm cache is back. Lesson reinforced: do NOT drive `lake` from a
  fresh workflow when the vendored `.git` may be corrupt — restore
  first.

## Task #208 — Mathlib build unblock + OS-surface deferral (2026-05-29)

Root cause of the red `towers-build`: `Towers/YM/LatticeGauge.lean`
and `Towers/YM/WilsonAction.lean` had been trimmed to **pure-core**
(zero mathlib imports), which DELETED the `G` (= SU(2)),
`GaugeConfig`, and `plaquette` substrate ("deferred to Wall 570+").
That orphaned every brick standing on it.

Resolution (user-approved, deferral path):

- **Repaired in place (4 modules, no statement change):**
  `SpectralBound` (import → `Mathlib.Analysis.Normed.Algebra.Spectrum`),
  `KoteckyPreiss` (add `import Towers.YM.LatticeGauge` for `Link` +
  `noncomputable polymerWeight`), `PolymerModel` (add `LatticeGauge`
  + `Mathlib.Data.Set.Pairwise.Lattice`, `noncomputable
  polymerWeightReal`, `PairwiseDisjoint` via `Set` coercion),
  `MassGapEnvelope` (`open scoped InnerProductSpace` for `⟪·,·⟫_ℂ`).
  All four verified: `#print axioms` = classical trio.

- **Deferred (24 modules → 29 BRICKS entries removed):** the full
  Osterwalder–Schrader surface (TRI #9–#13: OS-1 reflection
  positivity, OS-2 invariance, OS-3 locality, OS-4 clustering) plus
  the real Kotecký–Preiss / transfer-kernel chain. = 5 direct
  orphans (`LatticeRotation`, `LatticeAction`, `TimeReflection`,
  `Support`, `PlaquetteEnergy`) + 19 transitive importers. Removed
  from `lakefile.lean` roots (99 → 75) and `scripts/check-towers.sh`
  `BRICKS` (545 → 516). The `.lean` files are KEPT on disk for
  re-registration once the `G`/`GaugeConfig`/`plaquette` substrate
  returns at Wall 570+. These bricks made NO mass-gap / μ>0 claim
  (all vacuous `const_one` / Dirac stand-ins) — Surface #1 stays
  OPEN, YM Status Open. No invariant changed.

- **Verified:** direct `lake build Towers` = green (the wiping
  `check-towers.sh` / `towers-build` was NOT run — it `lake update`s
  and re-clones mathlib per the gotcha below).

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
