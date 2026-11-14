import 'person.dart';

enum CommunityType { general, specific }

class Community {
  const Community({
    required this.id,
    required this.name,
    required this.initials,
    required this.type,
    required this.institutionId,
    required this.description,
    this.meetingDay,
    this.meetingTime,
    this.room,
    this.superMentor,
    this.mentors = const [],
  });

  final String id;
  final String name;
  final String initials;
  final CommunityType type;
  final String institutionId;
  final String description;
  final String? meetingDay;
  final String? meetingTime;
  final String? room;
  final Person? superMentor;
  final List<Person> mentors;

  Community copyWith({
    String? id,
    String? name,
    String? initials,
    CommunityType? type,
    String? institutionId,
    String? description,
    String? meetingDay,
    String? meetingTime,
    String? room,
    Person? superMentor,
    List<Person>? mentors,
  }) {
    return Community(
      id: id ?? this.id,
      name: name ?? this.name,
      initials: initials ?? this.initials,
      type: type ?? this.type,
      institutionId: institutionId ?? this.institutionId,
      description: description ?? this.description,
      meetingDay: meetingDay ?? this.meetingDay,
      meetingTime: meetingTime ?? this.meetingTime,
      room: room ?? this.room,
      superMentor: superMentor ?? this.superMentor,
      mentors: mentors ?? this.mentors,
    );
  }
}
