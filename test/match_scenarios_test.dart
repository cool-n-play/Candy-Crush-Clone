import 'package:candy_crush_clone/src/logic/game_mechanics.dart';
import 'package:candy_crush_clone/src/logic/level.dart';
import 'package:candy_crush_clone/src/logic/match_scoring.dart';
import 'package:candy_crush_clone/src/models/game_field.dart';
import 'package:candy_crush_clone/src/models/grid_position.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MatchScoring', () {
    test('3 tiles rush 1 → 60', () {
      expect(
        MatchScoring.scoreDeltaForClear(tilesRemoved: 3, rush: 1),
        60,
      );
    });
    test('4 tiles rush 1 → 80', () {
      expect(
        MatchScoring.scoreDeltaForClear(tilesRemoved: 4, rush: 1),
        80,
      );
    });
    test('5 tiles rush 1 → 100', () {
      expect(
        MatchScoring.scoreDeltaForClear(tilesRemoved: 5, rush: 1),
        100,
      );
    });
    test('6 tiles rush 2 → 240', () {
      expect(
        MatchScoring.scoreDeltaForClear(tilesRemoved: 6, rush: 2),
        240,
      );
    });
  });

  group('illegal swap', () {
    test('board unchanged when swap would not create a match', () {
      final level = createMockLevel();
      final before = level.field.toString();
      final mech = GameMechanics(level.field);
      final a = const GridPosition(0, 0);
      final b = const GridPosition(0, 1);
      expect(mech.isSwapAllowed(a, b), isFalse);
      expect(level.field.toString(), before);
    });
  });

  group('mock level swap', () {
    test('known adjacent swap is allowed and clears 3 A', () {
      final level = createMockLevel();
      final mech = GameMechanics(level.field);
      final a = const GridPosition(1, 0);
      final b = const GridPosition(1, 1);
      expect(mech.isSwapAllowed(a, b), isTrue);
      mech.swapTiles(a, b);
      var rush = 1;
      final cleared = mech.getConnectedTileCells(
        a,
        b,
        onRush: () => rush++,
      );
      expect(cleared.length, 3);
      expect(MatchScoring.scoreDeltaForClear(tilesRemoved: cleared.length, rush: rush), rush * 60);
    });
  });

  group('line length clears', () {
    test('four in a row removes 4 cells', () {
      final f = GameField.fromString('''
        [A,B,A,A,C]
        [D,E,C,B,D]
        [E,D,B,C,E]
        ''');
      final mech = GameMechanics(f);
      final a = const GridPosition(1, 0);
      final b = const GridPosition(2, 0);
      expect(mech.isSwapAllowed(a, b), isTrue);
      mech.swapTiles(a, b);
      var rush = 1;
      final cleared = mech.getConnectedTileCells(a, b, onRush: () => rush++);
      expect(cleared.length, 4);
    });

    test('five in a row removes 5 cells', () {
      final f = GameField.fromString('''
        [A,A,B,A,A]
        [C,D,E,B,C]
        [D,E,C,A,D]
        ''');
      final mech = GameMechanics(f);
      final a = const GridPosition(2, 0);
      final b = const GridPosition(1, 0);
      expect(mech.isSwapAllowed(a, b), isTrue);
      mech.swapTiles(a, b);
      var rush = 1;
      final cleared = mech.getConnectedTileCells(a, b, onRush: () => rush++);
      expect(cleared.length, 5);
    });
  });

  group('rush / “x2” from two line groups', () {
    test('when both swapped cells each report a line group, onRush runs once', () {
      final f = GameField.fromString('''
        [A,B,A]
        [D,A,E]
        [B,C,D]
        ''');
      final mech = GameMechanics(f);
      final a = const GridPosition(1, 0);
      final b = const GridPosition(1, 1);
      mech.swapTiles(a, b);
      var rushes = 0;
      mech.getConnectedTileCells(a, b, onRush: () => rushes++);
      expect(rushes, 1);
    });
  });
}
