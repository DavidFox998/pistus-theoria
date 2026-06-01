# Morning Star Project · Theorema Aureum 143 (Volume I)

**Full history → `docs/CHANGELOG.md`** (per-batch wall-jump tables, tactic
notes, proof sketches, drift footnotes, env vars, stack, where-things-live,
gotchas). `replit.md` is the live-ops doc; the CHANGELOG is the version
history. Roadmap → `docs/ROADMAP.md`.

## Current status — 2026-06-01

- **HODGE 12-CURVE SET — `Towers/Hodge/Twelve.lean` (2026-06-01).** Real
  documented CM data only (M10/M13), NO 269. `exceptional_12 : Finset ℕ :=
  {27,32,36,49,64,81,121,144,169,196,225,256}` (the 12 CM levels `N` of M10/M13
  Table 1 — the `CM_LIST`; the two NON-square cross-check levels 289,361 are
  EXCLUDED). `structure CM_Curve where id:ℕ deriving DecidableEq`;
  `ExceptionalSet₁₂ := exceptional_12.image CM_Curve.mk`; `theorem twelve_card :
  card = 12 := by decide` (genuine finite fact). `C s := Σ_{p∈s} log p·p/(p-1)`
  + `BostBound s := C s > 2·√13` (formula ATTESTED in M5
  `paper/modules/m05-bostbound.tex`). `opaque S : CM_Curve → Finset ℕ` (the
  per-curve prime set, NOT computed — docs give it numerically only for `S_4`).
  The violation conjecture is a NAMED OPEN Prop `TwelveViolation_Surface := ∃ X
  ∈ ExceptionalSet₁₂, ¬ BostBound (S X)`, asserted by NO theorem. Registered as
  lakefile root `Towers.Hodge.Twelve`; direct-lean EXIT=0; classical trio
  (`exceptional_12`/`S` use the `{propext, Quot.sound}` subset). REFUSED from the
  drafted spec (would break the locks): `native_decide` (emits
  `Lean.ofReduceBool`, off-trio) → `decide`; `theorem twelve_check := by sorry`
  (emits `sorryAx`) → the named open Prop; `opaque S := sorry` → bodyless
  `opaque`. SORRY: 0, no new axiom, NOT a brick. Proves NOTHING — no
  Hodge/BSD/Bost-violation claim; the conjecture stays OPEN. Detail →
  `docs/CHANGELOG.md`.
- **HODGE α₀ DATA LAYER — `Towers/Hodge/Defs.lean` (2026-06-01).** Formalization
  Step 1, user-chosen **Option 2** (number-theory layer only). Pure DEFINITIONS
  file (no proofs / no computation / no `#eval`): `alpha_0 := 299 + π/10`,
  `nearestIntDist x := |x - round x|` (distance to nearest integer, NOT abs),
  `S_alpha_0 p := Nat.Prime p ∧ nearestIntDist (p·α₀) < 1/p`, `S_14 : Finset ℕ`
  (the REAL 14 certified M4 primes, copied verbatim from
  `paper/modules/m04-esete4.tex` — `2,3,19,191,3993746143633,…,
  3494164289073996361661384853541`), `S_4 := {2,3,19,191}`. Registered as
  lakefile root `Towers.Hodge.Defs`; direct-lean verify EXIT=0; `#print axioms`
  classical trio (`S_14`/`S_4` use the `{propext, Quot.sound}` subset). SORRY: 0,
  no new axiom, NOT a brick. DROPPED from the original spec (would not compile /
  was false): `import Mathlib.NumberTheory.CM` + `CM_Curve` (do NOT exist in
  v4.12.0), `BostBound`/`ExceptionalSet₂₆₉`/`AnalyticObstruction`/`C`, the three
  `:= sorry` placeholders (sorry⟹sorryAx), and the fabricated `S_14` list
  (`379,757,911,…` — NOT in the certificate). Proves NOTHING; asserts NO
  `S_14 =` exceptional-set equality; NO Hodge/BSD/mass-gap claim. Detail →
  `docs/CHANGELOG.md`.
