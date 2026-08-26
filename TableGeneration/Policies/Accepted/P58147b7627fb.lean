import TableGeneration.Policy

namespace TableGeneration.Policies.Accepted.P58147b7627fb

open Operations

/-!
Fixed, hand-optimized `k = 6` programs for both product modes.

The programs use a new eight-operation direct build for `V(2^e)` and
`V(-2^e)`.  The negative row is built from its even and odd halves first,
after which one scaled odd half is reused to obtain the positive row.  This
shortens the final return of each previous `k = 6` champion.  Every block
below is a fixed raw operation sequence; no general search or recursive
generator is used.
-/

def phaseProductK6Points : List Point :=
  [.int 0, .frac 0, .int 1, .int (-1),
   .int 2, .int (-2), .int 4, .int (-4),
   .int 8, .int (-8), .int 16]

def phaseTripleProductK6Points : List Point :=
  [.int 0, .frac 0, .int 1, .int (-1),
   .int 2, .int (-2), .int 4, .int (-4),
   .int 8, .int (-8), .int 16, .int (-16),
   .int 32, .int (-32), .int 64, .int (-64)]

def initialBuildK6 : Prog 6 :=
  [.addScaled 2 0 false 0,
   .addScaled 2 4 false 0,
   .addScaled 1 3 false 0,
   .addScaled 1 5 false 0,
   .addScaled 1 2 false 0,
   .shiftL 2 1,
   .addScaled 2 1 true 0]

def scaleStepK6E0 : Prog 6 :=
  [.addScaled 1 0 true 0,
   .addScaled 1 2 false 0,
   .addScaled 1 4 false 2,
   .shiftL 2 1,
   .addScaled 2 3 true 1,
   .addScaled 2 3 true 2,
   .addScaled 2 5 true 5,
   .addScaled 2 5 false 1,
   .addScaled 2 1 false 0,
   .shiftL 1 2,
   .addScaled 1 2 true 0,
   .addScaled 2 0 true 1,
   .addScaled 2 4 false 3]

def scaleStepK6E1 : Prog 6 :=
  [.addScaled 1 0 true 0,
   .addScaled 1 2 false 0,
   .addScaled 1 4 false 6,
   .shiftL 2 1,
   .addScaled 2 3 true 4,
   .addScaled 2 3 true 5,
   .addScaled 2 5 true 10,
   .addScaled 2 5 false 6,
   .addScaled 2 1 false 0,
   .shiftL 1 2,
   .addScaled 1 2 true 0,
   .addScaled 2 0 true 1,
   .addScaled 2 4 false 7]

def scaleStepK6E2 : Prog 6 :=
  [.addScaled 1 0 true 0,
   .addScaled 1 2 false 0,
   .addScaled 1 4 false 10,
   .shiftL 2 1,
   .addScaled 2 3 true 7,
   .addScaled 2 3 true 8,
   .addScaled 2 5 true 15,
   .addScaled 2 5 false 11,
   .addScaled 2 1 false 0,
   .shiftL 1 2,
   .addScaled 1 2 true 0,
   .addScaled 2 0 true 1,
   .addScaled 2 4 false 11]

def scaleStepK6E3 : Prog 6 :=
  [.addScaled 1 0 true 0,
   .addScaled 1 2 false 0,
   .addScaled 1 4 false 14,
   .shiftL 2 1,
   .addScaled 2 3 true 10,
   .addScaled 2 3 true 11,
   .addScaled 2 5 true 20,
   .addScaled 2 5 false 16,
   .addScaled 2 1 false 0,
   .shiftL 1 2,
   .addScaled 1 2 true 0,
   .addScaled 2 0 true 1,
   .addScaled 2 4 false 15]

def scaleStepK6E4 : Prog 6 :=
  [.addScaled 1 0 true 0,
   .addScaled 1 2 false 0,
   .addScaled 1 4 false 18,
   .shiftL 2 1,
   .addScaled 2 3 true 13,
   .addScaled 2 3 true 14,
   .addScaled 2 5 true 25,
   .addScaled 2 5 false 21,
   .addScaled 2 1 false 0,
   .shiftL 1 2,
   .addScaled 1 2 true 0,
   .addScaled 2 0 true 1,
   .addScaled 2 4 false 19]

def scaleStepK6E5 : Prog 6 :=
  [.addScaled 1 0 true 0,
   .addScaled 1 2 false 0,
   .addScaled 1 4 false 22,
   .shiftL 2 1,
   .addScaled 2 3 true 16,
   .addScaled 2 3 true 17,
   .addScaled 2 5 true 30,
   .addScaled 2 5 false 26,
   .addScaled 2 1 false 0,
   .shiftL 1 2,
   .addScaled 1 2 true 0,
   .addScaled 2 0 true 1,
   .addScaled 2 4 false 23]

