import 'grid_position.dart';
import 'tile.dart';

class TileCell {
  const TileCell(this.tile, this.position);
  final Tile tile;
  final GridPosition position;

  @override
  String toString() => '${tile.shortName} ${position}';
}
