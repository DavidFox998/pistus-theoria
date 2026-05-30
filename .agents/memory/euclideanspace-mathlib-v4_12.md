---
name: EuclideanSpace volume + component access (mathlib v4.12.0)
description: How to get a measure on EuclideanSpace, construct elements, and prove linear-subspace closure without fragile component indexing.
---

# EuclideanSpace gotchas (mathlib v4.12.0)

Context: `Towers/NS/FunctionSpaces.lean` models Hˢ as weighted `L²(ℝ³; ℂ³)`
with `Freq = EuclideanSpace ℝ (Fin 3)`, `Val = EuclideanSpace ℂ (Fin 3)`.

## Volume / MeasureSpace import
- `EuclideanSpace ℝ (Fin n)` HAS a canonical `volume` (`MeasureSpace`), but the
  module `Mathlib.MeasureTheory.Measure.Lebesgue.EuclideanSpace` does **not
  exist** in v4.12.0.
- Import `Mathlib.MeasureTheory.Measure.Haar.InnerProductSpace` instead — that
  is the file that surfaces the EuclideanSpace `volume` instance and
  `EuclideanSpace.volume_preserving_measurableEquiv`.
- **Why:** the instance is not declared with a grep-able `instance : MeasureSpace
  (EuclideanSpace …)` line; it comes through the finite-dim inner-product Haar
  construction, so search by *usage* (`volume_preserving_measurableEquiv`), not
  by the instance signature.

## Constructing an element from components
- `EuclideanSpace 𝕜 ι = PiLp 2 _ = WithLp 2 (ι → 𝕜)`, a type synonym — it is
  NOT defeq-transparent to the raw Pi type for instance/`simp` purposes.
- Build an element from a coordinate function with
  `(WithLp.equiv 2 (ι → 𝕜)).symm (fun i => …)` (mathlib's own idiom). The
  `abbrev EuclideanSpace.equiv` takes `𝕜 ι` *implicitly*, so positional
  `EuclideanSpace.equiv (Fin 3) ℂ` fails — prefer `WithLp.equiv`.

## Proving linear-subspace closure (don't index components)
- `Pi.add_apply` / `Pi.smul_apply` / `Pi.zero_apply` do **fire** on the outer
  `Lp` coe-fn applied at a point — `(⇑f + ⇑g) ξ = ⇑f ξ + ⇑g ξ` — because that
  layer is a genuine `Freq → Val` Pi function.
- They do **NOT** fire one level deeper on `(a + b) i` where `a b : EuclideanSpace`
  (that add is `WithLp`, not raw `Pi`), so component-sum proofs like
  `∑ i, ξ i * (a+b) i` stall.
- **Fix / idiom:** state the linear condition through the inner product, e.g.
  `IsDivFree f := ∀ᵐ ξ, ⟪toVal ξ, f ξ⟫_ℂ = 0`, then close `0/+/•` membership
  with `inner_zero_right`, `inner_add_right`, `inner_smul_right` (linear in the
  2nd slot, no conj). This avoids component indexing entirely.
- Honesty note for the divergence pairing: with `toVal ξ` having real
  (conjugation-fixed) components, `⟪toVal ξ, û⟫_ℂ = ∑ i, ξ_i · û_i = ξ · û` — the
  Hermitian inner product literally equals the bilinear divergence, so the
  inner-product phrasing is faithful, not a weakening.

## Proving a matrix Frobenius/HS distance is a genuine metric
- To show `√(∑ ‖M i j‖²)` separates points + satisfies the triangle inequality,
  do NOT grind Minkowski by hand. Embed the matrix into `EuclideanSpace 𝕜
  (ι × κ)` via `toEuc M := (WithLp.equiv 2 _).symm (fun ij => M ij.1 ij.2)` and
  prove `√(hsNormSq M) = ‖toEuc M‖` (`EuclideanSpace.norm_eq` +
  `Fintype.sum_prod_type` + `toEuc_apply` which is `rfl`).
- Then triangle = ambient `dist_triangle` (rewrite norms to `dist` via
  `← dist_eq_norm`); separation = `norm_eq_zero` + a coordinatewise
  `toEuc_eq_zero` (`congrArg (·  (i,j))` then `simpa [toEuc_apply]`).
- For `hsNormSq M = (tr(Mᴴ M)).re = ∑ ‖M i j‖²`: unfold `Matrix.trace`, then
  `simp only [Matrix.diag_apply, Matrix.mul_apply, Matrix.star_apply,
  Complex.re_sum, hz]` where `hz z : (star z * z).re = ‖z‖²`, finish with
  `Finset.sum_comm` (the `i,k` index order from the trace is swapped vs `i,j`).
  `Complex.re_sum` (in `Data/Complex/BigOperators`) pushes `.re` through a sum.
- `hz`: `star z * z = ↑(normSq z)` via `rw [Complex.star_def,
  Complex.normSq_eq_conj_mul_self]` (use `star_def` to bridge `star`↔`conj`,
  per the star-vs-starRingEnd defeq gotcha), then `Complex.ofReal_re`,
  `Complex.normSq_eq_abs`, `Complex.norm_eq_abs`.
