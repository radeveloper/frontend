class Room {
  final String id;
  final String code;
  final String name;
  final String deckType;

  Room({
    required this.id,
    required this.code,
    required this.name,
    required this.deckType,
  });

  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      deckType: json['deckType'] as String? ?? 'fibonacci',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'deckType': deckType,
  };
}
