#!/usr/bin/env bash
# ship-volume-ii.sh — Volume II ("Towers second bricks") verification
# harness.
#
# What this script does:
#   1. Verify the Genesis seal of data/hits.txt is intact
#      (eecbcd9a...875f).
#   2. Run the morningstar-tamper pytest (tamper-evidence of the
#      sealed ledger preamble).
#   3. Run the kernel-numerics pytest (mpmath backend numerics +
#      Three-Guns invariants + sieve dry-run).
#   4. Strict-mode build the lean-proof spine and re-verify
#      TheoremaAureum.main_theorem axiom debt = [].
#   5. Build the sibling lean-proof-towers/ package and run the
#      per-brick axiom-footprint check (RH + YM + NS + BSD, 18 bricks
#      total — 1 RH + 2 BSD + 8 NS + 7 YM/MassGap, all axiom
#      footprints subset of mathlib's classical trio
#      {propext, Classical.choice, Quot.sound}). Six hollow
#      `gauge_action_*` bricks on `TrivialConfiguration` were
#      retired 2026-05-26 — see docs/ROADMAP.md § 2.
#   6. Print a one-screen honest-scope summary that re-states the
#      current Status lines from docs/ROADMAP.md without promoting
#      anything.
#
# What this script does NOT do (deliberately):
#   - It does NOT edit docs/ROADMAP.md, replit.md, or any sealed
#     surface. The current ROADMAP is already accurate; do not
#     overwrite it from this script.
#   - It does NOT run `git commit`, `git tag`, or `git push`.
#     Version control is handled outside this script (Replit task
#     auto-commits; release tagging is a separate, deliberate
#     human-driven step that must go through a project task per the
#     sandbox rules).
#   - It does NOT promote any of the five towers past Status: Open
#     (only Bost-Connes at h = 1 closes inside the spine).
#   - It does NOT introduce any "Certified" / "Closed" / "Discharged"
#     wording for YM / NS / BSD / RH. Per replit.md "Honest-scope
#     wording is locked".
#
# Exit codes:
#   0   all six phases passed
#   1-6 the corresponding phase failed (see banner below)
#
# Usage:
#   bash scripts/ship-volume-ii.sh
#
# Cost: warm caches ~30s; cold mathlib cache adds 5-15 min for
# `lake exe cache get` inside scripts/check-towers.sh.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

