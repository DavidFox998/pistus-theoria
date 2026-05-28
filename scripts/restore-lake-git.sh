#!/usr/bin/env bash
# restore-lake-git.sh — Rehydrate the `.git/` directory of every
# vendored Lake dependency under
# `lean-proof-towers/.lake/packages/<pkg>/` from a small committed
# tar archive at `lean-proof-towers/lake-deps/<pkg>.git.tar`.
#
# Why this exists (Task #76, follow-up to Task #66):
#
# The Lake packages (mathlib, batteries, aesop, Qq, proofwidgets,
# importGraph, LeanSearchClient, Cli) need to be real git checkouts
# at the manifest-pinned revisions so that `lake update` and
# `lake exe cache get` can run safely without re-cloning everything
# from scratch. But the outer repo cannot directly commit nested
# `.git/` directories — git treats them as submodule boundaries and
# silently skips them on `git add`. The whole `.lake/` tree is also
# gitignored on top of that. So a snapshot can never carry the
# `.lake/packages/<pkg>/.git/` directories along.
#
# Workaround: each `.git/` is bundled as a single `<pkg>.git.tar`
# under `lean-proof-towers/lake-deps/` (a regular tracked
# directory). At restore time we extract the tar back into
# `.lake/packages/<pkg>/.git/`. Git bundles were rejected because
# the shallow single-commit fetch we use to build them references
# a parent SHA we don't have, which makes both `git fetch
# <bundle> …` and `git clone <bundle>` fail with "Failed to
# traverse parents of commit". A raw tar of `.git/` sidesteps
# git's commit-graph traversal entirely. Total tarball weight is
# ~20 MB (mathlib alone is ~18 MB, every other dep is under 1 MB).
#
# Restore procedure per package:
#   1. If `.git/` already exists and `HEAD` resolves to the
#      manifest-pinned rev, do nothing.
#   2. Otherwise: `rm -rf .git`, `tar -xf <pkg>.git.tar -C <pkg>`,
#      then verify `git rev-parse HEAD` matches the pinned rev.
#
# Idempotent. Safe to call from `scripts/check-towers.sh`,
# `scripts/post-merge.sh`, CI, or by hand.
#
# Hard failure modes (exit non-zero):
#   - `git` or `tar` not on PATH
#   - a tar file is missing for a package whose working tree exists
#   - after restore, `git rev-parse HEAD` does not match the
#     manifest-pinned rev

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES_DIR="$REPO_ROOT/lean-proof-towers/.lake/packages"
TARS_DIR="$REPO_ROOT/lean-proof-towers/lake-deps"

for tool in git tar; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "restore-lake-git: error: \`$tool\` not on PATH." >&2
    exit 127
  fi
done

# (name, url, manifest-pinned rev) — must stay in lock-step with
# `lean-proof-towers/lake-manifest.json`. If the manifest pins a new
# rev, regenerate the matching tar (see comment block at the bottom
# of this file) and update the entry here.
PKGS=(
  "batteries|https://github.com/leanprover-community/batteries|4756e0fc48acce0cc808df0ad149de5973240df6"
  "Qq|https://github.com/leanprover-community/quote4|2c8ae451ce9ffc83554322b14437159c1a9703f9"
  "aesop|https://github.com/leanprover-community/aesop|28fa80508edc97d96ed6342c9a771a67189e0baa"
  "proofwidgets|https://github.com/leanprover-community/ProofWidgets4|eb08eee94098fe530ccd6d8751a86fe405473d4c"
  "Cli|https://github.com/leanprover/lean4-cli|2cf1030dc2ae6b3632c84a09350b675ef3e347d0"
  "importGraph|https://github.com/leanprover-community/import-graph|e285a7ade149c551c17a4b24f127e1ef782e4bb1"
  "LeanSearchClient|https://github.com/leanprover-community/LeanSearchClient|2ba60fa2c384a94735454db11a2d523612eaabff"
  "mathlib|https://github.com/leanprover-community/mathlib4.git|809c3fb3b5c8f5d7dace56e200b426187516535a"
)

