---
name: Rigorous exp(constant) enclosure in Lean (mathlib v4.12.0)
description: How to bracket Real.exp of an exact rational constant via Taylor+Lagrange when norm_num/Real.exp_bound can't reach it; plus the derivWithin / positivity gotchas.
---

# Enclosing `Real.exp (-c)` for a rational constant `c ≈ 2.08`

`Real.exp_bound` only covers `|x| ≤ 1`; `norm_num` cannot decimalise `Real.exp`.
For `c` outside `[-1,1]` the working path is `taylor_mean_remainder_lagrange`
(Mathlib/Analysis/Calculus/Taylor.lean) on `g t = exp (-t)` over `[0,c]`
(orientation `0 < c`), giving an **alternating Lagrange bracket** with ℚ
endpoints:
`S_N - c^{N+1}/(N+1)!  ≤  exp(-c)  ≤  S_N`  for `N` even, where
`S_N = ∑_{k≤N} (-c)^k/k!`. Sign is correct because the `(N+1)`-th derivative is
`(-1)^{N+1} exp(-ξ)` and `0 < exp(-ξ) < 1` on `(0,c)`, so the remainder term is
`-R` with `0 < R < c^{N+1}/(N+1)!`. At `N=32`, `c=β₀≈2.0794`, width `≈3.6e-27`.

Key moving parts: prove `iteratedDerivWithin n g [0,c] x = (-1)^n·exp(-x)` by
induction (`iteratedDerivWithin_succ` + `derivWithin_congr` + the HasDerivAt of
`exp∘neg`); identify the Taylor poly with the cast partial sum via
`taylor_within_apply` + `Rat.cast_sum`/`neg_pow`; keep the output interval built
with `min/max` so the structural `lo ≤ hi` is free and the point case collapses
via `min_eq_left`/`max_eq_right`.

## Two gotchas that bite

- **`HasDerivAt.derivWithin` does NOT exist in v4.12.0.** Converting a
  `HasDerivAt h` to a `derivWithin` value needs
  `h.hasDerivWithinAt.derivWithin (hu x hx)` (i.e. go through
  `HasDerivWithinAt.derivWithin` with the `UniqueDiffWithinAt` witness). The
  direct `.derivWithin` field projection fails with "environment does not
  contain HasDerivAt.derivWithin".
- **`positivity` can't sign a cast-rational power.** For
  `0 < (↑c)^n / (m! : ℝ)` positivity stalls — it doesn't know `(↑c) > 0`.
  Supply it: `div_pos (pow_pos hc_pos _) (by exact_mod_cast Nat.factorial_pos m)`
  where `hc_pos : (0:ℝ) < (↑c)` is `exact_mod_cast` of the ℚ fact.

## Verifying the numerics (sanity, NOT the proof)

Lean's machine-check + `#print axioms` = classical trio IS the ground truth.
A `float` check of the bracket is USELESS here: width `~3.6e-27` is ~10 orders
below double epsilon, so `lo <= exp <= hi` can return a spurious `False` purely
from roundoff. To sanity-check the story, use `mpmath` with `mp.dps≥30` (and
build `c` from the exact integer ratio, not the float literal).
