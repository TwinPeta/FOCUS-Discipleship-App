-- AlterTable
ALTER TABLE "resourceProgress" ADD COLUMN     "reflection" TEXT,
ADD COLUMN     "reflectionAt" TIMESTAMPTZ(3);

-- AlterTable
ALTER TABLE "quizAttempts" ADD COLUMN     "answers" JSONB;

-- CreateTable
CREATE TABLE "postMarks" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "postId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "kind" TEXT NOT NULL,
    "extra" JSONB,

    CONSTRAINT "postMarks_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "testimonyEncouragements" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "testimonyId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "extra" JSONB,

    CONSTRAINT "testimonyEncouragements_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "postMarks_postId_idx" ON "postMarks"("postId");

-- CreateIndex
CREATE INDEX "postMarks_userId_idx" ON "postMarks"("userId");

-- CreateIndex
CREATE INDEX "testimonyEncouragements_testimonyId_idx" ON "testimonyEncouragements"("testimonyId");

-- CreateIndex
CREATE INDEX "testimonyEncouragements_userId_idx" ON "testimonyEncouragements"("userId");

-- AddForeignKey
ALTER TABLE "postMarks" ADD CONSTRAINT "postMarks_postId_fkey" FOREIGN KEY ("postId") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "postMarks" ADD CONSTRAINT "postMarks_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "testimonyEncouragements" ADD CONSTRAINT "testimonyEncouragements_testimonyId_fkey" FOREIGN KEY ("testimonyId") REFERENCES "testimonies"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "testimonyEncouragements" ADD CONSTRAINT "testimonyEncouragements_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
