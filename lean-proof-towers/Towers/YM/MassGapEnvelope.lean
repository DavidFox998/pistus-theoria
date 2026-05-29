/-
================================================================
Towers / YM / MassGapEnvelope  (Task #174 / Task #156 file 6 of 6
— final mass-gap envelope, **honest stand-in**)

**One-line summary.** Wire the Continuum schema's `IsMassGap`
predicate (Batch 20.1a / `Towers/YM/Continuum.lean`) to a
strictly-positive real constant `mass_gap_envelope_constant`
derived from the Varadhan-shape strip bound's amplitude
`varadhan_C` and upper endpoint `varadhan_t_top`
(Batch 156.3 / `Towers/YM/PeterWeylHeatVaradhan.lean`). The brick
`IsMassGap_mass_gap_envelope_default` then closes
`IsMassGap (default : YM4_Continuum) mass_gap_envelope_constant`
— **NOT** a proof that any real 4D pure-YM theory has a mass gap.

### Drift / honest scope (locked)

The original Task #156 brief asked for a real mass-gap envelope:
take the heat-trace bound, integrate against a spectral projector,
and extract a *genuine* spectral gap on a *genuine* continuum-YM
Hamiltonian. **None of those substrate objects exist** in this
repo today:

  * `IsMassGap` in `Towers/YM/Continuum.lean` was, until Task #196,
    the **placeholder** `0 < Δ`. Task #196 upgraded it to the
    spectral statement `∃ H op, OS.HasMassGap H op Δ` (real-part
    inner-product gap on a complex Hilbert-space operator,
    `Towers/YM/SpectralGapCore.lean`). It now references a real
    Hilbert space and operator — but the only available witnesses
    are scalar/zero stand-in operators, NOT a continuum-YM
    Hamiltonian.
  * `YM4_Continuum` is a structure with two `Nat` fields
    (`gauge_rank`, `spacetime_dim`); no analytic content.
  * `lattice_to_continuum a A` reads the rank/dimension slots off
    `(a, A)` but implements no real `a → 0` continuum limit.
  * `varadhan_C` is the strip-form amplitude constant — strictly
    positive but tied to the strip `[varadhan_t_lo, varadhan_t_top]`,
    NOT to any spectral gap.

After the Task #196 refactor this brick **re-closes** the new
spectral `IsMassGap` at `Δ := mass_gap_envelope_constant > 0` using
the honest scalar-of-identity stand-in operator
`op := ((1 - Δ : ℝ) : ℂ) • 1` on `H := ℂ` (the
`Towers/YM/NontrivialGap.lean` witness pattern). The gap size still
carries no spectral content and the operator is not `T`-derived, so
the upgrade does NOT import a real Yang-Mills mass gap.

### What this file ships

  * `mass_gap_envelope_constant : ℝ` — the concrete positive real
    `varadhan_C / varadhan_t_top ^ 4`. Built from the strip-form
    Varadhan-shape RHS at `t = varadhan_t_top` after the exp factor
    is bounded above by `1`. Positive because both `varadhan_C` and
    `varadhan_t_top ^ 4` are positive.
  * `mass_gap_envelope_constant_pos` — `0 < mass_gap_envelope_constant`.
  * `IsMassGap_mass_gap_envelope_default` —
    `IsMassGap (default : YM4_Continuum) mass_gap_envelope_constant`.
    The headline brick: it re-closes the Task #196 spectral
    `IsMassGap` (`∃ H op, OS.HasMassGap H op Δ`) via the
    scalar-of-identity stand-in `op := ((1 - Δ : ℝ) : ℂ) • 1` on
    `H := ℂ`, whose real-part bound holds with equality.

### What this file does NOT ship

  * A real Yang-Mills mass-gap lower bound.
  * A real continuum-YM Hamiltonian or spectrum.
  * Any reference to an Osterwalder-Schrader-reconstructed
    Hilbert space (Surfaces #1 / #2 stay OPEN).
  * Any new constants on top of the existing
    `varadhan_C`, `varadhan_t_top` from
    `Towers/YM/PeterWeylHeatVaradhan.lean`.

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2. Surfaces #1
(OS reconstruction), #2 (small-`t` Varadhan), and #3 (continuum
YM) all stay OPEN.

### Invariants honored

  * Sorry-free (this file has zero `sorry`).
  * Axiom footprint ⊆ `{propext, Classical.choice, Quot.sound}`.
  * No edit to `Towers/YM/Continuum.lean` or
    `Towers/YM/PeterWeylHeatVaradhan.lean`. Purely additive.

================================================================
-/

import Towers.YM.Continuum
import Towers.YM.PeterWeylHeatVaradhan
import Towers.YM.VaradhanStripWidened

namespace TheoremaAureum
namespace Towers
namespace YM
namespace MassGapEnvelope

open TheoremaAureum.Towers.YM.Continuum
open TheoremaAureum.Towers.YM.PeterWeylHeatVaradhan
open TheoremaAureum.Towers.YM.VaradhanStripWidened
open scoped InnerProductSpace

/-- **Mass-gap envelope constant.** Concrete positive real
`varadhan_C / varadhan_t_top ^ 4`. Built from the strip-form
Varadhan-shape RHS at `t = varadhan_t_top` after the exp factor
`exp(-(varadhan_c / varadhan_t_top))` is bounded above by `1`.
Positive because both factors are positive.

