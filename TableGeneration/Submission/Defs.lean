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
  canonicalPoints mode k

/- Return true exactly for the cases implemented by this submission.
   The default handles no scored cases. -/
def submissionHandles (_mode : ProductMode) (_k : Nat) : Bool :=
  false

/- Give the order in which the generated points are consumed. -/
def submissionGeneratePointsInOrder
    (mode : ProductMode) (k : Nat) (_hk : k >= 2) : List Point :=
  generatedPoints mode k

/- Generate the program for handled cases. -/
def submissionGenerate (mode : ProductMode) (k : Nat) (hk : k >= 2) : Prog k :=
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
