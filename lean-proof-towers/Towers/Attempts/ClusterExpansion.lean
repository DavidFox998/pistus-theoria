/-
================================================================
Towers / Attempts / ClusterExpansion  (Batch 19.1f / 19.1g,
sorry-bearing)

**Real Brydges-Federbush strict-contraction surface for the YM
transfer operator `T_g`.** Parked here as `sorry`-bearing stubs.
NOT registered in BRICKS — keeps the green-wall axiom footprint
`⊆ {propext, Classical.choice, Quot.sound}` untouched.

The 19.1f / 19.1g bricks in `Towers/YM/ClusterExpansion.lean`
ship the `≤ Decay_constant_from_KP` / `≤ Decay_constant_real`
placeholder slices. The strict `< 1` forms live here, where they
can carry a `sorry` without polluting the wall.

**Name change (19.1g).** The 19.1f-shipped sorry
`Spectral_radius_lt_one_real` was renamed to
`Spectral_radius_lt_one_strict_real` to free the name for the
19.1g BRICK `Spectral_radius_lt_one_real` in
`Towers/YM/ClusterExpansion.lean` (a named-handle bridge that
passes a strict-`< 1` hypothesis through). The mathematical
content of the renamed sorry is unchanged.

**What the real discharge needs (out of scope for these batches):**

  1. A real polymer measure `μ_pol` on `SU(3)^{|Λ|}` lattice
     polymer configurations, built from `Wilson_measure_def` via
     the Mayer-Montroll formal series.
  2. The Brydges-Federbush inductive Ursell bound
     `|φ_T(X)| ≤ Real.exp (X.card : ℝ) * (X.card)!` for `g < g₀`,
     which requires `Mathlib.Analysis.SpecialFunctions.Exp.Basic`.
  3. The Kotecky-Preiss strict criterion `K * e * Δ < 1` with
     `e = Real.exp 1` (NOT the 19.1f `e = 1` slice nor the 19.1g
     `Combinatorial_constant_e := 1` placeholder), which requires
     `Real.exp 1` and `Real.log` (for the decay constant
     `m := -log(K * e * Δ)`).
  4. A real `BoundedLinearMap` instance on the still-NAMED
     `physHilbert` so that `spectral_radius_def` can be
     promoted away from the literal `1` placeholder.

These four are the four sorries Batch 19.1h+ would have to
discharge.
================================================================
-/

import Towers.YM.OSReconstruction
import Towers.YM.SpectralGap
import Towers.YM.ClusterExpansion

namespace TheoremaAureum
namespace Towers
namespace Attempts
namespace ClusterExpansion

open TheoremaAureum.Towers.YM.OSReconstruction
open TheoremaAureum.Towers.YM.SpectralGap
open TheoremaAureum.Towers.YM.ClusterExpansion

/-- **Real strict contraction `g < g₀ → ‖T_g‖ ≤ e^{-m} < 1`.**

Honest scope: with the current placeholder
`spectral_radius_def := 1` and `Decay_constant_from_KP := 1`, the
`≤ 1` half is the 19.1f brick `Strict_contraction_CE`. The
strict `< 1` half is **false on its face** at the placeholder
(`(1 : ℝ) < 1` is `False`) — that mismatch is intentional, it is
the tripwire telling Batch 19.1h+ that promoting both
`spectral_radius_def` and `Decay_constant_from_KP` away from `1`
will require landing the real Brydges-Federbush polymer
expansion here. Marked `sorry`; lives outside BRICKS so the
axiom footprint of the green wall is untouched. -/
theorem Strict_contraction_CE_real (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def) :
    spectral_radius_def D g < 1 := by
  sorry

/-- **Real strict contraction (19.1g form): `g < g₀ → ‖T_g‖ <
Decay_constant_real`.** Strict-`<` companion to the 19.1g BRICK
`Strict_contraction_real` (which ships `≤`). At the placeholder
`spectral_radius_def := 1`, `Decay_constant_real := 1` this
unfolds to `(1 : ℝ) < 1`, false — the intentional tripwire that
the `≤ → <` gap is exactly the Brydges-Federbush strict
contraction content (Glimm-Jaffe Lemma 18.5.3). Marked
`sorry`. -/
theorem Strict_contraction_real_strict (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def) :
    spectral_radius_def D g < Decay_constant_real := by
  sorry

/-- **Real spectral radius `< 1` for `g < g₀` (renamed 19.1g).**

Previously named `Spectral_radius_lt_one_real` (19.1f); renamed
to free that identifier for the 19.1g BRICK in
`Towers/YM/ClusterExpansion.lean` (a named-handle bridge that
threads a strict hypothesis). Mathematical content unchanged:
the strict `spectral_radius_def D g < 1` for `g` in the small-
coupling regime, the single named target whose discharge would
flip the YM tower from `Status: Open` to `Status: Closed`.

Composes directly with the 19.1f bridge brick
`Spectral_radius_lt_one`, the 19.1g `Spectral_radius_lt_one_real`
named-handle, the 19.1c `Perron_Frobenius_statement`, and the
19.1g `MassGap_YM4_from_KP` to land `0 < mass_gap_def D g` and
the Clay-shape `∃ Δ > 0, Δ ≤ mass_gap_def D g` for `g < g₀`.
Marked `sorry`. -/
theorem Spectral_radius_lt_one_strict_real (D : OSPreHilbert) (g : ℝ)
    (_h : g < Small_g_regime_def) :
    spectral_radius_def D g < 1 := by
  sorry

end ClusterExpansion
end Attempts
end Towers
end TheoremaAureum
