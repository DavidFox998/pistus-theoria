# Morning Star Project · Theorema Aureum 143 (Volume I)

Publisher: **Morning Star Project (independent research)**
License: **All rights reserved (license pending review)**

Volume I: **Theorema Aureum 143 — Certificate Ledger**, plus the
MorningStar-Lab CLI surface for probing L-functions against a
Genesis-sealed append-only ledger.

For the version history and full design notes of v1.0 → v1.9 Stage 2A-Prime
(seven-layer surface, Three Guns CLI, sign-change sieve, etc.) see
`docs/CHANGELOG.md`. For a 3-command reproducibility recipe see
`docs/REPRODUCE.md`. For the full architecture write-up see
`docs/MorningStar_Architecture.pdf`.

## Single source of truth — before you edit anything

`scripts/print-direction.sh` and `data/THEOREMA_AUREUM_143.manifest.txt`
are the canonical "who/what/where" surface. They print the project
name, publisher, license, sealed-ledger path, Genesis seal, and
public-alias symlink. If anything in this README ever drifts from
those, the script and the manifest win — fix this file, not them.

**Rule: additive only — never edit sealed files.** That means
`data/hits.txt` (preamble lines 1–9 are Genesis-sealed),
`data/THEOREMA_AUREUM_143.manifest.txt`, `scripts/print-direction.sh`,
and the Lean spine in `lean-proof/` are not surfaces for casual edits.
Append new probes through `kernel.probe()` / the Three-Guns CLI; do
not hand-edit the ledger.

## Volume I — what this repo actually ships

**Theorema Aureum 143: A Formal Spine and Computational Ledger for RH.**

Three real, defensible deliverables:

1. **The Ledger** — `data/hits.txt`, a 20,964-line append-only DAG of
   L-function probes with a Genesis-sealed preamble (SHA
   `eecbcd9a…875f`). Tamper-evident, reproducible from a fresh
   checkout (`docs/REPRODUCE.md`). Publishable computational data.
2. **The Spine** — Lean 4 deductive chain
   `H1_ArakelovPositivity → H2_WeilTransfer → main_theorem` in
   `lean-proof/`, with `#print axioms TheoremaAureum.main_theorem`
   returning `[]`. That is a real formal theorem: *given* the
   Prop-level stubs declared in `Certificates.lean`, the spine closes
   without new axioms. It is **not** a formal proof of RH itself.
3. **The Infrastructure** — append-only ledger discipline, per-line
   SHA chain, Genesis-seal verifier, drift guard (`post-merge.sh` +
   `lean-proof` CI), and a single-source-of-truth banner
   (`scripts/print-direction.sh`). Real software, real reproducibility.

For the longer-term research direction — RH, Yang-Mills, Navier-Stokes,
the 280-curve cohort, Bost-Connes — see `docs/ROADMAP.md`. Those are
**Open**; this repo does not claim to have proved them.

## Run & operate

- `pnpm --filter @workspace/api-server run dev` — API server
- `pnpm run typecheck` — full typecheck
- `pnpm run build` — typecheck + build all packages
- `pnpm --filter @workspace/api-spec run codegen` — regen API hooks + Zod from OpenAPI
- `pnpm --filter @workspace/db run push` — push DB schema (dev only)
- `python lab.py` — open the MorningStar-Lab REPL
- `python lab.py -c "zeta_sniper(1)"` — one-shot probe
- `bash scripts/validate-morningstar.sh` — full kernel→bridge→lake harness
- `bash scripts/print-direction.sh` — print the canonical "you are here" banner

## Environment

