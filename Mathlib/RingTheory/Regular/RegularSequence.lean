/-
Copyright (c) 2024 Brendan Murphy. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Brendan Murphy
-/
import Mathlib.RingTheory.Regular.IsSMulRegular
import Mathlib.RingTheory.Artinian.Module
import Mathlib.RingTheory.Nakayama
import Mathlib.Algebra.Equiv.TransferInstance
import Mathlib.RingTheory.LocalRing.MaximalIdeal.Basic
import Mathlib.RingTheory.Noetherian.Basic

/-!
# Regular sequences and weakly regular sequences

The notion of a regular sequence is fundamental in commutative algebra.
Properties of regular sequences encode information about singularities of a
ring and regularity of a sequence can be tested homologically.
However the notion of a regular sequence is only really sensible for Noetherian local rings.

TODO: Koszul regular sequences, H_1-regular sequences, quasi-regular sequences, depth.

## Tags

module, regular element, regular sequence, commutative algebra
-/

universe u v

open scoped Pointwise

variable {R S M M₂ M₃ M₄ : Type*}

namespace Ideal

variable [Semiring R] [Semiring S]

/-- The ideal generated by a list of elements. -/
abbrev ofList (rs : List R) := span { r | r ∈ rs }

@[simp] lemma ofList_nil : (ofList [] : Ideal R) = ⊥ :=
  have : { r | r ∈ [] } = ∅ := Set.eq_empty_of_forall_not_mem (fun _ => List.not_mem_nil)
  Eq.trans (congrArg span this) span_empty

@[simp] lemma ofList_append (rs₁ rs₂ : List R) :
    ofList (rs₁ ++ rs₂) = ofList rs₁ ⊔ ofList rs₂ :=
  have : { r | r ∈ rs₁ ++ rs₂ } = _ := Set.ext (fun _ => List.mem_append)
  Eq.trans (congrArg span this) (span_union _ _)

lemma ofList_singleton (r : R) : ofList [r] = span {r} :=
  congrArg span (Set.ext fun _ => List.mem_singleton)

@[simp] lemma ofList_cons (r : R) (rs : List R) :
    ofList (r::rs) = span {r} ⊔ ofList rs :=
  Eq.trans (ofList_append [r] rs) (congrArg (· ⊔ _) (ofList_singleton r))

@[simp] lemma map_ofList (f : R →+* S) (rs : List R) :
    map f (ofList rs) = ofList (rs.map f) :=
  Eq.trans (map_span f { r | r ∈ rs }) <| congrArg span <|
    Set.ext (fun _ => List.mem_map.symm)

lemma ofList_cons_smul {R} [CommSemiring R] (r : R) (rs : List R) {M}
    [AddCommMonoid M] [Module R M] (N : Submodule R M) :
    ofList (r :: rs) • N = r • N ⊔ ofList rs • N := by
  rw [ofList_cons, Submodule.sup_smul, Submodule.ideal_span_singleton_smul]

end Ideal

namespace Submodule

lemma smul_top_le_comap_smul_top [CommSemiring R] [AddCommMonoid M]
    [AddCommMonoid M₂] [Module R M] [Module R M₂] (I : Ideal R)
    (f : M →ₗ[R] M₂) : I • ⊤ ≤ comap f (I • ⊤) :=
  map_le_iff_le_comap.mp <| le_of_eq_of_le (map_smul'' _ _ _) <|
    smul_mono_right _ le_top

variable (M) [CommRing R] [AddCommGroup M] [AddCommGroup M₂]
    [Module R M] [Module R M₂] (r : R) (rs : List R)

/-- The equivalence between M ⧸ (r₀, r₁, …, rₙ)M and (M ⧸ r₀M) ⧸ (r₁, …, rₙ) (M ⧸ r₀M). -/
def quotOfListConsSMulTopEquivQuotSMulTopInner :
    (M ⧸ (Ideal.ofList (r :: rs) • ⊤ : Submodule R M)) ≃ₗ[R]
      QuotSMulTop r M ⧸ (Ideal.ofList rs • ⊤ : Submodule R (QuotSMulTop r M)) :=
  quotEquivOfEq _ _ (Ideal.ofList_cons_smul r rs ⊤) ≪≫ₗ
    (quotientQuotientEquivQuotientSup (r • ⊤) (Ideal.ofList rs • ⊤)).symm ≪≫ₗ
      quotEquivOfEq _ _ (by rw [map_smul'', map_top, range_mkQ])

/-- The equivalence between M ⧸ (r₀, r₁, …, rₙ)M and (M ⧸ (r₁, …, rₙ)) ⧸ r₀ (M ⧸ (r₁, …, rₙ)). -/
def quotOfListConsSMulTopEquivQuotSMulTopOuter :
    (M ⧸ (Ideal.ofList (r :: rs) • ⊤ : Submodule R M)) ≃ₗ[R]
      QuotSMulTop r (M ⧸ (Ideal.ofList rs • ⊤ : Submodule R M)) :=
  quotEquivOfEq _ _ (Eq.trans (Ideal.ofList_cons_smul r rs ⊤) (sup_comm _ _)) ≪≫ₗ
    (quotientQuotientEquivQuotientSup (Ideal.ofList rs • ⊤) (r • ⊤)).symm ≪≫ₗ
      quotEquivOfEq _ _ (by rw [map_pointwise_smul, map_top, range_mkQ])

variable {M}

