import 'dart:ui' show Offset, Radius, Rect, RRect, Size;

import '../models/game_field.dart';
import '../models/grid_position.dart';

/// Maps the field to screen coordinates — aligned with [GameFieldRenderer] / [PositionGrid] from KorGE.
class BoardLayout {
  const BoardLayout({
    required this.originX,
    required this.originY,
    required this.tileSize,
    required this.field,
    required this.boardFrame,
    required this.tileDrawScale,
  });

  final double originX;
  final double originY;
  final double tileSize;
  final GameField field;

  /// Rounded rect for background panel + clipping (white frosted panel in donor).
  final RRect boardFrame;

  /// Same as KorGE [GameFieldRenderer.tileScale] — shrinks sprites inside each cell.
  final double tileDrawScale;

  factory BoardLayout.fit({
    required Size screen,
    required GameField field,
    required double topPadding,
    double outerMarginH = 10,
    double outerMarginBottom = 12,
    double boardInnerPad = 10,
    double tileDrawScale = 0.82,
  }) {
    if (field.columnsSize == 0) {
      return BoardLayout(
        originX: 0,
        originY: topPadding,
        tileSize: 32,
        field: field,
        boardFrame: RRect.fromRectAndRadius(
          Rect.fromLTWH(0, topPadding, screen.width, 200),
          const Radius.circular(28),
        ),
        tileDrawScale: tileDrawScale,
      );
    }
    final cols = field.columnsSize;
    final rows = field.rowSize;
    final maxW = screen.width - 2 * outerMarginH;
    final maxH = screen.height - topPadding - outerMarginBottom;
    final innerW = (maxW - 2 * boardInnerPad).clamp(40.0, maxW);
    final innerH = (maxH - 2 * boardInnerPad).clamp(40.0, maxH);
    final cw = innerW / cols;
    final ch = innerH / rows;
    final cell = cw < ch ? cw : ch;
    final gridW = cols * cell;
    final gridH = rows * cell;
    final frameW = gridW + 2 * boardInnerPad;
    final frameH = gridH + 2 * boardInnerPad;
    final frameLeft = (screen.width - frameW) / 2;
    final frameTop = topPadding + (maxH - frameH) / 2;
    final originX = frameLeft + boardInnerPad;
    final originY = frameTop + boardInnerPad;
    return BoardLayout(
      originX: originX,
      originY: originY,
      tileSize: cell,
      field: field,
      boardFrame: RRect.fromRectAndRadius(
        Rect.fromLTWH(frameLeft, frameTop, frameW, frameH),
        const Radius.circular(28),
      ),
      tileDrawScale: tileDrawScale,
    );
  }

  /// Inner cell rect (logical grid slot).
  Rect cellRectAt(GridPosition p) {
    final x = originX + p.column * tileSize;
    final y = originY + p.row * tileSize;
    return Rect.fromLTWH(x, y, tileSize, tileSize);
  }

  /// Donor draws donuts at [tileScale] of cell, centered.
  Rect donutDrawRect(GridPosition p) {
    final outer = cellRectAt(p);
    final w = tileSize * tileDrawScale;
    final h = tileSize * tileDrawScale;
    final dx = (tileSize - w) / 2;
    final dy = (tileSize - h) / 2;
    return Rect.fromLTWH(
      outer.left + dx,
      outer.top + dy,
      w,
      h,
    );
  }

  Offset cellCenter(GridPosition p) {
    final r = cellRectAt(p);
    return Offset(r.left + tileSize / 2, r.top + tileSize / 2);
  }

  GridPosition? toCell(Offset local) {
    final c = ((local.dx - originX) / tileSize).floor();
    final r = ((local.dy - originY) / tileSize).floor();
    if (field.isOnField(c, r)) {
      return GridPosition(c, r);
    }
    return null;
  }

  bool isAdjacent(GridPosition a, GridPosition b) {
    final d = a.distanceTo(b);
    return (d - 1.0).abs() < 0.0001;
  }
}
