/-
Copyright (c) 2021 Oliver Nash. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Oliver Nash
-/
import Mathlib.Algebra.Lie.Subalgebra
import Mathlib.LinearAlgebra.Finsupp.Span

/-!
# Lie submodules of a Lie algebra

In this file we define Lie submodules and Lie ideals, we construct the lattice structure on Lie
submodules and we use it to define various important operations, notably the Lie span of a subset
of a Lie module.

## Main definitions

  * `LieSubmodule`
  * `LieSubmodule.wellFounded_of_noetherian`
  * `LieSubmodule.lieSpan`
  * `LieSubmodule.map`
  * `LieSubmodule.comap`
  * `LieIdeal`
  * `LieIdeal.map`
  * `LieIdeal.comap`

## Tags

lie algebra, lie submodule, lie ideal, lattice structure
-/


universe u v w w₁ w₂

section LieSubmodule

variable (R : Type u) (L : Type v) (M : Type w)
variable [CommRing R] [LieRing L] [AddCommGroup M] [Module R M]
variable [LieRingModule L M]

/-- A Lie submodule of a Lie module is a submodule that is closed under the Lie bracket.
This is a sufficient condition for the subset itself to form a Lie module. -/
structure LieSubmodule extends Submodule R M where
  lie_mem : ∀ {x : L} {m : M}, m ∈ carrier → ⁅x, m⁆ ∈ carrier

attribute [nolint docBlame] LieSubmodule.toSubmodule
attribute [coe] LieSubmodule.toSubmodule

namespace LieSubmodule

