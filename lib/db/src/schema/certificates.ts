import { pgTable, text, integer, boolean, timestamp } from "drizzle-orm/pg-core";
import { createInsertSchema } from "drizzle-zod";
import { z } from "zod/v4";

export const certificatesTable = pgTable("certificates", {
  moduleId: text("module_id").primaryKey(),
  title: text("title").notNull(),
  claim: text("claim").notNull(),
  status: text("status").notNull().default("AWAITING"),
  sourceFile: text("source_file"),
  sourceSha: text("source_sha").notNull(),
  stdoutSha: text("stdout_sha").notNull(),
  parentShas: text("parent_shas").notNull().default("[]"),
  dagPosition: integer("dag_position").notNull(),
  pdfObjectPath: text("pdf_object_path"),
  leanBinding: text("lean_binding"),
  notes: text("notes"),
  updatedAt: timestamp("updated_at").notNull().defaultNow(),
});

export const insertCertificateSchema = createInsertSchema(certificatesTable).omit({
  updatedAt: true,
});
export type InsertCertificate = z.infer<typeof insertCertificateSchema>;
export type Certificate = typeof certificatesTable.$inferSelect;
