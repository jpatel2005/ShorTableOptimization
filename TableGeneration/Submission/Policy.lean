import TableGeneration.Policy

namespace TableGeneration.Submission.Policy

/-!
This is the editable submission entry point. Replace `implementation` with a
`GeneratorPolicy` for the targets handled by the submission; helper files may be
added as needed.
-/

/-- Replace this empty policy with the submitted implementation. -/
def implementation : TableGeneration.GeneratorPolicy :=
  .empty

end TableGeneration.Submission.Policy
