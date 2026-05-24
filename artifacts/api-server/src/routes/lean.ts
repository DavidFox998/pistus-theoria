import { Router, type IRouter } from "express";
import { existsSync, readFileSync, statSync } from "node:fs";
import { spawn } from "node:child_process";
import path from "node:path";

const router: IRouter = Router();

function resolveRepoRoot(): string {
  const candidates = [
    process.cwd(),
    path.resolve(process.cwd(), "..", ".."),
    path.resolve(process.cwd(), ".."),
  ];
  for (const c of candidates) {
    if (existsSync(path.join(c, "lean-proof", "VERIFY.txt"))) return c;
    if (existsSync(path.join(c, "lean-proof", "regenerate.sh"))) return c;
  }
  return candidates[0];
}

const REPO_ROOT = resolveRepoRoot();
const VERIFY_PATH = path.join(REPO_ROOT, "lean-proof", "VERIFY.txt");
const REGENERATE_SCRIPT = path.join(REPO_ROOT, "lean-proof", "regenerate.sh");
const REBUILD_TIMEOUT_MS = 5 * 60 * 1000;

interface ParsedVerification {
  toolchain: string;
  dateVerified: string;
  axiomDebt: string[];
  axiomLines: string[];
  content: string;
  lastModified: string;
}

function parseVerification(content: string, lastModified: string): ParsedVerification {
  const toolchainMatch = content.match(/Lean toolchain\s*:\s*(.+)/);
  const dateMatch = content.match(/Date verified\s*:\s*(.+)/);
  const axiomLines = content
    .split("\n")
    .filter((l) => /does not depend on any axioms/.test(l))
    .map((l) => l.trim());
  const debtMatch = content.match(/Axiom debt\s*=\s*\[([^\]]*)\]/);
  const axiomDebt = debtMatch && debtMatch[1].trim().length > 0
    ? debtMatch[1].split(",").map((s) => s.trim()).filter(Boolean)
    : [];

  return {
    toolchain: toolchainMatch ? toolchainMatch[1].trim() : "unknown",
    dateVerified: dateMatch ? dateMatch[1].trim() : "unknown",
    axiomDebt,
    axiomLines,
    content,
    lastModified,
  };
}

let cached: ParsedVerification | null = null;
let cachedError: string | null = null;

function readVerification(): ParsedVerification | null {
  try {
    const content = readFileSync(VERIFY_PATH, "utf8");
    const stat = statSync(VERIFY_PATH);
    return parseVerification(content, stat.mtime.toISOString());
  } catch (err) {
    cachedError = err instanceof Error ? err.message : String(err);
    return null;
  }
}

function load(): ParsedVerification | null {
  if (cached) return cached;
  if (cachedError) return null;
  cached = readVerification();
  return cached;
}

function invalidateCache(): void {
  cached = null;
  cachedError = null;
}

router.get("/lean/verify", (req, res) => {
  const parsed = load();
  if (!parsed) {
    req.log.error({ path: VERIFY_PATH, err: cachedError }, "Failed to read VERIFY.txt");
    res.status(500).json({ error: "Verification log unavailable" });
    return;
  }
  const ageMs = Date.now() - new Date(parsed.lastModified).getTime();
  const ageDays = ageMs / (1000 * 60 * 60 * 24);
  res.json({ ...parsed, ageDays });
});

let rebuildInFlight = false;

function extractBearerToken(header: string | undefined): string | null {
  if (!header) return null;
  const match = header.match(/^Bearer\s+(.+)$/i);
  return match ? match[1].trim() : null;
}

function timingSafeEqual(a: string, b: string): boolean {
  if (a.length !== b.length) return false;
  let diff = 0;
  for (let i = 0; i < a.length; i++) {
    diff |= a.charCodeAt(i) ^ b.charCodeAt(i);
  }
  return diff === 0;
}

