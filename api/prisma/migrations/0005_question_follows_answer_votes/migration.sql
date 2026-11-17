-- CreateTable
CREATE TABLE "questionFollows" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "postId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "extra" JSONB,

    CONSTRAINT "questionFollows_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "answerVotes" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "commentId" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "extra" JSONB,

    CONSTRAINT "answerVotes_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "questionFollows_postId_idx" ON "questionFollows"("postId");

-- CreateIndex
CREATE INDEX "questionFollows_userId_idx" ON "questionFollows"("userId");

-- CreateIndex
CREATE INDEX "answerVotes_commentId_idx" ON "answerVotes"("commentId");

-- CreateIndex
CREATE INDEX "answerVotes_userId_idx" ON "answerVotes"("userId");

-- AddForeignKey
ALTER TABLE "questionFollows" ADD CONSTRAINT "questionFollows_postId_fkey" FOREIGN KEY ("postId") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "questionFollows" ADD CONSTRAINT "questionFollows_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "answerVotes" ADD CONSTRAINT "answerVotes_commentId_fkey" FOREIGN KEY ("commentId") REFERENCES "comments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "answerVotes" ADD CONSTRAINT "answerVotes_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
