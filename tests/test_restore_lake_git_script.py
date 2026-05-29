"""Smoke tests for the recovery branches of
``scripts/restore-lake-git.sh`` (Tasks #192, #216).

Task #172 patched the script to rehydrate a Lake package's working
tree when ``.git/`` is intact at the manifest-pinned rev but the
tracked files themselves have been deleted (the failure mode that bit
the ``towers-build`` workflow three times: ``lake build`` silently
wipes the worktree under ``.lake/packages/mathlib/`` between builds,
leaving ``.git/`` behind). The fix lives in the
``if [ "$cur" = "$rev" ]`` branch: it counts ``^ D `` deletions via
``git status --porcelain`` and, when any are present, runs
``git checkout -- .`` to repopulate the worktree from the vendored
objects.

Task #192 added the first automated test for that one heal path — a
future refactor of the script could silently drop the deletion check
and we'd only discover it the next time ``towers-build`` failed. It
builds a throwaway fixture that mimics the wiped state (a package
directory with ``.git/`` at the pinned rev and *no* working-tree
files), runs the real script against it, and asserts the tracked
files come back and the script exits 0.

Task #216 extends that coverage to the script's other two
failure-prone recovery branches, which had no automated test and
would likewise only surface the next time a build failed:

- **Absent worktree** (``if [ ! -d "$pkg_dir" ]``): the package
  directory is gone entirely; the script restores ``.git/`` from the
  committed tar, checks out the pinned rev, and exits 0.
- **Wrong rev** (``if [ -d "$pkg_dir/.git" ]`` with ``HEAD`` at an
  unexpected commit): the script removes the stale ``.git/``,
  rebuilds it from tar, verifies ``HEAD`` lands on the pinned rev,
  and exits 0.
- **Missing worktree *and* tar**: the script must fail loudly
  (non-zero) rather than papering over a build-environment bug with a
  network fetch that would fail anyway.

To keep the smoke tests fast and self-contained they drive a single
small vendored package (``Cli``, ~120 KB tar) through the
``RESTORE_LAKE_PACKAGES_DIR`` / ``RESTORE_LAKE_TARS_DIR`` /
``RESTORE_LAKE_PKGS`` env-var overrides rather than the full ~20 MB
8-package set.
"""

from __future__ import annotations

import shutil
import subprocess
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
SCRIPT_PATH = REPO_ROOT / "scripts" / "restore-lake-git.sh"

# A small vendored package used as the fixture source. Its committed
# tar carries only `.git/`; the rev must match the entry in the
# script's PKGS array (and `lean-proof-towers/lake-manifest.json`).
FIXTURE_PKG = "Cli"
FIXTURE_URL = "https://github.com/leanprover/lean4-cli"
FIXTURE_REV = "2cf1030dc2ae6b3632c84a09350b675ef3e347d0"
SOURCE_TAR = REPO_ROOT / "lean-proof-towers" / "lake-deps" / f"{FIXTURE_PKG}.git.tar"


pytestmark = [
    pytest.mark.skipif(
        not shutil.which("git") or not shutil.which("tar"),
        reason="restore-lake-git.sh requires `git` and `tar` on PATH",
    ),
    pytest.mark.skipif(
        not SOURCE_TAR.exists(),
        reason=f"fixture source tar missing: {SOURCE_TAR}",
    ),
]


def _git(pkg_dir: Path, *args: str) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", "-C", str(pkg_dir), *args],
        check=True,
        capture_output=True,
        text=True,
    )


def _make_layout(tmp_path: Path, *, with_tar: bool = True) -> tuple[Path, Path]:
    """Create the throwaway ``packages``/``lake-deps`` skeleton the
    script points at via its env-var overrides.

    When ``with_tar`` is true the vendored fixture tar is copied into
    the ``lake-deps`` dir so the script's tar-extract branches can run;
    set it false to exercise the "no vendored tar" failure path.

    Returns ``(packages_dir, tars_dir)``.
    """

    packages_dir = tmp_path / "packages"
    tars_dir = tmp_path / "lake-deps"
    packages_dir.mkdir(parents=True)
    tars_dir.mkdir(parents=True)
    if with_tar:
        shutil.copy2(SOURCE_TAR, tars_dir / f"{FIXTURE_PKG}.git.tar")
    return packages_dir, tars_dir