restore_one() {
  local name="$1"
  local _url="$2"  # informational; we don't re-fetch here
  local rev="$3"
  local pkg_dir="$PACKAGES_DIR/$name"
  local tar_file="$TARS_DIR/${name}.git.tar"

  if [ ! -d "$pkg_dir" ]; then
    # Working tree absent. In sandboxed environments the upstream
    # `lake update` / `git fetch` path can fail on filesystem-level
    # pack-writes (seen 2026-05-28 in the lake-recovery workflow:
    # "unable to write file .git/objects/pack/...pack: No such file or
    # directory"). When we have a committed tar for this package, we
    # can sidestep the broken transport entirely by restoring `.git/`
    # from tar and then doing a local `git checkout` to populate the
    # worktree. This is exactly the path Lake itself would take after a
    # successful fetch; the only difference is the source of objects
    # (vendored tar vs. upstream remote).
    if [ -f "$tar_file" ]; then
      mkdir -p "$pkg_dir"
      tar -xf "$tar_file" -C "$pkg_dir"
      # Post-extract sanity check (architect review, Batch 158.1): crisper
      # diagnostics if the tar is corrupt / partially extracted before we
      # hand off to `git checkout`.
      if [ ! -d "$pkg_dir/.git" ]; then
        echo "restore-lake-git: error: $name: tar extracted but \`$pkg_dir/.git\` is absent (corrupt or partial tar)." >&2
        return 1
      fi
      if ! git -C "$pkg_dir" checkout -f "$rev" >/dev/null 2>&1; then
        echo "restore-lake-git: error: $name: \`git checkout $rev\` failed after tar extract." >&2
        return 1
      fi
      local got
      got="$(git -C "$pkg_dir" rev-parse HEAD 2>/dev/null || echo "")"
      if [ "$got" != "$rev" ]; then
        echo "restore-lake-git: error: after restore, $name HEAD=$got but manifest pins $rev." >&2
        return 1
      fi
      echo "restore-lake-git: ok    $name @ ${rev:0:12} (restored from tar; worktree checked out from local objects)." >&2
      return 0
    fi
    # Fail closed (architect review, Batch 158.1): previously this branch
    # silently returned 0 and let `lake update` attempt a network fetch,
    # which is exactly the path that fails in sandboxed environments
    # with the .git/objects/pack write error. If we have no working tree
    # AND no vendored tar, that is a build-environment bug worth surfacing
    # loudly rather than papering over with a fetch that probably won't
    # work either.
    echo "restore-lake-git: error: $name has no working tree at $pkg_dir AND no vendored tar at $tar_file." >&2
    echo "       Either restore the tar (see regeneration snippet at bottom of this script)" >&2
    echo "       or, if this package genuinely should not be vendored, remove it from \`git_packages\` above." >&2
    return 1
  fi

  if [ -d "$pkg_dir/.git" ]; then
    local cur
    cur="$(git -C "$pkg_dir" rev-parse HEAD 2>/dev/null || echo "")"
    if [ "$cur" = "$rev" ]; then
      echo "restore-lake-git: ok    $name @ ${rev:0:12} (already restored)." >&2
      return 0
    fi
    echo "restore-lake-git: warn  $name has \`.git\` at $cur (expected $rev); rebuilding from tar." >&2
    rm -rf "$pkg_dir/.git"
  fi

  if [ ! -f "$tar_file" ]; then
    echo "restore-lake-git: error: $name working tree exists but tar is missing at $tar_file." >&2
    echo "       Regenerate via the snippet at the bottom of scripts/restore-lake-git.sh," >&2
    echo "       or delete $pkg_dir so \`lake update\` re-fetches it from scratch." >&2
    return 1
  fi

  tar -xf "$tar_file" -C "$pkg_dir"

  local got
  got="$(git -C "$pkg_dir" rev-parse HEAD 2>/dev/null || echo "")"
  if [ "$got" != "$rev" ]; then
    echo "restore-lake-git: error: after restore, $name HEAD=$got but manifest pins $rev." >&2
    return 1
  fi
  echo "restore-lake-git: ok    $name @ ${rev:0:12} (restored from tar)." >&2
}

# Preflight assertion: every entry in PKGS must end up with a real
# `.git/` pinned to the manifest rev. If not, exit non-zero so the
# caller (check-towers.sh / post-merge.sh / CI) fails loudly instead
# of letting Lake silently re-clone and wipe the working tree.
FAILED=0
for entry in "${PKGS[@]}"; do
  IFS='|' read -r name url rev <<< "$entry"
  if ! restore_one "$name" "$url" "$rev"; then
    FAILED=1
  fi
done

if [ "$FAILED" = "1" ]; then
  echo "restore-lake-git: FAILED — one or more packages could not be restored. See errors above." >&2
  exit 1
fi

echo "restore-lake-git: done — all ${#PKGS[@]} Lake packages have real .git/ at their manifest-pinned revs." >&2

# ---------------------------------------------------------------------
# How to regenerate a tar (when the manifest pins a new rev):
#
#   pkg=mathlib
#   url=https://github.com/leanprover-community/mathlib4.git
#   rev=<new-sha-from-lake-manifest.json>
#   cd lean-proof-towers/.lake/packages/$pkg
#   rm -rf .git
#   git init -q
#   git remote add origin "$url"
#   git fetch --depth=1 origin "$rev"
#   git update-ref HEAD "$rev"
#   git reset --mixed -q "$rev"
#   cd -
#   tar -cf lean-proof-towers/lake-deps/${pkg}.git.tar \
#     -C lean-proof-towers/.lake/packages/$pkg .git
#
# Then update the matching entry in the PKGS array above.
# ---------------------------------------------------------------------
