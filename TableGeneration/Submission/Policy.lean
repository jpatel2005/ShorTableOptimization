import TableGeneration.Policy

namespace TableGeneration.Submission.Policy

open Operations

/-!
Fixed hand-derived programs for both product modes at `k = 7, ..., 16`.

The point stream is all-integral: `0`, infinity, and the pairs
`±1, ±2, ±4, ...`.  Registers one and two carry the current pair.  The even
rows beginning at register four form a short Gaussian reservoir.  A pair
transition injects its first row twice, which supplies every even-column
correction at once.  The triangular reservoir links are advanced only while
they can still affect a future point row; their fixed staggered return word is
what makes each of the twenty handled cells a strict improvement.

The five small link tables below completely specialize this construction to
the handled range.  There is no optimization procedure in this submission.
-/

/-- Register selection used only under the positive-width submission API. -/
def reg (k : Nat) (hk : 0 < k) (i : Nat) : Fin k :=
  ⟨i % k, Nat.mod_lt i hk⟩

def oddDegrees (k : Nat) : List Nat :=
  (List.range k).filter fun d => decide (3 ≤ d ∧ d % 2 = 1)

def evenDegrees (k : Nat) : List Nat :=
  (List.range k).filter fun d => decide (4 ≤ d ∧ d % 2 = 0)

def helperCount (k : Nat) : Nat :=
  (k - 3) / 2

abbrev LinkWord := List (Nat × Nat)

/-- Fixed adjacent-link factorizations of the Gaussian helper matrices. -/
def gaussianWord : Nat → LinkWord
  | 2 => [(0, 1), (0, 0)]
  | 3 => [(0, 1), (1, 1), (1, 2), (1, 0), (0, 0)]
  | 4 =>
      [(2, 0), (1, 0), (0, 1), (2, 1), (1, 2),
       (0, 0), (2, 3), (1, 1), (2, 2)]
  | 5 =>
      [(3, 0), (2, 0), (3, 1), (1, 0), (2, 1),
       (0, 0), (1, 1), (3, 2), (0, 1), (2, 2),
       (3, 3), (1, 2), (2, 3), (3, 4)]
  | 6 =>
      [(4, 0), (3, 0), (4, 1), (2, 0), (3, 1),
       (1, 0), (2, 1), (0, 1), (4, 2), (1, 2),
       (0, 0), (3, 2), (4, 3), (2, 3), (3, 4),
       (4, 5), (1, 1), (2, 2), (3, 3), (4, 4)]
  | _ => []

/--
Fixed teardown factorizations.  The second component is how many scale
levels behind the final exponent that occurrence of the link remains.
-/
def staggeredWord : Nat → LinkWord
  | 2 => [(0, 0), (0, 1)]
  | 3 => [(1, 0), (0, 0), (1, 1), (0, 1), (1, 2)]
  | 4 =>
      [(2, 0), (1, 0), (2, 1), (0, 0), (1, 1),
       (0, 1), (2, 2), (1, 2), (2, 3)]
  | 5 =>
      [(3, 0), (2, 0), (3, 1), (1, 0), (2, 1),
       (3, 2), (0, 0), (1, 1), (0, 1), (2, 2),
       (1, 2), (3, 3), (2, 3), (3, 4)]
  | 6 =>
      [(4, 0), (3, 0), (4, 1), (2, 0), (3, 1),
       (4, 2), (1, 0), (2, 1), (3, 2), (4, 3),
       (0, 0), (1, 1), (0, 1), (2, 2), (1, 2),
       (3, 3), (2, 3), (4, 4), (3, 4), (4, 5)]
  | _ => []

def appendInitialEven
    (k : Nat) (hk : 0 < k) (j : Fin k) : Prog k :=
  let r2 := reg k hk 2
  if j.val % 2 = 0 ∧ j ≠ r2 then
    [.addScaled r2 j false 0]
  else
    []

def appendInitialOdd
    (k : Nat) (hk : 0 < k) (j : Fin k) : Prog k :=
  let r1 := reg k hk 1
  if j.val % 2 = 1 ∧ j ≠ r1 then
    [.addScaled r1 j false 0]
  else
    []

def initialBuild (k : Nat) (hk : 0 < k) : Prog k :=
  let r1 := reg k hk 1
  let r2 := reg k hk 2
  (List.finRange k).flatMap (appendInitialEven k hk) ++
    (List.finRange k).flatMap (appendInitialOdd k hk) ++
    [.addScaled r1 r2 false 0,
     .shiftL r2 1,
     .addScaled r2 r1 true 0]

def reservoirBuild (k : Nat) (hk : 0 < k) (e : Nat) : Prog k :=
  (gaussianWord (helperCount k)).map fun link =>
    .addScaled (reg k hk (4 + 2 * link.1))
      (reg k hk (6 + 2 * link.1)) false (2 * (e + link.2))

