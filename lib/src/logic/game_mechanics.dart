import '../models/game_field.dart';
import '../models/grid_position.dart';
import '../models/tile.dart';
import '../models/tile_cell.dart';

class InsertMove implements Comparable<InsertMove> {
  const InsertMove(this.target, this.tile);
  final GridPosition target;
  final Tile tile;

  @override
  int compareTo(InsertMove other) {
    if (other.target.row != target.row) {
      return other.target.row - target.row;
    }
    return target.column - other.target.column;
  }
}

class FieldMove {
  const FieldMove({required this.toCell, required this.fromCell});
  final GridPosition toCell;
  final GridPosition fromCell;
}

class DropMove {
  const DropMove({required this.hole, required this.source});
  final GridPosition hole;
  final GridPosition source;
}

class GameMechanics {
  GameMechanics(this.field);

  final GameField field;

  void swapTiles(GridPosition a, GridPosition b) {
    final ta = field[a];
    final tb = field[b];
    field.setPosition(a, tb);
    field.setPosition(b, ta);
  }

  bool isSwapAllowed(GridPosition a, GridPosition b) {
    swapTiles(a, b);
    final ok = isInRowWithThree(a) || isInRowWithThree(b);
    final both = field[a].isTile() && field[b].isTile();
    swapTiles(a, b);
    return both && ok;
  }

  bool isInRowWithThree(GridPosition pos) {
    return isHorizontalConnected(pos) || isVerticalConnected(pos);
  }

  List<TileCell> getConnectedTileCells(
    GridPosition a,
    GridPosition b, {
    void Function()? onRush,
  }) {
    final linesA = getConnectedLineGroupsForPosition(a);
    final linesB = getConnectedLineGroupsForPosition(b);
    final combined = <List<TileCell>>[...linesA, ...linesB];
    if (combined.length > 1) {
      onRush?.call();
    }
    final byKey = <String, TileCell>{};
    for (final line in combined) {
      for (final c in line) {
        byKey['${c.position.column},${c.position.row}'] = c;
      }
    }
    return byKey.values.toList();
  }

  /// Same as Kotlin [getConnectedLines] for a single [pos]: 0..2 line groups of length ≥3.
  List<List<TileCell>> getConnectedLineGroupsForPosition(GridPosition pos) {
    final h = getHorizontalConnectedOrEmpty(pos);
    final v = getVerticalConnectedOrEmpty(pos);
    final r = <List<TileCell>>[];
    if (h.isNotEmpty) {
      r.add(h);
    }
    if (v.isNotEmpty) {
      r.add(v);
    }
    return r;
  }

  void removeTile(GridPosition position) {
    field.setPosition(position, Tile.hole);
  }

  void removeTiles(Iterable<GridPosition> positions) {
    for (final p in positions) {
      removeTile(p);
    }
  }

  void removeTileCells(Iterable<TileCell> cells) {
    for (final c in cells) {
      removeTile(c.position);
    }
  }

  bool isHorizontalConnected(GridPosition pos) {
    return getHorizontalConnectedOrEmpty(pos).isNotEmpty;
  }

