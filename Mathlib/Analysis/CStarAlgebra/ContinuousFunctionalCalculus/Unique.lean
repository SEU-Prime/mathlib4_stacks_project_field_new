/-
Copyright (c) 2024 Jireh Loreaux. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Jireh Loreaux
-/
import Mathlib.Analysis.CStarAlgebra.ContinuousFunctionalCalculus.NonUnital
import Mathlib.Topology.ContinuousMap.StoneWeierstrass
import Mathlib.Analysis.InnerProductSpace.Basic

/-!
# Uniqueness of the continuous functional calculus

Let `s : Set 𝕜` be compact where `𝕜` is either `ℝ` or `ℂ`. By the Stone-Weierstrass theorem, the
(star) subalgebra generated by polynomial functions on `s` is dense in `C(s, 𝕜)`. Moreover, this
star subalgebra is generated by `X : 𝕜[X]` (i.e., `ContinuousMap.restrict s (.id 𝕜)`) alone.
Consequently, any continuous star `𝕜`-algebra homomorphism with domain `C(s, 𝕜)`, is uniquely
determined by its value on `X : 𝕜[X]`.

The same is true for `𝕜 := ℝ≥0`, so long as the algebra `A` is an `ℝ`-algebra, which we establish
by upgrading a map `C((s : Set ℝ≥0), ℝ≥0) →⋆ₐ[ℝ≥0] A` to `C(((↑) '' s : Set ℝ), ℝ) →⋆ₐ[ℝ] A` in
the natural way, and then applying the uniqueness for `ℝ`-algebra homomorphisms.

This is the reason the `ContinuousMap.UniqueHom` class exists in the first place, as
opposed to simply appealing directly to Stone-Weierstrass to prove `StarAlgHom.ext_continuousMap`.
-/

open Topology

section UniqueUnital

section RCLike

variable {𝕜 A : Type*} [RCLike 𝕜]

instance (priority := 100) RCLike.instContinuousMapUniqueHom [TopologicalSpace A]
    [T2Space A] [Ring A] [StarRing A] [Algebra 𝕜 A] :
    ContinuousMap.UniqueHom 𝕜 A where
  eq_of_continuous_of_map_id s _ φ ψ hφ hψ h :=
    ContinuousMap.starAlgHom_ext_map_X hφ hψ <| by
      convert h using 1
      all_goals exact congr_arg _ (by ext; simp)

instance Real.instContinuousMapUniqueHom [TopologicalSpace A]
    [T2Space A] [Ring A] [StarRing A] [Algebra ℝ A] :
    ContinuousMap.UniqueHom ℝ A :=
  inferInstance

instance Complex.instContinuousMapUniqueHom [TopologicalSpace A]
    [T2Space A] [Ring A] [StarRing A] [Algebra ℂ A] :
    ContinuousMap.UniqueHom ℂ A :=
  inferInstance

end RCLike

section NNReal
open NNReal

variable {X : Type*} [TopologicalSpace X]

namespace ContinuousMap

/-- This map sends `f : C(X, ℝ)` to `Real.toNNReal ∘ f`, bundled as a continuous map `C(X, ℝ≥0)`. -/
noncomputable def toNNReal (f : C(X, ℝ)) : C(X, ℝ≥0) := .realToNNReal |>.comp f

@[fun_prop]
lemma continuous_toNNReal : Continuous (toNNReal (X := X)) := continuous_postcomp _

@[simp]
lemma toNNReal_apply (f : C(X, ℝ)) (x : X) : f.toNNReal x = (f x).toNNReal := rfl

lemma toNNReal_add_add_neg_add_neg_eq (f g : C(X, ℝ)) :
    (f + g).toNNReal + (-f).toNNReal + (-g).toNNReal =
      (-(f + g)).toNNReal + f.toNNReal + g.toNNReal := by
  ext x
  simp [max_neg_zero, -neg_add_rev]
  abel

lemma toNNReal_mul_add_neg_mul_add_mul_neg_eq (f g : C(X, ℝ)) :
    (f * g).toNNReal + (-f).toNNReal * g.toNNReal + f.toNNReal * (-g).toNNReal =
      (-(f * g)).toNNReal + f.toNNReal * g.toNNReal + (-f).toNNReal * (-g).toNNReal := by
  ext x
  simp [max_neg_zero, add_mul, mul_add]
  abel

