enum PersonRole { superMentor, mentor, member }

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.role,
    this.online = false,
  });

  final String id;
  final String name;
  final PersonRole role;
  final bool online;

  String get initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  Person copyWith({String? id, String? name, PersonRole? role, bool? online}) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      online: online ?? this.online,
    );
  }
}
