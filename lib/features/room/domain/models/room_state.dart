import 'room.dart';
import 'participant.dart';
import 'round.dart';
import 'vote.dart';

class RoomState {
  final Room room;
  final List<Participant> participants;
  final Round round;
  final List<Vote> votes;
  final num? average;

  const RoomState({
    required this.room,
    required this.participants,
    required this.round,
    required this.votes,
    this.average,
  });

  factory RoomState.fromJson(Map<String, dynamic> json) {
    return RoomState(
      room: Room.fromJson(json['room'] as Map<String, dynamic>),
      participants: (json['participants'] as List)
          .map((e) => Participant.fromJson(e as Map<String, dynamic>))
          .toList(),
      round: Round.fromJson(json['round'] as Map<String, dynamic>),
      votes: (json['votes'] as List)
          .map((e) => Vote.fromJson(e as Map<String, dynamic>))
          .toList(),
      average: json['average'] as num?,
    );
  }

  Map<String, dynamic> toJson() => {
    'room': room.toJson(),
    'participants': participants.map((e) => e.toJson()).toList(),
    'round': round.toJson(),
    'votes': votes.map((e) => e.toJson()).toList(),
    if (average != null) 'average': average,
  };
}
