ALTER TABLE "UserProfileML"
ADD COLUMN "embeddingSource" TEXT;

ALTER TABLE "ContentEmbedding"
ADD COLUMN "embeddingSource" TEXT,
ADD COLUMN "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;

UPDATE "UserProfileML"
SET "embeddingSource" = COALESCE("embeddingSource", 'legacy-semantic')
WHERE "embedding" IS NOT NULL;

UPDATE "ContentEmbedding"
SET "embeddingSource" = COALESCE("embeddingSource", 'legacy-semantic')
WHERE "embedding" IS NOT NULL;
