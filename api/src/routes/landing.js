const router = require('express').Router();
const store = require('../db/store');

router.get('/landing', (_req, res) => {
  res.json({
    stories: store.col('landingStories').map((s) => ({
      id: s.id,
      quote: s.quote,
      student_name: s.studentName,
      institution_name: s.institutionName,
      institution_type: s.institutionType,
      duration_seconds: s.durationSeconds,
      thumbnail_url: s.thumbnailUrl,
      video_url: s.videoUrl,
    })),
  });
});

module.exports = router;
