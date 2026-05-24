import { useEffect, useRef, useState, type ReactNode } from "react";
import { useGetLeanVerification } from "@workspace/api-client-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";

interface VerifyTxtDialogProps {
  trigger: ReactNode;
  highlightBinding?: string;
}

function findHighlightLineIndex(
  content: string,
  binding: string | undefined,
): number {
  if (!binding) return -1;
  const last = binding.includes(".")
    ? binding.slice(binding.lastIndexOf(".") + 1)
    : binding;
  const lines = content.split("\n");
  const fullIdx = lines.findIndex((line) => line.includes(binding));
  if (fullIdx >= 0) return fullIdx;
  return lines.findIndex((line) => line.includes(last));
}

export function VerifyTxtDialog({
  trigger,
  highlightBinding,
}: VerifyTxtDialogProps) {
  const { data } = useGetLeanVerification();
  const [open, setOpen] = useState(false);
  const highlightRef = useRef<HTMLSpanElement | null>(null);

  const content: string = data?.content ?? "";
  const lines: string[] = content.split("\n");
  const highlightIdx = findHighlightLineIndex(content, highlightBinding);

  useEffect(() => {
    if (!open) return;
    const id = window.setTimeout(() => {
      highlightRef.current?.scrollIntoView({
        behavior: "smooth",
        block: "center",
      });
    }, 50);
    return () => window.clearTimeout(id);
  }, [open, highlightIdx]);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{trigger}</DialogTrigger>
      <DialogContent className="max-w-3xl">
        <DialogHeader>
          <DialogTitle className="font-mono text-sm uppercase">
            lean-proof/VERIFY.txt
          </DialogTitle>
        </DialogHeader>
        {data ? (
          <pre
            className="bg-muted border border-border p-4 font-mono text-xs whitespace-pre-wrap overflow-auto max-h-[70vh]"
            data-testid="text-verify-content"
          >
            {lines.map((line, idx) => {
              const isHighlight = idx === highlightIdx;
              if (isHighlight) {
                return (
                  <span
                    key={idx}
                    ref={highlightRef}
                    data-testid={`verify-line-highlight`}
                    className="block bg-yellow-200 dark:bg-yellow-500/30 text-foreground"
                  >
                    {line || " "}
                    {"\n"}
                  </span>
                );
              }
              return (
                <span key={idx}>
                  {line}
                  {"\n"}
                </span>
              );
            })}
          </pre>
        ) : (
          <p className="text-xs font-mono text-muted-foreground">
            Verification log unavailable.
          </p>
        )}
      </DialogContent>
    </Dialog>
  );
}
