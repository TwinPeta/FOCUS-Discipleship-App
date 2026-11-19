const config = require('../config');
const store = require('../db/store');
const realtime = require('../realtime/socket');

const mediaUrl = (m) => (m ? `${config.baseUrl}/uploads/${m.id}` : null);

function institution(i) {
  return i && { id: i.id, name: i.name, type: i.type, country: i.country };
}

function userRef(u, communityId) {
  if (!u) return null;
  let role = 'member';
  if (communityId) {
    const m = store.first('memberships', (x) => x.communityId === communityId && x.userId === u.id && x.status === 'member');
    if (m) role = m.role;
  }
  return {
    id: u.id,
    full_name: u.fullName,
    username: u.username,
    photo_url: mediaUrl(store.get('media', u.photoMediaId)),
    community_role: role,
    online: realtime.isOnline(u.id),
  };
}

function myProfile(u) {
  return {
    id: u.id,
    full_name: u.fullName,
    username: u.username,
    photo_url: mediaUrl(store.get('media', u.photoMediaId)),
    email: u.email || null,
    phone: u.phone || null,
    email_verified: !!u.emailVerified,
    phone_verified: !!u.phoneVerified,
    birthdate: u.birthdate,
    country: u.country,
    institution: institution(store.get('institutions', u.institutionId)),
    year_of_study: u.yearOfStudy ?? null,
    home_church: u.homeChurch ? { name: u.homeChurch.name, location: u.homeChurch.location, pastor: u.homeChurch.pastor } : null,
    accepted_national_activities: !!(u.consents && u.consents.nationalActivities),
    minor_status: u.minorStatus,
    platform_role: u.platformRole,
    created_at: u.createdAt,
  };
}

const initials = (name) =>
  name.split(/\s+/).map((w) => w[0]).join('').slice(0, 2).toUpperCase();

function communitySummary(c, viewerId) {
  const superM = store.first('memberships', (m) => m.communityId === c.id && m.role === 'super_mentor' && m.status === 'member');
  let membershipStatus = 'none';
  let canRequest = c.type === 'specific';
  if (viewerId) {
    const mine = store.first('memberships', (m) => m.communityId === c.id && m.userId === viewerId);
    if (mine) membershipStatus = mine.status;
    if (c.type === 'specific') {
      const myOther = store.first(
        'memberships',
        (m) => m.userId === viewerId && m.status !== 'rejected' &&
          store.get('communities', m.communityId)?.type === 'specific'
      );
      canRequest = !myOther;
    }
  }
  return {
    id: c.id,
    type: c.type,
    name: c.name,
    initials: c.initials || initials(c.name),
    institution: institution(store.get('institutions', c.institutionId)),
    super_mentor: superM ? userRef(store.get('users', superM.userId), c.id) : null,
    meeting: c.meeting || null,
    can_request: canRequest,
    membership_status: membershipStatus === 'member' ? 'member' : membershipStatus === 'pending' ? 'pending' : 'none',
  };
}

function community(c, viewerId) {
  const members = store.where('memberships', (m) => m.communityId === c.id && m.status === 'member');
  const leaders = members.filter((m) => m.role !== 'member').sort((a) => (a.role === 'super_mentor' ? -1 : 1));
  const onlineMembers = members.filter((m) => realtime.isOnline(m.userId));
  return {
    ...communitySummary(c, viewerId),
    description: c.description || '',
    members_count: members.length,
    online_count: onlineMembers.length,
    online_preview: onlineMembers.slice(0, 4).map((m) => userRef(store.get('users', m.userId), c.id)),
    leadership: leaders.map((m) => userRef(store.get('users', m.userId), c.id)),
    tabs: ['feed', 'prayer', 'testimonies', 'pathways', 'resources', 'info'],
  };
}

function media(m) {
  if (!m) return null;
  const kind = m.contentType.startsWith('video') ? 'video' : 'image';
  return { id: m.id, kind, url: mediaUrl(m), thumbnail_url: kind === 'image' ? mediaUrl(m) : null, duration_seconds: null };
}
const mediaList = (ids = []) => ids.map((id) => media(store.get('media', id))).filter(Boolean);

function post(p, viewerId) {
  const likes = store.where('likes', (l) => l.postId === p.id);
  return {
    id: p.id,
    community_id: p.communityId,
    kind: p.kind || 'post',
    anonymous: !!p.anonymous,
    // Anonymous: no author for anyone (moderators see it in the back office); is_mine tells the author it is theirs.
    author: p.anonymous ? null : userRef(store.get('users', p.authorId), p.communityId),
    is_mine: p.authorId === viewerId,
    text: p.text,
    media: mediaList(p.mediaIds),
    pinned: !!p.pinned,
    like_count: likes.length,
    comment_count: store.where('comments', (c) => c.postId === p.id).length,
    liked_by_me: likes.some((l) => l.userId === viewerId),
    // Questions only: who follows it to hear about new answers, and whether the viewer passed on answering it.
    ...((p.kind || 'post') === 'question' ? { ...followState(p.id, viewerId), passed_by_me: marked(p.id, viewerId, 'passed') } : {}),
    created_at: p.createdAt,
  };
}