lemma quotOfListConsSMulTopEquivQuotSMulTopInner_naturality (f : M →ₗ[R] M₂) :
    (quotOfListConsSMulTopEquivQuotSMulTopInner M₂ r rs).toLinearMap ∘ₗ
        mapQ _ _ _ (smul_top_le_comap_smul_top (Ideal.ofList (r :: rs)) f) =
      mapQ _ _ _ (smul_top_le_comap_smul_top _ (QuotSMulTop.map r f)) ∘ₗ
        (quotOfListConsSMulTopEquivQuotSMulTopInner M r rs).toLinearMap :=
  quot_hom_ext _ _ _ fun _ => rfl

lemma top_eq_ofList_cons_smul_iff :
    (⊤ : Submodule R M) = Ideal.ofList (r :: rs) • ⊤ ↔
      (⊤ : Submodule R (QuotSMulTop r M)) = Ideal.ofList rs • ⊤ := by
  conv => congr <;> rw [eq_comm, ← subsingleton_quotient_iff_eq_top]
  exact (quotOfListConsSMulTopEquivQuotSMulTopInner M r rs).toEquiv.subsingleton_congr

end Submodule

namespace RingTheory.Sequence

open scoped TensorProduct List
open Function Submodule QuotSMulTop

variable (S M)

section Definitions

/-
In theory, regularity of `rs : List α` on `M` makes sense as soon as
`[Monoid α]`, `[AddCommGroup M]`, and `[DistribMulAction α M]`.
Instead of `Ideal.ofList (rs.take i) • (⊤ : Submodule R M)` we use
`⨆ (j : Fin i), rs[j] • (⊤ : AddSubgroup M)`.
However it's not clear that this is a useful generalization.
If we add the assumption `[SMulCommClass α α M]` this is essentially the same
as focusing on the commutative ring case, by passing to the monoid ring
`ℤ[abelianization of α]`.
-/
variable [CommRing R] [AddCommGroup M] [Module R M]

open Ideal

/-- A sequence `[r₁, …, rₙ]` is weakly regular on `M` iff `rᵢ` is regular on
`M⧸(r₁, …, rᵢ₋₁)M` for all `1 ≤ i ≤ n`. -/
@[mk_iff]
structure IsWeaklyRegular (rs : List R) : Prop where
  regular_mod_prev : ∀ i (h : i < rs.length),
    IsSMulRegular (M ⧸ (ofList (rs.take i) • ⊤ : Submodule R M)) rs[i]

lemma isWeaklyRegular_iff_Fin (rs : List R) :
    IsWeaklyRegular M rs ↔ ∀ (i : Fin rs.length),
      IsSMulRegular (M ⧸ (ofList (rs.take i) • ⊤ : Submodule R M)) rs[i] :=
  Iff.trans (isWeaklyRegular_iff M rs) (Iff.symm Fin.forall_iff)

/-- A weakly regular sequence `rs` on `M` is regular if also `M/rsM ≠ 0`. -/
@[mk_iff]
structure IsRegular (rs : List R) : Prop extends IsWeaklyRegular M rs where
  top_ne_smul : (⊤ : Submodule R M) ≠ Ideal.ofList rs • ⊤

end Definitions

section Congr

