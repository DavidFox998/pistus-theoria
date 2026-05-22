import { Check, Clock, Lock } from "lucide-react";

type CertificateStatus = "CERTIFIED" | "AWAITING" | "LOCKED";

interface StatusBadgeProps {
  status: CertificateStatus;
}

export function StatusBadge({ status }: StatusBadgeProps) {
  switch (status) {
    case "CERTIFIED":
      return (
        <div className="inline-flex items-center gap-1.5 px-2 py-0.5 border border-green-500/30 bg-green-500/10 text-green-700 dark:text-green-400 font-mono text-xs uppercase tracking-wider font-semibold" data-testid={`status-${status}`}>
          <Check className="w-3 h-3" />
          {status}
        </div>
      );
    case "AWAITING":
      return (
        <div className="inline-flex items-center gap-1.5 px-2 py-0.5 border border-amber-500/30 bg-amber-500/10 text-amber-700 dark:text-amber-400 font-mono text-xs uppercase tracking-wider font-semibold" data-testid={`status-${status}`}>
          <Clock className="w-3 h-3" />
          {status}
        </div>
      );
    case "LOCKED":
      return (
        <div className="inline-flex items-center gap-1.5 px-2 py-0.5 border border-muted-foreground/30 bg-muted text-muted-foreground font-mono text-xs uppercase tracking-wider font-semibold" data-testid={`status-${status}`}>
          <Lock className="w-3 h-3" />
          {status}
        </div>
      );
    default:
      return (
        <div className="inline-flex items-center gap-1.5 px-2 py-0.5 border border-muted font-mono text-xs uppercase tracking-wider" data-testid={`status-${status}`}>
          {status}
        </div>
      );
  }
}