router.post("/lean/verify/rebuild", (req, res) => {
  const start = Date.now();

  const expectedToken = process.env["LEAN_REBUILD_TOKEN"];
  if (!expectedToken || expectedToken.length === 0) {
    req.log.warn("Rebuild blocked: LEAN_REBUILD_TOKEN not configured");
    res.status(503).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: 0,
      error:
        "Lean rebuild is disabled on this server: LEAN_REBUILD_TOKEN is not configured. Set the secret to enable referee-driven rebuilds.",
      verification: null,
    });
    return;
  }

  const provided = extractBearerToken(req.headers["authorization"]);
  if (!provided || !timingSafeEqual(provided, expectedToken)) {
    req.log.warn({ hasHeader: Boolean(provided) }, "Rebuild blocked: bad token");
    res.status(401).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: 0,
      error:
        "Unauthorized: a valid referee rebuild token is required (Authorization: Bearer <token>).",
      verification: null,
    });
    return;
  }

  if (rebuildInFlight) {
    res.status(409).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: 0,
      error: "A Lean rebuild is already in progress. Please wait for it to finish before triggering another.",
      verification: null,
    });
    return;
  }

  if (!existsSync(REGENERATE_SCRIPT)) {
    req.log.error({ path: REGENERATE_SCRIPT }, "regenerate.sh not found");
    res.status(200).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: 0,
      error: `regenerate.sh not found at ${REGENERATE_SCRIPT}`,
      verification: null,
    });
    return;
  }

  rebuildInFlight = true;
  let child;
  try {
    child = spawn("bash", [REGENERATE_SCRIPT], {
      cwd: REPO_ROOT,
      env: process.env,
    });
  } catch (err) {
    rebuildInFlight = false;
    const message = err instanceof Error ? err.message : String(err);
    req.log.error({ err: message }, "Failed to spawn regenerate.sh");
    res.status(200).json({
      ok: false,
      exitCode: -1,
      stdout: "",
      stderr: "",
      durationMs: Date.now() - start,
      error: `Failed to spawn rebuild: ${message}`,
      verification: null,
    });
    return;
  }

  let stdout = "";
  let stderr = "";
  let timedOut = false;

  child.stdout.on("data", (chunk: Buffer) => {
    stdout += chunk.toString("utf8");
  });
  child.stderr.on("data", (chunk: Buffer) => {
    stderr += chunk.toString("utf8");
  });

  const timer = setTimeout(() => {
    timedOut = true;
    child.kill("SIGKILL");
  }, REBUILD_TIMEOUT_MS);

  let responded = false;
  const finish = (
    payload: {
      ok: boolean;
      exitCode: number;
      error: string | null;
    },
  ) => {
    if (responded) return;
    responded = true;
    clearTimeout(timer);
    rebuildInFlight = false;
    const durationMs = Date.now() - start;

    invalidateCache();
    let verification: (ParsedVerification & { ageDays: number }) | null = null;
    if (payload.ok) {
      const parsed = readVerification();
      if (parsed) {
        cached = parsed;
        const ageMs = Date.now() - new Date(parsed.lastModified).getTime();
        verification = { ...parsed, ageDays: ageMs / (1000 * 60 * 60 * 24) };
      }
    }

    req.log.info(
      {
        ok: payload.ok,
        exitCode: payload.exitCode,
        durationMs,
        error: payload.error,
      },
      "Lean rebuild attempted",
    );

    res.status(200).json({
      ok: payload.ok,
      exitCode: payload.exitCode,
      stdout,
      stderr,
      durationMs,
      error: payload.error,
      verification,
    });
  };

  child.on("error", (err) => {
    const message = err instanceof Error ? err.message : String(err);
    finish({ ok: false, exitCode: -1, error: `Spawn error: ${message}` });
  });

  child.on("close", (code, signal) => {
    if (timedOut) {
      finish({
        ok: false,
        exitCode: code ?? -1,
        error: `Rebuild timed out after ${REBUILD_TIMEOUT_MS / 1000}s and was killed (${signal ?? "SIGKILL"}).`,
      });
      return;
    }
    const exitCode = code ?? -1;
    if (exitCode === 0) {
      finish({ ok: true, exitCode, error: null });
      return;
    }
    let error: string;
    if (exitCode === 127) {
      error = "`lake` (Lean 4) is not installed in this environment, so the proof cannot be re-verified.";
    } else if (exitCode === 2) {
      error = "Axiom-debt check failed: the Lean proof has drifted. VERIFY.txt was NOT overwritten.";
    } else {
      error = `Rebuild script exited with code ${exitCode}.`;
    }
    finish({ ok: false, exitCode, error });
  });
});

export default router;