@[simp]
lemma toNNReal_algebraMap (r : ℝ≥0) :
    (algebraMap ℝ C(X, ℝ) r).toNNReal = algebraMap ℝ≥0 C(X, ℝ≥0) r := by
  ext; simp

@[simp]
lemma toNNReal_neg_algebraMap (r : ℝ≥0) : (- algebraMap ℝ C(X, ℝ) r).toNNReal = 0 := by
  ext; simp

@[simp]
lemma toNNReal_one : (1 : C(X, ℝ)).toNNReal = 1 := toNNReal_algebraMap 1

@[simp]
lemma toNNReal_neg_one : (-1 : C(X, ℝ)).toNNReal = 0 := toNNReal_neg_algebraMap 1

end ContinuousMap

variable {A : Type*} [Ring A] [StarRing A] [Algebra ℝ A]

namespace StarAlgHom

section IsTopologicalRing

variable [TopologicalSpace A] [IsTopologicalRing A]

/-- Given a star `ℝ≥0`-algebra homomorphism `φ` from `C(X, ℝ≥0)` into an `ℝ`-algebra `A`, this is
the unique extension of `φ` from `C(X, ℝ)` to `A` as a star `ℝ`-algebra homomorphism. -/
@[simps]
noncomputable def realContinuousMapOfNNReal (φ : C(X, ℝ≥0) →⋆ₐ[ℝ≥0] A) :
    C(X, ℝ) →⋆ₐ[ℝ] A where
  toFun f := φ f.toNNReal - φ (-f).toNNReal
  map_one' := by simp
  map_zero' := by simp
  map_mul' f g := by
    have := congr(φ $(f.toNNReal_mul_add_neg_mul_add_mul_neg_eq g))
    simp only [map_add, map_mul, sub_mul, mul_sub] at this ⊢
    rw [← sub_eq_zero] at this ⊢
    convert this using 1
    abel
  map_add' f g := by
    have := congr(φ $(f.toNNReal_add_add_neg_add_neg_eq g))
    simp only [map_add] at this ⊢
    rw [← sub_eq_zero] at this ⊢
    convert this using 1
    abel
  commutes' r := by
    obtain (hr | hr) := le_total 0 r
    · lift r to ℝ≥0 using hr
      simpa only [ContinuousMap.toNNReal_algebraMap, ContinuousMap.toNNReal_neg_algebraMap,
        map_zero, sub_zero] using AlgHomClass.commutes φ r
    · rw [← neg_neg r, ← map_neg, neg_neg (-r)]
      rw [← neg_nonneg] at hr
      lift -r to ℝ≥0 using hr with r
      simpa only [map_neg, ContinuousMap.toNNReal_neg_algebraMap, map_zero,
        ContinuousMap.toNNReal_algebraMap, zero_sub, neg_inj] using AlgHomClass.commutes φ r
  map_star' f := by simp only [star_trivial, star_sub, ← map_star]

@[fun_prop]
lemma continuous_realContinuousMapOfNNReal (φ : C(X, ℝ≥0) →⋆ₐ[ℝ≥0] A)
    (hφ : Continuous φ) : Continuous φ.realContinuousMapOfNNReal := by
  simp [realContinuousMapOfNNReal]
  fun_prop

end IsTopologicalRing

@[simp high]
lemma realContinuousMapOfNNReal_apply_comp_toReal (φ : C(X, ℝ≥0) →⋆ₐ[ℝ≥0] A)
    (f : C(X, ℝ≥0)) :
    φ.realContinuousMapOfNNReal ((ContinuousMap.mk toReal continuous_coe).comp f) = φ f := by
  simp only [realContinuousMapOfNNReal_apply]
  convert_to φ f - φ 0 = φ f using 2
  on_goal -1 => rw [map_zero, sub_zero]
  all_goals
    congr
    ext x
    simp

lemma realContinuousMapOfNNReal_injective :
    Function.Injective (realContinuousMapOfNNReal (X := X) (A := A)) := by
  intro φ ψ h
  ext f
  simpa using congr($(h) ((ContinuousMap.mk toReal continuous_coe).comp f))

end StarAlgHom

variable [TopologicalSpace A] [IsTopologicalRing A]

