-- AlterTable
ALTER TABLE "staffSessions" ADD COLUMN     "expiresAt" TIMESTAMPTZ(3),
ADD COLUMN     "remember" BOOLEAN,
ADD COLUMN     "tokenHash" TEXT;

-- CreateIndex
CREATE INDEX "staffSessions_tokenHash_idx" ON "staffSessions"("tokenHash");

