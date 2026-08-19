import TableGeneration.Baseline

namespace TableGeneration

open Operations

/-!
## Submission Implementation

Edit the four definitions in this section for your submission.
-/

section SubmissionImplementation

/- Fill in the table points for each handled product mode and k.
   The default canonical list is only a starting point, not a requirement. -/
def generatedPoints (mode : ProductMode) (k : Nat) : List Point :=
  if decide (mode = .PhaseTripleProduct ∧ k = 4) then
    [.int 0, .frac 0, .int 1, .int (-1), .int 2,
      .int (-2), .int 4, .int (-4), .int 8, .int (-8)]
  else
    canonicalPoints mode k

/- Return true exactly for the cases implemented by this submission.
   The default handles no scored cases. -/
def submissionHandles (mode : ProductMode) (k : Nat) : Bool :=
  decide (mode = .PhaseTripleProduct ∧ k = 4)

/- Give the order in which the generated points are consumed. -/
def submissionGeneratePointsInOrder
    (mode : ProductMode) (k : Nat) (_hk : k >= 2) : List Point :=
  generatedPoints mode k

/- Generate the program for handled cases. -/
def submissionGenerate (mode : ProductMode) (k : Nat) (hk : k >= 2) : Prog k :=
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

end SubmissionImplementation

/-!
## Verifier Entry Points

Do not edit these wrappers. Put custom submission logic in the section above.
-/

section VerifierEntryPoints

/- Unhandled cases use the protected baseline point order. -/
def generatePointsInOrder (mode : ProductMode) (k : Nat) (hk : k >= 2) : List Point :=
  if submissionHandles mode k then
    submissionGeneratePointsInOrder mode k hk
  else
    baselineGeneratePointsInOrder mode k hk

/- Unhandled cases use the protected baseline program. -/
def generate (mode : ProductMode) (k : Nat) (hk : k >= 2) : Prog k :=
  if submissionHandles mode k then
    submissionGenerate mode k hk
  else
    baselineGenerate mode k hk

end VerifierEntryPoints

end TableGeneration
