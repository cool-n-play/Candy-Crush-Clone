import 'dart:math';

/// Candy tile types: A–E, plus hole/wall (ported from j4k.candycrush.model.Tile).
enum Tile {
  a,
  b,
  c,
  d,
  e,
  wall,
  hole,
  outOfSpace,
  ;

  String get shortName {
    return switch (this) {
      Tile.hole => 'H',
      Tile.wall => 'W',
      Tile.outOfSpace => 'X',
      _ => name[0].toUpperCase(),
    };
  }

  static Tile fromShort(String s) {
    if (s.isEmpty) {
      throw ArgumentError('Empty short name');
    }
    final ch = s.trim();
    for (final t in Tile.values) {
      if (t.shortName == ch) {
        return t;
      }
    }
    throw ArgumentError('Unknown tile: $s');
  }

  bool isWall() => this == wall;
  bool isHole() => this == hole;
  bool isOutOfSpace() => this == outOfSpace;
  bool isTile() => !isWall() && !isHole() && !isOutOfSpace();
  bool isNotTile() => !isTile();

  static final _random = Random();
  static Tile randomTile() {
    const playable = [a, b, c, d, e];
    return playable[_random.nextInt(playable.length)];
  }
}
