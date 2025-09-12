class Participant {
  final String id;
  final String displayName;
  final bool isOwner;
  final bool hasVoted;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime? leftAt;

  const Participant({
    required this.id,
    required this.displayName,
    this.isOwner = false,
    this.hasVoted = false,
    this.isOnline = true,
    this.lastSeenAt,
    this.leftAt,
  });

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      isOwner: json['isOwner'] == true,
      hasVoted: json['hasVoted'] == true,
      isOnline: json['isOnline'] == true,
      lastSeenAt: json['lastSeenAt'] != null ? DateTime.parse(json['lastSeenAt']) : null,
      leftAt: json['leftAt'] != null ? DateTime.parse(json['leftAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'displayName': displayName,
    'isOwner': isOwner,
    'hasVoted': hasVoted,
    'isOnline': isOnline,
    if (lastSeenAt != null) 'lastSeenAt': lastSeenAt!.toIso8601String(),
    if (leftAt != null) 'leftAt': leftAt!.toIso8601String(),
  };

  bool isActive(Duration grace) {
    if (leftAt != null) return false;
    if (lastSeenAt == null) return true;
    return DateTime.now().difference(lastSeenAt!) <= grace;
  }
}
