import '../../../core/utils/initials.dart';

enum PersonRole {
  superMentor('Super-mentor'),
  mentor('Mentor'),
  member('Member');

  const PersonRole(this.label);

  /// Display label used on badges, thread rows and member lists.
  final String label;
}

class Person {
  const Person({
    required this.id,
    required this.name,
    required this.role,
    this.online = false,
    bool? isAdult,
    // ignore: prefer_initializing_formals
  }) : _isAdult = isAdult;

  final String id;
  final String name;
  final PersonRole role;
  final bool online;
  final bool? _isAdult;

  /// Mentors and super-mentors are always adults; members are adults
  /// unless marked otherwise. Drives the under-18 messaging limit.
  bool get isAdult => role != PersonRole.member || (_isAdult ?? true);

  String get initials => initialsOf(name);

  Person copyWith({
    String? id,
    String? name,
    PersonRole? role,
    bool? online,
    bool? isAdult,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      online: online ?? this.online,
      isAdult: isAdult ?? _isAdult,
    );
  }
}
