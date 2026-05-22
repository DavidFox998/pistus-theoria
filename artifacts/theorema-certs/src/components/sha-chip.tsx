import { useState } from "react";
import { Copy, Check } from "lucide-react";

interface ShaChipProps {
  sha: string;
  truncate?: boolean;
}

export function ShaChip({ sha, truncate = true }: ShaChipProps) {
  const [copied, setCopied] = useState(false);

  const displaySha = truncate && sha.length > 16 
    ? `${sha.substring(0, 8)}...${sha.substring(sha.length - 8)}` 
    : sha;

  const handleCopy = () => {
    navigator.clipboard.writeText(sha);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  if (!sha) return <span className="text-muted-foreground font-mono text-xs">N/A</span>;

  return (
    <div 
      className="inline-flex items-center gap-2 group cursor-pointer hover:bg-muted p-1 -m-1 transition-colors border border-transparent hover:border-border"
      onClick={handleCopy}
      title={sha}
      data-testid={`sha-chip-${sha.substring(0, 8)}`}
    >
      <span className="font-mono text-xs text-foreground/80 group-hover:text-foreground">
        {displaySha}
      </span>
      <span className="text-muted-foreground group-hover:text-foreground">
        {copied ? <Check className="w-3 h-3 text-green-600 dark:text-green-400" /> : <Copy className="w-3 h-3 opacity-0 group-hover:opacity-100 transition-opacity" />}
      </span>
    </div>
  );
}