/** True when [userId] put their own [kind] mark ('hidden' or 'passed') on the post. */
const marked = (postId, userId, kind) => !!store.first('postMarks', (m) => m.postId === postId && m.userId === userId && m.kind === kind);

function followState(postId, viewerId) {
  const f = store.where('questionFollows', (x) => x.postId === postId);
  return { follower_count: f.length, following: f.some((x) => x.userId === viewerId) };
}

function voteState(commentId, viewerId) {
  const v = store.where('answerVotes', (x) => x.commentId === commentId);
  return { vote_count: v.length, voted_by_me: v.some((x) => x.userId === viewerId) };
}

const comment = (c, communityId, viewerId) => ({
  id: c.id,
  author: userRef(store.get('users', c.authorId), communityId),
  text: c.text,
  // "Helpful" votes (shown on answers to questions).
  ...voteState(c.id, viewerId),
  created_at: c.createdAt,
});

function prayerRequest(r, viewerId) {
  const prayed = store.where('prayed', (p) => p.prayerRequestId === r.id);
  return {
    id: r.id,
    community_id: r.communityId,
    author: r.anonymous ? null : userRef(store.get('users', r.authorId), r.communityId),
    text: r.text,
    prayed_count: prayed.length,
    prayed_by_me: prayed.some((p) => p.userId === viewerId),
    response_count: store.where('prayerResponses', (x) => x.prayerRequestId === r.id).length,
    created_at: r.createdAt,
  };
}

function encouragedState(testimonyId, viewerId) {
  const e = store.where('testimonyEncouragements', (x) => x.testimonyId === testimonyId);
  return { encouraged_count: e.length, encouraged_by_me: e.some((x) => x.userId === viewerId) };
}

function testimony(t, { detail = false, viewerId = null } = {}) {
  const author = store.get('users', t.authorId);
  const approver = store.get('users', t.approvedBy);
  const inst = store.get('institutions', author?.institutionId);
  const m = mediaList(t.mediaIds);
  return {
    id: t.id,
    community_id: t.communityId,
    format: m.some((x) => x.kind === 'video') ? 'video' : 'story',
    title: t.title,
    excerpt: t.body.slice(0, 160),
    body: detail ? t.body : null,
    media: m,
    author: userRef(author, t.communityId),
    institution_name: inst ? inst.name : null,
    status: t.status,
    reviewed: t.status === 'published',
    approved_by: approver ? approver.fullName : null,
    published_at: t.publishedAt || null,
    created_at: t.createdAt || null,
    // "Encouraged" reactions (published stories only take them).
    ...encouragedState(t.id, viewerId),
  };
}

function resource(r, viewerId, { detail = false } = {}) {
  const prog = store.first('resourceProgress', (p) => p.resourceId === r.id && p.userId === viewerId);
  return {
    id: r.id,
    type: r.type,
    title: r.title,
    category: r.category,
    tags: r.tags || [],
    bible_book: r.bibleBook || null,
    duration_seconds: r.durationSeconds || null,
    read_minutes: r.readMinutes || null,
    question_count: r.type === 'quiz' ? (store.get('quizzes', r.id)?.questions.length ?? null) : null,
    file_size_bytes: r.fileSizeBytes || null,
    added_by: userRef(store.get('users', r.addedBy), r.communityId),
    thumbnail_url: r.thumbnailUrl || null,
    stream_url: r.type === 'video' ? r.streamUrl || null : null,
    body_html: detail && r.type === 'devotional' ? r.bodyHtml || null : null,
    document_url: r.type === 'document' ? r.documentUrl || null : null,
    offline_available: r.type === 'devotional' || r.type === 'document',
    download_url: r.type === 'document' ? r.documentUrl || null : null,
    language: r.language || 'en',
    status: 'published',
    my_progress: { position_seconds: prog?.positionSeconds || 0, completed: !!prog?.completed },
  };
}

const message = (m) => ({
  id: m.id,
  conversation_id: m.conversationId,
  sender_id: m.senderId,
  text: m.text,
  sent_at: m.createdAt,
  read_at: m.readAt || null,
});

module.exports = {
  mediaUrl, institution, userRef, myProfile, communitySummary, community, media, mediaList,
  post, comment, followState, voteState, marked, encouragedState, prayerRequest, testimony, resource, message, initials,
};