def _build_wiped_fixture(tmp_path: Path) -> tuple[Path, Path, Path]:
    """Create a throwaway lake layout whose single package mimics the
    wiped state: ``.git/`` present at the pinned rev, every tracked
    working-tree file deleted.

    Returns ``(packages_dir, tars_dir, pkg_dir)``.
    """

    packages_dir, tars_dir = _make_layout(tmp_path)
    pkg_dir = packages_dir / FIXTURE_PKG
    pkg_dir.mkdir(parents=True)

    # Lay down a real `.git/` at the pinned rev from the vendored tar,
    # then populate the worktree exactly as Lake would.
    subprocess.run(
        ["tar", "-xf", str(SOURCE_TAR), "-C", str(pkg_dir)],
        check=True,
        capture_output=True,
        text=True,
    )
    assert (pkg_dir / ".git").is_dir(), "tar did not yield a .git/ directory"
    _git(pkg_dir, "checkout", "-f", FIXTURE_REV)
    assert _git(pkg_dir, "rev-parse", "HEAD").stdout.strip() == FIXTURE_REV

    # Simulate the `lake build` wipe: remove every worktree entry except
    # `.git/`, leaving the repo metadata intact at the pinned rev.
    for entry in pkg_dir.iterdir():
        if entry.name == ".git":
            continue
        if entry.is_dir() and not entry.is_symlink():
            shutil.rmtree(entry)
        else:
            entry.unlink()

    return packages_dir, tars_dir, pkg_dir


def _run_script(packages_dir: Path, tars_dir: Path) -> subprocess.CompletedProcess[str]:
    env = {
        # Inherit PATH etc. from the parent process.
        **dict(__import__("os").environ),
        "RESTORE_LAKE_PACKAGES_DIR": str(packages_dir),
        "RESTORE_LAKE_TARS_DIR": str(tars_dir),
        "RESTORE_LAKE_PKGS": f"{FIXTURE_PKG}|{FIXTURE_URL}|{FIXTURE_REV}",
    }
    return subprocess.run(
        ["bash", str(SCRIPT_PATH)],
        env=env,
        capture_output=True,
        text=True,
    )


def test_heal_path_restores_wiped_worktree(tmp_path):
    packages_dir, tars_dir, pkg_dir = _build_wiped_fixture(tmp_path)

    # Sanity: the fixture really is in the wiped state the heal path
    # targets — `.git/` intact at the pinned rev, tracked files gone,
    # `git status` reporting `^ D ` deletions. Without this guard the
    # test could pass against an already-restored tree and never
    # exercise the `git checkout -- .` branch at all.
    porcelain = _git(pkg_dir, "status", "--porcelain").stdout.splitlines()
    deletions = [ln for ln in porcelain if ln.startswith(" D ")]
    assert deletions, (
        "fixture is not in the wiped state; no `^ D ` deletions to heal: "
        f"{porcelain!r}"
    )
    worktree_before = [p.name for p in pkg_dir.iterdir() if p.name != ".git"]
    assert worktree_before == [], (
        f"fixture worktree should be empty before heal, found: {worktree_before!r}"
    )

    result = _run_script(packages_dir, tars_dir)

    assert result.returncode == 0, (
        f"restore-lake-git.sh exited {result.returncode}; "
        f"stdout={result.stdout!r} stderr={result.stderr!r}"
    )

    # Every tracked file must be back on disk and the tree clean.
    after_porcelain = _git(pkg_dir, "status", "--porcelain").stdout.strip()
    assert after_porcelain == "", (
        f"worktree still dirty after heal: {after_porcelain!r}"
    )
    worktree_after = sorted(p.name for p in pkg_dir.iterdir() if p.name != ".git")
    assert worktree_after, "heal path did not repopulate any worktree files"
    # HEAD must remain pinned — the heal must not move the checkout.
    assert _git(pkg_dir, "rev-parse", "HEAD").stdout.strip() == FIXTURE_REV


def test_heal_path_is_idempotent_on_intact_worktree(tmp_path):
    """A second run against an already-healed tree must stay green and
    exit 0 — the script is the prerequisite for every Lake op and runs
    on every ``check-towers.sh`` invocation, so it must be a no-op when
    nothing is wrong."""

    packages_dir, tars_dir, pkg_dir = _build_wiped_fixture(tmp_path)

    first = _run_script(packages_dir, tars_dir)
    assert first.returncode == 0, (
        f"first run failed: stdout={first.stdout!r} stderr={first.stderr!r}"
    )

    second = _run_script(packages_dir, tars_dir)
    assert second.returncode == 0, (
        f"idempotent re-run failed: stdout={second.stdout!r} stderr={second.stderr!r}"
    )
    assert _git(pkg_dir, "status", "--porcelain").stdout.strip() == ""


