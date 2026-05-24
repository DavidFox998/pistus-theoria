import { useGetLeanVerification } from "@workspace/api-client-react";
import { ShieldCheck, ShieldQuestion } from "lucide-react";
import { VerifyTxtDialog } from "@/components/verify-txt-dialog";

interface LeanAxiomChipProps {
  leanBinding: string;
  size?: "sm" | "md";
}

function bindingAppearsInAxiomLines(binding: string, lines: string[]): boolean {
  const last = binding.includes(".") ? binding.slice(binding.lastIndexOf(".") + 1) : binding;
  return lines.some((line) => line.includes(binding) || line.includes(last));
}

export function LeanAxiomChip({ leanBinding, size = "sm" }: LeanAxiomChipProps) {
  const { data } = useGetLeanVerification();

  const verified = !!data && bindingAppearsInAxiomLines(leanBinding, data.axiomLines);
  const padding = size === "sm" ? "px-2 py-0.5" : "px-3 py-1";
  const iconSize = size === "sm" ? "w-3 h-3" : "w-3.5 h-3.5";

  const title = verified
    ? `Lean: ${leanBinding} does not depend on any axioms — click to open VERIFY.txt`
    : data
      ? `Lean: ${leanBinding} not found in axiom verification lines — click to open VERIFY.txt`
      : `Lean verification log unavailable`;

  const chipContent = verified ? (
    <>
      <ShieldCheck className={iconSize} /> Lean: axiom debt = []
    </>
  ) : (
    <>
      <ShieldQuestion className={iconSize} /> Lean: unverified
    </>
  );

  const chipClasses = verified
    ? `inline-flex items-center gap-1 ${padding} border border-green-500/50 bg-green-500/10 font-mono text-[10px] font-bold uppercase text-green-700 dark:text-green-400 whitespace-nowrap`
    : `inline-flex items-center gap-1 ${padding} border border-border bg-muted font-mono text-[10px] font-bold uppercase text-muted-foreground whitespace-nowrap`;

  if (!data) {
    return (
      <span
        title={title}
        data-testid={`chip-lean-axiom-${leanBinding}`}
        className={chipClasses}
      >
        {chipContent}
      </span>
    );
  }

  return (
    <VerifyTxtDialog
      highlightBinding={leanBinding}
      trigger={
        <button
          type="button"
          title={title}
          data-testid={`chip-lean-axiom-${leanBinding}`}
          className={`${chipClasses} cursor-pointer hover:brightness-110 focus:outline-none focus-visible:ring-2 focus-visible:ring-ring`}
        >
          {chipContent}
        </button>
      }
    />
  );
}
