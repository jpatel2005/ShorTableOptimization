import TableGeneration.Policy

namespace TableGeneration.Policies.Accepted.P2a0c1db7342f

open Operations

/-!
Fixed, hand-optimized `k = 5` programs for both product modes.

The programs share the usual all-integer trajectory through `±1`, `±2`, ...,
but use a seven-operation final build.  The negative row is built first; an
early column-three injection then contributes with opposite signs to the two
final rows.  This saves one arithmetic operation over the previous fixed
`k = 5` programs.  No general search or recursive generator is used here.
-/

def phaseProductK5Points : List Point :=
  [.int 0, .frac 0, .int 1, .int (-1),
   .int 2, .int (-2), .int 4, .int (-4), .int 8]

def phaseTripleProductK5Points : List Point :=
  [.int 0, .frac 0, .int 1, .int (-1),
   .int 2, .int (-2), .int 4, .int (-4),
   .int 8, .int (-8), .int 16, .int (-16), .int 32]

def initialBuild : Prog 5 :=
  [.addScaled 2 0 false 0,
   .addScaled 2 4 false 0,
   .addScaled 1 3 false 0,
   .addScaled 1 2 false 0,
   .shiftL 2 1,
   .addScaled 2 1 true 0]

def scaleStep0 : Prog 5 :=
  [.addScaled 1 0 true 0,
   .addScaled 1 2 false 0,
   .addScaled 1 4 false 2,
   .shiftL 2 1,
   .addScaled 2 3 true 1,
   .addScaled 2 3 true 2,
   .addScaled 2 1 false 0,
   .shiftL 1 2,
   .addScaled 1 2 true 0,
   .addScaled 2 0 true 1,
   .addScaled 2 4 false 3]

def scaleStep1 : Prog 5 :=
  [.addScaled 1 0 true 0,
   .addScaled 1 2 false 0,
   .addScaled 1 4 false 6,
   .shiftL 2 1,
   .addScaled 2 3 true 4,
   .addScaled 2 3 true 5,
   .addScaled 2 1 false 0,
   .shiftL 1 2,
   .addScaled 1 2 true 0,
   .addScaled 2 0 true 1,
   .addScaled 2 4 false 7]

def scaleStep2 : Prog 5 :=
  [.addScaled 1 0 true 0,
   .addScaled 1 2 false 0,
   .addScaled 1 4 false 10,
   .shiftL 2 1,
   .addScaled 2 3 true 7,
   .addScaled 2 3 true 8,
   .addScaled 2 1 false 0,
   .shiftL 1 2,
   .addScaled 1 2 true 0,
   .addScaled 2 0 true 1,
   .addScaled 2 4 false 11]

def scaleStep3 : Prog 5 :=
  [.addScaled 1 0 true 0,
   .addScaled 1 2 false 0,
   .addScaled 1 4 false 14,
   .shiftL 2 1,
   .addScaled 2 3 true 10,
   .addScaled 2 3 true 11,
   .addScaled 2 1 false 0,
   .shiftL 1 2,
   .addScaled 1 2 true 0,
   .addScaled 2 0 true 1,
   .addScaled 2 4 false 15]

/-- Seven raw operations build `V(4)` and `V(-4)` from the identity basis. -/
def finalBuild4 : Prog 5 :=
  [.shiftL 2 4,
   .addScaled 1 3 false 4,
   .addScaled 2 1 true 2,
   .addScaled 2 0 false 0,
   .addScaled 2 4 false 8,
   .shiftL 1 3,
   .addScaled 1 2 false 0]

/-- Seven raw operations build `V(16)` and `V(-16)` from the identity basis. -/
def finalBuild16 : Prog 5 :=
  [.shiftL 2 8,
   .addScaled 1 3 false 8,
   .addScaled 2 1 true 4,
   .addScaled 2 0 false 0,
   .addScaled 2 4 false 16,
   .shiftL 1 5,
   .addScaled 1 2 false 0]

def singleton8 : Prog 5 :=
  [.addScaled 0 1 false 3,
   .addScaled 0 2 false 6,
   .addScaled 0 3 false 9,
   .addScaled 0 4 false 12]

def singleton32 : Prog 5 :=
  [.addScaled 0 1 false 5,
   .addScaled 0 2 false 10,
   .addScaled 0 3 false 15,
   .addScaled 0 4 false 20]

def phaseProductK5Program : Prog 5 :=
  initialBuild ++
    [.phaseProduct 0, .phaseProduct 4, .phaseProduct 1, .phaseProduct 2] ++
    scaleStep0 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStep1 ++ [.phaseProduct 1, .phaseProduct 2] ++
    apply_Op_inverse finalBuild4 ++
    singleton8 ++ [.phaseProduct 0] ++ apply_Op_inverse singleton8

def phaseTripleProductK5Program : Prog 5 :=
  initialBuild ++
    [.phaseProduct 0, .phaseProduct 4, .phaseProduct 1, .phaseProduct 2] ++
    scaleStep0 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStep1 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStep2 ++ [.phaseProduct 1, .phaseProduct 2] ++
    scaleStep3 ++ [.phaseProduct 1, .phaseProduct 2] ++
    apply_Op_inverse finalBuild16 ++
    singleton32 ++ [.phaseProduct 0] ++ apply_Op_inverse singleton32

def generatedPoints (mode : ProductMode) (k : Nat) : List Point :=
  if decide (k = 5) then
    match mode with
    | .PhaseProduct => phaseProductK5Points
    | .PhaseTripleProduct => phaseTripleProductK5Points
  else
    canonicalPoints mode k

def handles (_mode : ProductMode) (k : Nat) : Bool :=
  decide (k = 5)

def generatePointsInOrder
    (mode : ProductMode) (k : Nat) (_hk : k >= 2) : List Point :=
  generatedPoints mode k

def generate (mode : ProductMode) (k : Nat) (hk : k >= 2) : Prog k :=
  if h5 : k = 5 then
    match mode with
    | .PhaseProduct => h5.symm ▸ phaseProductK5Program
    | .PhaseTripleProduct => h5.symm ▸ phaseTripleProductK5Program
  else
    baselineGenerate mode k hk

theorem generatedPoints_valid
    (mode : ProductMode) (k : Nat) (_hk : k >= 2)
    (hhandles : handles mode k = true) :
    ValidPointList mode k (generatedPoints mode k) := by
  have h5 : k = 5 := by
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
  have h5 : k = 5 := by
    simpa [handles] using hhandles
  subst k
  have hhk : hk = (by decide : 5 >= 2) := Subsingleton.elim _ _
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

end TableGeneration.Policies.Accepted.P2a0c1db7342f
