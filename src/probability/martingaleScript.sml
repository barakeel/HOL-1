(* ------------------------------------------------------------------------- *)
(* The Theory of Martingales for Sigma-finite Measure Spaces                 *)
(*  (Lebesgue Integral extras, Product Measure and Fubini-Tonelli's theorem) *)
(*                                                                           *)
(* Author: Chun Tian (2019 - 2021)                                           *)
(* Fondazione Bruno Kessler and University of Trento, Italy                  *)
(* ------------------------------------------------------------------------- *)

open HolKernel Parse boolLib bossLib;

open pairTheory relationTheory prim_recTheory arithmeticTheory fcpTheory
     pred_setTheory combinTheory realTheory realLib seqTheory posetTheory
     iterateTheory real_topologyTheory;

open hurdUtils util_probTheory extrealTheory sigma_algebraTheory
     measureTheory real_borelTheory borelTheory lebesgueTheory;

val _ = new_theory "martingale";

val _ = hide "S";

fun METIS ths tm = prove(tm, METIS_TAC ths);

(* "The theory of martingales as we know it now goes back to Doob and most of
    the material of this and the following chapter can be found in his seminal
    monograph [2] from 1953.

    We want to understand martingales as an analysis tool which will be useful
    for the study of L^p- and almost everywhere convergence and, in particular,
    for the further development of measure and integration theory. Our presentation
    differs somewhat from the standard way to introduce martingales - conditional
    expectations will be defined later in [1, Chapter 22] - but the results and
    their proofs are pretty much the usual ones."

  -- Rene L. Schilling, "Measures, Integrals and Martingales" [1]

   "Martingale theory illustrates the history of mathematical probability: the
    basic definitions are inspired by crude notions of gambling, but the theory
    has become a sophisticated tool of modern abstract mathematics, drawing from
    and contributing to other field."

  -- J. L. Doob, "What is a Martingale?" [3] *)

(* ------------------------------------------------------------------------- *)
(*  Martingale definitions ([1, Chapter 23])                                 *)
(* ------------------------------------------------------------------------- *)

Definition sub_sigma_algebra_def :
   sub_sigma_algebra a b =
      (sigma_algebra a /\ sigma_algebra b /\ (space a = space b) /\
       (subsets a) SUBSET (subsets b))
End

(* the set of all filtrations of A *)
Definition filtration_def :
   filtration A (a :num -> 'a algebra) =
     ((!n. sub_sigma_algebra (a n) A) /\
      (!i j. i <= j ==> subsets (a i) SUBSET subsets (a j)))
End

(* usually denoted by (sp,sts,a,m) in textbooks *)
Definition filtered_measure_space_def :
   filtered_measure_space (sp,sts,m) a =
           (measure_space (sp,sts,m) /\ filtration (sp,sts) a)
End

Definition sigma_finite_filtered_measure_space_def :
   sigma_finite_filtered_measure_space (sp,sts,m) a =
      (filtered_measure_space (sp,sts,m) a /\ sigma_finite (sp,subsets (a 0),m))
End

Definition martingale_def :
   martingale m a u =
     (sigma_finite_filtered_measure_space m a /\ (!n. integrable m (u n)) /\
      !n s. s IN (subsets (a n)) ==>
           (integral m (\x. u (SUC n) x * indicator_fn s x) =
            integral m (\x. u n x * indicator_fn s x)))
End

Definition super_martingale_def :
   super_martingale m a u =
     (sigma_finite_filtered_measure_space m a /\ (!n. integrable m (u n)) /\
      !n s. s IN (subsets (a n)) ==>
           (integral m (\x. u (SUC n) x * indicator_fn s x) <=
            integral m (\x. u n x * indicator_fn s x)))
End

Definition sub_martingale_def :
   sub_martingale m a u =
     (sigma_finite_filtered_measure_space m a /\ (!n. integrable m (u n)) /\
      !n s. s IN (subsets (a n)) ==>
           (integral m (\x. u n x * indicator_fn s x) <=
            integral m (\x. u (SUC n) x * indicator_fn s x)))
End

(* ------------------------------------------------------------------------- *)
(*   Convergence theorems and their applications [1, Chapter 9 & 12]         *)
(* ------------------------------------------------------------------------- *)

(* Another convergence theorem, usually called Fatou's lemma,
   named after Pierre Fatou (1878-1929), a French mathematician and astronomer.

   This is mainly to prove the validity of the definition of `ext_liminf`. The value
   of any of the integrals may be infinite.

   This is Theorem 9.11 of [1, p.78], a simple version (enough for now).

   cf. integrationTheory.FATOU for the version of Henstock-Kurzweil integrals.
 *)
Theorem fatou_lemma :
    !m f. measure_space m /\ (!x n. x IN m_space m ==> 0 <= f n x) /\
         (!n. f n IN measurable (m_space m,measurable_sets m) Borel) ==>
          pos_fn_integral m (\x. liminf (\n. f n x)) <=
          liminf (\n. pos_fn_integral m (f n))
Proof
    rw [ext_liminf_def]
 >> Know ‘pos_fn_integral m (\x. sup (IMAGE (\m. inf {f n x | m <= n}) UNIV)) =
          sup (IMAGE (\i. pos_fn_integral m (\x. inf {f n x | i <= n})) UNIV)’
 >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence >> rw [] >| (* 3 subgoals *)
     [ (* goal 1 (of 3) *)
       MATCH_MP_TAC IN_MEASURABLE_BOREL_INF >> simp [] \\
       qexistsl_tac [‘f’, ‘from i’] >> rw [IN_FROM] >| (* 3 subgoals *)
       [ (* goal 1 (of 3) *)
         FULL_SIMP_TAC std_ss [measure_space_def],
         (* goal 2 (of 3) *)
         rw [Once EXTENSION, IN_FROM] \\
         Q.EXISTS_TAC ‘i’ >> rw [],
         (* goal 3 (of 3) *)
         Suff ‘{f n x | i <= n} = (IMAGE (\n. f n x) (from i))’ >- rw [] \\
         rw [Once EXTENSION, IN_FROM] ],
       (* goal 2 (of 3) *)
       rw [le_inf'] >> METIS_TAC [],
       (* goal 3 (of 3) *)
       rw [ext_mono_increasing_def] \\
       MATCH_MP_TAC inf_mono_subset >> rw [SUBSET_DEF] \\
       Q.EXISTS_TAC ‘n’ >> rw [] ]) >> Rewr'
 >> MATCH_MP_TAC sup_mono >> rw []
 >> rw [le_inf']
 >> MATCH_MP_TAC pos_fn_integral_mono >> rw []
 >| [ (* goal 1 (of 2) *)
      rw [le_inf'] >> rw [],
      (* goal 2 (of 2) *)
      rw [inf_le'] \\
      POP_ASSUM MATCH_MP_TAC \\
      Q.EXISTS_TAC ‘n'’ >> rw [] ]
QED

(* This is also called Reverse Fatou Lemma, c.f. [1, p. 80]

   NOTE: the antecedents are just to make sure that WLLN_IID can be proved.
 *)
Theorem fatou_lemma' :
    !m f w. measure_space m /\ pos_fn_integral m w < PosInf /\
           (!x n. x IN m_space m ==> 0 <= f n x /\ f n x <= w x /\ w x < PosInf) /\
           (!n. f n IN measurable (m_space m,measurable_sets m) Borel) ==>
            limsup (\n. pos_fn_integral m (f n)) <=
            pos_fn_integral m (\x. limsup (\n. f n x))
Proof
    rw [ext_limsup_def]
 >> Know ‘pos_fn_integral m (\x. inf (IMAGE (\m. sup {f n x | m <= n}) UNIV)) =
          inf (IMAGE (\i. pos_fn_integral m (\x. sup {f n x | i <= n})) UNIV)’
 >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence_decreasing >> rw [] >| (* 5 subgoals *)
     [ (* goal 1 (of 5) *)
       MATCH_MP_TAC IN_MEASURABLE_BOREL_SUP >> simp [] \\
       qexistsl_tac [‘f’, ‘from i’] >> rw [IN_FROM] >| (* 3 subgoals *)
       [ (* goal 5.1 (of 3) *)
         FULL_SIMP_TAC std_ss [measure_space_def],
         (* goal 5.2 (of 3) *)
         rw [Once EXTENSION, IN_FROM] \\
         Q.EXISTS_TAC ‘i’ >> rw [],
         (* goal 5.3 (of 3) *)
         Suff ‘{f n x | i <= n} = (IMAGE (\n. f n x) (from i))’ >- rw [] \\
         rw [Once EXTENSION, IN_FROM] ],
       (* goal 2 (of 5) *)
       rw [le_sup'] \\
       MATCH_MP_TAC le_trans >> Q.EXISTS_TAC ‘f i x’ >> rw [] \\
       POP_ASSUM MATCH_MP_TAC \\
       Q.EXISTS_TAC ‘i’ >> rw [],
       (* goal 3 (of 5): sup {f n x | i <= n} < PosInf *)
       MATCH_MP_TAC let_trans >> Q.EXISTS_TAC ‘w x’ \\
       reverse CONJ_TAC >- rw [GSYM lt_infty] \\
       rw [sup_le'] >> METIS_TAC [],
       (* goal 4 (of 5): pos_fn_integral m (\x. sup {f n x | i <= n}) <> PosInf *)
       REWRITE_TAC [lt_infty] \\
       MATCH_MP_TAC let_trans \\
       Q.EXISTS_TAC ‘pos_fn_integral m w’ >> art [] \\
       MATCH_MP_TAC pos_fn_integral_mono >> rw [] >| (* 2 subgoals *)
       [ (* goal 4.1 (of 2) *)
         rw [le_sup'] \\
         MATCH_MP_TAC le_trans >> Q.EXISTS_TAC ‘f i x’ >> rw [] \\
         POP_ASSUM MATCH_MP_TAC \\
         Q.EXISTS_TAC ‘i’ >> rw [],
         (* goal 4.2 (of 2) *)
         rw [sup_le'] >> METIS_TAC [] ],
       (* goal 5 (of 5) *)
       rw [ext_mono_decreasing_def] \\
       MATCH_MP_TAC sup_mono_subset >> rw [SUBSET_DEF] \\
       Q.EXISTS_TAC ‘n’ >> rw [] ])
 >> Rewr'
 >> MATCH_MP_TAC inf_mono >> rw []
 >> rw [sup_le']
 >> MATCH_MP_TAC pos_fn_integral_mono >> rw []
 >> rw [le_sup']
 >> POP_ASSUM MATCH_MP_TAC
 >> Q.EXISTS_TAC ‘n'’ >> rw []
QED

Theorem LIM_SEQUENTIALLY_real_normal :
    !a l. (!n. a n <> PosInf /\ a n <> NegInf) ==>
          (((\n. real (a n)) --> l) sequentially <=>
           !e. 0 < e ==> ?N. !n. N <= n ==> abs (a n - Normal l) < Normal e)
Proof
    rw [LIM_SEQUENTIALLY, dist]
 >> EQ_TAC
 >- (rpt STRIP_TAC \\
     Q.PAT_X_ASSUM ‘!e. 0 < e ==> ?N. P’ (MP_TAC o (Q.SPEC ‘e’)) \\
     RW_TAC std_ss [] \\
     Know ‘!n. real (a n) - l = real (a n - Normal l)’
     >- (Q.X_GEN_TAC ‘n’ \\
        ‘?A. a n = Normal A’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         rw [real_normal, extreal_sub_eq]) \\
     DISCH_THEN (FULL_SIMP_TAC std_ss o wrap) \\
     Know ‘!n. abs (real (a n - Normal l)) = real (abs (a n - Normal l))’
     >- (Q.X_GEN_TAC ‘n’ \\
         MATCH_MP_TAC abs_real \\
        ‘?A. a n = Normal A’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         rw [extreal_sub_def]) \\
     DISCH_THEN (FULL_SIMP_TAC std_ss o wrap) \\
     POP_ASSUM MP_TAC \\
     ONCE_REWRITE_TAC [GSYM extreal_lt_eq] \\
     Know ‘!n. Normal (real (abs (a n - Normal l))) = abs (a n - Normal l)’
     >- (Q.X_GEN_TAC ‘n’ \\
         MATCH_MP_TAC normal_real \\
        ‘?A. a n = Normal A’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         rw [extreal_sub_def, extreal_abs_def]) >> Rewr' \\
     DISCH_TAC \\
     Q.EXISTS_TAC ‘N’ >> rw [])
 >> rpt STRIP_TAC
 >> Q.PAT_X_ASSUM ‘!e. 0 < e ==> ?N. P’ (MP_TAC o (Q.SPEC ‘e’))
 >> RW_TAC std_ss []
 >> Q.EXISTS_TAC ‘N’
 >> rpt STRIP_TAC
 >> Know ‘real (a n) - l = real (a n - Normal l)’
 >- (‘?A. a n = Normal A’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     rw [real_normal, extreal_sub_eq]) >> Rewr'
 >> Know ‘abs (real (a n - Normal l)) = real (abs (a n - Normal l))’
 >- (MATCH_MP_TAC abs_real \\
    ‘?A. a n = Normal A’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     rw [extreal_sub_def]) >> Rewr'
 >> ONCE_REWRITE_TAC [GSYM extreal_lt_eq]
 >> Know ‘Normal (real (abs (a n - Normal l))) = abs (a n - Normal l)’
 >- (MATCH_MP_TAC normal_real \\
    ‘?A. a n = Normal A’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     rw [extreal_sub_def, extreal_abs_def]) >> Rewr'
 >> FIRST_X_ASSUM MATCH_MP_TAC >> art []
QED

Theorem ext_limsup_lemma :
    !a. (!n. a n <> PosInf /\ a n <> NegInf) /\ ((\n. real (a n)) --> 0) sequentially
        ==> limsup a <= 0
Proof
    rpt STRIP_TAC
 >> Know ‘!e. 0 < e ==> ?N. !n. N <= n ==> abs (a n - Normal 0) < Normal e’
 >- (METIS_TAC [LIM_SEQUENTIALLY_real_normal])
 >> REWRITE_TAC [GSYM extreal_of_num_def, sub_rzero]
 >> DISCH_TAC
 >> rw [ext_limsup_def, inf_le']
 >> MATCH_MP_TAC le_epsilon >> rw [add_lzero]
 >> ‘e <> NegInf’ by PROVE_TAC [pos_not_neginf, lt_imp_le]
 >> ‘?E. e = Normal E /\ 0 < E’
       by METIS_TAC [extreal_cases, extreal_of_num_def, extreal_lt_eq]
 >> Q.PAT_X_ASSUM ‘e = Normal E’ (REWRITE_TAC o wrap)
 >> Q.PAT_X_ASSUM ‘0 < e’ K_TAC
 >> Q.PAT_X_ASSUM ‘e <> PosInf’ K_TAC
 >> Q.PAT_X_ASSUM ‘e <> NegInf’ K_TAC
 >> Q.PAT_X_ASSUM ‘!e. 0 < e ==> ?N. P’ (MP_TAC o (Q.SPEC ‘E’))
 >> RW_TAC std_ss []
 (* stage work *)
 >> MATCH_MP_TAC le_trans
 >> Q.EXISTS_TAC ‘sup {a n | N <= n}’
 >> CONJ_TAC
 >- (FIRST_X_ASSUM MATCH_MP_TAC \\
     Q.EXISTS_TAC ‘N’ >> rw [])
 >> rw [sup_le']
 >> MATCH_MP_TAC le_trans
 >> Q.EXISTS_TAC ‘abs (a n)’
 >> reverse CONJ_TAC
 >- (MATCH_MP_TAC lt_imp_le >> rw [])
 >> rw [le_abs]
QED

(* This is Properties A.1 (v) [1, p.409] (the most important property of limsup/liminf)

   NOTE: the condition ‘0 <= a n’ is not necessary but enough and ease the proof.
 *)
Theorem ext_limsup_thm :
    !a. (!n. 0 <= a n /\ a n <> PosInf) ==>
        (((\n. real (a n)) --> 0) sequentially <=> limsup a = 0 /\ liminf a = 0)
Proof
    rpt STRIP_TAC
 >> ‘!n. a n <> NegInf’ by METIS_TAC [pos_not_neginf]
 >> EQ_TAC
 >- (DISCH_TAC \\
    ‘limsup a <= 0’ by METIS_TAC [ext_limsup_lemma] \\
     CONJ_TAC >- (rw [GSYM le_antisym, ext_limsup_pos]) \\
     rw [GSYM le_antisym, ext_liminf_pos] \\
     MATCH_MP_TAC le_trans \\
     Q.EXISTS_TAC ‘limsup a’ >> rw [ext_liminf_le_limsup])
 >> STRIP_TAC
 >> Suff ‘!e. 0 < e ==> ?N. !n. N <= n ==> abs (a n - Normal 0) < Normal e’
 >- (METIS_TAC [LIM_SEQUENTIALLY_real_normal])
 >> rw [GSYM extreal_of_num_def, sub_rzero]
 (* stage work *)
 >> ‘!n. abs (a n) = a n’ by rw [abs_refl] >> POP_ORW
 >> CCONTR_TAC >> fs [extreal_lt_def]
 >> Q.PAT_X_ASSUM ‘liminf a = 0’ K_TAC (* always useless *)
 >> Know ‘limsup a <= 0’
 >- (METIS_TAC [ext_limsup_pos, le_antisym])
 >> Q.PAT_X_ASSUM ‘limsup a = 0’ K_TAC
 >> rw [ext_limsup_def, inf_le']
 >> REWRITE_TAC [GSYM extreal_lt_def]
 >> Q.EXISTS_TAC ‘Normal e’
 >> reverse CONJ_TAC >- (rw [extreal_of_num_def, extreal_lt_eq])
 >> rw []
 >> rw [le_sup']
 >> Q.PAT_X_ASSUM ‘!N. ?n. N <= n /\ Normal e <= a n’ (MP_TAC o (Q.SPEC ‘m’))
 >> rw []
 >> MATCH_MP_TAC le_trans
 >> Q.EXISTS_TAC ‘a n’ >> art []
 >> FIRST_X_ASSUM MATCH_MP_TAC
 >> Q.EXISTS_TAC ‘n’ >> art []
QED

(* Theorem 12.2 of [1, p.97], in slightly simplified form

   NOTE: ‘integrable m f’ can be moved to conclusions, but the current form is
          enough for WLLN_IID (directly used by truncated_vars_expectation).
 *)
Theorem lebesgue_dominated_convergence :
    !m f fi. measure_space m /\ (!i. integrable m (fi i)) /\ integrable m f /\
            (!i x. x IN m_space m ==> fi i x <> PosInf /\ fi i x <> NegInf) /\
            (!x. x IN m_space m ==> f x <> PosInf /\ f x <> NegInf) /\
            (!x. x IN m_space m ==>
                ((\i. real (fi i x)) --> real (f x)) sequentially) /\
            (?w. integrable m w /\
                (!x. x IN m_space m ==> 0 <= w x /\ w x <> PosInf) /\
                 !i x. x IN m_space m ==> abs (fi i x) <= w x)
        ==> ((\i. real (integral m (fi i))) --> real (integral m f)) sequentially
Proof
    rpt STRIP_TAC
 >> Suff ‘((\i. real (integral m (\x. abs (fi i x - f x)))) --> 0) sequentially’
 >- (rw [LIM_SEQUENTIALLY, dist] \\
     Q.PAT_X_ASSUM ‘!e. 0 < e ==> P’ (MP_TAC o (Q.SPEC ‘e’)) \\
     RW_TAC std_ss [] \\
     Q.EXISTS_TAC ‘N’ >> rpt STRIP_TAC \\
     Q.PAT_X_ASSUM ‘!i. N <= i ==> P’ (MP_TAC o (Q.SPEC ‘i’)) \\
     RW_TAC std_ss [] \\
     Know ‘integrable m (\x. fi i x - f x)’
     >- (MATCH_MP_TAC integrable_sub >> rw []) >> DISCH_TAC \\
     Know ‘integrable m (\x. abs (fi i x - f x))’
     >- (HO_MATCH_MP_TAC (REWRITE_RULE [o_DEF] integrable_abs) >> art []) \\
     DISCH_TAC \\
     Know ‘abs (real (integral m (\x. abs (fi i x - f x)))) =
           real (abs (integral m (\x. abs (fi i x - f x))))’
     >- (MATCH_MP_TAC abs_real >> METIS_TAC [integrable_finite_integral]) \\
     DISCH_THEN (FULL_SIMP_TAC std_ss o wrap) \\
     Know ‘real (abs (integral m (\x. abs (fi i x - f x)))) < e <=>
           Normal (real (abs (integral m (\x. abs (fi i x - f x))))) < Normal e’
     >- rw [extreal_lt_eq] \\
     Know ‘Normal (real (abs (integral m (\x. abs (fi i x - f x))))) =
                        (abs (integral m (\x. abs (fi i x - f x))))’
     >- (MATCH_MP_TAC normal_real \\
        ‘?r. integral m (\x. abs (fi i x - f x)) = Normal r’
            by METIS_TAC [extreal_cases, integrable_finite_integral] >> POP_ORW \\
         rw [extreal_abs_def, extreal_not_infty]) >> Rewr' \\
     DISCH_THEN (FULL_SIMP_TAC std_ss o wrap) \\
     Know ‘abs (integral m (\x. abs (fi i x - f x))) =
                integral m (\x. abs (fi i x - f x))’
     >- (REWRITE_TAC [abs_refl] \\
         MATCH_MP_TAC integral_pos >> rw [abs_pos]) \\
     DISCH_THEN (FULL_SIMP_TAC std_ss o wrap) \\
     Know ‘real (integral m (fi i)) - real (integral m f) =
           real (integral m (fi i) - integral m f)’
     >- (‘?a. integral m (fi i) = Normal a’
            by METIS_TAC [extreal_cases, integrable_finite_integral] >> POP_ORW \\
         ‘?b. integral m f = Normal b’
            by METIS_TAC [extreal_cases, integrable_finite_integral] >> POP_ORW \\
         rw [extreal_sub_def, real_normal]) >> Rewr' \\
     Know ‘abs (real (integral m (fi i) - integral m f)) =
           real (abs (integral m (fi i) - integral m f))’
     >- (MATCH_MP_TAC abs_real \\
         ‘?a. integral m (fi i) = Normal a’
            by METIS_TAC [extreal_cases, integrable_finite_integral] >> POP_ORW \\
         ‘?b. integral m f = Normal b’
            by METIS_TAC [extreal_cases, integrable_finite_integral] >> POP_ORW \\
         rw [extreal_sub_def, extreal_not_infty]) >> Rewr' \\
     ONCE_REWRITE_TAC [GSYM extreal_lt_eq] \\
     Know ‘Normal (real (abs (integral m (fi i) - integral m f))) =
                         abs (integral m (fi i) - integral m f)’
     >- (MATCH_MP_TAC normal_real \\
         ‘?a. integral m (fi i) = Normal a’
            by METIS_TAC [extreal_cases, integrable_finite_integral] >> POP_ORW \\
         ‘?b. integral m f = Normal b’
            by METIS_TAC [extreal_cases, integrable_finite_integral] >> POP_ORW \\
         rw [extreal_abs_def, extreal_sub_def, extreal_not_infty]) >> Rewr' \\
     MATCH_MP_TAC let_trans \\
     Q.EXISTS_TAC ‘integral m (\x. abs (fi i x - f x))’ >> art [] \\
     Know ‘integral m (fi i) - integral m f = integral m (\x. fi i x - f x)’
     >- (ONCE_REWRITE_TAC [EQ_SYM_EQ] \\
         MATCH_MP_TAC integral_sub >> rw []) >> Rewr' \\
     HO_MATCH_MP_TAC (REWRITE_RULE [o_DEF] integral_triangle_ineq) >> art [])
 (* stage work, renamed ‘fi’ to ‘u’ *)
 >> rename1 ‘!i. integrable m (u i)’
 (* simplify ‘((\i. real (u i x)) --> real (f x)) sequentially’ *)
 >> Know ‘!x. x IN m_space m ==>
              !e. 0 < e ==> ?N. !i. N <= i ==> abs (u i x - f x) < Normal e’
 >- (RW_TAC std_ss [] \\
     Q.PAT_X_ASSUM ‘!x. x IN m_space m ==>
                        ((\i. real (u i x)) --> real (f x)) sequentially’ MP_TAC \\
     rw [LIM_SEQUENTIALLY, dist] \\
     Q.PAT_X_ASSUM ‘!x. x IN m_space m ==> !e. 0 < e ==> P’ (MP_TAC o (Q.SPEC ‘x’)) \\
     RW_TAC std_ss [] \\
     Q.PAT_X_ASSUM ‘!e. 0 < e ==> ?N. P’ (MP_TAC o (Q.SPEC ‘e’)) \\
     RW_TAC std_ss [] \\
     Know ‘!i. real (u i x) - real (f x) = real (u i x - f x)’
     >- (Q.X_GEN_TAC ‘i’ \\
        ‘?a. u i x = Normal a’ by METIS_TAC [extreal_cases] >> POP_ORW \\
        ‘?b. f x   = Normal b’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         rw [real_normal, extreal_sub_eq]) \\
     DISCH_THEN (FULL_SIMP_TAC std_ss o wrap) \\
     Know ‘!i. abs (real (u i x - f x)) = real (abs (u i x - f x))’
     >- (Q.X_GEN_TAC ‘i’ \\
         MATCH_MP_TAC abs_real \\
        ‘?a. u i x = Normal a’ by METIS_TAC [extreal_cases] >> POP_ORW \\
        ‘?b. f x   = Normal b’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         rw [extreal_sub_def]) \\
     DISCH_THEN (FULL_SIMP_TAC std_ss o wrap) \\
     POP_ASSUM MP_TAC >> ONCE_REWRITE_TAC [GSYM extreal_lt_eq] \\
     Know ‘!i. Normal (real (abs (u i x - f x))) = abs (u i x - f x)’
     >- (Q.X_GEN_TAC ‘i’ \\
         MATCH_MP_TAC normal_real \\
        ‘?a. u i x = Normal a’ by METIS_TAC [extreal_cases] >> POP_ORW \\
        ‘?b. f x   = Normal b’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         rw [extreal_sub_def, extreal_abs_def]) >> Rewr' \\
     DISCH_TAC \\
     Q.EXISTS_TAC ‘N’ >> rw [])
 >> DISCH_TAC
 >> Q.ABBREV_TAC ‘a = \i x. abs (u i x - f x)’
 >> Know ‘!x. x IN m_space m ==> ((\i. real (a i x)) --> 0) sequentially’
 >- (rw [Abbr ‘a’, LIM_SEQUENTIALLY, dist] \\
     Q.PAT_X_ASSUM ‘!x. x IN m_space m ==> !e. 0 < e ==> P’ (MP_TAC o (Q.SPEC ‘x’)) \\
     RW_TAC std_ss [] \\
     Q.PAT_X_ASSUM ‘!e. 0 < e ==> ?N. P’ (MP_TAC o (Q.SPEC ‘e’)) \\
     RW_TAC std_ss [] \\
     Q.EXISTS_TAC ‘N’ >> rpt STRIP_TAC \\
     Know ‘abs (real (abs (u i x - f x))) =
           real (abs (abs (u i x - f x)))’
     >- (MATCH_MP_TAC abs_real \\
        ‘?a. u i x = Normal a’ by METIS_TAC [extreal_cases] >> POP_ORW \\
        ‘?b. f x   = Normal b’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         rw [extreal_sub_def, extreal_abs_def]) >> Rewr' \\
     rw [abs_abs, GSYM extreal_lt_eq] \\
     Suff ‘Normal (real (abs (u i x - f x))) = abs (u i x - f x)’ >- rw [] \\
     MATCH_MP_TAC normal_real \\
    ‘?a. u i x = Normal a’ by METIS_TAC [extreal_cases] >> POP_ORW \\
    ‘?b. f x   = Normal b’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     rw [extreal_sub_def, extreal_abs_def])
 >> DISCH_TAC
 >> Q.ABBREV_TAC ‘b = \i. integral m (a i)’
 >> Know ‘!n. integrable m (a n)’
 >- (rw [Abbr ‘a’] \\
     HO_MATCH_MP_TAC (REWRITE_RULE [o_DEF] integrable_abs) >> art [] \\
     MATCH_MP_TAC integrable_sub >> rw [])
 >> DISCH_TAC
 >> ‘!i. integral m (\x. abs (u i x - f x)) = b i’ by rw [Abbr ‘a’, Abbr ‘b’] >> POP_ORW
 (* applying ext_limsup_thm *)
 >> Know ‘!n. 0 <= b n /\ b n <> PosInf’
 >- (Q.X_GEN_TAC ‘n’ >> SIMP_TAC std_ss [Abbr ‘b’] \\
     reverse CONJ_TAC >- METIS_TAC [integrable_finite_integral] \\
     MATCH_MP_TAC integral_pos >> rw [Abbr ‘a’, abs_pos])
 >> DISCH_THEN
     (ONCE_REWRITE_TAC o wrap o (MATCH_MP ext_limsup_thm))
 >> Q.UNABBREV_TAC ‘b’
 (* applying ext_limsup_thm again *)
 >> Know ‘!x. x IN m_space m ==>
              limsup (\i. a i x) = Normal 0 /\ liminf (\i. a i x) = Normal 0’
 >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
     Know ‘((\i. real (a i x)) --> 0) sequentially’
     >- (FIRST_X_ASSUM MATCH_MP_TAC >> art []) \\
     Q.ABBREV_TAC ‘c = \i. a i x’ \\
    ‘!i. a i x = c i’ by rw [Abbr ‘c’] >> POP_ORW \\
     Know ‘!n. 0 <= c n /\ c n <> PosInf’
     >- (Q.X_GEN_TAC ‘n’ >> SIMP_TAC std_ss [Abbr ‘c’, Abbr ‘a’, abs_pos] \\
        ‘?r. u n x = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
        ‘?z. f x   = Normal z’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         rw [extreal_sub_def, extreal_abs_def]) \\
     DISCH_THEN (REWRITE_TAC o wrap o (MATCH_MP ext_limsup_thm)) \\
     REWRITE_TAC [GSYM extreal_of_num_def])
 >> REWRITE_TAC [GSYM extreal_of_num_def]
 >> DISCH_TAC
 (* f is also bounded by w *)
 >> Know ‘!x. x IN m_space m ==> abs (f x) <= w x’
 >- (RW_TAC std_ss [] \\
     MATCH_MP_TAC le_epsilon >> rpt STRIP_TAC \\
    ‘0 <= e’ by PROVE_TAC [lt_imp_le] \\
    ‘e <> NegInf’ by PROVE_TAC [pos_not_neginf] \\
    ‘?E. e = Normal E /\ 0 < E’
        by METIS_TAC [extreal_cases, extreal_of_num_def, extreal_lt_eq] \\
     Q.PAT_X_ASSUM ‘!x. x IN m_space m ==> !e. 0 < e ==> P’ (MP_TAC o (Q.SPEC ‘x’)) \\
     RW_TAC std_ss [] \\
     Q.PAT_X_ASSUM ‘!e. 0 < e ==> ?N. P’ (MP_TAC o (Q.SPEC ‘E’)) \\
     RW_TAC std_ss [] \\
     MATCH_MP_TAC le_trans >> Q.EXISTS_TAC ‘abs (u N x) + Normal E’ \\
     reverse CONJ_TAC
     >- (MATCH_MP_TAC le_radd_imp >> METIS_TAC []) \\
     MATCH_MP_TAC le_trans >> Q.EXISTS_TAC ‘abs (u N x) + abs (u N x - f x)’ \\
     CONJ_TAC >- (MATCH_MP_TAC abs_triangle_sub' >> rw []) \\
     MATCH_MP_TAC le_ladd_imp \\
     MATCH_MP_TAC lt_imp_le \\
     Q.UNABBREV_TAC ‘a’ >> FULL_SIMP_TAC std_ss [])
 >> DISCH_TAC
 (* preparing for fatou_lemma *)
 >> Know ‘!i x. x IN m_space m ==> a i x <= 2 * w x’
 >- (RW_TAC std_ss [GSYM extreal_double, Abbr ‘a’] \\
     MATCH_MP_TAC le_trans \\
     Q.EXISTS_TAC ‘abs (u i x) + abs (f x)’ \\
     CONJ_TAC >- (MATCH_MP_TAC abs_triangle_neg >> rw []) \\
     MATCH_MP_TAC le_add2 >> rw [])
 >> DISCH_TAC
 (* applying ext_liminf_le_limsup *)
 >> Know ‘!i. 0 <= integral m (a i)’
 >- (Q.X_GEN_TAC ‘i’ \\
     MATCH_MP_TAC integral_pos >> rw [Abbr ‘a’, abs_pos])
 >> DISCH_TAC
 >> Suff ‘limsup (\i. integral m (a i)) <= 0’
 >- (DISCH_TAC \\
     STRONG_CONJ_TAC
     >- (rw [GSYM le_antisym] \\
         MATCH_MP_TAC ext_limsup_pos >> rw []) \\
     DISCH_TAC \\
     REWRITE_TAC [GSYM le_antisym] \\
     reverse CONJ_TAC >- (MATCH_MP_TAC ext_liminf_pos >> rw []) \\
     MATCH_MP_TAC le_trans \\
     POP_ASSUM K_TAC \\
     Q.EXISTS_TAC ‘limsup (\i. integral m (a i))’ >> art [] \\
     REWRITE_TAC [ext_liminf_le_limsup])
 (* stage work *)
 >> Suff ‘limsup (\n. integral m (a n)) <= integral m (\x. limsup (\n. a n x))’
 >- (DISCH_TAC \\
     MATCH_MP_TAC le_trans \\
     Q.EXISTS_TAC ‘integral m (\x. limsup (\n. a n x))’ >> art [] \\
     MATCH_MP_TAC integral_neg >> rw [])
 (* final: applying fatou_lemma' *)
 >> Know ‘!n. integral m (a n) = pos_fn_integral m (a n)’
 >- (Q.X_GEN_TAC ‘n’ \\
     MATCH_MP_TAC integral_pos_fn >> rw [Abbr ‘a’, abs_pos])
 >> Rewr'
 >> Know  ‘integral m (\x. limsup (\n. a n x)) =
    pos_fn_integral m (\x. limsup (\n. a n x))’
 >- (MATCH_MP_TAC integral_pos_fn >> rw [])
 >> Rewr'
 >> MATCH_MP_TAC fatou_lemma'
 >> Q.EXISTS_TAC ‘\x. 2 * w x’ >> simp []
 >> CONJ_TAC (* pos_fn_integral m (\x. 2 * w x) < PosInf *)
 >- (REWRITE_TAC [extreal_of_num_def] \\
     Know ‘pos_fn_integral m (\x. Normal 2 * w x) = Normal 2 * pos_fn_integral m w’
     >- (MATCH_MP_TAC pos_fn_integral_cmul >> rw [le_02]) >> Rewr' \\
     Know ‘integral m w <> PosInf /\ integral m w <> NegInf’
     >- (MATCH_MP_TAC integrable_finite_integral >> art []) \\
     Know ‘integral m w = pos_fn_integral m w’
     >- (MATCH_MP_TAC integral_pos_fn >> rw []) >> Rewr' \\
     STRIP_TAC \\
    ‘?r. pos_fn_integral m w = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     rw [GSYM lt_infty, extreal_mul_def])
 >> reverse CONJ_TAC >- FULL_SIMP_TAC std_ss [integrable_def]
 >> rw [Abbr ‘a’, abs_pos, GSYM lt_infty]
 >> ‘w x <> NegInf’ by METIS_TAC [pos_not_neginf]
 >> ‘?r. w x = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW
 >> rw [extreal_of_num_def, extreal_mul_def]
QED

(* ------------------------------------------------------------------------- *)
(*  Integrals with Respect to Image Measures [1, Chapter 15]                 *)
(* ------------------------------------------------------------------------- *)

(* Theorem 15.1, Part I (transformation theorem, positive functions only) *)
Theorem pos_fn_integral_distr :
    !M B f u. measure_space M /\ sigma_algebra B /\
              f IN measurable (m_space M, measurable_sets M) B /\
              u IN measurable B Borel /\
             (!x. x IN space B ==> 0 <= u x) ==>
             (pos_fn_integral (space B,subsets B,distr M f) u = pos_fn_integral M (u o f))
Proof
    rpt STRIP_TAC
 >> ‘measure_space (space B,subsets B,distr M f)’ by PROVE_TAC [measure_space_distr]
 >> Know ‘u o f IN measurable (m_space M,measurable_sets M) Borel’
 >- (MATCH_MP_TAC MEASURABLE_COMP \\
     Q.EXISTS_TAC ‘B’ >> art []) >> DISCH_TAC
 >> MP_TAC (Q.SPECL [‘(space B,subsets B,distr M f)’, ‘u’]
                    (INST_TYPE [alpha |-> “:'b”] lemma_fn_seq_sup))
 >> DISCH_THEN (STRIP_ASSUME_TAC o GSYM o REWRITE_RULE [m_space_def])
 (* LHS simplification *)
 >> Know ‘pos_fn_integral (space B,subsets B,distr M f) u =
          sup (IMAGE (\n. pos_fn_integral (space B,subsets B,distr M f)
                            (fn_seq (space B,subsets B,distr M f) u n)) UNIV)’
 >- (MATCH_MP_TAC lebesgue_monotone_convergence >> simp [] \\
     CONJ_TAC
     >- (Q.X_GEN_TAC ‘n’ \\
         MP_TAC (Q.SPECL [‘(space B,subsets B,distr M f)’, ‘u’, ‘n’]
                         (INST_TYPE [alpha |-> “:'b”] lemma_fn_seq_measurable)) \\
         RW_TAC std_ss [m_space_def, measurable_sets_def, SPACE]) \\
     CONJ_TAC
     >- (rpt STRIP_TAC \\
         MP_TAC (Q.SPECL [‘(space B,subsets B,distr M f)’, ‘u’, ‘i’, ‘x’]
                         (INST_TYPE [alpha |-> “:'b”] lemma_fn_seq_positive)) \\
         RW_TAC std_ss []) \\
     rpt STRIP_TAC \\
     MP_TAC (Q.SPECL [‘(space B,subsets B,distr M f)’, ‘u’, ‘x’]
                     (INST_TYPE [alpha |-> “:'b”] lemma_fn_seq_mono_increasing)) \\
     RW_TAC std_ss []) >> Rewr'
 (* RHS simplification *)
 >> Know ‘pos_fn_integral M (u o f) =
          pos_fn_integral M (\x. sup (IMAGE (\n. fn_seq (space B,subsets B,distr M f)
                                                        u n (f x)) UNIV))’
 >- (MATCH_MP_TAC pos_fn_integral_cong >> ASM_SIMP_TAC std_ss [] \\
     CONJ_TAC >- (rpt STRIP_TAC >> FIRST_X_ASSUM MATCH_MP_TAC \\
                  Q.PAT_X_ASSUM ‘f IN measurable (m_space M,measurable_sets M) B’ MP_TAC \\
                  rw [IN_MEASURABLE, IN_FUNSET]) \\
     CONJ_TAC >- (rw [le_sup', IN_IMAGE, IN_UNIV] \\
                  MATCH_MP_TAC le_trans \\
                  Q.EXISTS_TAC ‘fn_seq (space B,subsets B,distr M f) u 0 (f x)’ \\
                  reverse CONJ_TAC >- (POP_ASSUM MATCH_MP_TAC \\
                                       Q.EXISTS_TAC ‘0’ >> REWRITE_TAC []) \\
                  MATCH_MP_TAC lemma_fn_seq_positive \\
                  FIRST_X_ASSUM MATCH_MP_TAC \\
                  Q.PAT_X_ASSUM ‘f IN measurable (m_space M,measurable_sets M) B’ MP_TAC \\
                  rw [IN_MEASURABLE, IN_FUNSET]) \\
     rpt STRIP_TAC >> FIRST_X_ASSUM MATCH_MP_TAC \\
     Q.PAT_X_ASSUM ‘f IN measurable (m_space M,measurable_sets M) B’ MP_TAC \\
     rw [IN_MEASURABLE, IN_FUNSET]) >> Rewr'
 >> Know ‘pos_fn_integral M
            (\x. sup (IMAGE (\n. fn_seq (space B,subsets B,distr M f) u n (f x)) UNIV)) =
          sup (IMAGE (\n. pos_fn_integral M
                            ((fn_seq (space B,subsets B,distr M f) u n) o f)) UNIV)’
 >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [] \\
     CONJ_TAC
     >- (GEN_TAC \\
         MATCH_MP_TAC MEASURABLE_COMP >> Q.EXISTS_TAC ‘B’ >> art [] \\
         MP_TAC (Q.SPECL [‘(space B,subsets B,distr M f)’, ‘u’, ‘n’]
                         (INST_TYPE [alpha |-> “:'b”] lemma_fn_seq_measurable)) \\
         RW_TAC std_ss [m_space_def, measurable_sets_def, SPACE]) \\
     CONJ_TAC
     >- (rpt STRIP_TAC \\
         MP_TAC (Q.SPECL [‘(space B,subsets B,distr M f)’, ‘u’, ‘n’, ‘f x’]
                         (INST_TYPE [alpha |-> “:'b”] lemma_fn_seq_positive)) \\
         RW_TAC std_ss [] \\
         POP_ASSUM MATCH_MP_TAC \\
         FIRST_X_ASSUM MATCH_MP_TAC \\
         Q.PAT_X_ASSUM ‘f IN measurable (m_space M,measurable_sets M) B’ MP_TAC \\
         rw [IN_MEASURABLE, IN_FUNSET]) \\
     rpt STRIP_TAC \\
     MP_TAC (Q.SPECL [‘(space B,subsets B,distr M f)’, ‘u’, ‘f x’]
                     (INST_TYPE [alpha |-> “:'b”] lemma_fn_seq_mono_increasing)) \\
     RW_TAC std_ss [] \\
     POP_ASSUM MATCH_MP_TAC \\
     FIRST_X_ASSUM MATCH_MP_TAC \\
     Q.PAT_X_ASSUM ‘f IN measurable (m_space M,measurable_sets M) B’ MP_TAC \\
     rw [IN_MEASURABLE, IN_FUNSET]) >> Rewr'
 >> Suff ‘!n. pos_fn_integral (space B,subsets B,distr M f)
                                (fn_seq (space B,subsets B,distr M f) u n) =
              pos_fn_integral M (fn_seq (space B,subsets B,distr M f) u n o f)’ >- Rewr
 >> POP_ASSUM K_TAC (* clean up *)
 (* stage work *)
 >> Q.X_GEN_TAC ‘N’
 >> SIMP_TAC std_ss [fn_seq_def, m_space_def, o_DEF]
 >> Know ‘!i n. (0 :extreal) <= &i / 2 pow n’
 >- (rpt GEN_TAC \\
    ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
       by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
    ‘?r. 0 < r /\ (2 pow n = Normal r)’
       by METIS_TAC [lt_02, pow_pos_lt, extreal_cases, extreal_lt_eq,
                     extreal_of_num_def] >> POP_ORW \\
     MATCH_MP_TAC le_div >> rw [extreal_of_num_def, extreal_le_eq])
 >> DISCH_TAC
 (* LHS simplification *)
 >> Know ‘pos_fn_integral (space B,subsets B,distr M f)
            (\x. SIGMA (\k. &k / 2 pow N *
                           indicator_fn
                             {x | x IN space B /\ &k / 2 pow N <= u x /\
                                  u x < (&k + 1) / 2 pow N} x) (count (4 ** N)) +
                 2 pow N * indicator_fn {x | x IN space B /\ 2 pow N <= u x} x) =
          pos_fn_integral (space B,subsets B,distr M f)
            (\x. SIGMA (\k. &k / 2 pow N *
                           indicator_fn
                             {x | x IN space B /\ &k / 2 pow N <= u x /\
                                  u x < (&k + 1) / 2 pow N} x) (count (4 ** N))) +
          pos_fn_integral (space B,subsets B,distr M f)
            (\x. 2 pow N * indicator_fn {x | x IN space B /\ 2 pow N <= u x} x)’
 >- (HO_MATCH_MP_TAC pos_fn_integral_add \\
     ASM_SIMP_TAC std_ss [m_space_def, measurable_sets_def] \\
     CONJ_TAC (* 0 <= SIGMA *)
     >- (rpt STRIP_TAC \\
         MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> SIMP_TAC std_ss [FINITE_COUNT] \\
         Q.X_GEN_TAC ‘n’ >> STRIP_TAC \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
     CONJ_TAC (* 0 <= 2 pow N * indicator_fn *)
     >- (rpt STRIP_TAC \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS] \\
         MATCH_MP_TAC pow_pos_le >> REWRITE_TAC [le_02]) \\
     reverse CONJ_TAC (* 2 pow N * indicator_fn IN Borel_measurable *)
     >- (HO_MATCH_MP_TAC IN_MEASURABLE_BOREL_MUL_INDICATOR \\
         rw [SPACE] >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CONST >> rw [] \\
                        Q.EXISTS_TAC ‘2 pow N’ >> rw []) \\
        ‘{x | x IN space B /\ 2 pow N <= u x} = {x | 2 pow N <= u x} INTER space B’
            by SET_TAC [] >> POP_ORW \\
         METIS_TAC [IN_MEASURABLE_BOREL_ALL]) \\
  (* SIGMA IN Borel_measurable *)
     MATCH_MP_TAC (INST_TYPE [“:'b” |-> “:num”] IN_MEASURABLE_BOREL_SUM) \\
     ASM_SIMP_TAC std_ss [SPACE, space_def] \\
     qexistsl_tac [‘\k x. &k / 2 pow N *
                          indicator_fn
                            {x | x IN space B /\ &k / 2 pow N <= u x /\
                                 u x < (&k + 1) / 2 pow N} x’, ‘count (4 ** N)’] \\
     SIMP_TAC std_ss [FINITE_COUNT] \\
     reverse CONJ_TAC
     >- (rpt GEN_TAC >> STRIP_TAC \\
         MATCH_MP_TAC pos_not_neginf \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
     rpt STRIP_TAC \\
     HO_MATCH_MP_TAC IN_MEASURABLE_BOREL_MUL_INDICATOR >> rw []
     >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CONST >> rw [] \\
         Q.EXISTS_TAC ‘&i / 2 pow N’ >> rw []) \\
    ‘{x | x IN space B /\ &i / 2 pow N <= u x /\ u x < (&i + 1) / 2 pow N} =
     {x | &i / 2 pow N <= u x /\ u x < (&i + 1) / 2 pow N} INTER space B’
        by SET_TAC [] >> POP_ORW \\
     METIS_TAC [IN_MEASURABLE_BOREL_ALL]) >> Rewr'
 (* RHS simplification *)
 >> Know ‘pos_fn_integral M
            (\x. SIGMA
                   (\k. &k / 2 pow N *
                        indicator_fn
                          {x | x IN space B /\ &k / 2 pow N <= u x /\
                               u x < (&k + 1) / 2 pow N} (f x)) (count (4 ** N)) +
                 2 pow N * indicator_fn {x | x IN space B /\ 2 pow N <= u x} (f x)) =
          pos_fn_integral M
            (\x. SIGMA
                   (\k. &k / 2 pow N *
                        indicator_fn
                          {x | x IN space B /\ &k / 2 pow N <= u x /\
                               u x < (&k + 1) / 2 pow N} (f x)) (count (4 ** N))) +
          pos_fn_integral M
            (\x. 2 pow N * indicator_fn {x | x IN space B /\ 2 pow N <= u x} (f x))’
 >- (HO_MATCH_MP_TAC pos_fn_integral_add >> ASM_SIMP_TAC std_ss [] \\
     CONJ_TAC (* 0 <= SIGMA *)
     >- (rpt STRIP_TAC \\
         MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> SIMP_TAC std_ss [FINITE_COUNT] \\
         Q.X_GEN_TAC ‘n’ >> STRIP_TAC \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
     CONJ_TAC (* 0 <= 2 pow N * indicator_fn *)
     >- (rpt STRIP_TAC \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS] \\
         MATCH_MP_TAC pow_pos_le >> REWRITE_TAC [le_02]) \\
     reverse CONJ_TAC (* 2 pow N * indicator_fn IN Borel_measurable *)
     >- (‘(\x. 2 pow N *
               indicator_fn {x | x IN space B /\ 2 pow N <= u x} (f x)) =
          (\x. 2 pow N *
               indicator_fn {x | x IN space B /\ 2 pow N <= u x} x) o f’ by rw [o_DEF] >> POP_ORW \\
         MATCH_MP_TAC MEASURABLE_COMP >> Q.EXISTS_TAC ‘B’ >> art [] \\
         HO_MATCH_MP_TAC IN_MEASURABLE_BOREL_MUL_INDICATOR \\
         rw [] >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CONST >> rw [] \\
                   Q.EXISTS_TAC ‘2 pow N’ >> rw []) \\
        ‘{x | x IN space B /\ 2 pow N <= u x} = {x | 2 pow N <= u x} INTER space B’
            by SET_TAC [] >> POP_ORW \\
         METIS_TAC [IN_MEASURABLE_BOREL_ALL]) \\
  (* SIGMA IN Borel_measurable *)
     MATCH_MP_TAC (INST_TYPE [“:'b” |-> “:num”] IN_MEASURABLE_BOREL_SUM) \\
     ASM_SIMP_TAC std_ss [SPACE, space_def] \\
     qexistsl_tac [‘\k x. &k / 2 pow N *
                          indicator_fn
                            {x | x IN space B /\ &k / 2 pow N <= u x /\
                                 u x < (&k + 1) / 2 pow N} (f x)’, ‘count (4 ** N)’] \\
     SIMP_TAC std_ss [FINITE_COUNT] \\
     CONJ_TAC >- FULL_SIMP_TAC std_ss [measure_space_def] \\
     reverse CONJ_TAC
     >- (rpt GEN_TAC >> STRIP_TAC \\
         MATCH_MP_TAC pos_not_neginf \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
     rpt STRIP_TAC \\
    ‘(\x. &i / 2 pow N * indicator_fn {x | x IN space B /\ &i / 2 pow N <= u x /\
                                           u x < (&i + 1) / 2 pow N} (f x)) =
     (\x. &i / 2 pow N * indicator_fn {x | x IN space B /\ &i / 2 pow N <= u x /\
                                           u x < (&i + 1) / 2 pow N} x) o f’
        by RW_TAC std_ss [o_DEF] >> POP_ORW \\
     MATCH_MP_TAC MEASURABLE_COMP >> Q.EXISTS_TAC ‘B’ >> art [] \\
     HO_MATCH_MP_TAC IN_MEASURABLE_BOREL_MUL_INDICATOR >> rw []
     >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CONST >> rw [] \\
         Q.EXISTS_TAC ‘&i / 2 pow N’ >> rw []) \\
    ‘{x | x IN space B /\ &i / 2 pow N <= u x /\ u x < (&i + 1) / 2 pow N} =
     {x | &i / 2 pow N <= u x /\ u x < (&i + 1) / 2 pow N} INTER space B’
        by SET_TAC [] >> POP_ORW \\
     METIS_TAC [IN_MEASURABLE_BOREL_ALL]) >> Rewr'
 (* LHS simplification *)
 >> Know ‘pos_fn_integral (space B,subsets B,distr M f)
           (\x. SIGMA
                  (\k. (\k x. &k / 2 pow N *
                              indicator_fn
                                {x | x IN space B /\ &k / 2 pow N <= u x /\
                                     u x < (&k + 1) / 2 pow N} x) k x) (count (4 ** N))) =
          SIGMA (\k. pos_fn_integral (space B,subsets B,distr M f)
                      ((\k x. &k / 2 pow N *
                              indicator_fn
                                {x | x IN space B /\ &k / 2 pow N <= u x /\
                                     u x < (&k + 1) / 2 pow N} x) k))
                (count (4 ** N))’
 >- (MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] pos_fn_integral_sum) \\
     ASM_SIMP_TAC std_ss [FINITE_COUNT, m_space_def, measurable_sets_def, SPACE] \\
     CONJ_TAC (* 0 <= &i / 2 pow N * indicator_fn *)
     >- (rpt STRIP_TAC \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
     rpt STRIP_TAC \\
     HO_MATCH_MP_TAC IN_MEASURABLE_BOREL_MUL_INDICATOR >> art [] \\
     CONJ_TAC >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CONST >> rw [] \\
                  Q.EXISTS_TAC ‘&i / 2 pow N’ >> rw []) \\
    ‘{x | x IN space B /\ &i / 2 pow N <= u x /\ u x < (&i + 1) / 2 pow N} =
     {x | &i / 2 pow N <= u x /\ u x < (&i + 1) / 2 pow N} INTER space B’
        by SET_TAC [] >> POP_ORW \\
     METIS_TAC [IN_MEASURABLE_BOREL_ALL])
 >> BETA_TAC >> Rewr'
 >> Know ‘pos_fn_integral M
           (\x. SIGMA
                  (\k. (\k x. &k / 2 pow N *
                              indicator_fn
                                {x | x IN space B /\ &k / 2 pow N <= u x /\
                                     u x < (&k + 1) / 2 pow N} (f x)) k x) (count (4 ** N))) =
          SIGMA (\k. pos_fn_integral M
                      ((\k x. &k / 2 pow N *
                              indicator_fn
                                {x | x IN space B /\ &k / 2 pow N <= u x /\
                                     u x < (&k + 1) / 2 pow N} (f x)) k))
                (count (4 ** N))’
 >- (MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] pos_fn_integral_sum) \\
     ASM_SIMP_TAC std_ss [FINITE_COUNT] \\
     CONJ_TAC (* 0 <= &i / 2 pow N * indicator_fn *)
     >- (rpt STRIP_TAC \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
     rpt STRIP_TAC \\
    ‘(\x. &i / 2 pow N *
          indicator_fn {x | x IN space B /\ &i / 2 pow N <= u x /\
                            u x < (&i + 1) / 2 pow N} (f x)) =
     (\x. &i / 2 pow N *
          indicator_fn {x | x IN space B /\ &i / 2 pow N <= u x /\
                            u x < (&i + 1) / 2 pow N} x) o f’
        by RW_TAC std_ss [o_DEF] >> POP_ORW \\
     MATCH_MP_TAC MEASURABLE_COMP >> Q.EXISTS_TAC ‘B’ >> art [] \\
     HO_MATCH_MP_TAC IN_MEASURABLE_BOREL_MUL_INDICATOR >> art [] \\
     CONJ_TAC >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CONST >> rw [] \\
                  Q.EXISTS_TAC ‘&i / 2 pow N’ >> rw []) \\
    ‘{x | x IN space B /\ &i / 2 pow N <= u x /\ u x < (&i + 1) / 2 pow N} =
     {x | &i / 2 pow N <= u x /\ u x < (&i + 1) / 2 pow N} INTER space B’
        by SET_TAC [] >> POP_ORW \\
     METIS_TAC [IN_MEASURABLE_BOREL_ALL])
 >> BETA_TAC >> Rewr'
 (* LHS simplification *)
 >> Know ‘pos_fn_integral (space B,subsets B,distr M f)
            (\x. 2 pow N * indicator_fn {x | x IN space B /\ 2 pow N <= u x} x) =
          2 pow N * pos_fn_integral (space B,subsets B,distr M f)
                                    (indicator_fn {x | x IN space B /\ 2 pow N <= u x})’
 >- (‘2 pow N = Normal (2 pow N)’ by METIS_TAC [extreal_of_num_def, extreal_pow_def] >> POP_ORW \\
     MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr'
 (* RHS simplification *)
 >> Know ‘pos_fn_integral M
            (\x. 2 pow N * indicator_fn {x | x IN space B /\ 2 pow N <= u x} (f x)) =
          2 pow N * pos_fn_integral M (\x. indicator_fn {x | x IN space B /\ 2 pow N <= u x} (f x))’
 >- (‘2 pow N = Normal (2 pow N)’ by METIS_TAC [extreal_of_num_def, extreal_pow_def] >> POP_ORW \\
     HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr'
 (* LHS simplification *)
 >> Know ‘!k. pos_fn_integral (space B,subsets B,distr M f)
                (\x. &k / 2 pow N *
                     indicator_fn {x | x IN space B /\ &k / 2 pow N <= u x /\
                                       u x < (&k + 1) / 2 pow N} x) =
              &k / 2 pow N * pos_fn_integral (space B,subsets B,distr M f)
                               (indicator_fn {x | x IN space B /\ &k / 2 pow N <= u x /\
                                                  u x < (&k + 1) / 2 pow N})’
 >- (GEN_TAC \\
    ‘!n. 0:real < 2 pow n’ by RW_TAC real_ss [REAL_POW_LT] \\
    ‘!n. 0:real <> 2 pow n’ by RW_TAC real_ss [REAL_LT_IMP_NE] \\
    ‘!n k. &k / 2 pow n = Normal (&k / 2 pow n)’
        by METIS_TAC [extreal_of_num_def, extreal_pow_def, extreal_div_eq] >> POP_ORW \\
     MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS] \\
     MATCH_MP_TAC REAL_LE_DIV >> rw []) >> Rewr'
 (* RHS simplification *)
 >> Know ‘!k. pos_fn_integral M
                (\x. &k / 2 pow N * indicator_fn {x | x IN space B /\ &k / 2 pow N <= u x /\
                                                      u x < (&k + 1) / 2 pow N} (f x)) =
              &k / 2 pow N * pos_fn_integral M
                               (\x. indicator_fn {x | x IN space B /\ &k / 2 pow N <= u x /\
                                                      u x < (&k + 1) / 2 pow N} (f x))’
 >- (GEN_TAC \\
    ‘!n. 0:real < 2 pow n’ by RW_TAC real_ss [REAL_POW_LT] \\
    ‘!n. 0:real <> 2 pow n’ by RW_TAC real_ss [REAL_LT_IMP_NE] \\
    ‘!n k. &k / 2 pow n = Normal (&k / 2 pow n)’
        by METIS_TAC [extreal_of_num_def, extreal_pow_def, extreal_div_eq] >> POP_ORW \\
     HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS] \\
     MATCH_MP_TAC REAL_LE_DIV >> rw []) >> Rewr'
 (* stage work *)
 >> Suff ‘!s. s IN subsets B ==>
             (pos_fn_integral (space B,subsets B,distr M f) (indicator_fn s) =
              pos_fn_integral M (\x. indicator_fn s (f x)))’
 >- (DISCH_TAC \\
    ‘!k. {x | x IN space B /\ &k / 2 pow N <= u x /\ u x < (&k + 1) / 2 pow N} =
         {x | &k / 2 pow N <= u x /\ u x < (&k + 1) / 2 pow N} INTER space B’
       by SET_TAC [] >> POP_ORW \\
    ‘{x | x IN space B /\ 2 pow N <= u x} = {x | 2 pow N <= u x} INTER space B’
       by SET_TAC [] >> POP_ORW \\
     Know ‘pos_fn_integral (space B,subsets B,distr M f)
             (indicator_fn ({x | 2 pow N <= u x} INTER space B)) =
           pos_fn_integral M
             (\x. indicator_fn ({x | 2 pow N <= u x} INTER space B) (f x))’
     >- (FIRST_X_ASSUM MATCH_MP_TAC \\
         METIS_TAC [IN_MEASURABLE_BOREL_ALL]) >> Rewr' \\
     Know ‘!k. pos_fn_integral (space B,subsets B,distr M f)
                 (indicator_fn
                    ({x | &k / 2 pow N <= u x /\ u x < (&k + 1) / 2 pow N} INTER space B)) =
               pos_fn_integral M
                 (\x. indicator_fn
                        ({x | &k / 2 pow N <= u x /\ u x < (&k + 1) / 2 pow N} INTER space B) (f x))’
     >- (GEN_TAC >> FIRST_X_ASSUM MATCH_MP_TAC \\
         METIS_TAC [IN_MEASURABLE_BOREL_ALL]) >> Rewr)
 (* core proof *)
 >> rpt STRIP_TAC
 >> Know ‘pos_fn_integral (space B,subsets B,distr M f) (indicator_fn s) =
          measure (space B,subsets B,distr M f) s’
 >- (MATCH_MP_TAC pos_fn_integral_indicator >> rw []) >> Rewr'
 >> SIMP_TAC std_ss [measure_def, distr_def]
 >> Know ‘pos_fn_integral M (\x. indicator_fn s (f x)) =
          pos_fn_integral M (indicator_fn (PREIMAGE f s INTER m_space M))’
 >- (MATCH_MP_TAC pos_fn_integral_cong >> rw [INDICATOR_FN_POS] \\
     rw [indicator_fn_def]) >> Rewr'
 >> MATCH_MP_TAC EQ_SYM
 >> MATCH_MP_TAC pos_fn_integral_indicator
 >> fs [IN_MEASURABLE]
QED

(* Theorem 15.1, Part II (transformation theorem, general form) *)
Theorem integral_distr :
    !M B f u. measure_space M /\ sigma_algebra B /\
              f IN measurable (m_space M, measurable_sets M) B /\
              u IN measurable B Borel ==>
             (integral (space B,subsets B,distr M f) u = integral M (u o f)) /\
             (integrable (space B,subsets B,distr M f) u = integrable M (u o f))
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> simp [integrable_def, integral_def]
 >> Suff ‘(pos_fn_integral (space B,subsets B,distr M f) (fn_plus u) =
           pos_fn_integral M (fn_plus (u o f))) /\
          (pos_fn_integral (space B,subsets B,distr M f) (fn_minus u) =
           pos_fn_integral M (fn_minus (u o f)))’
 >- (Rewr >> EQ_TAC >> rw [] \\
     MATCH_MP_TAC MEASURABLE_COMP >> Q.EXISTS_TAC ‘B’ >> art [])
 >> Know ‘fn_plus (u o f) = fn_plus u o f’
 >- rw [FN_PLUS_ALT, o_DEF] >> DISCH_THEN (fs o wrap)
 >> Know ‘fn_minus (u o f) = fn_minus u o f’
 >- rw [FN_MINUS_ALT, o_DEF] >> DISCH_THEN (fs o wrap)
 >> CONJ_TAC
 >| [ (* goal 1 (of 2) *)
      MATCH_MP_TAC pos_fn_integral_distr >> rw [FN_PLUS_POS] \\
      MATCH_MP_TAC IN_MEASURABLE_BOREL_FN_PLUS >> art [],
      (* goal 2 (of 2) *)
      MATCH_MP_TAC pos_fn_integral_distr >> rw [FN_MINUS_POS] \\
      MATCH_MP_TAC IN_MEASURABLE_BOREL_FN_MINUS >> art [] ]
QED

Theorem pos_fn_integral_cong_measure :
    !sp sts u v f.
        measure_space (sp,sts,u) /\ measure_space (sp,sts,v) /\
        (!s. s IN sts ==> (u s = v s)) /\ (!x. x IN sp ==> 0 <= f x) ==>
        (pos_fn_integral (sp,sts,u) f = pos_fn_integral (sp,sts,v) f)
Proof
    rw [pos_fn_integral_def]
 >> Suff ‘!g. psfis (sp,sts,u) g = psfis (sp,sts,v) g’ >- rw []
 >> rw [psfis_def, Once EXTENSION, IN_IMAGE]
 >> EQ_TAC >> STRIP_TAC (* 2 subgoals, same tactics *)
 >> ( fs [psfs_def, pos_simple_fn_def] \\
      rename1 ‘!i. i IN s ==> 0 <= z i’ \\
      Q.EXISTS_TAC ‘(s,a,z)’ \\
      REV_FULL_SIMP_TAC std_ss [pos_simple_fn_integral_def, measure_def] \\
      Q.PAT_X_ASSUM ‘x = _’ K_TAC \\
      Q.PAT_X_ASSUM ‘_ = (s,a,z)’ K_TAC \\
      irule EXTREAL_SUM_IMAGE_EQ >> rfs [] \\
      DISJ1_TAC >> NTAC 2 STRIP_TAC \\
      MATCH_MP_TAC pos_not_neginf \\
      MATCH_MP_TAC le_mul \\
      CONJ_TAC >- (rw [extreal_of_num_def, extreal_le_eq]) \\
      rename1 ‘y IN s’ \\
     ‘positive (sp,sts,v)’ by PROVE_TAC [MEASURE_SPACE_POSITIVE] \\
      fs [positive_def] )
QED

Theorem pos_fn_integral_cong_measure' :
    !m1 m2 f. measure_space m1 /\ measure_space m2 /\
             (m_space m1 = m_space m2) /\ (measurable_sets m1 = measurable_sets m2) /\
             (!s. s IN measurable_sets m1 ==> (measure m1 s = measure m2 s)) /\
             (!x. x IN m_space m1 ==> 0 <= f x) ==>
             (pos_fn_integral m1 f = pos_fn_integral m2 f)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘m_space m1’, ‘measurable_sets m1’, ‘measure m1’, ‘measure m2’, ‘f’]
                    pos_fn_integral_cong_measure)
 >> rw []
QED

Theorem integral_cong_measure_base[local] :
    !sp sts u v f.
        measure_space (sp,sts,u) /\ measure_space (sp,sts,v) /\
       (!s. s IN sts ==> (u s = v s)) ==>
       (integral (sp,sts,u) f = integral (sp,sts,v) f) /\
       (integrable (sp,sts,u) f <=> integrable (sp,sts,v) f)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> simp [integral_def, integrable_def]
 >> Suff ‘(pos_fn_integral (sp,sts,u) (fn_plus f) = pos_fn_integral (sp,sts,v) (fn_plus f)) /\
          (pos_fn_integral (sp,sts,u) (fn_minus f) = pos_fn_integral (sp,sts,v) (fn_minus f))’
 >- rw []
 >> CONJ_TAC (* 2 subgoals, same tactics *)
 >> MATCH_MP_TAC pos_fn_integral_cong_measure
 >> rw [FN_PLUS_POS, FN_MINUS_POS]
QED

Theorem integral_cong_measure :
    !sp sts u v f.
        measure_space (sp,sts,u) /\ measure_space (sp,sts,v) /\
       (!s. s IN sts ==> (u s = v s)) ==>
       (integral (sp,sts,u) f = integral (sp,sts,v) f)
Proof
    PROVE_TAC [integral_cong_measure_base]
QED

Theorem integral_cong_measure' :
    !m1 m2 f. measure_space m1 /\ measure_space m2 /\
             (m_space m1 = m_space m2) /\ (measurable_sets m1 = measurable_sets m2) /\
             (!s. s IN measurable_sets m1 ==> (measure m1 s = measure m2 s)) ==>
             (integral m1 f = integral m2 f)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘m_space m1’, ‘measurable_sets m1’, ‘measure m1’, ‘measure m2’, ‘f’]
                    integral_cong_measure)
 >> rw []
QED

Theorem integrable_cong_measure :
    !sp sts u v f.
        measure_space (sp,sts,u) /\ measure_space (sp,sts,v) /\
       (!s. s IN sts ==> (u s = v s)) ==>
       (integrable (sp,sts,u) f <=> integrable (sp,sts,v) f)
Proof
    PROVE_TAC [integral_cong_measure_base]
QED

Theorem integrable_cong_measure' :
    !m1 m2 f. measure_space m1 /\ measure_space m2 /\
             (m_space m1 = m_space m2) /\ (measurable_sets m1 = measurable_sets m2) /\
             (!s. s IN measurable_sets m1 ==> (measure m1 s = measure m2 s)) ==>
             (integrable m1 f <=> integrable m2 f)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘m_space m1’, ‘measurable_sets m1’, ‘measure m1’, ‘measure m2’, ‘f’]
                    integrable_cong_measure)
 >> rw []
QED

(* ------------------------------------------------------------------------- *)
(*  Product measures and Fubini's theorem (Chapter 14 of [1])                *)
(* ------------------------------------------------------------------------- *)

(* FCP version of ‘prod_sigma’ *)
val fcp_sigma_def = Define
   ‘fcp_sigma a b =
      sigma (fcp_cross (space a) (space b)) (fcp_prod (subsets a) (subsets b))’;

(* FCP version of SIGMA_ALGEBRA_PROD_SIGMA *)
Theorem sigma_algebra_prod_sigma :
    !a b. subset_class (space a) (subsets a) /\
          subset_class (space b) (subsets b) ==> sigma_algebra (fcp_sigma a b)
Proof
    RW_TAC std_ss [fcp_sigma_def]
 >> MATCH_MP_TAC SIGMA_ALGEBRA_SIGMA
 >> RW_TAC std_ss [subset_class_def, IN_FCP_PROD, GSPECIFICATION, IN_FCP_CROSS]
 >> fs [subset_class_def]
 >> RW_TAC std_ss [SUBSET_DEF, IN_FCP_CROSS]
 >> METIS_TAC [SUBSET_DEF]
QED

Theorem sigma_algebra_prod_sigma' =
   Q.GENL [‘X’, ‘Y’, ‘A’, ‘B’]
          (REWRITE_RULE [space_def, subsets_def]
                        (Q.SPECL [‘(X,A)’, ‘(Y,B)’] sigma_algebra_prod_sigma));

val general_sigma_def = Define
   ‘general_sigma (cons :'a -> 'b -> 'c) A B =
      sigma (general_cross cons (space A) (space B))
            (general_prod cons (subsets A) (subsets B))’;

(* alternative definition of ‘prod_sigma’ *)
Theorem prod_sigma_alt :
    !A B. prod_sigma A B = general_sigma pair$, A B
Proof
    RW_TAC std_ss [prod_sigma_def, general_sigma_def,
                   GSYM CROSS_ALT, GSYM prod_sets_alt]
QED

(* alternative definition of ‘fcp_sigma’ *)
Theorem fcp_sigma_alt :
    !A B. fcp_sigma A B = general_sigma FCP_CONCAT A B
Proof
    RW_TAC std_ss [fcp_sigma_def, general_sigma_def,
                   GSYM fcp_cross_alt, GSYM fcp_prod_alt]
QED

Theorem sigma_algebra_general_sigma :
    !(cons :'a -> 'b -> 'c) A B.
        subset_class (space A) (subsets A) /\
        subset_class (space B) (subsets B) ==> sigma_algebra (general_sigma cons A B)
Proof
    RW_TAC std_ss [general_sigma_def]
 >> MATCH_MP_TAC SIGMA_ALGEBRA_SIGMA
 >> RW_TAC std_ss [subset_class_def, IN_general_prod, GSPECIFICATION, IN_general_cross]
 >> fs [subset_class_def]
 >> RW_TAC std_ss [SUBSET_DEF, IN_general_cross]
 >> qexistsl_tac [‘a'’, ‘b'’] >> art []
 >> METIS_TAC [SUBSET_DEF]
QED

Theorem exhausting_sequence_general_cross :
    !(cons :'a -> 'b -> 'c) X Y A B f g.
       exhausting_sequence (X,A) f /\ exhausting_sequence (Y,B) g ==>
       exhausting_sequence (general_cross cons X Y,general_prod cons A B)
                           (\n. general_cross cons (f n) (g n))
Proof
    RW_TAC std_ss [exhausting_sequence_alt, space_def, subsets_def,
                   IN_FUNSET, IN_UNIV, IN_general_prod] (* 3 subgoals *)
 >| [ (* goal 1 (of 3) *)
      qexistsl_tac [‘f n’, ‘g n’] >> art [],
      (* goal 2 (of 3) *)
      rw [SUBSET_DEF, IN_general_cross] \\
      qexistsl_tac [‘a’, ‘b’] >> art [] \\
      METIS_TAC [SUBSET_DEF],
      (* goal 3 (of 3) *)
      simp [Once EXTENSION, IN_BIGUNION_IMAGE, IN_general_cross, IN_UNIV] \\
      GEN_TAC >> EQ_TAC >> rpt STRIP_TAC >| (* 2 subgoals *)
      [ (* goal 3.1 (of 2) *)
        qexistsl_tac [‘a’,‘b’] >> art [] \\
        CONJ_TAC >> Q.EXISTS_TAC ‘n’ >> art [],
        (* goal 3.2 (of 2) *)
        rename1 ‘a IN f n1’ \\
        rename1 ‘b IN g n2’ \\
        Q.EXISTS_TAC ‘MAX n1 n2’ \\
        qexistsl_tac [‘a’, ‘b’] >> art [] \\
        CONJ_TAC >| (* 2 subgoals *)
        [ Suff ‘f n1 SUBSET f (MAX n1 n2)’ >- METIS_TAC [SUBSET_DEF] \\
          FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss [],
          Suff ‘g n2 SUBSET g (MAX n1 n2)’ >- METIS_TAC [SUBSET_DEF] \\
          FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss [] ] ] ]
QED

Theorem exhausting_sequence_CROSS :
    !X Y A B f g.
       exhausting_sequence (X,A) f /\ exhausting_sequence (Y,B) g ==>
       exhausting_sequence (X CROSS Y,prod_sets A B) (\n. f n CROSS g n)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘pair$,’, ‘X’, ‘Y’, ‘A’, ‘B’, ‘f’, ‘g’]
                    (INST_TYPE [gamma |-> “:'a # 'b”] exhausting_sequence_general_cross))
 >> RW_TAC std_ss [GSYM CROSS_ALT, GSYM prod_sets_alt]
QED

(* FCP version of exhausting_sequence_CROSS *)
Theorem exhausting_sequence_cross :
    !X Y A B f g.
       exhausting_sequence (X,A) f /\ exhausting_sequence (Y,B) g ==>
       exhausting_sequence (fcp_cross X Y,fcp_prod A B) (\n. fcp_cross (f n) (g n))
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘FCP_CONCAT’, ‘X’, ‘Y’, ‘A’, ‘B’, ‘f’, ‘g’]
                    (((INST_TYPE [“:'temp1” |-> “:'a['b]”]) o
                      (INST_TYPE [“:'temp2” |-> “:'a['c]”]) o
                      (INST_TYPE [gamma |-> “:'a['b + 'c]”]) o
                      (INST_TYPE [alpha |-> “:'temp1”]) o
                      (INST_TYPE [beta |-> “:'temp2”]))
                         exhausting_sequence_general_cross))
 >> RW_TAC std_ss [GSYM fcp_cross_alt, GSYM fcp_prod_alt]
QED

Theorem general_sigma_of_generator :
    !(cons :'a -> 'b -> 'c) (car :'c -> 'a) (cdr :'c -> 'b) (X :'a set) (Y :'b set) E G.
        pair_operation cons car cdr /\
        subset_class X E /\ subset_class Y G /\
        has_exhausting_sequence (X,E) /\ has_exhausting_sequence (Y,G) ==>
       (general_sigma cons (X,E) (Y,G) = general_sigma cons (sigma X E) (sigma Y G))
Proof
    rpt STRIP_TAC
 >> Q.ABBREV_TAC ‘A = sigma X E’
 >> Q.ABBREV_TAC ‘B = sigma Y G’
 >> ONCE_REWRITE_TAC [GSYM SPACE]
 >> ‘general_cross cons (space A) (space B) = general_cross cons X Y’
       by METIS_TAC [SPACE_SIGMA]
 >> Suff ‘subsets (general_sigma cons (X,E) (Y,G)) = subsets (general_sigma cons A B)’
 >- (Know ‘space (general_sigma cons (X,E) (Y,G)) = space (general_sigma cons A B)’
     >- (rw [general_sigma_def, SPACE_SIGMA] \\
         METIS_TAC [SPACE_SIGMA]) >> Rewr' >> Rewr)
 >> rw [SET_EQ_SUBSET] (* 2 subgoals *)
 (* Part I: easy, ‘has_exhausting_sequence’ is not used *)
 >- (rw [general_sigma_def] \\
     MATCH_MP_TAC SIGMA_MONOTONE \\
     rw [IN_general_prod, SUBSET_DEF, GSPECIFICATION] \\
     qexistsl_tac [‘a’,‘b’] >> rw [] >| (* 2 subgoals *)
     [ (* goal 1 (of 2) *)
       Q.UNABBREV_TAC ‘A’ \\
       METIS_TAC [SIGMA_SUBSET_SUBSETS, SUBSET_DEF],
       (* goal 2 (of 2) *)
       Q.UNABBREV_TAC ‘B’ \\
       METIS_TAC [SIGMA_SUBSET_SUBSETS, SUBSET_DEF] ])
 >> ‘sigma_algebra A /\ sigma_algebra B’ by METIS_TAC [SIGMA_ALGEBRA_SIGMA]
 >> ‘sigma_algebra (general_sigma cons (X,E) (Y,G))’
      by (MATCH_MP_TAC sigma_algebra_general_sigma >> rw [])
 (* Part II: hard *)
 >> Q.ABBREV_TAC ‘S = {a | a IN subsets A /\
                          !g. g IN G ==> (general_cross cons a g) IN
                                            subsets (general_sigma cons (X,E) (Y,G))}’
 >> Know ‘sigma_algebra (X,S)’
 >- (simp [SIGMA_ALGEBRA_ALT_SPACE] \\
     CONJ_TAC (* subset_class *)
     >- (RW_TAC std_ss [subset_class_def, Abbr ‘S’, GSPECIFICATION] \\
        ‘X = space A’ by PROVE_TAC [SPACE_SIGMA] >> POP_ORW \\
         METIS_TAC [subset_class_def, SIGMA_ALGEBRA_ALT_SPACE]) \\
     STRONG_CONJ_TAC (* space *)
     >- (RW_TAC std_ss [Abbr ‘S’, GSPECIFICATION]
         >- (‘X = space A’ by PROVE_TAC [SPACE_SIGMA] >> POP_ORW \\
             fs [SIGMA_ALGEBRA_ALT_SPACE]) \\
        ‘?f. f IN (univ(:num) -> E) /\ (!n. f n SUBSET f (SUC n)) /\
             (BIGUNION (IMAGE f univ(:num)) = X)’
           by METIS_TAC [has_exhausting_sequence_def, space_def, subsets_def] \\
         POP_ASSUM (* rewrite only LHS *)
           ((GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites) o wrap o SYM) \\
         REWRITE_TAC [general_BIGUNION_CROSS] \\
         MATCH_MP_TAC SIGMA_ALGEBRA_ENUM >> art [] \\
         rw [general_sigma_def, IN_FUNSET, IN_UNIV] \\
         MATCH_MP_TAC IN_SIGMA \\
         RW_TAC std_ss [general_prod_def, GSPECIFICATION, IN_general_cross] \\
         Q.EXISTS_TAC ‘(f n,g)’ >> fs [IN_FUNSET]) >> DISCH_TAC \\
     CONJ_TAC (* DIFF *)
     >- (GEN_TAC >> fs [Abbr ‘S’, GSPECIFICATION] >> STRIP_TAC \\
         CONJ_TAC >- (‘X = space A’ by PROVE_TAC [SPACE_SIGMA] >> POP_ORW \\
                      fs [SIGMA_ALGEBRA_ALT_SPACE]) \\
         rpt STRIP_TAC \\
         Know ‘general_cross cons (X DIFF s) g =
                 (general_cross cons X g) DIFF (general_cross cons s g)’
         >- (MATCH_MP_TAC general_CROSS_DIFF \\
             qexistsl_tac [‘car’, ‘cdr’] >> art []) >> Rewr' \\
         MATCH_MP_TAC SIGMA_ALGEBRA_DIFF >> simp []) \\
     RW_TAC std_ss [IN_FUNSET, IN_UNIV] \\
     fs [Abbr ‘S’, GSPECIFICATION] \\
     CONJ_TAC >- (MATCH_MP_TAC SIGMA_ALGEBRA_ENUM >> rw [IN_FUNSET, IN_UNIV]) \\
     RW_TAC std_ss [general_BIGUNION_CROSS] \\
     MATCH_MP_TAC SIGMA_ALGEBRA_ENUM >> art [] \\
     rw [general_sigma_def, IN_FUNSET, IN_UNIV]) >> DISCH_TAC
 (* showing ‘E SUBSET S SUBSET subsets A’ *)
 >> Know ‘E SUBSET S’
 >- (RW_TAC std_ss [Abbr ‘S’, SUBSET_DEF, GSPECIFICATION]
     >- (Q.UNABBREV_TAC ‘A’ >> MATCH_MP_TAC IN_SIGMA >> art []) \\
     rw [general_sigma_def] >> MATCH_MP_TAC IN_SIGMA \\
     RW_TAC std_ss [IN_general_prod] \\
     qexistsl_tac [‘x’, ‘g’] >> art []) >> DISCH_TAC
 >> ‘S SUBSET subsets A’
       by (RW_TAC std_ss [Abbr ‘S’, SUBSET_DEF, GSPECIFICATION])
 >> Know ‘S = subsets A’
 >- (Q.UNABBREV_TAC ‘A’ \\
     MATCH_MP_TAC SIGMA_SMALLEST >> art []) >> DISCH_TAC
 >> Know ‘(general_prod cons (subsets A) G) SUBSET
          (subsets (general_sigma cons (X,E) (Y,G)))’
 >- (simp [IN_general_prod, SUBSET_DEF, GSPECIFICATION] \\
     rpt STRIP_TAC >> Know ‘a IN S’ >- PROVE_TAC [] \\
     rw [Abbr ‘S’, GSPECIFICATION])
 (* clean up all assumptions about S *)
 >> NTAC 4 (POP_ASSUM K_TAC) >> Q.UNABBREV_TAC ‘S’
 >> DISCH_TAC
 (* Part III: hard *)
 >> Q.ABBREV_TAC ‘S = {b | b IN subsets B /\
                          !e. e IN E ==>
                             (general_cross cons e b) IN subsets (general_sigma cons (X,E) (Y,G))}’
 >> Know ‘sigma_algebra (Y,S)’
 >- (simp [SIGMA_ALGEBRA_ALT_SPACE] \\
     CONJ_TAC (* subset_class *)
     >- (RW_TAC std_ss [subset_class_def, Abbr ‘S’, GSPECIFICATION] \\
        ‘Y = space B’ by PROVE_TAC [SPACE_SIGMA] >> POP_ORW \\
         METIS_TAC [subset_class_def, SIGMA_ALGEBRA_ALT_SPACE]) \\
     STRONG_CONJ_TAC (* space *)
     >- (RW_TAC std_ss [Abbr ‘S’, GSPECIFICATION]
         >- (‘Y = space B’ by PROVE_TAC [SPACE_SIGMA] >> POP_ORW \\
             fs [SIGMA_ALGEBRA_ALT_SPACE]) \\
        ‘?f. f IN (univ(:num) -> G) /\ (!n. f n SUBSET f (SUC n)) /\
             (BIGUNION (IMAGE f univ(:num)) = Y)’
           by METIS_TAC [has_exhausting_sequence_def, space_def, subsets_def] \\
         POP_ASSUM (* rewrite only LHS *)
           ((GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites) o wrap o SYM) \\
         REWRITE_TAC [general_CROSS_BIGUNION] \\
         MATCH_MP_TAC SIGMA_ALGEBRA_ENUM >> art [] \\
         rw [general_sigma_def, IN_FUNSET, IN_UNIV] \\
         MATCH_MP_TAC IN_SIGMA \\
         RW_TAC std_ss [IN_general_prod] \\
         qexistsl_tac [‘e’, ‘f n’] >> art [] \\
         fs [IN_FUNSET, IN_UNIV]) >> DISCH_TAC \\
     CONJ_TAC (* DIFF *)
     >- (GEN_TAC >> fs [Abbr ‘S’, GSPECIFICATION] >> STRIP_TAC \\
         CONJ_TAC >- (‘Y = space B’ by PROVE_TAC [SPACE_SIGMA] >> POP_ORW \\
                      fs [SIGMA_ALGEBRA_ALT_SPACE]) \\
         rpt STRIP_TAC \\
         Know ‘general_cross cons e (Y DIFF s) =
                (general_cross cons e Y) DIFF (general_cross cons e s)’
         >- (MATCH_MP_TAC general_CROSS_DIFF' \\
             qexistsl_tac [‘car’, ‘cdr’] >> art []) >> Rewr' \\
         MATCH_MP_TAC SIGMA_ALGEBRA_DIFF >> rw []) \\
     RW_TAC std_ss [IN_FUNSET, IN_UNIV] \\
     fs [Abbr ‘S’, GSPECIFICATION] \\
     CONJ_TAC
     >- (MATCH_MP_TAC SIGMA_ALGEBRA_ENUM >> rw [IN_FUNSET, IN_UNIV]) \\
     RW_TAC std_ss [general_CROSS_BIGUNION] \\
     MATCH_MP_TAC SIGMA_ALGEBRA_ENUM >> art [] \\
     rw [general_sigma_def, IN_FUNSET, IN_UNIV]) >> DISCH_TAC
 (* showing ‘E SUBSET S SUBSET subsets A’ *)
 >> Know ‘G SUBSET S’
 >- (RW_TAC std_ss [Abbr ‘S’, SUBSET_DEF, GSPECIFICATION]
     >- (Q.UNABBREV_TAC ‘B’ \\
         MATCH_MP_TAC IN_SIGMA >> art []) \\
     rw [general_sigma_def] >> MATCH_MP_TAC IN_SIGMA \\
     RW_TAC std_ss [IN_general_prod] \\
     qexistsl_tac [‘e’,‘x’] >> art []) >> DISCH_TAC
 >> ‘S SUBSET subsets B’
       by (RW_TAC std_ss [Abbr ‘S’, SUBSET_DEF, GSPECIFICATION])
 >> Know ‘S = subsets B’
 >- (Q.UNABBREV_TAC ‘B’ \\
     MATCH_MP_TAC SIGMA_SMALLEST >> art []) >> DISCH_TAC
 >> Know ‘(general_prod cons E (subsets B)) SUBSET
          (subsets (general_sigma cons (X,E) (Y,G)))’
 >- (simp [IN_general_prod, SUBSET_DEF, GSPECIFICATION] \\
     rpt STRIP_TAC >> Know ‘b IN S’ >- PROVE_TAC [] \\
     rw [Abbr ‘S’, GSPECIFICATION])
 (* clean up all assumptions about S *)
 >> NTAC 4 (POP_ASSUM K_TAC) >> Q.UNABBREV_TAC ‘S’
 >> DISCH_TAC
 (* Part IV: final stage *)
 >> GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites [general_sigma_def]
 >> Q.PAT_X_ASSUM ‘general_cross cons (space A) (space B) =
                   general_cross cons X Y’ (ONCE_REWRITE_TAC o wrap)
 >> Suff ‘general_prod cons (subsets A) (subsets B) SUBSET
          subsets (general_sigma cons (X,E) (Y,G))’
 >- (DISCH_TAC \\
     ASSUME_TAC (Q.SPEC ‘general_cross cons X Y’
                        (INST_TYPE [alpha |-> gamma] SIGMA_MONOTONE)) \\
     POP_ASSUM (MP_TAC o (Q.SPEC ‘general_prod cons (subsets A) (subsets B)’)) \\
     DISCH_THEN (MP_TAC o (Q.SPEC ‘subsets (general_sigma cons (X,E) (Y,G))’)) \\
     RW_TAC std_ss [] \\
     Suff ‘sigma (general_cross cons X Y) (subsets (general_sigma cons (X,E) (Y,G))) =
           general_sigma cons (X,E) (Y,G)’
     >- (DISCH_THEN (fs o wrap)) \\
    ‘general_cross cons X Y = space (general_sigma cons (X,E) (Y,G))’
        by (rw [general_sigma_def, SPACE_SIGMA]) \\
     POP_ORW >> MATCH_MP_TAC SIGMA_STABLE >> art [])
 >> RW_TAC std_ss [IN_general_prod, GSPECIFICATION, SUBSET_DEF]
 (* final goal: a CROSS b IN subsets ((X,E) CROSS (Y,G)) *)
 >> Know ‘general_cross cons a b =
            (general_cross cons a Y) INTER (general_cross cons X b)’
 >- (RW_TAC std_ss [Once EXTENSION, IN_INTER, IN_general_cross] \\
     EQ_TAC >> RW_TAC std_ss [] >| (* 3 subgoals *)
     [ (* goal 1 (of 3) *)
       qexistsl_tac [‘a'’,‘b'’] >> art [] \\
       Suff ‘b SUBSET Y’ >- rw [SUBSET_DEF] \\
      ‘subset_class (space B) (subsets B)’
         by METIS_TAC [sigma_algebra_def, algebra_def, subset_class_def] \\
      ‘Y = space B’ by PROVE_TAC [SPACE_SIGMA] >> POP_ORW \\
       METIS_TAC [subset_class_def],
       (* goal 2 (of 3) *)
       qexistsl_tac [‘a'’,‘b'’] >> art [] \\
       Suff ‘a SUBSET X’ >- rw [SUBSET_DEF] \\
      ‘subset_class (space A) (subsets A)’
         by METIS_TAC [sigma_algebra_def, algebra_def, subset_class_def] \\
      ‘X = space A’ by PROVE_TAC [SPACE_SIGMA] >> POP_ORW \\
       METIS_TAC [subset_class_def],
       (* goal 3 (of 3) *)
       rename1 ‘cons a1 b1 = cons a2 b2’ \\
       qexistsl_tac [‘a2’,‘b2’] >> art [] \\
       Suff ‘b1 = b2’ >- PROVE_TAC [] \\
       METIS_TAC [pair_operation_def] ]) >> Rewr'
 >> ‘?e. e IN (univ(:num) -> E) /\ (!n. e n SUBSET e (SUC n)) /\
         (BIGUNION (IMAGE e univ(:num)) = X)’
      by METIS_TAC [has_exhausting_sequence_def, space_def, subsets_def]
 >> POP_ASSUM (* rewrite only LHS *)
      ((GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites) o wrap o SYM)
 >> ‘?g. g IN (univ(:num) -> G) /\ (!n. g n SUBSET g (SUC n)) /\
         (BIGUNION (IMAGE g univ(:num)) = Y)’
      by METIS_TAC [has_exhausting_sequence_def, space_def, subsets_def]
 >> POP_ASSUM (* rewrite only LHS *)
      ((GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites) o wrap o SYM)
 >> REWRITE_TAC [general_CROSS_BIGUNION, general_BIGUNION_CROSS]
 >> MATCH_MP_TAC SIGMA_ALGEBRA_INTER >> art []
 >> Q.PAT_X_ASSUM ‘sigma_algebra (general_sigma cons (X,E) (Y,G))’
      (STRIP_ASSUME_TAC o
       (REWRITE_RULE [SIGMA_ALGEBRA_ALT_SPACE, IN_FUNSET, IN_UNIV]))
 >> CONJ_TAC
 >| [ (* goal 1 (of 2) *)
      POP_ASSUM MATCH_MP_TAC >> Q.X_GEN_TAC ‘n’ >> BETA_TAC \\
      Suff ‘general_cross cons a (g n) IN general_prod cons (subsets A) G’
      >- PROVE_TAC [SUBSET_DEF] \\
      RW_TAC std_ss [IN_general_prod] \\
      qexistsl_tac [‘a’, ‘g n’] >> fs [IN_FUNSET, IN_UNIV],
      (* goal 2 (of 2) *)
      POP_ASSUM MATCH_MP_TAC >> Q.X_GEN_TAC ‘n’ >> BETA_TAC \\
      Suff ‘general_cross cons (e n) b IN general_prod cons E (subsets B)’
      >- PROVE_TAC [SUBSET_DEF] \\
      RW_TAC std_ss [IN_general_prod] \\
      qexistsl_tac [‘e n’, ‘b’] >> fs [IN_FUNSET, IN_UNIV] ]
QED

(* Lemma 14.3 [1, p.138], reducing consideration of ‘prod_sigma’ to generators *)
Theorem PROD_SIGMA_OF_GENERATOR :
    !X Y E G. subset_class X E /\ subset_class Y G /\
              has_exhausting_sequence (X,E) /\
              has_exhausting_sequence (Y,G) ==>
             ((X,E) CROSS (Y,G) = (sigma X E) CROSS (sigma Y G))
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘pair$,’, ‘FST’, ‘SND’, ‘X’, ‘Y’, ‘E’, ‘G’]
                    (INST_TYPE [gamma |-> “:'a # 'b”] general_sigma_of_generator))
 >> RW_TAC std_ss [GSYM CROSS_ALT, GSYM prod_sets_alt, GSYM prod_sigma_alt,
                   pair_operation_pair]
QED

(* FCP version of PROD_SIGMA_OF_GENERATOR *)
Theorem prod_sigma_of_generator :
    !(X :'a['b] set) (Y :'a['c] set) E G.
        FINITE univ(:'b) /\ FINITE univ(:'c) /\
        subset_class X E /\ subset_class Y G /\
        has_exhausting_sequence (X,E) /\
        has_exhausting_sequence (Y,G) ==>
       (fcp_sigma (X,E) (Y,G) = fcp_sigma (sigma X E) (sigma Y G))
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘FCP_CONCAT’, ‘FCP_FST’, ‘FCP_SND’, ‘X’, ‘Y’, ‘E’, ‘G’]
                    (((INST_TYPE [“:'temp1” |-> “:'a['b]”]) o
                      (INST_TYPE [“:'temp2” |-> “:'a['c]”]) o
                      (INST_TYPE [gamma |-> “:'a['b + 'c]”]) o
                      (INST_TYPE [alpha |-> “:'temp1”]) o
                      (INST_TYPE [beta |-> “:'temp2”])) general_sigma_of_generator))
 >> RW_TAC std_ss [GSYM fcp_cross_alt, GSYM fcp_prod_alt, GSYM fcp_sigma_alt,
                   pair_operation_FCP_CONCAT]
QED

Theorem uniqueness_of_prod_measure_general :
    !(cons :'a -> 'b -> 'c) (car :'c -> 'a) (cdr :'c -> 'b)
     (X :'a set) (Y :'b set) E G A B u v m m'.
      pair_operation cons car cdr /\
      subset_class X E /\ subset_class Y G /\
      sigma_finite (X,E,u) /\ sigma_finite (Y,G,v) /\
     (!s t. s IN E /\ t IN E ==> s INTER t IN E) /\
     (!s t. s IN G /\ t IN G ==> s INTER t IN G) /\
     (A = sigma X E) /\ (B = sigma Y G) /\
      measure_space (X,subsets A,u) /\
      measure_space (Y,subsets B,v) /\
      measure_space (general_cross cons X Y,subsets (general_sigma cons A B),m) /\
      measure_space (general_cross cons X Y,subsets (general_sigma cons A B),m') /\
     (!s t. s IN E /\ t IN G ==> (m  (general_cross cons s t) = u s * v t)) /\
     (!s t. s IN E /\ t IN G ==> (m' (general_cross cons s t) = u s * v t)) ==>
      !x. x IN subsets (general_sigma cons A B) ==> (m x = m' x)
Proof
    rpt GEN_TAC >> STRIP_TAC
 (* applying PROD_SIGMA_OF_GENERATOR *)
 >> Know ‘general_sigma cons A B = general_sigma cons (X,E) (Y,G)’
 >- (simp [Once EQ_SYM_EQ] \\
     MATCH_MP_TAC general_sigma_of_generator >> art [] \\
     qexistsl_tac [‘car’, ‘cdr’] \\
     PROVE_TAC [sigma_finite_has_exhausting_sequence]) >> Rewr'
 >> REWRITE_TAC [general_sigma_def, space_def, subsets_def]
 >> MATCH_MP_TAC UNIQUENESS_OF_MEASURE
 >> ‘sigma_algebra A /\ sigma_algebra B’ by PROVE_TAC [SIGMA_ALGEBRA_SIGMA]
 >> CONJ_TAC (* subset_class *)
 >- (rw [subset_class_def, IN_general_prod, GSPECIFICATION] \\
     MATCH_MP_TAC general_SUBSET_CROSS \\
     fs [subset_class_def])
 >> CONJ_TAC (* INTER-stable *)
 >- (qx_genl_tac [‘a’, ‘b’] \\
     simp [IN_general_prod] >> STRIP_TAC \\
     rename1 ‘a = general_cross cons a1 b1’ \\
     rename1 ‘b = general_cross cons a2 b2’ \\
     qexistsl_tac [‘a1 INTER a2’, ‘b1 INTER b2’] \\
     CONJ_TAC >- (art [] >> MATCH_MP_TAC general_INTER_CROSS \\
                  qexistsl_tac [‘car’, ‘cdr’] >> art []) \\
     PROVE_TAC [])
 >> CONJ_TAC (* sigma_finite *)
 >- (fs [sigma_finite_alt_exhausting_sequence] \\
     Q.EXISTS_TAC ‘\n. general_cross cons (f n) (f' n)’ \\
     CONJ_TAC >- (MATCH_MP_TAC exhausting_sequence_general_cross >> art []) \\
     Q.X_GEN_TAC ‘n’ >> BETA_TAC >> simp [] \\
    ‘positive (X,subsets A,u) /\
     positive (Y,subsets B,v)’ by PROVE_TAC [MEASURE_SPACE_POSITIVE] \\
     fs [GSYM lt_infty] \\
    ‘E SUBSET subsets A /\ G SUBSET subsets B’ by METIS_TAC [SIGMA_SUBSET_SUBSETS] \\
     rename1 ‘!n. v (g n) <> PosInf’ \\
     fs [exhausting_sequence_def, IN_FUNSET, IN_UNIV] \\
    ‘f n IN subsets A /\ g n IN subsets B’ by METIS_TAC [SUBSET_DEF] \\
    ‘u (f n) <> NegInf /\ v (g n) <> NegInf’
       by METIS_TAC [positive_not_infty, measurable_sets_def, measure_def] \\
    ‘?r1. u (f n) = Normal r1’ by METIS_TAC [extreal_cases] >> POP_ORW \\
    ‘?r2. v (g n) = Normal r2’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     REWRITE_TAC [extreal_mul_def, extreal_not_infty])
 (* applying PROD_SIGMA_OF_GENERATOR again *)
 >> Know ‘general_sigma cons (X,E) (Y,G) = general_sigma cons A B’
 >- (simp [] >> MATCH_MP_TAC general_sigma_of_generator >> art [] \\
     PROVE_TAC [sigma_finite_has_exhausting_sequence])
 >> DISCH_THEN (MP_TAC o
                (GEN_REWRITE_RULE (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites
                                  [general_sigma_def]))
 >> REWRITE_TAC [space_def, subsets_def] >> Rewr' >> art []
 >> RW_TAC std_ss [IN_general_prod]
 >> METIS_TAC []
QED

(* Theorem 14.4 [1, p.139], cf. UNIQUENESS_OF_MEASURE *)
Theorem UNIQUENESS_OF_PROD_MEASURE :
    !(X :'a set) (Y :'b set) E G A B u v m m'.
      subset_class X E /\ subset_class Y G /\
      sigma_finite (X,E,u) /\ sigma_finite (Y,G,v) /\
     (!s t. s IN E /\ t IN E ==> s INTER t IN E) /\
     (!s t. s IN G /\ t IN G ==> s INTER t IN G) /\
     (A = sigma X E) /\ (B = sigma Y G) /\
      measure_space (X,subsets A,u) /\
      measure_space (Y,subsets B,v) /\
      measure_space (X CROSS Y,subsets (A CROSS B),m) /\
      measure_space (X CROSS Y,subsets (A CROSS B),m') /\
     (!s t. s IN E /\ t IN G ==> (m  (s CROSS t) = u s * v t)) /\
     (!s t. s IN E /\ t IN G ==> (m' (s CROSS t) = u s * v t)) ==>
      !x. x IN subsets (A CROSS B) ==> (m x = m' x)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘pair$,’,‘FST’,‘SND’,‘X’,‘Y’,‘E’,‘G’,‘A’,‘B’,‘u’,‘v’,‘m’,‘m'’]
                    (INST_TYPE [gamma |-> “:'a # 'b”] uniqueness_of_prod_measure_general))
 >> RW_TAC std_ss [GSYM CROSS_ALT, GSYM prod_sets_alt, GSYM prod_sigma_alt,
                   pair_operation_pair]
QED

(* FCP version of UNIQUENESS_OF_PROD_MEASURE *)
Theorem uniqueness_of_prod_measure :
    !(X :'a['b] set) (Y :'a['c] set) E G A B u v m m'.
      FINITE univ(:'b) /\ FINITE univ(:'c) /\
      subset_class X E /\ subset_class Y G /\
      sigma_finite (X,E,u) /\ sigma_finite (Y,G,v) /\
     (!s t. s IN E /\ t IN E ==> s INTER t IN E) /\
     (!s t. s IN G /\ t IN G ==> s INTER t IN G) /\
     (A = sigma X E) /\ (B = sigma Y G) /\
      measure_space (X,subsets A,u) /\
      measure_space (Y,subsets B,v) /\
      measure_space (fcp_cross X Y,subsets (fcp_sigma A B),m) /\
      measure_space (fcp_cross X Y,subsets (fcp_sigma A B),m') /\
     (!s t. s IN E /\ t IN G ==> (m  (fcp_cross s t) = u s * v t)) /\
     (!s t. s IN E /\ t IN G ==> (m' (fcp_cross s t) = u s * v t)) ==>
      !x. x IN subsets (fcp_sigma A B) ==> (m x = m' x)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘FCP_CONCAT’,‘FCP_FST’,‘FCP_SND’,‘X’,‘Y’,‘E’,‘G’,‘A’,‘B’,‘u’,‘v’,‘m’,‘m'’]
                    (((INST_TYPE [“:'temp1” |-> “:'a['b]”]) o
                      (INST_TYPE [“:'temp2” |-> “:'a['c]”]) o
                      (INST_TYPE [gamma |-> “:'a['b + 'c]”]) o
                      (INST_TYPE [alpha |-> “:'temp1”]) o
                      (INST_TYPE [beta |-> “:'temp2”])) uniqueness_of_prod_measure_general))
 >> RW_TAC std_ss [GSYM fcp_cross_alt, GSYM fcp_prod_alt, GSYM fcp_sigma_alt,
                   pair_operation_FCP_CONCAT]
QED

Theorem uniqueness_of_prod_measure_general' :
    !(cons :'a -> 'b -> 'c) (car :'c -> 'a) (cdr :'c -> 'b)
     (X :'a set) (Y :'b set) A B u v m m'.
      pair_operation cons car cdr /\
      sigma_finite_measure_space (X,A,u) /\
      sigma_finite_measure_space (Y,B,v) /\
      measure_space (general_cross cons X Y,subsets (general_sigma cons (X,A) (Y,B)),m) /\
      measure_space (general_cross cons X Y,subsets (general_sigma cons (X,A) (Y,B)),m') /\
     (!s t. s IN A /\ t IN B ==> (m  (general_cross cons s t) = u s * v t)) /\
     (!s t. s IN A /\ t IN B ==> (m' (general_cross cons s t) = u s * v t)) ==>
      !x. x IN subsets (general_sigma cons (X,A) (Y,B)) ==> (m x = m' x)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘cons’,‘car’,‘cdr’,‘X’,‘Y’,‘A’,‘B’,‘(X,A)’,‘(Y,B)’,‘u’,‘v’,‘m’,‘m'’]
                    uniqueness_of_prod_measure_general)
 >> fs [sigma_finite_measure_space_def]
 >> ‘sigma_algebra (X,A) /\ sigma_algebra (Y,B)’
      by METIS_TAC [measure_space_def, m_space_def, measurable_sets_def]
 >> ‘sigma X A = (X,A) /\ sigma Y B = (Y,B)’
      by METIS_TAC [SIGMA_STABLE, space_def, subsets_def]
 >> Know ‘!s t. s IN A /\ t IN A ==> s INTER t IN A’
 >- (rpt STRIP_TAC \\
     MATCH_MP_TAC (REWRITE_RULE [space_def, subsets_def]
                                (Q.SPEC ‘(X,A)’ SIGMA_ALGEBRA_INTER)) \\
     ASM_REWRITE_TAC [])
 >> Know ‘!s t. s IN B /\ t IN B ==> s INTER t IN B’
 >- (rpt STRIP_TAC \\
     MATCH_MP_TAC (REWRITE_RULE [space_def, subsets_def]
                                (Q.SPEC ‘(Y,B)’ SIGMA_ALGEBRA_INTER)) \\
     ASM_REWRITE_TAC [])
 >> RW_TAC std_ss []
 >> FIRST_X_ASSUM irule
 >> fs [sigma_algebra_def, algebra_def]
QED

(* A specialized version for sigma-algebras instead of generators *)
Theorem UNIQUENESS_OF_PROD_MEASURE' :
    !(X :'a set) (Y :'b set) A B u v m m'.
      sigma_finite_measure_space (X,A,u) /\
      sigma_finite_measure_space (Y,B,v) /\
      measure_space (X CROSS Y,subsets ((X,A) CROSS (Y,B)),m) /\
      measure_space (X CROSS Y,subsets ((X,A) CROSS (Y,B)),m') /\
     (!s t. s IN A /\ t IN B ==> (m  (s CROSS t) = u s * v t)) /\
     (!s t. s IN A /\ t IN B ==> (m' (s CROSS t) = u s * v t)) ==>
      !x. x IN subsets ((X,A) CROSS (Y,B)) ==> (m x = m' x)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘pair$,’,‘FST’,‘SND’,‘X’,‘Y’,‘A’,‘B’,‘u’,‘v’,‘m’,‘m'’]
                    (INST_TYPE [gamma |-> “:'a # 'b”] uniqueness_of_prod_measure_general'))
 >> RW_TAC std_ss [GSYM CROSS_ALT, GSYM prod_sets_alt, GSYM prod_sigma_alt,
                   pair_operation_pair]
QED

(* FCP version of UNIQUENESS_OF_PROD_MEASURE' *)
Theorem uniqueness_of_prod_measure' :
    !(X :'a['b] set) (Y :'a['c] set) A B u v m m'.
      FINITE univ(:'b) /\ FINITE univ(:'c) /\
      sigma_finite_measure_space (X,A,u) /\
      sigma_finite_measure_space (Y,B,v) /\
      measure_space (fcp_cross X Y,subsets (fcp_sigma (X,A) (Y,B)),m) /\
      measure_space (fcp_cross X Y,subsets (fcp_sigma (X,A) (Y,B)),m') /\
     (!s t. s IN A /\ t IN B ==> (m  (fcp_cross s t) = u s * v t)) /\
     (!s t. s IN A /\ t IN B ==> (m' (fcp_cross s t) = u s * v t)) ==>
      !x. x IN subsets (fcp_sigma (X,A) (Y,B)) ==> (m x = m' x)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘FCP_CONCAT’,‘FCP_FST’,‘FCP_SND’,‘X’,‘Y’,‘A’,‘B’,‘u’,‘v’,‘m’,‘m'’]
                    (((INST_TYPE [“:'temp1” |-> “:'a['b]”]) o
                      (INST_TYPE [“:'temp2” |-> “:'a['c]”]) o
                      (INST_TYPE [gamma |-> “:'a['b + 'c]”]) o
                      (INST_TYPE [alpha |-> “:'temp1”]) o
                      (INST_TYPE [beta |-> “:'temp2”])) uniqueness_of_prod_measure_general'))
 >> RW_TAC std_ss [GSYM fcp_cross_alt, GSYM fcp_prod_alt, GSYM fcp_sigma_alt,
                   pair_operation_FCP_CONCAT]
QED

Theorem existence_of_prod_measure_general :
   !(cons :'a -> 'b -> 'c) car cdr (X :'a set) (Y :'b set) A B u v m0.
       pair_operation cons car cdr /\
       sigma_finite_measure_space (X,A,u) /\
       sigma_finite_measure_space (Y,B,v) /\
       (!s t. s IN A /\ t IN B ==> (m0 (general_cross cons s t) = u s * v t)) ==>
       (!s. s IN subsets (general_sigma cons (X,A) (Y,B)) ==>
           (!x. x IN X ==> (\y. indicator_fn s (cons x y)) IN measurable (Y,B) Borel) /\
           (!y. y IN Y ==> (\x. indicator_fn s (cons x y)) IN measurable (X,A) Borel) /\
           (\y. pos_fn_integral (X,A,u)
                  (\x. indicator_fn s (cons x y))) IN measurable (Y,B) Borel /\
           (\x. pos_fn_integral (Y,B,v)
                  (\y. indicator_fn s (cons x y))) IN measurable (X,A) Borel) /\
       ?m. sigma_finite_measure_space (general_cross cons X Y,
                                       subsets (general_sigma cons (X,A) (Y,B)),m) /\
           (!s. s IN (general_prod cons A B) ==> (m s = m0 s)) /\
           (!s. s IN subsets (general_sigma cons (X,A) (Y,B)) ==>
               (m s = pos_fn_integral (Y,B,v)
                        (\y. pos_fn_integral (X,A,u) (\x. indicator_fn s (cons x y)))) /\
               (m s = pos_fn_integral (X,A,u)
                        (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn s (cons x y)))))
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> fs [sigma_finite_measure_space_def, sigma_finite_alt_exhausting_sequence]
 >> ‘sigma_algebra (X,A) /\ sigma_algebra (Y,B)’
      by PROVE_TAC [measure_space_def, m_space_def, measurable_sets_def,
                    space_def, subsets_def]
 >> rename1 ‘!n. u (a n) < PosInf’
 >> rename1 ‘!n. v (b n) < PosInf’
 >> Q.ABBREV_TAC ‘E = \n. general_cross cons (a n) (b n)’
 (* (D n) is supposed to be a dynkin system *)
 >> Q.ABBREV_TAC ‘D = \n.
     {d | d SUBSET (general_cross cons X Y) /\
          (!x. x IN X ==>
               (\y. indicator_fn (d INTER (E n)) (cons x y)) IN Borel_measurable (Y,B)) /\
          (!y. y IN Y ==>
               (\x. indicator_fn (d INTER (E n)) (cons x y)) IN Borel_measurable (X,A)) /\
          (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER (E n)) (cons x y)))
                 IN Borel_measurable (Y,B) /\
          (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER (E n)) (cons x y)))
                 IN Borel_measurable (X,A) /\
          (pos_fn_integral (X,A,u)
             (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER (E n)) (cons x y))) =
           pos_fn_integral (Y,B,v)
             (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER (E n)) (cons x y))))}’
 >> Know ‘!n. (general_prod cons A B) SUBSET (D n)’
 >- (rw [IN_general_prod, SUBSET_DEF] \\
     rename1 ‘s IN A’ >> rename1 ‘t IN B’ \\
     Q.UNABBREV_TAC ‘D’ >> BETA_TAC >> simp [GSPECIFICATION] \\
     CONJ_TAC (* (s CROSS t) SUBSET (X CROSS Y) *)
     >- (MATCH_MP_TAC general_SUBSET_CROSS \\
        ‘subset_class X A /\ subset_class Y B’
            by PROVE_TAC [measure_space_def, SIGMA_ALGEBRA_ALT_SPACE, m_space_def,
                          measurable_sets_def, space_def, subsets_def] \\
         fs [subset_class_def]) \\
     Q.UNABBREV_TAC ‘E’ >> BETA_TAC \\
     rfs [exhausting_sequence_def, IN_FUNSET, IN_UNIV] \\
  (* key separation *)
     Know ‘!x y. indicator_fn ((general_cross cons s t) INTER
                               (general_cross cons (a n) (b n))) (cons x y) =
                 indicator_fn (s INTER a n) x * indicator_fn (t INTER b n) y’
     >- (rpt GEN_TAC \\
         Know ‘general_cross cons s t INTER general_cross cons (a n) (b n) =
               general_cross cons (s INTER a n) (t INTER b n)’
         >- (MATCH_MP_TAC general_INTER_CROSS \\
             qexistsl_tac [‘car’, ‘cdr’] >> art []) >> Rewr' \\
         MATCH_MP_TAC indicator_fn_general_cross \\
         qexistsl_tac [‘car’, ‘cdr’] >> art []) >> Rewr' \\
  (* from now on FCP is not needed any more *)
     STRONG_CONJ_TAC (* Borel_measurable #1 *)
     >- (rpt STRIP_TAC \\
        ‘?r. indicator_fn (s INTER a n) x = Normal r’
            by METIS_TAC [indicator_fn_normal] >> POP_ORW \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> art [subsets_def] \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(Y,B) :'b algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> DISCH_TAC \\
     STRONG_CONJ_TAC (* Borel_measurable #2 *)
     >- (rpt STRIP_TAC >> ONCE_REWRITE_TAC [mul_comm] \\
        ‘?r. indicator_fn (t INTER b n) y = Normal r’
            by METIS_TAC [indicator_fn_normal] >> POP_ORW \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> art [subsets_def] \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(X,A) :'a algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> DISCH_TAC \\
     STRONG_CONJ_TAC (* Borel_measurable #3 *)
     >- (Know ‘!y. pos_fn_integral (X,A,u) (\x. indicator_fn (s INTER a n) x *
                                                indicator_fn (t INTER b n) y) =
                   indicator_fn (t INTER b n) y *
                   pos_fn_integral (X,A,u) (indicator_fn (s INTER a n))’
         >- (GEN_TAC \\
            ‘?r. 0 <= r /\ (indicator_fn (t INTER b n) y = Normal r)’
                by METIS_TAC [indicator_fn_normal] >> POP_ORW \\
             GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites [mul_comm] \\
             MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
         ONCE_REWRITE_TAC [mul_comm] \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR' >> art [subsets_def] \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(Y,B) :'b algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> DISCH_TAC \\
     STRONG_CONJ_TAC (* Borel_measurable #4 *)
     >- (Know ‘!x. pos_fn_integral (Y,B,v) (\y. indicator_fn (s INTER a n) x *
                                                indicator_fn (t INTER b n) y) =
                   indicator_fn (s INTER a n) x *
                   pos_fn_integral (Y,B,v) (indicator_fn (t INTER b n))’
         >- (GEN_TAC \\
            ‘?r. 0 <= r /\ (indicator_fn (s INTER a n) x = Normal r)’
                by METIS_TAC [indicator_fn_normal] >> POP_ORW \\
             MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
         ONCE_REWRITE_TAC [mul_comm] \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR' >> art [subsets_def] \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(X,A) :'a algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> DISCH_TAC \\
     Know ‘!x. pos_fn_integral (Y,B,v) (\y. indicator_fn (s INTER a n) x *
                                            indicator_fn (t INTER b n) y) =
               indicator_fn (s INTER a n) x *
               pos_fn_integral (Y,B,v) (indicator_fn (t INTER b n))’
     >- (GEN_TAC \\
        ‘?r. 0 <= r /\ (indicator_fn (s INTER a n) x = Normal r)’
            by METIS_TAC [indicator_fn_normal] >> POP_ORW \\
         MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
     Know ‘!y. pos_fn_integral (X,A,u) (\x. indicator_fn (s INTER a n) x *
                                            indicator_fn (t INTER b n) y) =
               indicator_fn (t INTER b n) y *
               pos_fn_integral (X,A,u) (indicator_fn (s INTER a n))’
     >- (GEN_TAC \\
        ‘?r. 0 <= r /\ (indicator_fn (t INTER b n) y = Normal r)’
            by METIS_TAC [indicator_fn_normal] >> POP_ORW \\
         GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites [mul_comm] \\
         MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
     Know ‘pos_fn_integral (Y,B,v) (indicator_fn (t INTER b n)) =
           measure (Y,B,v) (t INTER b n)’
     >- (MATCH_MP_TAC pos_fn_integral_indicator >> art [measurable_sets_def] \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(Y,B) :'b algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> Rewr' \\
     Know ‘pos_fn_integral (X,A,u) (indicator_fn (s INTER a n)) =
           measure (X,A,u) (s INTER a n)’
     >- (MATCH_MP_TAC pos_fn_integral_indicator >> art [measurable_sets_def] \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(X,A) :'a algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> Rewr' \\
     ONCE_REWRITE_TAC [mul_comm] >> REWRITE_TAC [measure_def] \\
  (* reduce u() and v() to normal extreals *)
     Know ‘u (s INTER a n) <> PosInf’
     >- (REWRITE_TAC [lt_infty] \\
         MATCH_MP_TAC let_trans >> Q.EXISTS_TAC ‘u (a n)’ >> art [] \\
         MATCH_MP_TAC (REWRITE_RULE [measurable_sets_def, measure_def]
                                    (Q.SPEC ‘(X,A,u)’ INCREASING)) \\
         CONJ_TAC >- (MATCH_MP_TAC MEASURE_SPACE_INCREASING >> art []) \\
         ASM_REWRITE_TAC [INTER_SUBSET] \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(X,A) :'a algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> DISCH_TAC \\
     Know ‘v (t INTER b n) <> PosInf’
     >- (REWRITE_TAC [lt_infty] \\
         MATCH_MP_TAC let_trans >> Q.EXISTS_TAC ‘v (b n)’ >> art [] \\
         MATCH_MP_TAC (REWRITE_RULE [measurable_sets_def, measure_def]
                                    (Q.SPEC ‘(Y,B,v)’ INCREASING)) \\
         CONJ_TAC >- (MATCH_MP_TAC MEASURE_SPACE_INCREASING >> art []) \\
         ASM_REWRITE_TAC [INTER_SUBSET] \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(Y,B) :'a algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> DISCH_TAC \\
     IMP_RES_TAC MEASURE_SPACE_POSITIVE >> rfs [positive_def] \\
     Know ‘0 <= u (s INTER a n)’
     >- (FIRST_X_ASSUM MATCH_MP_TAC \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(X,A) :'a algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> DISCH_TAC \\
     Know ‘0 <= v (t INTER b n)’
     >- (FIRST_X_ASSUM MATCH_MP_TAC \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(Y,B) :'b algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> DISCH_TAC \\
    ‘u (s INTER a n) <> NegInf /\ v (t INTER b n) <> NegInf’
        by PROVE_TAC [pos_not_neginf] \\
    ‘?r1. u (s INTER a n) = Normal r1’ by METIS_TAC [extreal_cases] \\
    ‘?r2. v (t INTER b n) = Normal r2’ by METIS_TAC [extreal_cases] \\
    ‘0 <= r1 /\ 0 <= r2’ by METIS_TAC [extreal_of_num_def, extreal_le_eq] >> art [] \\
     Know ‘pos_fn_integral (X,A,u) (\x. Normal r2 * indicator_fn (s INTER a n) x) =
           Normal r2 * pos_fn_integral (X,A,u) (indicator_fn (s INTER a n))’
     >- (MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
     Know ‘pos_fn_integral (Y,B,v) (\y. Normal r1 * indicator_fn (t INTER b n) y) =
           Normal r1 * pos_fn_integral (Y,B,v) (indicator_fn (t INTER b n))’
     >- (MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
     Know ‘pos_fn_integral (Y,B,v) (indicator_fn (t INTER b n)) =
           measure (Y,B,v) (t INTER b n)’
     >- (MATCH_MP_TAC pos_fn_integral_indicator >> art [measurable_sets_def] \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(Y,B) :'b algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> Rewr' \\
     Know ‘pos_fn_integral (X,A,u) (indicator_fn (s INTER a n)) =
           measure (X,A,u) (s INTER a n)’
     >- (MATCH_MP_TAC pos_fn_integral_indicator >> art [measurable_sets_def] \\
         MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                    (ISPEC “(X,A) :'a algebra” SIGMA_ALGEBRA_INTER)) \\
         rw []) >> Rewr' \\
     ASM_REWRITE_TAC [measure_def, Once mul_comm]) >> DISCH_TAC
 (* a basic property of D *)
 >> Know ‘!n. E n IN D n’
 >- (rw [Abbr ‘E’] \\
     Suff ‘general_cross cons (a n) (b n) IN general_prod cons A B’ >- PROVE_TAC [SUBSET_DEF] \\
     rw [IN_general_prod] >> qexistsl_tac [‘a n’, ‘b n’] >> REWRITE_TAC [] \\
     REV_FULL_SIMP_TAC std_ss [exhausting_sequence_def, IN_FUNSET, IN_UNIV, subsets_def])
 >> DISCH_TAC
 (* The following 4 D-properties are frequently needed.
    Note: the quantifiers (n,d,x,y) can be anything, in particular it's NOT
          required that ‘x IN X’ or ‘y IN y’ or ‘d IN D n’ *)
 >> ‘!n d y. pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y)) <> NegInf’
      by (rpt GEN_TAC >> MATCH_MP_TAC pos_not_neginf \\
          MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS])
 >> Know ‘!n d y. pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y)) <> PosInf’
 >- (rw [Abbr ‘E’, lt_infty] >> MATCH_MP_TAC let_trans \\
     Q.EXISTS_TAC ‘pos_fn_integral (X,A,u)
                     (\x. indicator_fn (general_cross cons (a n) (b n)) (cons x y))’ \\
     CONJ_TAC >- (MATCH_MP_TAC pos_fn_integral_mono >> rw [INDICATOR_FN_POS] \\
                  MATCH_MP_TAC INDICATOR_FN_MONO >> REWRITE_TAC [INTER_SUBSET]) \\
     Know ‘!x. indicator_fn (general_cross cons (a n) (b n)) (cons x y) =
               indicator_fn (a n) x * indicator_fn (b n) y’
     >- (MATCH_MP_TAC indicator_fn_general_cross \\
         qexistsl_tac [‘car’, ‘cdr’] >> art []) >> Rewr' \\
     ONCE_REWRITE_TAC [mul_comm] \\
    ‘?r. 0 <= r /\ indicator_fn (b n) y = Normal r’
        by METIS_TAC [indicator_fn_normal] >> POP_ORW \\
     Know ‘pos_fn_integral (X,A,u) (\x. Normal r * indicator_fn (a n) x) =
           Normal r * pos_fn_integral (X,A,u) (indicator_fn (a n))’
     >- (MATCH_MP_TAC pos_fn_integral_cmul >> simp [INDICATOR_FN_POS]) >> Rewr' \\
     Know ‘pos_fn_integral (X,A,u) (indicator_fn (a n)) = measure (X,A,u) (a n)’
     >- (MATCH_MP_TAC pos_fn_integral_indicator >> art [measurable_sets_def] \\
         FULL_SIMP_TAC std_ss [exhausting_sequence_def, subsets_def, IN_FUNSET, IN_UNIV]) \\
     REWRITE_TAC [measure_def] >> Rewr' \\
     REWRITE_TAC [GSYM lt_infty] \\
     IMP_RES_TAC MEASURE_SPACE_POSITIVE \\
     REV_FULL_SIMP_TAC std_ss [positive_def, exhausting_sequence_def,
                               IN_FUNSET, IN_UNIV, space_def, subsets_def,
                               measurable_sets_def, measure_def] \\
     Know ‘u (a n) <> PosInf /\ u (a n) <> NegInf’
     >- (CONJ_TAC >- art [lt_infty] \\
         MATCH_MP_TAC pos_not_neginf \\
         FIRST_X_ASSUM MATCH_MP_TAC >> art []) >> STRIP_TAC \\
    ‘?z. u (a n) = Normal z’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     REWRITE_TAC [extreal_mul_def, extreal_not_infty]) >> DISCH_TAC
 >> ‘!n d x. pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y)) <> NegInf’
      by (rpt GEN_TAC >> MATCH_MP_TAC pos_not_neginf \\
          MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS])
 >> Know ‘!n d x. pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y)) <> PosInf’
 >- (rw [Abbr ‘E’, lt_infty] >> MATCH_MP_TAC let_trans \\
     Q.EXISTS_TAC ‘pos_fn_integral (Y,B,v)
                     (\y. indicator_fn (general_cross cons (a n) (b n)) (cons x y))’ \\
     CONJ_TAC >- (MATCH_MP_TAC pos_fn_integral_mono >> rw [INDICATOR_FN_POS] \\
                  MATCH_MP_TAC INDICATOR_FN_MONO >> REWRITE_TAC [INTER_SUBSET]) \\
     Know ‘!y. indicator_fn (general_cross cons (a n) (b n)) (cons x y) =
               indicator_fn (a n) x * indicator_fn (b n) y’
     >- (MATCH_MP_TAC indicator_fn_general_cross \\
         qexistsl_tac [‘car’, ‘cdr’] >> art []) >> Rewr' \\
    ‘?r. 0 <= r /\ indicator_fn (a n) x = Normal r’
        by METIS_TAC [indicator_fn_normal] >> POP_ORW \\
     Know ‘pos_fn_integral (Y,B,v) (\y. Normal r * indicator_fn (b n) y) =
           Normal r * pos_fn_integral (Y,B,v) (indicator_fn (b n))’
     >- (MATCH_MP_TAC pos_fn_integral_cmul >> simp [INDICATOR_FN_POS]) >> Rewr' \\
     Know ‘pos_fn_integral (Y,B,v) (indicator_fn (b n)) = measure (Y,B,v) (b n)’
     >- (MATCH_MP_TAC pos_fn_integral_indicator >> art [measurable_sets_def] \\
         FULL_SIMP_TAC std_ss [exhausting_sequence_def, subsets_def, IN_FUNSET, IN_UNIV]) \\
     REWRITE_TAC [measure_def] >> Rewr' \\
     REWRITE_TAC [GSYM lt_infty] \\
     IMP_RES_TAC MEASURE_SPACE_POSITIVE \\
     REV_FULL_SIMP_TAC std_ss [positive_def, exhausting_sequence_def,
                               IN_FUNSET, IN_UNIV, space_def, subsets_def,
                               measurable_sets_def, measure_def] \\
     Know ‘v (b n) <> PosInf /\ v (b n) <> NegInf’
     >- (CONJ_TAC >- art [lt_infty] \\
         MATCH_MP_TAC pos_not_neginf \\
         FIRST_X_ASSUM MATCH_MP_TAC >> art []) >> STRIP_TAC \\
    ‘?z. v (b n) = Normal z’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     REWRITE_TAC [extreal_mul_def, extreal_not_infty]) >> DISCH_TAC
 (* key property: D n is a dynkin system *)
 >> Know ‘!n. dynkin_system (general_cross cons X Y,D n)’
 >- (rw [dynkin_system_def] >| (* 4 subgoals *)
     [ (* goal 1 (of 4) *)
       rw [subset_class_def, Abbr ‘D’],
       (* goal 2 (of 4) *)
       Suff ‘general_cross cons X Y IN general_prod cons A B’ >- PROVE_TAC [SUBSET_DEF] \\
       rw [IN_general_prod] >> qexistsl_tac [‘X’, ‘Y’] >> REWRITE_TAC [] \\
       fs [SIGMA_ALGEBRA_ALT_SPACE],
       (* goal 3 (of 4): DIFF (hard) *)
       rename1 ‘(general_cross cons X Y) DIFF d IN D n’ \\
    (* expanding D without touching assumptions *)
       Suff ‘(general_cross cons X Y) DIFF d IN
             {d | d SUBSET general_cross cons X Y /\
                 (!x. x IN X ==>
                      (\y. indicator_fn (d INTER E n) (cons x y)) IN Borel_measurable (Y,B)) /\
                 (!y. y IN Y ==>
                      (\x. indicator_fn (d INTER E n) (cons x y)) IN Borel_measurable (X,A)) /\
                 (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y)))
                        IN Borel_measurable (Y,B) /\
                 (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y)))
                        IN Borel_measurable (X,A) /\
                 pos_fn_integral (X,A,u)
                   (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y))) =
                 pos_fn_integral (Y,B,v)
                   (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y)))}’
       >- METIS_TAC [Abbr ‘D’] >> simp [GSPECIFICATION] \\
       Know ‘indicator_fn (((general_cross cons X Y) DIFF d) INTER E n) =
               (\t. indicator_fn (E n) t - indicator_fn (d INTER E n) t)’
       >- (ONCE_REWRITE_TAC [INTER_COMM] \\
           MATCH_MP_TAC INDICATOR_FN_DIFF_SPACE \\
           rw [Abbr ‘E’]
           >- (MATCH_MP_TAC general_SUBSET_CROSS \\
               FULL_SIMP_TAC std_ss [exhausting_sequence_def, IN_FUNSET, IN_UNIV,
                                     subsets_def, space_def] \\
               METIS_TAC [sigma_algebra_def, algebra_def, subset_class_def,
                          space_def, subsets_def]) \\
           REV_FULL_SIMP_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) >> Rewr' >> BETA_TAC \\
       STRONG_CONJ_TAC (* Borel_measurable #1 *)
       >- (rpt STRIP_TAC \\
           MATCH_MP_TAC IN_MEASURABLE_BOREL_SUB >> BETA_TAC \\
           qexistsl_tac [‘\y. indicator_fn (E n) (cons x y)’,
                         ‘\y. indicator_fn (d INTER E n) (cons x y)’] \\
           rw [INDICATOR_FN_NOT_INFTY] >|
           [ (* goal 1 (of 2) *)
            ‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
             REV_FULL_SIMP_TAC std_ss [Abbr ‘D’, GSPECIFICATION],
             (* goal 2 (of 2) *)
             FULL_SIMP_TAC std_ss [Abbr ‘D’, GSPECIFICATION] ]) >> DISCH_TAC \\
       STRONG_CONJ_TAC (* Borel_measurable #2 (symmetric with #1) *)
       >- (rpt STRIP_TAC \\
           MATCH_MP_TAC IN_MEASURABLE_BOREL_SUB >> BETA_TAC \\
           qexistsl_tac [‘\x. indicator_fn (E n) (cons x y)’,
                         ‘\x. indicator_fn (d INTER E n) (cons x y)’] \\
           rw [INDICATOR_FN_NOT_INFTY] >|
           [ (* goal 1 (of 2) *)
            ‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
             FULL_SIMP_TAC std_ss [Abbr ‘D’, GSPECIFICATION],
             (* goal 2 (of 2) *)
             FULL_SIMP_TAC std_ss [Abbr ‘D’, GSPECIFICATION] ]) >> DISCH_TAC \\
       CONJ_TAC (* Borel_measurable #3 *)
       >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                      (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) \\
           Q.EXISTS_TAC ‘\y. pos_fn_integral (X,A,u) (\x. indicator_fn (E n) (cons x y)) -
                             pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y))’ \\
           reverse CONJ_TAC
           >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_SUB >> BETA_TAC >> art [space_def] \\
               qexistsl_tac [‘\y. pos_fn_integral (X,A,u) (\x. indicator_fn (E n) (cons x y))’,
                             ‘\y. pos_fn_integral (X,A,u)
                                    (\x. indicator_fn (d INTER E n) (cons x y))’] \\
               rw [] >| (* 2 subgoals *)
               [ (* goal 1 (of 2) *)
                ‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
                 Q.PAT_X_ASSUM ‘!n. E n IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                 RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION],
                 (* goal 2 (of 2) *)
                 Q.PAT_X_ASSUM ‘d IN D n’ MP_TAC \\
                 RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION] ]) \\
           Q.X_GEN_TAC ‘y’ >> STRIP_TAC >> BETA_TAC \\
           HO_MATCH_MP_TAC pos_fn_integral_sub \\
           simp [INDICATOR_FN_POS, INDICATOR_FN_NOT_INFTY] \\
           CONJ_TAC >- (‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
                        Q.PAT_X_ASSUM ‘!n. E n IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           CONJ_TAC >- (Q.PAT_X_ASSUM ‘d IN D n’ MP_TAC \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           rpt STRIP_TAC \\
           MATCH_MP_TAC INDICATOR_FN_MONO >> REWRITE_TAC [INTER_SUBSET]) \\
       CONJ_TAC (* Borel_measurable #4 (symmetric with #3) *)
       >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                      (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) \\
           Q.EXISTS_TAC ‘\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (E n) (cons x y)) -
                             pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y))’ \\
           reverse CONJ_TAC
           >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_SUB >> BETA_TAC >> art [space_def] \\
               qexistsl_tac [‘\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (E n) (cons x y))’,
                             ‘\x. pos_fn_integral (Y,B,v)
                                    (\y. indicator_fn (d INTER E n) (cons x y))’] \\
               rw [] >| (* 2 subgoals *)
               [ (* goal 1 (of 2) *)
                ‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
                 Q.PAT_X_ASSUM ‘!n. E n IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                 RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION],
                 (* goal 2 (of 2) *)
                 Q.PAT_X_ASSUM ‘d IN D n’ MP_TAC \\
                 RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION] ]) \\
           Q.X_GEN_TAC ‘x’ >> STRIP_TAC >> BETA_TAC \\
           HO_MATCH_MP_TAC pos_fn_integral_sub \\
           simp [INDICATOR_FN_POS, INDICATOR_FN_NOT_INFTY] \\
           CONJ_TAC >- (‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
                        Q.PAT_X_ASSUM ‘!n. E n IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           CONJ_TAC >- (Q.PAT_X_ASSUM ‘d IN D n’ MP_TAC \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           rpt STRIP_TAC \\
           MATCH_MP_TAC INDICATOR_FN_MONO >> REWRITE_TAC [INTER_SUBSET]) \\
       Know ‘pos_fn_integral (X,A,u)
               (\x. pos_fn_integral (Y,B,v)
                      (\y. indicator_fn (E n) (cons x y) -
                           indicator_fn (d INTER E n) (cons x y))) =
             pos_fn_integral (X,A,u)
               (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (E n) (cons x y)) -
                    pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y)))’
       >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
           CONJ_TAC >- (rpt STRIP_TAC \\
                        MATCH_MP_TAC pos_fn_integral_pos >> simp [] \\
                        Q.X_GEN_TAC ‘y’ >> STRIP_TAC \\
                        MATCH_MP_TAC le_sub_imp \\
                        simp [INDICATOR_FN_NOT_INFTY, add_lzero] \\
                        MATCH_MP_TAC INDICATOR_FN_MONO >> rw [INTER_SUBSET]) \\
           CONJ_TAC >- (rpt STRIP_TAC \\
                        MATCH_MP_TAC le_sub_imp >> simp [add_lzero] \\
                        MATCH_MP_TAC pos_fn_integral_mono >> rw [INDICATOR_FN_POS] \\
                        MATCH_MP_TAC INDICATOR_FN_MONO >> rw [INTER_SUBSET]) \\
           rpt STRIP_TAC \\
           HO_MATCH_MP_TAC pos_fn_integral_sub \\
           simp [INDICATOR_FN_POS, INDICATOR_FN_NOT_INFTY] \\
           CONJ_TAC >- (‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
                        Q.PAT_X_ASSUM ‘!n. E n IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           CONJ_TAC >- (Q.PAT_X_ASSUM ‘d IN D n’ MP_TAC \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           rpt STRIP_TAC \\
           MATCH_MP_TAC INDICATOR_FN_MONO >> REWRITE_TAC [INTER_SUBSET]) >> Rewr' \\
       Know ‘pos_fn_integral (Y,B,v)
               (\y. pos_fn_integral (X,A,u)
                      (\x. indicator_fn (E n) (cons x y) -
                           indicator_fn (d INTER E n) (cons x y))) =
             pos_fn_integral (Y,B,v)
               (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (E n) (cons x y)) -
                    pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y)))’
       >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
           CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                        MATCH_MP_TAC pos_fn_integral_pos >> simp [] \\
                        Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                        MATCH_MP_TAC le_sub_imp \\
                        simp [INDICATOR_FN_NOT_INFTY, add_lzero] \\
                        MATCH_MP_TAC INDICATOR_FN_MONO >> rw [INTER_SUBSET]) \\
           CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                        MATCH_MP_TAC le_sub_imp >> simp [add_lzero] \\
                        MATCH_MP_TAC pos_fn_integral_mono >> rw [INDICATOR_FN_POS] \\
                        MATCH_MP_TAC INDICATOR_FN_MONO >> rw [INTER_SUBSET]) \\
           Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
           HO_MATCH_MP_TAC pos_fn_integral_sub \\
           simp [INDICATOR_FN_POS, INDICATOR_FN_NOT_INFTY] \\
           CONJ_TAC >- (‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
                        Q.PAT_X_ASSUM ‘!n. E n IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           CONJ_TAC >- (Q.PAT_X_ASSUM ‘d IN D n’ MP_TAC \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
           MATCH_MP_TAC INDICATOR_FN_MONO >> REWRITE_TAC [INTER_SUBSET]) >> Rewr' \\
       Know ‘pos_fn_integral (X,A,u)
               (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (E n) (cons x y)) -
                    pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y))) =
             pos_fn_integral (X,A,u)
               (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (E n) (cons x y))) -
             pos_fn_integral (X,A,u)
               (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y)))’
       >- (HO_MATCH_MP_TAC pos_fn_integral_sub >> simp [] \\
           CONJ_TAC >- (‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
                        Q.PAT_X_ASSUM ‘!n. E n IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           CONJ_TAC >- (Q.PAT_X_ASSUM ‘d IN D n’ MP_TAC \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           CONJ_TAC >- (rpt STRIP_TAC \\
                        MATCH_MP_TAC pos_fn_integral_pos >> simp [INDICATOR_FN_POS]) \\
           CONJ_TAC >- (rpt STRIP_TAC \\
                        MATCH_MP_TAC pos_fn_integral_mono >> simp [INDICATOR_FN_POS] \\
                        Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                        MATCH_MP_TAC INDICATOR_FN_MONO >> rw [INTER_SUBSET]) \\
           REWRITE_TAC [lt_infty] >> MATCH_MP_TAC let_trans \\
           Q.EXISTS_TAC ‘pos_fn_integral (X,A,u)
                          (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (E n) (cons x y)))’ \\
           CONJ_TAC >- (MATCH_MP_TAC pos_fn_integral_mono >> simp [INDICATOR_FN_POS] \\
                        CONJ_TAC >- (rpt STRIP_TAC \\
                                     MATCH_MP_TAC pos_fn_integral_pos \\
                                     simp [INDICATOR_FN_POS]) \\
                        rpt STRIP_TAC \\
                        MATCH_MP_TAC pos_fn_integral_mono >> simp [INDICATOR_FN_POS] \\
                        Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                        MATCH_MP_TAC INDICATOR_FN_MONO >> rw [INTER_SUBSET]) \\
           rw [Abbr ‘E’, GSYM lt_infty] \\
           Know ‘!x y. indicator_fn (general_cross cons (a n) (b n)) (cons x y) =
                       indicator_fn (a n) x * indicator_fn (b n) y’
           >- (rpt GEN_TAC >> MATCH_MP_TAC indicator_fn_general_cross \\
               qexistsl_tac [‘car’, ‘cdr’] >> art []) >> Rewr' \\
           Know ‘!x. pos_fn_integral (Y,B,v) (\y. indicator_fn (a n) x * indicator_fn (b n) y) =
                     indicator_fn (a n) x * pos_fn_integral (Y,B,v) (indicator_fn (b n))’
           >- (GEN_TAC \\
              ‘?r. 0 <= r /\ indicator_fn (a n) x = Normal r’
                 by METIS_TAC [indicator_fn_normal] >> POP_ORW \\
               Know ‘pos_fn_integral (Y,B,v) (\y. Normal r * indicator_fn (b n) y) =
                     Normal r * pos_fn_integral (Y,B,v) (indicator_fn (b n))’
               >- (MATCH_MP_TAC pos_fn_integral_cmul >> simp [INDICATOR_FN_POS]) \\
               Rewr) >> Rewr' \\
           Know ‘pos_fn_integral (Y,B,v) (indicator_fn (b n)) = measure (Y,B,v) (b n)’
           >- (MATCH_MP_TAC pos_fn_integral_indicator >> art [measurable_sets_def] \\
               FULL_SIMP_TAC std_ss [exhausting_sequence_def, subsets_def, IN_FUNSET, IN_UNIV]) \\
           REWRITE_TAC [measure_def] >> Rewr' \\
           IMP_RES_TAC MEASURE_SPACE_POSITIVE \\
           REV_FULL_SIMP_TAC std_ss [positive_def, exhausting_sequence_def,
                                     IN_FUNSET, IN_UNIV, space_def, subsets_def,
                                     measurable_sets_def, measure_def] \\
           Know ‘v (b n) <> PosInf /\ v (b n) <> NegInf’
           >- (CONJ_TAC >- art [lt_infty] \\
               MATCH_MP_TAC pos_not_neginf \\
               FIRST_X_ASSUM MATCH_MP_TAC >> art []) >> STRIP_TAC \\
           ONCE_REWRITE_TAC [mul_comm] \\
           Know ‘pos_fn_integral (X,A,u) (\x. v (b n) * indicator_fn (a n) x) =
                 v (b n) * pos_fn_integral (X,A,u) (indicator_fn (a n))’
           >- (‘?z. 0 <= z /\ v (b n) = Normal z’
                  by METIS_TAC [extreal_of_num_def, extreal_le_eq, extreal_cases] >> POP_ORW \\
               MATCH_MP_TAC pos_fn_integral_cmul >> simp [INDICATOR_FN_POS]) >> Rewr' \\
           Know ‘pos_fn_integral (X,A,u) (indicator_fn (a n)) = measure (X,A,u) (a n)’
           >- (MATCH_MP_TAC pos_fn_integral_indicator >> art [measurable_sets_def] \\
               FULL_SIMP_TAC std_ss [exhausting_sequence_def, subsets_def, IN_FUNSET, IN_UNIV]) \\
           REWRITE_TAC [measure_def] >> Rewr' \\
           Know ‘u (a n) <> PosInf /\ u (a n) <> NegInf’
           >- (CONJ_TAC >- art [lt_infty] \\
               MATCH_MP_TAC pos_not_neginf \\
               FIRST_X_ASSUM MATCH_MP_TAC >> art []) >> STRIP_TAC \\
          ‘?r1. u (a n) = Normal r1’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          ‘?r2. v (b n) = Normal r2’ by METIS_TAC [extreal_cases] >> POP_ORW \\
           REWRITE_TAC [extreal_mul_def, extreal_not_infty]) >> Rewr' \\
       Know ‘pos_fn_integral (Y,B,v)
               (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (E n) (cons x y)) -
                    pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y))) =
             pos_fn_integral (Y,B,v)
               (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (E n) (cons x y))) -
             pos_fn_integral (Y,B,v)
               (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y)))’
       >- (HO_MATCH_MP_TAC pos_fn_integral_sub >> simp [] \\
           CONJ_TAC >- (‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
                        Q.PAT_X_ASSUM ‘!n. E n IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           CONJ_TAC >- (Q.PAT_X_ASSUM ‘d IN D n’ MP_TAC \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           CONJ_TAC >- (rpt STRIP_TAC \\
                        MATCH_MP_TAC pos_fn_integral_pos >> simp [INDICATOR_FN_POS]) \\
           CONJ_TAC >- (rpt STRIP_TAC \\
                        MATCH_MP_TAC pos_fn_integral_mono >> simp [INDICATOR_FN_POS] \\
                        Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                        MATCH_MP_TAC INDICATOR_FN_MONO >> rw [INTER_SUBSET]) \\
           REWRITE_TAC [lt_infty] >> MATCH_MP_TAC let_trans \\
           Q.EXISTS_TAC ‘pos_fn_integral (Y,B,v)
                          (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (E n) (cons x y)))’ \\
           CONJ_TAC >- (MATCH_MP_TAC pos_fn_integral_mono >> simp [] \\
                        CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                                     MATCH_MP_TAC pos_fn_integral_pos >> simp [INDICATOR_FN_POS]) \\
                        Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                        MATCH_MP_TAC pos_fn_integral_mono >> simp [INDICATOR_FN_POS] \\
                        Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                        MATCH_MP_TAC INDICATOR_FN_MONO >> rw [INTER_SUBSET]) \\
           rw [Abbr ‘E’, GSYM lt_infty] \\
           Know ‘!x y. indicator_fn (general_cross cons (a n) (b n)) (cons x y) =
                      indicator_fn (a n) x * indicator_fn (b n) y’
           >- (rpt GEN_TAC >> MATCH_MP_TAC indicator_fn_general_cross \\
               qexistsl_tac [‘car’, ‘cdr’] >> art []) >> Rewr' \\
           ONCE_REWRITE_TAC [mul_comm] \\
           Know ‘!y. pos_fn_integral (X,A,u) (\x. indicator_fn (b n) y * indicator_fn (a n) x) =
                     indicator_fn (b n) y * pos_fn_integral (X,A,u) (indicator_fn (a n))’
           >- (GEN_TAC \\
              ‘?r. 0 <= r /\ indicator_fn (b n) y = Normal r’
                 by METIS_TAC [indicator_fn_normal] >> POP_ORW \\
               Know ‘pos_fn_integral (X,A,u) (\x. Normal r * indicator_fn (a n) x) =
                     Normal r * pos_fn_integral (X,A,u) (indicator_fn (a n))’
               >- (MATCH_MP_TAC pos_fn_integral_cmul >> simp [INDICATOR_FN_POS]) \\
               Rewr) >> Rewr' \\
           Know ‘pos_fn_integral (X,A,u) (indicator_fn (a n)) = measure (X,A,u) (a n)’
           >- (MATCH_MP_TAC pos_fn_integral_indicator >> art [measurable_sets_def] \\
               FULL_SIMP_TAC std_ss [exhausting_sequence_def, subsets_def, IN_FUNSET, IN_UNIV]) \\
           REWRITE_TAC [measure_def] >> Rewr' \\
           IMP_RES_TAC MEASURE_SPACE_POSITIVE \\
           REV_FULL_SIMP_TAC std_ss [positive_def, exhausting_sequence_def,
                                     IN_FUNSET, IN_UNIV, space_def, subsets_def,
                                     measurable_sets_def, measure_def] \\
           Know ‘u (a n) <> PosInf /\ u (a n) <> NegInf’
           >- (CONJ_TAC >- art [lt_infty] \\
               MATCH_MP_TAC pos_not_neginf \\
               FIRST_X_ASSUM MATCH_MP_TAC >> art []) >> STRIP_TAC \\
           ONCE_REWRITE_TAC [mul_comm] \\
           Know ‘pos_fn_integral (Y,B,v) (\y. u (a n) * indicator_fn (b n) y) =
                 u (a n) * pos_fn_integral (Y,B,v) (indicator_fn (b n))’
           >- (‘?z. 0 <= z /\ u (a n) = Normal z’
                  by METIS_TAC [extreal_of_num_def, extreal_le_eq, extreal_cases] >> POP_ORW \\
               MATCH_MP_TAC pos_fn_integral_cmul >> simp [INDICATOR_FN_POS]) >> Rewr' \\
           Know ‘pos_fn_integral (Y,B,v) (indicator_fn (b n)) = measure (Y,B,v) (b n)’
           >- (MATCH_MP_TAC pos_fn_integral_indicator >> art [measurable_sets_def] \\
               FULL_SIMP_TAC std_ss [exhausting_sequence_def, subsets_def, IN_FUNSET, IN_UNIV]) \\
           REWRITE_TAC [measure_def] >> Rewr' \\
           Know ‘v (b n) <> PosInf /\ v (b n) <> NegInf’
           >- (CONJ_TAC >- art [lt_infty] \\
               MATCH_MP_TAC pos_not_neginf \\
               FIRST_X_ASSUM MATCH_MP_TAC >> art []) >> STRIP_TAC \\
          ‘?r1. u (a n) = Normal r1’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          ‘?r2. v (b n) = Normal r2’ by METIS_TAC [extreal_cases] >> POP_ORW \\
           REWRITE_TAC [extreal_mul_def, extreal_not_infty]) >> Rewr' \\
       Know ‘pos_fn_integral (X,A,u)
               (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (E n) (cons x y))) =
             pos_fn_integral (Y,B,v)
               (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (E n) (cons x y)))’
       >- (‘E n = E n INTER E n’ by PROVE_TAC [INTER_IDEMPOT] >> POP_ORW \\
           Q.PAT_X_ASSUM ‘!n. E n IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
           RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) >> Rewr' \\
       Know ‘pos_fn_integral (X,A,u)
               (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y))) =
             pos_fn_integral (Y,B,v)
               (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y)))’
       >- (Q.PAT_X_ASSUM ‘d IN D n’ MP_TAC \\
           RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) >> Rewr,
       (* goal 4 (of 4): disjoint countably additive *)
       fs [IN_FUNSET, IN_UNIV] >> rename1 ‘!x. d x IN D n’ \\
    (* expanding D without touching assumptions *)
       Suff ‘BIGUNION (IMAGE d univ(:num)) IN
            {d | d SUBSET (general_cross cons X Y) /\
                 (!x. x IN X ==>
                      (\y. indicator_fn (d INTER E n) (cons x y)) IN Borel_measurable (Y,B)) /\
                 (!y. y IN Y ==>
                      (\x. indicator_fn (d INTER E n) (cons x y)) IN Borel_measurable (X,A)) /\
                 (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y)))
                        IN Borel_measurable (Y,B) /\
                 (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y)))
                        IN Borel_measurable (X,A) /\
                 pos_fn_integral (X,A,u)
                   (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (d INTER E n) (cons x y))) =
                 pos_fn_integral (Y,B,v)
                   (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (d INTER E n) (cons x y)))}’
       >- METIS_TAC [Abbr ‘D’] >> simp [GSPECIFICATION] \\
       Know ‘!x. d x SUBSET (general_cross cons X Y)’
       >- (GEN_TAC >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘x’)) \\
           RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) >> DISCH_TAC \\
       CONJ_TAC >- (POP_ASSUM MP_TAC >> rw [SUBSET_DEF, IN_BIGUNION_IMAGE, IN_UNIV]) \\
       REWRITE_TAC [BIGUNION_OVER_INTER_L] \\
    (* applying indicator_fn_split or indicator_fn_suminf *)
       Know ‘!x y. indicator_fn (BIGUNION (IMAGE (\i. d i INTER E n) UNIV)) (cons x y) =
                   suminf (\i. indicator_fn ((\i. d i INTER E n) i) (cons x y))’
       >- (rpt GEN_TAC >> MATCH_MP_TAC EQ_SYM \\
           MATCH_MP_TAC indicator_fn_suminf \\
           BETA_TAC >> qx_genl_tac [‘i’, ‘j’] >> DISCH_TAC \\
           MATCH_MP_TAC DISJOINT_RESTRICT_L \\
           FIRST_X_ASSUM MATCH_MP_TAC >> art []) >> Rewr' \\
       CONJ_TAC (* Borel_measurable #1 *)
       >- (rpt STRIP_TAC \\
           MATCH_MP_TAC IN_MEASURABLE_BOREL_SUMINF >> simp [INDICATOR_FN_POS] \\
           Q.EXISTS_TAC ‘\i y. indicator_fn (d i INTER E n) (cons x y)’ \\
           simp [INDICATOR_FN_POS] \\
           Q.X_GEN_TAC ‘i’ >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
           RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
       CONJ_TAC (* Borel_measurable #2 *)
       >- (rpt STRIP_TAC \\
           MATCH_MP_TAC IN_MEASURABLE_BOREL_SUMINF >> simp [INDICATOR_FN_POS] \\
           Q.EXISTS_TAC ‘\i x. indicator_fn (d i INTER E n) (cons x y)’ \\
           simp [INDICATOR_FN_POS] \\
           Q.X_GEN_TAC ‘i’ >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
           RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
       CONJ_TAC (* Borel_measurable #3 *)
       >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                      (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) \\
           BETA_TAC \\
           Q.EXISTS_TAC ‘\y. suminf (\i. pos_fn_integral (X,A,u)
                                           (\x. indicator_fn (d i INTER E n) (cons x y)))’ \\
           reverse CONJ_TAC
           >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_SUMINF >> simp [] \\
               Q.EXISTS_TAC ‘\i y. pos_fn_integral (X,A,u)
                                     (\x. indicator_fn (d i INTER E n) (cons x y))’ >> simp [] \\
               reverse CONJ_TAC
               >- (qx_genl_tac [‘i’, ‘y’] >> DISCH_TAC \\
                   MATCH_MP_TAC pos_fn_integral_pos >> simp [INDICATOR_FN_POS]) \\
               Q.X_GEN_TAC ‘i’ >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
               RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           Q.X_GEN_TAC ‘y’ >> BETA_TAC >> DISCH_TAC \\
           Know ‘pos_fn_integral (X,A,u)
                   (\x. suminf (\i. (\i x. indicator_fn (d i INTER E n) (cons x y)) i x)) =
                 suminf (\i. pos_fn_integral (X,A,u)
                               ((\i x. indicator_fn (d i INTER E n) (cons x y)) i))’
           >- (MATCH_MP_TAC pos_fn_integral_suminf >> simp [INDICATOR_FN_POS] \\
               GEN_TAC >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
               RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) >> BETA_TAC >> Rewr) \\
       CONJ_TAC (* Borel_measurable #4 *)
       >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                      (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) \\
           BETA_TAC \\
           Q.EXISTS_TAC ‘\x. suminf (\i. pos_fn_integral (Y,B,v)
                                           (\y. indicator_fn (d i INTER E n) (cons x y)))’ \\
           reverse CONJ_TAC
           >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_SUMINF >> simp [] \\
               Q.EXISTS_TAC ‘\i x. pos_fn_integral (Y,B,v)
                                     (\y. indicator_fn (d i INTER E n) (cons x y))’ >> simp [] \\
               reverse CONJ_TAC
               >- (qx_genl_tac [‘i’, ‘x’] >> DISCH_TAC \\
                   MATCH_MP_TAC pos_fn_integral_pos >> simp [INDICATOR_FN_POS]) \\
               Q.X_GEN_TAC ‘i’ >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
               RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           Q.X_GEN_TAC ‘x’ >> BETA_TAC >> DISCH_TAC \\
           Know ‘pos_fn_integral (Y,B,v)
                   (\y. suminf (\i. (\i y. indicator_fn (d i INTER E n) (cons x y)) i y)) =
                 suminf (\i. pos_fn_integral (Y,B,v)
                               ((\i y. indicator_fn (d i INTER E n) (cons x y)) i))’
           >- (MATCH_MP_TAC pos_fn_integral_suminf >> simp [INDICATOR_FN_POS] \\
               GEN_TAC >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
               RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) >> BETA_TAC >> Rewr) \\
       Know ‘pos_fn_integral (X,A,u)
               (\x. pos_fn_integral (Y,B,v)
                      (\y. suminf (\i. indicator_fn (d i INTER E n) (cons x y)))) =
             pos_fn_integral (X,A,u)
               (\x. suminf (\i. pos_fn_integral (Y,B,v)
                                  (\y. indicator_fn (d i INTER E n) (cons x y))))’
       >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                      (Q.SPEC ‘(X,A,u)’ pos_fn_integral_cong)) >> simp [] \\
           CONJ_TAC >- (rpt STRIP_TAC >> MATCH_MP_TAC pos_fn_integral_pos >> simp [] \\
                        Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                        MATCH_MP_TAC ext_suminf_pos >> simp [INDICATOR_FN_POS]) \\
           CONJ_TAC >- (rpt STRIP_TAC >> MATCH_MP_TAC ext_suminf_pos >> simp [] \\
                        Q.X_GEN_TAC ‘i’ >> MATCH_MP_TAC pos_fn_integral_pos \\
                        simp [INDICATOR_FN_POS]) \\
           rpt STRIP_TAC \\
           Know ‘pos_fn_integral (Y,B,v)
                   (\y. suminf (\i. (\i y. indicator_fn (d i INTER E n) (cons x y)) i y)) =
                 suminf (\i. pos_fn_integral (Y,B,v)
                               ((\i y. indicator_fn (d i INTER E n) (cons x y)) i))’
           >- (MATCH_MP_TAC pos_fn_integral_suminf \\
               simp [INDICATOR_FN_POS] \\
               GEN_TAC >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
               RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) >> BETA_TAC >> Rewr) \\
       BETA_TAC >> Rewr' \\
       Know ‘pos_fn_integral (Y,B,v)
               (\y. pos_fn_integral (X,A,u)
                      (\x. suminf (\i. indicator_fn (d i INTER E n) (cons x y)))) =
             pos_fn_integral (Y,B,v)
               (\y. suminf (\i. pos_fn_integral (X,A,u)
                                  (\x. indicator_fn (d i INTER E n) (cons x y))))’
       >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                      (Q.SPEC ‘(Y,B,v)’ pos_fn_integral_cong)) >> simp [] \\
           CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                        MATCH_MP_TAC pos_fn_integral_pos >> simp [] \\
                        rpt STRIP_TAC >> MATCH_MP_TAC ext_suminf_pos \\
                        simp [INDICATOR_FN_POS]) \\
           CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                        MATCH_MP_TAC ext_suminf_pos >> simp [] \\
                        Q.X_GEN_TAC ‘i’ >> MATCH_MP_TAC pos_fn_integral_pos \\
                        simp [INDICATOR_FN_POS]) \\
           Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
           Know ‘pos_fn_integral (X,A,u)
                   (\x. suminf (\i. (\i x. indicator_fn (d i INTER E n) (cons x y)) i x)) =
                 suminf (\i. pos_fn_integral (X,A,u)
                               ((\i x. indicator_fn (d i INTER E n) (cons x y)) i))’
           >- (MATCH_MP_TAC pos_fn_integral_suminf \\
               simp [INDICATOR_FN_POS] \\
               GEN_TAC >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
               RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) >> BETA_TAC >> Rewr) >> Rewr' \\
       Know ‘pos_fn_integral (X,A,u)
               (\x. suminf (\i. (\i x. pos_fn_integral (Y,B,v)
                                         (\y. indicator_fn (d i INTER E n) (cons x y))) i x)) =
             suminf (\i. pos_fn_integral (X,A,u)
                           ((\i x. pos_fn_integral (Y,B,v)
                                     (\y. indicator_fn (d i INTER E n) (cons x y))) i))’
       >- (MATCH_MP_TAC pos_fn_integral_suminf >> simp [] \\
           CONJ_TAC >- (rpt STRIP_TAC >> MATCH_MP_TAC pos_fn_integral_pos \\
                        simp [INDICATOR_FN_POS]) \\
           GEN_TAC >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
           RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) >> BETA_TAC >> Rewr' \\
       Know ‘pos_fn_integral (Y,B,v)
               (\y. suminf (\i. (\i y. pos_fn_integral (X,A,u)
                                         (\x. indicator_fn (d i INTER E n) (cons x y))) i y)) =
             suminf (\i. pos_fn_integral (Y,B,v)
                           ((\i y. pos_fn_integral (X,A,u)
                                     (\x. indicator_fn (d i INTER E n) (cons x y))) i))’
       >- (MATCH_MP_TAC pos_fn_integral_suminf >> simp [] \\
           CONJ_TAC >- (rpt STRIP_TAC >> MATCH_MP_TAC pos_fn_integral_pos \\
                        simp [INDICATOR_FN_POS]) \\
           Q.X_GEN_TAC ‘i’ >> Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
           RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) >> BETA_TAC >> Rewr' \\
       MATCH_MP_TAC ext_suminf_eq >> Q.X_GEN_TAC ‘i’ >> BETA_TAC \\
       Q.PAT_X_ASSUM ‘!x. d x IN D n’ (MP_TAC o (Q.SPEC ‘i’)) \\
       RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION] ]) >> DISCH_TAC
 (* clean up *)
 >> Q.PAT_X_ASSUM ‘!n d y. pos_fn_integral (X,A,u) f <> PosInf’ K_TAC
 >> Q.PAT_X_ASSUM ‘!n d y. pos_fn_integral (X,A,u) f <> NegInf’ K_TAC
 >> Q.PAT_X_ASSUM ‘!n d x. pos_fn_integral (Y,B,v) f <> PosInf’ K_TAC
 >> Q.PAT_X_ASSUM ‘!n d x. pos_fn_integral (Y,B,v) f <> NegInf’ K_TAC
 (* applying DYNKIN_SUBSET and DYNKIN_THM *)
 >> Know ‘!n. subsets (general_sigma cons (X,A) (Y,B)) SUBSET D n’
 >- (GEN_TAC >> rw [general_sigma_def] \\
     Suff ‘sigma (general_cross cons X Y) (general_prod cons A B) =
           dynkin (general_cross cons X Y) (general_prod cons A B)’
     >- (Rewr' \\
         MATCH_MP_TAC (REWRITE_RULE [space_def, subsets_def]
                        (Q.SPECL [‘general_prod cons A B’, ‘(general_cross cons X Y,D n)’]
                          (INST_TYPE [alpha |-> gamma] DYNKIN_SUBSET))) >> art []) \\
     MATCH_MP_TAC EQ_SYM >> MATCH_MP_TAC DYNKIN_THM \\
     CONJ_TAC >- (rw [subset_class_def, IN_general_prod] \\
                  MATCH_MP_TAC general_SUBSET_CROSS \\
                  fs [sigma_algebra_def, algebra_def, subset_class_def]) \\
     qx_genl_tac [‘x’, ‘y’] >> STRIP_TAC \\
     Q.PAT_X_ASSUM ‘x IN general_prod cons A B’
        (STRIP_ASSUME_TAC o (REWRITE_RULE [IN_general_prod])) \\
     rename1 ‘x = general_cross cons s1 t1’ \\
     Q.PAT_X_ASSUM ‘y IN general_prod cons A B’
        (STRIP_ASSUME_TAC o (REWRITE_RULE [IN_general_prod])) \\
     rename1 ‘y = general_cross cons s2 t2’ \\
     rw [IN_general_prod] \\
     qexistsl_tac [‘s1 INTER s2’, ‘t1 INTER t2’] \\
     CONJ_TAC >- (MATCH_MP_TAC general_INTER_CROSS \\
                  qexistsl_tac [‘car’, ‘cdr’] >> art []) \\
     CONJ_TAC >| (* 2 subgoals *)
     [ (* goal 1 (of 2) *)
       MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                  (ISPEC “(X,A) :'a algebra” SIGMA_ALGEBRA_INTER)) \\
       ASM_REWRITE_TAC [],
       (* goal 2 (of 2) *)
       MATCH_MP_TAC (REWRITE_RULE [subsets_def]
                                  (ISPEC “(Y,B) :'b algebra” SIGMA_ALGEBRA_INTER)) \\
       ASM_REWRITE_TAC [] ]) >> DISCH_TAC
 (* stage work *)
 >> Know ‘exhausting_sequence (general_cross cons X Y,general_prod cons A B) E’
 >- (Q.UNABBREV_TAC ‘E’ >> MATCH_MP_TAC exhausting_sequence_general_cross >> art [])
 >> DISCH_THEN (STRIP_ASSUME_TAC o
                (REWRITE_RULE [space_def, subsets_def, exhausting_sequence_alt,
                               IN_FUNSET, IN_UNIV]))
 >> STRONG_CONJ_TAC (* Borel_measurable *)
 >- (GEN_TAC >> DISCH_TAC \\
    ‘!n. s IN D n’ by METIS_TAC [SUBSET_DEF] \\
    ‘s SUBSET (general_cross cons X Y)’
       by (POP_ASSUM MP_TAC >> RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
    ‘s = s INTER (general_cross cons X Y)’ by ASM_SET_TAC [] >> POP_ORW \\
     Know ‘!x y. indicator_fn (s INTER (general_cross cons X Y)) (cons x y) =
                 sup (IMAGE (\n. indicator_fn (s INTER (E n)) (cons x y)) UNIV)’
     >- (rw [Once EQ_SYM_EQ, sup_eq', IN_IMAGE, IN_UNIV] >| (* 2 subgoals *)
         [ (* goal 1 (of 2) *)
           MATCH_MP_TAC INDICATOR_FN_MONO >> ASM_SET_TAC [],
           (* goal 2 (of 2) *)
           rename1 ‘!z. (?n. z = indicator_fn (s INTER E n) (cons x y)) ==> z <= N’ \\
           Cases_on ‘!n. indicator_fn (s INTER E n) (cons x y) = 0’
           >- (Q.PAT_X_ASSUM ‘_ = general_cross cons X Y’ (ONCE_REWRITE_TAC o wrap o SYM) \\
               POP_ASSUM MP_TAC \\
               rw [indicator_fn_def] >> METIS_TAC [ne_01]) \\
           fs [] >> FIRST_X_ASSUM MATCH_MP_TAC \\
           rename1 ‘indicator_fn (s INTER E i) (cons x y) <> 0’ \\
           Q.EXISTS_TAC ‘i’ \\
           Q.PAT_X_ASSUM ‘_ = general_cross cons X Y’ (ONCE_REWRITE_TAC o wrap o SYM) \\
           POP_ASSUM MP_TAC >> rw [indicator_fn_def] \\
           METIS_TAC [] ]) >> Rewr' \\
     CONJ_TAC (* Borel_measurable #1 *)
     >- (rpt STRIP_TAC \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_MONO_SUP >> simp [] \\
         Q.EXISTS_TAC ‘\n y. indicator_fn (s INTER E n) (cons x y)’ >> simp [] \\
         reverse CONJ_TAC
         >- (qx_genl_tac [‘n’, ‘y’] >> DISCH_TAC \\
             MATCH_MP_TAC INDICATOR_FN_MONO \\
             Suff ‘E n SUBSET E (SUC n)’ >- ASM_SET_TAC [] \\
             FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss []) \\
         GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
         RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
     CONJ_TAC (* Borel_measurable #2 *)
     >- (rpt STRIP_TAC \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_MONO_SUP >> simp [] \\
         Q.EXISTS_TAC ‘\n x. indicator_fn (s INTER E n) (cons x y)’ >> simp [] \\
         reverse CONJ_TAC
         >- (qx_genl_tac [‘n’, ‘x’] >> DISCH_TAC \\
             MATCH_MP_TAC INDICATOR_FN_MONO \\
             Suff ‘E n SUBSET E (SUC n)’ >- ASM_SET_TAC [] \\
             FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss []) \\
         GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
         RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
  (* applying lebesgue_monotone_convergence (Beppo Levi) *)
     CONJ_TAC >| (* 2 subgoals *)
     [ (* goal 1 (of 2) *)
       MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                  (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) \\
       Q.EXISTS_TAC ‘\y. sup (IMAGE (\n. pos_fn_integral (X,A,u)
                                           (\x. indicator_fn (s INTER E n) (cons x y))) UNIV)’ \\
       reverse CONJ_TAC
       >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_MONO_SUP >> simp [] \\
           Q.EXISTS_TAC ‘\n y. pos_fn_integral (X,A,u)
                                 (\x. indicator_fn (s INTER E n) (cons x y))’ >> simp [] \\
           CONJ_TAC >- (GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           qx_genl_tac [‘n’, ‘y’] >> DISCH_TAC \\
           MATCH_MP_TAC pos_fn_integral_mono >> simp [INDICATOR_FN_POS] \\
           rpt STRIP_TAC >> MATCH_MP_TAC INDICATOR_FN_MONO \\
           Suff ‘E n SUBSET E (SUC n)’ >- ASM_SET_TAC [] \\
           FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss []) \\
       Q.X_GEN_TAC ‘y’ >> DISCH_TAC >> BETA_TAC \\
       HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [INDICATOR_FN_POS] \\
       CONJ_TAC >- (GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                    RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
       rw [ext_mono_increasing_def] \\
       MATCH_MP_TAC INDICATOR_FN_MONO \\
       Suff ‘E n SUBSET E (SUC n)’ >- ASM_SET_TAC [] \\
       FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss [],
       (* goal 2 (of 2) *)
       MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                  (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) \\
       Q.EXISTS_TAC ‘\x. sup (IMAGE (\n. pos_fn_integral (Y,B,v)
                                           (\y. indicator_fn (s INTER E n) (cons x y))) UNIV)’ \\
       reverse CONJ_TAC
       >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_MONO_SUP >> simp [] \\
           Q.EXISTS_TAC ‘\n x. pos_fn_integral (Y,B,v)
                                 (\y. indicator_fn (s INTER E n) (cons x y))’ >> simp [] \\
           CONJ_TAC >- (GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                        RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
           qx_genl_tac [‘n’, ‘x’] >> DISCH_TAC \\
           MATCH_MP_TAC pos_fn_integral_mono >> simp [INDICATOR_FN_POS] \\
           Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
           MATCH_MP_TAC INDICATOR_FN_MONO \\
           Suff ‘E n SUBSET E (SUC n)’ >- ASM_SET_TAC [] \\
           FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss []) \\
       Q.X_GEN_TAC ‘x’ >> DISCH_TAC >> BETA_TAC \\
       HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [INDICATOR_FN_POS] \\
       CONJ_TAC >- (GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                    RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
       rw [ext_mono_increasing_def] \\
       MATCH_MP_TAC INDICATOR_FN_MONO \\
       Suff ‘E n SUBSET E (SUC n)’ >- ASM_SET_TAC [] \\
       FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss [] ]) >> DISCH_TAC
 (* final battle *)
 >> Q.EXISTS_TAC ‘\s. pos_fn_integral (X,A,u)
                        (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn s (cons x y)))’
 >> REWRITE_TAC [CONJ_ASSOC]
 >> reverse CONJ_TAC (* swap of integrals *)
 >- (RW_TAC std_ss [] \\
    ‘!n. s IN D n’ by METIS_TAC [SUBSET_DEF] \\
    ‘s SUBSET (general_cross cons X Y)’
       by (POP_ASSUM MP_TAC >> RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
    ‘s = s INTER (general_cross cons X Y)’ by ASM_SET_TAC [] >> POP_ORW \\
     Know ‘!x y. indicator_fn (s INTER (general_cross cons X Y)) (cons x y) =
                 sup (IMAGE (\n. indicator_fn (s INTER (E n)) (cons x y)) UNIV)’
     >- (rw [Once EQ_SYM_EQ, sup_eq', IN_IMAGE, IN_UNIV] >| (* 2 subgoals *)
         [ (* goal 1 (of 2) *)
           MATCH_MP_TAC INDICATOR_FN_MONO >> ASM_SET_TAC [],
           (* goal 2 (of 2) *)
           rename1 ‘!z. (?n. z = indicator_fn (s INTER E n) (cons x y)) ==> z <= N’ \\
           Cases_on ‘!n. indicator_fn (s INTER E n) (cons x y) = 0’
           >- (Q.PAT_X_ASSUM ‘_ = general_cross cons X Y’ (ONCE_REWRITE_TAC o wrap o SYM) \\
               POP_ASSUM MP_TAC \\
               rw [indicator_fn_def] >> METIS_TAC [ne_01]) \\
           fs [] >> FIRST_X_ASSUM MATCH_MP_TAC \\
           rename1 ‘indicator_fn (s INTER E i) (cons x y) <> 0’ \\
           Q.EXISTS_TAC ‘i’ \\
           Q.PAT_X_ASSUM ‘_ = general_cross cons X Y’ (ONCE_REWRITE_TAC o wrap o SYM) \\
           POP_ASSUM MP_TAC >> rw [indicator_fn_def] \\
           METIS_TAC [] ]) >> Rewr' \\
     Know ‘!x y. 0 <= sup (IMAGE (\n. indicator_fn (s INTER E n) (cons x y)) UNIV)’
     >- (rw [le_sup'] >> MATCH_MP_TAC le_trans \\
         Q.EXISTS_TAC ‘indicator_fn (s INTER E 0) (cons x y)’ \\
         simp [INDICATOR_FN_POS] >> POP_ASSUM MATCH_MP_TAC \\
         Q.EXISTS_TAC ‘0’ >> REWRITE_TAC []) >> DISCH_TAC \\
  (* applying pos_fn_integral_cong *)
     Know ‘pos_fn_integral (X,A,u)
             (\x. pos_fn_integral (Y,B,v)
                    (\y. sup (IMAGE (\n. indicator_fn (s INTER E n) (cons x y)) UNIV))) =
           pos_fn_integral (X,A,u)
             (\x. sup (IMAGE (\n. pos_fn_integral (Y,B,v)
                                    (\y. indicator_fn (s INTER E n) (cons x y))) UNIV))’
     >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                    (Q.SPEC ‘(X,A,u)’ pos_fn_integral_cong)) >> simp [] \\
         CONJ_TAC >- (rpt STRIP_TAC >> MATCH_MP_TAC pos_fn_integral_pos >> simp []) \\
         CONJ_TAC >- (rw [le_sup'] >> MATCH_MP_TAC le_trans \\
                      Q.EXISTS_TAC ‘pos_fn_integral (Y,B,v)
                                     (\y. indicator_fn (s INTER E 0) (cons x y))’ \\
                      reverse CONJ_TAC >- (POP_ASSUM MATCH_MP_TAC \\
                                           Q.EXISTS_TAC ‘0’ >> REWRITE_TAC []) \\
                      MATCH_MP_TAC pos_fn_integral_pos >> simp [INDICATOR_FN_POS]) \\
         rpt STRIP_TAC \\
         HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [INDICATOR_FN_POS] \\
         CONJ_TAC >- (GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                      RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
         rw [ext_mono_increasing_def] \\
         MATCH_MP_TAC INDICATOR_FN_MONO \\
         Suff ‘E n SUBSET E (SUC n)’ >- ASM_SET_TAC [] \\
         FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss []) >> Rewr' \\
     Know ‘pos_fn_integral (Y,B,v)
             (\y. pos_fn_integral (X,A,u)
                    (\x. sup (IMAGE (\n. indicator_fn (s INTER E n) (cons x y)) UNIV))) =
           pos_fn_integral (Y,B,v)
             (\y. sup (IMAGE (\n. pos_fn_integral (X,A,u)
                                    (\x. indicator_fn (s INTER E n) (cons x y))) UNIV))’
     >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                    (Q.SPEC ‘(Y,B,v)’ pos_fn_integral_cong)) >> simp [] \\
         CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                      MATCH_MP_TAC pos_fn_integral_pos >> simp []) \\
         CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> rw [le_sup'] >> MATCH_MP_TAC le_trans \\
                      Q.EXISTS_TAC ‘pos_fn_integral (X,A,u)
                                     (\x. indicator_fn (s INTER E 0) (cons x y))’ \\
                      reverse CONJ_TAC >- (POP_ASSUM MATCH_MP_TAC \\
                                           Q.EXISTS_TAC ‘0’ >> REWRITE_TAC []) \\
                      MATCH_MP_TAC pos_fn_integral_pos >> simp [INDICATOR_FN_POS]) \\
         Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
         HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [INDICATOR_FN_POS] \\
         CONJ_TAC >- (GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                      RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
         rw [ext_mono_increasing_def] \\
         MATCH_MP_TAC INDICATOR_FN_MONO \\
         Suff ‘E n SUBSET E (SUC n)’ >- ASM_SET_TAC [] \\
         FIRST_X_ASSUM MATCH_MP_TAC >> RW_TAC arith_ss []) >> Rewr' \\
     Know ‘pos_fn_integral (X,A,u)
             (\x. sup (IMAGE (\n. pos_fn_integral (Y,B,v)
                                    (\y. indicator_fn (s INTER E n) (cons x y))) UNIV)) =
           sup (IMAGE (\n. pos_fn_integral (X,A,u)
                             (\x. pos_fn_integral (Y,B,v)
                                    (\y. indicator_fn (s INTER E n) (cons x y)))) UNIV)’
     >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [] \\
         CONJ_TAC >- (GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                      RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
         CONJ_TAC >- (rpt STRIP_TAC \\
                      MATCH_MP_TAC pos_fn_integral_pos >> simp [INDICATOR_FN_POS]) \\
         rw [ext_mono_increasing_def] \\
         MATCH_MP_TAC pos_fn_integral_mono >> simp [INDICATOR_FN_POS] \\
         Q.X_GEN_TAC ‘y’ >> DISCH_TAC >> MATCH_MP_TAC INDICATOR_FN_MONO \\
         rename1 ‘n <= m’ >> Suff ‘E n SUBSET E m’ >- ASM_SET_TAC [] \\
         FIRST_X_ASSUM MATCH_MP_TAC >> art []) >> Rewr' \\
     Know ‘pos_fn_integral (Y,B,v)
             (\y. sup (IMAGE (\n. pos_fn_integral (X,A,u)
                                    (\x. indicator_fn (s INTER E n) (cons x y))) UNIV)) =
           sup (IMAGE (\n. pos_fn_integral (Y,B,v)
                             (\y. pos_fn_integral (X,A,u)
                                    (\x. indicator_fn (s INTER E n) (cons x y)))) UNIV)’
     >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [] \\
         CONJ_TAC >- (GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
                      RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION]) \\
         CONJ_TAC >- (rpt STRIP_TAC \\
                      MATCH_MP_TAC pos_fn_integral_pos >> simp [INDICATOR_FN_POS]) \\
         rw [ext_mono_increasing_def] \\
         MATCH_MP_TAC pos_fn_integral_mono >> simp [INDICATOR_FN_POS] \\
         rpt STRIP_TAC >> MATCH_MP_TAC INDICATOR_FN_MONO \\
         rename1 ‘n <= m’ >> Suff ‘E n SUBSET E m’ >- ASM_SET_TAC [] \\
         FIRST_X_ASSUM MATCH_MP_TAC >> art []) >> Rewr' \\
     Suff ‘!n. pos_fn_integral (X,A,u)
                 (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (s INTER E n) (cons x y))) =
               pos_fn_integral (Y,B,v)
                 (\y. pos_fn_integral (X,A,u)
                        (\x. indicator_fn (s INTER E n) (cons x y)))’ >- rw [] \\
     GEN_TAC >> Q.PAT_X_ASSUM ‘!n. s IN D n’ (MP_TAC o (Q.SPEC ‘n’)) \\
     RW_TAC std_ss [Abbr ‘D’, GSPECIFICATION])
 >> reverse CONJ_TAC (* compatibility with m0 *)
 >- (Q.X_GEN_TAC ‘d’ >> simp [IN_general_prod] \\
     DISCH_THEN (qx_choosel_then [‘s’, ‘t’] STRIP_ASSUME_TAC) \\
     Q.PAT_X_ASSUM ‘d = general_cross cons s t’ (ONCE_REWRITE_TAC o wrap) \\
     Know ‘!x y. indicator_fn (general_cross cons s t) (cons x y) =
                 indicator_fn s x * indicator_fn t y’
     >- (rpt GEN_TAC >> MATCH_MP_TAC indicator_fn_general_cross \\
         qexistsl_tac [‘car’, ‘cdr’] >> art []) >> Rewr' \\
     Know ‘!x. pos_fn_integral (Y,B,v) (\y. indicator_fn s x * indicator_fn t y) =
               indicator_fn s x * pos_fn_integral (Y,B,v) (indicator_fn t)’
     >- (GEN_TAC \\
        ‘?r. 0 <= r /\ (indicator_fn s x = Normal r)’
           by METIS_TAC [indicator_fn_normal, extreal_of_num_def, extreal_le_eq] >> POP_ORW \\
         MATCH_MP_TAC pos_fn_integral_cmul >> simp [INDICATOR_FN_POS]) >> Rewr' \\
     Know ‘pos_fn_integral (Y,B,v) (indicator_fn t) = measure (Y,B,v) t’
     >- (MATCH_MP_TAC pos_fn_integral_indicator >> rw []) >> Rewr' >> simp [] \\
     GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites [mul_comm] \\
     IMP_RES_TAC MEASURE_SPACE_POSITIVE >> rfs [positive_def] \\
     Know ‘pos_fn_integral (X,A,u) (\x. v t * indicator_fn s x) =
           v t * pos_fn_integral (X,A,u) (indicator_fn s)’
     >- (Know ‘indicator_fn s = fn_plus (indicator_fn s)’
         >- (MATCH_MP_TAC EQ_SYM \\
             MATCH_MP_TAC FN_PLUS_POS_ID >> rw [INDICATOR_FN_POS]) >> Rewr' \\
         MATCH_MP_TAC pos_fn_integral_cmult >> simp [] \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_INDICATOR \\
         Q.EXISTS_TAC ‘s’ >> simp []) >> Rewr' \\
     Know ‘pos_fn_integral (X,A,u) (indicator_fn s) = measure (X,A,u) s’
     >- (MATCH_MP_TAC pos_fn_integral_indicator >> rw []) >> Rewr' \\
     rw [Once mul_comm])
 >> reverse CONJ_TAC (* sigma-finiteness *)
 >- (Q.EXISTS_TAC ‘E’ \\
     CONJ_TAC
     >- (rw [exhausting_sequence_def, IN_FUNSET, IN_UNIV] \\
         Suff ‘(general_prod cons A B) SUBSET subsets (general_sigma cons (X,A) (Y,B))’
         >- METIS_TAC [SUBSET_DEF] \\
         REWRITE_TAC [general_sigma_def, space_def, subsets_def] \\
         REWRITE_TAC [SIGMA_SUBSET_SUBSETS]) \\
     RW_TAC std_ss [Abbr ‘E’] \\
     Know ‘!x y. indicator_fn (general_cross cons (a n) (b n)) (cons x y) =
                 indicator_fn (a n) x * indicator_fn (b n) y’
     >- (rpt GEN_TAC >> MATCH_MP_TAC indicator_fn_general_cross \\
         qexistsl_tac [‘car’, ‘cdr’] >> art []) >> Rewr' \\
     IMP_RES_TAC MEASURE_SPACE_POSITIVE \\
     REV_FULL_SIMP_TAC std_ss [positive_def, exhausting_sequence_def,
                               IN_FUNSET, IN_UNIV, space_def, subsets_def,
                               measurable_sets_def, measure_def] \\
     Know ‘!x. pos_fn_integral (Y,B,v) (\y. indicator_fn (a n) x * indicator_fn (b n) y) =
               indicator_fn (a n) x * pos_fn_integral (Y,B,v) (indicator_fn (b n))’
     >- (GEN_TAC \\
        ‘?r. 0 <= r /\ (indicator_fn (a n) x = Normal r)’
           by METIS_TAC [indicator_fn_normal, extreal_of_num_def, extreal_le_eq] >> POP_ORW \\
         MATCH_MP_TAC pos_fn_integral_cmul >> simp [INDICATOR_FN_POS]) >> Rewr' \\
     Know ‘pos_fn_integral (Y,B,v) (indicator_fn (b n)) = measure (Y,B,v) (b n)’
     >- (MATCH_MP_TAC pos_fn_integral_indicator >> rw []) >> Rewr' >> simp [] \\
     GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites [mul_comm] \\
     Know ‘v (b n) <> PosInf /\ v (b n) <> NegInf’
     >- (CONJ_TAC >- art [lt_infty] \\
         MATCH_MP_TAC pos_not_neginf >> simp []) >> STRIP_TAC \\
     Know ‘pos_fn_integral (X,A,u) (\x. v (b n) * indicator_fn (a n) x) =
           v (b n) * pos_fn_integral (X,A,u) (indicator_fn (a n))’
     >- (‘?r. 0 <= r /\ (v (b n) = Normal r)’
           by METIS_TAC [extreal_cases, extreal_of_num_def, extreal_le_eq] >> POP_ORW \\
         MATCH_MP_TAC pos_fn_integral_cmul >> simp [INDICATOR_FN_POS]) >> Rewr' \\
     Know ‘pos_fn_integral (X,A,u) (indicator_fn (a n)) = measure (X,A,u) (a n)’
     >- (MATCH_MP_TAC pos_fn_integral_indicator >> simp []) >> Rewr' >> simp [] \\
     Know ‘u (a n) <> PosInf /\ u (a n) <> NegInf’
     >- (CONJ_TAC >- art [lt_infty] \\
         MATCH_MP_TAC pos_not_neginf >> simp []) >> STRIP_TAC \\
    ‘?r1. u (a n) = Normal r1’ by METIS_TAC [extreal_cases] >> POP_ORW \\
    ‘?r2. v (b n) = Normal r2’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     REWRITE_TAC [extreal_mul_def, lt_infty, extreal_not_infty])
 (* last three goals *)
 >> rw [measure_space_def]
 (* 1. sigma_algebra *)
 >- (Know ‘(general_cross cons X Y,subsets (general_sigma cons (X,A) (Y,B))) =
           general_sigma cons (X,A) (Y,B)’
     >- (rw [general_sigma_def] >> METIS_TAC [SPACE, SPACE_SIGMA]) >> Rewr' \\
     MATCH_MP_TAC sigma_algebra_general_sigma >> simp [] \\
     fs [sigma_algebra_def, algebra_def])
 (* 2. positive *)
 >- (rw [positive_def] >- (simp [pos_fn_integral_zero]) \\
     MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
     MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS])
 (* 3. countably_additive *)
 >> rw [countably_additive_def, IN_FUNSET, IN_UNIV, o_DEF]
 >> Know ‘!x y. indicator_fn (BIGUNION (IMAGE f UNIV)) (cons x y) =
                suminf (\n. indicator_fn (f n) (cons x y))’
 >- (RW_TAC std_ss [Once EQ_SYM_EQ] \\
     MATCH_MP_TAC indicator_fn_suminf >> simp []) >> Rewr'
 >> Know ‘pos_fn_integral (X,A,u)
            (\x. pos_fn_integral (Y,B,v) (\y. suminf (\n. indicator_fn (f n) (cons x y)))) =
          pos_fn_integral (X,A,u)
            (\x. suminf (\n. pos_fn_integral (Y,B,v) (\y. indicator_fn (f n) (cons x y))))’
 >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
     CONJ_TAC >- (rpt STRIP_TAC >> MATCH_MP_TAC pos_fn_integral_pos >> simp [] \\
                  Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                  MATCH_MP_TAC ext_suminf_pos >> rw [INDICATOR_FN_POS]) \\
     CONJ_TAC >- (rpt STRIP_TAC >> MATCH_MP_TAC ext_suminf_pos >> rw [] \\
                  MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS]) \\
     rpt STRIP_TAC \\
  (* preparing for pos_fn_integral_suminf *)
    ‘pos_fn_integral (Y,B,v) (\y. suminf (\n. indicator_fn (f n) (cons x y))) =
     pos_fn_integral (Y,B,v) (\y. suminf (\n. (\n y. indicator_fn (f n) (cons x y)) n y))’
       by PROVE_TAC [] >> POP_ORW \\
    ‘suminf (\n. pos_fn_integral (Y,B,v) (\y. indicator_fn (f n) (cons x y))) =
     suminf (\n. pos_fn_integral (Y,B,v) ((\n y. indicator_fn (f n) (cons x y)) n))’
       by PROVE_TAC [] >> POP_ORW \\
     MATCH_MP_TAC pos_fn_integral_suminf >> simp [INDICATOR_FN_POS]) >> Rewr'
 >> Know ‘pos_fn_integral (X,A,u)
            (\x. suminf (\n. (\n x. pos_fn_integral (Y,B,v)
                                      (\y. indicator_fn (f n) (cons x y))) n x)) =
          suminf (\n. pos_fn_integral (X,A,u)
                        ((\n x. pos_fn_integral (Y,B,v) (\y. indicator_fn (f n) (cons x y))) n))’
 >- (MATCH_MP_TAC pos_fn_integral_suminf >> rw [] \\
     MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS])
 >> BETA_TAC >> Rewr
QED

(* Theorem 14.5 [1, p.139], cf. CARATHEODORY_SEMIRING *)
Theorem EXISTENCE_OF_PROD_MEASURE :
   !(X :'a set) (Y :'b set) A B u v m0.
       sigma_finite_measure_space (X,A,u) /\
       sigma_finite_measure_space (Y,B,v) /\
       (!s t. s IN A /\ t IN B ==> (m0 (s CROSS t) = u s * v t)) ==>
       (!s. s IN subsets ((X,A) CROSS (Y,B)) ==>
           (!x. x IN X ==> (\y. indicator_fn s (x,y)) IN measurable (Y,B) Borel) /\
           (!y. y IN Y ==> (\x. indicator_fn s (x,y)) IN measurable (X,A) Borel) /\
           (\y. pos_fn_integral (X,A,u) (\x. indicator_fn s (x,y))) IN measurable (Y,B) Borel /\
           (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn s (x,y))) IN measurable (X,A) Borel) /\
       ?m. sigma_finite_measure_space (X CROSS Y,subsets ((X,A) CROSS (Y,B)),m) /\
           (!s. s IN (prod_sets A B) ==> (m s = m0 s)) /\
           (!s. s IN subsets ((X,A) CROSS (Y,B)) ==>
               (m s = pos_fn_integral (Y,B,v)
                        (\y. pos_fn_integral (X,A,u) (\x. indicator_fn s (x,y)))) /\
               (m s = pos_fn_integral (X,A,u)
                        (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn s (x,y)))))
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘pair$,’,‘FST’,‘SND’,‘X’,‘Y’,‘A’,‘B’,‘u’,‘v’,‘m0’]
                    (INST_TYPE [gamma |-> “:'a # 'b”] existence_of_prod_measure_general))
 >> RW_TAC std_ss [GSYM CROSS_ALT, GSYM prod_sets_alt, GSYM prod_sigma_alt,
                   pair_operation_pair]
QED

(* A derived version of EXISTENCE_OF_PROD_MEASURE using ‘integral’ instead of
  ‘pos_fn_integral’ (NOTE: this theorem has no general and FCP versions)
 *)
Theorem EXISTENCE_OF_PROD_MEASURE' :
   !(X :'a set) (Y :'b set) A B u v m0.
       sigma_finite_measure_space (X,A,u) /\
       sigma_finite_measure_space (Y,B,v) /\
       (!s t. s IN A /\ t IN B ==> (m0 (s CROSS t) = u s * v t)) ==>
       (!s. s IN subsets ((X,A) CROSS (Y,B)) ==>
           (!x. x IN X ==> (\y. indicator_fn s (x,y)) IN measurable (Y,B) Borel) /\
           (!y. y IN Y ==> (\x. indicator_fn s (x,y)) IN measurable (X,A) Borel) /\
           (\y. integral (X,A,u) (\x. indicator_fn s (x,y))) IN measurable (Y,B) Borel /\
           (\x. integral (Y,B,v) (\y. indicator_fn s (x,y))) IN measurable (X,A) Borel) /\
       ?m. sigma_finite_measure_space (X CROSS Y,subsets ((X,A) CROSS (Y,B)),m) /\
           (!s. s IN (prod_sets A B) ==> (m s = m0 s)) /\
           (!s. s IN subsets ((X,A) CROSS (Y,B)) ==>
               (m s = integral (Y,B,v) (\y. integral (X,A,u) (\x. indicator_fn s (x,y)))) /\
               (m s = integral (X,A,u) (\x. integral (Y,B,v) (\y. indicator_fn s (x,y)))))
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘X’,‘Y’,‘A’,‘B’,‘u’,‘v’,‘m0’] EXISTENCE_OF_PROD_MEASURE)
 >> FULL_SIMP_TAC std_ss [sigma_finite_measure_space_def]
 >> RW_TAC std_ss [] (* 3 subgoals *)
 >| [ (* goal 1 (of 3) *)
     ‘(\y. pos_fn_integral (X,A,u) (\x. indicator_fn s (x,y))) IN Borel_measurable (Y,B)’
        by METIS_TAC [] \\
      MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                 (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) \\
      Q.EXISTS_TAC ‘\y. pos_fn_integral (X,A,u) (\x. indicator_fn s (x,y))’ >> rw [] \\
      MATCH_MP_TAC integral_pos_fn >> rw [INDICATOR_FN_POS],
      (* goal 2 (of 3) *)
     ‘(\x. pos_fn_integral (Y,B,v) (\y. indicator_fn s (x,y))) IN Borel_measurable (X,A)’
        by METIS_TAC [] \\
      MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                 (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) \\
      Q.EXISTS_TAC ‘\x. pos_fn_integral (Y,B,v) (\y. indicator_fn s (x,y))’ >> rw [] \\
      MATCH_MP_TAC integral_pos_fn >> rw [INDICATOR_FN_POS],
      (* goal 3 (of 3) *)
      Q.EXISTS_TAC ‘m’ >> RW_TAC std_ss [] >| (* 2 subgoals *)
      [ (* goal 3.1 (of 2) *)
        Know ‘!y. integral (X,A,u) (\x. indicator_fn s (x,y)) =
                  pos_fn_integral (X,A,u) (\x. indicator_fn s (x,y))’
        >- (GEN_TAC \\
            MATCH_MP_TAC integral_pos_fn >> rw [INDICATOR_FN_POS]) >> Rewr' \\
        MATCH_MP_TAC EQ_SYM \\
        MATCH_MP_TAC integral_pos_fn >> simp [] \\
        Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
        MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS],
        (* goal 3.2 (of 2) *)
       ‘pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. indicator_fn s (x,y))) =
        pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn s (x,y)))’
           by METIS_TAC [] >> POP_ORW \\
        MATCH_MP_TAC EQ_SYM \\
        Know ‘!x. integral (Y,B,v) (\y. indicator_fn s (x,y)) =
                  pos_fn_integral (Y,B,v) (\y. indicator_fn s (x,y))’
        >- (GEN_TAC >> MATCH_MP_TAC integral_pos_fn >> rw [INDICATOR_FN_POS]) >> Rewr' \\
        MATCH_MP_TAC integral_pos_fn >> simp [] \\
        rpt STRIP_TAC \\
        MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS] ] ]
QED

(* FCP version of EXISTENCE_OF_PROD_MEASURE *)
Theorem existence_of_prod_measure :
   !(X :'a['b] set) (Y :'a['c] set) A B u v m0.
       FINITE univ(:'b) /\ FINITE univ(:'c) /\
       sigma_finite_measure_space (X,A,u) /\
       sigma_finite_measure_space (Y,B,v) /\
       (!s t. s IN A /\ t IN B ==> (m0 (fcp_cross s t) = u s * v t)) ==>
       (!s. s IN subsets (fcp_sigma (X,A) (Y,B)) ==>
           (!x. x IN X ==> (\y. indicator_fn s (FCP_CONCAT x y)) IN measurable (Y,B) Borel) /\
           (!y. y IN Y ==> (\x. indicator_fn s (FCP_CONCAT x y)) IN measurable (X,A) Borel) /\
           (\y. pos_fn_integral (X,A,u)
                  (\x. indicator_fn s (FCP_CONCAT x y))) IN measurable (Y,B) Borel /\
           (\x. pos_fn_integral (Y,B,v)
                  (\y. indicator_fn s (FCP_CONCAT x y))) IN measurable (X,A) Borel) /\
       ?m. sigma_finite_measure_space (fcp_cross X Y,subsets (fcp_sigma (X,A) (Y,B)),m) /\
           (!s. s IN (fcp_prod A B) ==> (m s = m0 s)) /\
           (!s. s IN subsets (fcp_sigma (X,A) (Y,B)) ==>
               (m s = pos_fn_integral (Y,B,v)
                        (\y. pos_fn_integral (X,A,u) (\x. indicator_fn s (FCP_CONCAT x y)))) /\
               (m s = pos_fn_integral (X,A,u)
                        (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn s (FCP_CONCAT x y)))))
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> MP_TAC (Q.SPECL [‘FCP_CONCAT’,‘FCP_FST’,‘FCP_SND’,‘X’,‘Y’,‘A’,‘B’,‘u’,‘v’,‘m0’]
                    (((INST_TYPE [“:'temp1” |-> “:'a['b]”]) o
                      (INST_TYPE [“:'temp2” |-> “:'a['c]”]) o
                      (INST_TYPE [gamma |-> “:'a['b + 'c]”]) o
                      (INST_TYPE [alpha |-> “:'temp1”]) o
                      (INST_TYPE [beta |-> “:'temp2”])) existence_of_prod_measure_general))
 >> RW_TAC std_ss [GSYM fcp_cross_alt, GSYM fcp_prod_alt, GSYM fcp_sigma_alt,
                   pair_operation_FCP_CONCAT]
QED

(* Application: 2-dimensional Borel measure space *)
local
  val thm = Q.prove (
     ‘?m. sigma_finite_measure_space m /\
         (m_space m = UNIV CROSS UNIV) /\
         (measurable_sets m = subsets ((UNIV,subsets borel) CROSS (UNIV,subsets borel))) /\
         (!s t. s IN subsets borel /\ t IN subsets borel ==>
               (measure m (s CROSS t) = lambda s * lambda t)) /\
         (!s. s IN measurable_sets m ==>
             (!x. (\y. indicator_fn s (x,y)) IN Borel_measurable borel) /\
             (!y. (\x. indicator_fn s (x,y)) IN Borel_measurable borel) /\
             (\y. pos_fn_integral lborel (\x. indicator_fn s (x,y))) IN Borel_measurable borel /\
             (\x. pos_fn_integral lborel (\y. indicator_fn s (x,y))) IN Borel_measurable borel /\
             (measure m s = pos_fn_integral lborel
                              (\y. pos_fn_integral lborel (\x. indicator_fn s (x,y)))) /\
             (measure m s = pos_fn_integral lborel
                              (\x. pos_fn_integral lborel (\y. indicator_fn s (x,y)))))’,
   (* proof *)
      MP_TAC (Q.ISPECL [‘univ(:real)’, ‘univ(:real)’, ‘subsets borel’, ‘subsets borel’,
                        ‘lambda’, ‘lambda’, ‘\s. lambda (IMAGE FST s) * lambda (IMAGE SND s)’]
                       EXISTENCE_OF_PROD_MEASURE) \\
      simp [sigma_finite_measure_space_def] \\
      Know ‘(univ(:real),subsets borel,lambda) = lborel’
      >- (REWRITE_TAC [GSYM space_lborel, GSYM sets_lborel, MEASURE_SPACE_REDUCE]) >> Rewr' \\
      REWRITE_TAC [measure_space_lborel, sigma_finite_lborel] \\
      Know ‘!s t. s IN subsets borel /\ t IN subsets borel ==>
                  lambda (IMAGE FST (s CROSS t)) * lambda (IMAGE SND (s CROSS t)) =
                  lambda s * lambda t’
      >- (rpt STRIP_TAC \\
          Cases_on ‘s = {}’ >- rw [lambda_empty] \\
          Cases_on ‘t = {}’ >- rw [lambda_empty] \\
          Know ‘IMAGE FST (s CROSS t) = s’
          >- (rw [Once EXTENSION] >> EQ_TAC >> RW_TAC std_ss [] >- art [] \\
              fs [GSYM MEMBER_NOT_EMPTY] >> rename1 ‘y IN t’ \\
              Q.EXISTS_TAC ‘(x,y)’ >> rw []) >> Rewr' \\
          Know ‘IMAGE SND (s CROSS t) = t’
          >- (rw [Once EXTENSION] >> EQ_TAC >> RW_TAC std_ss [] >- art [] \\
              fs [GSYM MEMBER_NOT_EMPTY] >> rename1 ‘y IN s’ \\
              Q.EXISTS_TAC ‘(y,x)’ >> rw []) >> Rewr) \\
      RW_TAC std_ss [] \\
      Q.EXISTS_TAC ‘(UNIV CROSS UNIV,
                     subsets ((UNIV,subsets borel) CROSS (UNIV,subsets borel)),m)’ \\
      Know ‘(univ(:real),subsets borel) = borel’ >- (REWRITE_TAC [GSYM space_borel, SPACE]) \\
      DISCH_THEN (fs o wrap) \\
      reverse CONJ_TAC >- METIS_TAC [] \\
      rpt STRIP_TAC \\
      IMP_RES_TAC MEASURE_SPACE_POSITIVE >> fs [positive_def] \\
      Cases_on ‘s = {}’ >- rw [lambda_empty] \\
      Cases_on ‘t = {}’ >- rw [lambda_empty] \\
      Q.PAT_X_ASSUM ‘!s. _ ==> (m s = lambda (IMAGE FST s) * lambda (IMAGE SND s))’
        (MP_TAC o (Q.SPEC ‘s CROSS t’)) >> RW_TAC std_ss [] \\
      POP_ASSUM MATCH_MP_TAC \\
      qexistsl_tac [‘s’, ‘t’] >> art []);
in
  val lborel_2d_def = new_specification ("lborel_2d_def", ["lborel_2d"], thm);
end;

Definition prod_measure_def : (* was: pair_measure_def *)
    prod_measure m1 m2 =
      (m_space m1 CROSS m_space m2,
       subsets ((m_space m1,measurable_sets m1) CROSS (m_space m2,measurable_sets m2)),
       \s. pos_fn_integral m2 (\y. pos_fn_integral m1 (\x. indicator_fn s (x,y))))
End

val _ = overload_on ("CROSS", “prod_measure”);

Theorem measure_space_prod_measure : (* was: measure_space_pair_measure *)
    !m1 m2. sigma_finite_measure_space m1 /\
            sigma_finite_measure_space m2 ==> measure_space (m1 CROSS m2)
Proof
    rpt STRIP_TAC
 >> Cases_on ‘m1’ >> Cases_on ‘r’
 >> rename1 ‘sigma_finite_measure_space (X,A,u)’
 >> Cases_on ‘m2’ >> Cases_on ‘r’
 >> rename1 ‘sigma_finite_measure_space (Y,B,v)’
 (* applying EXISTENCE_OF_PROD_MEASURE *)
 >> MP_TAC (Q.SPECL [‘X’, ‘Y’, ‘A’, ‘B’, ‘u’, ‘v’] EXISTENCE_OF_PROD_MEASURE)
 >> DISCH_THEN (MP_TAC o (Q.SPEC ‘\x. u (IMAGE FST x) * v (IMAGE SND x)’))
 >> Know ‘!s t. s IN A /\ t IN B ==>
                (\x. u (IMAGE FST x) * v (IMAGE SND x)) (s CROSS t) = u s * v t’
 >- (rpt STRIP_TAC \\
     fs [sigma_finite_measure_space_def] \\
     Cases_on ‘s = {}’ >- (IMP_RES_TAC MEASURE_SPACE_POSITIVE >> fs [positive_def]) \\
     Cases_on ‘t = {}’ >- (IMP_RES_TAC MEASURE_SPACE_POSITIVE >> fs [positive_def]) \\
     Know ‘IMAGE FST (s CROSS t) = s’
     >- (rw [Once EXTENSION] >> EQ_TAC >> RW_TAC std_ss [] >- art [] \\
         Q.PAT_X_ASSUM ‘t <> {}’ (STRIP_ASSUME_TAC o
                                  (REWRITE_RULE [GSYM MEMBER_NOT_EMPTY])) \\
         rename1 ‘y IN t’ >> Q.EXISTS_TAC ‘(x,y)’ >> rw []) >> Rewr' \\
     Know ‘IMAGE SND (s CROSS t) = t’
     >- (rw [Once EXTENSION] >> EQ_TAC >> RW_TAC std_ss [] >- art [] \\
         Q.PAT_X_ASSUM ‘t <> {}’ K_TAC \\
         Q.PAT_X_ASSUM ‘s <> {}’ (STRIP_ASSUME_TAC o
                                  (REWRITE_RULE [GSYM MEMBER_NOT_EMPTY])) \\
         rename1 ‘y IN s’ >> Q.EXISTS_TAC ‘(y,x)’ >> rw []) >> Rewr)
 >> RW_TAC std_ss []
 >> ‘m_space ((X,A,u) CROSS (Y,B,v)) = X CROSS Y’ by rw [prod_measure_def]
 >> ‘measurable_sets ((X,A,u) CROSS (Y,B,v)) =
     subsets ((X,A) CROSS (Y,B))’ by rw [prod_measure_def]
 >> Know ‘space ((X,A) CROSS (Y,B)) = X CROSS Y’
 >- (rw [prod_sigma_def] >> REWRITE_TAC [SPACE_SIGMA]) >> DISCH_TAC
 >> fs [sigma_finite_measure_space_def]
 >> MATCH_MP_TAC measure_space_eq
 >> Q.EXISTS_TAC ‘(X CROSS Y,subsets ((X,A) CROSS (Y,B)),m)’
 >> rw [prod_measure_def]
QED

(* ‘lborel_2d = lborel CROSS lborel’ doesn't hold *)
Theorem lborel_2d_prod_measure :
    !s. s IN measurable_sets lborel_2d ==>
        measure lborel_2d s = measure (lborel CROSS lborel) s
Proof
    RW_TAC std_ss [prod_measure_def]
 >> STRIP_ASSUME_TAC lborel_2d_def
 >> rw [space_lborel, sets_lborel]
 >> METIS_TAC []
QED

(******************************************************************************)
(*     Fubini-Tonelli Theorems                                                *)
(******************************************************************************)

(* Theorem 14.8 [1, p.142] (Tonelli's theorem)

   named after Leonida Tonelli, an Italian mathematician [5].

   cf. HVG's limited version under the name "fubini":

 |- !f M1 M2. measure_space M1 /\ measure_space M2 /\
       sigma_finite_measure M1 /\ sigma_finite_measure M2 /\
       (!x. 0 <= f x) /\
       f IN measurable
        (m_space (pair_measure M1 M2), measurable_sets (pair_measure M1 M2)) Borel ==>
       (pos_fn_integral M1 (\x. pos_fn_integral M2 (\y. f (x,y))) =
        pos_fn_integral M2 (\y. pos_fn_integral M1 (\x. f (x,y)))): thm
 *)
Theorem TONELLI : (* was: fubini (HVG concordia) *)
    !(X :'a set) (Y :'b set) A B u v f.
        sigma_finite_measure_space (X,A,u) /\
        sigma_finite_measure_space (Y,B,v) /\
        f IN measurable ((X,A) CROSS (Y,B)) Borel /\
        (!s. s IN X CROSS Y ==> 0 <= f s)
       ==>
        (!y. y IN Y ==> (\x. f (x,y)) IN measurable (X,A) Borel) /\
        (!x. x IN X ==> (\y. f (x,y)) IN measurable (Y,B) Borel) /\
        (\x. pos_fn_integral (Y,B,v) (\y. f (x,y))) IN measurable (X,A) Borel /\
        (\y. pos_fn_integral (X,A,u) (\x. f (x,y))) IN measurable (Y,B) Borel /\
        (pos_fn_integral ((X,A,u) CROSS (Y,B,v)) f =
         pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. f (x,y)))) /\
        (pos_fn_integral ((X,A,u) CROSS (Y,B,v)) f =
         pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. f (x,y))))
Proof
    rpt GEN_TAC >> STRIP_TAC
 (* applying measure_space_prod_measure *)
 >> ‘measure_space ((X,A,u) CROSS (Y,B,v))’ (* only needed in goal 5 & 6 *)
      by METIS_TAC [measure_space_prod_measure]
 (* preliminaries *)
 >> Know ‘!i n. (0 :extreal) <= &i / 2 pow n’
 >- (rpt GEN_TAC \\
    ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
       by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
    ‘?r. 0 < r /\ (2 pow n = Normal r)’
       by METIS_TAC [lt_02, pow_pos_lt, extreal_cases, extreal_lt_eq,
                     extreal_of_num_def] >> POP_ORW \\
     MATCH_MP_TAC le_div >> rw [extreal_of_num_def, extreal_le_eq])
 >> DISCH_TAC
 >> Know ‘!i n. &i / 2 pow n <> PosInf /\ &i / 2 pow n <> NegInf’
 >- (rpt GEN_TAC \\
    ‘&i = Normal (&i)’ by METIS_TAC [extreal_of_num_def] >> POP_ORW \\
     MATCH_MP_TAC div_not_infty \\
     ONCE_REWRITE_TAC [EQ_SYM_EQ] >> MATCH_MP_TAC lt_imp_ne \\
     MATCH_MP_TAC pow_pos_lt >> REWRITE_TAC [lt_02])
 >> DISCH_TAC
 (* applying EXISTENCE_OF_PROD_MEASURE *)
 >> MP_TAC (Q.SPECL [‘X’, ‘Y’, ‘A’, ‘B’, ‘u’, ‘v’] EXISTENCE_OF_PROD_MEASURE)
 >> DISCH_THEN (MP_TAC o (Q.SPEC ‘\x. u (IMAGE FST x) * v (IMAGE SND x)’))
 >> Know ‘!s t. s IN A /\ t IN B ==>
                (\x. u (IMAGE FST x) * v (IMAGE SND x)) (s CROSS t) = u s * v t’
 >- (rpt STRIP_TAC \\
     fs [sigma_finite_measure_space_def] \\
     Cases_on ‘s = {}’ >- (IMP_RES_TAC MEASURE_SPACE_POSITIVE >> fs [positive_def]) \\
     Cases_on ‘t = {}’ >- (IMP_RES_TAC MEASURE_SPACE_POSITIVE >> fs [positive_def]) \\
     Know ‘IMAGE FST (s CROSS t) = s’
     >- (rw [Once EXTENSION] >> EQ_TAC >> RW_TAC std_ss [] >- art [] \\
         Q.PAT_X_ASSUM ‘t <> {}’ (STRIP_ASSUME_TAC o
                                  (REWRITE_RULE [GSYM MEMBER_NOT_EMPTY])) \\
         rename1 ‘y IN t’ >> Q.EXISTS_TAC ‘(x,y)’ >> rw []) >> Rewr' \\
     Know ‘IMAGE SND (s CROSS t) = t’
     >- (rw [Once EXTENSION] >> EQ_TAC >> RW_TAC std_ss [] >- art [] \\
         Q.PAT_X_ASSUM ‘t <> {}’ K_TAC \\
         Q.PAT_X_ASSUM ‘s <> {}’ (STRIP_ASSUME_TAC o
                                  (REWRITE_RULE [GSYM MEMBER_NOT_EMPTY])) \\
         rename1 ‘y IN s’ >> Q.EXISTS_TAC ‘(y,x)’ >> rw []) >> Rewr)
 >> DISCH_TAC
 >> ASM_SIMP_TAC std_ss []
 >> STRIP_TAC
 (* applying lemma_fn_seq_sup *)
 >> MP_TAC (Q.SPECL [‘(X,A,u) CROSS (Y,B,v)’, ‘f’]
                    (INST_TYPE [alpha |-> “:'a # 'b”] lemma_fn_seq_sup))
 >> ‘m_space ((X,A,u) CROSS (Y,B,v)) = X CROSS Y’ by rw [prod_measure_def]
 >> ASM_REWRITE_TAC [] >> DISCH_TAC
 >> ‘measurable_sets ((X,A,u) CROSS (Y,B,v)) =
       subsets ((X,A) CROSS (Y,B))’ by rw [prod_measure_def]
 >> Know ‘space ((X,A) CROSS (Y,B)) = X CROSS Y’
 >- (rw [prod_sigma_def] >> REWRITE_TAC [SPACE_SIGMA]) >> DISCH_TAC
 >> fs [sigma_finite_measure_space_def]
 >> ‘sigma_algebra (X,A) /\ sigma_algebra (Y,B)’
      by METIS_TAC [measure_space_def, space_def, subsets_def, m_space_def,
                    measurable_sets_def]
 >> Know ‘sigma_algebra ((X,A) CROSS (Y,B))’
 >- (MATCH_MP_TAC SIGMA_ALGEBRA_PROD_SIGMA \\
     fs [sigma_algebra_def, algebra_def]) >> DISCH_TAC
 (* common measurable sets inside fn_seq *)
 >> Q.ABBREV_TAC ‘s = \n k. {x | x IN X CROSS Y /\ &k / 2 pow n <= f x /\
                                 f x < (&k + 1) / 2 pow n}’
 >> Know ‘!n i. s n i IN subsets ((X,A) CROSS (Y,B))’
 >- (rpt GEN_TAC \\
     Know ‘s n i = ({x | &i / 2 pow n <= f x} INTER (X CROSS Y)) INTER
                   ({x | f x < (&i + 1) / 2 pow n} INTER (X CROSS Y))’
     >- (rw [Abbr ‘s’, Once EXTENSION, IN_INTER] \\
         EQ_TAC >> RW_TAC std_ss []) >> Rewr' \\
     MATCH_MP_TAC SIGMA_ALGEBRA_INTER \\
     MP_TAC (Q.SPECL [‘f’, ‘(X,A) CROSS (Y,B)’]
                     (INST_TYPE [alpha |-> “:'a # 'b”] IN_MEASURABLE_BOREL_ALL)) >> rw [])
 >> DISCH_TAC
 >> Q.ABBREV_TAC ‘t = \n. {x | x IN X CROSS Y /\ 2 pow n <= f x}’
 >> Know ‘!n. t n IN subsets ((X,A) CROSS (Y,B))’
 >- (RW_TAC std_ss [Abbr ‘t’] \\
    ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
        by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
    ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
    ‘{x | x IN X CROSS Y /\ Normal r <= f x} = {x | Normal r <= f x} INTER (X CROSS Y)’
        by SET_TAC [] >> POP_ORW \\
     MP_TAC (Q.SPECL [‘f’, ‘(X,A) CROSS (Y,B)’]
                     (INST_TYPE [alpha |-> “:'a # 'b”] IN_MEASURABLE_BOREL_ALL)) >> rw [])
 >> DISCH_TAC
 (* important properties of fn_seq *)
 >> Know ‘!n y. y IN Y /\ (!s. s IN subsets ((X,A) CROSS (Y,B)) ==>
                              (\x. indicator_fn s (x,y)) IN measurable (X,A) Borel) ==>
               (\x. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)) IN Borel_measurable (X,A)’
 >- (rpt STRIP_TAC \\
     ASM_SIMP_TAC std_ss [fn_seq_def] \\
    ‘!k. {x | x IN X CROSS Y /\ &k / 2 pow n <= f x /\ f x < (&k + 1) / 2 pow n} = s n k’
        by METIS_TAC [] >> POP_ORW \\
     MATCH_MP_TAC IN_MEASURABLE_BOREL_ADD \\
     qexistsl_tac [‘\x. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y))
                              (count (4 ** n))’,
                   ‘\x. 2 pow n * indicator_fn (t n) (x,y)’] \\
     ASM_SIMP_TAC std_ss [space_def] \\
     CONJ_TAC (* Borel_measurable #1 *)
     >- (MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] IN_MEASURABLE_BOREL_SUM) \\
         qexistsl_tac [‘\k x. &k / 2 pow n * indicator_fn (s n k) (x,y)’,
                       ‘count (4 ** n)’] \\
         ASM_SIMP_TAC std_ss [FINITE_COUNT, space_def] \\
         reverse CONJ_TAC
         >- (rpt GEN_TAC >> STRIP_TAC \\
             MATCH_MP_TAC pos_not_neginf \\
             MATCH_MP_TAC le_mul >> art [INDICATOR_FN_POS]) \\
         RW_TAC std_ss [IN_COUNT] \\
        ‘?z. &i / 2 pow n = Normal z’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> rw [] \\
         qexistsl_tac [‘\x. indicator_fn (s n i) (x,y)’, ‘z’] >> rw []) \\
     reverse CONJ_TAC
     >- (GEN_TAC >> DISCH_TAC >> DISJ1_TAC \\
         CONJ_TAC >> MATCH_MP_TAC pos_not_neginf >| (* 2 subgoals *)
         [ (* goal 1 (of 2) *)
           irule EXTREAL_SUM_IMAGE_POS \\
           reverse CONJ_TAC >- REWRITE_TAC [FINITE_COUNT] \\
           Q.X_GEN_TAC ‘i’ >> rw [] \\
           MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS],
           (* goal 2 (of 2) *)
           MATCH_MP_TAC le_mul >> REWRITE_TAC [INDICATOR_FN_POS] \\
           MATCH_MP_TAC pow_pos_le >> REWRITE_TAC [le_02] ]) \\
    ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
        by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
    ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> rw [] \\
     qexistsl_tac [‘\x. indicator_fn (t n) (x,y)’, ‘r’] >> rw [])
 >> DISCH_TAC
 >> Know ‘!n x. x IN X /\
               (!s. s IN subsets ((X,A) CROSS (Y,B)) ==>
                     (\y. indicator_fn s (x,y)) IN measurable (Y,B) Borel) ==>
               (\y. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)) IN Borel_measurable (Y,B)’
 >- (rpt STRIP_TAC \\
     ASM_SIMP_TAC std_ss [fn_seq_def] \\
    ‘!k. {x | x IN X CROSS Y /\ &k / 2 pow n <= f x /\ f x < (&k + 1) / 2 pow n} = s n k’
        by METIS_TAC [] >> POP_ORW \\
     MATCH_MP_TAC IN_MEASURABLE_BOREL_ADD \\
     qexistsl_tac [‘\y. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y))
                              (count (4 ** n))’,
                   ‘\y. 2 pow n * indicator_fn (t n) (x,y)’] \\
     ASM_SIMP_TAC std_ss [space_def] \\
     CONJ_TAC (* Borel_measurable #1 *)
     >- (MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] IN_MEASURABLE_BOREL_SUM) \\
         qexistsl_tac [‘\k y. &k / 2 pow n * indicator_fn (s n k) (x,y)’,
                       ‘count (4 ** n)’] \\
         ASM_SIMP_TAC std_ss [FINITE_COUNT, space_def] \\
         reverse CONJ_TAC
         >- (rpt GEN_TAC >> STRIP_TAC \\
             MATCH_MP_TAC pos_not_neginf \\
             MATCH_MP_TAC le_mul >> art [INDICATOR_FN_POS]) \\
         RW_TAC std_ss [IN_COUNT] \\
        ‘?z. &i / 2 pow n = Normal z’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> rw [] \\
         qexistsl_tac [‘\y. indicator_fn (s n i) (x,y)’, ‘z’] >> rw []) \\
     reverse CONJ_TAC
     >- (GEN_TAC >> DISCH_TAC >> DISJ1_TAC \\
         CONJ_TAC >> MATCH_MP_TAC pos_not_neginf >| (* 2 subgoals *)
         [ (* goal 1 (of 2) *)
           irule EXTREAL_SUM_IMAGE_POS \\
           reverse CONJ_TAC >- REWRITE_TAC [FINITE_COUNT] \\
           Q.X_GEN_TAC ‘i’ >> rw [] \\
           MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS],
           (* goal 2 (of 2) *)
           MATCH_MP_TAC le_mul >> REWRITE_TAC [INDICATOR_FN_POS] \\
           MATCH_MP_TAC pow_pos_le >> REWRITE_TAC [le_02] ]) \\
    ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
        by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
    ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> rw [] \\
     qexistsl_tac [‘\y. indicator_fn (t n) (x,y)’, ‘r’] >> rw [])
 >> DISCH_TAC
 (* shared property by goal 3 and 5/6 *)
 >> Know ‘!n. (\x. pos_fn_integral (Y,B,v) (\y. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)))
              IN Borel_measurable (X,A)’
 >- (RW_TAC std_ss [fn_seq_def] \\
    ‘!k. {x | x IN X CROSS Y /\ &k / 2 pow n <= f x /\ f x < (&k + 1) / 2 pow n} = s n k’
        by METIS_TAC [] >> POP_ORW \\
     MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
     Q.EXISTS_TAC ‘\x. pos_fn_integral (Y,B,v)
                         (\y. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y))
                                    (count (4 ** n))) +
                       pos_fn_integral (Y,B,v)
                         (\y. 2 pow n *
                              indicator_fn {x | x IN X CROSS Y /\ 2 pow n <= f x} (x,y))’ \\
     ASM_SIMP_TAC std_ss [] \\
     Know ‘!x. x IN X ==> (\y. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y))
                                     (count (4 ** n))) IN measurable (Y,B) Borel’
     >- (rpt STRIP_TAC \\
         MATCH_MP_TAC ((INST_TYPE [alpha |-> beta] o
                        INST_TYPE [beta |-> “:num”]) IN_MEASURABLE_BOREL_SUM) >> simp [] \\
         qexistsl_tac [‘\k y. &k / 2 pow n * indicator_fn (s n k) (x,y)’,
                       ‘count (4 ** n)’] >> simp [] \\
         CONJ_TAC
         >- (rpt STRIP_TAC \\
            ‘?z. &i / 2 pow n = Normal z’ by METIS_TAC [extreal_cases] >> POP_ORW \\
             MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> rw [] \\
             qexistsl_tac [‘\y. indicator_fn (s n i) (x,y)’, ‘z’] >> rw []) \\
         qx_genl_tac [‘i’, ‘y’] >> STRIP_TAC \\
         MATCH_MP_TAC pos_not_neginf \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) >> DISCH_TAC \\
     Know ‘!x. x IN X ==> (\y. 2 pow n * indicator_fn (t n) (x,y)) IN measurable (Y,B) Borel’
     >- (rpt STRIP_TAC \\
        ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
            by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
        ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL \\
         ASM_SIMP_TAC std_ss [space_def] \\
         qexistsl_tac [‘\y. indicator_fn (t n) (x,y)’, ‘r’] >> rw []) >> DISCH_TAC \\
     RW_TAC std_ss []
     >- (HO_MATCH_MP_TAC pos_fn_integral_add \\
         ASM_SIMP_TAC std_ss [m_space_def, measurable_sets_def] \\
         CONJ_TAC >- (rpt STRIP_TAC \\
                      MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> rw [IN_COUNT] \\
                      MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
         rpt STRIP_TAC \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
     MATCH_MP_TAC IN_MEASURABLE_BOREL_ADD \\
     qexistsl_tac [‘\x. pos_fn_integral (Y,B,v)
                          (\y. SIGMA (\k. &k / 2 pow n *
                                          indicator_fn (s n k) (x,y)) (count (4 ** n)))’,
                   ‘\x. pos_fn_integral (Y,B,v)
                          (\y. 2 pow n * indicator_fn (t n) (x,y))’] \\
     ASM_SIMP_TAC std_ss [space_def] \\
     REWRITE_TAC [CONJ_ASSOC] >> reverse CONJ_TAC
     >- (GEN_TAC >> DISCH_TAC >> DISJ1_TAC \\
         CONJ_TAC >> MATCH_MP_TAC pos_not_neginf >|
         [ (* goal 1 (of 2) *)
           MATCH_MP_TAC pos_fn_integral_pos >> simp [] \\
           Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
           MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> simp [] \\
           Q.X_GEN_TAC ‘i’ >> DISCH_TAC \\
           MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS],
           (* goal 2 (of 2) *)
           MATCH_MP_TAC pos_fn_integral_pos >> simp [] \\
           Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
           MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le] ]) \\
     CONJ_TAC
     >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                    (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
         Q.EXISTS_TAC ‘\x. SIGMA (\k. pos_fn_integral (Y,B,v)
                                        (\y. &k / 2 pow n * indicator_fn (s n k) (x,y)))
                                 (count (4 ** n))’ \\
         reverse CONJ_TAC
         >- (MATCH_MP_TAC ((INST_TYPE [alpha |-> beta] o
                            INST_TYPE [beta |-> “:num”]) IN_MEASURABLE_BOREL_SUM) >> simp [] \\
             qexistsl_tac [‘\k x. pos_fn_integral (Y,B,v)
                                    (\y. &k / 2 pow n * indicator_fn (s n k) (x,y))’,
                           ‘count (4 ** n)’] >> simp [] \\
             CONJ_TAC
             >- (rpt STRIP_TAC \\
                ‘?z. 0 <= z /\ (&i / 2 pow n = Normal z)’
                     by METIS_TAC [extreal_cases, extreal_le_eq, extreal_of_num_def] >> POP_ORW \\
                 MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                            (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
                 Q.EXISTS_TAC ‘\x. Normal z * pos_fn_integral (Y,B,v)
                                                (\y. indicator_fn (s n i) (x,y))’ >> BETA_TAC \\
                 CONJ_TAC >- (rpt STRIP_TAC \\
                              HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) \\
                 MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> rw [] \\
                 qexistsl_tac [‘\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (s n i) (x,y))’,
                               ‘z’] >> rw []) \\
             qx_genl_tac [‘i’, ‘x’] >> STRIP_TAC \\
             MATCH_MP_TAC pos_not_neginf \\
             MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
             MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
         RW_TAC std_ss [] \\
         Q.ABBREV_TAC ‘g = \k y. &k / 2 pow n * indicator_fn (s n k) (x,y)’ \\
         MP_TAC (Q.SPECL [‘(Y,B,v)’, ‘g’, ‘count (4 ** n)’]
                         ((INST_TYPE [alpha |-> beta] o
                           INST_TYPE [beta |-> “:num”]) pos_fn_integral_sum)) \\
         simp [Abbr ‘g’] \\
         Know ‘!i. i < 4 ** n ==>
                   !y. y IN Y ==> 0 <= &i / 2 pow n * indicator_fn (s n i) (x,y)’
         >- (rpt STRIP_TAC >> MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
         Suff ‘!i. i < 4 ** n ==>
                   (\y. &i / 2 pow n * indicator_fn (s n i) (x,y)) IN Borel_measurable (Y,B)’
         >- RW_TAC std_ss [] \\
         rpt STRIP_TAC \\
        ‘?z. &i / 2 pow n = Normal z’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         MATCH_MP_TAC (INST_TYPE [alpha |-> beta] IN_MEASURABLE_BOREL_CMUL) >> simp [] \\
         qexistsl_tac [‘\y. indicator_fn (s n i) (x,y)’, ‘z’] >> rw []) \\
    ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
        by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
    ‘?r. 0 <= r /\ (2 pow n = Normal r)’
        by METIS_TAC [extreal_cases, pow_pos_le, le_02, extreal_le_eq, extreal_of_num_def] \\
     POP_ORW \\
     MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
     Q.EXISTS_TAC ‘\x. Normal r * (pos_fn_integral (Y,B,v) (\y. indicator_fn (t n) (x,y)))’ \\
     BETA_TAC \\
     CONJ_TAC >- (rpt STRIP_TAC \\
                  HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) \\
     MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
     qexistsl_tac [‘\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (t n) (x,y))’, ‘r’] >> rw [])
 >> DISCH_TAC
 (* shared property by goal 4 and 5/6 *)
 >> Know ‘!n. (\y. pos_fn_integral (X,A,u) (\x. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)))
              IN Borel_measurable (Y,B)’
 >- (RW_TAC std_ss [fn_seq_def] \\
    ‘!k. {x | x IN X CROSS Y /\ &k / 2 pow n <= f x /\ f x < (&k + 1) / 2 pow n} = s n k’
        by METIS_TAC [] >> POP_ORW \\
     MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
     Q.EXISTS_TAC ‘\y. pos_fn_integral (X,A,u)
                         (\x. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y))
                                    (count (4 ** n))) +
                       pos_fn_integral (X,A,u)
                         (\x. 2 pow n * indicator_fn (t n) (x,y))’ \\
     ASM_SIMP_TAC std_ss [] \\
     Know ‘!y. y IN Y ==> (\x. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y))
                                     (count (4 ** n))) IN measurable (X,A) Borel’
     >- (rpt STRIP_TAC \\
         MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] IN_MEASURABLE_BOREL_SUM) >> simp [] \\
         qexistsl_tac [‘\k x. &k / 2 pow n * indicator_fn (s n k) (x,y)’,
                       ‘count (4 ** n)’] >> simp [] \\
         CONJ_TAC
         >- (rpt STRIP_TAC \\
            ‘?z. &i / 2 pow n = Normal z’ by METIS_TAC [extreal_cases] >> POP_ORW \\
             MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> rw [] \\
             qexistsl_tac [‘\x. indicator_fn (s n i) (x,y)’, ‘z’] >> rw []) \\
         qx_genl_tac [‘i’, ‘x’] >> STRIP_TAC \\
         MATCH_MP_TAC pos_not_neginf \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
     DISCH_TAC \\
     Know ‘!y. y IN Y ==> (\x. 2 pow n * indicator_fn (t n) (x,y)) IN measurable (X,A) Borel’
     >- (rpt STRIP_TAC \\
        ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
            by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
        ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> rw [] \\
         qexistsl_tac [‘\x. indicator_fn (t n) (x,y)’, ‘r’] >> rw []) >> DISCH_TAC \\
     RW_TAC std_ss []
     >- (HO_MATCH_MP_TAC pos_fn_integral_add \\
         ASM_SIMP_TAC std_ss [m_space_def, measurable_sets_def] \\
         CONJ_TAC >- (rpt STRIP_TAC \\
                      MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> rw [IN_COUNT] \\
                      MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
         rpt STRIP_TAC \\
         MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
     MATCH_MP_TAC IN_MEASURABLE_BOREL_ADD \\
     qexistsl_tac [‘\y. pos_fn_integral (X,A,u)
                          (\x. SIGMA (\k. &k / 2 pow n *
                                          indicator_fn (s n k) (x,y)) (count (4 ** n)))’,
                   ‘\y. pos_fn_integral (X,A,u)
                          (\x. 2 pow n * indicator_fn (t n) (x,y))’] \\
     ASM_SIMP_TAC std_ss [space_def] \\
     REWRITE_TAC [CONJ_ASSOC] >> reverse CONJ_TAC
     >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC >> DISJ1_TAC \\
         CONJ_TAC >> MATCH_MP_TAC pos_not_neginf >|
         [ (* goal 4.1 (of 2) *)
           MATCH_MP_TAC pos_fn_integral_pos >> simp [] \\
           Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
           MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> simp [] \\
           Q.X_GEN_TAC ‘i’ >> DISCH_TAC \\
           MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS],
           (* goal 4.2 (of 2) *)
           MATCH_MP_TAC pos_fn_integral_pos >> simp [] \\
           Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
           MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le] ]) \\
     CONJ_TAC
     >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                    (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
         Q.EXISTS_TAC ‘\y. SIGMA (\k. pos_fn_integral (X,A,u)
                                        (\x. &k / 2 pow n * indicator_fn (s n k) (x,y)))
                                 (count (4 ** n))’ \\
         reverse CONJ_TAC
         >- (MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] IN_MEASURABLE_BOREL_SUM) >> simp [] \\
             qexistsl_tac [‘\k y. pos_fn_integral (X,A,u)
                                    (\x. &k / 2 pow n * indicator_fn (s n k) (x,y))’,
                           ‘count (4 ** n)’] >> simp [] \\
             CONJ_TAC
             >- (rpt STRIP_TAC \\
                ‘?z. 0 <= z /\ (&i / 2 pow n = Normal z)’
                    by METIS_TAC [extreal_cases, extreal_le_eq, extreal_of_num_def] >> POP_ORW \\
                 MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                            (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
                 Q.EXISTS_TAC ‘\y. Normal z * pos_fn_integral (X,A,u)
                                                (\x. indicator_fn (s n i) (x,y))’ >> BETA_TAC \\
                 CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                              HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) \\
                 MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> rw [] \\
                 qexistsl_tac [‘\y. pos_fn_integral (X,A,u) (\x. indicator_fn (s n i) (x,y))’,
                               ‘z’] >> rw []) \\
             qx_genl_tac [‘i’, ‘y’] >> STRIP_TAC \\
             MATCH_MP_TAC pos_not_neginf \\
             MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
             MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
         Q.X_GEN_TAC ‘y’ >> STRIP_TAC \\
         Q.ABBREV_TAC ‘g = \k x. &k / 2 pow n * indicator_fn (s n k) (x,y)’ \\
         MP_TAC (Q.SPECL [‘(X,A,u)’, ‘g’, ‘count (4 ** n)’]
                         (INST_TYPE [beta |-> “:num”] pos_fn_integral_sum)) \\
         simp [Abbr ‘g’] \\
         Know ‘!i. i < 4 ** n ==>
                   !x. x IN X ==> 0 <= &i / 2 pow n * indicator_fn (s n i) (x,y)’
         >- (rpt STRIP_TAC >> MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
         Suff ‘!i. i < 4 ** n ==>
                   (\x. &i / 2 pow n * indicator_fn (s n i) (x,y)) IN Borel_measurable (X,A)’
         >- RW_TAC std_ss [] \\
         rpt STRIP_TAC \\
        ‘?z. &i / 2 pow n = Normal z’ by METIS_TAC [extreal_cases] >> POP_ORW \\
         MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
         qexistsl_tac [‘\x. indicator_fn (s n i) (x,y)’, ‘z’] >> rw []) \\
    ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
        by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
    ‘?r. 0 <= r /\ (2 pow n = Normal r)’
        by METIS_TAC [extreal_cases, pow_pos_le, le_02, extreal_le_eq, extreal_of_num_def] \\
     POP_ORW \\
     MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
     Q.EXISTS_TAC ‘\y. Normal r * (pos_fn_integral (X,A,u) (\x. indicator_fn (t n) (x,y)))’ \\
     BETA_TAC \\
     CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                  HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) \\
     MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
     qexistsl_tac [‘\y. pos_fn_integral (X,A,u) (\x. indicator_fn (t n) (x,y))’, ‘r’] >> rw [])
 >> DISCH_TAC
 (* stage work *)
 >> RW_TAC std_ss [] (* 6 subgoals *)
 >| [ (* goal 1 (of 6) *)
      MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                 (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) \\
      Q.EXISTS_TAC ‘\x. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))
                                   UNIV)’ >> rw [] \\
      MATCH_MP_TAC IN_MEASURABLE_BOREL_MONO_SUP \\
      Q.EXISTS_TAC ‘\n x. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)’ >> rw [] \\
      irule (SIMP_RULE std_ss [ext_mono_increasing_def]
                              lemma_fn_seq_mono_increasing) >> rw [],
      (* goal 2 (of 6), symmetric with goal 1 *)
      MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                 (Q.SPEC ‘(Y,B,v)’
                                         (INST_TYPE [alpha |-> beta] IN_MEASURABLE_BOREL_EQ))) \\
      Q.EXISTS_TAC ‘\y. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))
                                   UNIV)’ >> rw [] \\
      MATCH_MP_TAC IN_MEASURABLE_BOREL_MONO_SUP \\
      Q.EXISTS_TAC ‘\n y. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)’ >> rw [] \\
      irule (SIMP_RULE std_ss [ext_mono_increasing_def]
                              lemma_fn_seq_mono_increasing) >> rw [],
      (* goal 3 (of 6) *)
      MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                 (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
      Q.EXISTS_TAC ‘\x. pos_fn_integral (Y,B,v)
                          (\y. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))
                                          UNIV))’ >> rw []
      >- (MATCH_MP_TAC pos_fn_integral_cong >> rw []) \\
      MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                 (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
      Q.EXISTS_TAC ‘\x. sup (IMAGE (\n. pos_fn_integral (Y,B,v)
                                          (\y. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)))
                             UNIV)’ >> rw []
      >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence \\
          simp [lemma_fn_seq_positive, lemma_fn_seq_mono_increasing]) \\
      MATCH_MP_TAC IN_MEASURABLE_BOREL_MONO_SUP >> simp [] \\
      Q.EXISTS_TAC ‘\n x. pos_fn_integral (Y,B,v)
                            (\y. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))’ \\
      RW_TAC std_ss [] \\
      MATCH_MP_TAC pos_fn_integral_mono >> simp [lemma_fn_seq_positive] \\
      Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
      irule (SIMP_RULE std_ss [ext_mono_increasing_def]
                              lemma_fn_seq_mono_increasing) >> rw [],
      (* goal 4 (of 6), symmetric with goal 3 *)
      MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                 (Q.SPEC ‘(Y,B,b)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
      Q.EXISTS_TAC ‘\y. pos_fn_integral (X,A,u)
                          (\x. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))
                                          UNIV))’ >> rw []
      >- (MATCH_MP_TAC pos_fn_integral_cong >> rw []) \\
      MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                 (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) >> BETA_TAC \\
      Q.EXISTS_TAC ‘\y. sup (IMAGE (\n. pos_fn_integral (X,A,u)
                                          (\x. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)))
                             UNIV)’ >> rw []
      >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence \\
          simp [lemma_fn_seq_positive, lemma_fn_seq_mono_increasing]) \\
      MATCH_MP_TAC IN_MEASURABLE_BOREL_MONO_SUP >> simp [] \\
      Q.EXISTS_TAC ‘\n y. pos_fn_integral (X,A,u)
                            (\x. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))’ \\
      ASM_SIMP_TAC std_ss [] \\
      qx_genl_tac [‘n’, ‘y’] >> DISCH_TAC \\
      MATCH_MP_TAC pos_fn_integral_mono >> simp [lemma_fn_seq_positive] \\
      Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
      irule (SIMP_RULE std_ss [ext_mono_increasing_def]
                              lemma_fn_seq_mono_increasing) >> rw [],
      (* goal 5 (of 6) *)
      Know ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) f =
            pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\x. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n x) UNIV))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp []) >> Rewr' \\
      Know ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\x. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n x) UNIV)) =
            sup (IMAGE (\n. pos_fn_integral ((X,A,u) CROSS (Y,B,v))
                              (\z. fn_seq ((X,A,u) CROSS (Y,B,v)) f n z)) UNIV)’
      >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [] \\
          REWRITE_TAC [CONJ_ASSOC] (* easier goals first *) \\
          reverse CONJ_TAC (* mono_increasing *)
          >- (rpt STRIP_TAC >> MATCH_MP_TAC lemma_fn_seq_mono_increasing \\
              FIRST_X_ASSUM MATCH_MP_TAC >> art []) \\
          reverse CONJ_TAC (* positive *)
          >- (rpt STRIP_TAC >> MATCH_MP_TAC lemma_fn_seq_positive \\
              FIRST_X_ASSUM MATCH_MP_TAC >> art []) \\
          RW_TAC std_ss [fn_seq_def] \\
         ‘(X CROSS Y,subsets ((X,A) CROSS (Y,B))) = (X,A) CROSS (Y,B)’
            by METIS_TAC [SPACE] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_ADD \\
          ASM_SIMP_TAC std_ss [space_def] \\
          qexistsl_tac [‘\z. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) z) (count (4 ** n))’,
                        ‘\z. 2 pow n * indicator_fn (t n) z’] \\
          ASM_SIMP_TAC std_ss [CONJ_ASSOC] \\
          reverse CONJ_TAC (* nonnegative *)
          >- (Q.X_GEN_TAC ‘z’ >> DISCH_TAC >> DISJ1_TAC \\
              CONJ_TAC >> MATCH_MP_TAC pos_not_neginf >| (* 2 subgoals *)
              [ (* goal 5.1 (of 2) *)
                MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> rw [] \\
                MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS],
                (* goal 5.2 (of 2) *)
                MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le] ]) \\
          CONJ_TAC (* Borel_measurable #1 *)
          >- (MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] IN_MEASURABLE_BOREL_SUM) \\
              ASM_SIMP_TAC std_ss [space_def] \\
              qexistsl_tac [‘\k z. &k / 2 pow n * indicator_fn (s n k) z’,
                            ‘count (4 ** n)’] >> simp [] \\
              reverse CONJ_TAC
              >- (qx_genl_tac [‘i’, ‘z’] >> STRIP_TAC \\
                  MATCH_MP_TAC pos_not_neginf \\
                  MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
              rpt STRIP_TAC \\
             ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
              MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> rw []) \\
         ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
             by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
         ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> rw []) >> Rewr' \\
      Know ‘pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. f (x,y))) =
            pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u)
                     (\x. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)) UNIV)))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw []) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw []) \\
          Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
          MATCH_MP_TAC pos_fn_integral_cong >> simp []) >> Rewr' \\
      Know ‘pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u)
                     (\x. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)) UNIV))) =
            pos_fn_integral (Y,B,v)
              (\y. sup (IMAGE (\n. pos_fn_integral (X,A,u)
                                     (\x. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))) UNIV))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw []) \\
          CONJ_TAC
          >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
              rw [le_sup', IN_IMAGE, IN_UNIV] \\
              MATCH_MP_TAC le_trans \\
              Q.EXISTS_TAC ‘pos_fn_integral (X,A,u)
                              (\x. fn_seq ((X,A,u) CROSS (Y,B,v)) f 0 (x,y))’ \\
              CONJ_TAC >- (MATCH_MP_TAC pos_fn_integral_pos >> rw [lemma_fn_seq_positive]) \\
              POP_ASSUM MATCH_MP_TAC >> Q.EXISTS_TAC ‘0’ >> REWRITE_TAC []) \\
          Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
          HO_MATCH_MP_TAC lebesgue_monotone_convergence \\
          simp [lemma_fn_seq_positive, lemma_fn_seq_mono_increasing]) >> Rewr' \\
      Know ‘pos_fn_integral (Y,B,v)
              (\y. sup (IMAGE (\n. pos_fn_integral (X,A,u)
                                     (\x. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))) UNIV)) =
            sup (IMAGE (\n. pos_fn_integral (Y,B,v)
                              (\y. pos_fn_integral (X,A,u)
                                     (\x. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)))) UNIV)’
      >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [] \\
          CONJ_TAC >- (rpt STRIP_TAC >> MATCH_MP_TAC pos_fn_integral_pos \\
                       simp [lemma_fn_seq_positive]) \\
          RW_TAC std_ss [ext_mono_increasing_def] \\
          MATCH_MP_TAC pos_fn_integral_mono >> simp [lemma_fn_seq_positive] \\
          rpt STRIP_TAC \\
          irule (SIMP_RULE std_ss [ext_mono_increasing_def]
                                  lemma_fn_seq_mono_increasing) >> art [] \\
          FIRST_X_ASSUM MATCH_MP_TAC >> rw []) >> Rewr' \\
      Suff ‘!n. pos_fn_integral (Y,B,v)
                  (\y. pos_fn_integral (X,A,u) (\x. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))) =
                pos_fn_integral ((X,A,u) CROSS (Y,B,v))
                  (\z. fn_seq ((X,A,u) CROSS (Y,B,v)) f n z)’ >- rw [] \\
   (* ‘sup’ disappeared now *)
      GEN_TAC >> ASM_SIMP_TAC std_ss [fn_seq_def] \\
     ‘!k. {x | x IN X CROSS Y /\ &k / 2 pow n <= f x /\ f x < (&k + 1) / 2 pow n} = s n k’
         by METIS_TAC [] >> POP_ORW \\
   (* RHS simplification *)
      Know ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\z. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) z) (count (4 ** n)) +
                   2 pow n * indicator_fn (t n) z) =
            pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\z. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) z) (count (4 ** n))) +
            pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\z. 2 pow n * indicator_fn (t n) z)’
      >- (HO_MATCH_MP_TAC pos_fn_integral_add >> simp [] \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
         ‘(X CROSS Y,subsets ((X,A) CROSS (Y,B))) = (X,A) CROSS (Y,B)’
            by METIS_TAC [SPACE] >> POP_ORW \\
          reverse CONJ_TAC
          >- (‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
                 by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
              ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
              MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> rw []) \\
          MATCH_MP_TAC ((INST_TYPE [alpha |-> “:'a # 'b”] o
                         INST_TYPE [beta |-> “:num”]) IN_MEASURABLE_BOREL_SUM) >> simp [] \\
          qexistsl_tac [‘\k z. &k / 2 pow n * indicator_fn (s n k) z’,
                        ‘count (4 ** n)’] >> simp [] \\
          reverse CONJ_TAC >- (qx_genl_tac [‘i’, ‘z’] >> STRIP_TAC \\
                               MATCH_MP_TAC pos_not_neginf \\
                               MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          rpt STRIP_TAC \\
         ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> rw []) >> Rewr' \\
   (* LHS simplification *)
      Know ‘pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u)
                     (\x. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y)) (count (4 ** n)) +
                          2 pow n * indicator_fn (t n) (x,y))) =
            pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u)
                     (\x. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y)) (count (4 ** n))) +
                   pos_fn_integral (X,A,u)
                     (\x. 2 pow n * indicator_fn (t n) (x,y)))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_add \\
                       reverse CONJ_TAC
                       >- (MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_add \\
                       reverse CONJ_TAC
                       >- (MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                           MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
          Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
          HO_MATCH_MP_TAC pos_fn_integral_add >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
          reverse CONJ_TAC
          >- (‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
                 by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
              ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
              MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
              qexistsl_tac [‘\x. indicator_fn (t n) (x,y)’, ‘r’] >> rw []) \\
          MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] IN_MEASURABLE_BOREL_SUM) >> simp [] \\
          qexistsl_tac [‘\k x. &k / 2 pow n * indicator_fn (s n k) (x,y)’,
                        ‘count (4 ** n)’] >> simp [] \\
          reverse CONJ_TAC >- (rpt GEN_TAC >> STRIP_TAC \\
                               MATCH_MP_TAC pos_not_neginf \\
                               MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          rpt STRIP_TAC \\
         ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
          qexistsl_tac [‘\x. indicator_fn (s n i) (x,y)’, ‘r’] >> rw []) >> Rewr' \\
   (* LHS simplification *)
      Know ‘pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u)
                     (\x. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y))
                                (count (4 ** n))) +
                   pos_fn_integral (X,A,u) (\x. 2 pow n * indicator_fn (t n) (x,y))) =
            pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u)
                     (\x. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y))
                                (count (4 ** n)))) +
            pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u) (\x. 2 pow n * indicator_fn (t n) (x,y)))’
      >- (HO_MATCH_MP_TAC pos_fn_integral_add >> simp [] \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
          reverse CONJ_TAC
          >- (‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
                 by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
              ‘?r. 0 <= r /\ (2 pow n = Normal r)’
                 by METIS_TAC [extreal_cases, pow_pos_le, extreal_le_eq,
                               extreal_of_num_def, le_02] >> POP_ORW \\
              MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                         (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) \\
              BETA_TAC \\
              Q.EXISTS_TAC ‘\y. Normal r *
                                pos_fn_integral (X,A,u) (\x. indicator_fn (t n) (x,y))’ \\
              reverse CONJ_TAC
              >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
                  qexistsl_tac [‘\y. pos_fn_integral (X,A,u) (\x. indicator_fn (t n) (x,y))’,
                                ‘r’] >> rw []) \\
              Q.X_GEN_TAC ‘y’ >> RW_TAC std_ss [] \\
              HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) \\
          MATCH_MP_TAC ((INST_TYPE [alpha |-> beta] o
                         INST_TYPE [beta |-> “:num”]) IN_MEASURABLE_BOREL_SUM) \\
          ASM_SIMP_TAC std_ss [space_def] \\
          qexistsl_tac [‘\k y. pos_fn_integral (X,A,u)
                                 (\x. &k / 2 pow n * indicator_fn (s n k) (x,y))’,
                        ‘count (4 ** n)’] >> simp [] \\
          CONJ_TAC
          >- (rpt STRIP_TAC \\
             ‘?r. 0 <= r /\ (&i / 2 pow n = Normal r)’
                 by METIS_TAC [extreal_cases, extreal_le_eq, extreal_of_num_def] >> POP_ORW \\
              MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                         (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) \\
              BETA_TAC \\
              Q.EXISTS_TAC ‘\y. Normal r *
                                pos_fn_integral (X,A,u) (\x. indicator_fn (s n i) (x,y))’ \\
              simp [] \\
              reverse CONJ_TAC
              >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
                  qexistsl_tac [‘\y. pos_fn_integral (X,A,u) (\x. indicator_fn (s n i) (x,y))’,
                                ‘r’] >> rw []) \\
              Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
              HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (qx_genl_tac [‘i’, ‘y’] >> STRIP_TAC \\
                       MATCH_MP_TAC pos_not_neginf \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
          MATCH_MP_TAC ((BETA_RULE o
                         (Q.SPECL [‘(X,A,u)’,
                                   ‘\k x. &k / 2 pow n * indicator_fn (s n k) (x,y)’,
                                   ‘count (4 ** n)’]) o
                         (INST_TYPE [beta |-> “:num”])) pos_fn_integral_sum) >> simp [] \\
          CONJ_TAC >- (GEN_TAC >> DISCH_TAC \\
                       Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          GEN_TAC >> DISCH_TAC \\
         ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL \\
          ASM_SIMP_TAC std_ss [space_def] \\
          qexistsl_tac [‘\x. indicator_fn (s n i) (x,y)’, ‘r’] >> rw []) >> Rewr' \\
   (* LHS simplification *)
      Know ‘pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u) (\x. 2 pow n * indicator_fn (t n) (x,y))) =
            pos_fn_integral (Y,B,v)
              (\y. 2 pow n * pos_fn_integral (X,A,u) (\x. indicator_fn (t n) (x,y)))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_mul >> rw [pow_pos_le] \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS]) \\
          Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
         ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
             by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
         ‘?r. 0 <= r /\ (2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, pow_pos_le, extreal_le_eq,
                           extreal_of_num_def, le_02] >> POP_ORW \\
          HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
      Know ‘pos_fn_integral (Y,B,v)
              (\y. 2 pow n * pos_fn_integral (X,A,u) (\x. indicator_fn (t n) (x,y))) =
            2 pow n * pos_fn_integral (Y,B,v)
                        (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (t n) (x,y)))’
      >- (‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
             by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
          ‘?r. 0 <= r /\ (2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, pow_pos_le, extreal_le_eq,
                           extreal_of_num_def, le_02] >> POP_ORW \\
          HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [] \\
          MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS]) >> Rewr' \\
     ‘pos_fn_integral (Y,B,v)
        (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (t n) (x,y))) = m (t n)’
         by METIS_TAC [] >> POP_ORW \\
      Know ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (\z. 2 pow n * indicator_fn (t n) z) =
            2 pow n * pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (indicator_fn (t n))’
      >- (‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
             by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
          ‘?r. 0 <= r /\ (2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, pow_pos_le, extreal_le_eq,
                           extreal_of_num_def, le_02] >> POP_ORW \\
          HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
     ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (indicator_fn (t n)) =
      measure ((X,A,u) CROSS (Y,B,v)) (t n)’
         by METIS_TAC [pos_fn_integral_indicator] >> POP_ORW \\
      Know ‘measure ((X,A,u) CROSS (Y,B,v)) (t n) = m (t n)’
      >- (rw [prod_measure_def]) >> Rewr' \\
   (* stage work *)
      Suff ‘pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u)
                     (\x. SIGMA (\k. &k / 2 pow n *
                                     indicator_fn (s n k) (x,y)) (count (4 ** n)))) =
            pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\z. SIGMA (\k. &k / 2 pow n *
                              indicator_fn (s n k) z) (count (4 ** n)))’ >- Rewr \\
   (* RHS simplification *)
      Know ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\z. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) z) (count (4 ** n))) =
            SIGMA (\k. pos_fn_integral ((X,A,u) CROSS (Y,B,v))
                         (\z. &k / 2 pow n * indicator_fn (s n k) z)) (count (4 ** n))’
      >- (MATCH_MP_TAC ((BETA_RULE o
                         (Q.SPECL [‘(X,A,u) CROSS (Y,B,v)’,
                                   ‘\k z. &k / 2 pow n * indicator_fn (s n k) z’,
                                   ‘count (4 ** n)’]) o
                         (INST_TYPE [alpha |-> “:'a # 'b”]) o
                         (INST_TYPE [beta |-> “:num”])) pos_fn_integral_sum) >> simp [] \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          rpt STRIP_TAC \\
         ‘(X CROSS Y,subsets ((X,A) CROSS (Y,B))) = (X,A) CROSS (Y,B)’
            by METIS_TAC [SPACE] >> POP_ORW \\
         ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> rw []) >> Rewr' \\
      Know ‘!k. pos_fn_integral ((X,A,u) CROSS (Y,B,v))
                  (\z. &k / 2 pow n * indicator_fn (s n k) z) =
                &k / 2 pow n *
                pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (indicator_fn (s n k))’
      >- (GEN_TAC \\
         ‘?r. 0 <= r /\ (&k / 2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, extreal_le_eq, extreal_of_num_def] >> POP_ORW \\
          MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
     ‘!k. pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (indicator_fn (s n k)) =
          measure ((X,A,u) CROSS (Y,B,v)) (s n k)’
         by METIS_TAC [pos_fn_integral_indicator] >> POP_ORW \\
      Know ‘!k. measure ((X,A,u) CROSS (Y,B,v)) (s n k) = m (s n k)’
      >- (rw [prod_measure_def]) >> Rewr' \\
   (* LHS simplification *)
      Know ‘pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u)
                     (\x. SIGMA (\k. &k / 2 pow n *
                                     indicator_fn (s n k) (x,y)) (count (4 ** n)))) =
            pos_fn_integral (Y,B,v)
              (\y. SIGMA (\k. pos_fn_integral (X,A,u)
                                (\x. &k / 2 pow n * indicator_fn (s n k) (x,y)))
                         (count (4 ** n)))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
          MATCH_MP_TAC ((BETA_RULE o
                         (Q.SPECL [‘(X,A,u)’,
                                   ‘\k x. &k / 2 pow n * indicator_fn (s n k) (x,y)’,
                                   ‘count (4 ** n)’]) o
                         (INST_TYPE [beta |-> “:num”])) pos_fn_integral_sum) >> simp [] \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          rpt STRIP_TAC \\
         ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
          qexistsl_tac [‘\x. indicator_fn (s n i) (x,y)’, ‘r’] >> rw []) >> Rewr' \\
      Know ‘pos_fn_integral (Y,B,v)
              (\y. SIGMA (\k. pos_fn_integral (X,A,u)
                                (\x. &k / 2 pow n * indicator_fn (s n k) (x,y)))
                         (count (4 ** n))) =
            SIGMA (\k. pos_fn_integral (Y,B,v)
                         (\y. pos_fn_integral (X,A,u)
                                (\x. &k / 2 pow n * indicator_fn (s n k) (x,y))))
                  (count (4 ** n))’
      >- (MATCH_MP_TAC ((BETA_RULE o
                         (Q.SPECL [‘(Y,B,v)’,
                                   ‘\k y. pos_fn_integral (X,A,u)
                                            (\x. &k / 2 pow n * indicator_fn (s n k) (x,y))’,
                                   ‘count (4 ** n)’]) o
                         (INST_TYPE [alpha |-> beta]) o
                         (INST_TYPE [beta |-> “:num”])) pos_fn_integral_sum) >> simp [] \\
          CONJ_TAC >- (GEN_TAC >> DISCH_TAC \\
                       Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          rpt STRIP_TAC \\
         ‘?r. 0 <= r /\ (&i / 2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, extreal_le_eq, extreal_of_num_def] >> POP_ORW \\
          MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                     (Q.SPEC ‘(Y,B,v)’ IN_MEASURABLE_BOREL_EQ)) \\
          BETA_TAC \\
          Q.EXISTS_TAC ‘\y. Normal r *
                            pos_fn_integral (X,A,u) (\x. indicator_fn (s n i) (x,y))’ \\
          reverse CONJ_TAC
          >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
              qexistsl_tac [‘\y. pos_fn_integral (X,A,u) (\x. indicator_fn (s n i) (x,y))’,
                            ‘r’] >> rw []) \\
          Q.X_GEN_TAC ‘y’ >> RW_TAC std_ss [] \\
          HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
      Suff ‘!k. pos_fn_integral (Y,B,v)
                  (\y. pos_fn_integral (X,A,u)
                         (\x. &k / 2 pow n * indicator_fn (s n k) (x,y))) =
                &k / 2 pow n * m (s n k)’ >- Rewr \\
      GEN_TAC \\
     ‘?r. 0 <= r /\ (&k / 2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, extreal_le_eq, extreal_of_num_def] >> POP_ORW \\
      Know ‘pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u)
                     (\x. Normal r * indicator_fn (s n k) (x,y))) =
            pos_fn_integral (Y,B,v)
              (\y. Normal r * pos_fn_integral (X,A,u) (\x. indicator_fn (s n k) (x,y)))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul \\
                       rw [INDICATOR_FN_POS, extreal_le_eq, extreal_of_num_def]) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_mul \\
                       CONJ_TAC >- rw [extreal_le_eq, extreal_of_num_def] \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS]) \\
          Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
          HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
      Know ‘pos_fn_integral (Y,B,v)
              (\y. Normal r * pos_fn_integral (X,A,u) (\x. indicator_fn (s n k) (x,y))) =
            Normal r * pos_fn_integral (Y,B,v)
                         (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (s n k) (x,y)))’
      >- (HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [] \\
          MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS]) >> Rewr' \\
      Suff ‘pos_fn_integral (Y,B,v)
              (\y. pos_fn_integral (X,A,u) (\x. indicator_fn (s n k) (x,y))) =
            m (s n k)’ >- Rewr \\
      METIS_TAC [],
      (* goal 6 (of 6), symmetric with goal 5 *)
      Know ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) f =
            pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\x. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n x) UNIV))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp []) >> Rewr' \\
      Know ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\x. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n x) UNIV)) =
            sup (IMAGE (\n. pos_fn_integral ((X,A,u) CROSS (Y,B,v))
                              (\z. fn_seq ((X,A,u) CROSS (Y,B,v)) f n z)) UNIV)’
      >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [] \\
          REWRITE_TAC [CONJ_ASSOC] (* easier goals first *) \\
          reverse CONJ_TAC (* mono_increasing *)
          >- (rpt STRIP_TAC >> MATCH_MP_TAC lemma_fn_seq_mono_increasing \\
              FIRST_X_ASSUM MATCH_MP_TAC >> art []) \\
          reverse CONJ_TAC (* positive *)
          >- (rpt STRIP_TAC >> MATCH_MP_TAC lemma_fn_seq_positive \\
              FIRST_X_ASSUM MATCH_MP_TAC >> art []) \\
          RW_TAC std_ss [fn_seq_def] \\
         ‘(X CROSS Y,subsets ((X,A) CROSS (Y,B))) = (X,A) CROSS (Y,B)’
            by METIS_TAC [SPACE] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_ADD \\
          ASM_SIMP_TAC std_ss [space_def] \\
          qexistsl_tac [‘\z. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) z) (count (4 ** n))’,
                        ‘\z. 2 pow n * indicator_fn (t n) z’] \\
          ASM_SIMP_TAC std_ss [CONJ_ASSOC] \\
          reverse CONJ_TAC (* nonnegative *)
          >- (Q.X_GEN_TAC ‘z’ >> DISCH_TAC >> DISJ1_TAC \\
              CONJ_TAC >> MATCH_MP_TAC pos_not_neginf >| (* 2 subgoals *)
              [ (* goal 5.1 (of 2) *)
                MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> rw [] \\
                MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS],
                (* goal 5.2 (of 2) *)
                MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le] ]) \\
          CONJ_TAC (* Borel_measurable #1 *)
          >- (MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] IN_MEASURABLE_BOREL_SUM) \\
              ASM_SIMP_TAC std_ss [space_def] \\
              qexistsl_tac [‘\k z. &k / 2 pow n * indicator_fn (s n k) z’,
                            ‘count (4 ** n)’] >> simp [] \\
              reverse CONJ_TAC
              >- (qx_genl_tac [‘i’, ‘z’] >> STRIP_TAC \\
                  MATCH_MP_TAC pos_not_neginf \\
                  MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
              rpt STRIP_TAC \\
             ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
              MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> rw []) \\
         ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
             by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
         ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> rw []) >> Rewr' \\
      Know ‘pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. f (x,y))) =
            pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v)
                     (\y. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)) UNIV)))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw []) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw []) \\
          Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
          MATCH_MP_TAC pos_fn_integral_cong >> simp []) >> Rewr' \\
      Know ‘pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v)
                     (\y. sup (IMAGE (\n. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)) UNIV))) =
            pos_fn_integral (X,A,u)
              (\x. sup (IMAGE (\n. pos_fn_integral (Y,B,v)
                                     (\y. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))) UNIV))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw []) \\
          CONJ_TAC
          >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
              rw [le_sup', IN_IMAGE, IN_UNIV] \\
              MATCH_MP_TAC le_trans \\
              Q.EXISTS_TAC ‘pos_fn_integral (Y,B,v)
                              (\y. fn_seq ((X,A,u) CROSS (Y,B,v)) f 0 (x,y))’ \\
              CONJ_TAC >- (MATCH_MP_TAC pos_fn_integral_pos >> rw [lemma_fn_seq_positive]) \\
              POP_ASSUM MATCH_MP_TAC >> Q.EXISTS_TAC ‘0’ >> REWRITE_TAC []) \\
          Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
          HO_MATCH_MP_TAC lebesgue_monotone_convergence \\
          simp [lemma_fn_seq_positive, lemma_fn_seq_mono_increasing]) >> Rewr' \\
      Know ‘pos_fn_integral (X,A,u)
              (\x. sup (IMAGE (\n. pos_fn_integral (Y,B,v)
                                     (\y. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))) UNIV)) =
            sup (IMAGE (\n. pos_fn_integral (X,A,u)
                              (\x. pos_fn_integral (Y,B,v)
                                     (\y. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y)))) UNIV)’
      >- (HO_MATCH_MP_TAC lebesgue_monotone_convergence >> simp [] \\
          CONJ_TAC >- (rpt STRIP_TAC >> MATCH_MP_TAC pos_fn_integral_pos \\
                       simp [lemma_fn_seq_positive]) \\
          RW_TAC std_ss [ext_mono_increasing_def] \\
          MATCH_MP_TAC pos_fn_integral_mono >> simp [lemma_fn_seq_positive] \\
          rpt STRIP_TAC \\
          irule (SIMP_RULE std_ss [ext_mono_increasing_def]
                                  lemma_fn_seq_mono_increasing) >> art [] \\
          FIRST_X_ASSUM MATCH_MP_TAC >> rw []) >> Rewr' \\
      Suff ‘!n. pos_fn_integral (X,A,u)
                  (\x. pos_fn_integral (Y,B,v) (\y. fn_seq ((X,A,u) CROSS (Y,B,v)) f n (x,y))) =
                pos_fn_integral ((X,A,u) CROSS (Y,B,v))
                  (\z. fn_seq ((X,A,u) CROSS (Y,B,v)) f n z)’ >- rw [] \\
   (* ‘sup’ disappeared now *)
      GEN_TAC >> ASM_SIMP_TAC std_ss [fn_seq_def] \\
     ‘!k. {x | x IN X CROSS Y /\ &k / 2 pow n <= f x /\ f x < (&k + 1) / 2 pow n} = s n k’
         by METIS_TAC [] >> POP_ORW \\
   (* RHS simplification *)
      Know ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\z. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) z) (count (4 ** n)) +
                   2 pow n * indicator_fn (t n) z) =
            pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\z. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) z) (count (4 ** n))) +
            pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\z. 2 pow n * indicator_fn (t n) z)’
      >- (HO_MATCH_MP_TAC pos_fn_integral_add >> simp [] \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
         ‘(X CROSS Y,subsets ((X,A) CROSS (Y,B))) = (X,A) CROSS (Y,B)’
            by METIS_TAC [SPACE] >> POP_ORW \\
          reverse CONJ_TAC
          >- (‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
                 by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
              ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
              MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> rw []) \\
          MATCH_MP_TAC ((INST_TYPE [alpha |-> “:'a # 'b”] o
                         INST_TYPE [beta |-> “:num”]) IN_MEASURABLE_BOREL_SUM) >> simp [] \\
          qexistsl_tac [‘\k z. &k / 2 pow n * indicator_fn (s n k) z’,
                        ‘count (4 ** n)’] >> simp [] \\
          reverse CONJ_TAC >- (qx_genl_tac [‘i’, ‘z’] >> STRIP_TAC \\
                               MATCH_MP_TAC pos_not_neginf \\
                               MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          rpt STRIP_TAC \\
         ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> rw []) >> Rewr' \\
   (* LHS simplification *)
      Know ‘pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v)
                     (\y. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y)) (count (4 ** n)) +
                          2 pow n * indicator_fn (t n) (x,y))) =
            pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v)
                     (\y. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y)) (count (4 ** n))) +
                   pos_fn_integral (Y,B,v)
                     (\y. 2 pow n * indicator_fn (t n) (x,y)))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_add \\
                       reverse CONJ_TAC
                       >- (MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_add \\
                       reverse CONJ_TAC
                       >- (MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                           MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
          Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
          HO_MATCH_MP_TAC pos_fn_integral_add >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
          reverse CONJ_TAC
          >- (‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
                 by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
              ‘?r. 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
              MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
              qexistsl_tac [‘\y. indicator_fn (t n) (x,y)’, ‘r’] >> rw []) \\
          MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] IN_MEASURABLE_BOREL_SUM) >> simp [] \\
          qexistsl_tac [‘\k y. &k / 2 pow n * indicator_fn (s n k) (x,y)’,
                        ‘count (4 ** n)’] >> simp [] \\
          reverse CONJ_TAC >- (rpt GEN_TAC >> STRIP_TAC \\
                               MATCH_MP_TAC pos_not_neginf \\
                               MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          rpt STRIP_TAC \\
         ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
          qexistsl_tac [‘\y. indicator_fn (s n i) (x,y)’, ‘r’] >> rw []) >> Rewr' \\
   (* LHS simplification *)
      Know ‘pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v)
                     (\y. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y))
                                (count (4 ** n))) +
                   pos_fn_integral (Y,B,v) (\y. 2 pow n * indicator_fn (t n) (x,y))) =
            pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v)
                     (\y. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) (x,y))
                                (count (4 ** n)))) +
            pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v) (\y. 2 pow n * indicator_fn (t n) (x,y)))’
      >- (HO_MATCH_MP_TAC pos_fn_integral_add >> simp [] \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
          reverse CONJ_TAC
          >- (‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
                 by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
              ‘?r. 0 <= r /\ (2 pow n = Normal r)’
                 by METIS_TAC [extreal_cases, pow_pos_le, extreal_le_eq,
                               extreal_of_num_def, le_02] >> POP_ORW \\
              MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                         (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) \\
              BETA_TAC \\
              Q.EXISTS_TAC ‘\x. Normal r *
                                pos_fn_integral (Y,B,v) (\y. indicator_fn (t n) (x,y))’ \\
              reverse CONJ_TAC
              >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
                  qexistsl_tac [‘\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (t n) (x,y))’,
                                ‘r’] >> rw []) \\
              Q.X_GEN_TAC ‘x’ >> RW_TAC std_ss [] \\
              HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) \\
          MATCH_MP_TAC (INST_TYPE [beta |-> “:num”] IN_MEASURABLE_BOREL_SUM) \\
          ASM_SIMP_TAC std_ss [space_def] \\
          qexistsl_tac [‘\k x. pos_fn_integral (Y,B,v)
                                 (\y. &k / 2 pow n * indicator_fn (s n k) (x,y))’,
                        ‘count (4 ** n)’] >> simp [] \\
          CONJ_TAC
          >- (rpt STRIP_TAC \\
             ‘?r. 0 <= r /\ (&i / 2 pow n = Normal r)’
                 by METIS_TAC [extreal_cases, extreal_le_eq, extreal_of_num_def] >> POP_ORW \\
              MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                         (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) \\
              BETA_TAC \\
              Q.EXISTS_TAC ‘\x. Normal r *
                                pos_fn_integral (Y,B,v) (\y. indicator_fn (s n i) (x,y))’ \\
              simp [] \\
              reverse CONJ_TAC
              >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
                  qexistsl_tac [‘\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (s n i) (x,y))’,
                                ‘r’] >> rw []) \\
              Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
              HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (qx_genl_tac [‘i’, ‘x’] >> STRIP_TAC \\
                       MATCH_MP_TAC pos_not_neginf \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
          MATCH_MP_TAC ((BETA_RULE o
                         (Q.SPECL [‘(Y,B,v)’,
                                   ‘\k y. &k / 2 pow n * indicator_fn (s n k) (x,y)’,
                                   ‘count (4 ** n)’]) o
                         (INST_TYPE [alpha |-> beta]) o
                         (INST_TYPE [beta |-> “:num”])) pos_fn_integral_sum) >> simp [] \\
          CONJ_TAC >- (GEN_TAC >> DISCH_TAC \\
                       Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          GEN_TAC >> DISCH_TAC \\
         ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL \\
          ASM_SIMP_TAC std_ss [space_def] \\
          qexistsl_tac [‘\y. indicator_fn (s n i) (x,y)’, ‘r’] >> rw []) >> Rewr' \\
   (* LHS simplification *)
      Know ‘pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v) (\y. 2 pow n * indicator_fn (t n) (x,y))) =
            pos_fn_integral (X,A,u)
              (\x. 2 pow n * pos_fn_integral (Y,B,v) (\y. indicator_fn (t n) (x,y)))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS, pow_pos_le]) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_mul >> rw [pow_pos_le] \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS]) \\
          Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
         ‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
             by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
         ‘?r. 0 <= r /\ (2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, pow_pos_le, extreal_le_eq,
                           extreal_of_num_def, le_02] >> POP_ORW \\
          HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
      Know ‘pos_fn_integral (X,A,u)
              (\x. 2 pow n * pos_fn_integral (Y,B,v) (\y. indicator_fn (t n) (x,y))) =
            2 pow n * pos_fn_integral (X,A,u)
                        (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (t n) (x,y)))’
      >- (‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
             by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
          ‘?r. 0 <= r /\ (2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, pow_pos_le, extreal_le_eq,
                           extreal_of_num_def, le_02] >> POP_ORW \\
          HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [] \\
          MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS]) >> Rewr' \\
     ‘pos_fn_integral (X,A,u)
        (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (t n) (x,y))) = m (t n)’
         by METIS_TAC [] >> POP_ORW \\
      Know ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (\z. 2 pow n * indicator_fn (t n) z) =
            2 pow n * pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (indicator_fn (t n))’
      >- (‘2 pow n <> PosInf /\ 2 pow n <> NegInf’
             by METIS_TAC [pow_not_infty, extreal_of_num_def, extreal_not_infty] \\
          ‘?r. 0 <= r /\ (2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, pow_pos_le, extreal_le_eq,
                           extreal_of_num_def, le_02] >> POP_ORW \\
          HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
     ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (indicator_fn (t n)) =
      measure ((X,A,u) CROSS (Y,B,v)) (t n)’
         by METIS_TAC [pos_fn_integral_indicator] >> POP_ORW \\
      Know ‘measure ((X,A,u) CROSS (Y,B,v)) (t n) = m (t n)’
      >- (rw [prod_measure_def]) >> Rewr' \\
   (* stage work *)
      Suff ‘pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v)
                     (\y. SIGMA (\k. &k / 2 pow n *
                                     indicator_fn (s n k) (x,y)) (count (4 ** n)))) =
            pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\z. SIGMA (\k. &k / 2 pow n *
                              indicator_fn (s n k) z) (count (4 ** n)))’ >- Rewr \\
   (* RHS simplification *)
      Know ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v))
              (\z. SIGMA (\k. &k / 2 pow n * indicator_fn (s n k) z) (count (4 ** n))) =
            SIGMA (\k. pos_fn_integral ((X,A,u) CROSS (Y,B,v))
                         (\z. &k / 2 pow n * indicator_fn (s n k) z)) (count (4 ** n))’
      >- (MATCH_MP_TAC ((BETA_RULE o
                         (Q.SPECL [‘(X,A,u) CROSS (Y,B,v)’,
                                   ‘\k z. &k / 2 pow n * indicator_fn (s n k) z’,
                                   ‘count (4 ** n)’]) o
                         (INST_TYPE [alpha |-> “:'a # 'b”]) o
                         (INST_TYPE [beta |-> “:num”])) pos_fn_integral_sum) >> simp [] \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          rpt STRIP_TAC \\
         ‘(X CROSS Y,subsets ((X,A) CROSS (Y,B))) = (X,A) CROSS (Y,B)’
            by METIS_TAC [SPACE] >> POP_ORW \\
         ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL_INDICATOR >> rw []) >> Rewr' \\
      Know ‘!k. pos_fn_integral ((X,A,u) CROSS (Y,B,v))
                  (\z. &k / 2 pow n * indicator_fn (s n k) z) =
                &k / 2 pow n *
                pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (indicator_fn (s n k))’
      >- (GEN_TAC \\
         ‘?r. 0 <= r /\ (&k / 2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, extreal_le_eq, extreal_of_num_def] >> POP_ORW \\
          MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
     ‘!k. pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (indicator_fn (s n k)) =
          measure ((X,A,u) CROSS (Y,B,v)) (s n k)’
         by METIS_TAC [pos_fn_integral_indicator] >> POP_ORW \\
      Know ‘!k. measure ((X,A,u) CROSS (Y,B,v)) (s n k) = m (s n k)’
      >- (rw [prod_measure_def]) >> Rewr' \\
   (* LHS simplification *)
      Know ‘pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v)
                     (\y. SIGMA (\k. &k / 2 pow n *
                                     indicator_fn (s n k) (x,y)) (count (4 ** n)))) =
            pos_fn_integral (X,A,u)
              (\x. SIGMA (\k. pos_fn_integral (Y,B,v)
                                (\y. &k / 2 pow n * indicator_fn (s n k) (x,y)))
                         (count (4 ** n)))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC EXTREAL_SUM_IMAGE_POS >> REWRITE_TAC [FINITE_COUNT] \\
                       Q.X_GEN_TAC ‘i’ >> rw [] \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
          MATCH_MP_TAC ((BETA_RULE o
                         (Q.SPECL [‘(Y,B,v)’,
                                   ‘\k y. &k / 2 pow n * indicator_fn (s n k) (x,y)’,
                                   ‘count (4 ** n)’]) o
                         (INST_TYPE [alpha |-> beta]) o
                         (INST_TYPE [beta |-> “:num”])) pos_fn_integral_sum) >> simp [] \\
          CONJ_TAC >- (rpt STRIP_TAC \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          rpt STRIP_TAC \\
         ‘?r. &i / 2 pow n = Normal r’ by METIS_TAC [extreal_cases] >> POP_ORW \\
          MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
          qexistsl_tac [‘\y. indicator_fn (s n i) (x,y)’, ‘r’] >> rw []) >> Rewr' \\
      Know ‘pos_fn_integral (X,A,u)
              (\x. SIGMA (\k. pos_fn_integral (Y,B,v)
                                (\y. &k / 2 pow n * indicator_fn (s n k) (x,y)))
                         (count (4 ** n))) =
            SIGMA (\k. pos_fn_integral (X,A,u)
                         (\x. pos_fn_integral (Y,B,v)
                                (\y. &k / 2 pow n * indicator_fn (s n k) (x,y))))
                  (count (4 ** n))’
      >- (MATCH_MP_TAC ((BETA_RULE o
                         (Q.SPECL [‘(X,A,u)’,
                                   ‘\k x. pos_fn_integral (Y,B,v)
                                            (\y. &k / 2 pow n * indicator_fn (s n k) (x,y))’,
                                   ‘count (4 ** n)’]) o
                         (INST_TYPE [beta |-> “:num”])) pos_fn_integral_sum) >> simp [] \\
          CONJ_TAC >- (GEN_TAC >> DISCH_TAC \\
                       Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
                       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS]) \\
          rpt STRIP_TAC \\
         ‘?r. 0 <= r /\ (&i / 2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, extreal_le_eq, extreal_of_num_def] >> POP_ORW \\
          MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                     (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) \\
          BETA_TAC \\
          Q.EXISTS_TAC ‘\x. Normal r *
                            pos_fn_integral (Y,B,v) (\y. indicator_fn (s n i) (x,y))’ \\
          reverse CONJ_TAC
          >- (MATCH_MP_TAC IN_MEASURABLE_BOREL_CMUL >> simp [] \\
              qexistsl_tac [‘\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (s n i) (x,y))’,
                            ‘r’] >> rw []) \\
          Q.X_GEN_TAC ‘x’ >> RW_TAC std_ss [] \\
          HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
      Suff ‘!k. pos_fn_integral (X,A,u)
                  (\x. pos_fn_integral (Y,B,v)
                         (\y. &k / 2 pow n * indicator_fn (s n k) (x,y))) =
                &k / 2 pow n * m (s n k)’ >- Rewr \\
      GEN_TAC \\
     ‘?r. 0 <= r /\ (&k / 2 pow n = Normal r)’
             by METIS_TAC [extreal_cases, extreal_le_eq, extreal_of_num_def] >> POP_ORW \\
      Know ‘pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v)
                     (\y. Normal r * indicator_fn (s n k) (x,y))) =
            pos_fn_integral (X,A,u)
              (\x. Normal r * pos_fn_integral (Y,B,v) (\y. indicator_fn (s n k) (x,y)))’
      >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC pos_fn_integral_pos >> simp [] \\
                       Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_mul \\
                       rw [INDICATOR_FN_POS, extreal_le_eq, extreal_of_num_def]) \\
          CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                       MATCH_MP_TAC le_mul \\
                       CONJ_TAC >- rw [extreal_le_eq, extreal_of_num_def] \\
                       MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS]) \\
          Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
          HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [INDICATOR_FN_POS]) >> Rewr' \\
      Know ‘pos_fn_integral (X,A,u)
              (\x. Normal r * pos_fn_integral (Y,B,v) (\y. indicator_fn (s n k) (x,y))) =
            Normal r * pos_fn_integral (X,A,u)
                         (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (s n k) (x,y)))’
      >- (HO_MATCH_MP_TAC pos_fn_integral_cmul >> rw [] \\
          MATCH_MP_TAC pos_fn_integral_pos >> rw [INDICATOR_FN_POS]) >> Rewr' \\
      Suff ‘pos_fn_integral (X,A,u)
              (\x. pos_fn_integral (Y,B,v) (\y. indicator_fn (s n k) (x,y))) =
            m (s n k)’ >- Rewr \\
      METIS_TAC [] ]
QED

(* Corollary 14.9 (Fubini's theorem) [1, p.142]

   Named after Guido Fubini, an Italian mathematician [6].
 *)
Theorem FUBINI :
    !(X :'a set) (Y :'b set) A B u v f.
        sigma_finite_measure_space (X,A,u) /\
        sigma_finite_measure_space (Y,B,v) /\
        f IN measurable ((X,A) CROSS (Y,B)) Borel /\
     (* if at least one of the three integrals is finite (P \/ Q \/ R) *)
       (pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (abs o f) <> PosInf \/
        pos_fn_integral (Y,B,v)
          (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y))) <> PosInf \/
        pos_fn_integral (X,A,u)
          (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y))) <> PosInf)
       ==>
     (* then all three integrals are finite (P /\ Q /\ R) *)
        pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (abs o f) <> PosInf /\
        pos_fn_integral (Y,B,v)
          (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y))) <> PosInf /\
        pos_fn_integral (X,A,u)
          (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y))) <> PosInf /\
        integrable ((X,A,u) CROSS (Y,B,v)) f /\
       (AE y::(Y,B,v). integrable (X,A,u) (\x. f (x,y))) /\
       (AE x::(X,A,u). integrable (Y,B,v) (\y. f (x,y))) /\
        integrable (X,A,u) (\x. integral (Y,B,v) (\y. f (x,y))) /\
        integrable (Y,B,v) (\y. integral (X,A,u) (\x. f (x,y))) /\
       (integral ((X,A,u) CROSS (Y,B,v)) f =
        integral (Y,B,v) (\y. integral (X,A,u) (\x. f (x,y)))) /\
       (integral ((X,A,u) CROSS (Y,B,v)) f =
        integral (X,A,u) (\x. integral (Y,B,v) (\y. f (x,y))))
Proof
    rpt GEN_TAC
 (* prevent from separating ‘P \/ Q \/ R’ *)
 >> ONCE_REWRITE_TAC [DECIDE “(A /\ B /\ C /\ D ==> E) <=>
                              (A ==> B ==> C ==> D ==> E)”]
 >> rpt DISCH_TAC
 >> ‘measure_space ((X,A,u) CROSS (Y,B,v))’
      by PROVE_TAC [measure_space_prod_measure]
 >> ‘sigma_algebra ((X,A) CROSS (Y,B))’
      by (MATCH_MP_TAC SIGMA_ALGEBRA_PROD_SIGMA \\
          fs [sigma_algebra_def, algebra_def, sigma_finite_measure_space_def,
              measure_space_def])
 >> ‘(abs o f) IN Borel_measurable ((X,A) CROSS (Y,B))’
      by (MATCH_MP_TAC IN_MEASURABLE_BOREL_ABS' >> art [])
 >> ‘!s. s IN X CROSS Y ==> 0 <= (abs o f) s’ by rw [o_DEF, abs_pos]
 (* applying TONELLI on ‘abs o f’ *)
 >> Know ‘(!y. y IN Y ==> (\x. (abs o f) (x,y)) IN Borel_measurable (X,A)) /\
          (!x. x IN X ==> (\y. (abs o f) (x,y)) IN Borel_measurable (Y,B)) /\
          (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y))) IN Borel_measurable (X,A) /\
          (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y))) IN Borel_measurable (Y,B) /\
          pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (abs o f) =
          pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y))) /\
          pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (abs o f) =
          pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y)))’
 >- (MATCH_MP_TAC (Q.SPECL [‘X’, ‘Y’, ‘A’, ‘B’, ‘u’, ‘v’, ‘abs o f’] TONELLI) \\
     rw []) >> STRIP_TAC
 >> Q.PAT_X_ASSUM ‘!s. s IN X CROSS Y ==> 0 <= (abs o f) s’ K_TAC
 (* group the first subgoals together *)
 >> NTAC 2 (ONCE_REWRITE_TAC [CONJ_ASSOC])
 >> STRONG_CONJ_TAC >- METIS_TAC []
 (* replace one of three finite integrals by all finite integrals *)
 >> Q.PAT_X_ASSUM ‘P \/ Q \/ R’ K_TAC
 >> STRIP_TAC (* P /\ Q /\ R *)
 >> Know ‘space ((X,A) CROSS (Y,B)) = X CROSS Y’
 >- (rw [prod_sigma_def] >> REWRITE_TAC [SPACE_SIGMA]) >> DISCH_TAC
 >> ‘m_space ((X,A,u) CROSS (Y,B,v)) = X CROSS Y’ by rw [prod_measure_def]
 >> ‘measurable_sets ((X,A,u) CROSS (Y,B,v)) =
       subsets ((X,A) CROSS (Y,B))’ by rw [prod_measure_def]
 >> ‘(X CROSS Y,subsets ((X,A) CROSS (Y,B))) = (X,A) CROSS (Y,B)’
       by METIS_TAC [SPACE]
 >> STRONG_CONJ_TAC
 >- (MATCH_MP_TAC integrable_from_abs >> simp [integrable_def] \\
     ASM_SIMP_TAC bool_ss [FN_PLUS_ABS_SELF, FN_MINUS_ABS_ZERO, pos_fn_integral_zero] \\
     rw [] (* 0 <> PosInf *)) >> DISCH_TAC
 (* applying TONELLI again on both f^+ and f^- *)
 >> ‘(fn_plus f) IN measurable ((X,A) CROSS (Y,B)) Borel’
      by PROVE_TAC [IN_MEASURABLE_BOREL_FN_PLUS]
 >> ‘!s. s IN X CROSS Y ==> 0 <= (fn_plus f) s’ by rw [FN_PLUS_POS]
 >> Know ‘(!y. y IN Y ==> (\x. (fn_plus f) (x,y)) IN Borel_measurable (X,A)) /\
          (!x. x IN X ==> (\y. (fn_plus f) (x,y)) IN Borel_measurable (Y,B)) /\
          (\x. pos_fn_integral (Y,B,v) (\y. (fn_plus f) (x,y))) IN Borel_measurable (X,A) /\
          (\y. pos_fn_integral (X,A,u) (\x. (fn_plus f) (x,y))) IN Borel_measurable (Y,B) /\
          pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_plus f) =
          pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. (fn_plus f) (x,y))) /\
          pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_plus f) =
          pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. (fn_plus f) (x,y)))’
 >- (MATCH_MP_TAC (Q.SPECL [‘X’, ‘Y’, ‘A’, ‘B’, ‘u’, ‘v’, ‘fn_plus f’] TONELLI) \\
     rw []) >> STRIP_TAC
 >> Q.PAT_X_ASSUM ‘!s. s IN X CROSS Y ==> 0 <= (fn_plus f) s’ K_TAC
 >> ‘(fn_minus f) IN measurable ((X,A) CROSS (Y,B)) Borel’
      by PROVE_TAC [IN_MEASURABLE_BOREL_FN_MINUS]
 >> ‘!s. s IN X CROSS Y ==> 0 <= (fn_minus f) s’ by rw [FN_MINUS_POS]
 >> Know ‘(!y. y IN Y ==> (\x. (fn_minus f) (x,y)) IN Borel_measurable (X,A)) /\
          (!x. x IN X ==> (\y. (fn_minus f) (x,y)) IN Borel_measurable (Y,B)) /\
          (\x. pos_fn_integral (Y,B,v) (\y. (fn_minus f) (x,y))) IN Borel_measurable (X,A) /\
          (\y. pos_fn_integral (X,A,u) (\x. (fn_minus f) (x,y))) IN Borel_measurable (Y,B) /\
          pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_minus f) =
          pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. (fn_minus f) (x,y))) /\
          pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_minus f) =
          pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. (fn_minus f) (x,y)))’
 >- (MATCH_MP_TAC (Q.SPECL [‘X’, ‘Y’, ‘A’, ‘B’, ‘u’, ‘v’, ‘fn_minus f’] TONELLI) \\
     rw []) >> STRIP_TAC
 >> Q.PAT_X_ASSUM ‘!s. s IN X CROSS Y ==> 0 <= (fn_minus f) s’ K_TAC
 >> Q.PAT_X_ASSUM ‘sigma_finite_measure_space (X,A,u)’
      (STRIP_ASSUME_TAC o (REWRITE_RULE [sigma_finite_measure_space_def]))
 >> Q.PAT_X_ASSUM ‘sigma_finite_measure_space (Y,B,v)’
      (STRIP_ASSUME_TAC o (REWRITE_RULE [sigma_finite_measure_space_def]))
 (* some shared properties *)
 >> Know ‘pos_fn_integral (Y,B,v)
            (\y. pos_fn_integral (X,A,u) (\x. (fn_plus f) (x,y))) <> PosInf’
 >- (REWRITE_TAC [lt_infty] \\
     MATCH_MP_TAC let_trans \\
     Q.EXISTS_TAC ‘pos_fn_integral (Y,B,v)
                     (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y)))’ \\
     reverse CONJ_TAC >- PROVE_TAC [lt_infty] \\
     Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_plus f) =
                    pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. (fn_plus f) (x,y)))’
       (ONCE_REWRITE_TAC o wrap o SYM) \\
     Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (abs o f) =
                    pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y)))’
       (ONCE_REWRITE_TAC o wrap o SYM) \\
     MATCH_MP_TAC pos_fn_integral_mono \\
     rw [FN_PLUS_POS, FN_PLUS_LE_ABS]) >> DISCH_TAC
 >> Know ‘pos_fn_integral (X,A,u)
            (\x. pos_fn_integral (Y,B,v) (\y. (fn_plus f) (x,y))) <> PosInf’
 >- (REWRITE_TAC [lt_infty] \\
     MATCH_MP_TAC let_trans \\
     Q.EXISTS_TAC ‘pos_fn_integral (X,A,u)
                     (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y)))’ \\
     reverse CONJ_TAC >- PROVE_TAC [lt_infty] \\
     Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_plus f) =
                    pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. (fn_plus f) (x,y)))’
       (ONCE_REWRITE_TAC o wrap o SYM) \\
     Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (abs o f) =
                    pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y)))’
       (ONCE_REWRITE_TAC o wrap o SYM) \\
     MATCH_MP_TAC pos_fn_integral_mono \\
     rw [FN_PLUS_POS, FN_PLUS_LE_ABS]) >> DISCH_TAC
 >> Know ‘pos_fn_integral (Y,B,v)
            (\y. pos_fn_integral (X,A,u) (\x. (fn_minus f) (x,y))) <> PosInf’
 >- (REWRITE_TAC [lt_infty] \\
     MATCH_MP_TAC let_trans \\
     Q.EXISTS_TAC ‘pos_fn_integral (Y,B,v)
                     (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y)))’ \\
     reverse CONJ_TAC >- PROVE_TAC [lt_infty] \\
     Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_minus f) =
                    pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. (fn_minus f) (x,y)))’
       (ONCE_REWRITE_TAC o wrap o SYM) \\
     Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (abs o f) =
                    pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y)))’
       (ONCE_REWRITE_TAC o wrap o SYM) \\
     MATCH_MP_TAC pos_fn_integral_mono \\
     rw [FN_MINUS_POS, FN_MINUS_LE_ABS]) >> DISCH_TAC
 >> Know ‘pos_fn_integral (X,A,u)
            (\x. pos_fn_integral (Y,B,v) (\y. (fn_minus f) (x,y))) <> PosInf’
 >- (REWRITE_TAC [lt_infty] \\
     MATCH_MP_TAC let_trans \\
     Q.EXISTS_TAC ‘pos_fn_integral (X,A,u)
                     (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y)))’ \\
     reverse CONJ_TAC >- PROVE_TAC [lt_infty] \\
     Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_minus f) =
                    pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. (fn_minus f) (x,y)))’
       (ONCE_REWRITE_TAC o wrap o SYM) \\
     Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (abs o f) =
                    pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y)))’
       (ONCE_REWRITE_TAC o wrap o SYM) \\
     MATCH_MP_TAC pos_fn_integral_mono \\
     rw [FN_MINUS_POS, FN_MINUS_LE_ABS]) >> DISCH_TAC
 (* clean up useless assumptions *)
 >> Q.PAT_X_ASSUM ‘sigma_finite (X,A,u)’ K_TAC
 >> Q.PAT_X_ASSUM ‘sigma_finite (Y,B,v)’ K_TAC
 (* push ‘fn_plus/fn_minus’ inside *)
 >> ‘!y. fn_plus (\x. f (x,y)) = (\x. (fn_plus f) (x,y))’   by rw [FUN_EQ_THM, FN_PLUS_ALT]
 >> ‘!y. fn_minus (\x. f (x,y)) = (\x. (fn_minus f) (x,y))’ by rw [FUN_EQ_THM, FN_MINUS_ALT]
 >> ‘!x. fn_plus (\y. f (x,y)) = (\y. (fn_plus f) (x,y))’   by rw [FUN_EQ_THM, FN_PLUS_ALT]
 >> ‘!x. fn_minus (\y. f (x,y)) = (\y. (fn_minus f) (x,y))’ by rw [FUN_EQ_THM, FN_MINUS_ALT]
 (* goal: AE y::(Y,B,v). integrable (X,A,u) (\x. f (x,y)) *)
 >> STRONG_CONJ_TAC
 >- (rw [Once FN_DECOMP, integrable_def] \\
  (* applying pos_fn_integral_infty_null *)
     Know ‘null_set (Y,B,v) {y | y IN m_space (Y,B,v) /\
                                 ((\y. pos_fn_integral (X,A,u) (\x. (fn_plus f) (x,y))) y = PosInf)}’
     >- (MATCH_MP_TAC pos_fn_integral_infty_null >> simp [] \\
         Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
         MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_PLUS_POS]) \\
     simp [] >> DISCH_TAC \\
     Know ‘null_set (Y,B,v) {y | y IN m_space (Y,B,v) /\
                                 ((\y. pos_fn_integral (X,A,u) (\x. (fn_minus f) (x,y))) y = PosInf)}’
     >- (MATCH_MP_TAC pos_fn_integral_infty_null >> simp [] \\
         Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
         MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_MINUS_POS]) \\
     simp [] >> DISCH_TAC \\
     rw [AE_DEF] \\
     Q.EXISTS_TAC ‘{y | y IN Y /\ pos_fn_integral (X,A,u) (\x. (fn_plus f) (x,y)) = PosInf} UNION
                   {y | y IN Y /\ pos_fn_integral (X,A,u) (\x. (fn_minus f) (x,y)) = PosInf}’ \\
     CONJ_TAC >- (PROVE_TAC [NULL_SET_UNION, GSYM IN_NULL_SET]) \\
     Q.X_GEN_TAC ‘y’ >> rw [] >| (* 3 subgoals *)
     [ (* goal 1 (of 3) *)
      ‘!x. (fn_plus f) (x,y) - (fn_minus f) (x,y) = f (x,y)’
          by METIS_TAC [FN_DECOMP] >> POP_ORW \\
       simp [Once IN_MEASURABLE_BOREL_PLUS_MINUS],
       (* goal 2 (of 3) *)
       CCONTR_TAC >> FULL_SIMP_TAC std_ss [],
       (* goal 3 (of 3) *)
       CCONTR_TAC >> FULL_SIMP_TAC std_ss [] ]) >> DISCH_TAC
 (* goal: AE x::(X,A,u). integrable (Y,B,v) (\y. f (x,y)) *)
 >> STRONG_CONJ_TAC
 >- (rw [Once FN_DECOMP, integrable_def] \\
  (* applying pos_fn_integral_infty_null *)
     Know ‘null_set (X,A,u) {x | x IN m_space (X,A,u) /\
                                 ((\x. pos_fn_integral (Y,B,v) (\y. (fn_plus f) (x,y))) x = PosInf)}’
     >- (MATCH_MP_TAC pos_fn_integral_infty_null >> simp [] \\
         Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
         MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_PLUS_POS]) \\
     simp [] >> DISCH_TAC \\
     Know ‘null_set (X,A,u) {x | x IN m_space (X,A,u) /\
                                 ((\x. pos_fn_integral (Y,B,v) (\y. (fn_minus f) (x,y))) x = PosInf)}’
     >- (MATCH_MP_TAC pos_fn_integral_infty_null >> simp [] \\
         Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
         MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_MINUS_POS]) \\
     simp [] >> DISCH_TAC \\
     rw [AE_DEF] \\
     Q.EXISTS_TAC ‘{x | x IN X /\ pos_fn_integral (Y,B,v) (\y. (fn_plus f) (x,y)) = PosInf} UNION
                   {x | x IN X /\ pos_fn_integral (Y,B,v) (\y. (fn_minus f) (x,y)) = PosInf}’ \\
     CONJ_TAC >- (PROVE_TAC [NULL_SET_UNION, GSYM IN_NULL_SET]) \\
     Q.X_GEN_TAC ‘x’ >> rw [] >| (* 3 subgoals *)
     [ (* goal 1 (of 3) *)
      ‘!y. (fn_plus f) (x,y) - (fn_minus f) (x,y) = f (x,y)’
          by METIS_TAC [FN_DECOMP] >> POP_ORW \\
       simp [Once IN_MEASURABLE_BOREL_PLUS_MINUS],
       (* goal 2 (of 3) *)
       CCONTR_TAC >> FULL_SIMP_TAC std_ss [],
       (* goal 3 (of 3) *)
       CCONTR_TAC >> FULL_SIMP_TAC std_ss [] ]) >> DISCH_TAC
 (* goal: integrable (X,A,u) (\x. integral (Y,B,v) (\y. f (x,y))) *)
 >> STRONG_CONJ_TAC
 >- (rw [integrable_def] >| (* 3 subgoals *)
     [ (* goal 1 (of 3) *)
       MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                  (Q.SPEC ‘(X,A,u)’ IN_MEASURABLE_BOREL_EQ)) \\
       Q.EXISTS_TAC ‘\x. pos_fn_integral (Y,B,v) (\y. fn_plus f (x,y)) -
                         pos_fn_integral (Y,B,v) (\y. fn_minus f (x,y))’ >> BETA_TAC \\
       CONJ_TAC >- RW_TAC std_ss [integral_def] \\
       MATCH_MP_TAC IN_MEASURABLE_BOREL_SUB' \\
       FULL_SIMP_TAC std_ss [measure_space_def, space_def, m_space_def, measurable_sets_def] \\
       qexistsl_tac [‘\x. pos_fn_integral (Y,B,v) (\y. fn_plus f (x,y))’,
                     ‘\x. pos_fn_integral (Y,B,v) (\y. fn_minus f (x,y))’] \\
       simp [],
       (* goal 2 (of 3) *)
       REWRITE_TAC [lt_infty] >> MATCH_MP_TAC let_trans \\
       Q.EXISTS_TAC ‘pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y)))’ \\
       reverse CONJ_TAC >- art [GSYM lt_infty] \\
       MATCH_MP_TAC pos_fn_integral_mono_AE >> rw [FN_PLUS_POS]
       >- (MATCH_MP_TAC pos_fn_integral_pos >> rw [abs_pos]) \\
       Q.PAT_X_ASSUM ‘AE x::(X,A,u). integrable (Y,B,v) (\y. f (x,y))’ MP_TAC \\
       rw [AE_DEF] \\
       Q.EXISTS_TAC ‘N’ >> rw [] \\
       MATCH_MP_TAC le_trans \\
       Q.EXISTS_TAC ‘abs ((\x. integral (Y,B,v) (\y. f (x,y))) x)’ \\
       CONJ_TAC >- REWRITE_TAC [FN_PLUS_LE_ABS] >> BETA_TAC \\
       MP_TAC (Q.SPECL [‘(Y,B,v)’, ‘(\y. f (x,y))’]
                       (INST_TYPE [alpha |-> beta] integral_triangle_ineq')) \\
       simp [o_DEF],
       (* goal 3 (of 3) *)
       REWRITE_TAC [lt_infty] >> MATCH_MP_TAC let_trans \\
       Q.EXISTS_TAC ‘pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y)))’ \\
       reverse CONJ_TAC >- art [GSYM lt_infty] \\
       MATCH_MP_TAC pos_fn_integral_mono_AE >> rw [FN_MINUS_POS]
       >- (MATCH_MP_TAC pos_fn_integral_pos >> rw [abs_pos]) \\
       Q.PAT_X_ASSUM ‘AE x::(X,A,u). integrable (Y,B,v) (\y. f (x,y))’ MP_TAC \\
       rw [AE_DEF] \\
       Q.EXISTS_TAC ‘N’ >> rw [] \\
       MATCH_MP_TAC le_trans \\
       Q.EXISTS_TAC ‘abs ((\x. integral (Y,B,v) (\y. f (x,y))) x)’ \\
       CONJ_TAC >- REWRITE_TAC [FN_MINUS_LE_ABS] >> BETA_TAC \\
       MP_TAC (Q.SPECL [‘(Y,B,v)’, ‘(\y. f (x,y))’]
                       (INST_TYPE [alpha |-> beta] integral_triangle_ineq')) \\
       simp [o_DEF] ])
 >> DISCH_TAC
 (* goal: integrable (Y,B,v) (\y. integral (X,A,u) (\y. f (x,y))) *)
 >> STRONG_CONJ_TAC
 >- (rw [integrable_def] >| (* 3 subgoals *)
     [ (* goal 1 (of 3) *)
       MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                  (ISPEC “(Y,B,v) :'b m_space” IN_MEASURABLE_BOREL_EQ)) \\
       Q.EXISTS_TAC ‘\y. pos_fn_integral (X,A,u) (\x. fn_plus f (x,y)) -
                         pos_fn_integral (X,A,u) (\x. fn_minus f (x,y))’ >> BETA_TAC \\
       CONJ_TAC >- RW_TAC std_ss [integral_def] \\
       MATCH_MP_TAC IN_MEASURABLE_BOREL_SUB' \\
       FULL_SIMP_TAC std_ss [measure_space_def, space_def, m_space_def, measurable_sets_def] \\
       qexistsl_tac [‘\y. pos_fn_integral (X,A,u) (\x. fn_plus f (x,y))’,
                     ‘\y. pos_fn_integral (X,A,u) (\x. fn_minus f (x,y))’] \\
       simp [],
       (* goal 2 (of 3) *)
       REWRITE_TAC [lt_infty] >> MATCH_MP_TAC let_trans \\
       Q.EXISTS_TAC ‘pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y)))’ \\
       reverse CONJ_TAC >- art [GSYM lt_infty] \\
       MATCH_MP_TAC pos_fn_integral_mono_AE >> rw [FN_PLUS_POS]
       >- (MATCH_MP_TAC pos_fn_integral_pos >> rw [abs_pos]) \\
       Q.PAT_X_ASSUM ‘AE y::(Y,B,v). integrable (X,A,u) (\x. f (x,y))’ MP_TAC \\
       rw [AE_DEF] \\
       Q.EXISTS_TAC ‘N’ >> rw [] >> rename1 ‘y IN Y’ \\
       MATCH_MP_TAC le_trans \\
       Q.EXISTS_TAC ‘abs ((\y. integral (X,A,u) (\x. f (x,y))) y)’ \\
       CONJ_TAC >- REWRITE_TAC [FN_PLUS_LE_ABS] >> BETA_TAC \\
       MP_TAC (Q.SPECL [‘(X,A,u)’, ‘(\x. f (x,y))’] integral_triangle_ineq') \\
       simp [o_DEF],
       (* goal 3 (of 3) *)
       REWRITE_TAC [lt_infty] >> MATCH_MP_TAC let_trans \\
       Q.EXISTS_TAC ‘pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y)))’ \\
       reverse CONJ_TAC >- art [GSYM lt_infty] \\
       MATCH_MP_TAC pos_fn_integral_mono_AE >> rw [FN_MINUS_POS]
       >- (MATCH_MP_TAC pos_fn_integral_pos >> rw [abs_pos]) \\
       Q.PAT_X_ASSUM ‘AE y::(Y,B,v). integrable (X,A,u) (\x. f (x,y))’ MP_TAC \\
       rw [AE_DEF] \\
       Q.EXISTS_TAC ‘N’ >> rw [] >> rename1 ‘y IN Y’ \\
       MATCH_MP_TAC le_trans \\
       Q.EXISTS_TAC ‘abs ((\y. integral (X,A,u) (\x. f (x,y))) y)’ \\
       CONJ_TAC >- REWRITE_TAC [FN_MINUS_LE_ABS] >> BETA_TAC \\
       MP_TAC (Q.SPECL [‘(X,A,u)’, ‘(\x. f (x,y))’] integral_triangle_ineq') \\
       simp [o_DEF] ])
 >> DISCH_TAC
 (* final goals *)
 >> CONJ_TAC
 >| [ (* goal 1 (of 2) *)
      GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites [integral_def] \\
      Know ‘integral (Y,B,v) (\y. integral (X,A,u) (\x. f (x,y))) =
            integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. fn_plus f (x,y)) -
                                  pos_fn_integral (X,A,u) (\x. fn_minus f (x,y)))’
      >- (MATCH_MP_TAC integral_cong >> simp [] \\
          Q.X_GEN_TAC ‘y’ >> rw [integral_def]) >> Rewr' \\
      Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_plus f) =
                     pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. fn_plus f (x,y)))’
          (ONCE_REWRITE_TAC o wrap) \\
      Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_minus f) =
                     pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. fn_minus f (x,y)))’
          (ONCE_REWRITE_TAC o wrap) \\
      MATCH_MP_TAC EQ_SYM \\
      MATCH_MP_TAC integral_add_lemma' >> rw [] >| (* 5 subgoals *)
      [ (* goal 1.1 (of 5) *)
        MATCH_MP_TAC integrable_eq >> simp [] \\
        Q.EXISTS_TAC ‘\y. integral (X,A,u) (\x. f (x,y))’ >> simp [integral_def],
        (* goal 1.2 (of 5) *)
        Q.ABBREV_TAC ‘g = \y. pos_fn_integral (X,A,u) (\x. fn_plus f (x,y))’ \\
        Know ‘integrable (Y,B,v) g <=>
              g IN Borel_measurable (Y,B) /\ pos_fn_integral (Y,B,v) g <> PosInf’
        >- (MATCH_MP_TAC
              (REWRITE_RULE [m_space_def, measurable_sets_def]
                            (Q.SPEC ‘(Y,B,v)’ (INST_TYPE [alpha |-> beta] integrable_pos))) \\
            rw [Abbr ‘g’] \\
            MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_PLUS_POS]) >> Rewr' \\
        Q.UNABBREV_TAC ‘g’ >> art [],
        (* goal 1.3 (of 5) *)
        Q.ABBREV_TAC ‘g = \y. pos_fn_integral (X,A,u) (\x. fn_minus f (x,y))’ \\
        Know ‘integrable (Y,B,v) g <=>
              g IN Borel_measurable (Y,B) /\ pos_fn_integral (Y,B,v) g <> PosInf’
        >- (MATCH_MP_TAC
              (REWRITE_RULE [m_space_def, measurable_sets_def]
                            (Q.SPEC ‘(Y,B,v)’ (INST_TYPE [alpha |-> beta] integrable_pos))) \\
            rw [Abbr ‘g’] \\
            MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_MINUS_POS]) >> Rewr' \\
        Q.UNABBREV_TAC ‘g’ >> art [],
        (* goal 1.4 (of 5) *)
        MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_PLUS_POS],
        (* goal 1.5 (of 5) *)
        MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_MINUS_POS] ],
      (* goal 2 (of 2) *)
      GEN_REWRITE_TAC (RATOR_CONV o ONCE_DEPTH_CONV) empty_rewrites [integral_def] \\
      Know ‘integral (X,A,u) (\x. integral (Y,B,v) (\y. f (x,y))) =
            integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. fn_plus f (x,y)) -
                                  pos_fn_integral (Y,B,v) (\y. fn_minus f (x,y)))’
      >- (MATCH_MP_TAC integral_cong >> simp [] \\
          Q.X_GEN_TAC ‘x’ >> rw [integral_def]) >> Rewr' \\
      Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_plus f) =
                     pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. fn_plus f (x,y)))’
          (ONCE_REWRITE_TAC o wrap) \\
      Q.PAT_X_ASSUM ‘pos_fn_integral ((X,A,u) CROSS (Y,B,v)) (fn_minus f) =
                     pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. fn_minus f (x,y)))’
          (ONCE_REWRITE_TAC o wrap) \\
      MATCH_MP_TAC EQ_SYM \\
      MATCH_MP_TAC integral_add_lemma' >> rw [] >| (* 5 subgoals *)
      [ (* goal 2.1 (of 5) *)
        MATCH_MP_TAC integrable_eq >> simp [] \\
        Q.EXISTS_TAC ‘\x. integral (Y,B,v) (\y. f (x,y))’ >> simp [integral_def],
        (* goal 2.2 (of 5) *)
        Q.ABBREV_TAC ‘g = \x. pos_fn_integral (Y,B,v) (\y. fn_plus f (x,y))’ \\
        Know ‘integrable (X,A,u) g <=>
              g IN Borel_measurable (X,A) /\ pos_fn_integral (X,A,u) g <> PosInf’
        >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                       (Q.SPEC ‘(X,A,u)’ integrable_pos)) \\
            rw [Abbr ‘g’] \\
            MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_PLUS_POS]) >> Rewr' \\
        Q.UNABBREV_TAC ‘g’ >> art [],
        (* goal 2.3 (of 5) *)
        Q.ABBREV_TAC ‘g = \x. pos_fn_integral (Y,B,v) (\y. fn_minus f (x,y))’ \\
        Know ‘integrable (X,A,u) g <=>
              g IN Borel_measurable (X,A) /\ pos_fn_integral (X,A,u) g <> PosInf’
        >- (MATCH_MP_TAC (REWRITE_RULE [m_space_def, measurable_sets_def]
                                       (Q.SPEC ‘(X,A,u)’ integrable_pos)) \\
            rw [Abbr ‘g’] \\
            MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_MINUS_POS]) >> Rewr' \\
        Q.UNABBREV_TAC ‘g’ >> art [],
        (* goal 2.4 (of 5) *)
        MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_PLUS_POS],
        (* goal 2.5 (of 5) *)
        MATCH_MP_TAC pos_fn_integral_pos >> rw [FN_MINUS_POS] ] ]
QED

(* another form without using ‘pos_fn_integral’ *)
Theorem FUBINI' :
    !(X :'a set) (Y :'b set) A B u v f.
        sigma_finite_measure_space (X,A,u) /\
        sigma_finite_measure_space (Y,B,v) /\
        f IN measurable ((X,A) CROSS (Y,B)) Borel /\
     (* if at least one of the three integrals is finite (P \/ Q \/ R) *)
       (integral ((X,A,u) CROSS (Y,B,v)) (abs o f) <> PosInf \/
        integral (Y,B,v) (\y. integral (X,A,u) (\x. (abs o f) (x,y))) <> PosInf \/
        integral (X,A,u) (\x. integral (Y,B,v) (\y. (abs o f) (x,y))) <> PosInf)
       ==>
     (* then all three integrals are finite (P /\ Q /\ R) *)
        integral ((X,A,u) CROSS (Y,B,v)) (abs o f) <> PosInf /\
        integral (Y,B,v) (\y. integral (X,A,u) (\x. (abs o f) (x,y))) <> PosInf /\
        integral (X,A,u) (\x. integral (Y,B,v) (\y. (abs o f) (x,y))) <> PosInf /\
        integrable ((X,A,u) CROSS (Y,B,v)) f /\
       (AE y::(Y,B,v). integrable (X,A,u) (\x. f (x,y))) /\
       (AE x::(X,A,u). integrable (Y,B,v) (\y. f (x,y))) /\
        integrable (X,A,u) (\x. integral (Y,B,v) (\y. f (x,y))) /\
        integrable (Y,B,v) (\y. integral (X,A,u) (\x. f (x,y))) /\
       (integral ((X,A,u) CROSS (Y,B,v)) f =
        integral (Y,B,v) (\y. integral (X,A,u) (\x. f (x,y)))) /\
       (integral ((X,A,u) CROSS (Y,B,v)) f =
        integral (X,A,u) (\x. integral (Y,B,v) (\y. f (x,y))))
Proof
    rpt GEN_TAC
 (* prevent from separating ‘P \/ Q \/ R’ *)
 >> REWRITE_TAC [DECIDE “(A /\ B /\ C /\ D ==> E) <=>
                         (A ==> B ==> C ==> D ==> E)”]
 >> rpt DISCH_TAC
 >> ASSUME_TAC (Q.SPECL [‘X’, ‘Y’, ‘A’, ‘B’, ‘u’, ‘v’, ‘f’] FUBINI)
 >> ‘measure_space ((X,A,u) CROSS (Y,B,v))’
      by METIS_TAC [measure_space_prod_measure]
 >> ‘measure_space (X,A,u) /\ measure_space (Y,B,v)’
      by METIS_TAC [sigma_finite_measure_space_def]
 >> Q.PAT_X_ASSUM ‘P \/ Q \/ R’ MP_TAC
 >> Know ‘integral ((X,A,u) CROSS (Y,B,v)) (abs o f) = pos_fn_integral
                   ((X,A,u) CROSS (Y,B,v)) (abs o f)’
 >- (MATCH_MP_TAC integral_pos_fn >> rw [abs_pos])
 >> Rewr'
 >> Know ‘integral (Y,B,v) (\y. integral (X,A,u) (\x. (abs o f) (x,y))) =
          pos_fn_integral (Y,B,v) (\y. integral (X,A,u) (\x. (abs o f) (x,y)))’
 >- (MATCH_MP_TAC integral_pos_fn >> rw [] \\
     MATCH_MP_TAC integral_pos >> rw [abs_pos])
 >> Rewr'
 >> Know ‘pos_fn_integral (Y,B,v) (\y. integral (X,A,u) (\x. (abs o f) (x,y))) =
          pos_fn_integral (Y,B,v) (\y. pos_fn_integral (X,A,u) (\x. (abs o f) (x,y)))’
 >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
     CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                  MATCH_MP_TAC integral_pos >> rw [abs_pos]) \\
     CONJ_TAC >- (Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
                  MATCH_MP_TAC pos_fn_integral_pos >> rw [abs_pos]) \\
     Q.X_GEN_TAC ‘y’ >> DISCH_TAC \\
     MATCH_MP_TAC integral_pos_fn >> rw [abs_pos])
 >> Rewr'
 >> Know ‘integral (X,A,u) (\x. integral (Y,B,v) (\y. (abs o f) (x,y))) =
          pos_fn_integral (X,A,u) (\x. integral (Y,B,v) (\y. (abs o f) (x,y)))’
 >- (MATCH_MP_TAC integral_pos_fn >> rw [] \\
     MATCH_MP_TAC integral_pos >> rw [abs_pos])
 >> Rewr'
 >> Know ‘pos_fn_integral (X,A,u) (\x. integral (Y,B,v) (\y. (abs o f) (x,y))) =
          pos_fn_integral (X,A,u) (\x. pos_fn_integral (Y,B,v) (\y. (abs o f) (x,y)))’
 >- (MATCH_MP_TAC pos_fn_integral_cong >> simp [] \\
     CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                  MATCH_MP_TAC integral_pos >> rw [abs_pos]) \\
     CONJ_TAC >- (Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
                  MATCH_MP_TAC pos_fn_integral_pos >> rw [abs_pos]) \\
     Q.X_GEN_TAC ‘x’ >> DISCH_TAC \\
     MATCH_MP_TAC integral_pos_fn >> rw [abs_pos])
 >> Rewr'
 >> METIS_TAC []
QED

(* More compact forms of FUBINI and FUBINI' *)
Theorem Fubini = FUBINI
 |> (Q.SPECL [‘m_space m1’, ‘m_space m2’, ‘measurable_sets m1’, ‘measurable_sets m2’,
              ‘measure m1’, ‘measure m2’])
 |> (REWRITE_RULE [MEASURE_SPACE_REDUCE])
 |> (Q.GENL [‘m1’, ‘m2’]);

Theorem Fubini' = FUBINI'
 |> (Q.SPECL [‘m_space m1’, ‘m_space m2’, ‘measurable_sets m1’, ‘measurable_sets m2’,
              ‘measure m1’, ‘measure m2’])
 |> (REWRITE_RULE [MEASURE_SPACE_REDUCE])
 |> (Q.GENL [‘m1’, ‘m2’]);

(* This theorem only needs TONELLI *)
Theorem IN_MEASURABLE_BOREL_FROM_PROD_SIGMA :
    !X Y A B f. sigma_algebra (X,A) /\ sigma_algebra (Y,B) /\
                f IN measurable ((X,A) CROSS (Y,B)) Borel ==>
               (!y. y IN Y ==> (\x. f (x,y)) IN measurable (X,A) Borel) /\
               (!x. x IN X ==> (\y. f (x,y)) IN measurable (Y,B) Borel)
Proof
    rpt GEN_TAC >> STRIP_TAC
 >> ‘sigma_finite_measure_space (X,A,\s. 0) /\
     sigma_finite_measure_space (Y,B,\s. 0)’
      by METIS_TAC [measure_space_trivial, space_def, subsets_def]
 >> ‘(fn_plus f) IN measurable ((X,A) CROSS (Y,B)) Borel’
      by PROVE_TAC [IN_MEASURABLE_BOREL_FN_PLUS]
 >> ‘!s. s IN X CROSS Y ==> 0 <= (fn_plus f) s’ by rw [FN_PLUS_POS]
 >> Know ‘(!y. y IN Y ==> (\x. (fn_plus f) (x,y)) IN Borel_measurable (X,A)) /\
          (!x. x IN X ==> (\y. (fn_plus f) (x,y)) IN Borel_measurable (Y,B))’
 >- (MP_TAC (Q.SPECL [‘X’, ‘Y’, ‘A’, ‘B’, ‘\s. 0’, ‘\s. 0’, ‘fn_plus f’] TONELLI) \\
     RW_TAC std_ss []) >> STRIP_TAC
 >> ‘(fn_minus f) IN measurable ((X,A) CROSS (Y,B)) Borel’
      by PROVE_TAC [IN_MEASURABLE_BOREL_FN_MINUS]
 >> ‘!s. s IN X CROSS Y ==> 0 <= (fn_minus f) s’ by rw [FN_MINUS_POS]
 >> Know ‘(!y. y IN Y ==> (\x. (fn_minus f) (x,y)) IN Borel_measurable (X,A)) /\
          (!x. x IN X ==> (\y. (fn_minus f) (x,y)) IN Borel_measurable (Y,B))’
 >- (MP_TAC (Q.SPECL [‘X’, ‘Y’, ‘A’, ‘B’, ‘\s. 0’, ‘\s. 0’, ‘fn_minus f’] TONELLI) \\
     RW_TAC std_ss []) >> STRIP_TAC
 (* push ‘fn_plus/fn_minus’ inside *)
 >> ‘!y. fn_plus (\x. f (x,y)) = (\x. (fn_plus f) (x,y))’   by rw [FUN_EQ_THM, FN_PLUS_ALT]
 >> ‘!y. fn_minus (\x. f (x,y)) = (\x. (fn_minus f) (x,y))’ by rw [FUN_EQ_THM, FN_MINUS_ALT]
 >> ‘!x. fn_plus (\y. f (x,y)) = (\y. (fn_plus f) (x,y))’   by rw [FUN_EQ_THM, FN_PLUS_ALT]
 >> ‘!x. fn_minus (\y. f (x,y)) = (\y. (fn_minus f) (x,y))’ by rw [FUN_EQ_THM, FN_MINUS_ALT]
 >> ONCE_REWRITE_TAC [IN_MEASURABLE_BOREL_PLUS_MINUS]
 >> RW_TAC std_ss []
QED

(* ------------------------------------------------------------------------- *)
(*  Filtration and basic version of martingales (Chapter 23 of [1])          *)
(* ------------------------------------------------------------------------- *)

(* ‘sub_sigma_algebra’ is a partial-order between sigma-algebra *)
val SUB_SIGMA_ALGEBRA_REFL = store_thm
  ("SUB_SIGMA_ALGEBRA_REFL",
  ``!a. sigma_algebra a ==> sub_sigma_algebra a a``,
    RW_TAC std_ss [sub_sigma_algebra_def, SUBSET_REFL]);

val SUB_SIGMA_ALGEBRA_TRANS = store_thm
  ("SUB_SIGMA_ALGEBRA_TRANS",
  ``!a b c. sub_sigma_algebra a b /\ sub_sigma_algebra b c ==> sub_sigma_algebra a c``,
    RW_TAC std_ss [sub_sigma_algebra_def]
 >> MATCH_MP_TAC SUBSET_TRANS
 >> Q.EXISTS_TAC `subsets b` >> art []);

val SUB_SIGMA_ALGEBRA_ANTISYM = store_thm
  ("SUB_SIGMA_ALGEBRA_ANTISYM",
  ``!a b. sub_sigma_algebra a b /\ sub_sigma_algebra b a ==> (a = b)``,
    RW_TAC std_ss [sub_sigma_algebra_def]
 >> Q.PAT_X_ASSUM `space b = space a` K_TAC
 >> ONCE_REWRITE_TAC [GSYM SPACE]
 >> ASM_REWRITE_TAC [CLOSED_PAIR_EQ]
 >> MATCH_MP_TAC SUBSET_ANTISYM >> art []);

val SUB_SIGMA_ALGEBRA_ORDER = store_thm
  ("SUB_SIGMA_ALGEBRA_ORDER", ``Order sub_sigma_algebra``,
    RW_TAC std_ss [Order, antisymmetric_def, transitive_def]
 >- (MATCH_MP_TAC SUB_SIGMA_ALGEBRA_ANTISYM >> art [])
 >> IMP_RES_TAC SUB_SIGMA_ALGEBRA_TRANS);

val SUB_SIGMA_ALGEBRA_MEASURE_SPACE = store_thm
  ("SUB_SIGMA_ALGEBRA_MEASURE_SPACE",
  ``!m a. measure_space m /\ sub_sigma_algebra a (m_space m,measurable_sets m) ==>
          measure_space (m_space m,subsets a,measure m)``,
    RW_TAC std_ss [sub_sigma_algebra_def, space_def, subsets_def]
 >> MATCH_MP_TAC MEASURE_SPACE_RESTRICTION
 >> Q.EXISTS_TAC `measurable_sets m`
 >> simp [MEASURE_SPACE_REDUCE]
 >> METIS_TAC [SPACE]);

val FILTRATION_BOUNDED = store_thm
  ("FILTRATION_BOUNDED",
  ``!A a. filtration A a ==> !n. sub_sigma_algebra (a n) A``,
    PROVE_TAC [filtration_def]);

val FILTRATION_MONO = store_thm
  ("FILTRATION_MONO",
  ``!A a. filtration A a ==> !i j. i <= j ==> subsets (a i) SUBSET subsets (a j)``,
    PROVE_TAC [filtration_def]);

(* all sigma-algebras in `filtration A` are subset of A *)
val FILTRATION_SUBSETS = store_thm
  ("FILTRATION_SUBSETS",
  ``!A a. filtration A a ==> !n. subsets (a n) SUBSET (subsets A)``,
    RW_TAC std_ss [filtration_def, sub_sigma_algebra_def]);

val FILTRATION = store_thm
  ("FILTRATION",
  ``!A a. filtration A a <=> (!n. sub_sigma_algebra (a n) A) /\
                             (!n. subsets (a n) SUBSET (subsets A)) /\
                             (!i j. i <= j ==> subsets (a i) SUBSET subsets (a j))``,
    rpt GEN_TAC >> EQ_TAC
 >- (DISCH_TAC >> IMP_RES_TAC FILTRATION_SUBSETS >> fs [filtration_def])
 >> RW_TAC std_ss [filtration_def]);

Theorem filtered_measure_space_alt :
    !m a. filtered_measure_space m a <=>
          measure_space m /\ filtration (m_space m,measurable_sets m) a
Proof
    rpt GEN_TAC
 >> Cases_on `m` >> Cases_on `r`
 >> REWRITE_TAC [filtered_measure_space_def, m_space_def, measurable_sets_def]
QED

Theorem sigma_finite_filtered_measure_space :
    !m a. sigma_finite_filtered_measure_space m a <=>
          measure_space m /\ filtration (m_space m,measurable_sets m) a /\
          sigma_finite (m_space m,subsets (a 0),measure m)
Proof
    rpt GEN_TAC
 >> Cases_on ‘m’ >> Cases_on ‘r’ >> rename1 ‘measure_space (sp,sts,m)’
 >> rw [sigma_finite_filtered_measure_space_def,
        filtered_measure_space_def, GSYM CONJ_ASSOC]
QED

(* all sub measure spaces of a sigma-finite fms are also sigma-finite *)
Theorem SIGMA_FINITE_FILTERED_MEASURE_SPACE[local] :
    !sp sts m a. sigma_finite_filtered_measure_space (sp,sts,m) a ==>
                 !n. sigma_finite (sp,subsets (a n),m)
Proof
    RW_TAC std_ss [sigma_finite_filtered_measure_space_def,
                   filtered_measure_space_def, filtration_def]
 >> Know `measure_space (sp,subsets (a 0),m) /\
          measure_space (sp,subsets (a n),m)`
 >- (CONJ_TAC \\ (* 2 subgoals, same tactics *)
     MATCH_MP_TAC
       (REWRITE_RULE [m_space_def, measurable_sets_def, measure_def]
                     (Q.SPEC `(sp,sts,m)` SUB_SIGMA_ALGEBRA_MEASURE_SPACE)) >> art [])
 >> STRIP_TAC
 >> POP_ASSUM (simp o wrap o (MATCH_MP SIGMA_FINITE_ALT))
 >> POP_ASSUM (fs o wrap o (MATCH_MP SIGMA_FINITE_ALT))
 >> Q.EXISTS_TAC `f`
 >> fs [IN_FUNSET, IN_UNIV, measurable_sets_def, m_space_def, measure_def]
 >> `0 <= n` by RW_TAC arith_ss []
 >> METIS_TAC [SUBSET_DEF]
QED

(* |- !m a.
        sigma_finite_filtered_measure_space m a ==>
        !n. sigma_finite (m_space m,subsets (a n),measure m)
 *)
Theorem SIGMA_FINITE_FILTERED_MEASURE_SPACE_I =
        SIGMA_FINITE_FILTERED_MEASURE_SPACE
    |> (Q.SPECL [‘m_space m’, ‘measurable_sets m’, ‘measure m’])
    |> (Q.GEN ‘m’)
    |> (REWRITE_RULE [MEASURE_SPACE_REDUCE])

Theorem sigma_finite_filtered_measure_space_alt_all :
    !m a. sigma_finite_filtered_measure_space m a <=>
          measure_space m /\ filtration (m_space m,measurable_sets m) a /\
          !n. sigma_finite (m_space m,subsets (a n),measure m)
Proof
    rpt GEN_TAC
 >> reverse EQ_TAC
 >- RW_TAC std_ss [sigma_finite_filtered_measure_space]
 >> DISCH_TAC
 >> IMP_RES_TAC SIGMA_FINITE_FILTERED_MEASURE_SPACE_I
 >> fs [sigma_finite_filtered_measure_space]
QED

(* the smallest sigma-algebra generated by all (a n) *)
val infty_sigma_algebra_def = Define
   `infty_sigma_algebra sp a =
      sigma sp (BIGUNION (IMAGE (\(i :num). subsets (a i)) UNIV))`;

val INFTY_SIGMA_ALGEBRA_BOUNDED = store_thm
  ("INFTY_SIGMA_ALGEBRA_BOUNDED",
  ``!A a. filtration A a ==>
          sub_sigma_algebra (infty_sigma_algebra (space A) a) A``,
    RW_TAC std_ss [sub_sigma_algebra_def, FILTRATION, infty_sigma_algebra_def]
 >- (MATCH_MP_TAC SIGMA_ALGEBRA_SIGMA \\
     RW_TAC std_ss [subset_class_def, IN_BIGUNION_IMAGE, IN_UNIV] \\
    `x IN subsets A` by PROVE_TAC [SUBSET_DEF] \\
     METIS_TAC [sigma_algebra_def, algebra_def, subset_class_def, space_def, subsets_def])
 >- REWRITE_TAC [SPACE_SIGMA]
 >> MATCH_MP_TAC SIGMA_SUBSET >> art []
 >> RW_TAC std_ss [SUBSET_DEF, IN_BIGUNION_IMAGE, IN_UNIV]
 >> PROVE_TAC [SUBSET_DEF]);

val INFTY_SIGMA_ALGEBRA_MAXIMAL = store_thm
  ("INFTY_SIGMA_ALGEBRA_MAXIMAL",
  ``!A a. filtration A a ==> !n. sub_sigma_algebra (a n) (infty_sigma_algebra (space A) a)``,
 (* proof *)
    RW_TAC std_ss [sub_sigma_algebra_def, FILTRATION, infty_sigma_algebra_def]
 >- (MATCH_MP_TAC SIGMA_ALGEBRA_SIGMA \\
     RW_TAC std_ss [subset_class_def, IN_BIGUNION_IMAGE, IN_UNIV] \\
    `x IN subsets A` by PROVE_TAC [SUBSET_DEF] \\
     METIS_TAC [sigma_algebra_def, algebra_def, subset_class_def, space_def, subsets_def])
 >- REWRITE_TAC [SPACE_SIGMA]
 >> MATCH_MP_TAC SUBSET_TRANS
 >> Q.EXISTS_TAC `BIGUNION (IMAGE (\i. subsets (a i)) univ(:num))`
 >> CONJ_TAC
 >- (RW_TAC std_ss [SUBSET_DEF, IN_BIGUNION_IMAGE, IN_UNIV] \\
     Q.EXISTS_TAC `n` >> art [])
 >> REWRITE_TAC [SIGMA_SUBSET_SUBSETS]);

(* ------------------------------------------------------------------------- *)
(*  Martingale alternative definitions and properties (Chapter 23 of [1])    *)
(* ------------------------------------------------------------------------- *)

(* ‘u’ is a martingale if, and only if, it is both a sub- and a super-martingale

   This is Example 23.3 (i) [1, p.277]
 *)
Theorem MARTINGALE_EQ_SUB_SUPER :
    !m a u. martingale m a u <=> sub_martingale m a u /\ super_martingale m a u
Proof
    RW_TAC std_ss [martingale_def, sub_martingale_def, super_martingale_def]
 >> EQ_TAC >> RW_TAC std_ss [le_refl]
 >> ASM_SIMP_TAC std_ss [GSYM le_antisym]
QED

(* simple alternative definitions: ‘n < SUC n’ is replaced by ‘i <= j’ *)
val martingale_shared_tactics_1 =
    reverse EQ_TAC >- RW_TAC arith_ss []
 >> RW_TAC arith_ss [sigma_finite_filtered_measure_space]
 >> Q.PAT_X_ASSUM ‘i <= j’ MP_TAC
 >> Induct_on ‘j - i’
 >- (RW_TAC arith_ss [] \\
    ‘j = i’ by RW_TAC arith_ss [] >> RW_TAC arith_ss [le_refl])
 >> RW_TAC arith_ss []
 >> ‘v = PRE j - i’ by RW_TAC arith_ss []
 >> ‘i < j /\ i <= PRE j’ by RW_TAC arith_ss []
 >> ‘SUC (PRE j) = j’ by RW_TAC arith_ss []
 >> ‘s IN subsets (a (PRE j))’ by METIS_TAC [FILTRATION_MONO, SUBSET_DEF]
 >> Q.PAT_X_ASSUM ‘!n s. s IN subsets (a n) ==> P’
     (MP_TAC o (Q.SPECL [‘PRE j’, ‘s’]))
 >> RW_TAC arith_ss [];

val martingale_shared_tactics_2 =
    MATCH_MP_TAC le_trans
 >> Q.EXISTS_TAC ‘integral m (\x. u (PRE j) x * indicator_fn s x)’
 >> POP_ASSUM (REWRITE_TAC o wrap)
 >> FIRST_X_ASSUM irule
 >> RW_TAC arith_ss [];

Theorem martingale_alt :
   !m a u.
      martingale m a u <=>
      sigma_finite_filtered_measure_space m a /\ (!n. integrable m (u n)) /\
      !i j s. i <= j /\ s IN subsets (a i) ==>
             (integral m (\x. u i x * indicator_fn s x) =
              integral m (\x. u j x * indicator_fn s x))
Proof
    RW_TAC std_ss [martingale_def]
 >> martingale_shared_tactics_1
QED

Theorem super_martingale_alt :
   !m a u.
      super_martingale m a u <=>
      sigma_finite_filtered_measure_space m a /\ (!n. integrable m (u n)) /\
      !i j s. i <= j /\ s IN subsets (a i) ==>
             (integral m (\x. u j x * indicator_fn s x) <=
              integral m (\x. u i x * indicator_fn s x))
Proof
    RW_TAC std_ss [super_martingale_def]
 >> martingale_shared_tactics_1
 >> martingale_shared_tactics_2
QED

Theorem sub_martingale_alt :
   !m a u.
      sub_martingale m a u <=>
      sigma_finite_filtered_measure_space m a /\ (!n. integrable m (u n)) /\
      !i j s. i <= j /\ s IN subsets (a i) ==>
             (integral m (\x. u i x * indicator_fn s x) <=
              integral m (\x. u j x * indicator_fn s x))
Proof
    RW_TAC std_ss [sub_martingale_def]
 >> martingale_shared_tactics_1
 >> martingale_shared_tactics_2
QED

(* Remark 23.2 [1, p.276]: we can replace the sigma-algebra (a n) with any
   INTER-stable generator (g n) of (a n) containing an exhausive sequence.

   NOTE: in typical applications, it's expected to have (g n) such that
  ‘!i j. i <= j ==> g i SUBSET g j’ and thus the exhausting sequence of (g 0)
   is also the exhausting sequence of all (g n).
 *)

val martingale_alt_generator_shared_tactics_1 =
    qx_genl_tac [‘m’, ‘a’, ‘u’, ‘G’]
 >> RW_TAC std_ss [sigma_finite_filtered_measure_space, filtered_measure_space_alt,
                   martingale_alt, sub_martingale_alt, super_martingale_alt]
 >> EQ_TAC (* easy part first *)
 >- (RW_TAC std_ss [] \\
     FIRST_X_ASSUM MATCH_MP_TAC >> rw [] \\
     Suff ‘(G i) SUBSET subsets (sigma (m_space m) (G i))’ >- METIS_TAC [SUBSET_DEF] \\
     REWRITE_TAC [SIGMA_SUBSET_SUBSETS])
 >> rw [sigma_finite_alt_exhausting_sequence, exhausting_sequence_def, IN_FUNSET]
 >- (fs [has_exhausting_sequence_def, IN_FUNSET, IN_UNIV] \\
     Q.PAT_X_ASSUM ‘!n. ?f. P’ (MP_TAC o (Q.SPEC ‘0’)) \\
     RW_TAC std_ss [] \\
     Q.EXISTS_TAC ‘f’ >> rw []
     >- (Suff ‘(G 0) SUBSET subsets (sigma (m_space m) (G 0))’
         >- METIS_TAC [SUBSET_DEF] \\
         REWRITE_TAC [SIGMA_SUBSET_SUBSETS]) \\
     FIRST_X_ASSUM MATCH_MP_TAC \\
     Q.EXISTS_TAC ‘0’ >> art [])
 (* stage work *)
 >> FULL_SIMP_TAC std_ss [integral_def]
 >> Know ‘!n. subsets (a n) SUBSET (measurable_sets m)’
 >- (fs [filtration_def, sub_sigma_algebra_def])
 >> DISCH_TAC
 >> ‘!n s. s IN G n ==> s IN measurable_sets m’
      by METIS_TAC [SIGMA_SUBSET_SUBSETS, SUBSET_DEF]
 >> Know ‘!n s. (\x. u n x * indicator_fn s x)^+ =
                (\x. fn_plus (u n) x * indicator_fn s x)’
 >- (rpt GEN_TAC >> ONCE_REWRITE_TAC [mul_comm] \\
     MATCH_MP_TAC FN_PLUS_FMUL >> rw [INDICATOR_FN_POS])
 >> DISCH_THEN (FULL_SIMP_TAC std_ss o wrap)
 >> Know ‘!n s. (\x. u n x * indicator_fn s x)^- =
                (\x. fn_minus (u n) x * indicator_fn s x)’
 >- (rpt GEN_TAC >> ONCE_REWRITE_TAC [mul_comm] \\
     MATCH_MP_TAC FN_MINUS_FMUL >> rw [INDICATOR_FN_POS])
 >> DISCH_THEN (FULL_SIMP_TAC std_ss o wrap)
 (* simplifications by abbreviations *)
 >> Q.ABBREV_TAC ‘A = \n s. pos_fn_integral m (\x. (u n)^+ x * indicator_fn s x)’
 >> Q.ABBREV_TAC ‘B = \n s. pos_fn_integral m (\x. (u n)^- x * indicator_fn s x)’
 >> FULL_SIMP_TAC std_ss []
 >> Know ‘!n s. 0 <= A n s /\ 0 <= B n s’
 >- (rw [Abbr ‘A’, Abbr ‘B’] \\
     MATCH_MP_TAC pos_fn_integral_pos >> rw [] \\
     MATCH_MP_TAC le_mul \\
     rw [FN_PLUS_POS, FN_MINUS_POS, INDICATOR_FN_POS])
 >> DISCH_TAC
 >> Know ‘!n s. A n s < PosInf /\ B n s < PosInf’
 >- (rw [Abbr ‘A’, Abbr ‘B’] >| (* 2 subgoals *)
     [ (* goal 1 (of 2) *)
       MATCH_MP_TAC let_trans \\
       Q.EXISTS_TAC ‘pos_fn_integral m (fn_plus (u n))’ \\
       reverse CONJ_TAC >- (REWRITE_TAC [GSYM lt_infty] \\
                            METIS_TAC [integrable_def]) \\
       MATCH_MP_TAC pos_fn_integral_mono >> rw []
       >- (MATCH_MP_TAC le_mul >> rw [FN_PLUS_POS, INDICATOR_FN_POS]) \\
       GEN_REWRITE_TAC (RAND_CONV o ONCE_DEPTH_CONV) empty_rewrites [GSYM mul_rone] \\
       MATCH_MP_TAC le_lmul_imp >> rw [FN_PLUS_POS, INDICATOR_FN_LE_1],
       (* goal 2 (of 2) *)
       MATCH_MP_TAC let_trans \\
       Q.EXISTS_TAC ‘pos_fn_integral m (fn_minus (u n))’ \\
       reverse CONJ_TAC >- (REWRITE_TAC [GSYM lt_infty] \\
                            METIS_TAC [integrable_def]) \\
       MATCH_MP_TAC pos_fn_integral_mono >> rw []
       >- (MATCH_MP_TAC le_mul >> rw [FN_MINUS_POS, INDICATOR_FN_POS]) \\
       GEN_REWRITE_TAC (RAND_CONV o ONCE_DEPTH_CONV) empty_rewrites [GSYM mul_rone] \\
       MATCH_MP_TAC le_lmul_imp >> rw [FN_MINUS_POS, INDICATOR_FN_LE_1] ])
 >> DISCH_TAC;
 (* end of martingale_alt_generator_shared_tactics_1 *)

val martingale_alt_generator_shared_tactics_2 =
    Q.ABBREV_TAC ‘f = \i j x. fn_plus (u i) x + fn_minus (u j) x’
 >> Know ‘!i j s. s IN measurable_sets m ==> A i s + B j s = (f i j * m) s’
 >- (qx_genl_tac [‘k’, ‘n’, ‘t’] \\
     RW_TAC std_ss [Abbr ‘f’, Abbr ‘A’, Abbr ‘B’, density_measure_def] \\
     Know ‘pos_fn_integral m (\x. (u k)^+ x * indicator_fn t x) +
           pos_fn_integral m (\x. (u n)^- x * indicator_fn t x) =
           pos_fn_integral m (\x. (u k)^+ x * indicator_fn t x +
                                  (u n)^- x * indicator_fn t x)’
     >- (ONCE_REWRITE_TAC [EQ_SYM_EQ] \\
         HO_MATCH_MP_TAC pos_fn_integral_add >> rw [] >| (* 4 subgoals *)
         [ (* goal 1 (of 4) *)
           MATCH_MP_TAC le_mul >> rw [FN_PLUS_POS, INDICATOR_FN_POS],
           (* goal 2 (of 4) *)
           MATCH_MP_TAC le_mul >> rw [FN_MINUS_POS, INDICATOR_FN_POS],
           (* goal 3 (of 4) *)
           MATCH_MP_TAC IN_MEASURABLE_BOREL_MUL_INDICATOR >> rw []
           >- (FULL_SIMP_TAC std_ss [measure_space_def]) \\
           MATCH_MP_TAC IN_MEASURABLE_BOREL_FN_PLUS \\
           FULL_SIMP_TAC std_ss [integrable_def],
           (* goal 4 (of 4) *)
           MATCH_MP_TAC IN_MEASURABLE_BOREL_MUL_INDICATOR >> rw []
           >- (FULL_SIMP_TAC std_ss [measure_space_def]) \\
           MATCH_MP_TAC IN_MEASURABLE_BOREL_FN_MINUS \\
           FULL_SIMP_TAC std_ss [integrable_def] ]) >> Rewr' \\
     MATCH_MP_TAC pos_fn_integral_cong >> rw [] >| (* 3 subgoals *)
     [ (* goal 1 (of 3) *)
       MATCH_MP_TAC le_add >> CONJ_TAC >> MATCH_MP_TAC le_mul \\
       rw [FN_PLUS_POS, FN_MINUS_POS, INDICATOR_FN_POS],
       (* goal 2 (of 3) *)
       MATCH_MP_TAC le_mul >> rw [INDICATOR_FN_POS] \\
       MATCH_MP_TAC le_add >> rw [FN_PLUS_POS, FN_MINUS_POS],
       (* goal 3 (of 3) *)
       rw [indicator_fn_def] ])
 >> DISCH_TAC
 >> ‘s IN measurable_sets m’ by METIS_TAC [SIGMA_SUBSET_SUBSETS, SUBSET_DEF];
 (* end of martingale_alt_generator_shared_tactics_2 *)

val martingale_alt_generator_shared_tactics_3 =
    Know ‘!i j. measure_space (m_space m,measurable_sets m,f i j * m)’
 >- (qx_genl_tac [‘M’, ‘N’] \\
     MATCH_MP_TAC (REWRITE_RULE [density_def] measure_space_density) \\
     RW_TAC std_ss [Abbr ‘f’] >| (* 2 subgoals *)
     [ (* goal 1 (of 2) *)
       MATCH_MP_TAC IN_MEASURABLE_BOREL_ADD' \\
       qexistsl_tac [‘fn_plus (u M)’, ‘fn_minus (u N)’] >> simp [] \\
       CONJ_TAC >- FULL_SIMP_TAC std_ss [measure_space_def] \\
       FULL_SIMP_TAC std_ss [integrable_def] \\
       PROVE_TAC [IN_MEASURABLE_BOREL_FN_PLUS, IN_MEASURABLE_BOREL_FN_MINUS],
       (* goal 2 (of 2) *)
       MATCH_MP_TAC le_add >> rw [FN_PLUS_POS, FN_MINUS_POS] ])
 >> DISCH_TAC;
(* end of martingale_alt_generator_shared_tactics_3 *)

val martingale_alt_generator_shared_tactics_4 =
    Suff ‘!i j n. measure_space (m_space m,subsets (sigma (m_space m) (G n)),f i j * m)’
 >- Rewr
 >> Q.PAT_X_ASSUM ‘i <= j’ K_TAC
 >> Q.PAT_X_ASSUM ‘s IN subsets (sigma (m_space m) (G i))’ K_TAC
 >> Q.PAT_X_ASSUM ‘s IN measurable_sets m’ K_TAC
 >> rpt GEN_TAC
 >> MATCH_MP_TAC MEASURE_SPACE_RESTRICTION
 >> Q.EXISTS_TAC ‘measurable_sets m’ >> art []
 >> CONJ_TAC >- PROVE_TAC [] (* sigma (G n) SUBSET measurable_sets m *)
 >> ‘(m_space m,subsets (sigma (m_space m) (G n))) = sigma (m_space m) (G n)’
       by METIS_TAC [SPACE, SPACE_SIGMA]
 >> POP_ORW
 >> MATCH_MP_TAC SIGMA_ALGEBRA_SIGMA >> art [];
 (* end of martingale_alt_generator_shared_tactics_4 *)

Theorem martingale_alt_generator :
   !m a u g. (!n. a n = sigma (m_space m) (g n)) /\
             (!n. has_exhausting_sequence (m_space m,g n)) /\
             (!n s. s IN (g n) ==> measure m s < PosInf) /\
             (!n s t. s IN (g n) /\ t IN (g n) ==> s INTER t IN (g n)) ==>
     (martingale m a u <=>
      filtered_measure_space m a /\ (!n. integrable m (u n)) /\
      !i j s. i <= j /\ s IN (g i) ==>
             (integral m (\x. u i x * indicator_fn s x) =
              integral m (\x. u j x * indicator_fn s x)))
Proof
    martingale_alt_generator_shared_tactics_1
 (* stage work on transforming the goal into equivalence of two measures *)
 >> Know ‘!i j s. (A i s - B i s = A j s - B j s <=>
                   A i s + B j s = A j s + B i s)’
 >- (qx_genl_tac [‘M’, ‘N’, ‘t’] \\
    ‘A M t <> NegInf /\ A N t <> NegInf /\ B M t <> NegInf /\ B N t <> NegInf’
       by METIS_TAC [pos_not_neginf] \\
    ‘A M t <> PosInf /\ A N t <> PosInf /\ B M t <> PosInf /\ B N t <> PosInf’
       by METIS_TAC [lt_infty] \\
    ‘?r1. A M t = Normal r1’ by METIS_TAC [extreal_cases] >> POP_ORW \\
    ‘?r2. A N t = Normal r2’ by METIS_TAC [extreal_cases] >> POP_ORW \\
    ‘?r3. B M t = Normal r3’ by METIS_TAC [extreal_cases] >> POP_ORW \\
    ‘?r4. B N t = Normal r4’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     rw [extreal_add_def, extreal_sub_def, extreal_le_eq] >> REAL_ARITH_TAC)
 >> DISCH_THEN (FULL_SIMP_TAC pure_ss o wrap)
 (* applying density_measure_def *)
 >> martingale_alt_generator_shared_tactics_2
 (* final modification of the goal *)
 >> ‘A i s + B j s = A j s + B i s <=> (f i j * m) s = (f j i * m) s’
      by METIS_TAC [] >> POP_ORW
 (* final modification of the major assumption *)
 >> Know ‘!i j s. i <= j /\ s IN G i ==> (f i j * m) s = (f j i * m) s’
 >- (qx_genl_tac [‘k’, ‘n’, ‘t’] >> rpt STRIP_TAC \\
    ‘t IN measurable_sets m’ by PROVE_TAC [] \\
     METIS_TAC [])
 >> DISCH_TAC
 >> Q.PAT_X_ASSUM ‘!i j s. i <= j /\ s IN G i ==> A i s + B j s = A j s + B i s’ K_TAC
 (* applying measure_space_density, density_def *)
 >> martingale_alt_generator_shared_tactics_3
 (* applying UNIQUENESS_OF_MEASURE *)
 >> irule UNIQUENESS_OF_MEASURE
 >> qexistsl_tac [‘m_space m’, ‘G i’] >> simp []
 >> CONJ_TAC (* f i j * m = f j i * m *)
 >- (rpt STRIP_TAC >> FIRST_X_ASSUM MATCH_MP_TAC >> art [])
 >> Know ‘!n. subset_class (m_space m) (G n)’
 >- (rw [subset_class_def] \\
    ‘x IN measurable_sets m’ by METIS_TAC [SUBSET_DEF] \\
     FULL_SIMP_TAC std_ss [measure_space_def, sigma_algebra_def, algebra_def,
                           subset_class_def, space_def, subsets_def])
 >> DISCH_TAC
 (* easy goals first *)
 >> ASM_REWRITE_TAC [CONJ_ASSOC]
 >> reverse CONJ_TAC (* sigma_finite of G *)
 >- (Q.PAT_X_ASSUM ‘!n. has_exhausting_sequence (m_space m,G n)’ (MP_TAC o (Q.SPEC ‘i’)) \\
     rw [sigma_finite_def, has_exhausting_sequence_def, IN_FUNSET] \\
     rename1 ‘!x. g x IN G i’ >> Q.EXISTS_TAC ‘g’ >> rw [] \\
    ‘g n IN measurable_sets m’ by METIS_TAC [SUBSET_DEF] \\
    ‘(f i j * m) (g n) = A i (g n) + B j (g n)’ by METIS_TAC [] >> POP_ORW \\
     METIS_TAC [add_not_infty, lt_infty])
 (* final: applying MEASURE_SPACE_RESTRICTION *)
 >> martingale_alt_generator_shared_tactics_4
QED

val martingale_alt_generator_shared_tactics_5 =
    Know ‘!i j s. (A i s - B i s <= A j s - B j s <=>
                   A i s + B j s <= A j s + B i s)’
 >- (qx_genl_tac [‘M’, ‘N’, ‘t’] \\
    ‘A M t <> NegInf /\ A N t <> NegInf /\ B M t <> NegInf /\ B N t <> NegInf’
       by METIS_TAC [pos_not_neginf] \\
    ‘A M t <> PosInf /\ A N t <> PosInf /\ B M t <> PosInf /\ B N t <> PosInf’
       by METIS_TAC [lt_infty] \\
    ‘?r1. A M t = Normal r1’ by METIS_TAC [extreal_cases] >> POP_ORW \\
    ‘?r2. A N t = Normal r2’ by METIS_TAC [extreal_cases] >> POP_ORW \\
    ‘?r3. B M t = Normal r3’ by METIS_TAC [extreal_cases] >> POP_ORW \\
    ‘?r4. B N t = Normal r4’ by METIS_TAC [extreal_cases] >> POP_ORW \\
     rw [extreal_add_def, extreal_sub_def, extreal_le_eq] >> REAL_ARITH_TAC)
 >> DISCH_THEN (FULL_SIMP_TAC pure_ss o wrap);
 (* end of martingale_alt_generator_shared_tactics_5 *)

(* For sub- and super-martingales, we need, in addition, that (g n) is a semi-ring.

   This theorem (and the next one) relies on measureTheory.SEMIRING_SIGMA_MONOTONE
 *)
Theorem sub_martingale_alt_generator :
   !m a u g. (!n. a n = sigma (m_space m) (g n)) /\
             (!n. has_exhausting_sequence (m_space m,g n)) /\
             (!n s. s IN (g n) ==> measure m s < PosInf) /\
             (!n. semiring (m_space m,g n)) ==>
     (sub_martingale m a u <=>
      filtered_measure_space m a /\ (!n. integrable m (u n)) /\
      !i j s. i <= j /\ s IN (g i) ==>
             (integral m (\x. u i x * indicator_fn s x) <=
              integral m (\x. u j x * indicator_fn s x)))
Proof
    martingale_alt_generator_shared_tactics_1
 (* stage work on transforming the goal into equivalence of two measures *)
 >> martingale_alt_generator_shared_tactics_5
 (* applying density_measure_def *)
 >> martingale_alt_generator_shared_tactics_2
 (* final modification of the goal *)
 >> ‘A i s + B j s <= A j s + B i s <=> (f i j * m) s <= (f j i * m) s’
      by METIS_TAC [] >> POP_ORW
 (* final modification of the major assumption *)
 >> Know ‘!i j s. i <= j /\ s IN G i ==> (f i j * m) s <= (f j i * m) s’
 >- (qx_genl_tac [‘M’, ‘N’, ‘t’] >> rpt STRIP_TAC \\
    ‘t IN measurable_sets m’ by PROVE_TAC [] \\
     METIS_TAC [])
 >> DISCH_TAC
 >> Q.PAT_X_ASSUM ‘!i j s. i <= j /\ s IN G i ==> A i s + B j s <= _’ K_TAC
 (* applying measure_space_density, density_def *)
 >> martingale_alt_generator_shared_tactics_3
 (* applying SEMIRING_SIGMA_MONOTONE *)
 >> irule SEMIRING_SIGMA_MONOTONE
 >> qexistsl_tac [‘m_space m’, ‘G i’] >> simp []
 >> CONJ_TAC (* (f j i * m) s < PosInf *)
 >- (Q.X_GEN_TAC ‘t’ >> DISCH_TAC \\
    ‘t IN measurable_sets m’ by METIS_TAC [SUBSET_DEF] \\
    ‘(f j i * m) t = A j t + B i t’ by METIS_TAC [] >> POP_ORW \\
     METIS_TAC [add_not_infty, lt_infty])
 (* applying MEASURE_SPACE_RESTRICTION *)
 >> martingale_alt_generator_shared_tactics_4
 (* subset_class *)
 >> Q.PAT_X_ASSUM ‘!n. semiring (m_space m,G n)’ (MP_TAC o (Q.SPEC ‘n’))
 >> rw [semiring_def]
QED

Theorem super_martingale_alt_generator :
   !m a u g. (!n. a n = sigma (m_space m) (g n)) /\
             (!n. has_exhausting_sequence (m_space m,g n)) /\
             (!n s. s IN (g n) ==> measure m s < PosInf) /\
             (!n. semiring (m_space m,g n)) ==>
     (super_martingale m a u <=>
      filtered_measure_space m a /\ (!n. integrable m (u n)) /\
      !i j s. i <= j /\ s IN (g i) ==>
             (integral m (\x. u j x * indicator_fn s x) <=
              integral m (\x. u i x * indicator_fn s x)))
Proof
    martingale_alt_generator_shared_tactics_1
 (* stage work on transforming the goal into equivalence of two measures *)
 >> martingale_alt_generator_shared_tactics_5
 (* applying density_measure_def *)
 >> martingale_alt_generator_shared_tactics_2
 (* final modification of the goal *)
 >> ‘A j s + B i s <= A i s + B j s <=> (f j i * m) s <= (f i j * m) s’
      by METIS_TAC [] >> POP_ORW
 (* final modification of the major assumption *)
 >> Know ‘!i j s. i <= j /\ s IN G i ==> (f j i * m) s <= (f i j * m) s’
 >- (qx_genl_tac [‘M’, ‘N’, ‘t’] >> rpt STRIP_TAC \\
    ‘t IN measurable_sets m’ by PROVE_TAC [] \\
     METIS_TAC [])
 >> DISCH_TAC
 >> Q.PAT_X_ASSUM ‘!i j s. i <= j /\ s IN G i ==> A j s + B i s <= _’ K_TAC
 (* applying measure_space_density, density_def *)
 >> martingale_alt_generator_shared_tactics_3
 (* applying SEMIRING_SIGMA_MONOTONE *)
 >> irule SEMIRING_SIGMA_MONOTONE
 >> qexistsl_tac [‘m_space m’, ‘G i’] >> simp []
 >> CONJ_TAC (* (f i j * m) s < PosInf *)
 >- (Q.X_GEN_TAC ‘t’ >> DISCH_TAC \\
    ‘t IN measurable_sets m’ by METIS_TAC [SUBSET_DEF] \\
    ‘(f i j * m) t = A i t + B j t’ by METIS_TAC [] >> POP_ORW \\
     METIS_TAC [add_not_infty, lt_infty])
 (* applying MEASURE_SPACE_RESTRICTION *)
 >> martingale_alt_generator_shared_tactics_4
 (* subset_class *)
 >> Q.PAT_X_ASSUM ‘!n. semiring (m_space m,G n)’ (MP_TAC o (Q.SPEC ‘n’))
 >> rw [semiring_def]
QED

(* ------------------------------------------------------------------------- *)
(*  General version of martingales with poset indexes (Chapter 25 of [1])    *)
(* ------------------------------------------------------------------------- *)

Theorem POSET_NUM_LE :
    poset (univ(:num),$<=)
Proof
    RW_TAC std_ss [poset_def]
 >- (Q.EXISTS_TAC `0` >> REWRITE_TAC [GSYM IN_APP, IN_UNIV])
 >- (MATCH_MP_TAC LESS_EQUAL_ANTISYM >> art [])
 >> MATCH_MP_TAC LESS_EQ_TRANS
 >> Q.EXISTS_TAC `y` >> art []
QED

(* below J is an index set, R is a partial order on J *)
Definition general_filtration_def :
   general_filtration (J,R) A a =
     (poset (J,R) /\ (!n. n IN J ==> sub_sigma_algebra (a n) A) /\
      (!i j. i IN J /\ j IN J /\ R i j ==> subsets (a i) SUBSET subsets (a j)))
End

val _ = overload_on ("filtration", “general_filtration”);

Theorem filtration_alt_general : (* was: filtration_alt *)
    !A a. filtration A a = general_filtration (univ(:num),$<=) A a
Proof
    RW_TAC std_ss [filtration_def, general_filtration_def, POSET_NUM_LE, IN_UNIV]
QED

Definition general_filtered_measure_space_def :
    general_filtered_measure_space (J,R) (sp,sts,m) a =
      (measure_space (sp,sts,m) /\ general_filtration (J,R) (sp,sts) a)
End

val _ = overload_on ("filtered_measure_space", “general_filtered_measure_space”);

(* was: general_filtered_measure_space_alt *)
Theorem filtered_measure_space_alt_general :
    !sp sts m a. filtered_measure_space (sp,sts,m) a <=>
                 general_filtered_measure_space (univ(:num),$<=) (sp,sts,m) a
Proof
    RW_TAC std_ss [filtered_measure_space_def, general_filtered_measure_space_def,
                   filtration_alt_general, POSET_NUM_LE, IN_UNIV]
QED

Definition sigma_finite_general_filtered_measure_space_def :
    sigma_finite_general_filtered_measure_space (J,R) (sp,sts,m) a =
      (general_filtered_measure_space (J,R) (sp,sts,m) a /\
       !n. n IN J ==> sigma_finite (sp,subsets (a n),m))
End

val _ = overload_on ("sigma_finite_filtered_measure_space",
                     “sigma_finite_general_filtered_measure_space”);

(* was: sigma_finite_filtered_measure_space_alt *)
Theorem sigma_finite_filtered_measure_space_alt_general :
    !sp sts m a. sigma_finite_filtered_measure_space (sp,sts,m) a <=>
                 sigma_finite_general_filtered_measure_space (univ(:num),$<=) (sp,sts,m) a
Proof
    rw [sigma_finite_filtered_measure_space_alt_all, GSYM CONJ_ASSOC,
        sigma_finite_general_filtered_measure_space_def,
        GSYM filtered_measure_space_alt_general, filtered_measure_space_def]
QED

(* `general_martingale m a u (univ(:num),$<=) = martingale m a u`

   This is Definition 25.3 [1, p.301].
 *)
Definition general_martingale_def :
   general_martingale (J,R) m a u =
     (sigma_finite_general_filtered_measure_space (J,R) m a /\
      (!n. n IN J ==> integrable m (u n)) /\
      !i j s. i IN J /\ j IN J /\ R i j /\ s IN (subsets (a i)) ==>
             (integral m (\x. u i x * indicator_fn s x) =
              integral m (\x. u j x * indicator_fn s x)))
End

val _ = overload_on ("martingale", “general_martingale”);

(* or "upwards directed" *)
val upwards_filtering_def = Define
   `upwards_filtering (J,R) = !a b. a IN J /\ b IN J ==> ?c. c IN J /\ R a c /\ R b c`;

val _ = export_theory ();

(* References:

  [1] Schilling, R.L.: Measures, Integrals and Martingales (Second Edition).
      Cambridge University Press (2017).
  [2] Doob, J.L.: Stochastic processes. Wiley-Interscience (1990).
  [3] Doob, J.L.: What is a Martingale? Amer. Math. Monthly. 78(5), 451-463 (1971).
  [4] Pintacuda, N.: Probabilita'. Zanichelli, Bologna (1995).
  [5] Wikipedia: https://en.wikipedia.org/wiki/Leonida_Tonelli
  [6] Wikipedia: https://en.wikipedia.org/wiki/Guido_Fubini
 *)
