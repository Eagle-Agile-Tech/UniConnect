SET search_path TO public;

-- Add isNetworkedBy to UserProfile
ALTER TABLE "UserProfile" ADD COLUMN IF NOT EXISTS "networkCount" INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "UserProfile" ADD COLUMN IF NOT EXISTS "isNetworkedBy" BOOLEAN NOT NULL DEFAULT false;