def test_absent_worktree_restored_from_tar(tmp_path):
    """The ``if [ ! -d "$pkg_dir" ]`` branch: when the package
    directory is gone entirely (e.g. a sandboxed ``lake update`` /
    ``git fetch`` failed mid-write and left nothing behind) but the
    vendored tar is present, the script must restore ``.git/`` from the
    tar, ``checkout -f`` the pinned rev to populate the worktree, and
    exit 0."""

    packages_dir, tars_dir = _make_layout(tmp_path)
    pkg_dir = packages_dir / FIXTURE_PKG

    # Sanity: the package directory really is absent — this is the
    # precondition the branch keys off of.
    assert not pkg_dir.exists(), "fixture pkg dir should not exist yet"

    result = _run_script(packages_dir, tars_dir)

    assert result.returncode == 0, (
        f"restore-lake-git.sh exited {result.returncode}; "
        f"stdout={result.stdout!r} stderr={result.stderr!r}"
    )

    # `.git/` must be back, the worktree populated, HEAD at the pin, and
    # the tree clean — exactly what `lake exe cache get` would expect.
    assert (pkg_dir / ".git").is_dir(), "restore did not lay down a .git/ dir"
    assert _git(pkg_dir, "rev-parse", "HEAD").stdout.strip() == FIXTURE_REV
    worktree = [p.name for p in pkg_dir.iterdir() if p.name != ".git"]
    assert worktree, "restore did not check out any worktree files"
    assert _git(pkg_dir, "status", "--porcelain").stdout.strip() == "", (
        "worktree should be clean after restore-from-tar"
    )


def _build_wrong_rev_fixture(tmp_path: Path) -> tuple[Path, Path, Path, str]:
    """Create a throwaway layout whose package has a real ``.git/`` at
    an *unexpected* commit (a fresh standalone repo, not the pinned
    rev), with the vendored tar available so the rebuild path can run.

    Returns ``(packages_dir, tars_dir, pkg_dir, wrong_rev)``.
    """

    packages_dir, tars_dir = _make_layout(tmp_path)
    pkg_dir = packages_dir / FIXTURE_PKG
    pkg_dir.mkdir(parents=True)

    # A self-contained repo with its own arbitrary commit — its HEAD is
    # guaranteed not to be the manifest-pinned rev.
    _git(pkg_dir, "init", "-q")
    _git(pkg_dir, "config", "user.email", "test@example.com")
    _git(pkg_dir, "config", "user.name", "restore-lake-git test")
    (pkg_dir / "stale.txt").write_text("stale worktree content\n")
    _git(pkg_dir, "add", "-A")
    _git(pkg_dir, "commit", "-q", "-m", "stale commit at wrong rev")

    wrong_rev = _git(pkg_dir, "rev-parse", "HEAD").stdout.strip()
    assert wrong_rev != FIXTURE_REV, "fixture HEAD accidentally equals the pin"
    return packages_dir, tars_dir, pkg_dir, wrong_rev


def test_wrong_rev_rebuilt_from_tar(tmp_path):
    """The ``if [ -d "$pkg_dir/.git" ]`` rev-mismatch branch: when
    ``.git/`` exists but ``HEAD`` is at an unexpected commit, the
    script must ``rm -rf .git``, rebuild it from the vendored tar,
    verify ``HEAD`` lands on the pinned rev, and exit 0."""

    packages_dir, tars_dir, pkg_dir, wrong_rev = _build_wrong_rev_fixture(tmp_path)

    # Sanity: the fixture really is at the wrong rev before we run.
    assert _git(pkg_dir, "rev-parse", "HEAD").stdout.strip() == wrong_rev

    result = _run_script(packages_dir, tars_dir)

    assert result.returncode == 0, (
        f"restore-lake-git.sh exited {result.returncode}; "
        f"stdout={result.stdout!r} stderr={result.stderr!r}"
    )

    # HEAD must have been rebuilt to the manifest-pinned rev.
    assert _git(pkg_dir, "rev-parse", "HEAD").stdout.strip() == FIXTURE_REV, (
        "rev-mismatch branch did not rebuild HEAD to the pinned rev"
    )
    # The script should have announced the rebuild, not the no-op path.
    assert "rebuilding from tar" in result.stderr, (
        f"expected a rebuild warning in stderr, got: {result.stderr!r}"
    )


def test_missing_worktree_and_tar_fails_loudly(tmp_path):
    """The fail-closed leg of the ``if [ ! -d "$pkg_dir" ]`` branch:
    with neither a working tree nor a vendored tar the script must
    exit non-zero rather than silently returning 0 and letting Lake
    attempt a network fetch that fails in sandboxed environments."""

    packages_dir, tars_dir = _make_layout(tmp_path, with_tar=False)
    pkg_dir = packages_dir / FIXTURE_PKG
    tar_file = tars_dir / f"{FIXTURE_PKG}.git.tar"

    # Sanity: both inputs are genuinely absent.
    assert not pkg_dir.exists(), "fixture pkg dir should not exist"
    assert not tar_file.exists(), "fixture tar should not exist"

    result = _run_script(packages_dir, tars_dir)

    assert result.returncode != 0, (
        "script must fail loudly when a package has neither worktree nor tar; "
        f"got returncode 0. stdout={result.stdout!r} stderr={result.stderr!r}"
    )
    # The diagnostic must name both missing inputs so an operator can act.
    assert "no working tree" in result.stderr and "no vendored tar" in result.stderr, (
        f"expected a clear no-worktree/no-tar error, got: {result.stderr!r}"
    )