- Required: `DATABASE_URL` (Postgres)
- Required (auto-set by Replit): `DEFAULT_OBJECT_STORAGE_BUCKET_ID`, `PUBLIC_OBJECT_SEARCH_PATHS`, `PRIVATE_OBJECT_DIR`
- Optional: `LEAN_REBUILD_TOKEN` — shared rebuild token. Unset ⇒ rebuild endpoint returns 503. Callers send `Authorization: Bearer <token>`. Only one rebuild at a time (others 409). Referees may opt-in attribution via `X-Referee-Name` (`[A-Za-z0-9 _.-]{1,64}`).
- Optional: `LEAN_REBUILD_TOKENS` — comma-separated named tokens (`alice:tokA,bob:tokB`) for real per-referee attribution. Named tokens take precedence over the shared one; a matched named token wins over any `X-Referee-Name` header. At least one of the two must be set to enable rebuilds.

### Brute-force lockout

Per-IP limiter on `/api/lean/verify/rebuild`: 5 bad-token attempts / 15
min ⇒ 15 min lockout (`failuresByIp` in
`artifacts/api-server/src/routes/lean.ts`). Same limiter applies to
`/api/lean/lockouts` and `/api/lean/lockouts/clear` — admin endpoints
don't bypass it.

Dashboard surface: the **Lean 4 Verification** card has a "Brute-force
lockouts" panel (`panel-lean-lockouts`) once a referee token is set,
polling `/api/lean/lockouts` every 15s. Active lockouts shown in red,
pre-lockout failing IPs in amber, each with a Clear button.
In-memory only — resets on server restart, no email/webhook out of
the box.

## Stack

- pnpm workspaces, Node 24, TypeScript 5.9
- API: Express 5, PostgreSQL + Drizzle ORM, Zod (`zod/v4`), Orval codegen
- Frontend: React + Vite, Tailwind, shadcn/ui, wouter, TanStack Query
- File storage: Replit Object Storage (presigned PUT)
- Kernel: Python 3, mpmath (arbitrary precision), Lean 4 (`leanprover/lean4:v4.12.0`) + mathlib v4.12.0

## Where things live

- `scripts/print-direction.sh` — single source of truth for project name, publisher, license, paths
- `data/THEOREMA_AUREUM_143.manifest.txt` — public manifest (unsealed, regeneratable) that mirrors the above
- `data/hits.txt` — **canonical** Genesis-sealed append-only probe ledger (preamble lines 1–9 sealed against SHA `eecbcd9a…875f`)
- `data/theorema-aureum-143-hits.txt` — public symlink alias for `data/hits.txt` (byte-identical; do not treat as a separate file)
- `data/CASUALTY_LOG.md`, `data/M13_CERT.txt` — incident log + M13 certificate header
- `lib/api-spec/openapi.yaml` — API contract (source of truth)
- `lib/db/src/schema/certificates.ts` — Drizzle schema
- `artifacts/api-server/src/routes/{certificates,storage,lean}.ts` — routes
- `artifacts/theorema-certs/src/` — React frontend (dashboard, certificate list/detail, walkthrough, Miegakure 600-cell viewer)
- `kernel.py`, `lab.py`, `lean_bridge.py` — MorningStar-Lab CLI surface
- `lean-proof/` — Lean 4 project (axiom debt = [], drift-guarded)
- `scripts/check-genesis-seal.py`, `scripts/check-lean-proof.sh`, `scripts/validate-morningstar.sh`, `scripts/post-merge.sh`
- `tests/test_kernel.py`, `tests/test_morningstar.py`
- `docs/MorningStar_Architecture.{tex,pdf}`, `docs/SiteMap.md`, `docs/ProofIndex.md`, `docs/CHANGELOG.md`, `docs/REPRODUCE.md`, `docs/ROADMAP.md`

## Architecture (one-liners)

- Certificates in PostgreSQL; SHA hashes, parent SHAs (JSON string), Lean theorem names are first-class columns.
- PDF upload = presigned-URL PUT to GCS, then PATCH `pdfObjectPath`.
- Master manifest SHA (M7) is hardcoded in the summary endpoint.
- Ledger preamble (lines 1–9 of `data/hits.txt`) is sealed; SHA-256 must match `eecbcd9a…875f` before any append.
- Lean `main_theorem` axiom debt = [] is re-verified on every merge by `scripts/post-merge.sh` and in CI by the `lean-proof` workflow (`STRICT_LEAN_CHECK=1`).

