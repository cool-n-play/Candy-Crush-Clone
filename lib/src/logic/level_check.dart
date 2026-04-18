import '../models/tile.dart';
import '../models/tile_cell.dart';
import 'level.dart';

/// Tracks moves, per-tile clears, and total score — ported from [j4k.candycrush.LevelCheck].
class LevelCheck {
  LevelCheck(this.level);

  final Level level;

  int totalScore = 0;
  int moves = 0;
  final Map<Tile, int> tileCounters = {};

  int get remainingMoves {
    final m = level.maxMoves;
    if (m == null) {
      return 999999;
    }
    return (m - moves).clamp(0, m);
  }

  int remainingFor(Tile tile) {
    final goal = level.goalFor(tile);
    if (goal == null) {
      return 0;
    }
    return (goal - (tileCounters[tile] ?? 0)).clamp(0, goal);
  }

  bool get goalsSatisfied {
    if (level.tileObjectives.isEmpty) {
      return false;
    }
    for (final o in level.tileObjectives) {
      if ((tileCounters[o.tile] ?? 0) < o.goal) {
        return false;
      }
    }
    return true;
  }

  bool get outOfMoves =>
      level.maxMoves != null && moves >= level.maxMoves!;

  void onSwap() {
    moves++;
  }

  void onScoreDelta(int delta) {
    totalScore += delta;
  }

  void onTilesRemoved(List<TileCell> cells) {
    for (final c in cells) {
      if (c.tile.isTile()) {
        tileCounters[c.tile] = (tileCounters[c.tile] ?? 0) + 1;
      }
    }
  }

  void reset() {
    moves = 0;
    totalScore = 0;
    tileCounters.clear();
  }
}
