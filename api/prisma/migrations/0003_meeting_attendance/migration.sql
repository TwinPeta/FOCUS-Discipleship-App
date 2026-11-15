-- CreateTable
CREATE TABLE "meetingAttendance" (
    "id" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "userId" TEXT NOT NULL,
    "communityId" TEXT NOT NULL,
    "meetingId" TEXT NOT NULL,
    "going" BOOLEAN NOT NULL,
    "attendedAt" TIMESTAMPTZ(3),
    "extra" JSONB,

    CONSTRAINT "meetingAttendance_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "meetingAttendance_userId_idx" ON "meetingAttendance"("userId");

-- CreateIndex
CREATE INDEX "meetingAttendance_meetingId_idx" ON "meetingAttendance"("meetingId");

-- AddForeignKey
ALTER TABLE "meetingAttendance" ADD CONSTRAINT "meetingAttendance_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "meetingAttendance" ADD CONSTRAINT "meetingAttendance_communityId_fkey" FOREIGN KEY ("communityId") REFERENCES "communities"("id") ON DELETE CASCADE ON UPDATE CASCADE;