  List<List<TileCell>> getAndRemoveAllHorizontalRows() {
    return field
        .listAllPositions()
        .map(
          (p) {
            final line = getHorizontalConnectedOrEmpty(p);
            if (line.isNotEmpty) {
              removeTileCells(line);
            }
            return line;
          },
        )
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<List<TileCell>> getAndRemoveAllVerticalRows() {
    return field
        .listAllPositions()
        .map(
          (p) {
            final line = getVerticalConnectedOrEmpty(p);
            if (line.isNotEmpty) {
              removeTileCells(line);
            }
            return line;
          },
        )
        .where((e) => e.isNotEmpty)
        .toList();
  }

  List<TileCell> getHorizontalConnectedOrEmpty(GridPosition pos) {
    final s = getHorizontalSurroundings(field.getTileCellAt(pos));
    if (s.length < 3) {
      return [];
    }
    return s;
  }

  List<TileCell> getVerticalConnectedOrEmpty(GridPosition pos) {
    final s = getVerticalSurroundings(field.getTileCellAt(pos));
    if (s.length < 3) {
      return [];
    }
    return s;
  }

  List<TileCell> getHorizontalSurroundings(TileCell cell) {
    if (cell.tile.isNotTile()) {
      return [cell];
    }
    var pos = cell.position.right();
    final right = <TileCell>[];
    while (field.getTile(pos.column, pos.row) == cell.tile) {
      right.add(field.getTileCellAt(pos));
      pos = pos.right();
    }
    pos = cell.position.left();
    final left = <TileCell>[];
    while (field.getTile(pos.column, pos.row) == cell.tile) {
      left.add(field.getTileCellAt(pos));
      pos = pos.left();
    }
    return [...left.reversed, cell, ...right];
  }

  List<TileCell> getVerticalSurroundings(TileCell cell) {
    if (cell.tile.isNotTile()) {
      return [cell];
    }
    var pos = cell.position.bottom();
    final bottom = <TileCell>[];
    while (field.getTile(pos.column, pos.row) == cell.tile) {
      bottom.add(field.getTileCellAt(pos));
      pos = pos.bottom();
    }
    pos = cell.position.top();
    final top = <TileCell>[];
    while (field.getTile(pos.column, pos.row) == cell.tile) {
      top.add(field.getTileCellAt(pos));
      pos = pos.top();
    }
    return [...top.reversed, cell, ...bottom];
  }

  bool isVerticalConnected(GridPosition pos) {
    return getVerticalConnectedOrEmpty(pos).isNotEmpty;
  }

  List<FieldMove> dropAllToGround() {
    final out = <FieldMove>[];
    for (int c = 0; c < field.columnsSize; c++) {
      out.addAll(dropToGround(c));
    }
    return out;
  }

  /// Same sequence as [dropAllToGround] on a clone — does **not** mutate [field].
  /// Used to preview fall paths for animation before applying drops.
  List<({FieldMove move, Tile tile})> previewDropAllMoves() {
    final f = field.clone();
    final g = GameMechanics(f);
    final out = <({FieldMove move, Tile tile})>[];
    for (int c = 0; c < f.columnsSize; c++) {
      while (true) {
        final dm = g.getNextDropMove(c);
        if (dm == null) {
          break;
        }
        final tile = f[dm.source];
        final fm = FieldMove(toCell: dm.hole, fromCell: dm.source);
        g.applyFieldMoveForUndoOrAnim(fm);
        out.add((move: fm, tile: tile));
      }
    }
    return out;
  }

  List<FieldMove> dropToGround(int column) {
    final moves = <FieldMove>[];
    while (true) {
      final m = getNextDropMove(column);
      if (m == null) {
        break;
      }
      _applyDrop(m);
      moves.add(
        FieldMove(
          toCell: m.hole,
          fromCell: m.source,
        ),
      );
    }
    return moves;
  }

  DropMove? getNextDropMove(int column) {
    final cells = field.getColumnCell(column).reversed.toList();
    if (cells.isEmpty) {
      return null;
    }
    TileCell? hole;
    for (final next in cells) {
      if (hole == null) {
        if (next.tile.isHole()) {
          hole = next;
        }
      } else if (next.tile.isTile()) {
        return DropMove(hole: hole.position, source: next.position);
      }
    }
    return null;
  }

  void _applyDrop(DropMove m) {
    field.setPosition(m.hole, field[m.source]);
    field.setPosition(m.source, Tile.hole);
  }

  void applyFieldMoveForUndoOrAnim(FieldMove m) {
    _applyDrop(
      DropMove(
        hole: m.toCell,
        source: m.fromCell,
      ),
    );
  }

  List<GridPosition> listEmptyCells() {
    return field
        .listAllCells()
        .where((c) => c.tile.isHole())
        .map((c) => c.position)
        .toList();
  }

  List<InsertMove> getNewTileMoves(Tile Function(int column) nextTile) {
    final cells = listEmptyCells()
      ..sort((a, b) {
        if (a.row == b.row) {
          return a.column.compareTo(b.column);
        }
        return b.row - a.row;
      });
    return [for (final c in cells) InsertMove(c, nextTile(c.column))];
  }

  void insert(Iterable<InsertMove> moves) {
    for (final m in moves) {
      field.setPosition(m.target, m.tile);
    }
  }

  @override
  String toString() => field.toString();
}
