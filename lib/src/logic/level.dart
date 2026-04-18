import '../models/game_field.dart';
import '../models/tile.dart';
import 'game_mechanics.dart';
import 'tile_objective.dart';

class Level {
  Level({
    required this.levelData,
    this.reserveData,
    this.maxMoves,
    this.tileObjectives = const [],
  })  : field = GameField.fromString(levelData) {
    if (reserveData != null) {
      final rf = GameField.fromString(reserveData!);
      _reserve = GameMechanics(rf);
    } else {
      _reserve = null;
    }
  }

  final String levelData;
  final String? reserveData;
  final int? maxMoves;
  final List<TileObjective> tileObjectives;

  final GameField field;
  GameMechanics? _reserve;

  int? goalFor(Tile t) {
    for (final o in tileObjectives) {
      if (o.tile == t) {
        return o.goal;
      }
    }
    return null;
  }

  Tile getNextTile(int column) {
    final r = _reserve;
    if (r == null) {
      return Tile.randomTile();
    }
    final f = r.field;
    final cell = f.getTileCellOnGround(column);
    if (cell.tile.isNotTile()) {
      return Tile.randomTile();
    }
    r.removeTile(cell.position);
    r.dropToGround(column);
    return cell.tile;
  }

  void reset() {
    field.reload(levelData);
    if (reserveData != null) {
      _reserve = GameMechanics(GameField.fromString(reserveData!));
    } else {
      _reserve = null;
    }
  }
}

String defaultLevelData() {
  return '''
    [D,B,A,B,D]
    [B,E,C,A,B]
    [B,E,C,C,B]
    [C,C,E,C,D]
    [B,B,C,A,D]
    [A,C,B,E,E]
    [D,E,E,B,A]
    [E,D,A,E,C]
    [E,A,D,C,B]
    ''';
}

String defaultReserveData() {
  return '''
    [E,C,B,A,D]
    [D,A,E,C,B]
    ''';
}

/// Same as [j4k.candycrush.level.LevelFactory.createLevel].
Level createDefaultLevel() {
  return Level(
    levelData: defaultLevelData(),
    reserveData: defaultReserveData(),
    maxMoves: 42,
    tileObjectives: const [
      TileObjective(Tile.a, 18),
      TileObjective(Tile.c, 22),
    ],
  );
}
