/// Data model for a daily Build Brief / puzzle set.
class PuzzleSet {
  final String id;
  final DateTime scheduledDate;
  final String projectName;
  final String clientName;
  final String briefIntro;
  final String completionText;
  final int weekNumber;
  final DateTime createdAt;

  const PuzzleSet({
    required this.id,
    required this.scheduledDate,
    required this.projectName,
    required this.clientName,
    required this.briefIntro,
    required this.completionText,
    required this.weekNumber,
    required this.createdAt,
  });

  factory PuzzleSet.fromJson(Map<String, dynamic> json) {
    return PuzzleSet(
      id: json['id'] as String,
      scheduledDate: DateTime.parse(json['scheduled_date'] as String),
      projectName: json['project_name'] as String,
      clientName: json['client_name'] as String,
      briefIntro: json['brief_intro'] as String,
      completionText: json['completion_text'] as String,
      weekNumber: json['week_number'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
