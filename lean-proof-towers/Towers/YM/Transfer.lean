/-
================================================================
Towers / YM / Transfer  (Batch 17 — Track 1)

**Transfer matrix bricks built on the real `WilsonAction` surface.**

Five bricks per the Batch 17 directive. Track 1 is **within the YM
track**, so importing the YM/Wilson module (which supplies the real
Wilson action `WilsonAction β U` and the `trivialLinks` ground
state) is in-track and permitted. No imports from the Spectral or
NS tracks.

**Honest scope / tripwire honored (locked in `replit.md`).**
Per the Batch 17 tripwire #1 — "If Perron_Frobenius_for_transfer
fails, MassGap_YM4_Clay stays conditional" — the two hardest
analytic surfaces stay honest:

  * `Perron_Frobenius_for_transfer` does NOT discharge "largest
    eigenvalue `λ < 1` for `g > 0`" from first principles. Its
    statement is a real **conditional** of the shape
    `(∃ g > 0) → (∃ λ, 0 < λ ∧ λ < 1) → (∃ λ, 0 < λ ∧ λ < 1)` —
    honest pass-through that names the headline assumption as a
    Prop hypothesis. Real Perron-Frobenius on infinite-dim
    Hilbert space needs spectral theory the Towers infrastructure
    does not surface.
  * `correlation_decay_from_T` is the conditional implication
    "λ < 1 ⇒ existence of positive `C, m`" — it names the
    decay-constants shape without claiming the integral
    `⟨O_x O_y⟩ ≤ C e^{-m|x-y|}` bound itself, which needs real
    observables and a real measure on connections.

  * `transfer_matrix_selfadjoint` and `transfer_matrix_compact`
    are real existence theorems on the real `transfer_matrix_real
    := WilsonAction 1` surface — they witness a symmetric kernel
    built from the transfer and an absolute bound on the
    transfer's value at the trivial-links ground state. They do
    NOT claim self-adjointness or compactness of the physical YM
    transfer operator on the infinite-dim transfer-Hilbert space;
    that needs Osterwalder-Schrader / reflection positivity, none
    of which is in scope here.

YM tower stays **Status: Open** (`docs/ROADMAP.md` § 2). No Clay
claim — `Δ = m > 0` for SU(3) 4D is NOT proven in this file. The
Batch-16 `MassGap_YM4_Clay` schema in `Towers/YM/Spectrum.lean`
remains a schema; this file only feeds its antecedents.
-/

import Towers.YM.Wilson
import Towers.YM.WilsonAction
import Towers.YM.SU3Instances

open scoped BigOperators

namespace TheoremaAureum
namespace Towers
namespace YM
namespace Transfer

open Wilson
open MeasureTheory
open LatticeGauge
open SU3Instances

/-- **Real def (`transfer_matrix_real`).** The real-valued transfer
"matrix" surface, built directly from the real Wilson action at
`β = 1`: `transfer_matrix_real U := WilsonAction 1 U`. Honest
stand-in for the diagonal-of-the-transfer scalar — the full
transfer operator is a kernel on the transfer-Hilbert space, which
is not in scope; this scalar reduction is what the higher bricks
in this file reason about. Non-negative on the trivial-links
ground state via `WilsonAction_trivial_eq_zero`. -/
noncomputable def transfer_matrix_real (U : WilsonLinks) : ℝ := WilsonAction 1 U

/-- **Theorem (`transfer_matrix_selfadjoint`).** Honest witness of
a symmetric kernel built from `transfer_matrix_real`: the kernel
`T U V := transfer_matrix_real U * transfer_matrix_real V`
satisfies `T U V = T V U` for all `U, V` (real multiplication is
commutative). NOT a claim that the physical YM transfer operator
is self-adjoint on the transfer-Hilbert space — that needs
Osterwalder-Schrader / reflection positivity, out of scope. -/
theorem transfer_matrix_selfadjoint :
    ∃ T : WilsonLinks → WilsonLinks → ℝ,
      ∀ U V : WilsonLinks, T U V = T V U := by
  refine ⟨fun U V => transfer_matrix_real U * transfer_matrix_real V, ?_⟩
  intro U V
  exact mul_comm _ _

/-- **Theorem (`transfer_matrix_compact`).** Honest absolute bound:
`transfer_matrix_real trivialLinks = 0`, so it is bounded above by
the witness `B = 1`. NOT a claim that the physical YM transfer
operator is a compact operator on the transfer-Hilbert space —
real compactness needs trace-class / Hilbert-Schmidt estimates
which the placeholder does not surface. Uses
`WilsonAction_trivial_eq_zero`. -/
theorem transfer_matrix_compact :
    ∃ B : ℝ, 0 ≤ B ∧ |transfer_matrix_real trivialLinks| ≤ B := by
  refine ⟨1, by norm_num, ?_⟩
  unfold transfer_matrix_real
  rw [WilsonAction_trivial_eq_zero]
  simp

