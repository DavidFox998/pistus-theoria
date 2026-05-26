/-
================================================================
Towers / YM / SU3Basis  (Task #56 Path B, batch 1 of 3)

**The 8 anti-Hermitian Gell-Mann generators `iλ₁ … iλ₈` of su(3),
each proven to lie in `su3_submodule`.**

This file is the foundation for the downstream bricks
`su3_basis_def`, `su3_basis_linearIndependent`, `su3_basis_spans`
(batch 2, via `Basis.ofEquivFun` over a Gell-Mann LinearEquiv to
`Fin 8 → ℝ`), and `instance_inner_product_space_su3_euclidean`
(batch 3, via `InnerProductSpace.Core` on the same basis).

### Why the unnormalised `iλ₈`

Physics uses `λ₈ = (1/√3) · diag(1, 1, -2)`. We use
`gellMann₈ := !![I, 0, 0; 0, 0, 0; 0, 0, -I]` instead — all entries
in `{0, I, -I, 1, -1}`, no `√3`. This is still *a* basis for
`su3_submodule` (the two diagonal generators `gellMann₃`,
`gellMann₈` together span the same 2-dim real subspace of
diag-imaginary-traceless matrices that `λ₃, λ₈` do), so it gives a
valid `Basis (Fin 8) ℝ ↥su3_submodule` downstream. The cost is
that the resulting inner product is not the physics-normalised
`tr(A* B) / 2` — but the downstream IPS brick declares its own
inner product anyway, so nothing depends on this choice.

### Honest scope

`gellMann_k_mem` says: "this explicit 3×3 complex matrix is
anti-Hermitian and traceless." Nothing more. No statement about
Yang-Mills dynamics, the YM Hamiltonian, the mass-gap conjecture,
or any QFT. YM tower status remains **Open**
(`docs/ROADMAP.md` § 2). The bricks here are stepping stones to
giving `↥su3_submodule` the geometric structure (basis + inner
product) that the eventual `YMHamiltonian` schema concretization
will consume — they are NOT themselves a YM result.
================================================================
-/

import Mathlib.Data.Matrix.Notation
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.Algebra.Module.LinearMap.End
import Mathlib.Algebra.Module.Equiv.Basic
import Mathlib.LinearAlgebra.Basis.Defs
import Mathlib.LinearAlgebra.Pi
import Towers.YM.SU3

namespace TheoremaAureum
namespace Towers
namespace YM

open Matrix Complex

/-! ### The 8 Gell-Mann generators in anti-Hermitian form -/

/-- `iλ₁` — off-diagonal real-symmetric times `I` (slots (0,1)/(1,0)). -/
def gellMann₁ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, I, 0;
     I, 0, 0;
     0, 0, 0]

/-- `iλ₂` — off-diagonal real-skew (slots (0,1)/(1,0)). -/
def gellMann₂ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0,  1, 0;
     -1, 0, 0;
     0,  0, 0]

/-- `iλ₃` — diagonal `diag(I, -I, 0)`. -/
def gellMann₃ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![I, 0, 0;
     0, -I, 0;
     0, 0, 0]

/-- `iλ₄` — off-diagonal real-symmetric times `I` (slots (0,2)/(2,0)). -/
def gellMann₄ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 0, I;
     0, 0, 0;
     I, 0, 0]

/-- `iλ₅` — off-diagonal real-skew (slots (0,2)/(2,0)). -/
def gellMann₅ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0,  0, 1;
     0,  0, 0;
     -1, 0, 0]

/-- `iλ₆` — off-diagonal real-symmetric times `I` (slots (1,2)/(2,1)). -/
def gellMann₆ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 0, 0;
     0, 0, I;
     0, I, 0]

/-- `iλ₇` — off-diagonal real-skew (slots (1,2)/(2,1)). -/
def gellMann₇ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![0, 0,  0;
     0, 0,  1;
     0, -1, 0]

/-- `iλ₈` (unnormalised) — diagonal `diag(I, 0, -I)`. -/
def gellMann₈ : Matrix (Fin 3) (Fin 3) ℂ :=
  !![I, 0, 0;
     0, 0, 0;
     0, 0, -I]

