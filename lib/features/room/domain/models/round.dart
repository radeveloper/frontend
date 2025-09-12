enum RoundStatus {
  pending,
  voting,
  revealed;

  factory RoundStatus.fromString(String status) {
    return RoundStatus.values.firstWhere(
      (e) => e.toString().split('.').last == status,
      orElse: () => RoundStatus.pending,
    );
  }
}

class Round {
  final String id;
  final RoundStatus status;
  final String? storyId;

  const Round({
    required this.id,
    required this.status,
    this.storyId,
  });

  factory Round.fromJson(Map<String, dynamic> json) {
    return Round(
      id: json['id'] as String,
      status: RoundStatus.fromString(json['status'] as String? ?? 'pending'),
      storyId: json['storyId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.toString().split('.').last,
    if (storyId != null) 'storyId': storyId,
  };
}
