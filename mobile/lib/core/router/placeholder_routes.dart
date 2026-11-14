/// Destinations that exist as routes but are built in later prompts. Each
/// entry has a matching row in `docs/wiring.md`; when a prompt builds the
/// real screen it replaces the entry here and deletes that row.
class PlaceholderRoute {
  const PlaceholderRoute(this.path, this.title, this.owner);

  final String path;
  final String title;

  /// The prompt (2 or 3) that resolves it.
  final int owner;
}

const placeholderRoutes = <PlaceholderRoute>[
  PlaceholderRoute('/community/:id/manage', 'Manage community', 2),
  PlaceholderRoute('/post/:id', 'Post', 2),
  PlaceholderRoute('/post/:id/options', 'Post options', 2),
  PlaceholderRoute('/settings', 'Settings', 3),
  PlaceholderRoute('/settings/profile', 'Edit profile', 3),
  PlaceholderRoute('/notifications', 'Notifications', 3),
  PlaceholderRoute('/community/:id/meetings', 'Meetings', 3),
  PlaceholderRoute('/messages/new', 'New message', 3),
  PlaceholderRoute('/members/:id', 'Member', 3),
  PlaceholderRoute('/prayer/:id', 'Prayer request', 3),
  PlaceholderRoute('/testimony/:id', 'Testimony', 3),
  PlaceholderRoute('/help', 'Help & support', 3),
];
