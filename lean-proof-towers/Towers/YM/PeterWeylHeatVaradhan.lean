/-
================================================================
Towers / YM / PeterWeylHeatVaradhan  (Task #156 — Varadhan small-t
asymptotic for the SU(3) heat-kernel envelope, **strip form**)

**Headline.** A sorry-free Varadhan-shape upper bound on the
genuine SU(3) Peter-Weyl heat-kernel envelope
  `Heat_kernel_envelope_real t :=
       ∑'_{(m,n) : ℕ²} (dim λ)² · exp(-(t · C₂(λ)))`
(landed in `Towers/YM/PeterWeylHeat.lean` via
`PeterWeyl_Summable_SU3`, Batch 19.1p-redux-a/b, Tasks #154/#155).
For every `t : ℝ` in the **finite strip** `[varadhan_t_lo, varadhan_t_top]`
(concretely `[1, 2]`), with explicit positive constants
`varadhan_c, varadhan_C`, the brick

  `Heat_kernel_envelope_real_le_varadhan :`
      `varadhan_t_lo ≤ t → t ≤ varadhan_t_top →`
      `Heat_kernel_envelope_real t ≤`
        `varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4`

closes by composing (1) antitonicity of the envelope in `t` on
`(0,∞)` (each summand `exp(-(t·C₂))` decreases in `t` since `C₂ ≥ 0`,
both partial sums are `Summable` via `PeterWeyl_Summable_SU3` so
`tsum_le_tsum` applies), and (2) the algebraic fact that on the
strip `[t_lo, t_top]`, both `t_top^4 / t^4 ≥ 1` and the exp factor
`exp(c/t_lo) · exp(-c/t) ≥ exp(0) = 1` (since `t ≥ t_lo > 0` and
`c > 0` force `c/t ≤ c/t_lo`). Hence `varadhan_C · exp(-c/t)/t^4
≥ env(t_lo) ≥ env(t)` on the strip.

### Drift from the original task signature (honest scope, locked)

The Task #156 "Done looks like" line asked for the unrestricted
small-`t` shape
  `∀ t, 0 < t → t ≤ t₀ → env(t) ≤ C · exp(-c/t) / t^4`
for explicit positive `C, c, t₀`. **That statement is mathematically
false** for any positive `C, c, t₀` and the genuine envelope: as
`t → 0⁺`,
  - LHS `env(t) → +∞` (the SU(3) heat-trace blows up like `t^{-4}`,
    the Weyl-law `t^{-d/2}` with `d = dim_ℝ SU(3) = 8`),
  - RHS `C · exp(-c/t) / t^4 → 0` (the `exp(-c/t)` factor crushes
    `t^{-4}` to zero exponentially fast).
So no Varadhan-shape upper bound with `c > 0` can hold on any open
neighbourhood of `0`. The `exp(-c/t)` factor is the **off-diagonal**
Varadhan/Molchanov small-`t` asymptotic
  `K_t(x, y) ~ (4πt)^{-d/2} · exp(-d_g(x,y)² / 4t)`,
which collapses to the pure `t^{-d/2}` blow-up on the diagonal
`x = y` (where `d_g(x,x) = 0`). The repo's `Heat_kernel_def_real t
:= exp(-c/t) / t^4` placeholder is the off-diagonal shape; the
envelope is the on-diagonal trace, and the two cannot be related by
the literal Varadhan inequality without either (a) `c ≤ 0` or
(b) a lower bound on `t` away from `0`.

This file ships option (b): a **strip-form** Varadhan-shape bound
with `0 < t_lo ≤ t ≤ t_top`. The original task's "or honest
documentation of why the linear bound suffices for the chosen C, c"
escape hatch covers this drift: the strip carries no claim about
the small-`t` asymptotic regime, only the comparison shape inside
a bounded `t`-window — which is what a real off-diagonal Varadhan
bound + finite-volume cutoff would consume downstream once the
bi-invariant SU(3) Riemannian metric (Killing form) lands (not in
mathlib v4.12.0). The constants are nonetheless traceable to the
SU(3) Casimir via the `PeterWeyl_Summable_SU3` proof chain, since
`varadhan_C` is built directly from `Heat_kernel_envelope_real
varadhan_t_lo`, which in turn is dominated by the
Casimir/Weyl-dim product envelope of Bricks 1+2+3 in
`Towers/YM/PeterWeyl.lean`.

### Honest scope (locked)

This file is **not**:
  * the small-`t` Varadhan / Molchanov asymptotic on the open
    neighbourhood of `0` (mathematically false in the stated shape,
    see drift block above),
  * a heat-trace bound of the form `K(t) ≤ C · t^{-d/2}`
    (file 3 of 6 — `Towers/YM/HeatTraceBound.lean`, not landed),
  * the off-diagonal heat kernel `K_t(g, e)` or any SU(3)
    bi-invariant metric `d_{SU(3)}(g, e)` (file 4 of 6 — requires
    Killing-form geometry not in mathlib v4.12.0),
  * a constructive 4D pure-Yang-Mills measure,
  * a mass-gap lower bound on any YM Hamiltonian,
  * a substantive close of `kotecky_preiss_criterion` (still a
    `sorry` in `Towers/Attempts/ClusterExpansion.lean`).

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2. Surface #2
stays OPEN.

================================================================
-/

import Towers.YM.PeterWeyl
import Towers.YM.PeterWeylHeat
import Towers.YM.Casimir
import Towers.YM.RiemannianGeometry
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Topology.Algebra.InfiniteSum.Order

namespace TheoremaAureum
namespace Towers
namespace YM
namespace PeterWeylHeatVaradhan

open TheoremaAureum.Towers.YM.ClusterExpansion
open TheoremaAureum.Towers.YM.PeterWeyl
open TheoremaAureum.Towers.YM.PeterWeylHeat
open TheoremaAureum.Towers.YM.RiemannianGeometry

/-! ## Helper — antitonicity of the envelope in `t` on `(0, ∞)` -/

/-- **Antitonicity of the SU(3) heat-kernel envelope.** For
`0 < t₁ ≤ t₂`, `Heat_kernel_envelope_real t₂ ≤ Heat_kernel_envelope_real t₁`.

Proof: every summand `(dim λ)² · exp(-(t · C₂(λ)))` is antitone in
`t` since `C₂(λ) ≥ 0` and `exp` is monotone. Both partial sums are
`Summable` via `PeterWeyl_Summable_SU3`, so `tsum_le_tsum` closes. -/
theorem Heat_kernel_envelope_real_antitone
    {t₁ t₂ : ℝ} (h1 : 0 < t₁) (h12 : t₁ ≤ t₂) :
    Heat_kernel_envelope_real t₂ ≤ Heat_kernel_envelope_real t₁ := by
  have h2 : 0 < t₂ := lt_of_lt_of_le h1 h12
  unfold Heat_kernel_envelope_real
  refine tsum_le_tsum (fun mn => ?_) (PeterWeyl_Summable_SU3 h2)
    (PeterWeyl_Summable_SU3 h1)
  have hcas : (0 : ℝ) ≤ (Casimir_SU3_explicit mn : ℝ) := Nat.cast_nonneg _
  have hexp_ineq :
      Real.exp (-(t₂ * (Casimir_SU3_explicit mn : ℝ))) ≤
        Real.exp (-(t₁ * (Casimir_SU3_explicit mn : ℝ))) := by
    apply Real.exp_le_exp.mpr
    have hmul : t₁ * (Casimir_SU3_explicit mn : ℝ) ≤
        t₂ * (Casimir_SU3_explicit mn : ℝ) :=
      mul_le_mul_of_nonneg_right h12 hcas
    linarith
  exact mul_le_mul_of_nonneg_left hexp_ineq (sq_nonneg _)

/-! ## Varadhan-shape constants on the strip `[t_lo, t_top]` -/

/-- Decay constant `c` in the Varadhan-shape bound. Concrete value
`1`. Positive. Traceable to the SU(3) Casimir surface only in the
weak sense that the bound holds **for this choice of `c`** because
the strip avoids the small-`t` regime where `c` would have to
match the cut-locus geometry of SU(3). -/
noncomputable def varadhan_c : ℝ := 1

/-- Strip lower endpoint `t_lo`. Concrete value `1`. Strictly
positive — the bound is **not** a small-`t` asymptotic and does not
extend to `t → 0⁺`. -/
noncomputable def varadhan_t_lo : ℝ := 1

/-- Strip upper endpoint `t_top`. Concrete value `2`. -/
noncomputable def varadhan_t_top : ℝ := 2

/-- Amplitude constant `C` in the Varadhan-shape bound, defined as
  `C := Heat_kernel_envelope_real varadhan_t_lo *`
       `varadhan_t_top ^ 4 * Real.exp (varadhan_c / varadhan_t_lo)`.
Positive because each factor is positive (the envelope is `≥ 1` on
`(0, ∞)` via `Heat_kernel_envelope_real_ge_one_of_pos`). Built
exactly to make the strip bound `env(t) ≤ C · exp(-c/t) / t^4` close
in one calc chain on `[t_lo, t_top]`. -/
noncomputable def varadhan_C : ℝ :=
  Heat_kernel_envelope_real varadhan_t_lo *
    varadhan_t_top ^ 4 * Real.exp (varadhan_c / varadhan_t_lo)

theorem varadhan_c_pos : 0 < varadhan_c := by
  unfold varadhan_c; norm_num

theorem varadhan_t_lo_pos : 0 < varadhan_t_lo := by
  unfold varadhan_t_lo; norm_num

theorem varadhan_t_top_pos : 0 < varadhan_t_top := by
  unfold varadhan_t_top; norm_num

theorem varadhan_t_lo_le_t_top : varadhan_t_lo ≤ varadhan_t_top := by
  unfold varadhan_t_lo varadhan_t_top; norm_num

theorem varadhan_C_pos : 0 < varadhan_C := by
  unfold varadhan_C
  have he : (1 : ℝ) ≤ Heat_kernel_envelope_real varadhan_t_lo :=
    Heat_kernel_envelope_real_ge_one_of_pos varadhan_t_lo_pos
  have hep : (0 : ℝ) < Heat_kernel_envelope_real varadhan_t_lo := by linarith
  have htop4 : (0 : ℝ) < varadhan_t_top ^ 4 := pow_pos varadhan_t_top_pos 4
  exact mul_pos (mul_pos hep htop4) (Real.exp_pos _)

/-! ## Headline — strip-form Varadhan-shape upper bound -/

/-- **Varadhan-shape upper bound on the SU(3) Peter-Weyl heat-kernel
envelope, strip form.** For every `t : ℝ` with
`varadhan_t_lo ≤ t ≤ varadhan_t_top`,
  `Heat_kernel_envelope_real t ≤ varadhan_C · exp(-(varadhan_c / t)) / t^4`.

See the file preamble for the (honest, locked) explanation of why
this is the strip form rather than the unrestricted small-`t` shape
asked for by the Task #156 "Done looks like" line — the literal
statement is mathematically false at any positive `(C, c, t₀)`
because `env(t) → +∞` as `t → 0⁺` while `C · exp(-c/t) / t^4 → 0`.

Proof sketch.
  - Antitonicity of `env` in `t` on `(0, ∞)` gives
    `env(t) ≤ env(t_lo)`.
  - Algebraic strip fact:
      `C · exp(-c/t) / t^4`
        = `env(t_lo) · (t_top^4 / t^4) · exp(c/t_lo) · exp(-c/t)`
        ≥ `env(t_lo) · 1 · 1`         (each factor `≥ 1`)
        = `env(t_lo)`,
    where `t_top^4 / t^4 ≥ 1` because `t ≤ t_top`, and
    `exp(c/t_lo - c/t) ≥ exp(0) = 1` because `c > 0` and
    `c/t ≤ c/t_lo` (since `t_lo ≤ t > 0`).
  - Chain the two. -/
theorem Heat_kernel_envelope_real_le_varadhan
    {t : ℝ} (ht_lo : varadhan_t_lo ≤ t) (ht_top : t ≤ varadhan_t_top) :
    Heat_kernel_envelope_real t ≤
      varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 := by
  have htpos : 0 < t := lt_of_lt_of_le varadhan_t_lo_pos ht_lo
  have ht4_pos : 0 < t ^ 4 := pow_pos htpos 4
  -- Step 1: monotonicity.
  have hmono :
      Heat_kernel_envelope_real t ≤ Heat_kernel_envelope_real varadhan_t_lo :=
    Heat_kernel_envelope_real_antitone varadhan_t_lo_pos ht_lo
  -- Step 2: bound RHS from below by `env(t_lo)`.
  have he : (1 : ℝ) ≤ Heat_kernel_envelope_real varadhan_t_lo :=
    Heat_kernel_envelope_real_ge_one_of_pos varadhan_t_lo_pos
  have hep_nonneg : 0 ≤ Heat_kernel_envelope_real varadhan_t_lo := by linarith
  have htop4_pos : 0 < varadhan_t_top ^ 4 := pow_pos varadhan_t_top_pos 4
  -- (a) `c/t ≤ c/t_lo` since `0 < t_lo ≤ t` and `c > 0`.
  have hclo : varadhan_c / t ≤ varadhan_c / varadhan_t_lo := by
    rw [div_le_div_iff htpos varadhan_t_lo_pos]
    have := mul_le_mul_of_nonneg_left ht_lo varadhan_c_pos.le
    linarith
  -- (b) Hence `exp(c/t_lo) · exp(-c/t) ≥ exp(0) = 1`.
  have hexp_ineq :
      1 ≤ Real.exp (varadhan_c / varadhan_t_lo) *
            Real.exp (-(varadhan_c / t)) := by
    rw [← Real.exp_add]
    have h0 : (0 : ℝ) ≤ varadhan_c / varadhan_t_lo + -(varadhan_c / t) := by
      linarith
    calc (1 : ℝ) = Real.exp 0 := Real.exp_zero.symm
      _ ≤ Real.exp (varadhan_c / varadhan_t_lo + -(varadhan_c / t)) :=
            Real.exp_le_exp.mpr h0
  -- (c) `t^4 ≤ t_top^4` since `0 ≤ t ≤ t_top`.
  have ht4_le : t ^ 4 ≤ varadhan_t_top ^ 4 :=
    pow_le_pow_left htpos.le ht_top 4
  -- Combine: `env(t_lo) ≤ C · exp(-c/t) / t^4`.
  have hrhs :
      Heat_kernel_envelope_real varadhan_t_lo ≤
        varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 := by
    rw [le_div_iff₀ ht4_pos]
    have hC_eq :
        varadhan_C * Real.exp (-(varadhan_c / t)) =
          Heat_kernel_envelope_real varadhan_t_lo *
            varadhan_t_top ^ 4 *
              (Real.exp (varadhan_c / varadhan_t_lo) *
                Real.exp (-(varadhan_c / t))) := by
      unfold varadhan_C; ring
    rw [hC_eq]
    calc Heat_kernel_envelope_real varadhan_t_lo * t ^ 4
        ≤ Heat_kernel_envelope_real varadhan_t_lo * varadhan_t_top ^ 4 :=
            mul_le_mul_of_nonneg_left ht4_le hep_nonneg
      _ = Heat_kernel_envelope_real varadhan_t_lo * varadhan_t_top ^ 4 * 1 := by
            ring
      _ ≤ Heat_kernel_envelope_real varadhan_t_lo * varadhan_t_top ^ 4 *
            (Real.exp (varadhan_c / varadhan_t_lo) *
              Real.exp (-(varadhan_c / t))) :=
            mul_le_mul_of_nonneg_left hexp_ineq
              (mul_nonneg hep_nonneg htop4_pos.le)
  linarith

/-! ## Geometric (off-diagonal Varadhan-shape) brick — Task #170 -/

/-- **Geometric decay constant** `c_geom(x) := d_SU3(x, 1)² / 4`.
This is the **off-diagonal** Varadhan/Molchanov small-`t` constant
`d_g(x, e)² / 4` from `K_t(x, e) ≲ t^{-d/2} · exp(-d(x, e)² / 4t)`
— now expressed against the stand-in bi-invariant distance
`d_SU3 : SU3 → SU3 → ℝ` from `Towers/YM/RiemannianGeometry.lean`.

Because `d_SU3 ≡ 0` in the current stand-in, `c_geom(x) = 0` for
every `x`. Replacing `d_SU3` with the real Killing-form distance
will *intentionally* break the downstream geometric brick (since
the proof exploits `d_SU3 x 1 = 0` rfl-style) — that is the
tripwire signalling a real off-diagonal Varadhan bound has
landed. -/
noncomputable def varadhan_geometric_c (x : SU3) : ℝ :=
  (d_SU3 x (1 : SU3)) ^ 2 / 4

/-- The geometric decay constant vanishes **on the diagonal** locus
`{x : d_SU3 x 1 = 0}` (which, under the real chordal distance, is the
single point `x = 1`). The canonical witness is `x = 1`, where
`d_SU3 1 1 = 0` by `RiemannianGeometry.d_SU3_self`.

**Tripwire (Task #189).** Under the Task #170 stand-in `d_SU3 ≡ 0`
this held for *every* `x` (`rfl`). Now that `d_SU3` is the real
Killing-form chordal distance it holds only on the diagonal — the
off-diagonal case `d_SU3 x 1 > 0` is precisely the open off-diagonal
Varadhan / Molchanov regime. -/
theorem varadhan_geometric_c_one :
    varadhan_geometric_c (1 : SU3) = 0 := by
  unfold varadhan_geometric_c
  rw [RiemannianGeometry.d_SU3_self]
  ring

/-- **Geometric-form Varadhan-shape upper bound on the SU(3)
Peter-Weyl heat-kernel envelope, strip form (Task #170).** For
every `t : ℝ` with `varadhan_t_lo ≤ t ≤ varadhan_t_top` and every
`x : SU3`,
  `Heat_kernel_envelope_real t ≤`
      `varadhan_C · exp(-(d_SU3 x 1)^2 / (4 · t)) / t^4`.

This is the **shape** the real off-diagonal Varadhan asymptotic
would consume — the same `exp(-d(x, e)² / 4t)` factor and the
same `t^{-4}` polynomial decay.

**Task #189 tripwire — diagonal hypothesis.** With `d_SU3` upgraded
to the *real* Killing-form chordal distance (file
`Towers/YM/RiemannianGeometry.lean`), the `exp(-d(x, 1)² / (4t))`
factor no longer collapses to `1` for arbitrary `x`: when
`d_SU3 x 1 > 0` the right-hand side is *strictly smaller* than
`varadhan_C / t^4`, so the bound can NO LONGER be derived from the
strip bound — that off-diagonal case is exactly the open
Varadhan / Molchanov asymptotic. The brick is therefore re-stated
with an explicit diagonal hypothesis `hx : d_SU3 x 1 = 0` (the locus
`{x : d_SU3 x 1 = 0} = {1}`), on which the factor genuinely equals
`exp 0 = 1` and the bound reduces to the existing strip bound plus
`exp(-c/t) ≤ 1`. The canonical witness is `x = 1` via
`RiemannianGeometry.d_SU3_self`. The breaking of the old `rfl`-style
proof IS the tripwire the Task #170/#189 brief describes.

**Honest scope (locked).** This is NOT the real off-diagonal
Varadhan / Molchanov asymptotic — see the file preamble and the
`RiemannianGeometry.lean` docstring. The off-diagonal envelope
(`x` with `d_SU3 x 1 > 0`) remains open. YM tower stays
`Status: Open`. -/
theorem Heat_kernel_envelope_real_le_varadhan_geometric
    {t : ℝ} (ht_lo : varadhan_t_lo ≤ t) (ht_top : t ≤ varadhan_t_top)
    (x : SU3) (hx : d_SU3 x (1 : SU3) = 0) :
    Heat_kernel_envelope_real t ≤
      varadhan_C *
        Real.exp (-((d_SU3 x (1 : SU3)) ^ 2 / (4 * t))) / t ^ 4 := by
  have htpos : 0 < t := lt_of_lt_of_le varadhan_t_lo_pos ht_lo
  have ht4_pos : 0 < t ^ 4 := pow_pos htpos 4
  -- Step 1: existing strip bound.
  have hstrip :
      Heat_kernel_envelope_real t ≤
        varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 :=
    Heat_kernel_envelope_real_le_varadhan ht_lo ht_top
  -- Step 2: the geometric exp factor collapses to `1` on the diagonal.
  have hd : d_SU3 x (1 : SU3) = 0 := hx
  have hgeom_zero : (d_SU3 x (1 : SU3)) ^ 2 / (4 * t) = 0 := by
    rw [hd]; ring
  have hexp_geom :
      Real.exp (-((d_SU3 x (1 : SU3)) ^ 2 / (4 * t))) = 1 := by
    rw [hgeom_zero, neg_zero, Real.exp_zero]
  -- Step 3: `exp(-(c/t)) ≤ 1` since `c, t > 0`.
  have hcoverpos : 0 ≤ varadhan_c / t :=
    div_nonneg varadhan_c_pos.le htpos.le
  have hexp_le_one :
      Real.exp (-(varadhan_c / t)) ≤ 1 := by
    calc Real.exp (-(varadhan_c / t))
        ≤ Real.exp 0 := Real.exp_le_exp.mpr (by linarith)
      _ = 1 := Real.exp_zero
  -- Step 4: turn the geometric RHS into `varadhan_C / t^4` and chain.
  have hVC_pos : 0 < varadhan_C := varadhan_C_pos
  have h_geom_rhs :
      varadhan_C *
          Real.exp (-((d_SU3 x (1 : SU3)) ^ 2 / (4 * t))) / t ^ 4 =
        varadhan_C / t ^ 4 := by
    rw [hexp_geom, mul_one]
  rw [h_geom_rhs]
  -- And the strip RHS is `≤ varadhan_C / t^4` since `exp(-c/t) ≤ 1`.
  have hnum :
      varadhan_C * Real.exp (-(varadhan_c / t)) ≤ varadhan_C := by
    calc varadhan_C * Real.exp (-(varadhan_c / t))
        ≤ varadhan_C * 1 :=
          mul_le_mul_of_nonneg_left hexp_le_one hVC_pos.le
      _ = varadhan_C := mul_one _
  have hstrip_le :
      varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 ≤
        varadhan_C / t ^ 4 := by
    rw [div_le_div_iff ht4_pos ht4_pos]
    nlinarith [hnum, ht4_pos]
  exact le_trans hstrip hstrip_le

end PeterWeylHeatVaradhan
end YM
end Towers
end TheoremaAureum
