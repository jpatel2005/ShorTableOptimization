import Lake
open Lake DSL

package ShorTableOptimization where

@[default_target]
lean_lib TableGeneration where
  moreLeanArgs := #["-s", "1048576"]
