import TableGeneration.BestKnown
import TableGeneration.Submission.Policy

namespace TableGeneration

open Operations

/-!
## Submission Implementation

These fixed adapters expose the portable submitted policy.
-/

section SubmissionImplementation

/- Fill in the table points for each handled product mode and k.
   The default canonical list is only a starting point, not a requirement. -/
def generatedPoints (mode : ProductMode) (k : Nat) : List Point :=
  Submission.Policy.implementation.generatedPoints mode k

/- Return true exactly for the cases implemented by this submission.
   The default handles no scored cases. -/
def submissionHandles (mode : ProductMode) (k : Nat) : Bool :=
  Submission.Policy.implementation.handles mode k

/- Give the order in which the generated points are consumed. -/
def submissionGeneratePointsInOrder
    (mode : ProductMode) (k : Nat) (hk : k >= 2) : List Point :=
  Submission.Policy.implementation.generatePointsInOrder mode k hk

/- Generate the program for handled cases. -/
def submissionGenerate (mode : ProductMode) (k : Nat) (hk : k >= 2) : Prog k :=
  Submission.Policy.implementation.generate mode k hk

end SubmissionImplementation

/-!
## Verifier Entry Points

Do not edit these wrappers. Put custom submission logic in the section above.
-/

section VerifierEntryPoints

/- Unhandled cases use the protected best-known point order. -/
def generatePointsInOrder (mode : ProductMode) (k : Nat) (hk : k >= 2) : List Point :=
  if submissionHandles mode k then
    submissionGeneratePointsInOrder mode k hk
  else
    bestKnownGeneratePointsInOrder mode k hk

/- Unhandled cases use the protected best-known program. -/
def generate (mode : ProductMode) (k : Nat) (hk : k >= 2) : Prog k :=
  if submissionHandles mode k then
    submissionGenerate mode k hk
  else
    bestKnownGenerate mode k hk

end VerifierEntryPoints

end TableGeneration
