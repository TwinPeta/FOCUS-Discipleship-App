const router = require('express').Router();
const store = require('../db/store');
const { paginate } = require('../utils/pagination');
const S = require('../utils/serialize');

router.get('/countries', (_req, res) => {
  res.json({
    items: [
      { code: 'UG', name: 'Uganda', dial_code: '+256' },
      { code: 'KE', name: 'Kenya', dial_code: '+254' },
      { code: 'RW', name: 'Rwanda', dial_code: '+250' },
    ],
  });
});

router.get('/institutions', (req, res) => {
  const { type, country, q } = req.query;
  let items = store.col('institutions').filter((i) =>
    (!type || i.type === type) &&
    (!country || i.country === country) &&
    (!q || i.name.toLowerCase().includes(String(q).toLowerCase()))
  );
  items = items.sort((a, b) => a.name.localeCompare(b.name));
  const page = paginate(items, req.query);
  res.json({ items: page.items.map(S.institution), next_cursor: page.next_cursor });
});

module.exports = router;
