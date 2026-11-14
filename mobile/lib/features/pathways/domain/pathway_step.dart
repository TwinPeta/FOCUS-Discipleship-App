enum PathwayStepType { video, devotional, quiz }

enum PathwayStepStatus { done, current, locked }

class PathwayStep {
  const PathwayStep({
    required this.id,
    required this.pathwayId,
    required this.index,
    required this.type,
    required this.title,
    required this.meta,
    required this.status,
  });

  final String id;
  final String pathwayId;
  final int index;
  final PathwayStepType type;
  final String title;
  final String meta;
  final PathwayStepStatus status;

  PathwayStep copyWith({PathwayStepStatus? status}) {
    return PathwayStep(
      id: id,
      pathwayId: pathwayId,
      index: index,
      type: type,
      title: title,
      meta: meta,
      status: status ?? this.status,
    );
  }
}
