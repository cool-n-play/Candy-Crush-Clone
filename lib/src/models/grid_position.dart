import 'dart:math' as math;

class GridPosition {
  const GridPosition(this.column, this.row);

  final int column;
  final int row;

  GridPosition left([int steps = 1]) => GridPosition(column - steps, row);
  GridPosition right([int steps = 1]) => GridPosition(column + steps, row);
  GridPosition top([int steps = 1]) => GridPosition(column, row - steps);
  GridPosition bottom([int steps = 1]) => GridPosition(column, row + steps);

  double distanceTo(GridPosition other) {
    final dx = (column - other.column).toDouble();
    final dy = (row - other.row).toDouble();
    return math.sqrt(dx * dx + dy * dy);
  }

  @override
  bool operator ==(Object other) {
    if (other is! GridPosition) {
      return false;
    }
    return column == other.column && row == other.row;
  }

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => '($column,$row)';
}