variable {R L M}
variable (N N' : LieSubmodule R L M)

instance : SetLike (LieSubmodule R L M) M where
  coe s := s.carrier
  coe_injective' N O h := by cases N; cases O; congr; exact SetLike.coe_injective' h

instance : AddSubgroupClass (LieSubmodule R L M) M where
  add_mem {N} _ _ := N.add_mem'
  zero_mem N := N.zero_mem'
  neg_mem {N} x hx := show -x ∈ N.toSubmodule from neg_mem hx

instance instSMulMemClass : SMulMemClass (LieSubmodule R L M) R M where
  smul_mem {s} c _ h := s.smul_mem'  c h

/-- The zero module is a Lie submodule of any Lie module. -/
instance : Zero (LieSubmodule R L M) :=
  ⟨{ (0 : Submodule R M) with
      lie_mem := fun {x m} h ↦ by rw [(Submodule.mem_bot R).1 h]; apply lie_zero }⟩

instance : Inhabited (LieSubmodule R L M) :=
  ⟨0⟩

instance (priority := high) coeSort : CoeSort (LieSubmodule R L M) (Type w) where
  coe N := { x : M // x ∈ N }

instance (priority := mid) coeSubmodule : CoeOut (LieSubmodule R L M) (Submodule R M) :=
  ⟨toSubmodule⟩

instance : CanLift (Submodule R M) (LieSubmodule R L M) (·)
    (fun N ↦ ∀ {x : L} {m : M}, m ∈ N → ⁅x, m⁆ ∈ N) where
  prf N hN := ⟨⟨N, hN⟩, rfl⟩

@[norm_cast]
theorem coe_toSubmodule : ((N : Submodule R M) : Set M) = N :=
  rfl

theorem mem_carrier {x : M} : x ∈ N.carrier ↔ x ∈ (N : Set M) :=
  Iff.rfl

theorem mem_mk_iff (S : Set M) (h₁ h₂ h₃ h₄) {x : M} :
    x ∈ (⟨⟨⟨⟨S, h₁⟩, h₂⟩, h₃⟩, h₄⟩ : LieSubmodule R L M) ↔ x ∈ S :=
  Iff.rfl

@[simp]
theorem mem_mk_iff' (p : Submodule R M) (h) {x : M} :
    x ∈ (⟨p, h⟩ : LieSubmodule R L M) ↔ x ∈ p :=
  Iff.rfl

@[simp]
theorem mem_toSubmodule {x : M} : x ∈ (N : Submodule R M) ↔ x ∈ N :=
  Iff.rfl

@[deprecated (since := "2024-12-30")] alias mem_coeSubmodule := mem_toSubmodule

theorem mem_coe {x : M} : x ∈ (N : Set M) ↔ x ∈ N :=
  Iff.rfl

@[simp]
protected theorem zero_mem : (0 : M) ∈ N :=
  zero_mem N

@[simp]
theorem mk_eq_zero {x} (h : x ∈ N) : (⟨x, h⟩ : N) = 0 ↔ x = 0 :=
  Subtype.ext_iff_val

@[simp]
theorem coe_toSet_mk (S : Set M) (h₁ h₂ h₃ h₄) :
    ((⟨⟨⟨⟨S, h₁⟩, h₂⟩, h₃⟩, h₄⟩ : LieSubmodule R L M) : Set M) = S :=
  rfl

theorem toSubmodule_mk (p : Submodule R M) (h) :
    (({ p with lie_mem := h } : LieSubmodule R L M) : Submodule R M) = p := by cases p; rfl

@[deprecated (since := "2024-12-30")] alias coe_toSubmodule_mk := toSubmodule_mk

theorem toSubmodule_injective :
    Function.Injective (toSubmodule : LieSubmodule R L M → Submodule R M) := fun x y h ↦ by
  cases x; cases y; congr

@[deprecated (since := "2024-12-30")] alias coeSubmodule_injective := toSubmodule_injective

@[ext]
theorem ext (h : ∀ m, m ∈ N ↔ m ∈ N') : N = N' :=
  SetLike.ext h

@[simp]
theorem toSubmodule_inj : (N : Submodule R M) = (N' : Submodule R M) ↔ N = N' :=
  toSubmodule_injective.eq_iff

@[deprecated (since := "2024-12-30")] alias coe_toSubmodule_inj := toSubmodule_inj

@[deprecated (since := "2024-12-29")] alias toSubmodule_eq_iff := toSubmodule_inj

/-- Copy of a `LieSubmodule` with a new `carrier` equal to the old one. Useful to fix definitional
equalities. -/
protected def copy (s : Set M) (hs : s = ↑N) : LieSubmodule R L M where
  carrier := s
  zero_mem' := by simp [hs]
  add_mem' x y := by rw [hs] at x y ⊢; exact N.add_mem' x y
  smul_mem' := by exact hs.symm ▸ N.smul_mem'
  lie_mem := by exact hs.symm ▸ N.lie_mem

@[simp]
theorem coe_copy (S : LieSubmodule R L M) (s : Set M) (hs : s = ↑S) : (S.copy s hs : Set M) = s :=
  rfl

theorem copy_eq (S : LieSubmodule R L M) (s : Set M) (hs : s = ↑S) : S.copy s hs = S :=
  SetLike.coe_injective hs

instance : LieRingModule L N where
  bracket (x : L) (m : N) := ⟨⁅x, m.val⁆, N.lie_mem m.property⟩
  add_lie := by intro x y m; apply SetCoe.ext; apply add_lie
  lie_add := by intro x m n; apply SetCoe.ext; apply lie_add
  leibniz_lie := by intro x y m; apply SetCoe.ext; apply leibniz_lie

@[simp, norm_cast]
theorem coe_zero : ((0 : N) : M) = (0 : M) :=
  rfl

@[simp, norm_cast]
theorem coe_add (m m' : N) : (↑(m + m') : M) = (m : M) + (m' : M) :=
  rfl

@[simp, norm_cast]
theorem coe_neg (m : N) : (↑(-m) : M) = -(m : M) :=
  rfl

@[simp, norm_cast]
theorem coe_sub (m m' : N) : (↑(m - m') : M) = (m : M) - (m' : M) :=
  rfl

@[simp, norm_cast]
theorem coe_smul (t : R) (m : N) : (↑(t • m) : M) = t • (m : M) :=
  rfl

@[simp, norm_cast]
theorem coe_bracket (x : L) (m : N) :
    (↑⁅x, m⁆ : M) = ⁅x, ↑m⁆ :=
  rfl

-- Copying instances from `Submodule` for correct discrimination keys
instance [IsNoetherian R M] (N : LieSubmodule R L M) : IsNoetherian R N :=
  inferInstanceAs <| IsNoetherian R N.toSubmodule

instance [IsArtinian R M] (N : LieSubmodule R L M) : IsArtinian R N :=
  inferInstanceAs <| IsArtinian R N.toSubmodule

instance [NoZeroSMulDivisors R M] : NoZeroSMulDivisors R N :=
  inferInstanceAs <| NoZeroSMulDivisors R N.toSubmodule

variable [LieAlgebra R L] [LieModule R L M]

instance instLieModule : LieModule R L N where
  lie_smul := by intro t x y; apply SetCoe.ext; apply lie_smul
  smul_lie := by intro t x y; apply SetCoe.ext; apply smul_lie

instance [Subsingleton M] : Unique (LieSubmodule R L M) :=
  ⟨⟨0⟩, fun _ ↦ (toSubmodule_inj _ _).mp (Subsingleton.elim _ _)⟩

end LieSubmodule

section LieIdeal
variable [LieAlgebra R L] [LieModule R L M]

/-- An ideal of a Lie algebra is a Lie submodule of the Lie algebra as a Lie module over itself. -/
abbrev LieIdeal :=
  LieSubmodule R L L

theorem lie_mem_right (I : LieIdeal R L) (x y : L) (h : y ∈ I) : ⁅x, y⁆ ∈ I :=
  I.lie_mem h

theorem lie_mem_left (I : LieIdeal R L) (x y : L) (h : x ∈ I) : ⁅x, y⁆ ∈ I := by
  rw [← lie_skew, ← neg_lie]; apply lie_mem_right; assumption

/-- An ideal of a Lie algebra is a Lie subalgebra. -/
def LieIdeal.toLieSubalgebra (I : LieIdeal R L) : LieSubalgebra R L :=
  { I.toSubmodule with lie_mem' := by intro x y _ hy; apply lie_mem_right; exact hy }

@[deprecated (since := "2025-01-02")] alias lieIdealSubalgebra := LieIdeal.toLieSubalgebra

instance : Coe (LieIdeal R L) (LieSubalgebra R L) :=
  ⟨LieIdeal.toLieSubalgebra R L⟩

@[simp]
theorem LieIdeal.coe_toLieSubalgebra (I : LieIdeal R L) : ((I : LieSubalgebra R L) : Set L) = I :=
  rfl

@[deprecated (since := "2024-12-30")]
alias LieIdeal.coe_toSubalgebra := LieIdeal.coe_toLieSubalgebra

@[simp]
theorem LieIdeal.toLieSubalgebra_toSubmodule (I : LieIdeal R L) :
    ((I : LieSubalgebra R L) : Submodule R L) = LieSubmodule.toSubmodule I :=
  rfl

@[deprecated (since := "2025-01-02")]
alias LieIdeal.coe_toLieSubalgebra_toSubmodule := LieIdeal.toLieSubalgebra_toSubmodule

@[deprecated (since := "2024-12-30")]
alias LieIdeal.coe_to_lieSubalgebra_to_submodule := LieIdeal.toLieSubalgebra_toSubmodule

/-- An ideal of `L` is a Lie subalgebra of `L`, so it is a Lie ring. -/
instance LieIdeal.lieRing (I : LieIdeal R L) : LieRing I :=
  LieSubalgebra.lieRing R L ↑I

/-- Transfer the `LieAlgebra` instance from the coercion `LieIdeal → LieSubalgebra`. -/
instance LieIdeal.lieAlgebra (I : LieIdeal R L) : LieAlgebra R I :=
  LieSubalgebra.lieAlgebra R L ↑I

/-- Transfer the `LieRingModule` instance from the coercion `LieIdeal → LieSubalgebra`. -/
instance LieIdeal.lieRingModule {R L : Type*} [CommRing R] [LieRing L] [LieAlgebra R L]
    (I : LieIdeal R L) [LieRingModule L M] : LieRingModule I M :=
  LieSubalgebra.lieRingModule (I : LieSubalgebra R L)

@[simp]
theorem LieIdeal.coe_bracket_of_module {R L : Type*} [CommRing R] [LieRing L] [LieAlgebra R L]
    (I : LieIdeal R L) [LieRingModule L M] (x : I) (m : M) :
    ⁅x, m⁆ = ⁅(↑x : L), m⁆ :=
  LieSubalgebra.coe_bracket_of_module (I : LieSubalgebra R L) x m

/-- Transfer the `LieModule` instance from the coercion `LieIdeal → LieSubalgebra`. -/
instance LieIdeal.lieModule (I : LieIdeal R L) : LieModule R I M :=
  LieSubalgebra.lieModule (I : LieSubalgebra R L)

instance (I : LieIdeal R L) : IsLieTower I L M where
  leibniz_lie x y m := leibniz_lie x.val y m

instance (I : LieIdeal R L) : IsLieTower L I M where
  leibniz_lie x y m := leibniz_lie x y.val m

end LieIdeal

variable {R M}

theorem Submodule.exists_lieSubmodule_coe_eq_iff (p : Submodule R M) :
    (∃ N : LieSubmodule R L M, ↑N = p) ↔ ∀ (x : L) (m : M), m ∈ p → ⁅x, m⁆ ∈ p := by
  constructor
  · rintro ⟨N, rfl⟩ _ _; exact N.lie_mem
  · intro h; use { p with lie_mem := @h }

namespace LieSubalgebra

variable {L}
variable [LieAlgebra R L]
variable (K : LieSubalgebra R L)

/-- Given a Lie subalgebra `K ⊆ L`, if we view `L` as a `K`-module by restriction, it contains
a distinguished Lie submodule for the action of `K`, namely `K` itself. -/
def toLieSubmodule : LieSubmodule R K L :=
  { (K : Submodule R L) with lie_mem := fun {x _} hy ↦ K.lie_mem x.property hy }

@[simp]
theorem coe_toLieSubmodule : (K.toLieSubmodule : Submodule R L) = K := rfl

variable {K}

@[simp]
theorem mem_toLieSubmodule (x : L) : x ∈ K.toLieSubmodule ↔ x ∈ K :=
  Iff.rfl

theorem exists_lieIdeal_coe_eq_iff :
    (∃ I : LieIdeal R L, ↑I = K) ↔ ∀ x y : L, y ∈ K → ⁅x, y⁆ ∈ K := by
  simp only [← toSubmodule_inj, LieIdeal.toLieSubalgebra_toSubmodule,
    Submodule.exists_lieSubmodule_coe_eq_iff L]
  exact Iff.rfl

theorem exists_nested_lieIdeal_coe_eq_iff {K' : LieSubalgebra R L} (h : K ≤ K') :
    (∃ I : LieIdeal R K', ↑I = ofLe h) ↔ ∀ x y : L, x ∈ K' → y ∈ K → ⁅x, y⁆ ∈ K := by
  simp only [exists_lieIdeal_coe_eq_iff, coe_bracket, mem_ofLe]
  constructor
  · intro h' x y hx hy; exact h' ⟨x, hx⟩ ⟨y, h hy⟩ hy
  · rintro h' ⟨x, hx⟩ ⟨y, hy⟩ hy'; exact h' x y hx hy'

end LieSubalgebra

end LieSubmodule

namespace LieSubmodule

variable {R : Type u} {L : Type v} {M : Type w}
variable [CommRing R] [LieRing L] [AddCommGroup M] [Module R M]
variable [LieRingModule L M]
variable (N N' : LieSubmodule R L M)

section LatticeStructure

open Set

theorem coe_injective : Function.Injective ((↑) : LieSubmodule R L M → Set M) :=
  SetLike.coe_injective

@[simp, norm_cast]
theorem toSubmodule_le_toSubmodule : (N : Submodule R M) ≤ N' ↔ N ≤ N' :=
  Iff.rfl

@[deprecated (since := "2024-12-30")]
alias coeSubmodule_le_coeSubmodule := toSubmodule_le_toSubmodule

instance : Bot (LieSubmodule R L M) :=
  ⟨0⟩

instance instUniqueBot : Unique (⊥ : LieSubmodule R L M) :=
  inferInstanceAs <| Unique (⊥ : Submodule R M)

@[simp]
theorem bot_coe : ((⊥ : LieSubmodule R L M) : Set M) = {0} :=
  rfl

@[simp]
theorem bot_toSubmodule : ((⊥ : LieSubmodule R L M) : Submodule R M) = ⊥ :=
  rfl

@[deprecated (since := "2024-12-30")] alias bot_coeSubmodule := bot_toSubmodule

@[simp]
theorem toSubmodule_eq_bot : (N : Submodule R M) = ⊥ ↔ N = ⊥ := by
  rw [← toSubmodule_inj, bot_toSubmodule]

@[deprecated (since := "2024-12-30")] alias coeSubmodule_eq_bot_iff := toSubmodule_eq_bot

@[simp] theorem mk_eq_bot_iff {N : Submodule R M} {h} :
    (⟨N, h⟩ : LieSubmodule R L M) = ⊥ ↔ N = ⊥ := by
  rw [← toSubmodule_inj, bot_toSubmodule]

@[simp]
theorem mem_bot (x : M) : x ∈ (⊥ : LieSubmodule R L M) ↔ x = 0 :=
  mem_singleton_iff

instance : Top (LieSubmodule R L M) :=
  ⟨{ (⊤ : Submodule R M) with lie_mem := fun {x m} _ ↦ mem_univ ⁅x, m⁆ }⟩

@[simp]
theorem top_coe : ((⊤ : LieSubmodule R L M) : Set M) = univ :=
  rfl

@[simp]
theorem top_toSubmodule : ((⊤ : LieSubmodule R L M) : Submodule R M) = ⊤ :=
  rfl

@[deprecated (since := "2024-12-30")] alias top_coeSubmodule := top_toSubmodule

@[simp]
theorem toSubmodule_eq_top : (N : Submodule R M) = ⊤ ↔ N = ⊤ := by
  rw [← toSubmodule_inj, top_toSubmodule]

@[deprecated (since := "2024-12-30")] alias coeSubmodule_eq_top_iff := toSubmodule_eq_top

@[simp] theorem mk_eq_top_iff {N : Submodule R M} {h} :
    (⟨N, h⟩ : LieSubmodule R L M) = ⊤ ↔ N = ⊤ := by
  rw [← toSubmodule_inj, top_toSubmodule]

@[simp]
theorem mem_top (x : M) : x ∈ (⊤ : LieSubmodule R L M) :=
  mem_univ x

instance : Min (LieSubmodule R L M) :=
  ⟨fun N N' ↦
    { (N ⊓ N' : Submodule R M) with
      lie_mem := fun h ↦ mem_inter (N.lie_mem h.1) (N'.lie_mem h.2) }⟩

instance : InfSet (LieSubmodule R L M) :=
  ⟨fun S ↦
    { toSubmodule := sInf {(s : Submodule R M) | s ∈ S}
      lie_mem := fun {x m} h ↦ by
        simp only [Submodule.mem_carrier, mem_iInter, Submodule.sInf_coe, mem_setOf_eq,
          forall_apply_eq_imp_iff₂, forall_exists_index, and_imp] at h ⊢
        intro N hN; apply N.lie_mem (h N hN) }⟩

@[simp]
theorem inf_coe : (↑(N ⊓ N') : Set M) = ↑N ∩ ↑N' :=
  rfl

@[norm_cast, simp]
theorem inf_toSubmodule :
    (↑(N ⊓ N') : Submodule R M) = (N : Submodule R M) ⊓ (N' : Submodule R M) :=
  rfl

@[deprecated (since := "2024-12-30")] alias inf_coe_toSubmodule := inf_toSubmodule

@[simp]
theorem sInf_toSubmodule (S : Set (LieSubmodule R L M)) :
    (↑(sInf S) : Submodule R M) = sInf {(s : Submodule R M) | s ∈ S} :=
  rfl

@[deprecated (since := "2024-12-30")] alias sInf_coe_toSubmodule := sInf_toSubmodule

theorem sInf_toSubmodule_eq_iInf (S : Set (LieSubmodule R L M)) :
    (↑(sInf S) : Submodule R M) = ⨅ N ∈ S, (N : Submodule R M) := by
  rw [sInf_toSubmodule, ← Set.image, sInf_image]

@[deprecated (since := "2024-12-30")] alias sInf_coe_toSubmodule' := sInf_toSubmodule_eq_iInf

@[simp]
theorem iInf_toSubmodule {ι} (p : ι → LieSubmodule R L M) :
    (↑(⨅ i, p i) : Submodule R M) = ⨅ i, (p i : Submodule R M) := by
  rw [iInf, sInf_toSubmodule]; ext; simp

@[deprecated (since := "2024-12-30")] alias iInf_coe_toSubmodule := iInf_toSubmodule

@[simp]
theorem sInf_coe (S : Set (LieSubmodule R L M)) : (↑(sInf S) : Set M) = ⋂ s ∈ S, (s : Set M) := by
  rw [← LieSubmodule.coe_toSubmodule, sInf_toSubmodule, Submodule.sInf_coe]
  ext m
  simp only [mem_iInter, mem_setOf_eq, forall_apply_eq_imp_iff₂, exists_imp,
    and_imp, SetLike.mem_coe, mem_toSubmodule]

@[simp]
theorem iInf_coe {ι} (p : ι → LieSubmodule R L M) : (↑(⨅ i, p i) : Set M) = ⋂ i, ↑(p i) := by
  rw [iInf, sInf_coe]; simp only [Set.mem_range, Set.iInter_exists, Set.iInter_iInter_eq']

@[simp]
theorem mem_iInf {ι} (p : ι → LieSubmodule R L M) {x} : (x ∈ ⨅ i, p i) ↔ ∀ i, x ∈ p i := by
  rw [← SetLike.mem_coe, iInf_coe, Set.mem_iInter]; rfl

instance : Max (LieSubmodule R L M) where
  max N N' :=
    { toSubmodule := (N : Submodule R M) ⊔ (N' : Submodule R M)
      lie_mem := by
        rintro x m (hm : m ∈ (N : Submodule R M) ⊔ (N' : Submodule R M))
        change ⁅x, m⁆ ∈ (N : Submodule R M) ⊔ (N' : Submodule R M)
        rw [Submodule.mem_sup] at hm ⊢
        obtain ⟨y, hy, z, hz, rfl⟩ := hm
        exact ⟨⁅x, y⁆, N.lie_mem hy, ⁅x, z⁆, N'.lie_mem hz, (lie_add _ _ _).symm⟩ }

instance : SupSet (LieSubmodule R L M) where
  sSup S :=
    { toSubmodule := sSup {(p : Submodule R M) | p ∈ S}
      lie_mem := by
        intro x m (hm : m ∈ sSup {(p : Submodule R M) | p ∈ S})
        change ⁅x, m⁆ ∈ sSup {(p : Submodule R M) | p ∈ S}
        obtain ⟨s, hs, hsm⟩ := Submodule.mem_sSup_iff_exists_finset.mp hm
        clear hm
        classical
        induction s using Finset.induction_on generalizing m with
        | empty =>
          replace hsm : m = 0 := by simpa using hsm
          simp [hsm]
        | insert hqt ih =>
          rename_i q t
          rw [Finset.iSup_insert] at hsm
          obtain ⟨m', hm', u, hu, rfl⟩ := Submodule.mem_sup.mp hsm
          rw [lie_add]
          refine add_mem ?_ (ih (Subset.trans (by simp) hs) hu)
          obtain ⟨p, hp, rfl⟩ : ∃ p ∈ S, ↑p = q := hs (Finset.mem_insert_self q t)
          suffices p ≤ sSup {(p : Submodule R M) | p ∈ S} by exact this (p.lie_mem hm')
          exact le_sSup ⟨p, hp, rfl⟩ }

@[norm_cast, simp]
theorem sup_toSubmodule :
    (↑(N ⊔ N') : Submodule R M) = (N : Submodule R M) ⊔ (N' : Submodule R M) := by
  rfl

@[deprecated (since := "2024-12-30")] alias sup_coe_toSubmodule := sup_toSubmodule

@[simp]
theorem sSup_toSubmodule (S : Set (LieSubmodule R L M)) :
    (↑(sSup S) : Submodule R M) = sSup {(s : Submodule R M) | s ∈ S} :=
  rfl

@[deprecated (since := "2024-12-30")] alias sSup_coe_toSubmodule := sSup_toSubmodule

theorem sSup_toSubmodule_eq_iSup (S : Set (LieSubmodule R L M)) :
    (↑(sSup S) : Submodule R M) = ⨆ N ∈ S, (N : Submodule R M) := by
  rw [sSup_toSubmodule, ← Set.image, sSup_image]

@[deprecated (since := "2024-12-30")] alias sSup_coe_toSubmodule' := sSup_toSubmodule_eq_iSup

@[simp]
theorem iSup_toSubmodule {ι} (p : ι → LieSubmodule R L M) :
    (↑(⨆ i, p i) : Submodule R M) = ⨆ i, (p i : Submodule R M) := by
  rw [iSup, sSup_toSubmodule]; ext; simp [Submodule.mem_sSup, Submodule.mem_iSup]

@[deprecated (since := "2024-12-30")] alias iSup_coe_toSubmodule := iSup_toSubmodule

/-- The set of Lie submodules of a Lie module form a complete lattice. -/
instance : CompleteLattice (LieSubmodule R L M) :=
  { toSubmodule_injective.completeLattice toSubmodule sup_toSubmodule inf_toSubmodule
      sSup_toSubmodule_eq_iSup sInf_toSubmodule_eq_iInf rfl rfl with
    toPartialOrder := SetLike.instPartialOrder }

theorem mem_iSup_of_mem {ι} {b : M} {N : ι → LieSubmodule R L M} (i : ι) (h : b ∈ N i) :
    b ∈ ⨆ i, N i :=
  (le_iSup N i) h

@[elab_as_elim]
lemma iSup_induction {ι} (N : ι → LieSubmodule R L M) {motive : M → Prop} {x : M}
    (hx : x ∈ ⨆ i, N i) (mem : ∀ i, ∀ y ∈ N i, motive y) (zero : motive 0)
    (add : ∀ y z, motive y → motive z → motive (y + z)) : motive x := by
  rw [← LieSubmodule.mem_toSubmodule, LieSubmodule.iSup_toSubmodule] at hx
  exact Submodule.iSup_induction (motive := motive) (fun i ↦ (N i : Submodule R M)) hx mem zero add

@[elab_as_elim]
theorem iSup_induction' {ι} (N : ι → LieSubmodule R L M) {motive : (x : M) → (x ∈ ⨆ i, N i) → Prop}
    (mem : ∀ (i) (x) (hx : x ∈ N i), motive x (mem_iSup_of_mem i hx)) (zero : motive 0 (zero_mem _))
    (add : ∀ x y hx hy, motive x hx → motive y hy → motive (x + y) (add_mem ‹_› ‹_›)) {x : M}
    (hx : x ∈ ⨆ i, N i) : motive x hx := by
  refine Exists.elim ?_ fun (hx : x ∈ ⨆ i, N i) (hc : motive x hx) => hc
  refine iSup_induction N (motive := fun x : M ↦ ∃ (hx : x ∈ ⨆ i, N i), motive x hx) hx
    (fun i x hx => ?_) ?_ fun x y => ?_
  · exact ⟨_, mem _ _ hx⟩
  · exact ⟨_, zero⟩
  · rintro ⟨_, Cx⟩ ⟨_, Cy⟩
    exact ⟨_, add _ _ _ _ Cx Cy⟩

-- TODO(Yaël): turn around
theorem disjoint_iff_toSubmodule :
    Disjoint N N' ↔ Disjoint (N : Submodule R M) (N' : Submodule R M) := by
  rw [disjoint_iff, disjoint_iff, ← toSubmodule_inj, inf_toSubmodule, bot_toSubmodule,
    ← disjoint_iff]

@[deprecated (since := "2024-12-30")] alias disjoint_iff_coe_toSubmodule := disjoint_iff_toSubmodule

theorem codisjoint_iff_toSubmodule :
    Codisjoint N N' ↔ Codisjoint (N : Submodule R M) (N' : Submodule R M) := by
  rw [codisjoint_iff, codisjoint_iff, ← toSubmodule_inj, sup_toSubmodule,
    top_toSubmodule, ← codisjoint_iff]

@[deprecated (since := "2024-12-30")]
alias codisjoint_iff_coe_toSubmodule := codisjoint_iff_toSubmodule

theorem isCompl_iff_toSubmodule :
    IsCompl N N' ↔ IsCompl (N : Submodule R M) (N' : Submodule R M) := by
  simp only [isCompl_iff, disjoint_iff_toSubmodule, codisjoint_iff_toSubmodule]

@[deprecated (since := "2024-12-30")] alias isCompl_iff_coe_toSubmodule := isCompl_iff_toSubmodule

theorem iSupIndep_iff_toSubmodule {ι : Type*} {N : ι → LieSubmodule R L M} :
    iSupIndep N ↔ iSupIndep fun i ↦ (N i : Submodule R M) := by
  simp [iSupIndep_def, disjoint_iff_toSubmodule]

@[deprecated (since := "2024-12-30")]
alias iSupIndep_iff_coe_toSubmodule := iSupIndep_iff_toSubmodule

@[deprecated (since := "2024-11-24")]
alias independent_iff_toSubmodule := iSupIndep_iff_toSubmodule

@[deprecated (since := "2024-12-30")]
alias independent_iff_coe_toSubmodule := independent_iff_toSubmodule

theorem iSup_eq_top_iff_toSubmodule {ι : Sort*} {N : ι → LieSubmodule R L M} :
    ⨆ i, N i = ⊤ ↔ ⨆ i, (N i : Submodule R M) = ⊤ := by
  rw [← iSup_toSubmodule, ← top_toSubmodule (L := L), toSubmodule_inj]

@[deprecated (since := "2024-12-30")]
alias iSup_eq_top_iff_coe_toSubmodule := iSup_eq_top_iff_toSubmodule

instance : Add (LieSubmodule R L M) where add := max

instance : Zero (LieSubmodule R L M) where zero := ⊥

instance : AddCommMonoid (LieSubmodule R L M) where
  add_assoc := sup_assoc
  zero_add := bot_sup_eq
  add_zero := sup_bot_eq
  add_comm := sup_comm
  nsmul := nsmulRec

@[simp]
theorem add_eq_sup : N + N' = N ⊔ N' :=
  rfl

@[simp]
theorem mem_inf (x : M) : x ∈ N ⊓ N' ↔ x ∈ N ∧ x ∈ N' := by
  rw [← mem_toSubmodule, ← mem_toSubmodule, ← mem_toSubmodule, inf_toSubmodule,
    Submodule.mem_inf]

theorem mem_sup (x : M) : x ∈ N ⊔ N' ↔ ∃ y ∈ N, ∃ z ∈ N', y + z = x := by
  rw [← mem_toSubmodule, sup_toSubmodule, Submodule.mem_sup]; exact Iff.rfl

nonrec theorem eq_bot_iff : N = ⊥ ↔ ∀ m : M, m ∈ N → m = 0 := by rw [eq_bot_iff]; exact Iff.rfl

instance subsingleton_of_bot : Subsingleton (LieSubmodule R L (⊥ : LieSubmodule R L M)) := by
  apply subsingleton_of_bot_eq_top
  ext ⟨_, hx⟩
  simp only [mem_bot, mk_eq_zero, mem_top, iff_true]
  exact hx

instance : IsModularLattice (LieSubmodule R L M) where
  sup_inf_le_assoc_of_le _ _ := by
    simp only [← toSubmodule_le_toSubmodule, sup_toSubmodule, inf_toSubmodule]
    exact IsModularLattice.sup_inf_le_assoc_of_le _

variable (R L M)

/-- The natural functor that forgets the action of `L` as an order embedding. -/
@[simps] def toSubmodule_orderEmbedding : LieSubmodule R L M ↪o Submodule R M :=
  { toFun := (↑)
    inj' := toSubmodule_injective
    map_rel_iff' := Iff.rfl }

instance wellFoundedGT_of_noetherian [IsNoetherian R M] : WellFoundedGT (LieSubmodule R L M) :=
  RelHomClass.isWellFounded (toSubmodule_orderEmbedding R L M).dual.ltEmbedding

theorem wellFoundedLT_of_isArtinian [IsArtinian R M] : WellFoundedLT (LieSubmodule R L M) :=
  RelHomClass.isWellFounded (toSubmodule_orderEmbedding R L M).ltEmbedding

instance [IsArtinian R M] : IsAtomic (LieSubmodule R L M) :=
  isAtomic_of_orderBot_wellFounded_lt <| (wellFoundedLT_of_isArtinian R L M).wf

@[simp]
theorem subsingleton_iff : Subsingleton (LieSubmodule R L M) ↔ Subsingleton M :=
  have h : Subsingleton (LieSubmodule R L M) ↔ Subsingleton (Submodule R M) := by
    rw [← subsingleton_iff_bot_eq_top, ← subsingleton_iff_bot_eq_top, ← toSubmodule_inj,
      top_toSubmodule, bot_toSubmodule]
  h.trans <| Submodule.subsingleton_iff R

@[simp]
theorem nontrivial_iff : Nontrivial (LieSubmodule R L M) ↔ Nontrivial M :=
  not_iff_not.mp
    ((not_nontrivial_iff_subsingleton.trans <| subsingleton_iff R L M).trans
      not_nontrivial_iff_subsingleton.symm)

instance [Nontrivial M] : Nontrivial (LieSubmodule R L M) :=
  (nontrivial_iff R L M).mpr ‹_›

theorem nontrivial_iff_ne_bot {N : LieSubmodule R L M} : Nontrivial N ↔ N ≠ ⊥ := by
  constructor <;> contrapose!
  · rintro rfl
      ⟨⟨m₁, h₁ : m₁ ∈ (⊥ : LieSubmodule R L M)⟩, ⟨m₂, h₂ : m₂ ∈ (⊥ : LieSubmodule R L M)⟩, h₁₂⟩
    simp [(LieSubmodule.mem_bot _).mp h₁, (LieSubmodule.mem_bot _).mp h₂] at h₁₂
  · rw [not_nontrivial_iff_subsingleton, LieSubmodule.eq_bot_iff]
    rintro ⟨h⟩ m hm
    simpa using h ⟨m, hm⟩ ⟨_, N.zero_mem⟩

variable {R L M}

section InclusionMaps

/-- The inclusion of a Lie submodule into its ambient space is a morphism of Lie modules. -/
def incl : N →ₗ⁅R,L⁆ M :=
  { Submodule.subtype (N : Submodule R M) with map_lie' := fun {_ _} ↦ rfl }

@[simp]
theorem incl_coe : (N.incl : N →ₗ[R] M) = (N : Submodule R M).subtype :=
  rfl

@[simp]
theorem incl_apply (m : N) : N.incl m = m :=
  rfl

theorem incl_eq_val : (N.incl : N → M) = Subtype.val :=
  rfl

theorem injective_incl : Function.Injective N.incl := Subtype.coe_injective

variable {N N'}
variable (h : N ≤ N')

/-- Given two nested Lie submodules `N ⊆ N'`,
the inclusion `N ↪ N'` is a morphism of Lie modules. -/
def inclusion : N →ₗ⁅R,L⁆ N' where
  __ := Submodule.inclusion (show N.toSubmodule ≤ N'.toSubmodule from h)
  map_lie' := rfl

@[simp]
theorem coe_inclusion (m : N) : (inclusion h m : M) = m :=
  rfl

theorem inclusion_apply (m : N) : inclusion h m = ⟨m.1, h m.2⟩ :=
  rfl

theorem inclusion_injective : Function.Injective (inclusion h) := fun x y ↦ by
  simp only [inclusion_apply, imp_self, Subtype.mk_eq_mk, SetLike.coe_eq_coe]

end InclusionMaps

section LieSpan

variable (R L) (s : Set M)

/-- The `lieSpan` of a set `s ⊆ M` is the smallest Lie submodule of `M` that contains `s`. -/
def lieSpan : LieSubmodule R L M :=
  sInf { N | s ⊆ N }

variable {R L s}

theorem mem_lieSpan {x : M} : x ∈ lieSpan R L s ↔ ∀ N : LieSubmodule R L M, s ⊆ N → x ∈ N := by
  rw [← SetLike.mem_coe, lieSpan, sInf_coe]
  exact mem_iInter₂

theorem subset_lieSpan : s ⊆ lieSpan R L s := by
  intro m hm
  rw [SetLike.mem_coe, mem_lieSpan]
  intro N hN
  exact hN hm

theorem submodule_span_le_lieSpan : Submodule.span R s ≤ lieSpan R L s := by
  rw [Submodule.span_le]
  apply subset_lieSpan

@[simp]
theorem lieSpan_le {N} : lieSpan R L s ≤ N ↔ s ⊆ N := by
  constructor
  · exact Subset.trans subset_lieSpan
  · intro hs m hm; rw [mem_lieSpan] at hm; exact hm _ hs

theorem lieSpan_mono {t : Set M} (h : s ⊆ t) : lieSpan R L s ≤ lieSpan R L t := by
  rw [lieSpan_le]
  exact Subset.trans h subset_lieSpan

theorem lieSpan_eq (N : LieSubmodule R L M) : lieSpan R L (N : Set M) = N :=
  le_antisymm (lieSpan_le.mpr rfl.subset) subset_lieSpan

theorem coe_lieSpan_submodule_eq_iff {p : Submodule R M} :
    (lieSpan R L (p : Set M) : Submodule R M) = p ↔ ∃ N : LieSubmodule R L M, ↑N = p := by
  rw [p.exists_lieSubmodule_coe_eq_iff L]; constructor <;> intro h
  · intro x m hm; rw [← h, mem_toSubmodule]; exact lie_mem _ (subset_lieSpan hm)
  · rw [← toSubmodule_mk p @h, coe_toSubmodule, toSubmodule_inj, lieSpan_eq]

variable (R L M)

/-- `lieSpan` forms a Galois insertion with the coercion from `LieSubmodule` to `Set`. -/
protected def gi : GaloisInsertion (lieSpan R L : Set M → LieSubmodule R L M) (↑) where
  choice s _ := lieSpan R L s
  gc _ _ := lieSpan_le
  le_l_u _ := subset_lieSpan
  choice_eq _ _ := rfl

@[simp]
theorem span_empty : lieSpan R L (∅ : Set M) = ⊥ :=
  (LieSubmodule.gi R L M).gc.l_bot

@[simp]
theorem span_univ : lieSpan R L (Set.univ : Set M) = ⊤ :=
  eq_top_iff.2 <| SetLike.le_def.2 <| subset_lieSpan

theorem lieSpan_eq_bot_iff : lieSpan R L s = ⊥ ↔ ∀ m ∈ s, m = (0 : M) := by
  rw [_root_.eq_bot_iff, lieSpan_le, bot_coe, subset_singleton_iff]

variable {M}

theorem span_union (s t : Set M) : lieSpan R L (s ∪ t) = lieSpan R L s ⊔ lieSpan R L t :=
  (LieSubmodule.gi R L M).gc.l_sup

theorem span_iUnion {ι} (s : ι → Set M) : lieSpan R L (⋃ i, s i) = ⨆ i, lieSpan R L (s i) :=
  (LieSubmodule.gi R L M).gc.l_iSup

lemma isCompactElement_lieSpan_singleton (m : M) :
    CompleteLattice.IsCompactElement (lieSpan R L {m}) := by
  rw [CompleteLattice.isCompactElement_iff_le_of_directed_sSup_le]
  intro s hne hdir hsup
  replace hsup : m ∈ (↑(sSup s) : Set M) := (SetLike.le_def.mp hsup) (subset_lieSpan rfl)
  suffices (↑(sSup s) : Set M) = ⋃ N ∈ s, ↑N by
    obtain ⟨N : LieSubmodule R L M, hN : N ∈ s, hN' : m ∈ N⟩ := by
      simp_rw [this, Set.mem_iUnion, SetLike.mem_coe, exists_prop] at hsup; assumption
    exact ⟨N, hN, by simpa⟩
  replace hne : Nonempty s := Set.nonempty_coe_sort.mpr hne
  have := Submodule.coe_iSup_of_directed _ hdir.directed_val
  simp_rw [← iSup_toSubmodule, Set.iUnion_coe_set, coe_toSubmodule] at this
  rw [← this, SetLike.coe_set_eq, sSup_eq_iSup, iSup_subtype]

@[simp]
lemma sSup_image_lieSpan_singleton : sSup ((fun x ↦ lieSpan R L {x}) '' N) = N := by
  refine le_antisymm (sSup_le <| by simp) ?_
  simp_rw [← toSubmodule_le_toSubmodule, sSup_toSubmodule, Set.mem_image, SetLike.mem_coe]
  refine fun m hm ↦ Submodule.mem_sSup.mpr fun N' hN' ↦ ?_
  replace hN' : ∀ m ∈ N, lieSpan R L {m} ≤ N' := by simpa using hN'
  exact hN' _ hm (subset_lieSpan rfl)

instance instIsCompactlyGenerated : IsCompactlyGenerated (LieSubmodule R L M) :=
  ⟨fun N ↦ ⟨(fun x ↦ lieSpan R L {x}) '' N, fun _ ⟨m, _, hm⟩ ↦
    hm ▸ isCompactElement_lieSpan_singleton R L m, N.sSup_image_lieSpan_singleton⟩⟩

end LieSpan

end LatticeStructure

end LieSubmodule

section LieSubmoduleMapAndComap

variable {R : Type u} {L : Type v} {L' : Type w₂} {M : Type w} {M' : Type w₁}
variable [CommRing R] [LieRing L] [LieRing L'] [LieAlgebra R L']
variable [AddCommGroup M] [Module R M] [LieRingModule L M]
variable [AddCommGroup M'] [Module R M'] [LieRingModule L M']

namespace LieSubmodule

variable (f : M →ₗ⁅R,L⁆ M') (N N₂ : LieSubmodule R L M) (N' : LieSubmodule R L M')

/-- A morphism of Lie modules `f : M → M'` pushes forward Lie submodules of `M` to Lie submodules
of `M'`. -/
def map : LieSubmodule R L M' :=
  { (N : Submodule R M).map (f : M →ₗ[R] M') with
    lie_mem := fun {x m'} h ↦ by
      rcases h with ⟨m, hm, hfm⟩; use ⁅x, m⁆; constructor
      · apply N.lie_mem hm
      · norm_cast at hfm; simp [hfm] }

@[simp] theorem coe_map : (N.map f : Set M') = f '' N := rfl

@[simp]
theorem toSubmodule_map : (N.map f : Submodule R M') = (N : Submodule R M).map (f : M →ₗ[R] M') :=
  rfl

@[deprecated (since := "2024-12-30")] alias coeSubmodule_map := toSubmodule_map

/-- A morphism of Lie modules `f : M → M'` pulls back Lie submodules of `M'` to Lie submodules of
`M`. -/
def comap : LieSubmodule R L M :=
  { (N' : Submodule R M').comap (f : M →ₗ[R] M') with
    lie_mem := fun {x m} h ↦ by
      suffices ⁅x, f m⁆ ∈ N' by simp [this]
      apply N'.lie_mem h }

@[simp]
theorem toSubmodule_comap :
    (N'.comap f : Submodule R M) = (N' : Submodule R M').comap (f : M →ₗ[R] M') :=
  rfl

@[deprecated (since := "2024-12-30")] alias coeSubmodule_comap := toSubmodule_comap

variable {f N N₂ N'}

theorem map_le_iff_le_comap : map f N ≤ N' ↔ N ≤ comap f N' :=
  Set.image_subset_iff

variable (f) in
theorem gc_map_comap : GaloisConnection (map f) (comap f) := fun _ _ ↦ map_le_iff_le_comap

theorem map_inf_le : (N ⊓ N₂).map f ≤ N.map f ⊓ N₂.map f :=
  Set.image_inter_subset f N N₂

theorem map_inf (hf : Function.Injective f) :
    (N ⊓ N₂).map f = N.map f ⊓ N₂.map f :=
  SetLike.coe_injective <| Set.image_inter hf

@[simp]
theorem map_sup : (N ⊔ N₂).map f = N.map f ⊔ N₂.map f :=
  (gc_map_comap f).l_sup

@[simp]
theorem comap_inf {N₂' : LieSubmodule R L M'} :
    (N' ⊓ N₂').comap f = N'.comap f ⊓ N₂'.comap f :=
  rfl

@[simp]
theorem map_iSup {ι : Sort*} (N : ι → LieSubmodule R L M) :
    (⨆ i, N i).map f = ⨆ i, (N i).map f :=
  (gc_map_comap f : GaloisConnection (map f) (comap f)).l_iSup

@[simp]
theorem mem_map (m' : M') : m' ∈ N.map f ↔ ∃ m, m ∈ N ∧ f m = m' :=
  Submodule.mem_map

theorem mem_map_of_mem {m : M} (h : m ∈ N) : f m ∈ N.map f :=
  Set.mem_image_of_mem _ h

@[simp]
theorem mem_comap {m : M} : m ∈ comap f N' ↔ f m ∈ N' :=
  Iff.rfl

theorem comap_incl_eq_top : N₂.comap N.incl = ⊤ ↔ N ≤ N₂ := by
  rw [← LieSubmodule.toSubmodule_inj, LieSubmodule.toSubmodule_comap, LieSubmodule.incl_coe,
    LieSubmodule.top_toSubmodule, Submodule.comap_subtype_eq_top, toSubmodule_le_toSubmodule]

theorem comap_incl_eq_bot : N₂.comap N.incl = ⊥ ↔ N ⊓ N₂ = ⊥ := by
  simp only [← toSubmodule_inj, toSubmodule_comap, incl_coe, bot_toSubmodule,
    inf_toSubmodule]
  rw [← Submodule.disjoint_iff_comap_eq_bot, disjoint_iff]

@[gcongr, mono]
theorem map_mono (h : N ≤ N₂) : N.map f ≤ N₂.map f :=
  Set.image_subset _ h

theorem map_comp
    {M'' : Type*} [AddCommGroup M''] [Module R M''] [LieRingModule L M''] {g : M' →ₗ⁅R,L⁆ M''} :
    N.map (g.comp f) = (N.map f).map g :=
  SetLike.coe_injective <| by
    simp only [← Set.image_comp, coe_map, LinearMap.coe_comp, LieModuleHom.coe_comp]

@[simp]
theorem map_id : N.map LieModuleHom.id = N := by ext; simp

@[simp] theorem map_bot :
    (⊥ : LieSubmodule R L M).map f = ⊥ := by
  ext m; simp [eq_comm]

lemma map_le_map_iff (hf : Function.Injective f) :
    N.map f ≤ N₂.map f ↔ N ≤ N₂ :=
  Set.image_subset_image_iff hf

lemma map_injective_of_injective (hf : Function.Injective f) :
    Function.Injective (map f) := fun {N N'} h ↦
  SetLike.coe_injective <| hf.image_injective <| by simp only [← coe_map, h]

/-- An injective morphism of Lie modules embeds the lattice of submodules of the domain into that
of the target. -/
@[simps] def mapOrderEmbedding {f : M →ₗ⁅R,L⁆ M'} (hf : Function.Injective f) :
  LieSubmodule R L M ↪o LieSubmodule R L M' where
    toFun := LieSubmodule.map f
    inj' := map_injective_of_injective hf
    map_rel_iff' := Set.image_subset_image_iff hf

variable (N) in
/-- For an injective morphism of Lie modules, any Lie submodule is equivalent to its image. -/
noncomputable def equivMapOfInjective (hf : Function.Injective f) :
    N ≃ₗ⁅R,L⁆ N.map f :=
  { Submodule.equivMapOfInjective (f : M →ₗ[R] M') hf N with
    -- Note: https://github.com/leanprover-community/mathlib4/pull/8386 had to specify `invFun` explicitly this way, otherwise we'd get a type mismatch
    invFun := by exact DFunLike.coe (Submodule.equivMapOfInjective (f : M →ₗ[R] M') hf N).symm
    map_lie' := by rintro x ⟨m, hm : m ∈ N⟩; ext; exact f.map_lie x m }

/-- An equivalence of Lie modules yields an order-preserving equivalence of their lattices of Lie
Submodules. -/
@[simps] def orderIsoMapComap (e : M ≃ₗ⁅R,L⁆ M') :
    LieSubmodule R L M ≃o LieSubmodule R L M' where
  toFun := map e
  invFun := comap e
  left_inv := fun N ↦ by ext; simp
  right_inv := fun N ↦ by ext; simp [e.apply_eq_iff_eq_symm_apply]
  map_rel_iff' := fun {_ _} ↦ Set.image_subset_image_iff e.injective

end LieSubmodule

namespace LieIdeal
variable [LieAlgebra R L] [LieModule R L M] [LieModule R L M']

variable (f : L →ₗ⁅R⁆ L') (I I₂ : LieIdeal R L) (J : LieIdeal R L')

@[simp]
theorem top_toLieSubalgebra : ((⊤ : LieIdeal R L) : LieSubalgebra R L) = ⊤ :=
  rfl

@[deprecated (since := "2024-12-30")] alias top_coe_lieSubalgebra := top_toLieSubalgebra

/-- A morphism of Lie algebras `f : L → L'` pushes forward Lie ideals of `L` to Lie ideals of `L'`.

Note that unlike `LieSubmodule.map`, we must take the `lieSpan` of the image. Mathematically
this is because although `f` makes `L'` into a Lie module over `L`, in general the `L` submodules of
`L'` are not the same as the ideals of `L'`. -/
def map : LieIdeal R L' :=
  LieSubmodule.lieSpan R L' <| (I : Submodule R L).map (f : L →ₗ[R] L')

/-- A morphism of Lie algebras `f : L → L'` pulls back Lie ideals of `L'` to Lie ideals of `L`.

Note that `f` makes `L'` into a Lie module over `L` (turning `f` into a morphism of Lie modules)
and so this is a special case of `LieSubmodule.comap` but we do not exploit this fact. -/
def comap : LieIdeal R L :=
  { (J : Submodule R L').comap (f : L →ₗ[R] L') with
    lie_mem := fun {x y} h ↦ by
      suffices ⁅f x, f y⁆ ∈ J by
        simp only [AddSubsemigroup.mem_carrier, AddSubmonoid.mem_toSubsemigroup,
          Submodule.mem_toAddSubmonoid, Submodule.mem_comap, LieHom.coe_toLinearMap, LieHom.map_lie,
          LieSubalgebra.mem_toSubmodule]
        exact this
      apply J.lie_mem h }

@[simp]
theorem map_toSubmodule (h : ↑(map f I) = f '' I) :
    LieSubmodule.toSubmodule (map f I) = (LieSubmodule.toSubmodule I).map (f : L →ₗ[R] L') := by
  rw [SetLike.ext'_iff, LieSubmodule.coe_toSubmodule, h, Submodule.map_coe]; rfl

@[deprecated (since := "2024-12-30")] alias map_coeSubmodule := map_toSubmodule

@[simp]
theorem comap_toSubmodule :
    (LieSubmodule.toSubmodule (comap f J)) = (LieSubmodule.toSubmodule J).comap (f : L →ₗ[R] L') :=
  rfl

@[deprecated (since := "2024-12-30")] alias comap_coeSubmodule := comap_toSubmodule

theorem map_le : map f I ≤ J ↔ f '' I ⊆ J :=
  LieSubmodule.lieSpan_le

variable {f I I₂ J}

theorem mem_map {x : L} (hx : x ∈ I) : f x ∈ map f I := by
  apply LieSubmodule.subset_lieSpan
  use x
  exact ⟨hx, rfl⟩

@[simp]
theorem mem_comap {x : L} : x ∈ comap f J ↔ f x ∈ J :=
  Iff.rfl

theorem map_le_iff_le_comap : map f I ≤ J ↔ I ≤ comap f J := by
  rw [map_le]
  exact Set.image_subset_iff

variable (f) in
theorem gc_map_comap : GaloisConnection (map f) (comap f) := fun _ _ ↦ map_le_iff_le_comap

@[simp]
theorem map_sup : (I ⊔ I₂).map f = I.map f ⊔ I₂.map f :=
  (gc_map_comap f).l_sup

theorem map_comap_le : map f (comap f J) ≤ J := by rw [map_le_iff_le_comap]

/-- See also `LieIdeal.map_comap_eq`. -/
theorem comap_map_le : I ≤ comap f (map f I) := by rw [← map_le_iff_le_comap]

@[mono]
theorem map_mono : Monotone (map f) := fun I₁ I₂ h ↦ by
  rw [SetLike.le_def] at h
  apply LieSubmodule.lieSpan_mono (Set.image_subset (⇑f) h)

@[mono]
theorem comap_mono : Monotone (comap f) := fun J₁ J₂ h ↦ by
  rw [← SetLike.coe_subset_coe] at h ⊢
  dsimp only [SetLike.coe]
  exact Set.preimage_mono h

theorem map_of_image (h : f '' I = J) : I.map f = J := by
  apply le_antisymm
  · rw [map, LieSubmodule.lieSpan_le, Submodule.map_coe]
    /- I'm uncertain how to best resolve this `erw`.
    ```
    have : (↑(toLieSubalgebra R L I).toSubmodule : Set L) = I := rfl
    rw [this]
    simp [h]
    ```
    works, but still feels awkward. There are missing `simp` lemmas here.`
    -/
    erw [h]
  · rw [← SetLike.coe_subset_coe, ← h]; exact LieSubmodule.subset_lieSpan

/-- Note that this is not a special case of `LieSubmodule.subsingleton_of_bot`. Indeed, given
`I : LieIdeal R L`, in general the two lattices `LieIdeal R I` and `LieSubmodule R L I` are
different (though the latter does naturally inject into the former).

In other words, in general, ideals of `I`, regarded as a Lie algebra in its own right, are not the
same as ideals of `L` contained in `I`. -/
instance subsingleton_of_bot : Subsingleton (LieIdeal R (⊥ : LieIdeal R L)) := by
  apply subsingleton_of_bot_eq_top
  ext ⟨x, hx⟩
  rw [LieSubmodule.mem_bot] at hx
  subst hx
  simp only [LieSubmodule.mk_eq_zero, LieSubmodule.mem_bot, LieSubmodule.mem_top]

end LieIdeal

namespace LieHom
variable [LieAlgebra R L] [LieModule R L M] [LieModule R L M']
variable (f : L →ₗ⁅R⁆ L') (I : LieIdeal R L) (J : LieIdeal R L')

/-- The kernel of a morphism of Lie algebras, as an ideal in the domain. -/
def ker : LieIdeal R L :=
  LieIdeal.comap f ⊥

/-- The range of a morphism of Lie algebras as an ideal in the codomain. -/
def idealRange : LieIdeal R L' :=
  LieSubmodule.lieSpan R L' f.range

theorem idealRange_eq_lieSpan_range : f.idealRange = LieSubmodule.lieSpan R L' f.range :=
  rfl

theorem idealRange_eq_map : f.idealRange = LieIdeal.map f ⊤ := by
  ext
  simp only [idealRange, range_eq_map]
  rfl

/-- The condition that the range of a morphism of Lie algebras is an ideal. -/
def IsIdealMorphism : Prop :=
  (f.idealRange : LieSubalgebra R L') = f.range

@[simp]
theorem isIdealMorphism_def : f.IsIdealMorphism ↔ (f.idealRange : LieSubalgebra R L') = f.range :=
  Iff.rfl

variable {f} in
theorem IsIdealMorphism.eq (hf : f.IsIdealMorphism) : f.idealRange = f.range := hf

theorem isIdealMorphism_iff : f.IsIdealMorphism ↔ ∀ (x : L') (y : L), ∃ z : L, ⁅x, f y⁆ = f z := by
  simp only [isIdealMorphism_def, idealRange_eq_lieSpan_range, ←
    LieSubalgebra.toSubmodule_inj, ← f.range.coe_toSubmodule,
    LieIdeal.toLieSubalgebra_toSubmodule, LieSubmodule.coe_lieSpan_submodule_eq_iff,
    LieSubalgebra.mem_toSubmodule, mem_range, exists_imp,
    Submodule.exists_lieSubmodule_coe_eq_iff]
  constructor
  · intro h x y; obtain ⟨z, hz⟩ := h x (f y) y rfl; use z; exact hz.symm
  · intro h x y z hz; obtain ⟨w, hw⟩ := h x z; use w; rw [← hw, hz]

theorem range_subset_idealRange : (f.range : Set L') ⊆ f.idealRange :=
  LieSubmodule.subset_lieSpan

theorem map_le_idealRange : I.map f ≤ f.idealRange := by
  rw [f.idealRange_eq_map]
  exact LieIdeal.map_mono le_top

theorem ker_le_comap : f.ker ≤ J.comap f :=
  LieIdeal.comap_mono bot_le

@[simp]
theorem ker_toSubmodule : LieSubmodule.toSubmodule (ker f) = LinearMap.ker (f : L →ₗ[R] L') :=
  rfl

@[deprecated (since := "2024-12-30")] alias ker_coeSubmodule := ker_toSubmodule

variable {f} in
@[simp]
theorem mem_ker {x : L} : x ∈ ker f ↔ f x = 0 :=
  show x ∈ LieSubmodule.toSubmodule (f.ker) ↔ _ by
    simp only [ker_toSubmodule, LinearMap.mem_ker, coe_toLinearMap]

theorem mem_idealRange (x : L) : f x ∈ idealRange f := by
  rw [idealRange_eq_map]
  exact LieIdeal.mem_map (LieSubmodule.mem_top x)

@[simp]
theorem mem_idealRange_iff (h : IsIdealMorphism f) {y : L'} :
    y ∈ idealRange f ↔ ∃ x : L, f x = y := by
  rw [f.isIdealMorphism_def] at h
  rw [← LieSubmodule.mem_coe, ← LieIdeal.coe_toLieSubalgebra, h, f.range_coe, Set.mem_range]

theorem le_ker_iff : I ≤ f.ker ↔ ∀ x, x ∈ I → f x = 0 := by
  constructor <;> intro h x hx
  · specialize h hx; rw [mem_ker] at h; exact h
  · rw [mem_ker]; apply h x hx

theorem ker_eq_bot : f.ker = ⊥ ↔ Function.Injective f := by
  rw [← LieSubmodule.toSubmodule_inj, ker_toSubmodule, LieSubmodule.bot_toSubmodule,
    LinearMap.ker_eq_bot, coe_toLinearMap]

@[simp]
theorem range_toSubmodule : (f.range : Submodule R L') = LinearMap.range (f : L →ₗ[R] L') :=
  rfl

@[deprecated (since := "2024-12-30")] alias range_coeSubmodule := range_toSubmodule

theorem range_eq_top : f.range = ⊤ ↔ Function.Surjective f := by
  rw [← LieSubalgebra.toSubmodule_inj, range_toSubmodule, LieSubalgebra.top_toSubmodule]
  exact LinearMap.range_eq_top

@[simp]
theorem idealRange_eq_top_of_surjective (h : Function.Surjective f) : f.idealRange = ⊤ := by
  rw [← f.range_eq_top] at h
  rw [idealRange_eq_lieSpan_range, h, ← LieSubalgebra.coe_toSubmodule, ←
    LieSubmodule.toSubmodule_inj, LieSubmodule.top_toSubmodule,
    LieSubalgebra.top_toSubmodule, LieSubmodule.coe_lieSpan_submodule_eq_iff]
  use ⊤
  exact LieSubmodule.top_toSubmodule

theorem isIdealMorphism_of_surjective (h : Function.Surjective f) : f.IsIdealMorphism := by
  rw [isIdealMorphism_def, f.idealRange_eq_top_of_surjective h, f.range_eq_top.mpr h,
    LieIdeal.top_toLieSubalgebra]

end LieHom

namespace LieIdeal
variable [LieAlgebra R L] [LieModule R L M] [LieModule R L M']
variable {f : L →ₗ⁅R⁆ L'} {I : LieIdeal R L} {J : LieIdeal R L'}

@[simp]
theorem map_eq_bot_iff : I.map f = ⊥ ↔ I ≤ f.ker := by
  rw [← le_bot_iff]
  exact LieIdeal.map_le_iff_le_comap

theorem coe_map_of_surjective (h : Function.Surjective f) :
    LieSubmodule.toSubmodule (I.map f) = (LieSubmodule.toSubmodule I).map (f : L →ₗ[R] L') := by
  let J : LieIdeal R L' :=
    { (I : Submodule R L).map (f : L →ₗ[R] L') with
      lie_mem := fun {x y} hy ↦ by
        have hy' : ∃ x : L, x ∈ I ∧ f x = y := by simpa [hy]
        obtain ⟨z₂, hz₂, rfl⟩ := hy'
        obtain ⟨z₁, rfl⟩ := h x
        simp only [LieHom.coe_toLinearMap, SetLike.mem_coe, Set.mem_image,
          LieSubmodule.mem_toSubmodule, Submodule.mem_carrier, Submodule.map_coe]
        use ⁅z₁, z₂⁆
        exact ⟨I.lie_mem hz₂, f.map_lie z₁ z₂⟩ }
  rw [map, toLieSubalgebra_toSubmodule, LieSubmodule.coe_lieSpan_submodule_eq_iff]
  exact ⟨J, rfl⟩

theorem mem_map_of_surjective {y : L'} (h₁ : Function.Surjective f) (h₂ : y ∈ I.map f) :
    ∃ x : I, f x = y := by
  rw [← LieSubmodule.mem_toSubmodule, coe_map_of_surjective h₁, Submodule.mem_map] at h₂
  obtain ⟨x, hx, rfl⟩ := h₂
  use ⟨x, hx⟩
  rw [LieHom.coe_toLinearMap]

theorem bot_of_map_eq_bot {I : LieIdeal R L} (h₁ : Function.Injective f) (h₂ : I.map f = ⊥) :
    I = ⊥ := by
  rw [← f.ker_eq_bot, LieHom.ker] at h₁
  rw [eq_bot_iff, map_le_iff_le_comap, h₁] at h₂
  rw [eq_bot_iff]; exact h₂

/-- Given two nested Lie ideals `I₁ ⊆ I₂`, the inclusion `I₁ ↪ I₂` is a morphism of Lie algebras. -/
def inclusion {I₁ I₂ : LieIdeal R L} (h : I₁ ≤ I₂) : I₁ →ₗ⁅R⁆ I₂ where
  __ := Submodule.inclusion (show I₁.toSubmodule ≤ I₂.toSubmodule from h)
  map_lie' := rfl

@[simp]
theorem coe_inclusion {I₁ I₂ : LieIdeal R L} (h : I₁ ≤ I₂) (x : I₁) : (inclusion h x : L) = x :=
  rfl

theorem inclusion_apply {I₁ I₂ : LieIdeal R L} (h : I₁ ≤ I₂) (x : I₁) :
    inclusion h x = ⟨x.1, h x.2⟩ :=
  rfl

theorem inclusion_injective {I₁ I₂ : LieIdeal R L} (h : I₁ ≤ I₂) :
    Function.Injective (inclusion h) :=
  fun x y ↦ by
  simp only [inclusion_apply, imp_self, Subtype.mk_eq_mk, SetLike.coe_eq_coe]

theorem map_sup_ker_eq_map : LieIdeal.map f (I ⊔ f.ker) = LieIdeal.map f I := by
  suffices LieIdeal.map f (I ⊔ f.ker) ≤ LieIdeal.map f I by
    exact le_antisymm this (LieIdeal.map_mono le_sup_left)
  apply LieSubmodule.lieSpan_mono
  rintro x ⟨y, hy₁, hy₂⟩
  rw [← hy₂]
  erw [LieSubmodule.mem_sup] at hy₁
  obtain ⟨z₁, hz₁, z₂, hz₂, hy⟩ := hy₁
  rw [← hy]
  rw [f.coe_toLinearMap, f.map_add, LieHom.mem_ker.mp hz₂, add_zero]; exact ⟨z₁, hz₁, rfl⟩

@[simp]
theorem map_sup_ker_eq_map' :
    LieIdeal.map f I ⊔ LieIdeal.map f (LieHom.ker f) = LieIdeal.map f I := by
  simpa using map_sup_ker_eq_map (f := f)

@[simp]
theorem map_comap_eq (h : f.IsIdealMorphism) : map f (comap f J) = f.idealRange ⊓ J := by
  apply le_antisymm
  · rw [le_inf_iff]; exact ⟨f.map_le_idealRange _, map_comap_le⟩
  · rw [f.isIdealMorphism_def] at h
    rw [← SetLike.coe_subset_coe, LieSubmodule.inf_coe, ← coe_toLieSubalgebra, h]
    rintro y ⟨⟨x, h₁⟩, h₂⟩; rw [← h₁] at h₂ ⊢; exact mem_map h₂

@[simp]
theorem comap_map_eq (h : ↑(map f I) = f '' I) : comap f (map f I) = I ⊔ f.ker := by
  rw [← LieSubmodule.toSubmodule_inj, comap_toSubmodule, I.map_toSubmodule f h,
    LieSubmodule.sup_toSubmodule, f.ker_toSubmodule, Submodule.comap_map_eq]

variable (f I J)

/-- Regarding an ideal `I` as a subalgebra, the inclusion map into its ambient space is a morphism
of Lie algebras. -/
def incl : I →ₗ⁅R⁆ L :=
  (I : LieSubalgebra R L).incl

@[simp]
theorem incl_range : I.incl.range = I :=
  (I : LieSubalgebra R L).incl_range

@[simp]
theorem incl_apply (x : I) : I.incl x = x :=
  rfl

@[simp]
theorem incl_coe : (I.incl.toLinearMap : I →ₗ[R] L) = (I : Submodule R L).subtype :=
  rfl

lemma incl_injective (I : LieIdeal R L) : Function.Injective I.incl :=
  Subtype.val_injective

@[simp]
theorem comap_incl_self : comap I.incl I = ⊤ := by ext; simp

@[simp]
theorem ker_incl : I.incl.ker = ⊥ := by ext; simp

@[simp]
theorem incl_idealRange : I.incl.idealRange = I := by
  rw [LieHom.idealRange_eq_lieSpan_range, ← LieSubalgebra.coe_toSubmodule, ←
    LieSubmodule.toSubmodule_inj, incl_range, toLieSubalgebra_toSubmodule,
    LieSubmodule.coe_lieSpan_submodule_eq_iff]
  use I

theorem incl_isIdealMorphism : I.incl.IsIdealMorphism := by
  rw [I.incl.isIdealMorphism_def, incl_idealRange]
  exact (I : LieSubalgebra R L).incl_range.symm

end LieIdeal

end LieSubmoduleMapAndComap

namespace LieModuleHom

variable {R : Type u} {L : Type v} {M : Type w} {N : Type w₁}
variable [CommRing R] [LieRing L]
variable [AddCommGroup M] [Module R M] [LieRingModule L M]
variable [AddCommGroup N] [Module R N] [LieRingModule L N]
variable (f : M →ₗ⁅R,L⁆ N)

/-- The kernel of a morphism of Lie algebras, as an ideal in the domain. -/
def ker : LieSubmodule R L M :=
  LieSubmodule.comap f ⊥

@[simp]
theorem ker_toSubmodule : (f.ker : Submodule R M) = LinearMap.ker (f : M →ₗ[R] N) :=
  rfl

@[deprecated (since := "2024-12-30")] alias ker_coeSubmodule := ker_toSubmodule

theorem ker_eq_bot : f.ker = ⊥ ↔ Function.Injective f := by
  rw [← LieSubmodule.toSubmodule_inj, ker_toSubmodule, LieSubmodule.bot_toSubmodule,
    LinearMap.ker_eq_bot, coe_toLinearMap]

variable {f}

@[simp]
theorem mem_ker {m : M} : m ∈ f.ker ↔ f m = 0 :=
  Iff.rfl

@[simp]
theorem ker_id : (LieModuleHom.id : M →ₗ⁅R,L⁆ M).ker = ⊥ :=
  rfl

@[simp]
theorem comp_ker_incl : f.comp f.ker.incl = 0 := by ext ⟨m, hm⟩; exact mem_ker.mp hm

theorem le_ker_iff_map (M' : LieSubmodule R L M) : M' ≤ f.ker ↔ LieSubmodule.map f M' = ⊥ := by
  rw [ker, eq_bot_iff, LieSubmodule.map_le_iff_le_comap]

variable (f)

/-- The range of a morphism of Lie modules `f : M → N` is a Lie submodule of `N`.
See Note [range copy pattern]. -/
def range : LieSubmodule R L N :=
  (LieSubmodule.map f ⊤).copy (Set.range f) Set.image_univ.symm

@[simp]
theorem coe_range : f.range = Set.range f :=
  rfl

@[simp]
theorem toSubmodule_range : f.range = LinearMap.range (f : M →ₗ[R] N) :=
  rfl

@[deprecated (since := "2024-12-30")] alias coeSubmodule_range := toSubmodule_range

@[simp]
theorem mem_range (n : N) : n ∈ f.range ↔ ∃ m, f m = n :=
  Iff.rfl

@[simp]
theorem map_top : LieSubmodule.map f ⊤ = f.range := by ext; simp [LieSubmodule.mem_map]

theorem range_eq_top : f.range = ⊤ ↔ Function.Surjective f := by
  rw [SetLike.ext'_iff, coe_range, LieSubmodule.top_coe, Set.range_eq_univ]

/-- A morphism of Lie modules `f : M → N` whose values lie in a Lie submodule `P ⊆ N` can be
restricted to a morphism of Lie modules `M → P`. -/
def codRestrict (P : LieSubmodule R L N) (f : M →ₗ⁅R,L⁆ N) (h : ∀ m, f m ∈ P) :
    M →ₗ⁅R,L⁆ P where
  toFun := f.toLinearMap.codRestrict P h
  __ := f.toLinearMap.codRestrict P h
  map_lie' {x m} := by ext; simp

@[simp]
lemma codRestrict_apply (P : LieSubmodule R L N) (f : M →ₗ⁅R,L⁆ N) (h : ∀ m, f m ∈ P) (m : M) :
    (f.codRestrict P h m : N) = f m :=
  rfl

end LieModuleHom

namespace LieSubmodule

variable {R : Type u} {L : Type v} {M : Type w}
variable [CommRing R] [LieRing L]
variable [AddCommGroup M] [Module R M] [LieRingModule L M]
variable (N : LieSubmodule R L M)

@[simp]
theorem ker_incl : N.incl.ker = ⊥ := (LieModuleHom.ker_eq_bot N.incl).mpr <| injective_incl N

@[simp]
theorem range_incl : N.incl.range = N := by
  simp only [← toSubmodule_inj, LieModuleHom.toSubmodule_range, incl_coe]
  rw [Submodule.range_subtype]

@[simp]
theorem comap_incl_self : comap N.incl N = ⊤ := by
  simp only [← toSubmodule_inj, toSubmodule_comap, incl_coe, top_toSubmodule]
  rw [Submodule.comap_subtype_self]

theorem map_incl_top : (⊤ : LieSubmodule R L N).map N.incl = N := by simp

variable {N}

@[simp]
lemma map_le_range {M' : Type*}
    [AddCommGroup M'] [Module R M'] [LieRingModule L M'] (f : M →ₗ⁅R,L⁆ M') :
    N.map f ≤ f.range := by
  rw [← LieModuleHom.map_top]
  exact LieSubmodule.map_mono le_top

@[simp]
lemma map_incl_lt_iff_lt_top {N' : LieSubmodule R L N} :
    N'.map (LieSubmodule.incl N) < N ↔ N' < ⊤ := by
  convert (LieSubmodule.mapOrderEmbedding (f := N.incl) Subtype.coe_injective).lt_iff_lt
  simp

@[simp]
lemma map_incl_le {N' : LieSubmodule R L N} :
    N'.map N.incl ≤ N := by
  conv_rhs => rw [← N.map_incl_top]
  exact LieSubmodule.map_mono le_top

end LieSubmodule

section TopEquiv

variable (R : Type u) (L : Type v)
variable [CommRing R] [LieRing L]

variable (M : Type*) [AddCommGroup M] [Module R M] [LieRingModule L M]

/-- The natural equivalence between the 'top' Lie submodule and the enclosing Lie module. -/
def LieModuleEquiv.ofTop : (⊤ : LieSubmodule R L M) ≃ₗ⁅R,L⁆ M :=
  { LinearEquiv.ofTop ⊤ rfl with
    map_lie' := rfl }

variable {R L}

lemma LieModuleEquiv.ofTop_apply (x : (⊤ : LieSubmodule R L M)) :
    LieModuleEquiv.ofTop R L M x = x :=
  rfl

@[simp] lemma LieModuleEquiv.range_coe {M' : Type*}
    [AddCommGroup M'] [Module R M'] [LieRingModule L M'] (e : M ≃ₗ⁅R,L⁆ M') :
    LieModuleHom.range (e : M →ₗ⁅R,L⁆ M') = ⊤ := by
  rw [LieModuleHom.range_eq_top]
  exact e.surjective

variable [LieAlgebra R L] [LieModule R L M]

/-- The natural equivalence between the 'top' Lie subalgebra and the enclosing Lie algebra.

This is the Lie subalgebra version of `Submodule.topEquiv`. -/
def LieSubalgebra.topEquiv : (⊤ : LieSubalgebra R L) ≃ₗ⁅R⁆ L :=
  { (⊤ : LieSubalgebra R L).incl with
    invFun := fun x ↦ ⟨x, Set.mem_univ x⟩
    left_inv := fun x ↦ by ext; rfl
    right_inv := fun _ ↦ rfl }

@[simp]
theorem LieSubalgebra.topEquiv_apply (x : (⊤ : LieSubalgebra R L)) : LieSubalgebra.topEquiv x = x :=
  rfl

/-- The natural equivalence between the 'top' Lie ideal and the enclosing Lie algebra.

This is the Lie ideal version of `Submodule.topEquiv`. -/
def LieIdeal.topEquiv : (⊤ : LieIdeal R L) ≃ₗ⁅R⁆ L :=
  LieSubalgebra.topEquiv

theorem LieIdeal.topEquiv_apply (x : (⊤ : LieIdeal R L)) : LieIdeal.topEquiv x = x :=
  rfl

end TopEquiv