- **TOWER SEPARATION — COMPILING CanonicalSurfaces REGISTRIES (2026-06-01).**
  Deleted the doc-only `Towers/CanonicalSurfaces.lean` and replaced it with TWO
  COMPILING registries split by tower: `Towers/YM/CanonicalSurfaces.lean` (`def
  YM_Clay_Open : Prop` = `(∀ T, MassGap_YM4_Clay_Surface T) ∧
  kotecky_preiss_criterion_Surface ∧ (∀ d L n [NeZero L][NeZero n] U,
  YM_mass_gap_Surface …)`) and `Towers/NS/CanonicalSurfaces.lean` (`def NS_Open
  : Prop` = `(∀ u, enstrophy_bound_global_Surface u) ∧ (∀ s,
  leray_proj_ker_eq_grad_Surface s)`). Both compile (direct-lean bypass), both
  `#print axioms` = classical trio, both OPEN (conjunctions of hypotheses,
  asserted by NO theorem). Added as `lakefile.lean` roots. They only NAME/group
  the existing open surfaces — discharge NOTHING; NO "YM proven" / "mass gap" /
  "NS solved" claim. NS file created under an EXPLICIT user unfreeze order,
  purely additive (NS otherwise still frozen). VACUOUS count UNCHANGED at 11
  (2 deprecated + 9 flagged) — the false "Vacuous: 0" was REFUSED. SORRY: 0;
  classical trio. Per-file detail → `docs/CHANGELOG.md`.
- **VACUOUS SURFACE PURGE + HONEST REGISTRY (2026-05-31).** Audit found 11 of
  the post-purge named `*_Surface` Props were VACUOUS under the stand-in defs
  (`spectral_radius_def := 1` / `Decay_constant_real := 1` ⟹ `1 < 1`
  unsatisfiable; `Plaquette_action_def := 0` / `Polymer_activity_def := 0` etc.
  ⟹ `0 ≤ 1` trivially true) — they encode nothing. The 2 fully-vacuous files
  moved to `Towers/Deprecated/` (`UniformGap_Placeholder`, `Perron_Placeholder`;
  lakefile roots renamed); the other 9 are flagged in-place with a VACUOUS-AUDIT
  header in `Attempts/{ClusterExpansion,T_g}.lean`. The 6 GENUINE non-trivial
  open surfaces were indexed in the doc-only `Towers/CanonicalSurfaces.lean`
  (SUPERSEDED 2026-06-01 by the split compiling registries `Towers/YM/` +
  `Towers/NS/CanonicalSurfaces.lean` — see top bullet):
  real-object — NS `Leray.leray_proj_ker_eq_grad`, NS
  `Enstrophy.enstrophy_bound_global` (simplified `‖u t 0‖` seminorm), YM
  `Transfer.kotecky_preiss_criterion` (real `T_L`), YM
  `Transfer.trivial_polymer_set_null` (real `haarN`); shadow-object
  (necessary-not-sufficient, SCALAR operator) — YM `Clay.MassGap_YM4_Clay`, YM
  `MassGap574.YM_mass_gap`. Plus 4 abstract placeholder-bundle hypotheses
  (`OSHilbert`×3, `T_g.Transfer_compact`). NO `iff` / `NSGlobalRegularity` claim
  — FOUR of the six are YM, only TWO are NS. Registry placed OUTSIDE `Towers/NS/`
  to respect the NS freeze (it only NAMES surfaces; no import/modification of
  NS). SORRY: 0; classical trio; every surface stays OPEN.
- **SORRY PURGE (2026-05-31).** Every live `sorry` proof-term in `Towers/`
  converted to a named open `Prop` hypothesis (Option B); BSD `axiom`s →
  hypotheses. Pattern: `theorem foo (a) : Goal := by sorry` ⟹
  `def Foo_Surface (a) : Prop := Goal` + `theorem foo (a) (h : Foo_Surface a) :
  Goal := h`. Logical hygiene only — discharges NO surface, proves NO new
  result. Grep audit across `Towers/`: 0 bare `sorry`, 0 `axiom`, 0 `admit`
  proof-terms (remaining matches are docstring prose). Dashboard carries the
  HONEST "Open-surface status" badge (`YM: OPEN (conditional) · HODGE: OPEN via
  AnalyticObstruction · NS: OPEN · SORRY: 0`). Done under a one-pass user
  override of the NS freeze + YM locks; those locks remain in force for future
  work. Per-file detail → `docs/CHANGELOG.md`.
