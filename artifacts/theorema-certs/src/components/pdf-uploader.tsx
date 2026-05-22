import { useState, useRef } from "react";
import { useRequestUploadUrl, useUpdateCertificate, getListCertificatesQueryKey, getGetCertificateQueryKey, getGetCertificateSummaryQueryKey } from "@workspace/api-client-react";
import { Button } from "@/components/ui/button";
import { useQueryClient } from "@tanstack/react-query";
import { Loader2, Upload } from "lucide-react";
import { useToast } from "@/hooks/use-toast";

interface PdfUploaderProps {
  moduleId: string;
}

export function PdfUploader({ moduleId }: PdfUploaderProps) {
  const [isUploading, setIsUploading] = useState(false);
  const fileInputRef = useRef<HTMLInputElement>(null);
  const { toast } = useToast();
  const queryClient = useQueryClient();
  
  const requestUrlMutation = useRequestUploadUrl();
  const updateCertMutation = useUpdateCertificate();

  const handleFileChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0];
    if (!file) return;

    if (file.type !== "application/pdf") {
      toast({
        title: "Invalid file type",
        description: "Only PDF files are permitted for module certificates.",
        variant: "destructive",
      });
      return;
    }

    setIsUploading(true);

    try {
      // 1. Get presigned URL
      const { uploadURL, objectPath } = await requestUrlMutation.mutateAsync({
        data: {
          name: file.name,
          size: file.size,
          contentType: file.type,
        }
      });

      // 2. Upload file directly to presigned URL
      const uploadResponse = await fetch(uploadURL, {
        method: "PUT",
        body: file,
        headers: {
          "Content-Type": file.type,
        },
      });

      if (!uploadResponse.ok) {
        throw new Error("Failed to upload file to storage");
      }

      // 3. Update certificate with the object path
      await updateCertMutation.mutateAsync({
        moduleId,
        data: {
          pdfObjectPath: objectPath,
        }
      });

      toast({
        title: "Upload successful",
        description: `Proof document attached to ${moduleId}.`,
      });

      // 4. Invalidate caches
      queryClient.invalidateQueries({ queryKey: getGetCertificateQueryKey(moduleId) });
      queryClient.invalidateQueries({ queryKey: getListCertificatesQueryKey() });
      queryClient.invalidateQueries({ queryKey: getGetCertificateSummaryQueryKey() });
      
    } catch (error) {
      console.error(error);
      toast({
        title: "Upload failed",
        description: "An error occurred while attaching the proof document.",
        variant: "destructive",
      });
    } finally {
      setIsUploading(false);
      if (fileInputRef.current) {
        fileInputRef.current.value = "";
      }
    }
  };

  return (
    <div>
      <input
        type="file"
        accept="application/pdf"
        className="hidden"
        ref={fileInputRef}
        onChange={handleFileChange}
        disabled={isUploading}
        data-testid={`input-upload-${moduleId}`}
      />
      <Button 
        variant="outline" 
        size="sm" 
        onClick={() => fileInputRef.current?.click()}
        disabled={isUploading}
        className="font-mono text-xs"
        data-testid={`button-upload-${moduleId}`}
      >
        {isUploading ? (
          <Loader2 className="w-3 h-3 mr-2 animate-spin" />
        ) : (
          <Upload className="w-3 h-3 mr-2" />
        )}
        UPLOAD PDF
      </Button>
    </div>
  );
}