red()    { printf '\033[0;31m%s\033[0m\n' "$*"; }
green()  { printf '\033[0;32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[0;33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

phase() {
  echo
  bold "============================================================"
  bold "$1"
  bold "============================================================"
}

fail() {
  red "FAIL ($1): $2"
  exit "$1"
}

bold "============================================================"
bold "  Morning Star Project · Volume II verification harness"
bold "  Theorema Aureum 143 — Towers second bricks"
bold "============================================================"
echo "  Publisher: Morning Star Project (independent research)"
echo "  License:   All rights reserved (license pending review)"
echo "  Repo:      $REPO_ROOT"

# ------------------------------------------------------------------
phase "[1/6] Genesis seal of data/hits.txt"
# ------------------------------------------------------------------
python3 scripts/check-genesis-seal.py \
  || fail 1 "Genesis seal mismatch on data/hits.txt"
green "  Genesis seal eecbcd9a...875f intact."

# ------------------------------------------------------------------
phase "[2/6] morningstar-tamper (sealed-preamble tamper-evidence)"
# ------------------------------------------------------------------
python3 -m pytest tests/test_morningstar.py -q \
  || fail 2 "morningstar-tamper pytest failed"
green "  Tamper-evidence pytest GREEN."

# ------------------------------------------------------------------
phase "[3/6] kernel-numerics (mpmath backend + Three-Guns)"
# ------------------------------------------------------------------
python3 -m pytest tests/test_kernel.py -q \
  || fail 3 "kernel-numerics pytest failed"
green "  Kernel numerics pytest GREEN."

# ------------------------------------------------------------------
phase "[4/6] lean-proof spine — main_theorem axiom debt = []"
# ------------------------------------------------------------------
STRICT_LEAN_CHECK=1 bash scripts/check-lean-proof.sh \
  || fail 4 "lean-proof spine strict check failed"
green "  TheoremaAureum.main_theorem axiom debt = [] preserved."

# ------------------------------------------------------------------
phase "[5/6] lean-proof-towers — 18 trio-clean bricks"
# ------------------------------------------------------------------
# scripts/check-towers.sh builds the sibling lean-proof-towers/
# package on mathlib v4.12.0 and runs `#print axioms` on each of the
# 18 named bricks (RH: N_monotone_in_sigma; BSD: add_comm,
# eq_zero_of_isRankZero; NS: divergence_{add,smul,zero,neg,sub,
# const,add_const,sub_const}; YM/MassGap: SU3Connection_one_mul,
# SU3Connection_component_unitary, SU3Connection_component_det_one,
# SU3Connection_mul_one, SU3Connection_one_one,
# SU3Connection_component_mul_unitary,
# SU3Connection_component_mul_det_one). Each brick's axiom
# footprint must be either [] or a subset of {propext,
# Classical.choice, Quot.sound}; sorryAx or any user-declared
# axiom causes a non-zero exit. (The six `gauge_action_*` bricks
# on `TrivialConfiguration` were retired 2026-05-26 — see
# docs/ROADMAP.md § 2.)
bash scripts/check-towers.sh \
  || fail 5 "lean-proof-towers axiom-footprint check failed"
green "  All 18 tower bricks: axiom footprint subset of classical trio."

# ------------------------------------------------------------------
phase "[6/6] Honest-scope summary (no status promotions)"
# ------------------------------------------------------------------
cat <<'BANNER'
  Tower status (from docs/ROADMAP.md — DO NOT promote past these):

    1. RH ............ Open — first brick formalized
                        (N_monotone_in_sigma, conditional on
                         finiteness of the larger zero box).
    2. Yang-Mills .... Open — seven SU(3) bricks formalized
                        (Towers.YM.MassGap: real
                         Matrix.specialUnitaryGroup algebra; the
                         trivial-bundle scaffold is NOT a physical
                         YM configuration; six retired
                         gauge_action_* bricks excluded).
    3. Navier-Stokes . Open — second brick formalized
                        (divergence_add + divergence_smul; linearity
                         of a minimal fderiv-based divergence on
                         Differentiable vector fields).
    4. BSD / 280-curve Certified for N = 397 (M9_WeilTransfer_All
                        in the spine). General statement Open —
                        second brick formalized (MordellWeilGroup
                        add_comm + eq_zero_of_isRankZero via
                        Subsingleton.elim; NO rank-of-E_143a1 claim,
                        NO `decide`-based rank theorem).
    5. Bost-Connes ... Certified in spine (BC-CM at h = 1 only).
                        Higher h is Open.

  What "Volume II" actually means in this repo:
    * Eighteen Lean bricks (1 RH + 2 BSD + 8 NS + 7 YM/MassGap)
      with axiom footprint subset of
      {propext, Classical.choice, Quot.sound}.
    * The spine (TheoremaAureum.main_theorem) still has axiom debt
      = []. The Genesis seal still matches eecbcd9a...875f.
    * No Millennium statement has been proved. The trivial bricks
      are stable hooks for future plans, not theorems about RH /
      YM mass gap / NS global regularity / BSD rank.

  What it does NOT mean:
    * "Volume II Certified" is not a valid phrase. The towers are
      Status: Open, with first/second bricks formalized.
    * Bost-Connes is not "Volume I complete" — only the h = 1 case
      closes inside the spine.

BANNER

green "Volume II verification: all 6 phases passed."
echo
echo "Next, deliberate, manually-initiated steps (NOT done here):"
echo "  - Optional: tag this commit via a project task if you want a"
echo "    release marker. Do NOT name the tag in a way that implies"
echo "    any Millennium statement is proved."
echo "  - Future plans: third bricks on YM / NS / BSD (and discharging"
echo "    the finiteness hypothesis on the RH first brick). All"
echo "    additive, all in the sibling lean-proof-towers/ package."
echo