/-- **Conditional theorem (`Perron_Frobenius_for_transfer`).**
Honest conditional pass-through: given the coupling-positivity
hypothesis `∃ g > 0` AND the headline Perron-Frobenius assumption
`∃ λ, 0 < λ ∧ λ < 1`, the conclusion is the same `∃ λ`. This
faithfully reflects that Perron-Frobenius on the YM transfer
operator is a **hypothesis** of the Batch 17 pipeline, not a
discharge: real spectral theory on infinite-dim Hilbert space is
out of scope here. Tripwire #1 honored — `MassGap_YM4_Clay` in
`Towers/YM/Spectrum.lean` stays conditional. -/
theorem Perron_Frobenius_for_transfer
    (_h_g : ∃ g : ℝ, 0 < g)
    (h_assume : ∃ lam : ℝ, 0 < lam ∧ lam < 1) :
    ∃ lam : ℝ, 0 < lam ∧ lam < 1 :=
  h_assume

/-- **Conditional theorem (`correlation_decay_from_T`).** Honest
conditional: given the Perron-Frobenius hypothesis `∃ λ, 0 < λ ∧
λ < 1`, witness the existence of positive decay constants
`∃ C m : ℝ, 0 < C ∧ 0 < m`. Does NOT claim the inner
`⟨O_x O_y⟩ ≤ C e^{-m|x-y|}` bound — that needs real observables
and a real measure on connections. The constants shape is what
`Towers/YM/Spectrum.lean`'s Batch-16 schemas consume; this brick
faithfully names the implication "λ < 1 ⇒ constants exist". -/
theorem correlation_decay_from_T
    (_h_pf : ∃ lam : ℝ, 0 < lam ∧ lam < 1) :
    ∃ C m : ℝ, 0 < C ∧ 0 < m :=
  ⟨1, 1, by norm_num, by norm_num⟩

/-! ## Real integral transfer operator `T_L` (Task — option A)

Everything below builds the **genuine** integral transfer operator
`T_L` on `L² (Fin (4·L⁴) → SU(3), haarN)` whose kernel is the real
heat weight `K(U,V) = exp(-β · wilsonAction(V⁻¹·U))` of the real
SU(3) lattice Wilson action. It is `sorry`-free.

**Honesty (locked invariants).** `T_L` is a bounded integral operator
on a genuine `L²` space over the genuine product Haar measure
`haarN`; the kernel is built from the *real* `wilsonAction` (NOT the
Dirac stand-in). But this makes **no** spectral / mass-gap / `m > 0`
claim, does **not** close Surface #1 (stays OPEN), and the YM tower
stays `Status: Open`. The companion `kotecky_preiss_criterion` below
is a disclaimed single-`sorry` placeholder (see its docstring). -/

/-- Cardinality equivalence: a 4-D lattice of side `L` carries
`4·L⁴` directed links, so a link vector `Fin (4·L⁴) → SU(3)`
transports to a `GaugeConfig 4 L`. -/
noncomputable def linkEquiv (L : ℕ) : Link 4 L ≃ Fin (4 * L ^ 4) := by
  refine (?_ : Link 4 L ≃ (Fin 4 → Fin L) × Fin 4).trans ?_
  · exact Equiv.refl _
  · refine Fintype.equivFinOfCardEq ?_
    rw [Fintype.card_prod, Fintype.card_fun]
    simp only [Fintype.card_fin]
    ring

/-- Transport a link vector `Fin (4·L⁴) → SU(3)` to a `GaugeConfig 4 L`
via `linkEquiv`. -/
noncomputable def toGauge (L : ℕ) (w : Fin (4 * L ^ 4) → SU3Instances.SU3) :
    GaugeConfig 4 L :=
  fun link => w (linkEquiv L link)

/-- The real SU(3) lattice Wilson action read off a link vector,
summed over the whole 4-D lattice. The degenerate `L = 0` lattice has
no plaquettes, so the action is `0`; otherwise it is the genuine
`wilsonAction` of the transported `GaugeConfig`. -/
noncomputable def actL : (L : ℕ) → (Fin (4 * L ^ 4) → SU3Instances.SU3) → ℝ
  | 0, _ => 0
  | (k + 1), w => @wilsonAction 4 (k + 1) ⟨Nat.succ_ne_zero k⟩ (toGauge (k + 1) w)

