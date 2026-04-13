-- Create the missing EventView tracking table
CREATE TABLE IF NOT EXISTS "EventView" (
  "id" TEXT NOT NULL,
  "eventId" TEXT NOT NULL,
  "userId" TEXT NOT NULL,
  CONSTRAINT "EventView_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "EventView_eventId_userId_key" ON "EventView"("eventId", "userId");
