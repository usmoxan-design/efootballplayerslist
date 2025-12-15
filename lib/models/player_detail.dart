import 'player.dart';

class PlayerDetail {
  final Player player;
  final String position;
  final String height;
  final String age;
  final String foot;
  final Map<String, String> stats;
  final String playingStyle;
  final List<String> skills;

  PlayerDetail({
    required this.player,
    required this.position,
    required this.height,
    required this.age,
    required this.foot,
    required this.stats,
    this.info = const {}, // For non-numeric details like Team, League, etc.
    this.playingStyle = 'Unknown',
    this.skills = const [],
  });

  /// Helper to access info safely
  final Map<String, String> info;
}