/-- Eight raw operations build `V(8)` and `V(-8)` from the identity basis. -/
def finalBuildK6E3 : Prog 6 :=
  [.addScaled 1 3 false 6,
   .addScaled 1 5 false 12,
   .shiftL 2 6,
   .addScaled 2 1 true 3,
   .addScaled 2 0 false 0,
   .addScaled 2 4 false 12,
   .shiftL 1 4,
   .addScaled 1 2 false 0]

/-- Eight raw operations build `V(64)` and `V(-64)` from the identity basis. -/
def finalBuildK6E6 : Prog 6 :=
  [.addScaled 1 3 false 12,
   .addScaled 1 5 false 24,
   .shiftL 2 12,
   .addScaled 2 1 true 6,
   .addScaled 2 0 false 0,
   .addScaled 2 4 false 24,
   .shiftL 1 7,
   .addScaled 1 2 false 0]

def singleton16K6 : Prog 6 :=
  [.addScaled 0 1 false 4,
   .addScaled 0 2 false 8,
   .addScaled 0 3 false 12,
   .addScaled 0 4 false 16,
   .addScaled 0 5 false 20]

def phaseProductK6Program : Prog 6 :=
  initialBuildK6 ++
    [.phaseProduct 0, .phaseProduct 5, .phaseProduct 1, .phaseProduct 2] ++
    scaleStepK6E0 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStepK6E1 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStepK6E2 ++ [.phaseProduct 1, .phaseProduct 2] ++
    apply_Op_inverse finalBuildK6E3 ++
    singleton16K6 ++ [.phaseProduct 0] ++ apply_Op_inverse singleton16K6

def phaseTripleProductK6Program : Prog 6 :=
  initialBuildK6 ++
    [.phaseProduct 0, .phaseProduct 5, .phaseProduct 1, .phaseProduct 2] ++
    scaleStepK6E0 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStepK6E1 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStepK6E2 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStepK6E3 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStepK6E4 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStepK6E5 ++ [.phaseProduct 1, .phaseProduct 2] ++
    apply_Op_inverse finalBuildK6E6

def generatedPoints (mode : ProductMode) (k : Nat) : List Point :=
  if decide (k = 6) then
    match mode with
    | .PhaseProduct => phaseProductK6Points
    | .PhaseTripleProduct => phaseTripleProductK6Points
  else
    canonicalPoints mode k

def handles (_mode : ProductMode) (k : Nat) : Bool :=
  decide (k = 6)

def generatePointsInOrder
    (mode : ProductMode) (k : Nat) (_hk : k >= 2) : List Point :=
  generatedPoints mode k

def generate (mode : ProductMode) (k : Nat) (hk : k >= 2) : Prog k :=
  if h6 : k = 6 then
    match mode with
    | .PhaseProduct => h6.symm ▸ phaseProductK6Program
    | .PhaseTripleProduct => h6.symm ▸ phaseTripleProductK6Program
  else
    baselineGenerate mode k hk

theorem generatedPoints_valid
    (mode : ProductMode) (k : Nat) (_hk : k >= 2)
    (hhandles : handles mode k = true) :
    ValidPointList mode k (generatedPoints mode k) := by
  have h6 : k = 6 := by
    simpa [handles] using hhandles
  subst k
  cases mode <;> unfold ValidPointList generatedPoints <;> decide

set_option maxHeartbeats 10000000 in
set_option maxRecDepth 100000 in
theorem generate_safe
    (mode : ProductMode) (k : Nat) (hk : k >= 2)
    (hhandles : handles mode k = true) :
    ValidPointOrder (generatedPoints mode k) (generatePointsInOrder mode k hk) /\
      ProgConsumesPtsSafe (positive_of_ge_two hk) State.start_state
        (generate mode k hk) (generatePointsInOrder mode k hk) := by
  have h6 : k = 6 := by
    simpa [handles] using hhandles
  subst k
  have hhk : hk = (by decide : 6 >= 2) := Subsingleton.elim _ _
  subst hk
  constructor
  · exact List.Perm.refl _
  · cases mode <;> apply progConsumesPtsSafe_of_checks <;> decide

def implementation : GeneratorPolicy where
  generatedPoints := generatedPoints
  handles := handles
  generatePointsInOrder := generatePointsInOrder
  generate := generate
  generatedPoints_valid := generatedPoints_valid
  generate_safe := generate_safe

end TableGeneration.Policies.Accepted.P58147b7627fb
