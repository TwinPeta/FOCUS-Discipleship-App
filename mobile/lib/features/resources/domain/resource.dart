enum ResourceType { video, devotional, quiz, document }

enum ResourceTopic { characters, texts, none }

class Resource {
  const Resource({
    required this.id,
    required this.type,
    required this.topic,
    required this.title,
    required this.meta,
    required this.addedBy,
  });

  final String id;
  final ResourceType type;
  final ResourceTopic topic;
  final String title;
  final String meta;
  final String addedBy;
}
