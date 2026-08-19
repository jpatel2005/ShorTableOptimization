import TableGeneration.Submission.Defs

namespace TableGeneration

/- For handled cases, the generated point list has the required size and valid points. -/
theorem generatedPoints_valid
    (mode : ProductMode) (k : Nat) (_ : k >= 2)
    (_hhandles : submissionHandles mode k = true) :
    ValidPointList mode k (generatedPoints mode k) := by
  sorry

/- For handled cases, the generated program consumes the generated points and returns to start. -/
theorem generate_ProgConsumesPtsSafe
    (mode : ProductMode) (k : Nat) (hk : k >= 2)
    (_hhandles : submissionHandles mode k = true) :
    ValidPointOrder (generatedPoints mode k) (generatePointsInOrder mode k hk) /\
      ProgConsumesPtsSafe (positive_of_ge_two hk) State.start_state
        (generate mode k hk) (generatePointsInOrder mode k hk) := by
  sorry

end TableGeneration
