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
  String get imageFlipUrl => 'https://pesdb.net/assets/img/card/b$id.png';
  String get imageMaxUrl => 'https://pesdb.net/assets/img/card/f${id}max.png';
  String get imageMaxFlipUrl =>
      'https://pesdb.net/assets/img/card/b${id}max.png';
}
