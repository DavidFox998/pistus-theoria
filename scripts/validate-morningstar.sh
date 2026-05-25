#!/usr/bin/env bash
# MorningStar-Lab v1.0 validation harness.
# Runs (in order):
#   1. python lab.py -c "probe(1,19,0.5,0)"   — Layer 7 + Layer 4 + Genesis seal
#   1a. assert kms_beta=2.0 in the latest ledger line
#   1b. python lab.py -c "zero(1)"            — honest-scope RH_ok witness
#                                                (tag=MPMATH_ZETA, kms_beta=2.0,
#                                                 RH_ok=True)
#   2. python lab.py -c "hunt_zeros(1,3)"     — zeta zero reconnaissance
#   3. python lab.py -c "bracket_zero(1,1e-4)" — tight bracket sweep
#   4. assert data/MorningStar_RH_Cert.tex exists
#   5. python lean_bridge.py                  — Layer 2 (emit AutoLemmas.lean,
#                                                runtime axiom check)
#   6. cd lean-proof && lake build            — full Lake build
#   7. lake env lean Verify.lean              — main_theorem axiom debt = []
#                                                hit_437 / hit_1094 axiom check
# On full success, prints:
#   MorningStar-Lab v1.0 online. 4D stable. W=h Z=N X=Re Y=Im. CERTIFICATE at /data/M13_CERT.txt
#
# NOTE: This script is NOT wired into scripts/post-merge.sh or the
# `lean-proof` validation workflow. The v1.8-BC drift guard must keep
# running unchanged.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo ">> [1/7] python lab.py -c \"probe(1,19,0.5,0)\""
python lab.py -c "probe(1,19,0.5,0)"

echo
echo ">> [1a/7] verify kms_beta wired into latest ledger line"
TAIL_LINE="$(tail -1 data/hits.txt)"
if ! grep -qE ' kms_beta=' <<<"$TAIL_LINE"; then
  echo "FATAL: kms_beta field missing from latest ledger line:" >&2
  echo "  $TAIL_LINE" >&2
  exit 1
fi
# Re(s)=0.5 → β = 1/0.5 = 2.0
if ! grep -qE ' kms_beta=2\.0 ' <<<"$TAIL_LINE"; then
  echo "FATAL: expected kms_beta=2.0 at Re(s)=0.5; latest line was:" >&2
  echo "  $TAIL_LINE" >&2
  exit 1
fi

echo
echo ">> [1b/7] python lab.py -c \"zero(1)\"  (honest-scope RH_ok witness)"
python lab.py -c "zero(1)"
ZERO_LINE="$(tail -1 data/hits.txt)"
# Must be the real Riemann-ζ backend, on the critical line, with the
# witness firing — i.e. tag=MPMATH_ZETA, kms_beta=2.0, RH_ok=True.
for needle in "MPMATH_ZETA" "kms_beta=2.0" "RH_ok=True"; do
  if ! grep -qF "$needle" <<<"$ZERO_LINE"; then
    echo "FATAL: zero(1) ledger line missing '$needle':" >&2
    echo "  $ZERO_LINE" >&2
    exit 1
  fi
done

echo
echo ">> [2/7] python lab.py -c \"hunt_zeros(1,3)\""
python lab.py -c "hunt_zeros(1,3)"

echo
echo ">> [3/7] python lab.py -c \"bracket_zero(1,1e-4)\""
python lab.py -c "bracket_zero(1,1e-4)"

echo
echo ">> [4/7] check data/MorningStar_RH_Cert.tex exists"
if [ ! -s data/MorningStar_RH_Cert.tex ]; then
  echo "FATAL: data/MorningStar_RH_Cert.tex missing or empty." >&2
  exit 1
fi
echo "ok: data/MorningStar_RH_Cert.tex present ($(wc -c <data/MorningStar_RH_Cert.tex) bytes)"

echo
echo ">> [5/7] python lean_bridge.py"
python lean_bridge.py

if ! command -v lake >/dev/null 2>&1; then
  echo "FATAL: lake not on PATH; cannot verify Lean axiom debt." >&2
  echo "       Install Lean 4 / elan and re-run. v1.0-online line WILL NOT be printed." >&2
  exit 1
fi

echo
echo ">> [6/7] cd lean-proof && lake build"
( cd lean-proof && lake build )

echo
echo ">> [7/7] lake env lean Verify.lean + hit_437 / hit_1094 axiom check"
VERIFY_OUT="$(cd lean-proof && lake env lean Verify.lean)"
echo "$VERIFY_OUT"

REQUIRED=(
  "'TheoremaAureum.main_theorem' does not depend on any axioms"
  "'TheoremaAureum.H2_WeilTransfer' does not depend on any axioms"
  "'TheoremaAureum.M9_WeilTransfer_All' does not depend on any axioms"
)
for line in "${REQUIRED[@]}"; do
  if ! grep -qF "$line" <<<"$VERIFY_OUT"; then
    echo "FATAL: missing required axiom-debt line: $line" >&2
    exit 1
  fi
done

# Extra check: hit_437 / hit_1094 via a transient lean file.
PROBE="lean-proof/_MorningStar_Verify.lean"
cat > "$PROBE" <<'EOF'
import TheoremaAureum.AutoLemmas
#print axioms TheoremaAureum.AutoLemmas.hit_437
#print axioms TheoremaAureum.AutoLemmas.hit_1094
EOF
HIT_OUT="$(cd lean-proof && lake env lean _MorningStar_Verify.lean)"
rm -f "$PROBE"
echo "$HIT_OUT"

for t in hit_437 hit_1094; do
  needle="'TheoremaAureum.AutoLemmas.${t}' does not depend on any axioms"
  if ! grep -qF "$needle" <<<"$HIT_OUT"; then
    echo "FATAL: $t axiom check failed." >&2
    exit 1
  fi
done

echo
echo "MorningStar-Lab v1.0 online. 4D stable. W=h Z=N X=Re Y=Im. CERTIFICATE at /data/M13_CERT.txt"
