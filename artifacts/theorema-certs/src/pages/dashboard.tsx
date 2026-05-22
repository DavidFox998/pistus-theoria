import { useGetCertificateSummary, useListCertificates } from "@workspace/api-client-react";
import { ShaChip } from "@/components/sha-chip";
import { StatusBadge } from "@/components/status-badge";
import { Card } from "@/components/ui/card";
import { Link } from "wouter";

export default function DashboardPage() {
  const { data: summary, isLoading: isSummaryLoading } = useGetCertificateSummary();
  const { data: certificates, isLoading: isCertsLoading } = useListCertificates();

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
            {summary.pdfUploadedCount} / {summary.totalModules}
          </span>
        </Card>
      </div>

      <Card className="p-6 border-border bg-card">
        <h3 className="text-sm font-mono font-bold mb-4 uppercase text-muted-foreground border-b border-border pb-2">Master Manifest</h3>
        <div className="flex flex-col gap-2">
          <span className="text-xs font-mono text-muted-foreground">SHA-256 DIGEST (M1..M7 CHAIN)</span>
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