def reservoirBuildStaggered
    (k : Nat) (hk : 0 < k) (finalE : Nat) : Prog k :=
  (staggeredWord (helperCount k)).map fun link =>
    .addScaled (reg k hk (4 + 2 * link.1))
      (reg k hk (6 + 2 * link.1)) false (2 * (finalE - link.2))

def oddCorrections (k : Nat) (hk : 0 < k) (e : Nat) : Prog k :=
  let r2 := reg k hk 2
  (oddDegrees k).flatMap fun degree =>
    [.addScaled r2 (reg k hk degree) false (e * degree + 1),
     .addScaled r2 (reg k hk degree) true (e * degree + degree)]

def liveHelperUpdates
    (k : Nat) (hk : 0 < k) (e futureEdges : Nat) : Prog k :=
  let live := Nat.min (helperCount k - 1) futureEdges
  (List.range live).flatMap fun link =>
    [.addScaled (reg k hk (4 + 2 * link))
        (reg k hk (6 + 2 * link)) false (2 * e + 2 * (link + 2)),
     .addScaled (reg k hk (4 + 2 * link))
        (reg k hk (6 + 2 * link)) true (2 * e)]

def reservoirScaleStep
    (k : Nat) (hk : 0 < k) (e futureEdges : Nat) : Prog k :=
  let r0 := reg k hk 0
  let r1 := reg k hk 1
  let r2 := reg k hk 2
  let r4 := reg k hk 4
  [.addScaled r1 r0 true 0,
   .addScaled r1 r2 false 0,
   .addScaled r1 r4 false (4 * e + 2),
   .shiftL r2 1] ++
    oddCorrections k hk e ++
    [.addScaled r2 r1 false 0,
     .shiftL r1 2,
     .addScaled r1 r2 true 0,
     .addScaled r2 r0 true 1,
     .addScaled r2 r4 false (4 * e + 3)] ++
    liveHelperUpdates k hk e futureEdges

def middleFinalBuild (k : Nat) (hk : 0 < k) (e : Nat) : Prog k :=
  let r0 := reg k hk 0
  let r1 := reg k hk 1
  let r2 := reg k hk 2
  (oddDegrees k).map (fun degree =>
      .addScaled r1 (reg k hk degree) false (e * (degree - 1))) ++
    [.shiftL r2 (2 * e),
     .addScaled r2 r1 true e,
     .addScaled r2 r0 false 0] ++
    (evenDegrees k).map (fun degree =>
      .addScaled r2 (reg k hk degree) false (e * degree)) ++
    [.shiftL r1 (e + 1),
     .addScaled r1 r2 false 0]

def singletonBlock (k : Nat) (hk : 0 < k) (e : Nat) : Prog k :=
  let r0 := reg k hk 0
  let build := (List.finRange k).flatMap fun j =>
    if j = r0 then [] else [.addScaled r0 j false (e * j.val)]
  build ++ [.phaseProduct r0] ++ apply_Op_inverse build

def pairCount (mode : ProductMode) (k : Nat) : Nat :=
  (mode.pointCount k - 4) / 2

def hasSingleton (mode : ProductMode) (k : Nat) : Bool :=
  decide ((mode.pointCount k - 4) % 2 = 1)

def pairPoints (n : Nat) : List Point :=
  (List.range n).flatMap fun e =>
    let z : Int := (2 : Int) ^ (e + 1)
    [.int z, .int (-z)]

def candidatePoints (mode : ProductMode) (k : Nat) : List Point :=
  let n := pairCount mode k
  [.int 0, .frac 0, .int 1, .int (-1)] ++ pairPoints n ++
    if hasSingleton mode k then
      [.int ((2 : Int) ^ (n + 1))]
    else
      []

def scaleBlocks
    (mode : ProductMode) (k : Nat) (hk : 0 < k) : Prog k :=
  let n := pairCount mode k
  let r1 := reg k hk 1
  let r2 := reg k hk 2
  (List.range n).flatMap fun e =>
    reservoirScaleStep k hk e (n - (e + 1)) ++
      [.phaseProduct r1, .phaseProduct r2]

def candidateProgram
    (mode : ProductMode) (k : Nat) (hk : 0 < k) : Prog k :=
  let n := pairCount mode k
  let r0 := reg k hk 0
  let r1 := reg k hk 1
  let r2 := reg k hk 2
  initialBuild k hk ++
    [.phaseProduct r0, .phaseProduct (finLast hk),
     .phaseProduct r1, .phaseProduct r2] ++
    reservoirBuild k hk 0 ++
    scaleBlocks mode k hk ++
    apply_Op_inverse (reservoirBuildStaggered k hk n) ++
    apply_Op_inverse (middleFinalBuild k hk n) ++
    if hasSingleton mode k then singletonBlock k hk (n + 1) else []

