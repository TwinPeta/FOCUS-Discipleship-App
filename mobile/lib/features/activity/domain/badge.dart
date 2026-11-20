/// Named `AppBadge`, not `Badge`, to avoid colliding with Flutter's own
/// `Badge` widget (exported transitively via material_ui).
/// Every badge the app knows, unearned. One list for the activity rules
/// and for the badges shown on member profiles.
const kBadgeCatalog = [
  AppBadge(id: 'newcomer', name: 'Newcomer'),
  AppBadge(id: 'first-steps', name: 'First steps'),
  AppBadge(id: 'quiz-finisher', name: 'Quiz finisher'),
  AppBadge(id: 'prayer-partner', name: 'Prayer partner'),
  AppBadge(id: 'pathway-complete', name: 'Pathway complete'),
];

class AppBadge {
  const AppBadge({required this.id, required this.name, this.earned = false});

  final String id;
  final String name;
  final bool earned;

  AppBadge copyWith({bool? earned}) {
    return AppBadge(id: id, name: name, earned: earned ?? this.earned);
  }
}
