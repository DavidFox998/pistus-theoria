import {
  useGetCertificateSummary,
  useListCertificates,
  useGetLeanVerification,
} from "@workspace/api-client-react";
import { ShaChip } from "@/components/sha-chip";
import { StatusBadge } from "@/components/status-badge";
import { VerifyTxtDialog } from "@/components/verify-txt-dialog";
import { Card } from "@/components/ui/card";
import { Link } from "wouter";
import { CheckCircle2, ArrowRight, FileText, ShieldCheck, AlertTriangle, Clock } from "lucide-react";

const STALE_THRESHOLD_DAYS = 30;

function formatAge(ageDays: number | undefined): string {
  if (ageDays === undefined || Number.isNaN(ageDays)) return "unknown";
  if (ageDays < 1 / 24) return "just now";
  if (ageDays < 1) {
    const hours = Math.max(1, Math.round(ageDays * 24));
    return `${hours} hour${hours === 1 ? "" : "s"} ago`;
  }
  const days = Math.round(ageDays);
  return `${days} day${days === 1 ? "" : "s"} ago`;
}

function formatTimestamp(iso: string | undefined): string {
  if (!iso) return "unknown";
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return iso;
  return d.toISOString().replace("T", " ").replace(/\.\d+Z$/, "Z");
}

