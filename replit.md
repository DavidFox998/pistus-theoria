# Morning Star Project · Theorema Aureum 143 (Volume I)

**Full history → `docs/CHANGELOG.md`** (per-batch wall-jump tables, tactic
notes, proof sketches, drift footnotes, env vars, stack, where-things-live,
gotchas). `replit.md` is the live-ops doc; the CHANGELOG is the version
history. Roadmap → `docs/ROADMAP.md`.

## Current status — 2026-05-30

- **Wall:** 539 BRICKS (`${#BRICKS[@]}` in `scripts/check-towers.sh`). The
  source of truth for the count is the script, not this file.
- **Axiom debt:** `[]` on `TheoremaAureum.main_theorem` (`#print axioms`
  returns `[]`; also `[]` on `H2_WeilTransfer` and `M9_WeilTransfer_All`).
  Every landed brick is classical-trio-only.
- **Mathlib:** v4.12.0 only.
- **YM Surface #1: OPEN.** No `m > 0` claim while the `sorry` stands.
- **Wall 574 `[YM1]`** (`Towers/YM/MassGap574.lean`) elaborates against the
  real Step-4/5 `H` / `spectrum_bound` and carries `(hpos : 0 < wilsonAction U)`,
  but still carries a `sorry`; INVARIANT-LOCKED, NOT in BRICKS, not a lakefile
  root. The companion `YM_mass_gap_nontrivial` discharges `hpos` for
  non-trivial `U` and is `sorry`-free, but `H = wilsonAction U • 𝟙` is the
  scalar shadow, NOT the real Wilson transfer operator — so no mass-gap claim.
- **Registered YM walls** (tagged files, lake-gated `[YM1-*]`, NOT in BRICKS):
  571-B `[YM1-LB-Core]` (`lattice_positivity`, axioms `[]`), 572 `[YM1-LB-Real]`
  (`hamiltonian_pos`), 573 `[YM1-GR]` (`gap_reduction`), 575 `[YM1-SB]`
  (`spectrum_bound` + `spectrum_bound_H_iff`). All classical trio.
- **Deferred:** 24 OS/KP modules unregistered (Task #208); `.lean` files kept
  on disk, await Wall 570+/574 with the real SU(3) `H`.
- **Infra:** mathlib cache self-heal landed (`scripts/fetch-mathlib-oleans.sh`:
  authoritative `lake exe cache get`, no from-source fallback).
- **Honest measure infra (NOT a brick, not in BRICKS):**
  `Towers/YM/SU3Instances.lean` carries the real `SU(3)` instance stack
  (`Group` / `TopologicalGroup` / `CompactSpace` / `BorelSpace`), `haarSU3 =
  haarMeasure ⊤`, and now `haarN n := Measure.pi (fun _ : Fin n => haarSU3)` —
  the product Haar measure on `Fin n → SU(3)` link configurations — plus
  `IsProbabilityMeasure` instances for both. `#print axioms` on `haarSU3` /
  `haarN` = classical trio (`[propext, Classical.choice, Quot.sound]`), verified
  live. This is measure-theoretic scaffolding ONLY: built on the *real* Haar
  measure (NOT the Dirac stand-in), but it makes **no** `m > 0` / mass-gap /
  `μ > 0` claim and does **not** touch Surface #1 (stays OPEN).
- **Real integral transfer operator `T_L` (NOT a brick, not in BRICKS):**
  `Towers/YM/Transfer.lean` now carries a `sorry`-free `noncomputable def T_L
  (L β) : Lp ℝ 2 (haarN (4·L⁴)) → Lp ℝ 2 (haarN (4·L⁴))`, the genuine integral
  operator `(T_L f)(U) = ∫ V, exp(-β·wilsonAction(V⁻¹·U))·f(V) d(haarN)` — a real
  heat kernel over the *real* product Haar measure built from the *real* SU(3)
  Wilson action (via `linkEquiv`/`toGauge`, continuity + `Memℒp` proofs). `#print
  axioms T_L` = classical trio (no `sorryAx`), verified live. Makes **no**
  spectral / mass-gap / `m > 0` claim; Surface #1 stays OPEN; YM stays
  `Status: Open`. The companion `Transfer.kotecky_preiss_criterion` is a
  **disclaimed single-`sorry` placeholder** (own namespace `…YM.Transfer`,
  reports `sorryAx`, NOT a brick) — it does NOT touch the invariant-locked
  `kotecky_preiss_criterion` `sorry` in `Towers/Attempts/ClusterExpansion.lean`.

## Locked invariants (every batch must hold these)

- Axiom footprint = classical trio `{propext, Classical.choice, Quot.sound}`;
  no new research-grade axioms.
- Mathlib v4.12.0 only; no `sorry` / `admit` / `sorryAx` in any landed brick.
- YM and NS towers stay `Status: Open` in `docs/ROADMAP.md`; Surface #1 and
  Surface #2 stay OPEN. "Surface #1 CLOSED" / "μ > 0" / "removes the Attempts
  sorry" / "Mass Gap proven" claims are REFUSED — every YM Measure-surface
  brick is trivially or vacuously true under the Dirac haar stand-in
  (`T_OS = 0` / `T_real = 0`), NOT under any real Wilson transfer operator.
- `kotecky_preiss_criterion` remains a `sorry` in
  `Towers/Attempts/ClusterExpansion.lean` (invariant-locked).

## Operational gotchas

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

## User preferences

- Ship clean: no `sorryAx`, no `sorry` / `admit` in any landed/registered brick.
- Be honest about scope — never overstate a placeholder/stand-in as a real
  result (no false "mass gap proven" / "Surface #1 closed" claims).

## theorema-certs dashboard

Web artifact (`artifacts/theorema-certs`) — the certificate-ledger dashboard.
Has e2e Playwright specs under `tests/e2e/`. Run a spec with:
`PLAYWRIGHT_MANAGED_WEB_SERVER=1 pnpm --filter @workspace/theorema-certs exec playwright test <name>`.