instance NNReal.instContinuousMap.UniqueHom [T2Space A] :
    ContinuousMap.UniqueHom ℝ≥0 A where
  eq_of_continuous_of_map_id s hs φ ψ hφ hψ h := by
    let s' : Set ℝ := (↑) '' s
    let e : s ≃ₜ s' :=
      { toFun := Subtype.map (↑) (by simp [s'])
        invFun := Subtype.map Real.toNNReal (by simp [s'])
        left_inv := fun _ ↦ by ext; simp
        right_inv := fun x ↦ by
          ext
          obtain ⟨y, -, hy⟩ := x.2
          simpa using hy ▸ NNReal.coe_nonneg y
        continuous_toFun := continuous_coe.subtype_map (by simp [s'])
        continuous_invFun := continuous_real_toNNReal.subtype_map (by simp [s']) }
    have (ξ : C(s, ℝ≥0) →⋆ₐ[ℝ≥0] A) (hξ : Continuous ξ) :
        (let ξ' := ξ.realContinuousMapOfNNReal.comp <| ContinuousMap.compStarAlgHom' ℝ ℝ e
        Continuous ξ' ∧ ξ' (.restrict s' <| .id ℝ) = ξ (.restrict s <| .id ℝ≥0)) := by
      intro ξ'
      refine ⟨ξ.continuous_realContinuousMapOfNNReal hξ |>.comp <|
        ContinuousMap.continuous_precomp _, ?_⟩
      exact ξ.realContinuousMapOfNNReal_apply_comp_toReal (.restrict s <| .id ℝ≥0)
    obtain ⟨hφ', hφ_id⟩ := this φ hφ
    obtain ⟨hψ', hψ_id⟩ := this ψ hψ
    have hs' : CompactSpace s' := e.compactSpace
    have h' := ContinuousMap.UniqueHom.eq_of_continuous_of_map_id s' _ _ hφ' hψ'
      (hφ_id ▸ hψ_id ▸ h)
    have h'' := congr($(h').comp <| ContinuousMap.compStarAlgHom' ℝ ℝ (e.symm : C(s', s)))
    have : (ContinuousMap.compStarAlgHom' ℝ ℝ (e : C(s, s'))).comp
        (ContinuousMap.compStarAlgHom' ℝ ℝ (e.symm : C(s', s))) = StarAlgHom.id _ _ := by
      ext1; simp
    simp only [StarAlgHom.comp_assoc, this, StarAlgHom.comp_id] at h''
    exact StarAlgHom.realContinuousMapOfNNReal_injective h''

end NNReal

end UniqueUnital

section UniqueNonUnital

section RCLike

variable {𝕜 A : Type*} [RCLike 𝕜]

open NonUnitalStarAlgebra in
instance RCLike.uniqueNonUnitalContinuousFunctionalCalculus
    [TopologicalSpace A] [T2Space A] [NonUnitalRing A] [StarRing A] [Module 𝕜 A]
    [IsScalarTower 𝕜 A A] [SMulCommClass 𝕜 A A] :
    ContinuousMapZero.UniqueHom 𝕜 A where
  eq_of_continuous_of_map_id s hs _inst h0 φ ψ hφ hψ h := by
    rw [DFunLike.ext'_iff, ← Set.eqOn_univ, ← (ContinuousMapZero.adjoin_id_dense h0).closure_eq]
    refine Set.EqOn.closure (fun f hf ↦ ?_) hφ hψ
    rw [← NonUnitalStarAlgHom.mem_equalizer]
    apply adjoin_le ?_ hf
    rw [Set.singleton_subset_iff]
    exact h

end RCLike

section NNReal
open NNReal

variable {X : Type*} [TopologicalSpace X] [Zero X]

namespace ContinuousMapZero

/-- This map sends `f : C(X, ℝ)` to `Real.toNNReal ∘ f`, bundled as a continuous map `C(X, ℝ≥0)`. -/
noncomputable def toNNReal (f : C(X, ℝ)₀) : C(X, ℝ≥0)₀ := ⟨.realToNNReal |>.comp f, by simp⟩

@[simp]
lemma toNNReal_apply (f : C(X, ℝ)₀) (x : X) : f.toNNReal x = Real.toNNReal (f x) := rfl

@[fun_prop]
lemma continuous_toNNReal : Continuous (toNNReal (X := X)) := by
  rw [continuous_induced_rng]
  convert_to Continuous (ContinuousMap.toNNReal ∘ ((↑) : C(X, ℝ)₀ → C(X, ℝ))) using 1
  exact ContinuousMap.continuous_postcomp _ |>.comp continuous_induced_dom

lemma toContinuousMapHom_toNNReal (f : C(X, ℝ)₀) :
    (toContinuousMapHom (X := X) (R := ℝ) f).toNNReal =
      toContinuousMapHom (X := X) (R := ℝ≥0) f.toNNReal :=
  rfl

@[simp]
lemma toNNReal_smul (r : ℝ≥0) (f : C(X, ℝ)₀) : (r • f).toNNReal = r • f.toNNReal := by
  ext x
  by_cases h : 0 ≤ f x
  · simpa [max_eq_left h, NNReal.smul_def] using mul_nonneg r.coe_nonneg h
  · push_neg at h
    simpa [max_eq_right h.le, NNReal.smul_def]
      using mul_nonpos_of_nonneg_of_nonpos r.coe_nonneg h.le

@[simp]
lemma toNNReal_neg_smul (r : ℝ≥0) (f : C(X, ℝ)₀) : (-(r • f)).toNNReal = r • (-f).toNNReal := by
  rw [NNReal.smul_def, ← smul_neg, ← NNReal.smul_def, toNNReal_smul]

lemma toNNReal_mul_add_neg_mul_add_mul_neg_eq (f g : C(X, ℝ)₀) :
    ((f * g).toNNReal + (-f).toNNReal * g.toNNReal + f.toNNReal * (-g).toNNReal) =
    ((-(f * g)).toNNReal + f.toNNReal * g.toNNReal + (-f).toNNReal * (-g).toNNReal) := by
  apply toContinuousMap_injective
  simpa only [← toContinuousMapHom_apply, map_add, map_mul, map_neg, toContinuousMapHom_toNNReal]
    using (f : C(X, ℝ)).toNNReal_mul_add_neg_mul_add_mul_neg_eq g

lemma toNNReal_add_add_neg_add_neg_eq (f g : C(X, ℝ)₀) :
    ((f + g).toNNReal + (-f).toNNReal + (-g).toNNReal) =
      ((-(f + g)).toNNReal + f.toNNReal + g.toNNReal) := by
  apply toContinuousMap_injective
  simpa only [← toContinuousMapHom_apply, map_add, map_mul, map_neg, toContinuousMapHom_toNNReal]
    using (f : C(X, ℝ)).toNNReal_add_add_neg_add_neg_eq g

end ContinuousMapZero

variable {A : Type*} [NonUnitalRing A] [StarRing A] [Module ℝ A]

namespace NonUnitalStarAlgHom

open ContinuousMapZero

section IsTopologicalRing

variable [TopologicalSpace A] [IsTopologicalRing A]

/-- Given a non-unital star `ℝ≥0`-algebra homomorphism `φ` from `C(X, ℝ≥0)₀` into a non-unital
`ℝ`-algebra `A`, this is the unique extension of `φ` from `C(X, ℝ)₀` to `A` as a non-unital
star `ℝ`-algebra homomorphism. -/
@[simps]
noncomputable def realContinuousMapZeroOfNNReal (φ : C(X, ℝ≥0)₀ →⋆ₙₐ[ℝ≥0] A) :
    C(X, ℝ)₀ →⋆ₙₐ[ℝ] A where
  toFun f := φ f.toNNReal - φ (-f).toNNReal
  map_zero' := by simp
  map_mul' f g := by
    have := congr(φ $(f.toNNReal_mul_add_neg_mul_add_mul_neg_eq g))
    simp only [map_add, map_mul, sub_mul, mul_sub] at this ⊢
    rw [← sub_eq_zero] at this ⊢
    rw [← this]
    abel
  map_add' f g := by
    have := congr(φ $(f.toNNReal_add_add_neg_add_neg_eq g))
    simp only [map_add, map_mul, sub_mul, mul_sub] at this ⊢
    rw [← sub_eq_zero] at this ⊢
    rw [← this]
    abel
  map_smul' r f := by
    simp only [MonoidHom.id_apply]
    by_cases hr : 0 ≤ r
    · lift r to ℝ≥0 using hr
      simp only [← smul_def, toNNReal_smul, map_smul, toNNReal_neg_smul, smul_sub]
    · rw [not_le, ← neg_pos] at hr
      rw [← neg_smul]
      nth_rw 1 [← neg_neg r]
      nth_rw 3 [← neg_neg r]
      lift -r to ℝ≥0 using hr.le with r
      simp only [neg_smul, ← smul_def, toNNReal_neg_smul, map_smul, toNNReal_smul, smul_sub,
        sub_neg_eq_add]
      rw [sub_eq_add_neg, add_comm]
  map_star' f := by simp only [star_trivial, star_sub, ← map_star]

@[fun_prop]
lemma continuous_realContinuousMapZeroOfNNReal (φ : C(X, ℝ≥0)₀ →⋆ₙₐ[ℝ≥0] A)
    (hφ : Continuous φ) : Continuous φ.realContinuousMapZeroOfNNReal := by
  simp [realContinuousMapZeroOfNNReal]
  fun_prop

end IsTopologicalRing

@[simp high]
lemma realContinuousMapZeroOfNNReal_apply_comp_toReal (φ : C(X, ℝ≥0)₀ →⋆ₙₐ[ℝ≥0] A)
    (f : C(X, ℝ≥0)₀) :
    φ.realContinuousMapZeroOfNNReal ((ContinuousMapZero.mk ⟨toReal, continuous_coe⟩ rfl).comp f) =
      φ f := by
  simp only [realContinuousMapZeroOfNNReal_apply]
  convert_to φ f - φ 0 = φ f using 2
  on_goal -1 => rw [map_zero, sub_zero]
  all_goals
    congr
    ext x
    simp

lemma realContinuousMapZeroOfNNReal_injective :
    Function.Injective (realContinuousMapZeroOfNNReal (X := X) (A := A)) := by
  intro φ ψ h
  ext f
  simpa using congr($(h) ((ContinuousMapZero.mk ⟨toReal, continuous_coe⟩ rfl).comp f))

end NonUnitalStarAlgHom

open ContinuousMapZero

instance NNReal.instContinuousMapZero.UniqueHom
    [TopologicalSpace A] [IsTopologicalRing A] [IsScalarTower ℝ A A] [SMulCommClass ℝ A A]
    [T2Space A] :
    ContinuousMapZero.UniqueHom ℝ≥0 A where
  eq_of_continuous_of_map_id s hs _inst h0 φ ψ hφ hψ h := by
    let s' : Set ℝ := (↑) '' s
    let e : s ≃ₜ s' :=
      { toFun := Subtype.map (↑) (by simp [s'])
        invFun := Subtype.map Real.toNNReal (by simp [s'])
        left_inv := fun _ ↦ by ext; simp
        right_inv := fun x ↦ by
          ext
          obtain ⟨y, -, hy⟩ := x.2
          simpa using hy ▸ NNReal.coe_nonneg y
        continuous_toFun := continuous_coe.subtype_map (by simp [s'])
        continuous_invFun := continuous_real_toNNReal.subtype_map (by simp [s']) }
    let _inst₁ : Zero s' := ⟨0, ⟨0, h0 ▸ Subtype.property (0 : s), coe_zero⟩⟩
    have h0' : ((0 : s') : ℝ) = 0 := rfl
    have e0 : e 0 = 0 := by ext; simp [e, h0, h0']
    have e0' : e.symm 0 = 0 := by
      simpa only [Homeomorph.symm_apply_apply] using congr(e.symm $(e0)).symm
    have (ξ : C(s, ℝ≥0)₀ →⋆ₙₐ[ℝ≥0] A) (hξ : Continuous ξ) :
        (let ξ' := ξ.realContinuousMapZeroOfNNReal.comp <|
          ContinuousMapZero.nonUnitalStarAlgHom_precomp ℝ ⟨e, e0⟩;
          Continuous ξ' ∧ ξ' (ContinuousMapZero.id h0') = ξ (ContinuousMapZero.id h0)) := by
      intro ξ'
      refine ⟨ξ.continuous_realContinuousMapZeroOfNNReal hξ |>.comp <| ?_, ?_⟩
      · rw [continuous_induced_rng]
        exact ContinuousMap.continuous_precomp _ |>.comp continuous_induced_dom
      · exact ξ.realContinuousMapZeroOfNNReal_apply_comp_toReal (.id h0)
    obtain ⟨hφ', hφ_id⟩ := this φ hφ
    obtain ⟨hψ', hψ_id⟩ := this ψ hψ
    have hs' : CompactSpace s' := e.compactSpace
    have : ContinuousMapZero.UniqueHom ℝ A := inferInstance
    have h' := ContinuousMapZero.UniqueHom.eq_of_continuous_of_map_id
      s' h0' _ _ hφ' hψ' (hφ_id ▸ hψ_id ▸ h)
    have h'' := congr($(h').comp <|
      ContinuousMapZero.nonUnitalStarAlgHom_precomp ℝ ⟨(e.symm : C(s', s)), e0'⟩)
    have : (ContinuousMapZero.nonUnitalStarAlgHom_precomp ℝ ⟨(e : C(s, s')), e0⟩).comp
        (ContinuousMapZero.nonUnitalStarAlgHom_precomp ℝ ⟨(e.symm : C(s', s)), e0'⟩) =
        NonUnitalStarAlgHom.id _ _ := by
      ext; simp
    simp only [NonUnitalStarAlgHom.comp_assoc, this, NonUnitalStarAlgHom.comp_id] at h''
    exact NonUnitalStarAlgHom.realContinuousMapZeroOfNNReal_injective h''

end NNReal

end UniqueNonUnital

section NonUnitalStarAlgHom

open scoped ContinuousMapZero NonUnitalContinuousFunctionalCalculus

variable {F R S A B : Type*} {p : A → Prop} {q : B → Prop}
  [CommSemiring R] [Nontrivial R] [StarRing R] [MetricSpace R] [IsTopologicalSemiring R]
  [ContinuousStar R] [CommRing S] [Algebra R S]
  [NonUnitalRing A] [StarRing A] [TopologicalSpace A] [Module R A]
  [IsScalarTower R A A] [SMulCommClass R A A]
  [NonUnitalRing B] [StarRing B] [TopologicalSpace B] [Module R B]
  [IsScalarTower R B B] [SMulCommClass R B B]
  [Module S A] [Module S B] [IsScalarTower R S A] [IsScalarTower R S B]
  [NonUnitalContinuousFunctionalCalculus R A p] [NonUnitalContinuousFunctionalCalculus R B q]
  [ContinuousMapZero.UniqueHom R B] [FunLike F A B] [NonUnitalAlgHomClass F S A B]
  [StarHomClass F A B]

include S in
/-- Non-unital star algebra homomorphisms commute with the non-unital continuous functional
calculus. -/
lemma NonUnitalStarAlgHomClass.map_cfcₙ (φ : F) (f : R → R) (a : A)
    (hf : ContinuousOn f (quasispectrum R a) := by cfc_cont_tac)
    (hf₀ : f 0 = 0 := by cfc_zero_tac) (hφ : Continuous φ := by fun_prop) (ha : p a := by cfc_tac)
    (hφa : q (φ a) := by cfc_tac) : φ (cfcₙ f a) = cfcₙ f (φ a) := by
  let ψ : A →⋆ₙₐ[R] B := (φ : A →⋆ₙₐ[S] B).restrictScalars R
  have : Continuous ψ := hφ
  have h_spec := NonUnitalAlgHom.quasispectrum_apply_subset' (R := R) S φ a
  have hψa : q (ψ a) := hφa
  let ι : C(quasispectrum R (ψ a), quasispectrum R a)₀ :=
    ⟨⟨Set.inclusion h_spec, continuous_id.subtype_map h_spec⟩, rfl⟩
  suffices ψ.comp (cfcₙHom ha) =
      (cfcₙHom hψa).comp (ContinuousMapZero.nonUnitalStarAlgHom_precomp R ι) by
    have hf' : ContinuousOn f (quasispectrum R (ψ a)) := hf.mono h_spec
    rw [cfcₙ_apply .., cfcₙ_apply ..]
    exact DFunLike.congr_fun this _
  refine ContinuousMapZero.UniqueHom.eq_of_continuous_of_map_id _ rfl _ _
    ?_ ?_ ?apply_id
  case apply_id =>
    trans cfcₙHom hψa ⟨.restrict (quasispectrum R (ψ a)) (.id R), rfl⟩
    · simp [cfcₙHom_id]
    · congr
  all_goals
    simp [ContinuousMapZero.nonUnitalStarAlgHom_precomp]
    fun_prop

/-- Non-unital star algebra homomorphisms commute with the non-unital continuous functional
calculus.  This version is specialized to `A →⋆ₙₐ[S] B` to allow for dot notation. -/
lemma NonUnitalStarAlgHom.map_cfcₙ (φ : A →⋆ₙₐ[S] B) (f : R → R) (a : A)
    (hf : ContinuousOn f (quasispectrum R a) := by cfc_cont_tac)
    (hf₀ : f 0 = 0 := by cfc_zero_tac) (hφ : Continuous φ := by fun_prop) (ha : p a := by cfc_tac)
    (hφa : q (φ a) := by cfc_tac) : φ (cfcₙ f a) = cfcₙ f (φ a) :=
  NonUnitalStarAlgHomClass.map_cfcₙ φ f a

end NonUnitalStarAlgHom

section StarAlgHom

open scoped ContinuousFunctionalCalculus

variable {F R S A B : Type*} {p : A → Prop} {q : B → Prop}
  [CommSemiring R] [StarRing R] [MetricSpace R] [IsTopologicalSemiring R] [ContinuousStar R]
  [Ring A] [StarRing A] [TopologicalSpace A] [Algebra R A]
  [Ring B] [StarRing B] [TopologicalSpace B] [Algebra R B]
  [CommSemiring S] [Algebra R S] [Algebra S A] [Algebra S B] [IsScalarTower R S A]
  [IsScalarTower R S B] [ContinuousFunctionalCalculus R A p] [ContinuousFunctionalCalculus R B q]
  [ContinuousMap.UniqueHom R B] [FunLike F A B] [AlgHomClass F S A B]
  [StarHomClass F A B]

include S in
/-- Star algebra homomorphisms commute with the continuous functional calculus. -/
lemma StarAlgHomClass.map_cfc (φ : F) (f : R → R) (a : A)
    (hf : ContinuousOn f (spectrum R a) := by cfc_cont_tac)
    (hφ : Continuous φ := by fun_prop) (ha : p a := by cfc_tac) (hφa : q (φ a) := by cfc_tac) :
    φ (cfc f a) = cfc f (φ a) := by
  let ψ : A →⋆ₐ[R] B := (φ : A →⋆ₐ[S] B).restrictScalars R
  have : Continuous ψ := hφ
  have h_spec := AlgHom.spectrum_apply_subset ψ a
  have hψa : q (ψ a) := hφa
  let ι : C(spectrum R (ψ a), spectrum R a) :=
    ⟨Set.inclusion h_spec, continuous_id.subtype_map h_spec⟩
  suffices ψ.comp (cfcHom ha) = (cfcHom hψa).comp (ContinuousMap.compStarAlgHom' R R ι) by
    have hf' : ContinuousOn f (spectrum R (ψ a)) := hf.mono h_spec
    rw [cfc_apply .., cfc_apply ..]
    congrm($(this) ⟨_, hf.restrict⟩)
  refine ContinuousMap.UniqueHom.eq_of_continuous_of_map_id _ _ _ ?_ ?_ ?apply_id
  case apply_id =>
    trans cfcHom hψa (.restrict (spectrum R (ψ a)) (.id R))
    · simp [cfcHom_id]
    · congr
  all_goals
    simp [ContinuousMap.compStarAlgHom']
    fun_prop

/-- Star algebra homomorphisms commute with the continuous functional calculus.
This version is specialized to `A →⋆ₐ[S] B` to allow for dot notation. -/
lemma StarAlgHom.map_cfc (φ : A →⋆ₐ[S] B) (f : R → R) (a : A)
    (hf : ContinuousOn f (spectrum R a) := by cfc_cont_tac) (hφ : Continuous φ := by fun_prop)
    (ha : p a := by cfc_tac) (hφa : q (φ a) := by cfc_tac) :
    φ (cfc f a) = cfc f (φ a) :=
  StarAlgHomClass.map_cfc φ f a

end StarAlgHom
