import 'tile.dart';

/// One horizontal line of the field (port of Row).
class Row {
  Row._(this._cells);

  factory Row.filled(int length) {
    return Row._(List.filled(length, Tile.hole));
  }

  factory Row.outOfSpace() {
    return Row._(const [Tile.outOfSpace]);
  }

  final List<Tile> _cells;

  int get length => _cells.length;

  Tile get(int i) {
    if (i < 0 || i >= _cells.length) {
      return Tile.outOfSpace;
    }
    return _cells[i];
  }

  set(int i, Tile t) {
    if (i >= 0 && i < _cells.length) {
      _cells[i] = t;
    }
  }

  void copyFrom(Row other) {
    for (int i = 0; i < _cells.length && i < other._cells.length; i++) {
      _cells[i] = other._cells[i];
    }
  }

  Row clone() {
    return Row._(List<Tile>.from(_cells));
  }

  @override
  String toString() {
    return '[${_cells.map((e) => e.shortName).join(", ")}]';
  }
}
