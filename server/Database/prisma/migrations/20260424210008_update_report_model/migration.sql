-- AlterTable
ALTER TABLE "Report" ADD COLUMN     "isFlagged" BOOLEAN NOT NULL DEFAULT false;

-- CreateIndex
CREATE INDEX "Report_isFlagged_idx" ON "Report"("isFlagged");