variable {S M} [CommRing R] [CommRing S] [AddCommGroup M] [AddCommGroup M₂]
    [Module R M] [Module S M₂]
    {σ : R →+* S} {σ' : S →+* R} [RingHomInvPair σ σ'] [RingHomInvPair σ' σ]

open DistribMulAction AddSubgroup in
private lemma _root_.AddHom.map_smul_top_toAddSubgroup_of_surjective
    {f : M →+ M₂} {as : List R} {bs : List S} (hf : Function.Surjective f)
    (h : List.Forall₂ (fun r s => ∀ x, f (r • x) = s • f x) as bs) :
    (Ideal.ofList as • ⊤ : Submodule R M).toAddSubgroup.map f =
      (Ideal.ofList bs • ⊤ : Submodule S M₂).toAddSubgroup := by
  induction h with
  | nil =>
    convert AddSubgroup.map_bot f using 1 <;>
      rw [Ideal.ofList_nil, bot_smul, bot_toAddSubgroup]
  | @cons r s _ _ h _ ih =>
    conv => congr <;> rw [Ideal.ofList_cons, sup_smul, sup_toAddSubgroup,
      ideal_span_singleton_smul, pointwise_smul_toAddSubgroup,
      top_toAddSubgroup, pointwise_smul_def]
    apply DFunLike.ext (f.comp (toAddMonoidEnd R M r))
      ((toAddMonoidEnd S M₂ s).comp f) at h
    rw [AddSubgroup.map_sup, ih, map_map, h, ← map_map,
      map_top_of_surjective f hf]

lemma _root_.AddEquiv.isWeaklyRegular_congr {e : M ≃+ M₂} {as bs}
    (h : List.Forall₂ (fun (r : R) (s : S) => ∀ x, e (r • x) = s • e x) as bs) :
    IsWeaklyRegular M as ↔ IsWeaklyRegular M₂ bs := by
  conv => congr <;> rw [isWeaklyRegular_iff_Fin]
  let e' i : (M ⧸ (Ideal.ofList (as.take i) • ⊤ : Submodule R M)) ≃+
      M₂ ⧸ (Ideal.ofList (bs.take i) • ⊤ : Submodule S M₂) :=
    QuotientAddGroup.congr _ _ e <|
      AddHom.map_smul_top_toAddSubgroup_of_surjective e.surjective <|
        List.forall₂_take i h
  refine (finCongr h.length_eq).forall_congr @fun _ => (e' _).isSMulRegular_congr ?_
  exact (mkQ_surjective _).forall.mpr fun _ => congrArg (mkQ _) (h.get _ _ _)

lemma _root_.LinearEquiv.isWeaklyRegular_congr' (e : M ≃ₛₗ[σ] M₂) (rs : List R) :
    IsWeaklyRegular M rs ↔ IsWeaklyRegular M₂ (rs.map σ) :=
  e.toAddEquiv.isWeaklyRegular_congr <| List.forall₂_map_right_iff.mpr <|
    List.forall₂_same.mpr fun r _ x => e.map_smul' r x

lemma _root_.LinearEquiv.isWeaklyRegular_congr [Module R M₂] (e : M ≃ₗ[R] M₂) (rs : List R) :
    IsWeaklyRegular M rs ↔ IsWeaklyRegular M₂ rs :=
  Iff.trans (e.isWeaklyRegular_congr' rs) <| iff_of_eq <| congrArg _ rs.map_id

lemma _root_.AddEquiv.isRegular_congr {e : M ≃+ M₂} {as bs}
    (h : List.Forall₂ (fun (r : R) (s : S) => ∀ x, e (r • x) = s • e x) as bs) :
    IsRegular M as ↔ IsRegular M₂ bs := by
  conv => congr <;> rw [isRegular_iff, ne_eq, eq_comm,
    ← subsingleton_quotient_iff_eq_top]
  let e' := QuotientAddGroup.congr _ _ e <|
    AddHom.map_smul_top_toAddSubgroup_of_surjective e.surjective h
  exact and_congr (e.isWeaklyRegular_congr h) e'.subsingleton_congr.not

lemma _root_.LinearEquiv.isRegular_congr' (e : M ≃ₛₗ[σ] M₂) (rs : List R) :
    IsRegular M rs ↔ IsRegular M₂ (rs.map σ) :=
  e.toAddEquiv.isRegular_congr <| List.forall₂_map_right_iff.mpr <|
    List.forall₂_same.mpr fun r _ x => e.map_smul' r x

lemma _root_.LinearEquiv.isRegular_congr [Module R M₂] (e : M ≃ₗ[R] M₂) (rs : List R) :
    IsRegular M rs ↔ IsRegular M₂ rs :=
  Iff.trans (e.isRegular_congr' rs) <| iff_of_eq <| congrArg _ rs.map_id

end Congr

lemma isWeaklyRegular_map_algebraMap_iff [CommRing R] [CommRing S]
    [Algebra R S] [AddCommGroup M] [Module R M] [Module S M]
    [IsScalarTower R S M] (rs : List R) :
    IsWeaklyRegular M (rs.map (algebraMap R S)) ↔ IsWeaklyRegular M rs :=
  (AddEquiv.refl M).isWeaklyRegular_congr <| List.forall₂_map_left_iff.mpr <|
    List.forall₂_same.mpr fun r _ => algebraMap_smul S r

variable [CommRing R] [AddCommGroup M] [AddCommGroup M₂] [AddCommGroup M₃]
    [AddCommGroup M₄] [Module R M] [Module R M₂] [Module R M₃] [Module R M₄]

@[simp]
lemma isWeaklyRegular_cons_iff (r : R) (rs : List R) :
    IsWeaklyRegular M (r :: rs) ↔
      IsSMulRegular M r ∧ IsWeaklyRegular (QuotSMulTop r M) rs :=
  have := Eq.trans (congrArg (· • ⊤) Ideal.ofList_nil) (bot_smul ⊤)
  let e i := quotOfListConsSMulTopEquivQuotSMulTopInner M r (rs.take i)
  Iff.trans (isWeaklyRegular_iff_Fin _ _) <| Iff.trans Fin.forall_iff_succ <|
    and_congr ((quotEquivOfEqBot _ this).isSMulRegular_congr r) <|
      Iff.trans (forall_congr' fun i => (e i).isSMulRegular_congr (rs.get i))
        (isWeaklyRegular_iff_Fin _ _).symm

lemma isWeaklyRegular_cons_iff' (r : R) (rs : List R) :
    IsWeaklyRegular M (r :: rs) ↔
      IsSMulRegular M r ∧
        IsWeaklyRegular (QuotSMulTop r M)
          (rs.map (Ideal.Quotient.mk (Ideal.span {r}))) :=
  Iff.trans (isWeaklyRegular_cons_iff M r rs) <| and_congr_right' <|
    Iff.symm <| isWeaklyRegular_map_algebraMap_iff (R ⧸ Ideal.span {r}) _ rs

@[simp]
lemma isRegular_cons_iff (r : R) (rs : List R) :
    IsRegular M (r :: rs) ↔
      IsSMulRegular M r ∧ IsRegular (QuotSMulTop r M) rs := by
  rw [isRegular_iff, isRegular_iff, isWeaklyRegular_cons_iff M r rs,
    ne_eq, top_eq_ofList_cons_smul_iff, and_assoc]

lemma isRegular_cons_iff' (r : R) (rs : List R) :
    IsRegular M (r :: rs) ↔
      IsSMulRegular M r ∧ IsRegular (QuotSMulTop r M)
          (rs.map (Ideal.Quotient.mk (Ideal.span {r}))) := by
  conv => congr <;> rw [isRegular_iff, ne_eq]
  rw [isWeaklyRegular_cons_iff', ← restrictScalars_inj R (R ⧸ _),
    ← Ideal.map_ofList, ← Ideal.Quotient.algebraMap_eq, Ideal.smul_restrictScalars,
    restrictScalars_top, top_eq_ofList_cons_smul_iff, and_assoc]

variable {M}

namespace IsWeaklyRegular

variable (R M) in
@[simp] lemma nil : IsWeaklyRegular M ([] : List R) :=
  .mk (False.elim <| Nat.not_lt_zero · ·)

lemma cons {r : R} {rs : List R} (h1 : IsSMulRegular M r)
    (h2 : IsWeaklyRegular (QuotSMulTop r M) rs) : IsWeaklyRegular M (r :: rs) :=
  (isWeaklyRegular_cons_iff M r rs).mpr ⟨h1, h2⟩

lemma cons' {r : R} {rs : List R} (h1 : IsSMulRegular M r)
    (h2 : IsWeaklyRegular (QuotSMulTop r M)
            (rs.map (Ideal.Quotient.mk (Ideal.span {r})))) :
    IsWeaklyRegular M (r :: rs) :=
  (isWeaklyRegular_cons_iff' M r rs).mpr ⟨h1, h2⟩

/-- Weakly regular sequences can be inductively characterized by:
* The empty sequence is weakly regular on any module.
* If `r` is regular on `M` and `rs` is a weakly regular sequence on `M⧸rM` then
the sequence obtained from `rs` by prepending `r` is weakly regular on `M`.

This is the induction principle produced by the inductive definition above.
The motive will usually be valued in `Prop`, but `Sort*` works too. -/
@[induction_eliminator]
def recIterModByRegular
    {motive : (M : Type v) → [AddCommGroup M] → [Module R M] → (rs : List R) →
      IsWeaklyRegular M rs → Sort*}
    (nil : (M : Type v) → [AddCommGroup M] → [Module R M] → motive M [] (nil R M))
    (cons : {M : Type v} → [AddCommGroup M] → [Module R M] → (r : R) →
      (rs : List R) → (h1 : IsSMulRegular M r) →
      (h2 : IsWeaklyRegular (QuotSMulTop r M) rs) →
      (ih : motive (QuotSMulTop r M) rs h2) → motive M (r :: rs) (cons h1 h2)) :
    {M : Type v} → [AddCommGroup M] → [Module R M] → {rs : List R} →
    (h : IsWeaklyRegular M rs) → motive M rs h
  | M, _, _, [], _ => nil M
  | M, _, _, r :: rs, h =>
    let ⟨h1, h2⟩ := (isWeaklyRegular_cons_iff M r rs).mp h
    cons r rs h1 h2 (recIterModByRegular nil cons h2)

/-- A simplified version of `IsWeaklyRegular.recIterModByRegular` where the
motive is not allowed to depend on the proof of `IsWeaklyRegular`. -/
def ndrecIterModByRegular
    {motive : (M : Type v) → [AddCommGroup M] → [Module R M] → (rs : List R) → Sort*}
    (nil : (M : Type v) → [AddCommGroup M] → [Module R M] → motive M [])
    (cons : {M : Type v} → [AddCommGroup M] → [Module R M] → (r : R) →
      (rs : List R) → IsSMulRegular M r → IsWeaklyRegular (QuotSMulTop r M) rs →
      motive (QuotSMulTop r M) rs → motive M (r :: rs))
    {M} [AddCommGroup M] [Module R M] {rs} :
    IsWeaklyRegular M rs → motive M rs :=
  recIterModByRegular (motive := fun M _ _ rs _ => motive M rs) nil cons

/-- An alternate induction principle from `IsWeaklyRegular.recIterModByRegular`
where we mod out by successive elements in both the module and the base ring.
This is useful for propagating certain properties of the initial `M`, e.g.
faithfulness or freeness, throughout the induction. -/
def recIterModByRegularWithRing
    {motive : (R : Type u) → [CommRing R] → (M : Type v) → [AddCommGroup M] →
      [Module R M] → (rs : List R) → IsWeaklyRegular M rs → Sort*}
    (nil : (R : Type u) → [CommRing R] → (M : Type v) → [AddCommGroup M] →
      [Module R M] → motive R M [] (nil R M))
    (cons : {R : Type u} → [CommRing R] → {M : Type v} → [AddCommGroup M] →
      [Module R M] → (r : R) → (rs : List R) → (h1 : IsSMulRegular M r) →
      (h2 : IsWeaklyRegular (QuotSMulTop r M)
              (rs.map (Ideal.Quotient.mk (Ideal.span {r})))) →
      (ih : motive (R⧸Ideal.span {r}) (QuotSMulTop r M)
              (rs.map (Ideal.Quotient.mk (Ideal.span {r}))) h2) →
            motive R M (r :: rs) (cons' h1 h2)) :
    {R : Type u} → [CommRing R] → {M : Type v} → [AddCommGroup M] →
    [Module R M] → {rs : List R} → (h : IsWeaklyRegular M rs) → motive R M rs h
  | R, _, M, _, _, [], _ => nil R M
  | _, _, M, _, _, r :: rs, h =>
    let ⟨h1, h2⟩ := (isWeaklyRegular_cons_iff' M r rs).mp h
    cons r rs h1 h2 (recIterModByRegularWithRing nil cons h2)
  termination_by _ _ _ _ _ rs => List.length rs

/-- A simplified version of `IsWeaklyRegular.recIterModByRegularWithRing` where
the motive is not allowed to depend on the proof of `IsWeaklyRegular`. -/
def ndrecWithRing
    {motive : (R : Type u) → [CommRing R] → (M : Type v) →
      [AddCommGroup M] → [Module R M] → (rs : List R) → Sort*}
    (nil : (R : Type u) → [CommRing R] → (M : Type v) →
      [AddCommGroup M] → [Module R M] → motive R M [])
    (cons : {R : Type u} → [CommRing R] → {M : Type v} → [AddCommGroup M] →
      [Module R M] → (r : R) → (rs : List R) → IsSMulRegular M r →
      IsWeaklyRegular (QuotSMulTop r M)
        (rs.map (Ideal.Quotient.mk (Ideal.span {r}))) →
      motive (R⧸Ideal.span {r}) (QuotSMulTop r M)
        (rs.map (Ideal.Quotient.mk (Ideal.span {r}))) → motive R M (r :: rs))
    {R} [CommRing R] {M} [AddCommGroup M] [Module R M] {rs} :
    IsWeaklyRegular M rs → motive R M rs :=
  recIterModByRegularWithRing (motive := fun R _ M _ _ rs _ => motive R M rs)
    nil cons

end IsWeaklyRegular

section

variable (M)

lemma isWeaklyRegular_singleton_iff (r : R) :
    IsWeaklyRegular M [r] ↔ IsSMulRegular M r :=
  Iff.trans (isWeaklyRegular_cons_iff M r []) (and_iff_left (.nil R _))

lemma isWeaklyRegular_append_iff (rs₁ rs₂ : List R) :
    IsWeaklyRegular M (rs₁ ++ rs₂) ↔
      IsWeaklyRegular M rs₁ ∧
        IsWeaklyRegular (M ⧸ (Ideal.ofList rs₁ • ⊤ : Submodule R M)) rs₂ := by
  induction rs₁ generalizing M with
  | nil =>
    refine Iff.symm <| Iff.trans (and_iff_right (.nil R M)) ?_
    refine (quotEquivOfEqBot _ ?_).isWeaklyRegular_congr rs₂
    rw [Ideal.ofList_nil, bot_smul]
  | cons r rs₁ ih =>
    let e := quotOfListConsSMulTopEquivQuotSMulTopInner M r rs₁
    rw [List.cons_append, isWeaklyRegular_cons_iff, isWeaklyRegular_cons_iff,
      ih, ← and_assoc, ← e.isWeaklyRegular_congr rs₂]

lemma isWeaklyRegular_append_iff' (rs₁ rs₂ : List R) :
    IsWeaklyRegular M (rs₁ ++ rs₂) ↔
      IsWeaklyRegular M rs₁ ∧
        IsWeaklyRegular (M ⧸ (Ideal.ofList rs₁ • ⊤ : Submodule R M))
          (rs₂.map (Ideal.Quotient.mk (Ideal.ofList rs₁))) :=
  Iff.trans (isWeaklyRegular_append_iff M rs₁ rs₂) <| and_congr_right' <|
    Iff.symm <| isWeaklyRegular_map_algebraMap_iff (R ⧸ Ideal.ofList rs₁) _ rs₂

end

namespace IsRegular

variable (R M) in
lemma nil [Nontrivial M] : IsRegular M ([] : List R) where
  toIsWeaklyRegular := IsWeaklyRegular.nil R M
  top_ne_smul h := by
    rw [Ideal.ofList_nil, bot_smul, eq_comm, subsingleton_iff_bot_eq_top] at h
    exact not_subsingleton M ((Submodule.subsingleton_iff _).mp h)

lemma cons {r : R} {rs : List R} (h1 : IsSMulRegular M r)
    (h2 : IsRegular (QuotSMulTop r M) rs) : IsRegular M (r :: rs) :=
  (isRegular_cons_iff M r rs).mpr ⟨h1, h2⟩

lemma cons' {r : R} {rs : List R} (h1 : IsSMulRegular M r)
    (h2 : IsRegular (QuotSMulTop r M) (rs.map (Ideal.Quotient.mk (Ideal.span {r})))) :
    IsRegular M (r :: rs) :=
  (isRegular_cons_iff' M r rs).mpr ⟨h1, h2⟩

/-- Regular sequences can be inductively characterized by:
* The empty sequence is regular on any nonzero module.
* If `r` is regular on `M` and `rs` is a regular sequence on `M⧸rM` then the
sequence obtained from `rs` by prepending `r` is regular on `M`.

This is the induction principle produced by the inductive definition above.
The motive will usually be valued in `Prop`, but `Sort*` works too. -/
@[induction_eliminator]
def recIterModByRegular
    {motive : (M : Type v) → [AddCommGroup M] → [Module R M] → (rs : List R) →
      IsRegular M rs → Sort*}
    (nil : (M : Type v) → [AddCommGroup M] → [Module R M] → [Nontrivial M] →
      motive M [] (nil R M))
    (cons : {M : Type v} → [AddCommGroup M] → [Module R M] → (r : R) →
      (rs : List R) → (h1 : IsSMulRegular M r) → (h2 : IsRegular (QuotSMulTop r M) rs) →
      (ih : motive (QuotSMulTop r M) rs h2) → motive M (r :: rs) (cons h1 h2))
    {M} [AddCommGroup M] [Module R M] {rs} (h : IsRegular M rs) : motive M rs h :=
  h.toIsWeaklyRegular.recIterModByRegular
    (motive := fun N _ _ rs' h' => ∀ h'', motive N rs' ⟨h', h''⟩)
    (fun N _ _ h' =>
      haveI := (nontrivial_iff R).mp (nontrivial_of_ne _ _ h'); nil N)
    (fun r rs' h1 h2 h3 h4 =>
      have ⟨h5, h6⟩ := (isRegular_cons_iff _ _ _).mp ⟨h2.cons h1, h4⟩
      cons r rs' h5 h6 (h3 h6.top_ne_smul))
    h.top_ne_smul

/-- A simplified version of `IsRegular.recIterModByRegular` where the motive is
not allowed to depend on the proof of `IsRegular`. -/
def ndrecIterModByRegular
    {motive : (M : Type v) → [AddCommGroup M] → [Module R M] → (rs : List R) → Sort*}
    (nil : (M : Type v) → [AddCommGroup M] → [Module R M] → [Nontrivial M] → motive M [])
    (cons : {M : Type v} → [AddCommGroup M] → [Module R M] → (r : R) →
      (rs : List R) → IsSMulRegular M r → IsRegular (QuotSMulTop r M) rs →
      motive (QuotSMulTop r M) rs → motive M (r :: rs))
    {M} [AddCommGroup M] [Module R M] {rs} : IsRegular M rs → motive M rs :=
  recIterModByRegular (motive := fun M _ _ rs _ => motive M rs) nil cons

/-- An alternate induction principle from `IsRegular.recIterModByRegular` where
we mod out by successive elements in both the module and the base ring. This is
useful for propagating certain properties of the initial `M`, e.g. faithfulness
or freeness, throughout the induction. -/
def recIterModByRegularWithRing
    {motive : (R : Type u) → [CommRing R] → (M : Type v) → [AddCommGroup M] →
      [Module R M] → (rs : List R) → IsRegular M rs → Sort*}
    (nil : (R : Type u) → [CommRing R] → (M : Type v) → [AddCommGroup M] →
      [Module R M] → [Nontrivial M] → motive R M [] (nil R M))
    (cons : {R : Type u} → [CommRing R] → {M : Type v} → [AddCommGroup M] →
      [Module R M] → (r : R) → (rs : List R) → (h1 : IsSMulRegular M r) →
      (h2 : IsRegular (QuotSMulTop r M)
              (rs.map (Ideal.Quotient.mk (Ideal.span {r})))) →
      (ih : motive (R⧸Ideal.span {r}) (QuotSMulTop r M)
              (rs.map (Ideal.Quotient.mk (Ideal.span {r}))) h2) →
            motive R M (r :: rs) (cons' h1 h2))
    {R} [CommRing R] {M} [AddCommGroup M] [Module R M] {rs}
    (h : IsRegular M rs) : motive R M rs h :=
  h.toIsWeaklyRegular.recIterModByRegularWithRing
    (motive := fun R _ N _ _ rs' h' => ∀ h'', motive R N rs' ⟨h', h''⟩)
    (fun R _ N _ _ h' =>
      haveI := (nontrivial_iff R).mp (nontrivial_of_ne _ _ h'); nil R N)
    (fun r rs' h1 h2 h3 h4 =>
      have ⟨h5, h6⟩ := (isRegular_cons_iff' _ _ _).mp ⟨h2.cons' h1, h4⟩
      cons r rs' h5 h6 <| h3 h6.top_ne_smul)
    h.top_ne_smul

/-- A simplified version of `IsRegular.recIterModByRegularWithRing` where the
motive is not allowed to depend on the proof of `IsRegular`. -/
def ndrecIterModByRegularWithRing
    {motive : (R : Type u) → [CommRing R] → (M : Type v) →
      [AddCommGroup M] → [Module R M] → (rs : List R) → Sort*}
    (nil : (R : Type u) → [CommRing R] → (M : Type v) →
      [AddCommGroup M] → [Module R M] → [Nontrivial M] → motive R M [])
    (cons : {R : Type u} → [CommRing R] → {M : Type v} →
      [AddCommGroup M] → [Module R M] → (r : R) → (rs : List R) →
      IsSMulRegular M r →
      IsRegular (QuotSMulTop r M)
        (rs.map (Ideal.Quotient.mk (Ideal.span {r}))) →
      motive (R⧸Ideal.span {r}) (QuotSMulTop r M)
        (rs.map (Ideal.Quotient.mk (Ideal.span {r}))) →
      motive R M (r :: rs))
    {R} [CommRing R] {M} [AddCommGroup M] [Module R M] {rs} :
    IsRegular M rs → motive R M rs :=
  recIterModByRegularWithRing (motive := fun R _ M _ _ rs _ => motive R M rs)
    nil cons

lemma quot_ofList_smul_nontrivial {rs : List R} (h : IsRegular M rs)
    (N : Submodule R M) : Nontrivial (M ⧸ Ideal.ofList rs • N) :=
  Submodule.Quotient.nontrivial_of_lt_top _ <|
    lt_of_le_of_lt (smul_mono_right _ le_top) h.top_ne_smul.symm.lt_top

lemma nontrivial {rs : List R} (h : IsRegular M rs) : Nontrivial M :=
  haveI := quot_ofList_smul_nontrivial h ⊤
  (mkQ_surjective (Ideal.ofList rs • ⊤ : Submodule R M)).nontrivial

end IsRegular

lemma isRegular_iff_isWeaklyRegular_of_subset_jacobson_annihilator
    [Nontrivial M] [Module.Finite R M] {rs : List R}
    (h : ∀ r ∈ rs, r ∈ Ideal.jacobson (Module.annihilator R M)) :
    IsRegular M rs ↔ IsWeaklyRegular M rs :=
  Iff.trans (isRegular_iff M rs) <| and_iff_left <|
    top_ne_ideal_smul_of_le_jacobson_annihilator <| Ideal.span_le.mpr h

lemma _root_.IsLocalRing.isRegular_iff_isWeaklyRegular_of_subset_maximalIdeal
    [IsLocalRing R] [Nontrivial M] [Module.Finite R M] {rs : List R}
    (h : ∀ r ∈ rs, r ∈ IsLocalRing.maximalIdeal R) :
    IsRegular M rs ↔ IsWeaklyRegular M rs :=
  have H h' := bot_ne_top.symm <| annihilator_eq_top_iff.mp <|
    Eq.trans annihilator_top h'
  isRegular_iff_isWeaklyRegular_of_subset_jacobson_annihilator fun r hr =>
    IsLocalRing.jacobson_eq_maximalIdeal (Module.annihilator R M) H ▸ h r hr

open IsWeaklyRegular IsArtinian in
lemma eq_nil_of_isRegular_on_artinian [IsArtinian R M] :
    {rs : List R} → IsRegular M rs → rs = []
  | [], _ => rfl
  | r :: rs, h => by
    rw [isRegular_iff, ne_comm, ← lt_top_iff_ne_top, Ideal.ofList_cons,
      sup_smul, ideal_span_singleton_smul, isWeaklyRegular_cons_iff] at h
    refine absurd ?_ (ne_of_lt (lt_of_le_of_lt le_sup_left h.right))
    exact Eq.trans (Submodule.map_top _) <| LinearMap.range_eq_top.mpr <|
      surjective_of_injective_endomorphism (LinearMap.lsmul R M r) h.left.left

lemma IsWeaklyRegular.isWeaklyRegular_lTensor [Module.Flat R M₂]
    {rs : List R} (h : IsWeaklyRegular M rs) :
    IsWeaklyRegular (M₂ ⊗[R] M) rs := by
  induction h with
  | nil N => exact nil R (M₂ ⊗[R] N)
  | @cons N _ _ r rs' h1 _ ih =>
    let e := tensorQuotSMulTopEquivQuotSMulTop r M₂ N
    exact ((e.isWeaklyRegular_congr rs').mp ih).cons (h1.lTensor M₂)

lemma IsWeaklyRegular.isWeaklyRegular_rTensor [Module.Flat R M₂]
    {rs : List R} (h : IsWeaklyRegular M rs) :
    IsWeaklyRegular (M ⊗[R] M₂) rs := by
  induction h with
  | nil N => exact nil R (N ⊗[R] M₂)
  | @cons N _ _ r rs' h1 _ ih =>
    let e := quotSMulTopTensorEquivQuotSMulTop r M₂ N
    exact ((e.isWeaklyRegular_congr rs').mp ih).cons (h1.rTensor M₂)
-- TODO: apply the above to localization and completion (Corollary 1.1.3 in B&H)

lemma map_first_exact_on_four_term_right_exact_of_isSMulRegular_last
    {rs : List R} {f₁ : M →ₗ[R] M₂} {f₂ : M₂ →ₗ[R] M₃} {f₃ : M₃ →ₗ[R] M₄}
    (h₁₂ : Exact f₁ f₂) (h₂₃ : Exact f₂ f₃) (h₃ : Surjective f₃)
    (h₄ : IsWeaklyRegular M₄ rs) :
    Exact (mapQ _ _ _ (smul_top_le_comap_smul_top (Ideal.ofList rs) f₁))
          (mapQ _ _ _ (smul_top_le_comap_smul_top (Ideal.ofList rs) f₂)) := by
  induction h₄ generalizing M M₂ M₃ with
  | nil =>
    apply (Exact.iff_of_ladder_linearEquiv ?_ ?_).mp h₁₂
    any_goals exact quotEquivOfEqBot _ <|
      Eq.trans (congrArg (· • ⊤) Ideal.ofList_nil) (bot_smul ⊤)
    all_goals exact quot_hom_ext _ _ _ fun _ => rfl
  | cons r rs h₄ _ ih =>
    specialize ih
      (map_first_exact_on_four_term_exact_of_isSMulRegular_last h₁₂ h₂₃ h₄)
      (map_exact r h₂₃ h₃) (map_surjective r h₃)
    have H₁ := quotOfListConsSMulTopEquivQuotSMulTopInner_naturality r rs f₁
    have H₂ := quotOfListConsSMulTopEquivQuotSMulTopInner_naturality r rs f₂
    exact (Exact.iff_of_ladder_linearEquiv H₁.symm H₂.symm).mp ih

-- todo: modding out a complex by a regular sequence (prop 1.1.5 in B&H)

section Perm

open LinearMap in
private lemma IsWeaklyRegular.swap {a b : R} (h1 : IsWeaklyRegular M [a, b])
    (h2 : torsionBy R M b = a • torsionBy R M b → torsionBy R M b = ⊥) :
    IsWeaklyRegular M [b, a] := by
  rw [isWeaklyRegular_cons_iff, isWeaklyRegular_singleton_iff] at h1 ⊢
  obtain ⟨ha, hb⟩ := h1
  rw [← isSMulRegular_iff_torsionBy_eq_bot] at h2
  specialize h2 (le_antisymm ?_ (smul_le_self_of_tower a (torsionBy R M b)))
  · refine le_of_eq_of_le ?_ <| smul_top_inf_eq_smul_of_isSMulRegular_on_quot <|
      ha.of_injective _ <| ker_eq_bot.mp <| ker_liftQ_eq_bot' _ (lsmul R M b) rfl
    rw [← (isSMulRegular_on_quot_iff_lsmul_comap_eq _ _).mp hb]
    exact (inf_eq_right.mpr (ker_le_comap _)).symm
  · rwa [ha.isSMulRegular_on_quot_iff_smul_top_inf_eq_smul, inf_comm, smul_comm,
      ← h2.isSMulRegular_on_quot_iff_smul_top_inf_eq_smul, and_iff_left hb]

-- TODO: Equivalence of permutability of regular sequences to regularity of
-- subsequences and regularity on poly ring. See [07DW] in stacks project
-- We need a theory of multivariate polynomial modules first

-- This is needed due to a bug in the linter
set_option linter.unusedVariables false in
lemma IsWeaklyRegular.prototype_perm {rs : List R} (h : IsWeaklyRegular M rs)
    {rs'} (h'' : rs ~ rs') (h' : ∀ a b rs', (a :: b :: rs') <+~ rs →
      let K := torsionBy R (M ⧸ (Ideal.ofList rs' • ⊤ : Submodule R M)) b
      K = a • K → K = ⊥) : IsWeaklyRegular M rs' :=
  have H := LinearEquiv.isWeaklyRegular_congr <| quotEquivOfEqBot _ <|
    Eq.trans (congrArg (· • ⊤) Ideal.ofList_nil) (bot_smul ⊤)
  (H rs').mp <| (aux [] h'' (.refl rs) (h''.symm.subperm)) <| (H rs).mpr h
  where aux {rs₁ rs₂} (rs₀ : List R)
    (h₁₂ : rs₁ ~ rs₂) (H₁ : rs₀ ++ rs₁ <+~ rs) (H₃ : rs₀ ++ rs₂ <+~ rs)
    (h : IsWeaklyRegular (M ⧸ (Ideal.ofList rs₀ • ⊤ : Submodule R M)) rs₁) :
    IsWeaklyRegular (M ⧸ (Ideal.ofList rs₀ • ⊤ : Submodule R M)) rs₂ := by {
  induction h₁₂ generalizing rs₀ with
  | nil => exact .nil R _
  | cons r _ ih =>
    let e := quotOfListConsSMulTopEquivQuotSMulTopOuter M r rs₀
    rw [isWeaklyRegular_cons_iff, ← e.isWeaklyRegular_congr] at h ⊢
    refine h.imp_right (ih (r :: rs₀) ?_ ?_) <;>
      exact List.perm_middle.subperm_right.mp ‹_›
  | swap a b t =>
    rw [show ∀ x y z, x :: y :: z = [x, y] ++ z from fun _ _ _ => rfl,
      isWeaklyRegular_append_iff] at h ⊢
    have : Ideal.ofList [b, a] = Ideal.ofList [a, b] :=
      congrArg Ideal.span <| Set.ext fun _ => (List.Perm.swap a b []).mem_iff
    rw [(quotEquivOfEq _ _ (congrArg₂ _ this rfl)).isWeaklyRegular_congr] at h
    rw [List.append_cons, List.append_cons, List.append_assoc _ [b] [a]] at H₁
    apply (List.sublist_append_left (rs₀ ++ [b, a]) _).subperm.trans at H₁
    apply List.perm_append_comm.subperm.trans at H₁
    exact h.imp_left (swap · (h' b a rs₀ H₁))
  | trans h₁₂ _ ih₁₂ ih₂₃ =>
    have H₂ := (h₁₂.append_left rs₀).subperm_right.mp H₁
    exact ih₂₃ rs₀ H₂ H₃ (ih₁₂ rs₀ H₁ H₂ h) }

-- putting `{rs' : List R}` and `h2` after `h3` would be better for partial
-- application, but this argument order seems nicer overall
lemma IsWeaklyRegular.of_perm_of_subset_jacobson_annihilator [IsNoetherian R M]
    {rs rs' : List R} (h1 : IsWeaklyRegular M rs) (h2 : List.Perm rs rs')
    (h3 : ∀ r ∈ rs, r ∈ (Module.annihilator R M).jacobson) :
    IsWeaklyRegular M rs' :=
  h1.prototype_perm h2 fun r _ _ h h' =>
    eq_bot_of_eq_pointwise_smul_of_mem_jacobson_annihilator
      (IsNoetherian.noetherian _) h'
      (Ideal.jacobson_mono
        (le_trans
          -- The named argument `(R := R)` below isn't necessary, but
          -- typechecking is much slower without it
          (LinearMap.annihilator_le_of_surjective (R := R) _ (mkQ_surjective _))
          (LinearMap.annihilator_le_of_injective _ (injective_subtype _)))
        (h3 r (h.subset List.mem_cons_self)))

end Perm

lemma IsRegular.of_perm_of_subset_jacobson_annihilator [IsNoetherian R M]
    {rs rs' : List R} (h1 : IsRegular M rs) (h2 : List.Perm rs rs')
    (h3 : ∀ r ∈ rs, r ∈ (Module.annihilator R M).jacobson) : IsRegular M rs' :=
  ⟨h1.toIsWeaklyRegular.of_perm_of_subset_jacobson_annihilator h2 h3,
    letI := h1.nontrivial
    top_ne_ideal_smul_of_le_jacobson_annihilator <|
      Ideal.span_le.mpr (h3 · <| h2.mem_iff.mpr ·)⟩

lemma _root_.IsLocalRing.isWeaklyRegular_of_perm_of_subset_maximalIdeal
    [IsLocalRing R] [IsNoetherian R M] {rs rs' : List R}
    (h1 : IsWeaklyRegular M rs) (h2 : List.Perm rs rs')
    (h3 : ∀ r ∈ rs, r ∈ IsLocalRing.maximalIdeal R) : IsWeaklyRegular M rs' :=
  IsWeaklyRegular.of_perm_of_subset_jacobson_annihilator h1 h2 fun r hr =>
    IsLocalRing.maximalIdeal_le_jacobson _ (h3 r hr)

lemma _root_.IsLocalRing.isRegular_of_perm [IsLocalRing R] [IsNoetherian R M]
    {rs rs' : List R} (h1 : IsRegular M rs) (h2 : List.Perm rs rs') :
    IsRegular M rs' := by
  obtain ⟨h3, h4⟩ := h1
  refine ⟨IsLocalRing.isWeaklyRegular_of_perm_of_subset_maximalIdeal h3 h2 ?_, ?_⟩
  · intro x (h6 : x ∈ { r | r ∈ rs })
    refine IsLocalRing.le_maximalIdeal ?_ (Ideal.subset_span h6)
    exact h4 ∘ Eq.trans (top_smul _).symm ∘ Eq.symm ∘ congrArg (· • ⊤)
  · refine ne_of_ne_of_eq h4 (congrArg (Ideal.span · • ⊤) ?_)
    exact Set.ext fun _ => h2.mem_iff

@[deprecated (since := "2024-11-09")]
alias _root_.LocalRing.isRegular_of_perm := _root_.IsLocalRing.isRegular_of_perm

end RingTheory.Sequence
