import '../models/tile.dart';

/// [j4k.candycrush.model.Level.TileObjective]
class TileObjective {
  const TileObjective(this.tile, this.goal);
  final Tile tile;
  final int goal;
}
