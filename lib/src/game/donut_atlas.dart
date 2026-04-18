import 'dart:ui' as ui;

import '../models/tile.dart';

/// Sprite sheet layout from KorGE [CandySets.donuts]: `candy_donuts.png`, 5×4 grid.
class DonutAtlas {
  DonutAtlas._();

  static const double spritePx = 212;
  static const int cols = 5;
  static const int rows = 4;

  /// Same indices as `suspend fun donuts()` in donor [CandySets.kt].
  static const Map<Tile, int> donutTileIndex = {
    Tile.a: 14,
    Tile.b: 8,
    Tile.c: 5,
    Tile.d: 10,
    Tile.e: 16,
  };

  static ui.Rect? srcRectForTile(Tile t) {
    final idx = donutTileIndex[t];
    if (idx == null) {
      return null;
    }
    final col = idx % cols;
    final row = idx ~/ cols;
    return ui.Rect.fromLTWH(
      col * spritePx,
      row * spritePx,
      spritePx,
      spritePx,
    );
  }
}
