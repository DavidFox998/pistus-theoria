import { useListCertificates } from "@workspace/api-client-react";
import { Link } from "wouter";
import { ShaChip } from "@/components/sha-chip";
import { StatusBadge } from "@/components/status-badge";
import { PdfUploader } from "@/components/pdf-uploader";
import { FileText, ArrowRight } from "lucide-react";
import { Button } from "@/components/ui/button";

export default function CertificatesPage() {
  const { data: certificates, isLoading } = useListCertificates();

  if (isLoading) {
    return (
      <div className="space-y-4 animate-pulse">
        <div className="h-10 w-48 bg-muted mb-8"></div>
        {[1, 2, 3, 4, 5, 6, 7].map(i => (
          <div key={i} className="h-20 w-full bg-muted border border-border"></div>
        ))}
      </div>
    );
  }

  if (!certificates) return <div className="text-destructive font-mono text-sm">FAILED TO LOAD CERTIFICATES</div>;

  return (
    <div className="space-y-6">
      <header>
        <h2 className="text-2xl font-bold font-sans tracking-tight mb-2">Module Certificates</h2>
        <p className="text-sm font-mono text-muted-foreground">CHAIN OF TRUST FOR THEOREMA AUREUM 143</p>
      </header>

      <div className="flex flex-col gap-3">
        {certificates.sort((a, b) => a.dagPosition - b.dagPosition).map((cert, i) => (
          <div 
            key={cert.moduleId} 
            className="flex flex-col border border-border bg-card overflow-hidden animate-in fade-in slide-in-from-bottom-2"
            style={{ animationDelay: `${i * 50}ms`, animationFillMode: 'both' }}
          >
            <div className="flex flex-col md:flex-row md:items-center p-4 gap-4">
              <div className="flex items-center gap-4 w-full md:w-1/4">
                <div className="bg-primary text-primary-foreground font-mono font-bold text-sm px-2 py-1 min-w-[3rem] text-center">
                  {cert.moduleId}
                </div>
                <StatusBadge status={cert.status} />
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="font-sans font-bold truncate" title={cert.title}>{cert.title}</div>
                <div className="text-xs font-mono text-muted-foreground truncate mt-1" title={cert.claim}>
                  {cert.claim}
                </div>
              </div>

              <div className="flex items-center gap-3 w-full md:w-auto mt-4 md:mt-0 justify-between md:justify-end border-t border-border pt-4 md:border-0 md:pt-0">
                <div className="flex items-center gap-2">
                  <div className="text-xs font-mono text-muted-foreground hidden md:block">OUT:</div>
                  <ShaChip sha={cert.stdoutSha} />
                </div>
                
                <div className="flex items-center gap-2">
                  {!cert.pdfObjectPath ? (
                    <PdfUploader moduleId={cert.moduleId} />
                  ) : (
                    <div className="flex items-center text-xs font-mono text-muted-foreground border border-border px-2 py-1">
                      <FileText className="w-3 h-3 mr-2" /> PDF ATTACHED
                    </div>
                  )}
                  <Link href={`/certificates/${cert.moduleId}`} className="flex-shrink-0">
                    <Button variant="secondary" size="sm" className="font-mono text-xs px-3" data-testid={`button-inspect-${cert.moduleId}`}>
                      INSPECT <ArrowRight className="w-3 h-3 ml-2" />
                    </Button>
                  </Link>
                </div>
              </div>
            </div>
            
            {cert.parentShas.length > 0 && (
              <div className="px-4 py-2 bg-muted/50 border-t border-border flex items-center gap-4 overflow-x-auto">
                <span className="text-xs font-mono text-muted-foreground whitespace-nowrap">DEPENDS ON:</span>
                <div className="flex gap-2">
                  {cert.parentShas.map((sha, idx) => (
                    <div key={idx} className="bg-background border border-border px-2 py-0.5">
                      <ShaChip sha={sha} />
                    </div>
                  ))}
                </div>
              </div>
            )}
          </div>
        ))}
      </div>
    </div>
  );
}
