import sys
from pathlib import Path

import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
if str(REPO_ROOT) not in sys.path:
    sys.path.insert(0, str(REPO_ROOT))

_HITS = REPO_ROOT / "data" / "hits.txt"
_CHECKPOINT = REPO_ROOT / "data" / "hits.txt.checkpoint"


@pytest.fixture(scope="session", autouse=True)
def _snapshot_ledger_for_session():
    """Snapshot data/hits.txt and data/hits.txt.checkpoint at session
    start; restore at session end (pass or fail).

    Why (task #58): `tests/test_kernel.py` runs real `kernel.probe()`
    calls. The kernel module's module-level constants `kernel.HITS` and
    `kernel.CHECKPOINT` point at the canonical ledger files. Tests
    monkeypatch `kernel.HITS` to a throwaway tmp_path, but
    `kernel.CHECKPOINT` is not monkeypatched, so every probe rewrites
    the real `data/hits.txt.checkpoint` with `(size_of_fake, sha_of_fake)`.
    Other tamper-tests deliberately mutate `data/hits.txt` in place.
    The net effect: after `pytest` finishes, `git status` is dirty on
    both files, and contributors have to remember to
    `git restore data/hits.txt data/hits.txt.checkpoint` by hand.

    This session-scoped autouse fixture snapshots both files once at
    session start (in-memory bytes) and atomically restores them at
    session teardown, regardless of test pass/fail. Per-test fixtures
    (`hits_backup`, `fresh_checkpoint`) keep working unchanged — they
    handle intra-test restore for the tampering body of a single test;
    this fixture is the outer safety net for cross-suite side effects
    like the kernel.CHECKPOINT rewrites.
    """
    # Task #59 — restore policy:
    #
    # * `data/hits.txt.checkpoint` is ALWAYS restored at session end.
    #   The checkpoint file is a tiny `(size, sha)` summary that
    #   `kernel.probe()` rewrites every call, even when tests
    #   monkeypatch `kernel.HITS` to a tmp_path — `kernel.CHECKPOINT`
    #   is not monkeypatched, so the real checkpoint gets stamped
    #   with the fake ledger's hash. That's the original reason this
    #   fixture exists (task #58). Restoring it is cheap and there
    #   is no concurrent writer racing against the checkpoint —
    #   `_update_checkpoint` always runs under
    #   `kernel.hits_exclusive_lock()` via `_append_line`, and we
    #   acquire the same lock here.
    #
    # * `data/hits.txt` is NOT restored from a session-start
    #   snapshot. Pre-task #59 this fixture restored it defensively,
    #   but that snapshot is fundamentally stale once the session
    #   begins: a concurrent cross-process probe workflow that
    #   legitimately appends during the session would have its line
    #   overwritten at teardown. Holding the sidecar flock across
    #   the entire session would prevent that, but it also dead-
    #   locks any test that spawns its own appender thread (e.g.
    #   `test_snapshot_restore_does_not_lose_concurrent_appends`)
    #   because the per-process RLock semantics block cross-thread
    #   acquisitions. The correct guarantee is the one task #59
    #   actually delivers: every test that intentionally mutates
    #   `data/hits.txt` goes through the `hits_backup` fixture,
    #   which holds `kernel.hits_exclusive_lock()` for its full
    #   snapshot → test-body → restore window. The lint test
    #   `test_no_non_append_writes_to_hits_txt` enforces that no
    #   other test path writes directly. So if `hits_backup`
    #   cleaned up correctly, no session-level restore is needed;
    #   if it didn't, restoring from a session-start snapshot
    #   wouldn't be safe anyway (overwrites concurrent appends).
    import kernel

    with kernel.hits_exclusive_lock():
        cp_snapshot = _CHECKPOINT.read_bytes() if _CHECKPOINT.exists() else None
    try:
        yield
    finally:
        with kernel.hits_exclusive_lock():
            if cp_snapshot is not None:
                _atomic_restore(_CHECKPOINT, cp_snapshot)
            elif _CHECKPOINT.exists():
                _CHECKPOINT.unlink()


