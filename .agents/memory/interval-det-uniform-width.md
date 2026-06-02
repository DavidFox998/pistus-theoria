---
name: Interval determinant uniform-width bound
description: How to certify a 3x3 (Bessel-)matrix determinant enclosure in RatInterval arithmetic without any per-k kernel compute.
---

# Certified determinant enclosure via uniform interval width

To enclose `det M` of a real 3x3 matrix whose entries lie in known rational
intervals (e.g. Bessel-Toeplitz `B(k)_{ij} = I_{|i-j-k|}(beta0/3)` over many
shifts k), do NOT `decide`/`native_decide` each k.

**Membership:** build `detI e` as the `Matrix.det_fin_three` polynomial in
RatInterval `.add/.sub/.mul`; the assembled `add_contains/sub_contains/
mul_contains` term is *syntactically* the det polynomial (`a-b-c+d+e-f` parses
identically to the nested ops), so `rw [Matrix.det_fin_three]; exact <term>`
closes `(detI e).contains M.det`.

**Width (the key trick):** prove a UNIFORM bound `width(detI e) <= 18*U^2*E`
where every entry has `0 <= lo`, `hi <= U`, `width <= E`. Needs RatInterval
lemmas: `mul_lo_nonneg`, `mul_hi_le` (`(I.mul J).hi <= I.hi*J.hi`),
`mul_lo_ge` (`I.lo*J.lo <= (I.mul J).lo`), `mul_width_le`
(`<= I.hi*J.width + J.hi*I.width`), then `triple_width_le` (`<= 3 U^2 E`), then
6 terms via `simp only [detI, sub_width, add_width]; linarith [b1..b6]`.

**Why:** `decide` is dead here — Nat.gcd in ℚ normalization is not
kernel-reducible, so per-k kernel evaluation hangs. The uniform algebraic bound
sidesteps all kernel arithmetic; only `norm_num` on the final concrete
`18*42^2*(1/10^14) < 2/10^9` is needed. `#eval decide(...)` still works (compiled,
GMP gcd) for illustration but adds no axioms.

**How to apply:** reuse for any fixed-size interval-matrix determinant where the
same magnitude/width bound holds across a family; keep entries pinned at a
rational point (cast bridge `(q:ℝ)/3 = ((q/3:ℚ):ℝ)` via `push_cast; ring`) so the
series enclosure (`besselIn_beta0_enclosure`) applies. Result is trio-only.

Gotcha: `Nat.one_le_factorial` does NOT exist in mathlib v4.12.0; use
`Nat.one_le_iff_ne_zero.mpr (Nat.factorial_ne_zero n)` (cast) for `1 <= n!`.
