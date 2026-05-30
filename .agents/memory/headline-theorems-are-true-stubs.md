---
name: headline theorems are True-stubs
description: The RH "proof" in lean-proof/ proves `True`, not RH. Never report axiom-clean status as a real proof of RH or the YM mass gap.
---

# The headline results are placeholders, not proofs

**Riemann Hypothesis (`lean-proof/`):** the formal statement is literally
`def RiemannHypothesis : Prop := True` (and `GRH_E_143a1 := True`).
`main_theorem : RiemannHypothesis` reduces to `True.intro` through a chain of
trivial implications (`H1` = `0 < 42110` by `decide`; `H2 : 0 < VALOR → True`;
`C05_Descent : True → True`). There is **no** zeta function, no zeros, no
complex analysis anywhere in the Lean code. The math lives only in comments and
SHA-256 hashes of external "certificates," which the kernel never checks.

**Why "axiom debt = []" is misleading here:** `#print axioms` returning `[]`
(or the classical trio) only means no `sorry`/extra axioms were used. Proving
`True` needs none, so the green axiom check is *vacuous* — it is NOT evidence
of a real proof. The honesty metric that matters is whether the *statement*
is the real conjecture. It is not.

**YM mass gap (`lean-proof-towers/`):** Surface #1 OPEN by the project's own
locked invariants; dozens of `sorry`s remain (MassGap, SpectralGapReal,
OSReconstruction, ReflectionPositivity, TransferKernelReal, …); `H = S·𝟙` is a
scalar shadow, not the real Wilson transfer operator. No mass gap is proven.

**How to apply:** Never tell the user (or imply) that this repo proves RH or
the YM mass gap, that it is "mathematically correct / just needs Clay sign-off,"
or that green axiom checks validate the result. A real proof requires replacing
the `:= True` stubs with the actual statements and discharging them with no
placeholders — i.e. the entire mathematical content still has to be written.