- **NS Tower 540 — weak→strong chain, Phases 1–6 COMPLETE, FROZEN at the Clay
  boundary (Status: Open).** Milestone `NS-540-phase6-clay-boundary` @ checkpoint
  `c5f29fb4390e5dda83ffdbfcae5dea2333cf5c12`. Both Clay surfaces stay OPEN:
  Surface #1 global regularity (`global_smooth_exists : Prop`, named hypothesis,
  classical trio) and Surface #2 weak existence (`weak_solution_exists`, HONEST
  combinator over the MODELED `WeakNS` surrogate, nonlinear term dropped — NOT
  literal Leray–Hopf). Per-phase detail → `docs/CHANGELOG.md` + `docs/ROADMAP.md`.
- **YM wall series** (Wall251b–Wall263, Wall262a, S4Numerics,
  WilsonPositivitySU2, EntropyBound, RiemannianGeometry) — all bricks, in BRICKS,
  `sorry`-free, classical trio. Each proves NO YM result, discharges NO open
  surface, makes NO mass-gap / μ>0 / Surface-#1 claim. Full per-wall index →
  `docs/CHANGELOG.md`.
- **YM Transfer / polymer / positivity / measure scaffolding** (NONE bricks,
  classical trio) — real SU(3) Haar stack, integral transfer `T_L` with
  `‖T_L‖ ≤ 1`, Wilson positivity, cluster-expansion `polymerActivity`. Every
  lemma is necessary-not-sufficient; the spectral lower bound stays OPEN as the
  named open-surface `Transfer.kotecky_preiss_criterion` (a `Prop` hypothesis
  post-purge, formerly a disclaimed `sorry`). NO mass-gap / Surface-#1 claim.
  Detail → `docs/CHANGELOG.md`.
- **Wall 574 `[YM1]`** (`Towers/YM/MassGap574.lean`) — `YM_mass_gap` elaborates
  against the real Step-4/5 `H` / `spectrum_bound` and now threads the named-open
  surface `YM_mass_gap_Surface` (a `Prop` hypothesis post-purge, formerly a
  `sorry`); OPEN, INVARIANT-LOCKED, NOT in BRICKS. `H = wilsonAction U • 𝟙` is
  the scalar shadow, NOT the real Wilson transfer operator — no mass-gap claim.
  (The companion `YM_mass_gap_nontrivial` discharges `hpos` for non-trivial `U`
  and is `sorry`-free, but only over the same scalar shadow.) NB: some in-file
  docstrings still say "keeps its `sorry`" — stale prose, not the proof-term.
- **Registered YM walls** (tagged, lake-gated, NOT in BRICKS): 571-B
  `[YM1-LB-Core]`, 572 `[YM1-LB-Real]`, 573 `[YM1-GR]`, 575 `[YM1-SB]`. All
  classical trio.
