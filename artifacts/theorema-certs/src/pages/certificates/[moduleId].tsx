import { useParams } from "wouter";
import { useGetCertificate, getGetCertificateQueryKey } from "@workspace/api-client-react";
import { ShaChip } from "@/components/sha-chip";
import { StatusBadge } from "@/components/status-badge";
import { PdfUploader } from "@/components/pdf-uploader";
import { ArrowLeft, FileText, Code2, Clock } from "lucide-react";
import { Link } from "wouter";
import { Card } from "@/components/ui/card";
import { format } from "date-fns";

export default function CertificateDetailPage() {
  const params = useParams();
  const moduleId = params.moduleId!;

  const { data: cert, isLoading } = useGetCertificate(moduleId, {
    query: { enabled: !!moduleId, queryKey: getGetCertificateQueryKey(moduleId) }
  });

  if (isLoading) {
    return <div className="animate-pulse space-y-4">
      <div className="h-8 w-32 bg-muted mb-6"></div>
      <div className="h-64 bg-muted border border-border"></div>
    </div>;
  }

  if (!cert) {
    return <div className="text-destructive font-mono text-sm">CERTIFICATE NOT FOUND</div>;
  }

  return (
    <div className="space-y-6">
      <Link href="/certificates" className="inline-flex items-center text-xs font-mono text-muted-foreground hover:text-foreground transition-colors mb-4">
        <ArrowLeft className="w-3 h-3 mr-2" /> BACK TO LEDGER
      </Link>

      <header className="flex flex-col md:flex-row md:items-start justify-between gap-4 border-b border-border pb-6">
        <div>
          <div className="flex items-center gap-3 mb-2">
            <h2 className="text-3xl font-bold font-sans tracking-tight">{cert.moduleId}</h2>
            <StatusBadge status={cert.status} />
          </div>
          <h1 className="text-xl font-sans text-foreground/90">{cert.title}</h1>
        </div>
        <div className="flex items-center gap-2">
          {!cert.pdfObjectPath && <PdfUploader moduleId={cert.moduleId} />}
        </div>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2 space-y-6">
          <Card className="p-6 border-border bg-card">
            <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider mb-4 border-b border-border pb-2">Mathematical Claim</h3>
            <p className="font-serif text-lg leading-relaxed text-foreground/90 bg-muted/30 p-4 border-l-4 border-primary">
              {cert.claim}
            </p>
          </Card>

          <Card className="p-0 border-border bg-card overflow-hidden flex flex-col">
            <div className="p-4 border-b border-border bg-muted/30 flex items-center justify-between">
              <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider flex items-center gap-2">
                <FileText className="w-4 h-4" /> Proof Document
              </h3>
            </div>
            <div className="bg-background min-h-[400px] lg:min-h-[600px] flex-1 relative">
              {cert.pdfObjectPath ? (
                <iframe 
                  src={`/api/storage/objects/${encodeURIComponent(cert.pdfObjectPath)}`}
                  className="absolute inset-0 w-full h-full border-0"
                  title={`Proof Document for ${cert.moduleId}`}
                />
              ) : (
                <div className="absolute inset-0 flex flex-col items-center justify-center text-muted-foreground font-mono text-sm">
                  <FileText className="w-12 h-12 mb-4 opacity-20" />
                  <div>NO PROOF DOCUMENT ATTACHED</div>
                  <div className="mt-4"><PdfUploader moduleId={cert.moduleId} /></div>
                </div>
              )}
            </div>
          </Card>
        </div>

        <div className="space-y-6">
          <Card className="p-6 border-border bg-card">
            <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider mb-4 border-b border-border pb-2">Cryptographic Fingerprints</h3>
            <div className="space-y-4">
              <div>
                <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase">Source Output (STDOUT)</div>
                <div className="bg-muted p-2 border border-border">
                  <ShaChip sha={cert.stdoutSha} truncate={false} />
                </div>
              </div>
              <div>
                <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase">Source File</div>
                {cert.sourceFile ? (
                  <div className="font-mono text-xs text-foreground bg-muted p-2 border border-border">
                    {cert.sourceFile}
                  </div>
                ) : (
                  <div className="font-mono text-xs text-muted-foreground">N/A</div>
                )}
              </div>
              <div>
                <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase">Source Digest</div>
                <div className="bg-muted p-2 border border-border">
                  <ShaChip sha={cert.sourceSha} truncate={false} />
                </div>
              </div>
            </div>
          </Card>

          <Card className="p-6 border-border bg-card">
            <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider mb-4 border-b border-border pb-2">DAG Lineage</h3>
            <div className="space-y-3">
              <div>
                <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase">DAG Position</div>
                <div className="font-mono text-sm">{cert.dagPosition} / 7</div>
              </div>
              <div>
                <div className="text-[10px] font-mono text-muted-foreground mb-2 uppercase">Parent Bindings</div>
                {cert.parentShas.length > 0 ? (
                  <ul className="space-y-2">
                    {cert.parentShas.map((sha, idx) => (
                      <li key={idx} className="bg-muted p-2 border border-border">
                        <ShaChip sha={sha} truncate={true} />
                      </li>
                    ))}
                  </ul>
                ) : (
                  <div className="font-mono text-xs text-muted-foreground">ROOT NODE - NO PARENTS</div>
                )}
              </div>
            </div>
          </Card>

          <Card className="p-6 border-border bg-card">
            <h3 className="text-xs font-mono font-bold text-muted-foreground uppercase tracking-wider mb-4 border-b border-border pb-2">Metadata</h3>
            <div className="space-y-4">
              {cert.leanBinding && (
                <div>
                  <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase flex items-center gap-1">
                    <Code2 className="w-3 h-3" /> Lean 4 Binding
                  </div>
                  <div className="font-mono text-xs text-primary bg-primary/10 p-2 border border-primary/20">
                    {cert.leanBinding}
                  </div>
                </div>
              )}
              {cert.notes && (
                <div>
                  <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase">Committee Notes</div>
                  <p className="text-sm text-foreground/80 leading-snug">
                    {cert.notes}
                  </p>
                </div>
              )}
              {cert.updatedAt && (
                <div>
                  <div className="text-[10px] font-mono text-muted-foreground mb-1 uppercase flex items-center gap-1">
                    <Clock className="w-3 h-3" /> Last Updated
                  </div>
                  <div className="font-mono text-xs">
                    {format(new Date(cert.updatedAt), "yyyy-MM-dd HH:mm:ss 'UTC'")}
                  </div>
                </div>
              )}
            </div>
          </Card>
        </div>
      </div>
    </div>
  );
}