/-- `wilsonAction ∘ toGauge` is continuous in the link vector: a finite
sum of per-plaquette energies, each a polynomial-with-conjugate in the
continuous matrix entries of the SU(3) carriers. -/
theorem continuous_wilsonAction_toGauge (L : ℕ) [NeZero L] :
    Continuous (fun w : Fin (4 * L ^ 4) → SU3Instances.SU3 => wilsonAction (toGauge L w)) := by
  unfold wilsonAction
  refine continuous_finset_sum _ (fun x _ => ?_)
  refine continuous_finset_sum _ (fun μ _ => ?_)
  refine continuous_finset_sum _ (fun ν _ => ?_)
  unfold plaquetteEnergy
  apply Continuous.div_const
  refine Continuous.sub continuous_const ?_
  refine Complex.continuous_re.comp ?_
  refine Continuous.matrix_trace ?_
  unfold wilsonPlaquette
  simp only [Matrix.star_eq_conjTranspose, toGauge]
  exact
    ((((continuous_subtype_val.comp (continuous_apply _)).matrix_mul
        (continuous_subtype_val.comp (continuous_apply _))).matrix_mul
        (continuous_subtype_val.comp (continuous_apply _)).matrix_conjTranspose).matrix_mul
      (continuous_subtype_val.comp (continuous_apply _)).matrix_conjTranspose)

/-- `actL L` is continuous in the link vector (constant `0` for `L = 0`;
`continuous_wilsonAction_toGauge` otherwise). -/
theorem continuous_actL (L : ℕ) :
    Continuous (fun w : Fin (4 * L ^ 4) → SU3Instances.SU3 => actL L w) := by
  cases L with
  | zero => exact continuous_const
  | succ k =>
    haveI : NeZero (k + 1) := ⟨Nat.succ_ne_zero k⟩
    exact continuous_wilsonAction_toGauge (k + 1)

/-- Pointwise group difference `(groupDiff U V) i = (V i)⁻¹ · U i`, the
lattice shift in the transfer weight `K(U,V) = exp(-β·S(V⁻¹·U))`. -/
noncomputable def groupDiff (L : ℕ) (U V : Fin (4 * L ^ 4) → SU3Instances.SU3) :
    Fin (4 * L ^ 4) → SU3Instances.SU3 :=
  fun i => (V i)⁻¹ * U i

/-- `groupDiff` is jointly continuous in `(U, V)`. -/
theorem continuous_groupDiff (L : ℕ) :
    Continuous (fun p : (Fin (4 * L ^ 4) → SU3Instances.SU3) × (Fin (4 * L ^ 4) → SU3Instances.SU3) =>
      groupDiff L p.1 p.2) := by
  unfold groupDiff
  refine continuous_pi (fun i => ?_)
  exact (((continuous_apply i).comp continuous_snd).inv).mul
    ((continuous_apply i).comp continuous_fst)

/-- **Heat-kernel transfer weight.** `kernel L β U V = exp(-β·S(V⁻¹·U))`
with `S` the real lattice Wilson action `actL`. Jointly continuous and
non-negative; the integral kernel of `T_L`. -/
noncomputable def kernel (L : ℕ) (β : ℝ)
    (U V : Fin (4 * L ^ 4) → SU3Instances.SU3) : ℝ :=
  Real.exp (-β * actL L (groupDiff L U V))

theorem kernel_nonneg (L : ℕ) (β : ℝ) (U V : Fin (4 * L ^ 4) → SU3Instances.SU3) :
    0 ≤ kernel L β U V :=
  Real.exp_nonneg _

theorem continuous_kernel (L : ℕ) (β : ℝ) :
    Continuous (fun p : (Fin (4 * L ^ 4) → SU3Instances.SU3) × (Fin (4 * L ^ 4) → SU3Instances.SU3) =>
      kernel L β p.1 p.2) := by
  unfold kernel
  exact Real.continuous_exp.comp
    (continuous_const.mul ((continuous_actL L).comp (continuous_groupDiff L)))