- **Geometry / Hodge leaves** (NOT bricks): `Wall264_H4Vertices.lean` (600-cell
  vertex geometry, machine-checked) and `Towers/Hodge/ZoeComparisonTest.lean`
  (HODGE_STATUS: OPEN, conditional reduction over the named-open
  `AnalyticObstruction`). Detail → `docs/CHANGELOG.md`; prior superseded Hodge
  work (Lemma 7.6, M* Transform) is retracted there.
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem` (also `H2_WeilTransfer`,
  `M9_WeilTransfer_All`). Every landed brick is classical-trio-only.
- **Mathlib:** v4.12.0 only. **YM Surface #1: OPEN** — no `m > 0` claim while
  the `sorry` stands.
- **Wall count:** the BRICKS array in `scripts/check-towers.sh`
  (`${#BRICKS[@]}`) is the source of truth, not this file.
- **Deferred:** 24 OS/KP modules unregistered; `.lean` files kept on disk, await
  Wall 570+/574 with the real SU(3) `H`.

## Locked invariants (every batch must hold these)

- Axiom footprint = classical trio `{propext, Classical.choice, Quot.sound}`;
  no new research-grade axioms.
- Mathlib v4.12.0 only; no `sorry` / `admit` / `sorryAx` in any landed brick.
- YM and NS towers stay `Status: Open` in `docs/ROADMAP.md`; Surface #1 and
  Surface #2 stay OPEN. "Surface #1 CLOSED" / "μ > 0" / "removes the Attempts
  sorry" / "Mass Gap proven" claims are REFUSED — every YM Measure-surface
  brick is trivially or vacuously true under the Dirac haar stand-in
  (`T_OS = 0` / `T_real = 0`), NOT under any real Wilson transfer operator.
- `kotecky_preiss_criterion` stays OPEN in
  `Towers/Attempts/ClusterExpansion.lean` — a named open-surface hypothesis
  post-purge (formerly a `sorry`); invariant-locked, do not discharge.
- **NS FREEZE.** `Towers/NS/*` is FROZEN at the Clay boundary (milestone
  `NS-540-phase6-clay-boundary`). NO further commits to `Towers/NS/` without an
  explicit unfreeze order from the user. Surface #1 (`global_smooth_exists`) and
  Surface #2 (modeled `weak_solution_exists`) stay OPEN; "NS solved" /
  "regularity proven" / "weak solutions exist (literally)" claims are REFUSED.
  - **Unfreeze exception (2026-05-31): `Towers/NS/Wall300_Scaffold.lean`** added
    under an EXPLICIT user unfreeze order. HONEST CONDITIONAL combinator
    `navier_stokes_global_regularity` threading three named open surfaces (weak
    existence, local regularity, global continuation) through
    `Regularity.weak_implies_strong` to a MODELED global-smoothness shape.
    SORRY: 0, axiom-free, NOT a brick. Proves NO regularity; Surfaces #1/#2 stay
    OPEN. NS otherwise still frozen.
  - **Unfreeze exception (2026-06-01): `Towers/NS/CanonicalSurfaces.lean`** added
    under an EXPLICIT user unfreeze order. Purely ADDITIVE registry — `def
    NS_Open : Prop` that NAMES/groups the two genuine NS open surfaces
    (`enstrophy_bound_global_Surface`, `leray_proj_ker_eq_grad_Surface`);
    imports/modifies no frozen NS proof. SORRY: 0, classical trio, NOT a brick.
    Discharges NOTHING; Surfaces #1/#2 stay OPEN. NS otherwise still frozen.
- **Infra (in progress).** Disabling the `towers-build` auto-run and permanently
  locking the mathlib `v4.12.0` pin is tracked as a background Project Task
  (#294); until it lands, every boot/merge can still wipe the pin and require
  the manual recovery in "Operational gotchas".

## Operational gotchas

- **Git-tag creation is restricted for the main agent.** `git tag` (and other
  git writes) are blocked with "Destructive git operations are not allowed in
  the main agent" — they must go through a background Project Task. This repo's
  working convention is therefore to track milestones as **prose + SHA** in
  `replit.md` / `docs/ROADMAP.md` / `docs/CHANGELOG.md` (e.g. "YM frozen at
  `c8f6a7ed`", "milestone `NS-540-phase2b-stokes` @ checkpoint `f4becd5`"),
  NOT as literal git refs. Replit checkpoints already capture the merged state.
- **Do NOT run `towers-build` / `lake update` casually.** Both re-clone the
  vendored mathlib checkout and wipe its oleans, requiring a `lake-recovery`
  (`lake exe cache get`) pass. Verify bricks via direct `lake env lean <file>`
  + `#print axioms` — **but `lake env` is ALSO destructive when the
  `v4.12.0` tag is missing.** `lake env` re-resolves `inputRev: v4.12.0` from
  the mathlib git; if the tag does not resolve it fetches from remote and wipes
  the oleans, exactly like `lake update` (confirmed 2026-05-30). So BEFORE any
  `lake env lean`, assert `git -C lean-proof-towers/.lake/packages/mathlib
  rev-parse v4.12.0` succeeds. Recovery if wiped: `scripts/restore-lake-git.sh`
  (run it TWICE — first run restores `.git` at the pinned rev, second run
  rehydrates the empty worktree via its `git checkout -- .` heal), then recreate
  the tag (`git -C lean-proof-towers/.lake/packages/mathlib tag -f v4.12.0
  809c3fb3b5c8f5d7dace56e200b426187516535a`), then run
  `scripts/fetch-mathlib-oleans.sh` to re-download the oleans.
- The destructive mathlib re-clone is triggered when the restore-tar's vendored
  mathlib `.git` lacks the `v4.12.0` tag (lake fetches from remote to resolve
  `inputRev: v4.12.0`). Fix: recreate the tag locally after any
  `restore-lake-git.sh` worktree rebuild —
  `git -C .lake/packages/mathlib tag v4.12.0 <HEAD>` (manifest `rev` already =
  HEAD). It is NOT persisted in the restore tar.
- **Direct-lean verify bypass.** When the `v4.12.0` tag is unresolved (so `lake
  env` would wipe the oleans) but the oleans are intact, compile a brick with a
  hand-built `LEAN_PATH` over each `.lake/packages/*/.lake/build/lib` +
  `.lake/build/lib` and invoke `lean <file>` directly from `lean-proof-towers/`.

## User preferences

- Ship clean: no `sorryAx`, no `sorry` / `admit` in any landed/registered brick.
- Be honest about scope — never overstate a placeholder/stand-in as a real
  result (no false "mass gap proven" / "Surface #1 closed" claims).

## theorema-certs dashboard

Web artifact (`artifacts/theorema-certs`) — the certificate-ledger dashboard.
Has e2e Playwright specs under `tests/e2e/`. Run a spec with:
`PLAYWRIGHT_MANAGED_WEB_SERVER=1 pnpm --filter @workspace/theorema-certs exec playwright test <name>`.
Typecheck with `pnpm --filter @workspace/theorema-certs run typecheck` (NOT
`build`, which needs workflow-provided `PORT`/`BASE_PATH`). The dashboard
consumes generated hooks from `@workspace/api-client-react`; after editing the
OpenAPI spec run `pnpm --filter @workspace/api-spec run codegen`, and if the
consuming typecheck reports missing exports rebuild the composite lib
declarations with `pnpm run typecheck:libs` (its `exports` resolves through the
project-reference `dist/*.d.ts`, which can go stale).

## Wall256 — SU(3) conditional reduction (research phase)

`Towers/YM/Wall256_Scaffold.lean` (commit `8eeab54`, tracked on main, NOT a
brick). Classical trio, 0 `sorry`, YM_STATUS: OPEN. **Conditional reduction
only** — `strong_coupling_decay_of_open_inputs` threads three explicit OPEN
hypotheses through the genuine `Wall256Note.kp_summable_of_truncatedActivity`
comparison test to an abstract two-point decay shape. Proves NO mass gap, NO
`μ > 0`, NO Surface-#1; LATTICE scope, NOT Clay. The conclusion is valid ONLY
IF the three hypotheses hold; none is discharged or scheduled:

1. **`w1_SU3_bound`** (`hw1 : w1 < 1/7`) — strict single-site SU(3) Haar weight
   bound. STRICT matters: `= 1/7` gives `I = log 7` and a divergent entropy
   series. In the scaffold `w1 : ℝ` is abstract, so `hw1` is formally trivial;
   a real `w1 := ∫_{SU(3)} exp(-β·S) d haarSU3` needs SU(3) character theory or
   verified cubature, absent from mathlib v4.12.0.
2. **`OS_cluster_bound`** (`hOS : w1 < 1/7 → TruncatedActivityBound a`) — the
   Osterwalder–Seiler strong-coupling Ursell/cluster step (NOT OS reflection
   positivity).
3. **`KP_implies_decay`** (`h_bridge`) — the Brydges–Federbush step:
   KP-summability ⟹ geometric two-point clustering with `ρ < 1` (Friedli–Velenik
   2018, Ch. 5; absent from mathlib v4.12.0).
