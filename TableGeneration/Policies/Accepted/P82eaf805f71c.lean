import TableGeneration.Policy

namespace TableGeneration.Policies.Accepted.P82eaf805f71c

open Operations

def generatedPoints (mode : ProductMode) (k : Nat) : List Point :=
  if decide (mode = .PhaseTripleProduct ∧ k = 4) then
    [.int 0, .frac 0, .int 1, .int (-1), .int 2,
      .int (-2), .int 4, .int (-4), .int 8, .int (-8)]
  else
    canonicalPoints mode k

def handles (mode : ProductMode) (k : Nat) : Bool :=
  decide (mode = .PhaseTripleProduct ∧ k = 4)

def generatePointsInOrder
    (mode : ProductMode) (k : Nat) (_hk : k >= 2) : List Point :=
  generatedPoints mode k

def generate (mode : ProductMode) (k : Nat) (hk : k >= 2) : Prog k :=
  if htarget : mode = .PhaseTripleProduct ∧ k = 4 then
    let r0 : Fin 4 := ⟨0, by decide⟩
    let r1 : Fin 4 := ⟨1, by decide⟩
    let r2 : Fin 4 := ⟨2, by decide⟩
    let r3 : Fin 4 := ⟨3, by decide⟩
    let initialBuild : Prog 4 :=
      [.addScaled r1 r3 false 0,
        .addScaled r2 r0 false 0,
        .addScaled r1 r2 false 0,
        .shiftL r2 1,
        .addScaled r2 r1 true 0]
    let scaleStep (dShift : Nat) : Prog 4 :=
      [.addScaled r1 r0 true 0,
        .addScaled r1 r2 false 0,
        .shiftL r2 1,
        .addScaled r2 r3 true dShift,
        .addScaled r2 r3 true (dShift + 1),
        .addScaled r2 r1 false 0,
        .shiftL r1 2,
        .addScaled r1 r2 true 0,
        .addScaled r2 r0 true 1]
    let finalBuild : Prog 4 :=
      [.shiftL r1 3,
        .shiftL r2 6,
        .addScaled r1 r3 false 9,
        .addScaled r2 r0 false 0,
        .addScaled r1 r2 false 0,
        .shiftL r2 1,
        .addScaled r2 r1 true 0]
    let targetProgram : Prog 4 :=
      initialBuild ++
        [.phaseProduct r0, .phaseProduct r3, .phaseProduct r1, .phaseProduct r2] ++
        scaleStep 1 ++ [.phaseProduct r1, .phaseProduct r2] ++
        scaleStep 4 ++ [.phaseProduct r1, .phaseProduct r2] ++
        scaleStep 7 ++ [.phaseProduct r1, .phaseProduct r2] ++
        apply_Op_inverse finalBuild
    htarget.2.symm ▸ targetProgram
  else
    baselineGenerate mode k hk

theorem generatedPoints_valid
    (mode : ProductMode) (k : Nat) (_hk : k >= 2)
    (hhandles : handles mode k = true) :
    ValidPointList mode k (generatedPoints mode k) := by
  have htarget : mode = .PhaseTripleProduct ∧ k = 4 :=
    of_decide_eq_true hhandles
  rcases htarget with ⟨rfl, rfl⟩
  unfold ValidPointList
  decide

theorem generate_safe
    (mode : ProductMode) (k : Nat) (hk : k >= 2)
    (hhandles : handles mode k = true) :
    ValidPointOrder (generatedPoints mode k) (generatePointsInOrder mode k hk) /\
      ProgConsumesPtsSafe (positive_of_ge_two hk) State.start_state
        (generate mode k hk) (generatePointsInOrder mode k hk) := by
  have htarget : mode = .PhaseTripleProduct ∧ k = 4 :=
    of_decide_eq_true hhandles
  rcases htarget with ⟨rfl, rfl⟩
  have hhk : hk = (by decide : 4 >= 2) := Subsingleton.elim _ _
  subst hk
  constructor
  · exact List.Perm.refl _
  · apply progConsumesPtsSafe_of_checks <;> decide

def implementation : GeneratorPolicy where
  generatedPoints := generatedPoints
  handles := handles
  generatePointsInOrder := generatePointsInOrder
  generate := generate
  generatedPoints_valid := generatedPoints_valid
  generate_safe := generate_safe

end TableGeneration.Policies.Accepted.P82eaf805f71c
