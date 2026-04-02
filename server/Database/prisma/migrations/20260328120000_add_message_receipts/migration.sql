-- Add clientMessageId to Message and create MessageReceipt table
ALTER TABLE "Message" ADD COLUMN "clientMessageId" TEXT;

CREATE TABLE "MessageReceipt" (
    "id" TEXT NOT NULL,
    "messageId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "deliveredAt" TIMESTAMP(3),
    "readAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "MessageReceipt_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX "MessageReceipt_messageId_userId_key" ON "MessageReceipt"("messageId", "userId");
CREATE INDEX "MessageReceipt_userId_idx" ON "MessageReceipt"("userId");
CREATE INDEX "MessageReceipt_messageId_idx" ON "MessageReceipt"("messageId");

CREATE UNIQUE INDEX "Message_senderId_clientMessageId_key" ON "Message"("senderId", "clientMessageId");

ALTER TABLE "MessageReceipt" ADD CONSTRAINT "MessageReceipt_messageId_fkey" FOREIGN KEY ("messageId") REFERENCES "Message"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
ALTER TABLE "MessageReceipt" ADD CONSTRAINT "MessageReceipt_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
