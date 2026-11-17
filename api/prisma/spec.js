/**
 * Relational layout of every store collection — the single source of truth for
 *   - prisma/schema.prisma   (generated: npm run prisma:schema)
 *   - src/db/mapping.js      (document <-> row conversion used by src/db/prisma.js)
 *
 * Column types:  s string · i int · b boolean · d timestamp (ISO string in memory) · D calendar date ('YYYY-MM-DD') · e epoch-ms number in memory
 *                j json · ss string[]      — suffix ? = nullable.
 * Every table also has: id (text PK), createdAt (timestamptz), extra (jsonb) — `extra` keeps any document
 * field that has no column (or whose runtime type doesn't match its column), so nothing is ever lost.
 * fk: field -> [parentCollection, nullable]. Required FKs cascade on delete; nullable FKs set null.
 */
module.exports = {
  // ── identity & structure
  institutions: { cols: { name: 's', type: 's', country: 's', city: 's?', shownInSignup: 'b' }, index: ['country'] },
  users: {
    cols: {
      fullName: 's?', username: 's?', email: 's?', phone: 's?', passwordHash: 's', birthdate: 'D?', country: 's?', institutionId: 's?',
      emailVerified: 'b', phoneVerified: 'b', minorStatus: 's?', platformRole: 's?', roleOverride: 's?', verifiedMentor: 'b', invited: 'b?', suspended: 'b?',
      photoMediaId: 's?', photoUrl: 's?', lastLoginAt: 'd?', deletedAt: 'd?', guardian: 'j?', consents: 'j?',
    },
    fk: { institutionId: ['institutions', true] }, unique: ['email', 'username'], index: ['phone', 'institutionId'],
  },
  communities: {
    cols: { type: 's', name: 's', initials: 's?', institutionId: 's?', description: 's?', meeting: 'j?', openForJoinRequests: 'b?', closed: 'b?' },
    fk: { institutionId: ['institutions', true] }, index: ['institutionId'],
  },
  memberships: {
    cols: { communityId: 's', userId: 's', role: 's', status: 's', joinedAt: 'd?' },
    fk: { communityId: ['communities'], userId: ['users'] }, index: ['communityId', 'userId'],
  },
  joinRequests: {
    cols: { communityId: 's', userId: 's', status: 's', decidedAt: 'd?', decidedBy: 's?', note: 's?' },
    fk: { communityId: ['communities'], userId: ['users'], decidedBy: ['users', true] }, index: ['communityId', 'userId', 'status'],
  },

  // ── community content
  posts: {
    cols: { communityId: 's', authorId: 's', text: 's', pinned: 'b', hidden: 'b?', mediaIds: 'ss' },
    fk: { communityId: ['communities'], authorId: ['users'] }, index: ['communityId', 'authorId'],
  },
  likes: { cols: { postId: 's', userId: 's' }, fk: { postId: ['posts'], userId: ['users'] }, index: ['postId', 'userId'] },
  comments: { cols: { postId: 's', authorId: 's', text: 's' }, fk: { postId: ['posts'], authorId: ['users'] }, index: ['postId'] },
  // People following a question (told when it gets an answer).
  questionFollows: { cols: { postId: 's', userId: 's' }, fk: { postId: ['posts'], userId: ['users'] }, index: ['postId', 'userId'] },
  // "Helpful" votes on an answer (a comment on a question).
  answerVotes: { cols: { commentId: 's', userId: 's' }, fk: { commentId: ['comments'], userId: ['users'] }, index: ['commentId', 'userId'] },
  prayerRequests: {
    cols: { communityId: 's', authorId: 's', anonymous: 'b', text: 's' },
    fk: { communityId: ['communities'], authorId: ['users'] }, index: ['communityId'],
  },
  prayed: { cols: { prayerRequestId: 's', userId: 's' }, fk: { prayerRequestId: ['prayerRequests'], userId: ['users'] }, index: ['prayerRequestId'] },
  prayerResponses: { cols: { prayerRequestId: 's', authorId: 's', text: 's' }, fk: { prayerRequestId: ['prayerRequests'], authorId: ['users'] }, index: ['prayerRequestId'] },
  testimonies: {
    cols: { communityId: 's', authorId: 's', title: 's?', body: 's?', status: 's', mediaIds: 'ss', approvedBy: 's?', publishedAt: 'd?', reviewNotes: 's?', reviewedBy: 's?' },
    fk: { communityId: ['communities'], authorId: ['users'], approvedBy: ['users', true], reviewedBy: ['users', true] }, index: ['communityId', 'status'],
  },

  // ── learning
  pathways: { cols: { title: 's', steps: 'j' } },
  pathwayProgress: { cols: { userId: 's', pathwayId: 's', completedStepIds: 'ss' }, fk: { userId: ['users'], pathwayId: ['pathways'] }, index: ['userId', 'pathwayId'] },
  resources: {
    cols: {
      communityId: 's?', addedBy: 's?', status: 's', language: 's?', tags: 'ss', type: 's', title: 's', category: 's?', bibleBook: 's?',
      durationSeconds: 'i?', streamUrl: 's?', readMinutes: 'i?', bodyHtml: 's?', fileSizeBytes: 'i?', documentUrl: 's?',
    },
    fk: { communityId: ['communities', true], addedBy: ['users', true] }, index: ['communityId', 'type'],
  },
  resourceProgress: {
    cols: { resourceId: 's', userId: 's', positionSeconds: 'i?', completed: 'b' },
    fk: { resourceId: ['resources'], userId: ['users'] }, index: ['resourceId', 'userId'],
  },
  quizzes: { cols: { title: 's', passMarkPercent: 'i?', questions: 'j' } },
  quizAttempts: {
    cols: { quizId: 's', userId: 's', score: 'i', total: 'i', passed: 'b' },
    fk: { quizId: ['quizzes'], userId: ['users'] }, index: ['quizId', 'userId'],
  },
  badges: { cols: { key: 's?', name: 's', iconUrl: 's?' }, unique: ['key'] },
  userBadges: { cols: { userId: 's', badgeId: 's' }, fk: { userId: ['users'], badgeId: ['badges'] }, index: ['userId'] },
  events: { cols: { userId: 's', type: 's', label: 's?', internal: 'b?' }, fk: { userId: ['users'] }, index: ['userId'] },
  landingStories: {
    cols: { quote: 's', studentName: 's', institutionName: 's?', institutionType: 's?', durationSeconds: 'i?', thumbnailUrl: 's?', videoUrl: 's?' },
  },

  // ── messaging & safety
  conversations: { cols: { userIds: 'ss' } },
  messages: {
    cols: { conversationId: 's', senderId: 's', text: 's', readAt: 'd?' },
    fk: { conversationId: ['conversations'], senderId: ['users'] }, index: ['conversationId'],
  },
  reports: {
    cols: { reporterId: 's', targetType: 's', targetId: 's', reason: 's', details: 's?', status: 's', resolution: 'j?', evidenceMediaId: 's?' },
    fk: { reporterId: ['users'] }, index: ['status', 'targetId'],
  },
  blocks: { cols: { blockerId: 's', blockedId: 's' }, fk: { blockerId: ['users'], blockedId: ['users'] }, index: ['blockerId'] },

  // ── files, devices, tokens
  media: {
    cols: { ownerId: 's', purpose: 's', contentType: 's', sizeBytes: 'i', status: 's' },
    fk: { ownerId: ['users'] }, index: ['ownerId'],
  },
  devices: { cols: { userId: 's', platform: 's?', pushToken: 's' }, fk: { userId: ['users'] }, unique: ['pushToken'] },
  refreshTokens: {
    cols: { userId: 's', tokenHash: 's?', hash: 's?', admin: 'b?', expiresAt: 'e' },
    fk: { userId: ['users'] }, index: ['userId', 'tokenHash', 'hash'],
  },
  otps: { cols: { destination: 's', purpose: 's', hash: 's', expiresAt: 'e', attempts: 'i' }, index: ['destination'] },
  resetTokens: { cols: { userId: 's', token: 's', expiresAt: 'e', used: 'b' }, fk: { userId: ['users'] }, unique: ['token'] },

  // ── in-app notifications (the mobile app's list and settings)
  notifications: {
    cols: { userId: 's', type: 's', title: 's', body: 's?', targetRoute: 's', readAt: 'd?' },
    fk: { userId: ['users'] }, index: ['userId'],
  },
  notificationPrefs: { cols: { userId: 's', channels: 'ss', muted: 'ss' }, fk: { userId: ['users'] }, unique: ['userId'] },

  // ── meetings: RSVP and check-in per weekly meeting (the meeting itself is derived from communities.meeting)
  meetingAttendance: {
    cols: { userId: 's', communityId: 's', meetingId: 's', going: 'b', attendedAt: 'd?' },
    fk: { userId: ['users'], communityId: ['communities'] }, index: ['userId', 'meetingId'],
  },

  // ── back office
  content: {
    cols: {
      title: 's', type: 's', bibleLink: 's?', language: 's?', tags: 'ss', description: 's?', status: 's', authorId: 's?', authorName: 's?',
      version: 'i', updatedAt: 'd?', validatedAt: 'd?', validatorName: 's?', trail: 'j',
    },
    fk: { authorId: ['users', true] }, index: ['status', 'type'],
  },
  adminPathways: {
    cols: { name: 's', theme: 's?', level: 's?', description: 's?', unlockRule: 's?', published: 'b', updatedAt: 'd?', steps: 'j' },
  },
  adminBadges: {
    cols: { name: 's', description: 's?', ruleType: 's?', ruleTargetCount: 'i?', icon: 's?', status: 's', visibleOnProfile: 'b', updatedAt: 'd?' },
  },
  announcements: {
    cols: { title: 's', message: 's', audienceType: 's', communityId: 's?', imageUrl: 's?', scheduledFor: 'd?', status: 's', authorName: 's?' },
    fk: { communityId: ['communities', true] }, index: ['status'],
  },
  adminStories: {
    cols: { studentName: 's', institution: 's?', videoUrl: 's?', duration: 's?', consentObtained: 'b', visible: 'b', order: 'i' },
  },
  notificationRules: {
    cols: { triggerKey: 's', triggerLabel: 's?', recipient: 's?', channels: 'j?', enabled: 'b', template: 'j?', updatedAt: 'd?' },
    unique: ['triggerKey'],
  },
  auditLog: {
    cols: { occurredAt: 'd', actorId: 's?', actorName: 's?', actorRole: 's?', action: 's', actionLabel: 's?', target: 's?', place: 's?' },
    fk: { actorId: ['users', true] }, index: ['occurredAt', 'action'],
  },
  sanctions: {
    cols: { userId: 's', communityId: 's?', type: 's', reason: 's?', issuedBy: 's?', issuedAt: 'd', active: 'b' },
    fk: { userId: ['users'], communityId: ['communities', true] }, index: ['userId', 'active'],
  },
  dataRequests: {
    cols: { userId: 's', type: 's', requestedAt: 'd', status: 's', processedBy: 's?', processedAt: 'd?' },
    fk: { userId: ['users'] }, index: ['status'],
  },
  guardianConsents: {
    cols: { userId: 's', guardianName: 's?', guardianContact: 's?', status: 's', updatedAt: 'd?' },
    fk: { userId: ['users'] }, index: ['userId'],
  },
  reportSchedules: { cols: { reportType: 's', cadence: 's', recipientEmail: 's', active: 'b' } },
  staffSessions: {
    // tokenHash = SHA-256 of the opaque cookie value (the raw value is never stored); expiresAt = absolute end of life;
    // `token` is the legacy column from the JWT era and is no longer written.
    cols: { userId: 's', token: 's?', tokenHash: 's?', remember: 'b?', expiresAt: 'e?', deviceName: 's?', browser: 's?', os: 's?', ipAddress: 's?', lastActiveAt: 'd?' },
    fk: { userId: ['users'] }, index: ['userId', 'tokenHash'],
  },
  settings: { cols: { key: 's', value: 'j?' }, unique: ['key'] },
};
