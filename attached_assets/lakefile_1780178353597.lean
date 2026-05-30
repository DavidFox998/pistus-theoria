import Lake
open Lake DSL

package «TheoremaAureum» where
  name := "TheoremaAureum"
  version := "0.1.0"

require mathlib from git
  "https://github.com/leanprover-community/mathlib4" @ "v4.14.0"

@[default_target]
lean_lib «TheoremaAureum» where
  globs := #[.andSubmodules `TheoremaAureum]

lean_lib «Main» where
  globs := #[.submodules `TheoremaAureum]
