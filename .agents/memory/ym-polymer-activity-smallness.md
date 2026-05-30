---
name: YM polymer-activity smallness is FALSE unconditionally
description: Why ∀γ, polymerActivity β γ ≤ (1/8)^|γ| cannot hold without a β/threshold hypothesis, and where the real KP smallness lives.
---

# Polymer-activity smallness is conditional, never pointwise/unconditional

`polymerActivity L β γ := ∫ w, exp(-β · polymerEnergy (toGauge L w) γ) ∂(haarN …)`
where `haarN` is a **probability** measure.

**Rule:** any lemma of the shape `∀ γ, polymerActivity β γ ≤ (1/8)^|γ|` with NO
hypothesis on `β` (or no strong-coupling threshold) is **FALSE** — refuse it.

**Why:**
- At `β = 0` the integrand is `exp 0 = 1`, and `∫ 1 ∂haarN = 1` (probability
  measure). So `polymerActivity L 0 γ = 1` for EVERY `γ`, including nonempty `γ`
  where `(1/8)^|γ| < 1`. Direct counterexample.
- A pointwise per-polymer energy LOWER bound `∀ w, c·|γ| ≤ polymerEnergy
  (toGauge L w) γ` with `c > 0` is ALSO false: the vacuum link field `w ≡ 1` has
  `polymerEnergy = 0` (every plaquette is the identity,
  `plaquetteEnergy_const_one`). So `inf_{w} polymerEnergy = 0`; there is no
  energy floor to exponentiate.

**How to apply:**
- The honest version takes hypotheses `0 ≤ β` and a threshold `log 8 ≤ β·c` plus
  a NAMED OPEN energy lower bound, and runs `integral_mono` over the probability
  measure. That is `Wall257_StrongCoupling` (conditional combinator + the
  `vacuum_breaks_energy_lb` honest-gap record proving the hypothesis is
  unsatisfiable for `c>0`).
- The genuine Kotecký–Preiss smallness lives at the **integral/measure** level
  (how `haarN` concentrates near the vacuum as `β → ∞`), NOT at any pointwise
  energy floor. Do not try to derive activity smallness from `inf` energy.
- Watch the inequality direction: `kEff_le`/`c_S4_lt`-style facts are UPPER
  bounds; a per-polymer energy floor needs a LOWER bound — they don't compose.
