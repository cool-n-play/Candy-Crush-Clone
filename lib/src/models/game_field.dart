import 'grid_position.dart';
import 'row.dart';
import 'tile.dart';
import 'tile_cell.dart';

/// 2D playing field. Row 0 is the top row (same as Kotlin [GameField]).
class GameField {
  GameField(this.columnsSize, this.rowSize)
    : _rows = List<Row>.generate(
        rowSize,
        (_) => Row.filled(columnsSize),
      );

  final int columnsSize;
  final int rowSize;
  final List<Row> _rows;

  factory GameField.fromString(String data) {
    final rawRows = <List<Tile>>[];
    final re = RegExp(r'\[([^\]]*)\]');
    for (final m in re.allMatches(data)) {
      final body = m.group(1) ?? '';
      if (body.trim().isEmpty) {
        continue;
      }
      final line = body
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .map((e) => Tile.fromShort(e))
          .toList();
      rawRows.add(line);
    }
    if (rawRows.isEmpty) {
      return GameField(0, 0);
    }
    final cols = rawRows.first.length;
    final f = GameField(cols, rawRows.length);
    for (int r = 0; r < rawRows.length; r++) {
      for (int c = 0; c < rawRows[r].length; c++) {
        f.set(c, r, rawRows[r][c]);
      }
    }
    return f;
  }

  GameField clone() {
    final c = GameField(columnsSize, rowSize);
    for (int r = 0; r < rowSize; r++) {
      c._rows[r] = _rows[r].clone();
    }
    return c;
  }

  Tile getTile(int column, int row) {
    if (isOnField(column, row)) {
      return _rows[row].get(column);
    }
    return Tile.outOfSpace;
  }

  Tile operator [](GridPosition p) => getTile(p.column, p.row);

  void set(int column, int row, Tile value) {
    if (isOnField(column, row)) {
      _rows[row].set(column, value);
    }
  }

  void setPosition(GridPosition p, Tile t) {
    set(p.column, p.row, t);
  }

  void setFromCell(TileCell c) {
    setPosition(c.position, c.tile);
  }

  bool isOnField(int column, int row) {
    return column >= 0 && column < columnsSize && row >= 0 && row < rowSize;
  }

  List<TileCell> listAllCells() {
    return listAllPositions().map(getTileCellAt).toList();
  }

  List<GridPosition> listAllPositions() {
    final r = <GridPosition>[];
    for (int row = 0; row < rowSize; row++) {
      for (int c = 0; c < columnsSize; c++) {
        r.add(GridPosition(c, row));
      }
    }
    return r;
  }

  TileCell getTileCell(int column, int row) {
    return TileCell(getTile(column, row), GridPosition(column, row));
  }

  TileCell getTileCellAt(GridPosition p) => getTileCell(p.column, p.row);

  /// Bottom cell of a column in this field (as in [Level] reserve logic).
  TileCell getTileCellOnGround(int column) {
    return getTileCell(column, rowSize - 1);
  }

  List<TileCell> getColumnCell(int column) {
    return List<TileCell>.generate(
      rowSize,
      (row) => getTileCell(column, row),
    );
  }

  void shuffle() {
    for (final p in listAllPositions()) {
      setPosition(p, Tile.randomTile());
    }
  }

  void reload(String levelData) {
    final f = GameField.fromString(levelData);
    for (final cell in f.listAllCells()) {
      setFromCell(cell);
    }
  }

  @override
  String toString() {
    return _rows.map((e) => e.toString()).join('\n');
  }
}