@pytest.fixture(autouse=True)
def _isolate_ledger_alert_dispatch(tmp_path_factory):
    """Function-scoped isolation for the async ledger-alert pipeline.

    `kernel._fire_ledger_alert` (reached whenever `_append_line` trips a
    `LedgerIntegrityError`) launches a daemon thread that, at *write*
    time, reads the module-global `kernel.ALERTS_LOG` and runs the
    configured transports. Two side effects leak across tests without
    this fixture:

      1. A test that fires an alert but never calls
         `kernel._await_alert_dispatch()` (the delivery-failure and
         env-unset tamper tests) leaves a live worker in
         `kernel._ALERT_DISPATCH_THREADS`. When a *later* test
         monkeypatches `ALERTS_LOG` to its own tmp file and then awaits
         dispatch, that stale worker wakes up, reads the now-current
         `ALERTS_LOG`, and appends a SECOND entry — turning
         `assert len(recent) == 1` into `2 == 1`
         (`test_alert_history_records_every_invocation`). This is the
         root cause of the recurring `kernel-numerics` failure.

      2. A test that fires an alert without redirecting `ALERTS_LOG`
         would otherwise write into the real `data/ledger-alerts.jsonl`
         (this conftest only snapshots the checkpoint), dirtying the
         repo across runs.

    The fixture drains any stale worker BEFORE each test — with the
    transports neutralised and the log pointed at a throwaway, so the
    drain itself can never hit the network or pollute a real file —
    defaults `ALERTS_LOG` to a per-test tmp file, then drains again on
    teardown so no worker survives the test boundary. Tests that set
    their own `ALERTS_LOG` still override it for their own body.
    """
    import kernel

    throwaway = tmp_path_factory.mktemp("alert-drain") / "drain.jsonl"

    def _drain_safely() -> None:
        prev_log = kernel.ALERTS_LOG
        prev_webhook = kernel._post_webhook
        prev_email = kernel._send_email
        kernel.ALERTS_LOG = throwaway
        kernel._post_webhook = lambda *a, **k: None
        kernel._send_email = lambda *a, **k: None
        try:
            # 10s comfortably exceeds any (now-neutralised) transport
            # timeout, so a False return means a genuinely wedged worker,
            # not boundary jitter.
            drained = kernel._await_alert_dispatch(timeout=10.0)
            with kernel._ALERT_DISPATCH_LOCK:
                if drained:
                    kernel._ALERT_DISPATCH_THREADS.clear()
                    leaked: list = []
                else:
                    # Never drop references to a LIVE worker — that would
                    # re-create the exact untracked-thread leak this
                    # fixture exists to prevent. Surface it loudly instead.
                    leaked = [
                        t
                        for t in kernel._ALERT_DISPATCH_THREADS
                        if t.is_alive()
                    ]
        finally:
            kernel.ALERTS_LOG = prev_log
            kernel._post_webhook = prev_webhook
            kernel._send_email = prev_email
        if leaked:
            pytest.fail(
                "ledger alert-dispatch worker(s) still alive after a 10s "
                f"drain: {leaked!r}. Refusing to orphan them (that would "
                "leak alert writes into a later test). A test fired an "
                "alert whose worker cannot complete — investigate it "
                "rather than masking the hang."
            )

    saved_log = kernel.ALERTS_LOG
    _drain_safely()
    kernel.ALERTS_LOG = (
        tmp_path_factory.mktemp("alert-log") / "ledger-alerts.jsonl"
    )
    try:
        yield
    finally:
        _drain_safely()
        kernel.ALERTS_LOG = saved_log


def _atomic_restore(path: Path, data: bytes) -> None:
    """Restore `path` to `data` via sibling tempfile + os.replace.

    Uses the same atomic-write pattern as tests/test_morningstar.py
    `_atomic_write_bytes` so we don't briefly truncate the ledger
    during teardown — concurrent appender workflows must always see
    either the old bytes or the new bytes, never an empty file.
    """
    import os as _os

    tmp = path.with_name(path.name + ".session-restore.tmp")
    tmp.write_bytes(data)
    _os.replace(tmp, path)
