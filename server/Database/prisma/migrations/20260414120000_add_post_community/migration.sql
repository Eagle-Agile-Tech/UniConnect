-- Add communityId to Post for community-scoped posts
ALTER TABLE "Post" ADD COLUMN "communityId" TEXT;

-- Foreign key to Community
ALTER TABLE "Post"
ADD CONSTRAINT "Post_communityId_fkey"
FOREIGN KEY ("communityId") REFERENCES "Community"("id")
ON DELETE SET NULL ON UPDATE CASCADE;

-- Index for filtering posts by community
CREATE INDEX "Post_communityId_idx" ON "Post"("communityId");
