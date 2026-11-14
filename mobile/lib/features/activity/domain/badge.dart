/// Named `AppBadge`, not `Badge`, to avoid colliding with Flutter's own
/// `Badge` widget (exported transitively via material_ui).
class AppBadge {
  const AppBadge({required this.id, required this.name, this.earned = false});

  final String id;
  final String name;
  final bool earned;

  AppBadge copyWith({bool? earned}) {
    return AppBadge(id: id, name: name, earned: earned ?? this.earned);
  }
}
