import Lake
open Lake DSL
package «theorema-aureum» where
-- The structural / axiom-debt verification in TheoremaAureum/*.lean carries
-- no Mathlib imports, so the standard `lake build` + `lake env lean Verify.lean`
-- pipeline does not need Mathlib at all. To run the *full semantic* build
-- (with real `riemannZeta` / `riemannXi` from Mathlib) uncomment the require
-- below and then `lake exe cache get && lake build` (~2 GB prebuilt oleans).
-- require mathlib from git "https://github.com/leanprover-community/mathlib4.git" @ "v4.12.0"
@[default_target]
lean_lib TheoremaAureum where

-- Note: the opt-in Towers build (mathlib-backed first bricks for RH /
-- Yang-Mills / Navier-Stokes) intentionally lives in a SIBLING package
-- at `lean-proof-towers/`, not as a second target here. Adding
-- `require mathlib` to this lakefile forces `lake update` before any
-- `lake build` (even of TheoremaAureum), which would couple the fast
-- spine drift guard (`scripts/check-lean-proof.sh`) to a ~2 GB mathlib
-- fetch. Keeping the Towers package in a sibling directory means the
-- fast workflow continues to build in seconds without mathlib, while
-- `scripts/check-towers.sh` builds the Towers package independently.