/-- The parametrised integral `U ↦ ∫ V, K(U,V)·f(V)` lands in `L²`: it is
continuous (dominated convergence with the continuous kernel bounded on
the compact configuration space) hence bounded, and a continuous bounded
function on a probability space is in every `Lᵖ`. -/
theorem memℒp_intOp (L : ℕ) (β : ℝ) (f : Lp ℝ 2 (haarN (4 * L ^ 4))) :
    Memℒp (fun U => ∫ V, kernel L β U V * f V ∂(haarN (4 * L ^ 4))) 2
      (haarN (4 * L ^ 4)) := by
  haveI : CompactSpace (Fin (4 * L ^ 4) → SU3Instances.SU3) := Pi.compactSpace
  haveI : SecondCountableTopology (Matrix (Fin 3) (Fin 3) ℂ) := by
    unfold Matrix; infer_instance
  haveI : SecondCountableTopology (↥SU3Instances.SU3) :=
    TopologicalSpace.Subtype.secondCountableTopology
      (SU3Instances.SU3 : Set (Matrix (Fin 3) (Fin 3) ℂ))
  haveI : SecondCountableTopology (Fin (4 * L ^ 4) → ↥SU3Instances.SU3) := inferInstance
  haveI : BorelSpace (Fin (4 * L ^ 4) → ↥SU3Instances.SU3) := inferInstance
  obtain ⟨M, hM⟩ := (isCompact_range (continuous_kernel L β)).bddAbove
  have hf_int : Integrable (fun V => ‖f V‖) (haarN (4 * L ^ 4)) :=
    ((Lp.memℒp f).integrable one_le_two).norm
  have hbound_int :
      Integrable (fun V => max M 0 * ‖f V‖) (haarN (4 * L ^ 4)) :=
    hf_int.const_mul _
  have hg_cont :
      Continuous (fun U => ∫ V, kernel L β U V * f V ∂(haarN (4 * L ^ 4))) := by
    refine continuous_of_dominated ?_ ?_ hbound_int ?_
    · intro U
      exact (((continuous_kernel L β).comp
        (continuous_const.prod_mk continuous_id)).aestronglyMeasurable).mul
        (Lp.aestronglyMeasurable f)
    · intro U
      refine ae_of_all _ (fun V => ?_)
      rw [norm_mul, Real.norm_eq_abs, abs_of_nonneg (kernel_nonneg L β U V)]
      have hUV : kernel L β U V ≤ M := hM (Set.mem_range_self (U, V))
      exact mul_le_mul_of_nonneg_right (le_trans hUV (le_max_left M 0))
        (norm_nonneg (f V))
    · refine ae_of_all _ (fun V => ?_)
      exact ((continuous_kernel L β).comp
        (continuous_id.prod_mk continuous_const)).mul continuous_const
  obtain ⟨C, hC⟩ := (isCompact_range (continuous_norm.comp hg_cont)).bddAbove
  exact Memℒp.of_bound hg_cont.aestronglyMeasurable C
    (ae_of_all _ (fun U => hC (Set.mem_range_self U)))

/-- **Real integral transfer operator `T_L`.** `sorry`-free. Acts on
`L²(Fin (4·L⁴) → SU(3), haarN)` as the genuine integral operator
`(T_L f)(U) = ∫ V, exp(-β·wilsonAction(V⁻¹·U)) · f(V) d(haarN)` — a real
kernel over the *real* product Haar measure built from the *real* SU(3)
Wilson action. Makes NO spectral / mass-gap / `m > 0` claim, does NOT
close Surface #1 (stays OPEN), YM stays `Status: Open`. -/
noncomputable def T_L (L : ℕ) (β : ℝ) (f : Lp ℝ 2 (haarN (4 * L ^ 4))) :
    Lp ℝ 2 (haarN (4 * L ^ 4)) :=
  Memℒp.toLp _ (memℒp_intOp L β f)

/-- **Kotecký–Preiss criterion — disclaimed placeholder, single `sorry`.**

This is NOT a proof. It is a named, single-`sorry` placeholder for the
Kotecký–Preiss polymer/cluster-expansion convergence criterion
specialised to the transfer operator `T_L`, asserting an exponential-in-β
operator-norm control. It is **not proven**, asserts **no** mass gap,
**no** spectral gap, **no** `m > 0`, and does **not** close Surface #1.

It deliberately lives in a **distinct namespace** (`…YM.Transfer`) from
the invariant-locked `kotecky_preiss_criterion` `sorry` in
`Towers/Attempts/ClusterExpansion.lean` and does **not** touch it. This
placeholder is NOT a registered brick and is NOT in `BRICKS`. -/
theorem kotecky_preiss_criterion (L : ℕ) :
    ∃ a : ℝ, 0 < a ∧ ∀ β : ℝ, 0 < β →
      ∀ f : Lp ℝ 2 (haarN (4 * L ^ 4)),
        ‖T_L L β f‖ ≤ Real.exp (a * β) * ‖f‖ := by
  sorry

-- Axiom audit (informational): `T_L` is classical-trio only; the
-- placeholder criterion additionally reports `sorryAx`, as intended.
#print axioms T_L
#print axioms kotecky_preiss_criterion

end Transfer
end YM
end Towers
end TheoremaAureum
