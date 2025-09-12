class Vote {
  final String participantId;
  final String value;

  const Vote({
    required this.participantId,
    required this.value,
  });

  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      participantId: json['participantId'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'participantId': participantId,
    'value': value,
  };
}
