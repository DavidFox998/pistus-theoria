---
name: Explicit 4x4 determinant in mathlib v4.12.0
description: How to compute det of a concrete !![...] matrix when there is no det_fin_four, and the charpoly->eigenvalue bridge.
---

# Computing det of an explicit `!![...]` matrix (mathlib v4.12.0)

mathlib v4.12.0 has **no `det_fin_four`** and no charpoly↔eigenvalue lemma. To
machine-check the determinant of a concrete `Matrix (Fin 4) (Fin 4) ℝ` you must
unfold Laplace cofactor expansion by hand.

**The working tactic** (found via scratch testing, then reused in
`Towers/YM/Wall263_CoxeterSpectral.lean` and `Towers/YM/MassGap.lean` ~1135–1197):
use **plain `simp`** (NOT `simp only`) with this set, then `ring`:

```
simp [Matrix.det_succ_row_zero, Fin.sum_univ_succ, Matrix.submatrix_apply,
      Matrix.cons_val', Matrix.cons_val_zero, Matrix.cons_val_one,
      Matrix.cons_val_succ, Matrix.head_cons, Matrix.head_fin_const,
      Matrix.empty_val', Matrix.cons_val_fin_one, Matrix.of_apply,
      Fin.succAbove, Fin.lt_def]
ring
```

**Why each matters / the footgun:**
- `simp only` with the same lemma list **does not close it** — leftover
  `Fin.succAbove 1 2` style terms remain. Plain `simp` (full default set on top
  of these) reduces them.
- `Fin.succAbove, Fin.lt_def` are the crucial additions that evaluate the
  `Fin.succAbove` index juggling produced by repeated `det_succ_row_zero`.

**Eigenvalue bridge:** to get `φ ∉ spectrum ℝ B` from `det(φ•I − B) ≠ 0`, use
`spectrum.not_mem_iff` + `Matrix.isUnit_iff_isUnit_det` (invertible ⟺ unit det).
This is the honest, non-vacuous route — it does NOT assert non-membership from a
polynomial-only surrogate.

**Doc-comment gotcha encountered here:** the literal substring `-/` inside a
`/-! ... -/` docstring (e.g. writing `120-/600-cell`) **closes the comment early**
and produces baffling "unexpected token; expected command" errors far below.
Write `120-cell / 600-cell` instead.