## Tests / validations

- `kernel-numerics` workflow — `pytest tests/test_kernel.py` (mpmath backend numerics + Three-Guns invariants + sieve dry-run)
- `morningstar-tamper` workflow — `pytest tests/test_morningstar.py` (Genesis-seal tamper-evidence; also invoked from `post-merge.sh`)
- `lean-proof` workflow — strict-mode `check-lean-proof.sh`; fails closed if `lake` missing

## Honest-scope guards

- `hit_437` / `hit_1094` are tautologies (`True := trivial`). Their *names* reference the OpenCV cube counts; their *statements* claim nothing about number theory.
- `probe()` and friends never call SageMath. Out-of-scope inputs are recorded with `NEEDS_SAGE` and a `reason=` field, never silently stubbed.
- `elliptic_stub` writes a SHA-stamped intent line tagged `ELLIPTIC_STUB`; the returned dict has no `L_*` keys. `test_kernel.py` pins this.
- `zeta_sieve` is a parallelised sign-change sieve, **not** the Odlyzko-Schönhage 1991 FFT. The docstring says so.
- **YM mass-gap schema concretized (2026-05-26, Task #51).** The three
  previously `sorry`-backed schema defs in `Towers/YM/MassGap.lean`
  (`HilbertSpace`, `YMHamiltonian`, `IsEigenstate`) and the two in
  `Towers/NS/EnergyIneq.lean` (`H1Norm`, `HasFiniteEnergy`) were
  replaced with concrete, minimal, mathlib-backed stand-ins
  (`EuclideanSpace ℂ (Fin 3)`, sum of `Matrix.trace.re` over the four
  SU(3) components, scaling-form eigenstate predicate; Euclidean norm
  at the origin; bounded-amplitude predicate). Both files are now
  `sorry`-free and `YM_mass_gap_statement` / `NS_global_regular_statement`
  type-check without `sorryAx`. The schemas are **not** the Clay
  surfaces — finite-dim Hilbert space, no Sobolev / Wightman / OS
  machinery. YM and NS towers remain `Status: Open` in `docs/ROADMAP.md`.
  New brick `IsEigenstate_zero_zero` lives in BRICKS and proves the
  zero state is a trivial eigenstate of the zero Hamiltonian
  (`0 = 0 * (‖0‖ * ‖0‖)`), demonstrating the concretized schema is
  no longer dead weight. YM brick wall: **19**.
- **NS energy schema is load-bearing (2026-05-26, Task #56).** Three
  trio-clean bricks added to `Towers/NS/EnergyIneq.lean` exercising
  the Task #51 concretizations of `H1Norm` and `HasFiniteEnergy`:
  `H1Norm_zero` (`H1Norm 0 t = 0`), `HasFiniteEnergy_zero` (witness
  `M = 0`), and `H1Norm_nonneg` (`0 ≤ H1Norm u t`, delegating to
  `norm_nonneg`). These are the NS analogue of the YM
  `IsEigenstate_zero_zero` move — minimal demonstrations that the
  post-Task-#51 NS schema defs are real, usable, mathlib-flavoured
  surfaces, not opaque `sorry`-defs. All three pass the axiom-
  footprint check with `{propext, Classical.choice, Quot.sound}`.
  Total brick wall: **32**. NS tower status unchanged: **Open**
  (`docs/ROADMAP.md` § 3). These are NOT statements about the H¹
  Sobolev norm, the L² energy bound, or any Leray-Hopf solution.
- **YM Hamiltonian schema is load-bearing (2026-05-26, Task #55).**
  Four additional trio-clean bricks added to `Towers/YM/MassGap.lean`
  that each reference at least one of the Task #51 + Task #55
  concretized schema defs (`HilbertSpace`, `YMHamiltonian`,
  `IsEigenstate`); three reference at least two, and one references
  all three. The bricks are: `YMHamiltonian_one_eq_twelve` (the
  all-ones SU(3) connection has Hamiltonian value `12 = 4 · 3`, the
  first numerical answer extracted from the def);
  `IsEigenstate_zero_const` (the zero Hamiltonian is degenerate on
  every `ψ : HilbertSpace`); `IsEigenstate_of_forall_zero` (any
  extensionally-zero Hamiltonian is an eigenstate on every ψ); and
  `YMHamiltonian_not_isEigenstate_zero` (the `YMHamiltonian` is NOT
  an eigenstate at `(0 : HilbertSpace)` — derives `(12 : ℝ) = 0`
  contradiction via the first brick). All four pass the
  axiom-footprint check with `{propext, Classical.choice, Quot.sound}`.
  YM brick wall: **26**. YM tower status unchanged: **Open**
  (`docs/ROADMAP.md` § 2). The schema is still the placeholder
  (ℓ²(ℕ,ℂ), sum-of-traces, scaling-form predicate), NOT the Clay
  surface — the bricks prove the schema is genuinely usable, not
  that the Yang-Mills mass gap has been formalized.
- **SU(3) Gell-Mann basis bricks landed (2026-05-26, Task #56 Path B
  batch 1).** Added `Towers/YM/SU3Basis.lean` with the eight
  anti-Hermitian Gell-Mann generators `gellMann₁ … gellMann₈` as
  explicit `Matrix (Fin 3) (Fin 3) ℂ` literals via mathlib's `!![…]`
  notation, each proven to lie in `su3_submodule` (i.e.
  anti-Hermitian + traceless). The unnormalised choice
  `gellMann₈ := diag(I, 0, -I)` (no √3) keeps every membership proof
  inside `ext + fin_cases + simp + rfl` — no `norm_num`, no `ring`,
  no scary numeric coercion. Two local `macro`s factor the
  per-generator boilerplate. All 8 bricks pass the axiom-footprint
  check with `{propext, Classical.choice, Quot.sound}`. Total tower
  brick wall: **51** (was 43 before this batch: 26 YM from Task #55
  + 3 YM ℓ²(ℕ,ℂ) Hilbert-canonical-family bricks + 6 NS energy +
  8 BSD/RH/NS legacy, plus 8 new `gellMann_i_mem` = 51).
  These are the foundation for Path B batches 2 (`Basis.ofEquivFun`
  on `↥su3_submodule ≃ₗ[ℝ] (Fin 8 → ℝ)` plus linear-independence /
  span wrappers) and 3 (`InnerProductSpace.Core` instance on
  `↥su3_submodule`). The bricks claim ONLY: anti-Hermitian +
  traceless 3×3 complex matrices. No statement about YM dynamics,
  the YM Hamiltonian, the SU(3) Lie algebra structure constants
  `f^{abc}`, or the mass-gap conjecture. YM tower status unchanged:
  **Open** (`docs/ROADMAP.md` § 2).
- **Path B batch 2 deferred (Task #56 follow-up).** A full prototype
  of `gellMannSub`, `su3_coords`, `su3_reconstruct`,
  `su3_equiv_fin8_def`, `su3_basis_def`, `su3_basis_linearIndependent`,
  `su3_basis_spans` was drafted in `Towers/YM/SU3Basis.lean` but
  the `simp + linarith` finisher on the 9-case `funext p q;
  fin_cases p <;> fin_cases q` left-inverse proof over the 8-term
  `∑ cᵢ • gellMannᵢ` reconstruction exceeded mathlib v4.12.0's
  default 200000-heartbeat budget — `whnf` / `isDefEq` / `simp`
  all hit the wall. The draft was rolled back; the file now ships
  Batch 1 only (the 8 `gellMann_k_mem` membership bricks) plus a
  `Path B batch 2/3 — deferred` docstring documenting the retreat.
  No bricks were lost; total tower brick wall is **52** classical-
  trio clean (51 from the Task #56 Batch 1 checkpoint above plus
  `YMHamiltonian_abs_le_twelve` landed later; the `lake build Towers`
  axiom-footprint check passes for all of them). The Batch 2/3 work
  needs either
  (a) a per-entry `LinearMap.smulRight` unfolding lemma instead
  of `simp` over the whole sum, (b) `set_option maxHeartbeats` on
  the equiv def, or (c) splitting the 9 entry-cases into 9 separate
  intermediate lemmas. YM tower status unchanged: **Open**.
- **Trivial-bundle Gauge bricks retired (2026-05-26, Task #50, Option A).** The six `gauge_action_*` lemmas (`one_smul`, `mul_smul`, `inv_smul`, `smul_inv`, `inv_inv`, `pow_zero`) that lived on `TrivialConfiguration G` in `Towers/YM/Gauge.lean` were removed: the action was `· • A := A`, so every lemma reduced definitionally on both sides to `A`, exercising neither group multiplication nor the action — hollow even by trivial-brick standards. The YM wall is now **18 bricks**, not 24, and YM bricks live exclusively in `Towers.YM.MassGap` against `Matrix.specialUnitaryGroup`. Rule going forward: no `gauge_action_*` on `TrivialConfiguration` — only real SU(3). See `docs/ROADMAP.md` for the retirement note and `scripts/check-towers.sh` for the comment block.

## User preferences

- One PDF per module (M1–M7), uploaded one at a time
- SHA-256 hashes in monospace, truncated with copy-on-click
- Audit corrections documented in the per-module notes field
- Public-facing surface stays in the applied-science frame; scripture / personal-meaning notes are not in the repo
- Publisher line and license line are **locked** to the `scripts/print-direction.sh` wording — "Morning Star Project (independent research)" and "All rights reserved (license pending review)". Do not substitute "Entangled Technologies LLC" or "CC0" (or any other license) anywhere in the repo or UI.
- **Honest-scope wording is locked.** Do not describe any of the five roadmap towers (RH, Yang-Mills, Navier-Stokes, 280-curve cohort, Bost-Connes) as "proved" / "certified" / "discharged" in this repo *unless* the Lean spine actually closes that named theorem with axioms = []. Computational evidence, geometric invariants, and conjectural scaffolding are NOT proofs. Tower status lives in `docs/ROADMAP.md`; do not promote a tower out of `Status: Open` from `replit.md` or any UI surface.

## Gotchas

- After any OpenAPI change, run `pnpm --filter @workspace/api-spec run codegen` before touching frontend.
- `parentShas` is stored as text — JSON-parse on read.
- Restart the `theorema-certs` workflow after `status-badge.tsx` changes (Vite HMR caches the type).
- `_append_line` takes an exclusive `fcntl.flock` on the sidecar `data/.hits.lock` (created on first use, stable inode) **and** a second flock on its own append handle. The sidecar lock is the canonical cross-tool serialization primitive — exposed as `kernel.hits_exclusive_lock()` — and is used by `_append_line` AND by external backup/restore helpers (the `morningstar-tamper` snapshot fixture in `tests/test_morningstar.py` wraps its snapshot → mutate → restore window in this lock, task #59). A sidecar is used rather than `flock(data/hits.txt)` directly because tamper helpers `os.replace` the ledger for atomicity against concurrent readers; a lock taken on HITS itself would be orphaned by the inode swap, and a sibling `_append_line` would slip a line in during the mutate→restore window and have it silently overwritten. The sidecar lock is thread-reentrant within the same process (built on `threading.RLock`), so a fixture that holds the lock and then calls `kernel.probe()` — which itself calls `_append_line()` — does not self-deadlock; cross-thread and cross-process callers still serialize as normal.
- `replit.md` is operational only. History lives in `docs/CHANGELOG.md`. Don't grow this file with version notes.

## Pointers

- `pnpm-workspace` skill — workspace structure, TS setup
- `.local/skills/object-storage/SKILL.md` — presigned-URL upload architecture
- `docs/MorningStar_Architecture.pdf` — the full write-up (Part I Math Kernel, Part II Engineering Manifest, Appendices A–D)
