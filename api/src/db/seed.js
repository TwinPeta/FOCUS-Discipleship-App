const bcrypt = require('bcryptjs');
const store = require('./store');
const { ensureBadges } = require('../utils/activity');

// Demo data for local development only. All accounts share this TEST password.
const DEMO_PASSWORD = 'Password123!';

function seed() {
  const hash = bcrypt.hashSync(DEMO_PASSWORD, 10);
  ensureBadges();

  const makerere = store.insert('institutions', { name: 'Makerere University', type: 'university', country: 'UG' });
  const kyambogo = store.insert('institutions', { name: 'Kyambogo University', type: 'university', country: 'UG' });
  store.insert('institutions', { name: 'Uganda Christian University', type: 'university', country: 'UG' });
  store.insert('institutions', { name: 'Kampala Parents School', type: 'high_school', country: 'UG' });
  store.insert('institutions', { name: 'University of Nairobi', type: 'university', country: 'KE' });
  store.insert('institutions', { name: 'University of Rwanda', type: 'university', country: 'RW' });

  // General communities (one per institution)
  store.col('institutions').forEach((i) => {
    store.insert('communities', {
      type: 'general', name: 'General community', initials: 'GE', institutionId: i.id,
      description: `Everyone on the ${i.name} campus, open to all.`,
    });
  });
  const generalMak = store.first('communities', (c) => c.type === 'general' && c.institutionId === makerere.id);

  const mkUser = (o) => store.insert('users', {
    passwordHash: hash, emailVerified: true, phoneVerified: true, minorStatus: 'adult',
    platformRole: 'student', institutionId: makerere.id, country: 'UG', verifiedMentor: false, ...o,
  });

  const superMentor = mkUser({
    fullName: 'Samuel Mukasa', username: 'sam.mukasa', email: 'super@fcu.test', phone: '+256700000001',
    birthdate: '1990-04-12', platformRole: 'leader', verifiedMentor: true,
  });
  const mentor = mkUser({
    fullName: 'Miriam Auma', username: 'miriam', email: 'mentor@fcu.test', phone: '+256700000002',
    birthdate: '1995-08-03', platformRole: 'associate', verifiedMentor: true,
  });
  const student = mkUser({
    fullName: 'Grace Namuli', username: 'gracen', email: 'student@fcu.test', phone: '+256700000003',
    birthdate: '2004-02-20',
  });
  const friend = mkUser({
    fullName: 'David Kato', username: 'dkato', email: 'david@fcu.test', phone: '+256700000004',
    birthdate: '2003-11-30',
  });
  mkUser({
    fullName: 'Admin User', username: 'admin', email: 'admin@fcu.test', phone: '+256700000005',
    birthdate: '1988-01-01', platformRole: 'system_admin', verifiedMentor: true,
  });

  mkUser({
    fullName: 'Daniel Okello', username: 'content', email: 'content@fcu.test', phone: '+256700000006',
    birthdate: '1989-06-15', platformRole: 'content_admin', verifiedMentor: true,
  });

  // Specific communities
  const mkSpecific = (name, weekday, start, loc, description) => store.insert('communities', {
    type: 'specific', name, institutionId: makerere.id, description,
    meeting: { recurrence: 'weekly', weekday, start_time: start, timezone: 'Africa/Kampala', location: loc },
  });
  const growth = mkSpecific('Growth Circle', 'tue', '17:00', 'Room 3, Main Building',
    'A small group for students growing in faith through prayer, the Word and friendship.');
  const lifeFaith = mkSpecific('Life & Faith Circle', 'thu', '18:30', 'Chapel Annex',
    'Exploring how faith shapes everyday student life.');
  const freshers = mkSpecific('Freshers Connect', 'fri', '16:00', 'Student Centre Hall B',
    'A welcoming group for first-year students.');
  mkSpecific.__unused = null;

  const member = (communityId, userId, role = 'member', status = 'member') =>
    store.insert('memberships', { communityId, userId, role, status, joinedAt: status === 'member' ? store.now() : null });

  [superMentor, mentor, student, friend].forEach((u) => member(generalMak.id, u.id, 'member'));
  member(growth.id, superMentor.id, 'super_mentor');
  member(growth.id, mentor.id, 'mentor');
  member(growth.id, friend.id, 'member');
  member(lifeFaith.id, superMentor.id, 'super_mentor');
  member(freshers.id, mentor.id, 'super_mentor');
  // `student` has no specific community yet, so the join flow can be tried.

  // Feed
  store.insert('posts', {
    communityId: growth.id, authorId: superMentor.id, pinned: true, mediaIds: [],
    text: "Announcement: this week's meeting topic is Prayer. Reading: Luke 11:1-13.",
  });
  store.insert('posts', {
    communityId: growth.id, authorId: mentor.id, mediaIds: [],
    text: 'What is one thing you are thankful for this week? Share below.',
  });
  store.insert('posts', {
    communityId: generalMak.id, authorId: superMentor.id, mediaIds: [], pinned: true,
    text: 'Campus event: Open worship night this Saturday, 6 PM. All students welcome.',
  });

  // Prayer wall
  store.insert('prayerRequests', {
    communityId: growth.id, authorId: friend.id, anonymous: false,
    text: 'Please pray for my exams next week.',
  });
  store.insert('prayerRequests', {
    communityId: growth.id, authorId: mentor.id, anonymous: true,
    text: 'Praying for peace in a difficult family situation.',
  });

  // Testimonies
  store.insert('testimonies', {
    communityId: growth.id, authorId: friend.id, status: 'published', mediaIds: [],
    title: 'From anxious to anchored',
    body: 'I joined the Growth Circle during a hard season. Through prayer and friendships my anxiety lifted and I found purpose again.',
    approvedBy: superMentor.id, publishedAt: store.now(),
  });

  // Resources + quiz
  const res = (o) => store.insert('resources', {
    communityId: growth.id, addedBy: superMentor.id, status: 'published', language: 'en', tags: [], ...o,
  });
  const v1 = res({ type: 'video', title: 'Daniel: faith under pressure', category: 'bible_characters',
    tags: ['courage', 'daniel'], bibleBook: 'Daniel', durationSeconds: 480, streamUrl: 'https://cdn.fcu.example/v/daniel.m3u8' });
  const d1 = res({ type: 'devotional', title: 'Abiding in Christ', category: 'bible_texts', bibleBook: 'John',
    tags: ['john15'], readMinutes: 5, bodyHtml: '<p>Remain in me, and I will remain in you. (John 15:4)</p>' });
  const q1 = res({ type: 'quiz', title: 'Quiz: The life of Joseph', category: 'bible_characters', bibleBook: 'Genesis' });
  res({ type: 'document', title: 'Study guide: Sermon on the Mount', category: 'bible_texts', bibleBook: 'Matthew',
    fileSizeBytes: 2 * 1024 * 1024, documentUrl: 'https://cdn.fcu.example/docs/sermon-on-the-mount.pdf' });
  const v2 = res({ type: 'video', title: 'How to read your Bible', category: 'bible_texts', durationSeconds: 600,
    streamUrl: 'https://cdn.fcu.example/v/read-bible.m3u8' });
  const d2 = res({ type: 'devotional', title: 'The habit of prayer', category: 'bible_texts', readMinutes: 5,
    bodyHtml: '<p>Pray without ceasing. (1 Thess 5:17)</p>' });
  const q2 = res({ type: 'quiz', title: 'Quiz: Foundations review', category: 'bible_texts' });

  const quizQs = (n) => Array.from({ length: n }, (_, i) => ({
    id: `q${i + 1}`, text: `Question ${i + 1}`,
    options: [{ id: 'a', text: 'Option A' }, { id: 'b', text: 'Option B' }, { id: 'c', text: 'Option C' }],
    correct: 'a',
  }));
  store.col('quizzes').push({ id: q1.id, title: q1.title, passMarkPercent: 60, questions: quizQs(10) });
  store.col('quizzes').push({ id: q2.id, title: q2.title, passMarkPercent: 60, questions: quizQs(10) });

  // Pathways
  const path = (title, steps) => {
    const p = store.insert('pathways', { title, steps: [] });
    p.steps = steps.map(([type, resourceId, label], i) => ({
      id: store.uid(), order: i + 1, type, resourceId, title: label,
      durationLabel: type === 'video' ? '8 min' : type === 'devotional' ? '5 min read' : '10 questions',
    }));
    return p;
  };
  path('Foundations of faith', [
    ['video', v1.id, 'Step 1 · Faith that endures'], ['devotional', d1.id, 'Step 2 · Abiding in Christ'],
    ['quiz', q1.id, 'Step 3 · Check your understanding'], ['video', v2.id, 'Step 4 · Reading the Bible'],
    ['devotional', d2.id, 'Step 5 · The habit of prayer'], ['quiz', q2.id, 'Step 6 · Foundations review'],
  ]);
  path('Prayer & Bible reading', [['video', v2.id, 'Step 1 · How to read your Bible'], ['devotional', d2.id, 'Step 2 · Prayer']]);
  path('Purpose & calling', [['video', v1.id, 'Step 1 · Called under pressure']]);
  path('Leadership & service', [['devotional', d1.id, 'Step 1 · Servant leadership']]);

  // Landing stories
  [
    ['I found real friends on campus.', 'Ruth A.', 'Makerere University', 'university', 45],
    ['The guides helped me study with purpose.', 'Peter O.', 'Kyambogo University', 'university', 70],
    ['My mentor kept me going.', 'Esther N.', 'Kampala Parents School', 'high_school', 55],
  ].forEach(([quote, name, inst, type, dur]) => store.insert('landingStories', {
    quote, studentName: name, institutionName: inst, institutionType: type, durationSeconds: dur,
    thumbnailUrl: 'https://cdn.fcu.example/stories/thumb.jpg', videoUrl: 'https://cdn.fcu.example/stories/story.m3u8',
  }));

  // Back-office demo content
  const cAdmin = store.first('users', (u) => u.email === 'content@fcu.test');
  const mkContent = (title, type, bible, status) => store.insert('content', {
    title, type, bibleLink: bible, language: 'English', tags: [], description: '', status, authorId: cAdmin.id, authorName: cAdmin.fullName,
    version: 1, updatedAt: store.now(), validatedAt: status === 'PUBLISHED' ? store.now() : null, validatorName: status === 'PUBLISHED' ? 'Admin User' : '', trail: [],
  });
  const c1 = mkContent('Walking with David', 'VIDEO', 'char-david', 'PUBLISHED');
  mkContent('Psalm 23 Devotional', 'DEVOTIONAL', 'text-psalm-23', 'PUBLISHED');
  mkContent('Abiding in Christ', 'DOCUMENT', 'text-john-15', 'IN_REVIEW');
  store.insert('adminBadges', { name: 'First Steps', description: 'Joined a fellowship community', ruleType: 'join_community', ruleTargetCount: 1, icon: 'award', status: 'active', visibleOnProfile: true, updatedAt: store.now() });
  store.insert('adminPathways', { name: 'Foundations of Faith', theme: 'Foundations', level: 'Beginner', description: 'Start here.', unlockRule: 'none', published: true, updatedAt: store.now(),
    steps: [{ id: store.uid(), contentId: c1.id, title: c1.title, contentType: 'video', order: 0, required: true }] });

  return { student, superMentor, mentor, friend, growth, generalMak, kyambogo };
}

module.exports = { seed, DEMO_PASSWORD };
