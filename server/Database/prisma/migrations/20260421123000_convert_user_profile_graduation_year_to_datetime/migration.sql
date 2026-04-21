ALTER TABLE "UserProfile"
ALTER COLUMN "graduationYear" TYPE TIMESTAMP(3)
USING (
  CASE
    WHEN "graduationYear" IS NULL THEN NULL
    ELSE make_timestamp("graduationYear", 1, 1, 0, 0, 0)
  END
);