/-! ### Membership in `su3_submodule`

    For each generator we have to show:
    (i)  `star A = -A`  (anti-Hermitian: `Aᴴ = -A`)
    (ii) `Matrix.trace A = 0`

    The proof is a uniform tactic block:
      * unpack the iff via `su3_submodule_mem_iff`;
      * for (i), reduce to entry-by-entry equality with
        `ext i j; fin_cases i <;> fin_cases j` and close every case
        with `simp` over the matrix-literal cons/of unfolders and
        `Complex.conj_I`;
      * for (ii), use `Matrix.trace_fin_three` to expand to
        `A 0 0 + A 1 1 + A 2 2`, then simp away.

    `Matrix.star_apply` in mathlib v4.12.0 reduces
    `(star A) i j = star (A j i)`, which together with
    `Complex.conj_I : star I = -I` and the cons-of-cons unfolders
    closes every case.

    Axiom footprint target for each: subset of mathlib's classical
    trio `{propext, Classical.choice, Quot.sound}`. No new axioms.
-/

/-- Internal: the entry-by-entry `star = neg` tactic for an
    explicit 3×3 `!![...]` literal of `Matrix (Fin 3) (Fin 3) ℂ`.
    Takes the unfolder for the specific generator. -/
local macro "gellMann_antiHermitian_tac" name:ident : tactic =>
  `(tactic|
    (ext i j
     fin_cases i <;> fin_cases j <;>
       (simp [$name:ident, Matrix.star_apply, Matrix.neg_apply,
              Matrix.of_apply, Matrix.cons_val', Matrix.cons_val_zero,
              Matrix.cons_val_one, Matrix.head_cons, Matrix.head_fin_const,
              Matrix.empty_val', Matrix.cons_val_fin_one,
              Matrix.vecHead, Matrix.vecTail,
              Complex.conj_I, star_neg, star_one, star_zero,
              neg_neg, neg_zero] <;> rfl)))

/-- Internal: the trace-zero tactic for an explicit 3×3 `!![...]`
    literal. Takes the unfolder for the specific generator. -/
local macro "gellMann_traceless_tac" name:ident : tactic =>
  `(tactic|
    (simp [$name:ident, Matrix.trace_fin_three, Matrix.of_apply,
           Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons,
           Matrix.head_fin_const, Matrix.empty_val', Matrix.cons_val_fin_one,
           Matrix.vecHead, Matrix.vecTail] <;> rfl))

theorem gellMann₁_mem : gellMann₁ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₁
  · gellMann_traceless_tac gellMann₁

theorem gellMann₂_mem : gellMann₂ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₂
  · gellMann_traceless_tac gellMann₂

theorem gellMann₃_mem : gellMann₃ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₃
  · gellMann_traceless_tac gellMann₃

theorem gellMann₄_mem : gellMann₄ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₄
  · gellMann_traceless_tac gellMann₄

theorem gellMann₅_mem : gellMann₅ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₅
  · gellMann_traceless_tac gellMann₅

theorem gellMann₆_mem : gellMann₆ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₆
  · gellMann_traceless_tac gellMann₆

theorem gellMann₇_mem : gellMann₇ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₇
  · gellMann_traceless_tac gellMann₇

theorem gellMann₈_mem : gellMann₈ ∈ su3_submodule := by
  refine (su3_submodule_mem_iff _).mpr ⟨?_, ?_⟩
  · gellMann_antiHermitian_tac gellMann₈
  · gellMann_traceless_tac gellMann₈

/-! ## Path B batch 2/3 — deferred

The downstream bricks `su3_basis_def`, `su3_basis_linearIndependent`,
`su3_basis_spans` (basis via `Basis.ofEquivFun`), and
`instance_inner_product_space_su3_euclidean` (InnerProductSpace.Core)
were prototyped in this session but exceeded mathlib v4.12.0's
default 200000-heartbeat budget on the `simp + linarith` finisher
over the 8-term `∑ cᵢ • gellMannᵢ` reconstruction. They are deferred
to a follow-up task. The 8 `gellMann_k_mem` bricks above stand on
their own — they are the explicit anti-Hermitian + traceless
witnesses, and they ship classical-trio-clean.
-/

end YM
end Towers
end TheoremaAureum