def scoredK (k : Nat) : Bool :=
  decide (k = 7) || (decide (k = 8) || (decide (k = 9) ||
    (decide (k = 10) || (decide (k = 11) || (decide (k = 12) ||
    (decide (k = 13) || (decide (k = 14) ||
    (decide (k = 15) || decide (k = 16)))))))))

def generatedPoints (mode : ProductMode) (k : Nat) : List Point :=
  if scoredK k then candidatePoints mode k else canonicalPoints mode k

def generatePointsInOrder
    (mode : ProductMode) (k : Nat) (_hk : k >= 2) : List Point :=
  generatedPoints mode k

def generate (mode : ProductMode) (k : Nat) (hk : k >= 2) : Prog k :=
  if scoredK k then
    candidateProgram mode k (positive_of_ge_two hk)
  else
    baselineGenerate mode k hk

/-- Kernel checks bundled into the handled-target predicate. -/
def generalChecks (mode : ProductMode) (k : Nat) : Bool :=
  if hk : k >= 2 then
    decide ((generatedPoints mode k).length = mode.pointCount k) &&
      (decide ((generatedPoints mode k).map normalizePoint).Nodup &&
        ((generatedPoints mode k).all validPoint? &&
          (progConsumesPts? (positive_of_ge_two hk) State.start_state
              (generate mode k hk) (generatedPoints mode k) &&
            (safeProg? (generate mode k hk) &&
              returnsToStartCheck (generate mode k hk) State.start_state))))
  else
    false

def handles (_mode : ProductMode) (k : Nat) : Bool :=
  scoredK k

theorem scoredK_cases {k : Nat} (h : scoredK k = true) :
    k = 7 ∨ k = 8 ∨ k = 9 ∨ k = 10 ∨ k = 11 ∨ k = 12 ∨
      k = 13 ∨ k = 14 ∨ k = 15 ∨ k = 16 := by
  simpa [scoredK, Bool.or_eq_true, decide_eq_true_eq] using h

set_option exponentiation.threshold 512 in
set_option maxHeartbeats 1000000000 in
set_option maxRecDepth 100000 in
theorem generalChecks_scored
    (mode : ProductMode) (k : Nat) (h : scoredK k = true) :
    generalChecks mode k = true := by
  rcases scoredK_cases h with h | h | h | h | h | h | h | h | h | h
  all_goals subst k
  all_goals cases mode <;> decide

theorem checks_of_generalChecks
    (mode : ProductMode) (k : Nat) (hk : k >= 2)
    (hchecks : generalChecks mode k = true) :
    ValidPointList mode k (generatedPoints mode k) /\
      (progConsumesPts? (positive_of_ge_two hk) State.start_state
          (generate mode k hk) (generatedPoints mode k) = true /\
        (safeProg? (generate mode k hk) = true /\
          returnsToStartCheck (generate mode k hk) State.start_state = true)) := by
  unfold generalChecks at hchecks
  rw [dif_pos hk] at hchecks
  rcases Bool.and_eq_true_iff.mp hchecks with ⟨hlength, hrest⟩
  rcases Bool.and_eq_true_iff.mp hrest with ⟨hnodup, hrest⟩
  rcases Bool.and_eq_true_iff.mp hrest with ⟨hpoints, hrest⟩
  rcases Bool.and_eq_true_iff.mp hrest with ⟨hconsumes, hrest⟩
  rcases Bool.and_eq_true_iff.mp hrest with ⟨hsafe, hreturns⟩
  exact ⟨⟨of_decide_eq_true hlength, of_decide_eq_true hnodup, hpoints⟩,
    hconsumes, hsafe, hreturns⟩

theorem generatedPoints_valid
    (mode : ProductMode) (k : Nat) (hk : k >= 2)
    (hhandles : handles mode k = true) :
    ValidPointList mode k (generatedPoints mode k) := by
  have hchecks : generalChecks mode k = true :=
    generalChecks_scored mode k hhandles
  exact (checks_of_generalChecks mode k hk hchecks).1

theorem generate_safe
    (mode : ProductMode) (k : Nat) (hk : k >= 2)
    (hhandles : handles mode k = true) :
    ValidPointOrder (generatedPoints mode k) (generatePointsInOrder mode k hk) /\
      ProgConsumesPtsSafe (positive_of_ge_two hk) State.start_state
        (generate mode k hk) (generatePointsInOrder mode k hk) := by
  have hchecks : generalChecks mode k = true :=
    generalChecks_scored mode k hhandles
  rcases checks_of_generalChecks mode k hk hchecks with
    ⟨_, hconsumes, hsafe, hreturns⟩
  constructor
  · exact List.Perm.refl _
  · exact progConsumesPtsSafe_of_checks hconsumes hsafe hreturns

def implementation : GeneratorPolicy where
  generatedPoints := generatedPoints
  handles := handles
  generatePointsInOrder := generatePointsInOrder
  generate := generate
  generatedPoints_valid := generatedPoints_valid
  generate_safe := generate_safe

end TableGeneration.Submission.Policy
