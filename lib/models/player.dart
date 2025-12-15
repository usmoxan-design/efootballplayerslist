class Player {
  final String id;
  final String name;
  final String club;
  final String nationality;

  Player({
    required this.id,
    required this.name,
    required this.club,
    required this.nationality,
  });

  String get imageUrl => 'https://pesdb.net/assets/img/card/f$id.png';
}
