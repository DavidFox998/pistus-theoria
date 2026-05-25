"""Numerical regression tests for the mpmath L-function backend in
`kernel.probe()`.

These pin the actual numbers the backend writes to the append-only
ledger, so a future refactor (precision change, Euler-factor rewrite,
mpmath bump) can't silently shift what gets recorded.

Cases covered:
  * `probe(1, 1, 0.5, 14.134725)` — first nontrivial zero of ζ.
    Tag `MPMATH_ZETA`, `|L| < 1e-6`.
  * `probe(1, 1, 2, 0)` — ζ(2) = π²/6. Tag `MPMATH_ZETA`,
    `|L - π²/6| < 1e-10`.
  * `probe(1, 19, 0.5, 0)` — principal Dirichlet character mod 19.
    Tag `MPMATH_DIRICHLET_TRIVIAL`; the prime-19 Euler factor is
    stripped, so the value matches `ζ(0.5) · (1 - 19^{-0.5})`.
  * `probe(2, 547, 0, 0)` — out of scope for the mpmath backend.
    Tag `NEEDS_SAGE` with the documented
    `h>=2_out_of_scope_for_mpmath_backend` reason.

Each test monkeypatches `kernel.HITS` to a throwaway file in `tmp_path`
so the real append-only ledger is never touched.
"""

from __future__ import annotations

import mpmath
import pytest

import kernel


@pytest.fixture
def tmp_hits(tmp_path, monkeypatch):
    """Redirect `kernel.HITS` to a throwaway file under tmp_path."""
    fake = tmp_path / "hits.txt"
    monkeypatch.setattr(kernel, "HITS", fake)
    return fake


def test_probe_zeta_first_zero(tmp_hits):
    out = kernel.probe(1, 1, 0.5, 14.134725)
    assert out["tag"] == "MPMATH_ZETA"
    assert out["backend"] == "mpmath"
    assert mpmath.mpf(out["L_abs"]) < mpmath.mpf("1e-6")
    assert tmp_hits.exists()
    assert tmp_hits.read_text(encoding="utf-8").count("\n") == 1


def test_probe_zeta_at_two(tmp_hits):
    out = kernel.probe(1, 1, 2, 0)
    assert out["tag"] == "MPMATH_ZETA"
    assert out["backend"] == "mpmath"
    expected = mpmath.pi ** 2 / 6
    actual = mpmath.mpc(out["L_real"], out["L_imag"])
    assert abs(actual - expected) < mpmath.mpf("1e-10")
    assert out["L_nonvanish"] is True


def test_probe_dirichlet_trivial_strips_prime_19(tmp_hits):
    out = kernel.probe(1, 19, 0.5, 0)
    assert out["tag"] == "MPMATH_DIRICHLET_TRIVIAL"
    assert out["backend"] == "mpmath"
    with mpmath.workdps(50):
        s = mpmath.mpc(0.5, 0)
        expected = mpmath.zeta(s) * (mpmath.mpc(1) - mpmath.power(19, -s))
    actual = mpmath.mpc(out["L_real"], out["L_imag"])
    assert abs(actual - expected) < mpmath.mpf("1e-10")


def test_probe_h_ge_2_needs_sage(tmp_hits):
    out = kernel.probe(2, 547, 0, 0)
    assert out["tag"] == "NEEDS_SAGE"
    assert out["backend"] == "none"
    assert out["L_real"] is None
    assert out["L_imag"] is None
    assert out["L_abs"] is None
    assert out["reason"] == "h>=2_out_of_scope_for_mpmath_backend"
    assert "NEEDS_SAGE" in tmp_hits.read_text(encoding="utf-8")


def test_elliptic_stub_appends_one_line_with_intent_tag(tmp_hits):
    """Gun 3: elliptic_stub writes one ELLIPTIC_STUB line, no L value,
    no claim of RH_ok, and includes the elliptic_L_requires_sage reason.
    """
    out = kernel.elliptic_stub("37a1", 1.0, 0.0)
    assert out["tag"] == "ELLIPTIC_STUB"
    assert out["backend"] == "none"
    assert out["reason"] == "elliptic_L_requires_sage"
    assert out["RH_ok"] is None
    assert out["kms_beta"] is None
    assert out["axioms"] == []
    assert len(out["sha"]) == 64
    body = tmp_hits.read_text(encoding="utf-8")
    assert body.count("\n") == 1
    line = body.strip()
    assert line.startswith("elliptic_stub ts=")
    assert "label=37a1" in line
    assert "tag=ELLIPTIC_STUB" in line
    assert "reason=elliptic_L_requires_sage" in line
    assert f"sha={out['sha']}" in line


def test_elliptic_stub_rejects_bad_label_without_writing(tmp_hits):
    """A label that violates ELLIPTIC_LABEL_RE must raise before any
    seal check or append — no ledger line, no partial state."""
    with pytest.raises(ValueError, match="elliptic_stub: label"):
        kernel.elliptic_stub("37a1; rm -rf /", 1.0, 0.0)
    assert not tmp_hits.exists() or tmp_hits.read_text(encoding="utf-8") == ""


def test_elliptic_stub_does_not_call_mpmath_backend(tmp_hits):
    """Gun 3 is a stub: even when label looks like a real curve and s is
    well-defined, no L value is ever filled in. Catches a future refactor
    that accidentally routes elliptic_stub through probe()."""
    out = kernel.elliptic_stub("143b2", 0.5, 14.134725)
    assert "L_abs" not in out  # no numeric field at all
    assert "L_real" not in out
    assert "L_imag" not in out
    assert out["tag"] == "ELLIPTIC_STUB"