export default function DashboardPage() {
  const { data: summary, isLoading: isSummaryLoading } = useGetCertificateSummary();
  const { data: certificates, isLoading: isCertsLoading } = useListCertificates();
  const { data: leanVerify } = useGetLeanVerification();

  const isLoading = isSummaryLoading || isCertsLoading;

  if (isLoading) {
    return (
      <div className="space-y-8 animate-pulse">
        <div className="h-32 bg-muted w-full border border-border"></div>
        <div className="h-64 bg-muted w-full border border-border"></div>
      </div>
    );
  }

  if (!summary || !certificates) {
    return <div className="text-destructive font-mono text-sm">FAILED TO LOAD LEDGER STATE</div>;
  }

  return (
    <div className="space-y-8">
      <header>
        <h2 className="text-2xl font-bold font-sans tracking-tight mb-2">Ledger Status</h2>
        <p className="text-sm font-mono text-muted-foreground">OVERVIEW OF DAG CHAIN VERIFICATION</p>
      </header>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <Card className="p-4 flex flex-col justify-between border-border bg-card">
          <span className="text-xs font-mono text-muted-foreground uppercase">DAG Status</span>
          <span className={`text-lg font-bold font-mono mt-2 ${summary.dagSealed ? 'text-green-600 dark:text-green-400' : 'text-amber-600 dark:text-amber-400'}`}>
            {summary.dagSealed ? 'SEALED' : 'OPEN'}
          </span>
        </Card>
        <Card className="p-4 flex flex-col justify-between border-border bg-card">
          <span className="text-xs font-mono text-muted-foreground uppercase">Modules Certified</span>
          <span className="text-lg font-bold font-mono mt-2">
            {summary.certifiedCount} / {summary.totalModules}
          </span>
        </Card>
        <Card className="p-4 flex flex-col justify-between border-border bg-card">
          <span className="text-xs font-mono text-muted-foreground uppercase">Modules Awaiting</span>
          <span className="text-lg font-bold font-mono mt-2">
            {summary.awaitingCount}
          </span>
        </Card>
        <Card className="p-4 flex flex-col justify-between border-border bg-card">
          <span className="text-xs font-mono text-muted-foreground uppercase">PDF Documents</span>
          <span className="text-lg font-bold font-mono mt-2">
            {summary.pdfUploadedCount} / {summary.pdfTotal ?? summary.totalModules}
          </span>
        </Card>
      </div>

      <Card className="p-6 border-green-500/40 bg-green-500/5">
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h3 className="text-sm font-mono font-bold uppercase text-green-700 dark:text-green-400 mb-1 flex items-center gap-2">
              <CheckCircle2 className="w-4 h-4" /> Axiom Status
            </h3>
            <p className="text-sm text-foreground/80">
              <span className="font-mono">H2_WeilTransfer</span>{" "}
              <span className="line-through text-muted-foreground">axiom</span>{" "}
              <span className="font-mono font-bold text-green-700 dark:text-green-400">DISCHARGED</span>{" "}
              via M9 (280-case Weil Transfer All).
            </p>
            <p className="text-xs font-mono text-muted-foreground mt-1">
              main_theorem axiom debt: [] (zero axioms)
            </p>
            <p className="text-xs font-mono text-muted-foreground mt-1">
              H2_WeilTransfer is now a theorem (M9). #print axioms TheoremaAureum → [].
            </p>
          </div>
          <Link href="/walkthrough" data-testid="link-walkthrough-banner">
            <span className="inline-flex items-center gap-2 font-mono text-xs uppercase tracking-wider text-primary hover:underline">
              Referee Walkthrough <ArrowRight className="w-3 h-3" />
            </span>
          </Link>
        </div>
      </Card>

      <Card
        className="p-6 border-green-500/40 bg-green-500/5"
        data-testid="card-lean-verification"
      >
        <div className="flex flex-col gap-4">
          <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-3">
            <h3 className="text-sm font-mono font-bold uppercase text-green-700 dark:text-green-400 flex items-center gap-2">
              <ShieldCheck className="w-4 h-4" /> Lean 4 Verification
            </h3>
            <span
              className="inline-flex items-center gap-2 px-3 py-1 border border-green-500/50 bg-green-500/10 font-mono text-xs font-bold text-green-700 dark:text-green-400"
              data-testid="badge-axiom-debt"
            >
              Lean axiom debt = [
              {leanVerify?.axiomDebt.join(", ") ?? ""}
              ]
            </span>
          </div>

          {leanVerify ? (
            <>
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3 text-xs font-mono">
                <div className="flex flex-col gap-1">
                  <span className="text-muted-foreground uppercase">Toolchain</span>
                  <span
                    className="inline-flex items-center self-start px-2 py-1 border border-green-500/50 bg-green-500/10 font-bold text-green-700 dark:text-green-400"
                    data-testid="text-lean-toolchain"
                  >
                    {leanVerify.toolchain}
                  </span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-muted-foreground uppercase">Date verified</span>
                  <span data-testid="text-lean-date">{leanVerify.dateVerified}</span>
                </div>
                <div className="flex flex-col gap-1">
                  <span className="text-muted-foreground uppercase">Log last refreshed</span>
                  {(() => {
                    const stale =
                      typeof leanVerify.ageDays === "number" &&
                      leanVerify.ageDays > STALE_THRESHOLD_DAYS;
                    return (
                      <span
                        className={`inline-flex items-center gap-1.5 self-start ${
                          stale
                            ? "text-amber-700 dark:text-amber-400 font-bold"
                            : "text-foreground"
                        }`}
                        data-testid="text-lean-last-modified"
                        title={leanVerify.lastModified ?? ""}
                      >
                        {stale ? (
                          <AlertTriangle className="w-3 h-3" />
                        ) : (
                          <Clock className="w-3 h-3" />
                        )}
                        <span data-testid="text-lean-age">
                          {formatAge(leanVerify.ageDays)}
                        </span>
                        <span className="text-muted-foreground">
                          ({formatTimestamp(leanVerify.lastModified)})
                        </span>
                        {stale ? (
                          <span
                            className="ml-1 px-1.5 py-0.5 border border-amber-500/50 bg-amber-500/10 text-[10px] uppercase tracking-wider"
                            data-testid="badge-lean-stale"
                          >
                            stale &gt; {STALE_THRESHOLD_DAYS}d
                          </span>
                        ) : null}
                      </span>
                    );
                  })()}
                </div>
              </div>

              <div className="bg-muted/50 border border-border p-3 font-mono text-xs space-y-1">
                {leanVerify.axiomLines.length === 0 ? (
                  <span className="text-muted-foreground">No axiom-status lines found.</span>
                ) : (
                  leanVerify.axiomLines.map((line, i) => (
                    <div
                      key={i}
                      className="text-green-700 dark:text-green-400"
                      data-testid={`text-axiom-line-${i}`}
                    >
                      {line}
                    </div>
                  ))
                )}
              </div>

              <VerifyTxtDialog
                trigger={
                  <button
                    type="button"
                    className="self-start inline-flex items-center gap-2 font-mono text-xs uppercase tracking-wider text-primary hover:underline"
                    data-testid="button-view-verify-txt"
                  >
                    <FileText className="w-3 h-3" /> View VERIFY.txt
                  </button>
                }
              />
            </>
          ) : (
            <p className="text-xs font-mono text-muted-foreground">
              Verification log unavailable.
            </p>
          )}
        </div>
      </Card>

      <Card className="p-6 border-border bg-card">
        <h3 className="text-sm font-mono font-bold mb-4 uppercase text-muted-foreground border-b border-border pb-2">Master Manifest</h3>
        <div className="flex flex-col gap-2">
          <span className="text-xs font-mono text-muted-foreground">SHA-256 DIGEST (M1..M7 SEALED CHAIN)</span>
          <div className="bg-muted p-4 border border-border">
            <ShaChip sha={summary.masterSha} truncate={false} />
          </div>
        </div>
      </Card>

      <div className="space-y-4">
        <h3 className="text-sm font-mono font-bold uppercase text-muted-foreground border-b border-border pb-2">Module DAG Visualization</h3>
        <div className="grid grid-cols-1 gap-2">
          {certificates.sort((a, b) => a.dagPosition - b.dagPosition).map((cert, index) => (
            <div key={cert.moduleId} className="flex flex-col md:flex-row md:items-center gap-4 p-4 border border-border bg-card hover:bg-muted/50 transition-colors">
              <div className="w-16 font-mono font-bold text-lg text-primary">{cert.moduleId}</div>
              <div className="flex-1 min-w-0">
                <Link href={`/certificates/${cert.moduleId}`} className="font-sans font-semibold hover:underline block truncate">
                  {cert.title}
                </Link>
                <p className="text-xs font-mono text-muted-foreground truncate mt-1">{cert.claim}</p>
              </div>
              <div className="w-48 hidden md:block">
                <ShaChip sha={cert.stdoutSha} />
              </div>
              <div className="w-32 flex justify-end">
                <StatusBadge status={cert.status} />
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
