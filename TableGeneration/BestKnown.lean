import TableGeneration.Policy

namespace TableGeneration

open Operations

/-!
## Best-known generator

Accepted target-specific policies are selected here. The protected general
generator is the final fallback for every other `(mode, k)` pair.
-/

def bestKnownGeneratedPoints (mode : ProductMode) (k : Nat) : List Point :=
  baselineGeneratedPoints mode k

def bestKnownGeneratePointsInOrder
    (mode : ProductMode) (k : Nat) (hk : k >= 2) : List Point :=
  baselineGeneratePointsInOrder mode k hk

def bestKnownGenerate (mode : ProductMode) (k : Nat) (hk : k >= 2) : Prog k :=
  baselineGenerate mode k hk

def bestKnownPolicyId (_mode : ProductMode) (_k : Nat) : String :=
  "general"

end TableGeneration
