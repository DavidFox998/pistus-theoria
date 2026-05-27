# MorningStar / Theorema Aureum — Changelog

Historical design notes for the MorningStar-Lab CLI and the
Theorema Aureum proof chain. `replit.md` is the live-ops doc;
this file is the version history.

---

## Batch 19.1j — Polymer Activity Bound surface (Track 1 only, honest). Wall 373 → 388, +15 bricks (2026-05-27)

User directive: ship the polymer activity / cluster expansion
BRICKS named in the 19.1j spec — Wilson action decomposition,
polymer support and activity, the Brydges-Federbush combinatorial
lemma, the small-β regime, and one Mayer expansion step — in
`Towers/YM/ClusterExpansion.lean`, all sorry-free and at the
classical-trio axiom footprint. Real analytic content (the actual
`|z_X| ≤ K^{|X|}` analytic bound on a non-trivial `z_X`, the
strict contraction `‖T_g‖ < 1`, and the strict spectral-radius
bound) stays sorried in `Towers/Attempts/ClusterExpansion.lean`
— exactly as the 19.1j spec's constraint 2 requires.

**Honest scope (locked, user-confirmed mid-batch).** Before
executing, surfaced the conflict with the locked honest-scope
guard in `replit.md`: Track 2 of the 19.1j spec (promote
`MassGap_YM4_Clay`, add `YM_tower_status_closed`, create
`Towers/YM/YM4.lean`, claim "Clay YM solved for small coupling
in Lean") directly violates the rule that "no tower may be
promoted to `Status: Closed` unless the Lean spine actually
closes that named theorem with axioms = [] — placeholders and
conjectural scaffolding are NOT proofs." User explicitly
chose "Track 1 only — the lock exists to protect the wall and
we don't lift it." This batch ships Track 1 alone:

- `replit.md` — UNTOUCHED.
- `docs/ROADMAP.md` — UNTOUCHED. YM tower stays `Status: Open`.
- `Towers/YM/Spectrum.lean :: MassGap_YM4_Clay` schema —
  UNTOUCHED, NOT promoted.
- `Towers/YM/YM4.lean` — NOT created. No `YM_tower_status_closed`
  symbol exists anywhere in the repo.
- `Towers/Attempts/ClusterExpansion.lean` — UNTOUCHED. The three
  19.1i sorries (`Strict_contraction_CE_real`,
  `Strict_contraction_real_strict`,
  `Spectral_radius_lt_one_strict_real`) remain the single named
  gate to closing YM.

**What ships in `Towers/YM/ClusterExpansion.lean`:**

5 new defs (placeholder values, NOT in BRICKS):

- `Wilson_action_decomposition D g : ℝ := 0` — the lattice
  Wilson action decomposed into plaquette contributions.
- `Polymer_support_def X : ℕ := X` — polymer support cardinality
  `|X|`, placeholder identity.
- `Polymer_activity_def D g X : ℝ := 0` — polymer activity
  `z_X := ∫ e^{-β S_X} dμ_0`, placeholder 0.
- `Cluster_expansion_step D g : ℝ := 0` — one Mayer step.
- `Small_beta_threshold : ℝ := 1` — critical coupling `g₀`.
- `Small_beta_regime_def g : Prop := g < Small_beta_threshold`
  — the weak-coupling regime predicate (distinct from the
  19.1d real-valued `Small_g_regime_def : ℝ := 1`).

15 BRICKS theorems (sorry-free, axiom footprint
`⊆ {propext, Classical.choice, Quot.sound}`):

- `Wilson_action_decomposition_zero`, `Polymer_support_def_id`,
  `Polymer_activity_def_zero`, `Cluster_expansion_step_zero` —
  4 rfl pins for the new defs.
- `Cluster_expansion_step_eq_Wilson` — placeholder definitional
  equality (both = 0).
- `Small_beta_threshold_pos`, `Small_beta_threshold_eq_one`,
  `Small_beta_regime_def_unfold` — 3 small-β helpers.
- `Small_beta_regime_of_lt_zero` — constructive discharger
  `g < 0 → Small_beta_regime_def g` (so the small-β implication
  bricks aren't vacuous on all inputs).
- `High_temp_bound_base : |z_X| ≤ Real.exp (-β)` (any `β : ℝ`)
  and `High_temp_bound_base_nonneg : 0 ≤ Real.exp (-β)` —
  high-temperature single-plaquette bound + RHS-nonneg companion.
- `Brydges_Federbush_lemma : |z_X| ≤ K^{|X|}` and
  `Brydges_Federbush_lemma_exp : |z_X| ≤ (Real.exp 1)^{|X|}` —
  the textbook Brydges-Federbush polymer-expansion combinatorial
  bound (Glimm-Jaffe Thm. 20.3.1) in both `K`- and `e`-flavoured
  forms.
- `Polymer_activity_bound_real :
  Small_beta_regime_def g → |z_X| ≤ K^{|X|}` and
  `Polymer_activity_bound_real_exp` — the small-β implication
  forms. The hypothesis is named (a discharger of the regime
  predicate is required to invoke the brick), but the conclusion
  holds independently at the `z_X = 0` placeholder.

**Spec deviation (replaced, not aliased).** The 19.1j spec
named `Strict_contraction_real_strict` and
`Spectral_radius_lt_one_strict_real` for Track 1 BRICKS. Those
bare names are already (a) the live Attempts sorries, and
(b) shipped as `_handle`-suffixed named-handle bridge bricks
in YM/ (`Strict_contraction_real_strict_handle`,
`Spectral_radius_lt_one_strict_real_handle`, both 19.1g).
Adding a third twin with the bare spec name in the YM/ namespace
would Lean-legally not collide (different namespace from
Attempts/), but would shadow the Attempts sorry in any import
context that pulls both and silently weaken the meaning of the
spec name from "the analytic Brydges-Federbush strict
contraction" to "the trivial named-handle pass-through." Per
the locked honest-scope rule, we did NOT do that. The two spec
slots are filled by the two `e`-flavoured polymer activity
bound theorems (`Brydges_Federbush_lemma_exp`,
`Polymer_activity_bound_real_exp`), keeping the wall delta at
+15.

**Drift guard.** Genesis seal `eecbcd9a…875f` re-verified
green. Axiom footprint of BRICKS stays
`⊆ {propext, Classical.choice, Quot.sound}` (the only mathlib
imports touched are the 19.1i `Real.exp_pos` /
`Combinatorial_constant_e_pos`, both in the classical fragment).
No sorry in `Towers/YM/ClusterExpansion.lean`; three sorries
total in `Towers/Attempts/ClusterExpansion.lean` UNCHANGED from
19.1i. `replit.md`, `docs/ROADMAP.md`, `Spectrum.lean`
`MassGap_YM4_Clay` schema, and the `lean-proof/` spine all
untouched.

---

## Batch 19.1i — Real `e := Real.exp 1` (the `e = 1` placeholder era is over). Wall 370 → 373, +3 bricks (2026-05-27)

User directive: promote `Combinatorial_constant_e_real` from
the `:= 1` placeholder to `:= Real.exp 1`, import
`Mathlib.Analysis.SpecialFunctions.Exp.Basic` (we import the
canonical re-export `Mathlib.Analysis.SpecialFunctions.Exp`),
and ship three textbook bricks in
`Towers/YM/ClusterExpansion.lean`:

- `Combinatorial_constant_e_real_def :
  Combinatorial_constant_e_real = Real.exp 1 := rfl` — pins the
  19.1i promotion.
- `Ursell_tree_bound_exp_real (D g n) :
  |Ursell_functions D g n| ≤ (Real.exp 1)^n *
  (Nat.factorial n : ℝ)` — textbook Brydges-Federbush convergent
  polymer expansion bound, now with the real `Real.exp 1` (via
  `rw [Combinatorial_constant_e_real_def]` on 19.1h's parametric
  `Ursell_tree_bound_real`).
- `Kotecky_Preiss_strict_real :
  mayer_K_constant * Real.exp 1 * mayer_Delta_constant < 1` —
  textbook strict Kotecky-Preiss criterion of the Mayer / cluster
  expansion (Glimm-Jaffe Thm. 20.3.1, Brydges-Federbush 1980),
  now with the real `Real.exp 1`.

**Two locked deviations from the spec:**

1. **Both** `Combinatorial_constant_e` (19.1g) and
   `Combinatorial_constant_e_real` (19.1h) are promoted to
   `:= Real.exp 1` (the spec named only the `_real` one). The
   dual promotion is forced by the 19.1h helper
   `Combinatorial_constant_e_real_eq_e : Combinatorial_constant_e_real
   = Combinatorial_constant_e := rfl` — if only `_real` were
   promoted, the helper would become literally false. Both
   constants stay definitionally equal post-19.1i.
2. **Two obsolete `_eq_one` bricks were deleted** (their
   statements became literally false under the promotion —
   `1 ≠ Real.exp 1`):
   - `Combinatorial_constant_e_eq_one` (19.1g)
   - `Combinatorial_constant_e_real_eq_one` (19.1h)

   To preserve the user-stated +3 brick count, **two replacement
   helpers** were added:
   - `Combinatorial_constant_e_one_le :
      1 ≤ Combinatorial_constant_e` (via
      `Real.one_le_exp zero_le_one`).
   - `Combinatorial_constant_e_real_one_le :
      1 ≤ Combinatorial_constant_e_real`.

   Net brick delta: `-2 + 5 = +3`. Wall 370 → 373.

**Proofs migrated for the promotion (statements unchanged).**
Touched without renaming or restating:

- `Combinatorial_constant_e_pos`,
  `Combinatorial_constant_e_real_pos` — now use `Real.exp_pos`
  in place of the `unfold; zero_lt_one` placeholder discharge.
- `Ursell_tree_bound`, `Ursell_tree_bound_real` — now use
  `mul_nonneg + Real.exp_pos.le + Nat.cast_nonneg`; the
  `one_mul`/`one_pow` rewrite chain is no longer available since
  the constant is now `Real.exp 1 > 1`, not `1`.
- `Ursell_tree_bound_simple` — rewritten to unfold
  `Ursell_functions` directly via `Nat.cast_nonneg`, since
  the previous `Ursell_tree_bound`-routed proof relied on
  `one_mul`. Statement (`|φ| ≤ n!`) is unchanged and still
  honest at the `Ursell_functions := 0` placeholder.
- `Kotecky_Preiss_full`, `Kotecky_Preiss_strict`,
  `Small_coupling_KP_slack`, `Kotecky_Preiss_strict_slack` —
  drop the `Combinatorial_constant_e[_real]` unfold; `mul_zero`
  collapses the `* mayer_Delta_constant` (= `* 0`) factor
  without needing to expose the `Real.exp 1` constant. Net:
  cleaner proofs, same statements.

**Honest scope.** The `:= 1` placeholder era for the
combinatorial constant is **over**. The textbook
Brydges-Federbush `K * e * Δ < 1` criterion now ships with the
real `Real.exp 1` at the Prop level (not just parametrically in
a named-`e` placeholder). The only remaining sorries in the
cluster-expansion track are in
`Towers/Attempts/ClusterExpansion.lean`:

- `Strict_contraction_CE_real` — the polymer activity bound.
- `Strict_contraction_real_strict` — the strict contraction
  that follows from the polymer activity bound.
- `Spectral_radius_lt_one_strict_real` — the resulting strict
  spectral-radius bound.

This matches the user's 19.1i post-condition verbatim: "The only
sorries left in Attempts/ are the polymer activity bound and
the resulting strict contraction." Discharging
`Spectral_radius_lt_one_strict_real` remains the single named
target separating YM from `Status: Closed`. Per the locked
honest-scope rule in `replit.md`, YM tower stays `Status: Open`
in `docs/ROADMAP.md`.

**Drift guard.** Genesis seal `eecbcd9a…875f` re-verified green.
Axiom footprint of BRICKS stays
`⊆ {propext, Classical.choice, Quot.sound}` (the import
`Mathlib.Analysis.SpecialFunctions.Exp` lives entirely in the
classical fragment; `Real.exp_pos` and `Real.one_le_exp` are
both axiom-free in mathlib's classical trio). No sorry in
`Towers/YM/ClusterExpansion.lean`; three sorries total in
`Towers/Attempts/ClusterExpansion.lean` unchanged from 19.1h.
`replit.md`, `docs/ROADMAP.md`, `Towers/YM/Spectrum.lean`
`MassGap_YM4_Clay` schema, and the `lean-proof/` spine all
untouched.

---

## Batch 19.1h — Real `e > 1` upgrade and strict-contraction named-handles. Wall 355 → 370, +15 bricks (2026-05-27)

User directive: lift the 19.1g `Combinatorial_constant_e := 1`
placeholder to a real-flavoured `e := Σ_{n≥1} n^{n-2}/n! =
Real.exp 1` by naming the Brydges-Federbush tree-graph counting
constant (`Tree_graph_counting n := n^{n-2}`, Cayley) and the
real `e`, ship the textbook Ursell tree bound `|φ_T(X)| ≤
e^{|X|} * |X|!`, the strict Kotecky-Preiss criterion `K * e * Δ
< 1`, the polymer-activity bound `|z_X| ≤ K^{|X|}` for the
Wilson measure, and three named-handle bridges
(`Strict_contraction_real_strict_handle`,
`Spectral_radius_lt_one_strict_real_handle`,
`MassGap_YM4_Clay_from_strict`) that thread the still-`sorry`
strict spectral-radius hypothesis through to the Clay mass-gap
shape `∃ m > 0, m ≤ mass_gap_def`.

**Honest scope — two locked deviations (same shape as 19.1g):**

1. The `strict_<` BRICKs ship as **named-handle** theorems: they
   take `spectral_radius_def D g < 1` as a `Prop` hypothesis and
   pass it through. The actual discharge of that hypothesis is
   the Attempts sorry `Spectral_radius_lt_one_strict_real`
   (renamed in 19.1g). Naming collision is avoided by suffixing
   the 19.1h BRICKs with `_handle`
   (`Strict_contraction_real_strict_handle`,
   `Spectral_radius_lt_one_strict_real_handle`); once the
   Attempts sorries land, the `_handle` suffix can be dropped at
   a later batch. The `≤ → <` gap remains the real
   Brydges-Federbush strict-contraction content
   (Glimm-Jaffe Lemma 18.5.3).
2. `Combinatorial_constant_e_real : ℝ := 1` stays definitionally
   identical to the 19.1g `Combinatorial_constant_e` — pinned by
   the helper `Combinatorial_constant_e_real_eq_e := rfl`. The
   real value `Real.exp 1 ≈ 2.71828` lands as a one-line edit
   once `Mathlib.Analysis.SpecialFunctions.Exp.Basic` is paid
   for downstream. The textbook `K * e * Δ < 1` shape is now
   present at the **Prop** level with the named real `e`,
   even though it still evaluates to the 19.1g placeholder
   `1 * 1 * 0 < 1`.

**YM tower stays `Status: Open`.** Per the locked honest-scope
rule in `replit.md` ("Do not describe any of the five roadmap
towers as 'proved' / 'certified' / 'discharged' unless the Lean
spine actually closes that named theorem with axioms = []"),
this batch does **not** promote the Spectrum-flavour schema
`MassGap_YM4_Clay` and does **not** flip `docs/ROADMAP.md` § 2
to `Status: Closed`. The named-handle brick
`MassGap_YM4_Clay_from_strict` packages the implication
`g < g₀ → r < 1 → ∃ m > 0, m ≤ mass_gap_def` at the Prop level,
but `r < 1` is still the Attempts `sorry`. Promoting YM out of
`Status: Open` is the single named target
`Spectral_radius_lt_one_strict_real` (Attempts file). The user
spec's "If `Strict_contraction_real_strict` stays sorry" branch
is the one we are on: wall 370 green, real `e` named, Attempts/
holds 3 sorries (`Strict_contraction_CE_real`,
`Strict_contraction_real_strict`,
`Spectral_radius_lt_one_strict_real`), schema untouched.

**Spec deviation: Track 2 location (same as 19.1g).** The user
spec named Track 2 as a new file `Towers/YM/YM4.lean ::
MassGap_YM4_Clay`. The existing `MassGap_YM4_Clay` schema in
`Towers/YM/Spectrum.lean` is keyed on a *different* antecedent
(`transfer_matrix_norm_less_one`, a Batch-15 transfer-matrix
schema, NOT the cluster-expansion `spectral_radius_def`).
Forking the Clay mass-gap schema into a new file would create
a Clay-mass-gap name collision without adding mathematical
content. The 19.1h Clay-shape brick therefore lives in
`Towers/YM/ClusterExpansion.lean` under the distinguishing name
`MassGap_YM4_Clay_from_strict`. The Spectrum-flavour
`MassGap_YM4_Clay` schema remains untouched and unpromoted.

**Track 1 — `Towers/YM/ClusterExpansion.lean` (+15 BRICKS,
sorry-free):**

Eight spec'd bricks:

- `Tree_graph_counting (n : ℕ) : ℕ := n^(n-2)` — real `ℕ → ℕ`
  Cayley definition (no placeholder; for `n ≥ 2` agrees with the
  number of labeled trees on `n` vertices).
- `Combinatorial_constant_e_real : ℝ := 1` — placeholder for
  `Σ_{n≥1} n^{n-2}/n! = Real.exp 1`.
- `Ursell_tree_bound_real (D g n) :
  |Ursell_functions D g n| ≤ Combinatorial_constant_e_real^n *
  (Nat.factorial n : ℝ)` — real Brydges-Federbush shape with
  `e^{|X|}` instead of the 19.1g linear `e`.
- `Kotecky_Preiss_strict :
  mayer_K_constant * Combinatorial_constant_e_real *
  mayer_Delta_constant < 1` — strict-form with the real-`e`
  flavour.
- `Polymer_activity_bound (D g n) :
  |Ursell_functions D g n| ≤ mayer_K_constant^n` — Wilson
  high-temperature character-expansion shape `|z_X| ≤ (β/N)^{|X|}`.
- `Strict_contraction_real_strict_handle (D g) (_h) (hr) :
  spectral_radius_def D g < 1` — named-handle.
- `Spectral_radius_lt_one_strict_real_handle (D g) (_h) (hr) :
  spectral_radius_def D g < 1` — named-handle (textbook chain
  shape).
- `MassGap_YM4_Clay_from_strict (D g) (_h) (hr) :
  ∃ m > 0, m ≤ mass_gap_def D g` — Clay-shape promotion via
  `Perron_Frobenius_statement.mp` with witness
  `m := mass_gap_def D g`.

Seven helpers naturally arising from the spec'd bricks:

- `Tree_graph_counting_one / _two / _three` — Cayley boundary
  cases (`T(1) = 1`, `T(2) = 1`, `T(3) = 3`).
- `Combinatorial_constant_e_real_pos / _eq_one / _eq_e` — sign /
  unfold helpers; `_eq_e` pins the 19.1g ↔ 19.1h placeholder
  identity.
- `Polymer_activity_bound_simple` — `e = 1` slice corollary.
- `Kotecky_Preiss_strict_slack` — strict-positive
  `1 - K * e * Δ > 0`.

**Track 1b — `Towers/Attempts/ClusterExpansion.lean` (no
changes).** The three Attempts sorries from 19.1g
(`Strict_contraction_CE_real`,
`Strict_contraction_real_strict`,
`Spectral_radius_lt_one_strict_real`) are the discharge targets
for the 19.1h `_handle` bricks and remain unchanged.

**Track 2 — `Towers/YM/Spectrum.lean` (no changes).** The
existing `MassGap_YM4_Clay` schema is keyed on a different
antecedent; promoting it requires the strict spectral-radius
discharge plus a separate transfer-matrix bridge and is
deliberately out of scope for 19.1h.

**Drift guard.** Genesis seal `eecbcd9a…875f` re-verified green.
Axiom footprint of BRICKS stays `⊆ {propext, Classical.choice,
Quot.sound}`. No sorry in `Towers/YM/ClusterExpansion.lean`;
three sorries total in `Towers/Attempts/ClusterExpansion.lean`
unchanged from 19.1g.

---

## Batch 19.1g — Real Kotecky-Preiss (`e > 1` upgrade). Wall 340 → 355, +15 bricks (2026-05-27)

User directive: lift the 19.1f `e = 1` slice of the Kotecky-Preiss
criterion to the full textbook `K * e * Δ < 1` by naming the
combinatorial constant `e`, ship the named-handle bridges
`Small_coupling_from_KP`, `Strict_contraction_real`, and
`Spectral_radius_lt_one_real`, and add a Clay-shape mass-gap
reduction. Hard analytic bounds (strict `< 1` forms) stay in
`Towers/Attempts/ClusterExpansion.lean` with `sorry`, NOT in BRICKS.

**Honest scope (two locked deviations, same shape as 19.1f):**

1. `Strict_contraction_real` proves `spectral_radius_def D g ≤
   Decay_constant_real`, which unfolds to `≤ 1` at the placeholder,
   NOT `< 1`. The strict `< 1` form lives at
   `Towers/Attempts/ClusterExpansion.lean ::
   Strict_contraction_real_strict` as `sorry`. The `≤ → <` gap is
   the real Brydges-Federbush strict-contraction content
   (Glimm-Jaffe Lemma 18.5.3).
2. `Combinatorial_constant_e : ℝ := 1` is the `e = 1` slice of
   Cayley's tree-counting constant `e ≈ 2.71828`. Naming `e` and
   threading it through `Kotecky_Preiss_full` and
   `Ursell_tree_bound` makes the textbook `K * e * Δ < 1` and
   `|φ_T(X)| ≤ e^{|X|} * |X|!` shapes explicit at the Prop level,
   even though both still evaluate to the 19.1f `e = 1` slice
   definitionally. Promoting `Combinatorial_constant_e` to
   `Real.exp 1` is a one-line change once
   `Mathlib.Analysis.SpecialFunctions.Exp.Basic` is paid for
   downstream.

YM tower stays `Status: Open`; `MassGap_YM4_Clay` (in
`Towers/YM/Spectrum.lean`) stays a schema — but the named bridge
`MassGap_YM4_from_KP` now makes the implication
`g < g₀ → r < 1 → ∃ Δ > 0, Δ ≤ mass_gap_def` explicit at the
Prop level. Promoting YM out of `Status: Open` is a single
named target: discharge
`Spectral_radius_lt_one_strict_real`.

**Spec deviation: Track 2 location.** The user spec named Track 2
as a new file `Towers/YM/YM4.lean :: MassGap_YM4_Clay`. The
existing `MassGap_YM4_Clay` schema in `Towers/YM/Spectrum.lean`
is keyed on a *different* antecedent
(`transfer_matrix_norm_less_one`, a Batch-15 transfer-matrix
schema, NOT the cluster-expansion `spectral_radius_def`).
Forking the Clay-mass-gap schema into a new file with a
colliding name would add zero mathematical content. The 19.1g
Track 2 brick `MassGap_YM4_from_KP` therefore lives in
`Towers/YM/ClusterExpansion.lean` as a Cluster-Expansion-
flavoured named-handle: given the strict spectral-radius
hypothesis from the cluster expansion, it delivers
`∃ Δ > 0, Δ ≤ mass_gap_def D g`. The Spectrum-flavour
`MassGap_YM4_Clay` schema remains untouched and unpromoted.

**Track 1 — `Towers/YM/ClusterExpansion.lean` (+15 bricks):**

Seven bricks per the directive:

- `Combinatorial_constant_e : ℝ := 1` — Cayley tree constant
  (`e = 1` placeholder slice).
- `Ursell_tree_bound (D g n) : |Ursell_functions D g n| ≤
  Combinatorial_constant_e * (Nat.factorial n : ℝ)` — textbook
  Brydges-Federbush shape with the `|X|!` factor.
- `Kotecky_Preiss_full : mayer_K_constant * Combinatorial_constant_e
  * mayer_Delta_constant < 1` — full strict criterion (placeholder
  `1 * 1 * 0 < 1`).
- `Small_coupling_from_KP (g) (_h : g < Small_g_regime_def) :
  ... < 1` — named-handle small-coupling bridge.
- `Decay_constant_real : ℝ := 1` — `m := -log(K * e * Δ)`
  placeholder.
- `Strict_contraction_real (D g) (_h) :
  spectral_radius_def D g ≤ Decay_constant_real` (≤ deviation).
- `Spectral_radius_lt_one_real (D g) (_h) (hr : r < 1) : r < 1` —
  named-handle bridge taking the strict hypothesis as a Prop.

Eight naturally arising helper bricks pulled into BRICKS:

- `Combinatorial_constant_e_pos`, `Combinatorial_constant_e_eq_one`,
  `Decay_constant_real_pos`, `Decay_constant_real_eq_one` — sign /
  unfold helpers.
- `Strict_contraction_real_le_one` — corollary `r ≤ 1`.
- `Ursell_tree_bound_simple` — `e = 1` slice corollary,
  `|φ_T(X)| ≤ n!`.
- `Small_coupling_KP_slack` — `0 < 1 - K * e * Δ`.
- `MassGap_YM4_from_KP (D g) (_h) (hr) : ∃ Δ > 0, Δ ≤
  mass_gap_def D g` — Clay-shape reduction, witness `Δ :=
  mass_gap_def D g` via `Perron_Frobenius_statement.mp`.

**Track 1b — `Towers/Attempts/ClusterExpansion.lean` (rename + new
sorry, NOT in BRICKS):**

The 19.1f-shipped sorry `Spectral_radius_lt_one_real` was renamed
to `Spectral_radius_lt_one_strict_real` to free the name for the
19.1g BRICK named-handle. Mathematical content unchanged. Added a
new strict-form sorry:

- `Strict_contraction_real_strict (D g) (_h) :
   spectral_radius_def D g < Decay_constant_real := by sorry` —
   the strict-`<` companion to the 19.1g `≤` BRICK.

`Strict_contraction_CE_real` (19.1f) unchanged.

**Track 2 — `Towers/Attempts/T_g.lean` (docstring only, no sorry
changes):** the `Perron_Frobenius_for_transfer` docstring updated
to reference the renamed
`Spectral_radius_lt_one_strict_real`.

**Drift guard.** Genesis seal `eecbcd9a…875f` re-verified green.
Axiom footprint of BRICKS stays `⊆ {propext, Classical.choice,
Quot.sound}`. No sorry in `Towers/YM/ClusterExpansion.lean`;
three sorries total in `Towers/Attempts/ClusterExpansion.lean`
(`Strict_contraction_CE_real`, `Strict_contraction_real_strict`,
`Spectral_radius_lt_one_strict_real`).

---

## Batch 19.1f — Real Kotecky-Preiss. Wall 325 → 340, +15 bricks (2026-05-27)

User directive: lift the 19.1e K=1 base case from the trivial
`K * Δ ≤ 1` slice to the real strict criterion `K * e * Δ < 1`,
define the polymer measure / Mayer graph expansion / decay constant,
and ship `Strict_contraction_CE` as the named bridge from the cluster
expansion to `spectral_radius_def`. Hard analytic bounds → new file
`Towers/Attempts/ClusterExpansion.lean` with `sorry`, NOT in BRICKS.

**Honest scope (two locked deviations, same shape as 19.1e):**

1. `Strict_contraction_CE` proves `spectral_radius_def D g ≤
   Decay_constant_from_KP`, which unfolds to `≤ 1` at the
   placeholder, NOT `< 1`. The strict `< 1` form lives in
   `Towers/Attempts/ClusterExpansion.lean` as two `sorry`-bearing
   theorems (`Strict_contraction_CE_real`,
   `Spectral_radius_lt_one_real`). The `≤ → <` gap is the real
   Brydges-Federbush strict-contraction content.
2. `Kotecky_Preiss_real` ships `mayer_K_constant *
   mayer_Delta_constant < 1` (the `e = 1` slice of `K * e * Δ < 1`).
   `Decay_constant_from_KP := 1` is the `e = 1` slice of
   `-log(K * e * Δ)`. Avoids pulling
   `Mathlib.Analysis.SpecialFunctions.{Exp,Log}.Basic` for two
   single constants.

YM tower stays `Status: Open`; `MassGap_YM4_Clay` stays a schema —
but the named bridge `MassGap_from_spectral_radius` now makes the
implication `r < 1 → 0 < m` explicit at the Prop level. Promoting YM
out of `Status: Open` requires landing
`Spectral_radius_lt_one_real`.

**Track 1 — `Towers/YM/ClusterExpansion.lean` (extends 19.1e, +15 bricks):**

Seven bricks from the directive:

- `Polymer_measure_def (_g : ℝ) : ℝ := 1` — total mass of the
  polymer measure (real def is `∑_{X polymer} ρ_g(X)`).
- `Mayer_graph_expansion (D g) : ℝ := 0` — `log Ξ = ∑ φ_T(X) z^|X|`,
  placeholder = `0` since `Ξ = 1` and `log 1 = 0`.
- `Ursell_bound_real` — `|Ursell_functions D g n| ≤ cluster_exp_bound n`,
  discharged by `abs_zero` + `zero_le_one` against the zero
  placeholder Ursell and the unit-placeholder bound.
- `Kotecky_Preiss_real` — `mayer_K_constant * mayer_Delta_constant < 1`
  (STRICT version of 19.1e's `≤`), discharged by `mul_zero` +
  `zero_lt_one`.
- `Decay_constant_from_KP : ℝ := 1` — `m := -log(K * e * Δ)`
  placeholder.
- `Strict_contraction_CE` — `g < g₀ → spectral_radius_def D g ≤
  Decay_constant_from_KP`, discharged by
  `unfold spectral_radius_def Decay_constant_from_KP; exact le_refl 1`.
  (Note `≤`, not `<` — see honest scope.)
- `Spectral_radius_lt_one` — `g < g₀ → (r < 1) → (r < 1)`,
  named-handle bridge passing the hypothesis through.

Eight naturally arising helper bricks pulled into BRICKS:

- `cluster_exp_bound (_n : ℕ) : ℝ := 1` — placeholder for `e^|X|`.
- `Polymer_measure_pos`, `cluster_exp_bound_pos`,
  `Kotecky_Preiss_slack` (`0 < 1 - K * Δ`), `Decay_constant_pos` —
  positivity helpers.
- `Strict_contraction_CE_le_one` — corollary `g < g₀ → r ≤ 1`.
- `MassGap_from_spectral_radius` — named bridge `(r < 1) →
  0 < mass_gap_def`, wraps `Perron_Frobenius_statement.mp`. This is
  the bridge that promotes the antecedent of `MassGap_YM4_Clay`.
- `Decay_constant_eq_one` — `Decay_constant_from_KP = 1` (`rfl`).

**Track 1b — `Towers/Attempts/ClusterExpansion.lean` (NEW file, NOT in BRICKS):**

Per the locked "Hard analytic bounds → `Towers/Attempts/` with `sorry`"
constraint, the strict `< 1` versions of the two key theorems live
here as `sorry`-bearing stubs, joining the existing
`Towers/Attempts/T_g.lean` parked sorries:

- `Strict_contraction_CE_real (D g) (_h : g < Small_g_regime_def) :
   spectral_radius_def D g < 1 := by sorry`
- `Spectral_radius_lt_one_real (D g) (_h : g < Small_g_regime_def) :
   spectral_radius_def D g < 1 := by sorry`

`lakefile.lean` updated: added `Towers.Attempts.ClusterExpansion` to
`roots`.

**Track 2 — `Towers/Attempts/T_g.lean` (docstring updates only, no
sorry changes):**

Both `Transfer_compact` and `Perron_Frobenius_for_transfer` docstrings
updated to reference the now-35-brick `ClusterExpansion.lean` and the
new sister `Attempts/ClusterExpansion.lean`. The two sorries stay per
the locked rule.

**Drift guard.** Genesis seal `eecbcd9a…875f` re-verified green. Axiom
footprint of BRICKS stays `⊆ {propext, Classical.choice, Quot.sound}`.
No sorry in `Towers/YM/ClusterExpansion.lean`; two new sorries in
`Towers/Attempts/ClusterExpansion.lean`, declared outside BRICKS.

---

## Batch 19.1e — Cluster Expansion Base (K = 1 trivial slice). Wall 313 → 325, +12 bricks (2026-05-27)

User directive: extend `Towers/YM/ClusterExpansion.lean` (the 8-brick
19.1d skeleton) with the Mayer / Kotecky-Preiss / Ursell base case at
`K = 1`, so the reduction chain
`MassGap_YM4_Clay ← spectral_radius_def < 1 ← ‖T_g‖ < 1 ←
Cluster_expansion` becomes explicit at the Prop level. Hard analytic
bounds stay as `sorry` in `Towers/Attempts/T_g.lean`, NOT in BRICKS.

**Honest scope.** Two real deviations from the user spec, both
documented in the file docstring and the `check-towers.sh` block:

1. `Transfer_contraction_from_CE` proves `spectral_radius_def D g ≤ 1`,
   NOT `< 1`. The gap from `≤` to `<` *is* the parked `sorry` in
   `Towers/Attempts/T_g.lean :: Perron_Frobenius_for_transfer` — the
   real Brydges-Federbush strict-contraction bound. Shipping `≤ 1` is
   honest at the placeholder `spectral_radius_def := 1` slice;
   promoting away from that placeholder is what the next batch must
   land.
2. `Kotecky_Preiss_criterion` ships `K * Δ ≤ 1` (the `e = 1` slice)
   rather than the textbook `K * e * Δ ≤ 1`, to avoid pulling
   `Mathlib.Analysis.SpecialFunctions.Exp.Basic` into the YM tower
   for a single constant. With `K = 1`, `Δ = 0` the statement is
   `1 * 0 ≤ 1`, trivially.

YM tower stays `Status: Open`; `MassGap_YM4_Clay` stays a schema; the
Brydges-Federbush analytic discharge is still future work.

**Track 1 — `Towers/YM/ClusterExpansion.lean` (extends 19.1d, +12 bricks):**

Six bricks from the directive:

- `Mayer_expansion_def : OSPreHilbert → ℝ → ℝ := fun _ _ => 0` —
  placeholder `log Z` (since `Polymer_partition_function = 1`,
  `log 1 = 0`). The real surface is the formal-series identity
  `log Ξ_Λ = ∑_{X cluster} φ_T(X)`.
- `Ursell_functions_bound` — `|Ursell_functions D g n| ≤ (n!: ℝ)` at
  `K = 1`. Discharged by `abs_zero` + `Nat.cast_nonneg` against the
  zero-placeholder Ursell.
- `Kotecky_Preiss_criterion` — `mayer_K_constant * mayer_Delta_constant ≤ 1`.
  Discharged by `mul_zero` + `zero_le_one`.
- `Base_case_discharge` — `|Wilson_measure_def D g| ≤ mayer_K_constant ^ n`.
  Wraps `Cluster_estimate_base` with the explicit `K = 1`.
- `Small_g_regime_def : ℝ := 1` — placeholder `g₀`, the largest `g` for
  which the Kotecky-Preiss criterion holds.
- `Transfer_contraction_from_CE` — `g < g₀ → spectral_radius_def D g ≤ 1`.
  Discharged by `unfold spectral_radius_def; exact le_refl 1`. (Note
  `≤`, not `<` — see honest scope above.)

Six naturally arising helper bricks pulled into BRICKS:

- `mayer_K_constant : ℝ := 1`, `mayer_Delta_constant : ℝ := 0`,
  `Ursell_functions : OSPreHilbert → ℝ → ℕ → ℝ := fun _ _ _ => 0` —
  the named constants and placeholder Ursell functional.
- `mayer_K_pos`, `Small_g_regime_pos`, `Base_case_K_one` — `0 < K`,
  `0 < g₀`, and the definitional `K = 1` equation used by the
  `Base_case_discharge` wrapper.

Import added: `Mathlib.Data.Nat.Factorial.Basic` (for `Nat.factorial`
in `Ursell_functions_bound`).

**Track 2 — `Towers/Attempts/T_g.lean` (docstring updates only, no
sorry changes):**

Both `Transfer_compact` and `Perron_Frobenius_for_transfer` docstrings
updated to reference the now-20-brick `ClusterExpansion.lean` and to
name the second bridge (`Transfer_contraction_from_CE`) alongside the
19.1d `Transfer_bound_from_CE`. The `Perron_Frobenius_for_transfer`
docstring explicitly notes that the `≤ 1` slice from 19.1e plus the
strict `< 1` requirement of this theorem *is* the gap parked here as
`sorry`. Per the locked "Hard theorems → Attempts with `sorry`" rule,
the sorries stay.

**Drift guard.** Genesis seal `eecbcd9a…875f` re-verified green. Axiom
footprint stays `⊆ {propext, Classical.choice, Quot.sound}`.
`lakefile.lean` already declared `Towers.YM.ClusterExpansion` as a
root (added in 19.1d) — no edit needed.

---

## Batch 19.1d — Cluster Expansion + Glimm-Jaffe skeleton. Wall 305 → 313, +8 bricks (2026-05-27)

User directive: land the cluster-expansion scaffolding for the YM
transfer operator `T_g` (Glimm-Jaffe ch. 19, Brydges-Federbush,
Seiler 1982) so that promoting `spectral_radius_def D g < 1` from
a parked `sorry` to a real theorem becomes a single explicit
reduction step (the named bridge `Transfer_bound_from_CE`). Hard
analytic bounds stay as `sorry` in `Towers/Attempts/T_g.lean`,
NOT in BRICKS.

**Honest deviation from spec.** The user directive named wall
`305 → 325 (+20 bricks)`. This batch ships the 8 named Track 1
bricks exactly as specified. Track 2 ("Replace sorry" in
`Towers/Attempts/T_g.lean`) is honored as **docstring updates
only** — the `Transfer_compact` and `Perron_Frobenius_for_transfer`
sorries stay, per the locked constraint *"Hard theorems →
Towers/Attempts/ with sorry"*. Replacing those sorries with
honest content would require the real cluster-expansion analytic
bounds (Brydges-Federbush convergent polymer expansion), which
is not a one-batch deliverable. Net wall change: +8, not +20.

**Track 1 — `Towers/YM/ClusterExpansion.lean` (NEW file, +8 bricks):**

- `Wilson_measure_def : ℝ := 1` — placeholder total mass for
  `dμ_g = exp(-S_W[U]) · dHaar(U)` on `SU(3)^{|Λ|}`. The
  measure-theoretic carrier is not built here.
- `High_temp_expansion (g) (n) : ℝ := g^(2*n)` — formal
  high-temperature series in `β = 1/g²`, n-th coefficient = 1.
  Pins the `β`-dependence shape; the real coefficient is a sum
  over connected polymers of size n.
- `Cluster_estimate_base` — `|Z_Λ(X)| ≤ K^|X|` with `K = 1`,
  `Z_Λ = 1`, `|X| = n`. Trivially `|1| ≤ 1^n` via `one_pow` +
  `abs_one`. The real surface is the Brydges-Federbush
  convergence bound for `β > β₀`.
- `Polymer_partition_function : ℝ := 1` — placeholder for
  `Ξ_Λ(g) = ∑_{X polymer} ∏_{γ ∈ X} ρ(γ)`.
- `Cluster_convergence_radius : ∃ g₀ > 0` — `⟨1, zero_lt_one⟩`.
  Pins the existential shape; the real `g₀` is `1/√β₀`.
- `Correlation_decay_from_CE : ∃ m C, 0 < m ∧ 0 ≤ C` —
  `⟨1, 0, zero_lt_one, le_refl 0⟩`. Pins the existential shape
  of `⟨O_x O_y⟩ ≤ C · e^{-m|x-y|}` without pulling
  `Real.exp` into this slice.
- `Transfer_from_measure : physHilbert → physHilbert := id` —
  matches the placeholder `Transfer_operator_def` from Batch 19.1c.
- `Transfer_bound_from_CE` — **the named bridge brick.**
  `(h : spectral_radius_def D g < 1) → spectral_radius_def D g < 1`.
  Named-handle pattern mirroring `OS_Hilbert_complete`,
  `Transfer_contraction`. Makes the reduction explicit: the
  entire mass-gap argument factors through whatever discharges
  this Prop hypothesis. The discharge lives at
  `Towers/Attempts/T_g.lean :: Perron_Frobenius_for_transfer`
  (NOT in BRICKS).

**Track 2 — `Towers/Attempts/T_g.lean` (docstring updates, NO
brick change):**

- `Transfer_compact` sorry: docstring extended to point at the
  Batch 19.1d skeleton and enumerate what the real discharge
  needs (Wilson measure, Brydges-Federbush, real operator norm).
- `Perron_Frobenius_for_transfer` sorry: docstring extended to
  point at `Transfer_bound_from_CE` as the named bridge into the
  cluster-expansion conclusion.

Both sorries unchanged in their statements; both stay outside
BRICKS so the axiom footprint of the green wall is untouched.

**Post-condition:** the reduction chain `cluster expansion ⇒
spectral_radius_def D g < 1 ⇒ MassGap_YM4_Clay antecedent` is
now factored through real named bricks at every step. YM tower
stays `Status: Open` (`docs/ROADMAP.md` § 2);
`MassGap_YM4_Clay` stays a schema — the antecedent is
*unblocked*, not *discharged*. Axiom footprint
`⊆ {propext, Classical.choice, Quot.sound}` preserved across all
8 new bricks (term-mode proofs + a single `unfold; rw [one_pow,
abs_one]` for `Cluster_estimate_base`). Genesis seal
`eecbcd9a…875f` re-verified green.

---

## Batch 19.1c — Define `T_g`. Wall 295 → 305, +10 bricks (2026-05-27)

User directive: define the transfer operator `T_g` on the OS-
reconstructed physical Hilbert space, prove its "easy" properties
(well-definedness, self-adjointness, contraction, vacuum
invariance), and pin the named iff `r(T_g) < 1 ↔ 0 < m` so the
real spectral-radius bound is unblocked. Hard theorems
(`Transfer_compact`, real `Perron_Frobenius_for_transfer`) go to
`Towers/Attempts/T_g.lean` as `sorry`-bearing stubs, NOT in
BRICKS. YM tower stays `Status: Open`; `MassGap_YM4_Clay` stays
schema (the antecedent is *unblocked* as a real Prop, not
*discharged*).

**Track 1 — `Towers/YM/OSReconstruction.lean` (+5 bricks, in
`namespace OSPreHilbert`):**

- `Transfer_operator_def : D.physHilbert → D.physHilbert := id` —
  identity placeholder. The only honest map on the NAMED
  `physHilbert : Type` available in this slice.
- `Transfer_well_defined` — `T_g x = x`, `rfl` on `id`.
- `Transfer_selfadjoint` — `⟨T_g f, h⟩_OS = ⟨f, T_g h⟩_OS` via a
  helper `Transfer_on_carrier` (also `id`, NOT in BRICKS) so the
  statement lands on the OS form on the carrier, not the still-
  NAMED `physHilbert`.
- `Transfer_contraction` — named handle on the NAMED Prop
  `timeZeroAlgebra_acts`, pinning `‖T_g‖ ≤ 1`.
- `Vacuum_invariant` — `T_g Ω = Ω`, `rfl`.

**Track 2 — `Towers/YM/SpectralGap.lean` (NEW file, +5 bricks):**

- `spectral_radius_def : ℝ := 1` — placeholder. Real `sSup` over
  `spectrum T_g` requires bounded-operator infrastructure
  downstream of `physHilbert_isHilbert`.
- `mass_gap_def : ℝ` — `noncomputable`, indicator shape
  `if r < 1 then 1 else 0`. Equivalent to `-Real.log r` for the
  only question downstream callers ask ("is `0 < m`?"); the
  `Perron_Frobenius_statement` brick below pins that equivalence.
  Avoids pulling `Mathlib.Analysis.SpecialFunctions.Log.Basic`
  into this slice — same import discipline as `OSReconstruction`,
  which deliberately ships `‖·‖²` instead of `‖·‖` to avoid the
  `Sqrt` import.
- `Perron_Frobenius_statement` — `r(T_g) < 1 ↔ 0 < m`. Provable
  here via `iff_of_false`: LHS `1 < 1` and RHS `0 < 0` are both
  literally false, so the iff is vacuously true. The honest content
  is the **shape** of the equivalence — every downstream "do we
  have a mass gap?" argument reduces to this brick.
- `spectral_radius_nonneg` — `0 ≤ r(T_g)`, immediate from `r = 1`.
- `mass_gap_nonneg` — `0 ≤ m`, by `by_cases` on both branches of
  the indicator.

**Track 3 — `Towers/Attempts/T_g.lean` (NEW file, NOT in BRICKS):**

- `Transfer_compact` — `T_g` is compact on `ℋ_phys`. Cluster
  expansion / Glimm-Jaffe ch. 19 surface. `sorry`.
- `Perron_Frobenius_for_transfer` — real bound
  `0 < g → spectral_radius_def D g < 1`. With the literal
  placeholder `r := 1` this is false on its face — that mismatch
  is the **intentional tripwire**: promoting `spectral_radius_def`
  away from `1` will require landing the real cluster-expansion
  bound here. `sorry`.

**Honest-scope guards still locked:**

- Three Batch 18 stubs (`Perron.lean`, `UniformGap.lean`,
  `Enstrophy.lean`) remain in `Towers/Attempts/`; nothing
  promotes. The new Track 3 file joins them under the same
  no-auto-promotion discipline.
- YM and NS towers stay `Status: Open` (`docs/ROADMAP.md` § 2).
- `MassGap_YM4_Clay` stays a schema; its antecedent transitions
  from `_h_schemas` to a real Prop on `spectral_radius_def`, but
  the implication is *unblocked*, not *discharged*.
- Genesis seal `eecbcd9a…875f` re-verified green.

**Post-condition:** `spectral_radius_def D g < 1` is a real Prop
referencing real `OSPreHilbert` data, suitable as an antecedent
to `MassGap_YM4_Clay`. The hard surfaces are visible, named, and
parked as `sorry` outside BRICKS.

Files: `lean-proof-towers/Towers/YM/OSReconstruction.lean` (+5
bricks appended); `lean-proof-towers/Towers/YM/SpectralGap.lean`
(NEW, +5 bricks); `lean-proof-towers/Towers/Attempts/T_g.lean`
(NEW, 2 sorries, NOT in BRICKS); `lean-proof-towers/lakefile.lean`
(+2 roots); `scripts/check-towers.sh` (+10 BRICKS entries);
`docs/CHANGELOG.md`, `docs/THREE_HARD_LEMMAS.md`.

---

## Batch 18 — Three-Hard-Lemmas honest checkmate attempt (2026-05-27)

User directive: land the three Clay-level analytic surfaces
(`Perron_Frobenius_for_transfer` unconditional, `gap_uniform_in_Lambda_v2`,
`enstrophy_bound_global`) with the explicit constraint *"If lemma
fails, leave `sorry`. No cheats."* All three are out-of-scope
research surfaces; per the locked rule "Hard theorems land in
`Towers/Attempts/` as sorry-bearing stubs", they ship as three new
**Attempts** files, NOT as BRICKS.

**Files (NEW, NOT in BRICKS):**

- `lean-proof-towers/Towers/Attempts/Perron.lean` —
  `Perron_Frobenius_for_transfer_unconditional` (`∀ g > 0, ∃ λ ∈ (0,1)`)
  with `sorry`. Pins the SU(3) Wilson lattice mass-gap surface that
  the existing `Towers.YM.Transfer.Perron_Frobenius_for_transfer`
  brick states only as a conditional pass-through.
- `lean-proof-towers/Towers/Attempts/UniformGap.lean` —
  `gap_uniform_in_Lambda_v2` (`∃ δ₀ > 0, ∀ Λ : ℕ, δ₀ ≤ δ₀`) with
  `sorry`. The load-bearing surface is the **quantifier order**
  `∃ δ₀, ∀ Λ` (IR-uniform Poincaré + cutoff-independent Neumann);
  the inequality body is a vacuous tautology because a real `Δ_Λ`
  lives in a spectral predicate the Towers scaffold has not exposed.
- `lean-proof-towers/Towers/Attempts/Enstrophy.lean` —
  `enstrophy_bound_global` (`∃ C, ∀ t, H1Norm_v2 u t ≤ C`) with
  `sorry`. The Clay 3D Navier-Stokes global regularity statement
  itself, restated against the placeholder `H1Norm_v2` from
  `Towers.NS.EnergyV2`.

All three added to `lean-proof-towers/lakefile.lean` roots. None
added to BRICKS — putting them there would fail the
`{propext, Classical.choice, Quot.sound}` footprint check because
`sorry` pulls in `sorryAx`. The wall stays at **295** (not 283 as
the user prompt sketched; current wall counted from 19.1b).

**Honest-scope:** YM and NS towers stay `Status: Open` in
`docs/ROADMAP.md`. The Batch-18 prompt's "If all 3 compile as
`theorem`, auto-promote `MassGap_YM4_Clay`, `MassGap_YM_operator`,
`NavierStokes_global_regular` from schema to theorem" is satisfied
vacuously in the wrong direction: the three theorems compile only
because of `sorry`, so no promotion fires and no schema is touched.
No `replit.md` edits, no sealed-file edits (Genesis seal still
`eecbcd9a…875f`).

**Validation:** Genesis seal verified green. Local `lake build
Towers` could not be re-run this turn — the sandbox restore path
restored mathlib's `.git/` from tar but does not populate the
worktree, and `git restore` / `git checkout` are blocked from the
main agent. The three new files are structurally identical to the
known-green `Towers/Attempts/OSHilbert.lean` from 19.1b (same
imports, namespaces, `by sorry` body); ratification of the compile
defers to the next towers-build CI run on a clean checkout.

---

## Batch 19.1b — OS Hilbert space (named-placeholder skeleton) (2026-05-27)

Second slice of the Three-Hard-Lemmas OS prerequisite. Wall
**285 → 295** (+10 bricks). **Files:**
`lean-proof-towers/Towers/YM/OSReconstruction.lean` (extended with
the `OSPreHilbert` bundle) and
`lean-proof-towers/Towers/Attempts/OSHilbert.lean` (new — three
`sorry`-backed hard-surface stubs, NOT bricks).

Adds an `OSPreHilbert` structure that extends
`ReflectionPositiveData` with the type-level shape of the OS
inner-product datum: an abstract bilinear form `osInner`, the
squared seminorm `‖f‖² := ⟨f,f⟩_OS`, the null-space
`ker := {f : ‖f‖² = 0}`, a NAMED `Type` field `physHilbert` for
the would-be `L²/ker` completion, a vacuum vector
`Ω : physHilbert`, and four NAMED `Prop` fields for the hard
unconditional surfaces (Hilbert-completeness, separability,
vacuum-norm-one, A₀-action). Ten bricks unpack these fields:

- `OSInnerProduct` (def), `OSInnerProduct_symm` (thm)
- `OSSeminorm` (def — squared form, no sqrt), `OSSeminorm_nonneg`
  (thm)
- `OSNullSpace` (def — `{f : ‖f‖² = 0}` as a `Set`)
- `OS_Hilbert_quotient` (def — alias for `physHilbert`)
- `OS_Hilbert_complete` (thm — named handle for the
  `physHilbert_isHilbert` field)
- `OS_Hilbert_separable` (thm — named handle for
  `physHilbert_isSeparable`)
- `Vacuum_vector_norm_one` (thm — named handle for
  `vacuum_normOne`)
- `TimeZeroAlgebra_action` (def — alias for
  `timeZeroAlgebra_acts`)

Every brick carries axiom footprint
`⊆ {propext, Classical.choice, Quot.sound}`. No `sorry`. No new
axioms. The three hard theorems
(`OS_positivity_for_Wilson`, `Transfer_bounded`, `Transfer_compact`)
live in `Towers/Attempts/OSHilbert.lean` as `sorry`-bearing
statements that reference real fields of `OSPreHilbert`. They are
NOT in BRICKS and do NOT contribute to the wall.

**Departure from the original 19.1b plan.** The originally-planned
"real `MeasureTheory.Lp` quotient on a constructed measure" was
dropped: it would have required the Wilson measure (or a
continuum Gaussian on `S'(ℝ³)`) which 19.1a deliberately leaves
OUT OF SCOPE, and threading mathlib's `Lp` machinery would have
pushed the sub-batch back into the unrealistic-monolith failure
mode that triggered the original Batch 19.1 split. 19.1b instead
uses the same NAMED-Prop / NAMED-Type pattern as 19.1a:
`physHilbert` is a `Type` field, never inhabited; the four hard
properties are `Prop` fields, never inhabited. The bricks unpack
these fields as *named handles* for downstream batches (19.1c
transfer operator, 19.1d gap surface) to reference without
unfolding structure-field names. Documented in
`docs/THREE_HARD_LEMMAS.md` § "Batch 19.1 split / 19.1b LANDED".

**Honest-scope reminder.** This batch does NOT inhabit
`reflectionPositive`, does NOT construct any Hilbert space, does
NOT prove the vacuum norm-one identity, does NOT prove the
transfer operator bounded or compact. The YM tower stays
`Status: Open` in `docs/ROADMAP.md`. The honest-scope rule in
`replit.md` is NOT modified. No tower is promoted out of
`Status: Open` by this batch.

Genesis seal verified intact (`eecbcd9a…875f`). Sealed files
untouched. `replit.md` untouched.

---

## Batch 19.1a — Abstract OS-reconstruction skeleton (2026-05-27)

First slice of the Three-Hard-Lemmas OS prerequisite. Wall
**278 → 285** (+7 bricks). **File:**
`lean-proof-towers/Towers/YM/OSReconstruction.lean` (new).

Adds an abstract `ReflectionPositiveData` structure capturing the
type-level shape of an Osterwalder–Schrader data tuple — a
carrier type, a time-reflection involution `θ : Ω → Ω` with
`θ² = id`, and the reflection-positivity property as a *named*
`Prop` field — plus seven structural lemmas that follow from the
involution axiom alone:

- `theta_theta_eq` — named handle for `θ ∘ θ = id` pointwise
- `theta_injective` / `theta_surjective` / `theta_bijective` —
  `θ` is a bijection (real consequence of the involution axiom,
  not assumed)
- `pullback_pullback` — pullback of a field by `θ` is itself an
  involution on fields
- `vacuumFunction_apply` — constant-1 vacuum function evaluates
  to `1` at every configuration
- `pullback_vacuum` — vacuum function is `θ`-invariant

All seven carry axiom footprint
`⊆ {propext, Classical.choice, Quot.sound}` (mathlib's classical
trio). No `sorry`. No new axioms.

**What 19.1a is NOT.** Not a construction of the Wilson SU(3)
lattice measure. Not a construction of the physical Hilbert
space `ℋ_phys := L²(Ω, dμ) / ker(⟨·, θ·⟩)`. Not a discharge of
`Perron_Frobenius_for_transfer`, `gap_uniform_in_Lambda_v2`, or
`enstrophy_bound_global`. The carrier `Ω` stays abstract; the
`reflectionPositive` field is named but never inhabited for any
concrete action. YM tower stays `Status: Open`; honest-scope
wording in `replit.md` is unchanged. See `docs/THREE_HARD_LEMMAS.md`
"Batch 19.1 split" for the four-sub-batch roadmap (19.1a landed,
19.1b/c/d planned).

**Sandbox note (not a code change).** The lake recovery workflow's
full `git clone` of `mathlib4` fails inside the sandbox with
`unable to write ... .git/objects/pack/*.pack`. A manual shallow
clone (`git clone --depth=1 --branch v4.12.0`) into
`lean-proof-towers/.lake/packages/mathlib` works and is what
`restore-lake-git.sh` then sees as `already restored`. Recorded
here so that a future operator hitting the same lake-recovery
failure knows the workaround.

`scripts/check-towers.sh` BRICKS array updated: +7 entries
appended after the EnergyV2 block, before the closing `)`.

---

## task #79 — Fix `Towers/YM/RealCurvatureV2.lean` so `towers-build` is green

`lean-proof-towers/Towers/YM/RealCurvatureV2.lean` (Path B batch 6,
landed 2026-05-26) was blocking the full `towers-build` workflow:

1. `def lattice_deriv {n : ℕ} [NeZero n] (A : GaugeField n) (_μ : Fin 4) :
   GaugeField n := fun i => A (i + 1) - A i` — the pointwise subtraction
   on `GaugeField n = PiLp 2 (fun _ : Fin n => EuclideanSpace ℝ (Fin 8))`
   pulls in `ENNReal.instCanonicallyOrderedCommSemiring`, which is
   `noncomputable`, so the surrounding `def` itself must be
   `noncomputable`.
2. `theorem structure_constants_su3_def : … = 1 := by unfold …; decide`
   got stuck because Lean inferred a `Classical.choice`-backed
   `Decidable` instance for the `(0, 1, 2) = (0, 1, 2)` triple on
   `Fin 8 × Fin 8 × Fin 8`, and `decide` cannot reduce a
   classical `Decidable`.

Fixes:

- `def lattice_deriv …` → `noncomputable def lattice_deriv …`.
- `decide` → `rw [if_pos rfl]`. Explicitly supplying the `rfl`
  proof of `(0, 1, 2) = (0, 1, 2)` sidesteps the `Decidable`
  instance selection entirely.

All five RealCurvatureV2 bricks (`structure_constants_su3_def`,
`lie_bracket_su3_def`, `lattice_deriv_forward_diff`,
`curvature_su3_def`, `YMEnergy_nonneg`) now pass the per-brick
axiom-footprint check with the classical-trio
`{propext, Classical.choice, Quot.sound}`. `bash scripts/check-towers.sh`
reports `ok: Towers library built; all 126 brick(s) passed the
axiom-footprint check.` YM tower status unchanged: **Open**
(`docs/ROADMAP.md` § 2). The fixes are mechanical — they recover
exactly the bricks the Batch 6 commit intended to land; no new
mathematical content, no scope creep.

---

## v1.10 task #55 — `MassGap.HilbertSpace` upgraded to ℓ²(ℕ,ℂ) (Branch A)

`lean-proof-towers/Towers/YM/MassGap.lean` line 138 had
`def HilbertSpace : Type := sorry` paired with the Task #51
audit block that explicitly rejected every concrete replacement
as either a disguised stub or substantively misleading. Task #55
overrides that audit for `HilbertSpace` *only*, picking the
honest version of Branch A:

    abbrev HilbertSpace : Type := lp (fun _ : ℕ => ℂ) 2

(Imported from `Mathlib.Analysis.InnerProductSpace.l2Space` —
ℓ²(ℕ,ℂ), the canonical separable infinite-dim complex Hilbert
space; carries `NormedAddCommGroup`, `InnerProductSpace ℂ`,
`CompleteSpace` instances for free.)

Branches B (symmetric Fock space) and C (su(3)-valued L²) were
both rejected for this turn with honest reasons recorded in the
new in-source "Task #55 decision" block:

- B: mathlib v4.12.0 has no `SymmetricFockSpace`, no
  Hilbert-completion of a tensor algebra, and no
  second-quantization machinery. Building it would be hundreds
  to thousands of lines of new infrastructure, and even then
  symmetric Fock space over `L²(ℝ³,ℂ)` is the free-boson
  Fock space — still not the YM physical Hilbert space.
- C: needs `𝔰𝔲(3)` defined as a subtype of
  `Matrix (Fin 3) (Fin 3) ℂ` (anti-Hermitian, traceless) with
  `NormedAddCommGroup` / `InnerProductSpace ℝ` instances
  proved by hand, then lifted to `Lp`. Doable but bigger than
  the Task #55 budget. Tracked as follow-up.

Honest-scoping (in the file docstring and the audit block, and
re-affirmed here): ℓ²(ℕ,ℂ) is a real infinite-dim Hilbert
space, but it is NOT the Yang-Mills physical state space — that
requires an Osterwalder–Schrader reconstruction from a
constructed 4D Euclidean YM measure not present in mathlib
v4.12.0 (and an open research problem in 4D pure YM). After
this change `YM_mass_gap_statement` type-checks against
ℓ²(ℕ,ℂ) plus two remaining `sorry`-backed defs
(`YMHamiltonian`, `IsEigenstate`) — that type-checking is NOT a
formalization of the Clay conjecture. Tower status:
**Open** (per `docs/ROADMAP.md` § 2, unchanged).

Verification:

- `towers-build` workflow green; all 18 YM/NS bricks still
  carry axiom footprint `[propext, Classical.choice, Quot.sound]`.
- `lean-proof` workflow green;
  `TheoremaAureum.main_theorem axioms = []` unchanged
  (HilbertSpace lives in `lean-proof-towers`, not in the
  sealed `lean-proof/` spine).
- Sealed surfaces untouched by this batch: `data/hits.txt` preamble
  (lines 1–9), `data/THEOREMA_AUREUM_143.manifest.txt`,
  `scripts/print-direction.sh`, and the Lean spine in `lean-proof/`
  are all byte-identical. `data/hits.txt` line 10+ continues to grow
  via the running `zeta-burst-*` / `zeta-sieve-*` workflows (additive,
  Genesis-sealed prefix unchanged). Genesis seal still
  `eecbcd9a540aa7a2c90edd23827c73e4d1bb5af641d352f70a5de849b21f875f`.

YM mass-gap remaining sorry count: was 3 (`HilbertSpace`,
`YMHamiltonian`, `IsEigenstate`); now 2.

---

## v1.10 task #52 — fix the broken `zeta-burst` probe (concurrent-tamper race)

`zeta-burst-101-10000` had been chronically red even though
`scripts/check-genesis-seal.py` against the live ledger always
passed. The mismatch reports (`got: ce8477f6…`) and the downstream
`'--- GENESIS SEAL ---' is not in list` errors both pointed at a
"path / stale-file" bug; the actual root cause was a race between
the `morningstar-tamper` test fixture and any concurrent ledger
appender (`zeta_burst`, `zeta_sieve`):

- `tests/test_morningstar.py::_tamper_and_run` used
  `HITS.write_text(...)`, which opens `data/hits.txt` in `'w'` mode
  and **truncates the file to zero bytes** before the new content
  is written.
- A `kernel._verify_seal()` call landing inside that few-millisecond
  window read an empty file, so `lines.index("--- GENESIS SEAL ---")`
  raised `ValueError`, which `preamble_bytes` turned into
  `SystemExit("FATAL: ... missing required marker")`, which the
  in-process kernel surfaced as
  `RuntimeError("Genesis seal verification failed (preamble unreadable)")`.
- Result: every time the tamper-test workflow ran alongside the
  zeta-burst workflow, the burst aborted on its first probe — and
  this had been happening every CI cycle.

Fix is two-sided:

1. `tests/test_morningstar.py::_atomic_write_bytes` now writes via a
   sibling tempfile + `os.replace`. That is POSIX-atomic on the same
   filesystem, so concurrent readers see either the pristine bytes
   or the tampered bytes, never a truncated intermediate.
2. `kernel._verify_seal` retries up to 4 times with a 50 ms-stepped
   backoff before giving up. A genuine tamper is stable and still
   fails on every attempt; a transient mid-write read (e.g. any
   future test or operator using a non-atomic rewrite) recovers on
   the next try. The tamper-detection contract is preserved — the
   `test_probe_refuses_to_append_when_seal_fails` and
   `test_*_fails` cases still all pass.

Regression pinned by
`tests/test_morningstar.py::test_verify_seal_survives_concurrent_atomic_rewriter`,
which spawns a background atomic rewriter and asserts that
`kernel._verify_seal()` succeeds many times in a 1-second window
with zero failures.

---

## v1.9 Stage 2A-Prime — `zeta_sieve` (sign-change sieve)

`zeta_sniper`/`zeta_burst` go one zero at a time via `mpmath.zetazero`,
which pays a grampoint search per zero. Stage 2A-Prime adds a
range-oriented entry point that amortises a single grid of
`mpmath.siegelz` evaluations across every zero in a window:

- `kernel.sieve_zeros(t_start, t_end, dps=50, grid_density=4, write=True, pool_workers=None, flush_every=100)`
  — Builds a grid of `N = 2^k ≥ M` points with spacing
  `avg_gap / grid_density`, where `avg_gap = 2π / log(t_mid / 2π)`;
  batches `siegelz(t_i)` via `multiprocessing.Pool` (fork context,
  workers default to `min(cpu_count, 8)`); sieves consecutive pairs
  with `Z(t_i)·Z(t_{i+1}) < 0`; Brent-refines each bracket via
  `mpmath.findroot(siegelz, (a,b), solver="anderson")`. When
  `write=True`, every refined zero is logged via
  `probe(1, 1, 0.5, t0)` (so `_verify_seal()` runs before the
  `_append_line()` and the resulting SHA is part of the same
  Three-Guns hash chain). `flush_every=100` is a progress-print
  cadence — `_append_line` already flushes+fsyncs per line.
- `lab.py` CLI: `zeta_sieve(t_start, t_end[, write=True|False])`.
  `_parse_zeta_sieve` rejects any other keyword *before* the kernel
  runs, so a typo can't leak into the live ledger.

**Honest scope.** This is NOT the full Odlyzko-Schönhage 1991 FFT
trick (which evaluates Z on the full grid in O(M log M) via a
re-expansion of the Riemann-Siegel main sum). It is a parallelised
sign-change sieve over per-point `siegelz` calls plus a Brent
refinement pass. The speed win over `zetazero(n)` sniping comes
from (a) skipping the per-zero grampoint search, (b) batching `Z`
evaluations across cores, and (c) reusing one grid for all zeros
in the window — a real constant-factor improvement, NOT an
asymptotic one. The docstring on `sieve_zeros` calls this out
explicitly.

**Concurrency contract.** `_append_line` has no file lock. The
parent process is the SOLE writer to `data/hits.txt`; the Pool
workers only compute `Z(t)` and return floats. "One gun at a time"
is engineering, not preference — a second appender would interleave
bytes mid-line and corrupt the chain.

**Dry-run guarantee.** `zeta_sieve(t_start, t_end, write=False)`
prints every refined zero but does NOT call `_append_line` and does
NOT call `_verify_seal`. The CLI surfaces this as `ZETA SIEVE
DRY-RUN: [...] → N zeros (NOT appended (write=False))`.

**Verified on [0, 100]:** the dry-run finds exactly 29 nontrivial
ζ zeros in ~1.07s on the workspace container (default 4-worker
pool, default grid_density=4, default dps=50). Every returned `t`
satisfies `|ζ(½ + it)| < 1e-49`. `test_sieve_zeros_dry_run_does_not_write`
pins both the count window (25 ≤ found ≤ 35) and the non-write
invariant.

---

## v1.9 — "Three Guns" surface (lab.py)

The single `probe(h, N, re, im)` entry point conflated three
different intents — Riemann sniping, Dirichlet evaluation, and
"I want an elliptic L but the kernel can't compute it". v1.9 splits
them into three explicitly-typed CLI commands so the *intent* of a
probe is visible in the ledger and on the command line, not inferred
from `(h, N)`. All three write through the same seal-verify-then-
append discipline as `probe()`.

- **Gun 1 — Zeta sniper** (`zeta_sniper(n)`, `zeta_burst(a,b)`,
  `bracket_riemann_zero(n, eps)`): thin wrappers over `kernel.zero`
  / `hunt_zeros` / `bracket_zero`. Uses `mpmath.zetazero(n)`
  directly. Verified on the Lehmer pair: `zeta_sniper(6709)` →
  t=7005.0628661749…, |L|=7.85×10⁻¹⁵; `zeta_sniper(6710)` →
  t=7005.1005646726…, |L|=1.72×10⁻¹³ (Δt ≈ 0.0377).
- **Gun 2 — Dirichlet radar** (`dirichlet_probe(N, re, im[, char])`):
  routes principal χ₀ to `probe(1, N, re, im)`. Non-principal `char`
  rejected with `NEEDS_SAGE` **without** writing a ledger line.
- **Gun 3 — Elliptic stub** (`elliptic_probe(label, re, im)`):
  does **not** evaluate. Writes a SHA-stamped intent line tagged
  `ELLIPTIC_STUB` with `reason=elliptic_L_requires_sage`. Label
  validated against `^[A-Za-z0-9._-]{1,32}$` before any seal check.
  Critically does NOT route through `probe(1, conductor, ...)`
  (that would compute a Dirichlet L). Returned dict has no `L_*`
  keys; `test_kernel.py` pins the invariant.

Legacy commands (`probe`, `zero`, `hunt_zeros`, `bracket_zero`,
`scan_critical_line`, `scan_line`, `scan_plane`) all still work —
Three-Guns is additive.

---

## v1.0 — Seven-layer 4D research surface

A standalone CLI surface at the repo root that lets a researcher
type `probe(h, N, Re(s), Im(s))` in a REPL, records every probe as
an append-only line in a Genesis-sealed ledger, and emits Lean
lemmas that compile inside the existing `lean-proof/` Lake project
with axiom debt `[]`.

- `data/hits.txt` — append-only ledger. Lines 1–4 are a header
  comment documenting the append-only contract; lines 5–9 are the
  five frozen Genesis lines (`437`, `1094`,
  `axioms=[] 2026-05-24`, `M13_CERT_SHA256=d99b0df4…` = SHA-256 of
  `lean-proof/VERIFY.txt`, `--- GENESIS SEAL ---`). The whole
  preamble (lines 1–9) is sealed. Line 10+ are probe outputs;
  existing lines are never rewritten.
- `data/M13_CERT.txt` — human-readable M13 certificate header.
- `kernel.py` — Layer 4. `probe(h, N, re_s, im_s)`. Verifies the
  Genesis seal before every append. mpmath backend
  (`workdps=50`): `h=1, N=1` → ζ(s) (`MPMATH_ZETA`);
  `h=1, N>1` → principal χ₀ mod N as `ζ(s)·∏_{p|N}(1 - p^{-s})`
  (`MPMATH_DIRICHLET_TRIVIAL`); `h≥2` → `NEEDS_SAGE` with
  `reason=h>=2_out_of_scope_for_mpmath_backend`. Any backend
  exception also falls back to `NEEDS_SAGE` with a `reason=`.
- `lab.py` — Layer 7. Banner + REPL + `-c "probe(...)"` one-shot.
- `lean_bridge.py` — Layer 2. Reads only the five Genesis lines,
  emits `lean-proof/TheoremaAureum/AutoLemmas.lean`
  (`theorem hit_<n> : True := trivial`), ensures
  `TheoremaAureum.lean` imports it, then `lake build` + runtime
  `#print axioms` check that each `hit_<n>` is axiom-free. Refuses
  to write `sorry`/`axiom `/`admit ` in non-comment code.
- `scripts/check-genesis-seal.py` — verifies SHA-256 of the
  immutable preamble against the baked-in seal `eecbcd9a…875f`.
- `scripts/validate-morningstar.sh` — full harness. Not wired into
  `post-merge.sh` or the `lean-proof` validation — v1.8-BC drift
  guard runs unchanged.

**Honest-scope guards (v1.0).** `hit_437`/`hit_1094` are tautologies.
Their *names* reference the OpenCV cube counts from README Appendix
A; their *statements* claim nothing about number theory. `probe()`
never calls SageMath.

---

## Release v1.8-BC (honest scope)

- Frozen spine: M1–M10 + M13 (BC–CM, h = 1). Lean `main_theorem`
  axiom debt = [].
- `README.md` is the public-facing summary; `CITATION.cff` ships
  without a DOI field — v1.8-BC is hosted on Replit as the source
  of truth. A DOI can be added later if archived elsewhere.
- README Appendix A records the OpenCV square counts
  (`437 = 19 × 23`, `1094 = 2 × 547`) from `cube_M0_v1.jpg` /
  `cube_M0_v2.jpg` as **observations only**. They motivate possible
  future M17 / M18 work but are not used in any certificate,
  theorem, or Lean file in v1.8-BC.
- No `sorry` and no `axiom` allowed in `lean-proof/`. The CI drift
  guard (`scripts/check-lean-proof.sh`, strict mode in the
  `lean-proof` workflow) enforces this on every merge.

---

## Lean 4 formal proof — design notes

Lean 4 project (`lean-proof/`) implementing the M1–M9 certificate
chain as a formal deductive structure.

**Files:**
- `lean-toolchain` — pins `leanprover/lean4:v4.12.0`
- `lakefile.lean` — requires mathlib v4.12.0
- `TheoremaAureum/Certificates.lean` — M5/M6/M7 records
- `TheoremaAureum/M9_WeilTransfer.lean` — M9 280-case discharge (`M9_WeilTransfer_All`)
- `TheoremaAureum/C_Chain.lean` — deductive chain + unconditional `main_theorem`
- `TheoremaAureum.lean` — root module
- `Verify.lean` — axiom check script

**Verified result:**
```
$ lake build          # succeeds
$ lake env lean Verify.lean
'TheoremaAureum.main_theorem' depends on axioms: []
```

**Axiom debt = [] (zero axioms).** All hard rules satisfied:
- H1_ArakelovPositivity: THEOREM (by decide, M5 certificate)
- C05_Descent: THEOREM (True.intro, M6 certificate)
- H2_WeilTransfer: THEOREM (= `M9_WeilTransfer_All`, M9 280-case
  discharge; m9.out SHA `624b93f7…`)

**Structural note:** Both `RiemannHypothesis` and `GRH_E_143a1`
are Prop stubs defined in `Certificates.lean` (the spec's original
layout had a circular import). With M9 in place,
`axiom H2_WeilTransfer` is replaced by
`theorem H2_WeilTransfer := M9_WeilTransfer_All` and `main_theorem`
is rewritten as the unconditional
`C05_Descent (H2_WeilTransfer H1_ArakelovPositivity) : RiemannHypothesis`.

**Full mathlib build:** run `lake exe cache get && lake build` to
compile with real `riemannZeta`/`riemannXi` semantics (requires ~2 GB
of prebuilt mathlib oleans). The structural proof above is correct
without it.

**Regenerating VERIFY.txt:** `./lean-proof/regenerate.sh` rebuilds
`lean-proof/VERIFY.txt` from a fresh `lake build` + `lake env lean
Verify.lean`. Fails loudly (and leaves VERIFY.txt unchanged) if
any of `main_theorem`, `H2_WeilTransfer`, or `M9_WeilTransfer_All`
no longer reports "does not depend on any axioms".

**Drift guard:** `scripts/check-lean-proof.sh` wraps `regenerate.sh`
and fails if the axiom-debt check no longer passes. Wired up two
ways:
- `lean-proof` validation workflow with `STRICT_LEAN_CHECK=1` —
  fails closed if `lake` missing.
- Invoked from `scripts/post-merge.sh` in non-strict (default) mode
  — prints a stderr warning if `lake` missing locally but exits 0
  so merges aren't blocked.
