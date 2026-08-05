-- AlterTable
ALTER TABLE "document_verification" ADD COLUMN     "bien_id" UUID;

-- CreateIndex
CREATE INDEX "document_verification_bien_id_idx" ON "document_verification"("bien_id");

-- AddForeignKey
ALTER TABLE "document_verification" ADD CONSTRAINT "document_verification_bien_id_fkey" FOREIGN KEY ("bien_id") REFERENCES "bien"("id") ON DELETE CASCADE ON UPDATE CASCADE;