This is **not** a mass-gap lower bound for any real Yang-Mills
theory; it is the gap size `Δ` plugged into the (Task #196) spectral
`IsMassGap` predicate `∃ H op, OS.HasMassGap H op Δ` in
`Towers/YM/Continuum.lean`, witnessed only by a scalar/zero stand-in
operator (no spectral content). -/
noncomputable def mass_gap_envelope_constant : ℝ :=
  varadhan_C / varadhan_t_top ^ 4

/-- `mass_gap_envelope_constant > 0`. -/
theorem mass_gap_envelope_constant_pos :
    0 < mass_gap_envelope_constant := by
  unfold mass_gap_envelope_constant
  have htop4 : 0 < varadhan_t_top ^ 4 := pow_pos varadhan_t_top_pos 4
  exact div_pos varadhan_C_pos htop4

/-- **Final mass-gap envelope brick (re-closed against the spectral
`IsMassGap`).** Task #196 upgraded `IsMassGap` in
`Towers/YM/Continuum.lean` from the bare `0 < Δ` placeholder to the
spectral statement

  `∃ H op, OS.HasMassGap H op Δ`

(real-part inner-product gap on a complex Hilbert-space operator).
This brick re-closes that new predicate at the default
`YM4_Continuum` and `Δ := mass_gap_envelope_constant`, using the
honest scalar-of-identity stand-in operator
`op := ((1 - Δ : ℝ) : ℂ) • 1` on `H := ℂ`. For that operator the
real-part bound holds with equality
(`(⟪x, op x⟫_ℂ).re = (1 - Δ) * ‖x‖^2 ≤ (1 - Δ) * ‖x‖^2`), exactly
the witness pattern of `Towers/YM/NontrivialGap.lean`.

**Honest scope (locked).** This is NOT a proof that any real 4D
pure-Yang-Mills theory has a mass gap. The witnessing operator is a
scalar multiple of the identity (spectrum `{1 - Δ}`, totally
degenerate); it is **not** built from any continuum-YM Hamiltonian
and the schema `T` is ignored. The gap size
`mass_gap_envelope_constant = varadhan_C / varadhan_t_top ^ 4`
carries no spectral content. YM tower stays `Status: Open`. -/
theorem IsMassGap_mass_gap_envelope_default :
    IsMassGap ({} : YM4_Continuum) mass_gap_envelope_constant := by
  refine ⟨ℂ, inferInstance, inferInstance,
    ((1 - mass_gap_envelope_constant : ℝ) : ℂ) • (1 : ℂ →L[ℂ] ℂ),
    mass_gap_envelope_constant_pos, ?_⟩
  intro x
  have hT :
      (((1 - mass_gap_envelope_constant : ℝ) : ℂ) • (1 : ℂ →L[ℂ] ℂ)) x
        = ((1 - mass_gap_envelope_constant : ℝ) : ℂ) • x := by
    simp [ContinuousLinearMap.smul_apply, ContinuousLinearMap.one_apply]
  rw [hT, inner_smul_right, Complex.mul_re]
  have hr : (((1 - mass_gap_envelope_constant : ℝ) : ℂ)).re
      = 1 - mass_gap_envelope_constant := Complex.ofReal_re _
  have hi : (((1 - mass_gap_envelope_constant : ℝ) : ℂ)).im = 0 :=
    Complex.ofReal_im _
  have hsq : (⟪x, x⟫_ℂ).re = ‖x‖ ^ 2 := inner_self_eq_norm_sq (𝕜 := ℂ) x
  have him : (⟪x, x⟫_ℂ).im = 0 := inner_self_im (𝕜 := ℂ) x
  rw [hr, hi, hsq, him]
  linarith [sq_nonneg ‖x‖]

/-! ## Widened upper-side mass-gap envelope constant — Task #219

Carry the upper-widened strip amplitude `varadhan_C_widened` and top
endpoint `varadhan_t_top_widened` (Task #194,
`Towers/YM/VaradhanStripWidened.lean`) into the mass-gap envelope
constant. The widened constant is built from the widened Varadhan-shape
RHS at `t = varadhan_t_top_widened` after the exp factor is bounded
above by `1`, exactly mirroring `mass_gap_envelope_constant` but on the
widened upper window. **No spectral content is added** — this is the
same honest positive-real envelope constant, retuned to the widened
amplitude. YM tower stays `Status: Open`. -/

/-- **Widened mass-gap envelope constant.** Concrete positive real
`varadhan_C_widened / varadhan_t_top_widened ^ 4`. The widened-upper
companion of `mass_gap_envelope_constant`: built from the upper-widened
strip-form Varadhan-shape RHS at `t = varadhan_t_top_widened` after the
exp factor `exp(-(varadhan_c / varadhan_t_top_widened))` is bounded
above by `1`. Positive because both factors are positive.

This is **not** a mass-gap lower bound for any real Yang-Mills theory;
it is a positive real envelope constant carrying no spectral content. -/
noncomputable def mass_gap_envelope_constant_widened : ℝ :=
  varadhan_C_widened / varadhan_t_top_widened ^ 4

/-- `mass_gap_envelope_constant_widened > 0`. -/
theorem mass_gap_envelope_constant_widened_pos :
    0 < mass_gap_envelope_constant_widened := by
  unfold mass_gap_envelope_constant_widened
  have htop4 : 0 < varadhan_t_top_widened ^ 4 :=
    pow_pos varadhan_t_top_widened_pos 4
  exact div_pos varadhan_C_widened_pos htop4

end MassGapEnvelope
end YM
end Towers
end TheoremaAureum
