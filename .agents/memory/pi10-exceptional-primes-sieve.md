---
name: pi/10 exceptional-primes sieve (Diophantine)
description: How to rigorously enumerate ALL exceptional primes of alpha=pi/10 (||p*pi/10||<1/p) without false positives, and the honest result.
---

# Exceptional primes of alpha = pi/10  (||p*pi/10|| < 1/p)

Task surface separate from the Lean tower: enumerate every prime p with
`||p*(pi/10)|| < 1/p` up to a bound (equivalently alpha0 = 299 + pi/10, since
299*p is integral). Tool: `scripts/enumerate_pi10_exceptional.py`.

**The key mathematical move (don't brute-force / don't guess):**
- Every CONVERGENT denominator q_n of alpha is automatically exceptional
  (`||q_n*alpha|| < 1/q_{n+1} < 1/q_n`). By Legendre / best-approximation
  theory, any q with `||q*alpha|| < 1/q` is a convergent OR an upper
  semiconvergent. So enumerate the exact integer continued fraction of pi/10
  and test convergents + semiconvergents `q = m*q_p + q_pp` (m=1..a_k) only —
  NOT random integers. This is why naive "guess and test" reports are riddled
  with false positives.
- Do everything in exact integers: pi via integer Chudnovsky to D≈2*bound+300
  digits, alpha = Aa/Ba (Aa=floor(pi*10^D), Ba=10^(D+1)); residue
  e_k = q_k*Aa - p_k*Ba; `nn = min(rr, Ba-rr)` = Ba*||q*alpha||; test
  `q*nn < Ba`. Primality: trial-divide then BPSW (sympy.isprime).
- **Decision certificate** (makes completeness rigorous, not just "probably"):
  the pi-truncation perturbs the scaled test value by < q^2/Ba, so a decision
  can only flip if `|Ba - q*nn| <= q^2`. Track the min of `|Ba - q*nn|` over ALL
  candidates and assert it exceeds q_max^2 = 10^(2*bound). At bound 10^4000 the
  min margin was ~10^8295 vs threshold 10^8000 — huge, so the rational test
  provably equals the true pi/10 test over the whole range.

**Honest result:** up to 10^4000 there are exactly **20** exceptional primes:
2, 3, 19, 191, then 16 larger ones (13 → 3548 digits). Cross-validated: the
sieve's results <=10^6 equal the independent brute force {2,3,19,191}. There is
NO clean criterion that yields exactly 14: `||p*pi/10||<1/p` gives 20, and the
stricter Legendre `1/(2p)` would DROP 2,19,191 (all semiconvergents) leaving 8.

**Three distinct "14" lists — do not conflate them:**
1. **v1.3–v1.5 (BUGGY)** tested CF DENOMINATORS k_n instead of numerators h_n →
   "desert holds" artifact + a composite tail. THIS is the bogus list hardcoded
   as `S_14` in `Towers/Hodge/Defs.lean` / `data/exceptional_primes.csv`
   (#8–#14 composite AND non-exceptional). `BostViolations/Compute.lean`'s
   `C_rat≈842.42` is computed over it ⟹ also meaningless.
2. **v1.6 (CORRECT but INCOMPLETE)** tested numerators h_n → 14 GENUINE primes
   = exactly a SUBSET of the canonical 20. It finds 14 not 20 only because it
   searches PRINCIPAL convergents (Legendre completeness needs the stricter
   1/(2p)) and its 4010-digit pi tops out ~10^2005 (flags h4610 itself). So 14
   is "method+precision limited," NOT wrong and NOT canonical.
3. **A separately circulated list** `2,3,19,191,291,317,607,...,10651` — a
   `299+pi` (NOT pi/10) computation, mislabeled, with arithmetic that doesn't
   close; 291=3*97 composite; only 2,3,19,191 actually pass. See "Two traps".

The CANONICAL machine-verified set is the 20 in
`data/pi10_exceptional_primes.txt` (with completeness cert). Trust the data
file, not Defs.lean's S_14. Defs.lean is NOT a brick ⟹ data-honesty defect, not
an axiom-lock breach. Honest draft audit reconciling all this:
`docs/exceptional-prime-gap-audit-draft.md` (has a re-runnable repro script).

**Two traps that keep recurring:**
- **pi vs pi/10.** alpha0 = 299 + pi/10 = **299.31415927**; the decimal
  **302.14159265** is 299 + pi. Since 299p is integral, `||p*(299+t)||=||p*t||`,
  so 299+pi/10 ⟺ pi/10 (ONE test). Testing 299+pi instead gives a DIFFERENT set
  ({2,7,113} below 11000, vs {2,3,19,191} for pi/10).
- **"float64 false positives" is impossible here.** Low precision returns
  `0.0` (meaningless garbage), NEVER a false pass; float64's ~15 digits can't
  even represent a 95- or 3548-digit prime. #10 needs pi to >=250 digits, #20
  >=7200, to register; once sufficient the value is stable across dps. The 6
  extras beyond v1.6's 14 are VERIFIED PRIME, not rounding artifacts.

**Honesty caveat to always state:** BPSW has no known counterexample but is NOT
a formal primality proof for the 3000+ digit entries (ECPP/Primo certs would be
needed for that, impractical here).

**Desert structure (the headline geometry):** first 4 primes (2,3,19,191) are
immediate; then a boundary phase shift to p5≈3.99e12 (first desert width =
3,993,746,143,442 integers, ~1.4e11 ordinary primes crossed). Consecutive gap
ratios grow super-exponentially (p5/p4≈2.1e10 … p19/p18≈4.8e1039); primes
crossed per desert reach ~1.6e3543 before p20. Structural cause: exceptional ⟺
CF convergent/semiconvergent denominator ⟹ log q_n grows ≥ linearly ⟹ deserts
diverge. Written up as the "Desert Structure" + "Methods" sections of
`paper/theorema-aureum-143.tex`.
