/-
================================================================
Towers / YM / VaradhanStripWidened  (Task #174 / Task #156 file 4
of 6, follow-on to Batch 156.3 — small-`t` Varadhan strip
refinement, **honest stand-in**)

**One-line summary.** Re-state the strip-form Varadhan-shape upper
bound `Heat_kernel_envelope_real_le_varadhan` (Batch 156.3, file
`Towers/YM/PeterWeylHeatVaradhan.lean`) against a **wider** strip
`[varadhan_t_lo_widened, varadhan_t_top_widened]` whose interior
contains the original strip `[varadhan_t_lo, varadhan_t_top]`.
Inside the *original* strip the new endpoints differ from the old
by additive padding (`varadhan_t_lo_widened := varadhan_t_lo / 2`,
`varadhan_t_top_widened := varadhan_t_top * 2`), and the existing
bound transports across the inclusion **without** changing the
RHS constants `varadhan_C`, `varadhan_c`.

### Drift / honest scope (locked)

The original Task #156 brief asked for a *true* small-`t`
refinement: extend the strip toward `t = 0⁺` and re-derive the
constants so the bound stays sharp. **That refinement is
mathematically false** in the literal Varadhan shape (see the
preamble of `Towers/YM/PeterWeylHeatVaradhan.lean` — `env(t) → +∞`
as `t → 0⁺` while `C · exp(-c/t) / t^4 → 0`, so no positive `(C, c)`
can hold on any neighbourhood of `0`).

What this file ships instead:

  * A pair of wider strip endpoints `varadhan_t_lo_widened`,
    `varadhan_t_top_widened` whose closed interval **strictly
    contains** the original strip (the widened lower endpoint is
    `varadhan_t_lo / 2 = 1/2`, the widened upper is
    `varadhan_t_top * 2 = 4`).
  * Positivity of the widened endpoints and the strict containment
    `varadhan_t_lo_widened < varadhan_t_lo` /
    `varadhan_t_top < varadhan_t_top_widened`.
  * A re-statement of the strip bound `Heat_kernel_envelope_real_le_varadhan_widened`
    on the *original* strip carried under the *widened* signature:
    when `varadhan_t_lo ≤ t ≤ varadhan_t_top` (i.e. `t` is in the
    original strip, which is contained in the widened one), the
    existing bound holds. This is **not** a real extension of the
    valid `t`-range — the widened endpoints are just slots for a
    future genuine refinement to fill once a real off-diagonal
    Varadhan / Killing-form argument lands.

YM tower stays `Status: Open` in `docs/ROADMAP.md` § 2. Surface #2
stays OPEN.

### Invariants honored

  * Sorry-free (this file has zero `sorry`).
  * Axiom footprint ⊆ `{propext, Classical.choice, Quot.sound}`.
  * No new defs of `varadhan_C`, `varadhan_c`, or the envelope —
    they remain owned by `PeterWeylHeatVaradhan.lean`.
  * No claim about the small-`t` asymptotic on
    `(0, varadhan_t_lo)`. The bound is **not** valid there and is
    not stated there.

================================================================
-/

import Towers.YM.PeterWeylHeatVaradhan

namespace TheoremaAureum
namespace Towers
namespace YM
namespace VaradhanStripWidened

open TheoremaAureum.Towers.YM.PeterWeylHeat
open TheoremaAureum.Towers.YM.PeterWeylHeatVaradhan

/-- **Widened strip lower endpoint.** Concrete value
`varadhan_t_lo / 2 = 1/200` (tracks the Task #190 widening of
`varadhan_t_lo` to `1/100`). Strictly positive but strictly less
than `varadhan_t_lo`; the widening is a *slot* for a future
genuine small-`t` refinement, **not** itself a valid lower bound
for the strip-form Varadhan inequality (the inequality is false on
`(0, varadhan_t_lo)`). -/
noncomputable def varadhan_t_lo_widened : ℝ := varadhan_t_lo / 2

/-- **Widened strip upper endpoint.** Concrete value
`varadhan_t_top * 2 = 200` (tracks the Task #190 widening of
`varadhan_t_top` to `100`). -/
noncomputable def varadhan_t_top_widened : ℝ := varadhan_t_top * 2

/-- The widened lower endpoint is strictly positive. -/
theorem varadhan_t_lo_widened_pos : 0 < varadhan_t_lo_widened := by
  unfold varadhan_t_lo_widened varadhan_t_lo; norm_num

/-- The widened upper endpoint is strictly positive. -/
theorem varadhan_t_top_widened_pos : 0 < varadhan_t_top_widened := by
  unfold varadhan_t_top_widened varadhan_t_top; norm_num

/-- The widened strip strictly contains the original strip on the
left: `varadhan_t_lo_widened < varadhan_t_lo`. -/
theorem varadhan_t_lo_widened_lt : varadhan_t_lo_widened < varadhan_t_lo := by
  unfold varadhan_t_lo_widened varadhan_t_lo; norm_num

/-- The widened strip strictly contains the original strip on the
right: `varadhan_t_top < varadhan_t_top_widened`. -/
theorem varadhan_t_top_lt_widened : varadhan_t_top < varadhan_t_top_widened := by
  unfold varadhan_t_top_widened varadhan_t_top; norm_num

/-- **Strip-form Varadhan-shape upper bound, widened-signature
re-statement.** When `t` lies in the *original* strip
`[varadhan_t_lo, varadhan_t_top]` (necessarily inside the widened
strip), the existing bound from `PeterWeylHeatVaradhan.lean`
applies verbatim — the RHS constants `varadhan_C`, `varadhan_c`
are unchanged.

This is **not** a genuine extension of the valid `t`-range: the
hypotheses are still the original strip bounds. The widened
endpoint defs above are slots for a future refinement, not an
honest claim that the bound holds on the wider window. -/
theorem Heat_kernel_envelope_real_le_varadhan_widened
    {t : ℝ} (ht_lo : varadhan_t_lo ≤ t) (ht_top : t ≤ varadhan_t_top) :
    Heat_kernel_envelope_real t ≤
      varadhan_C * Real.exp (-(varadhan_c / t)) / t ^ 4 :=
  Heat_kernel_envelope_real_le_varadhan ht_lo ht_top

end VaradhanStripWidened
end YM
end Towers
end TheoremaAureum
