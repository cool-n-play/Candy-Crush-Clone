import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/extensions.dart';
import 'package:flame/game.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart' as p;
import 'package:flutter/services.dart' show rootBundle;

import '../logic/game_mechanics.dart';
import '../logic/level.dart';
import '../logic/level_check.dart';
import '../models/game_field.dart';
import '../models/grid_position.dart';
import '../models/tile.dart';
import '../models/tile_cell.dart';
import 'board_layout.dart';
import 'candy_soundboard.dart';
import 'donut_atlas.dart';
import 'palette.dart';

class CandyFlameGame extends FlameGame {
  CandyFlameGame({this.onStateChanged});
  void Function()? onStateChanged;

  static const kScorePerTile = 20;
  static const kTouchSlop = 6.0;
  static const _swapSec = 0.38;
  static const _illegalSec = 0.62;
  static const _scorePopSec = 1.1;
  static const _multFadeSec = 1.6;

  late final Level _level = createDefaultLevel();
  late GameMechanics _mech = GameMechanics(_level.field);
  late final LevelCheck progress = LevelCheck(_level);

  BoardLayout? _grid;
  var _busy = false;
  var _rush = 1;
  GridPosition? _selected;
  ui.Image? _donutSheet;
  ui.Image? _bgImage;

  GridPosition? _animA;
  GridPosition? _animB;
  Tile? _animTileA;
  Tile? _animTileB;
  var _swapT = 0.0;
  var _swapIllegal = false;
  var _swapRunning = false;

  final List<_ScorePop> _scorePops = [];
  int? _multShow;
  var _multFadeT = 0.0;

  List<_FallItem>? _falling;
  Completer<void>? _fallComplete;

  List<_InsertItem>? _inserting;
  Completer<void>? _insertComplete;

  int get rush => _rush;
  int get fieldColumns => _field.columnsSize;
  int get fieldRows => _field.rowSize;
  bool get isBusy => _busy;

  int get score => progress.totalScore;

  GameField get _field => _level.field;

  double get hudHeight => 112 * (size.x / 400).clamp(0.85, 1.15);

  void restartLevel() {
    if (_busy) {
      return;
    }
    _level.reset();
    _mech = GameMechanics(_field);
    progress.reset();
    _selected = null;
    _rush = 1;
    _swapRunning = false;
    _animA = null;
    _scorePops.clear();
    _multShow = null;
    _multFadeT = 0;
    _falling = null;
    _fallComplete = null;
    _inserting = null;
    _insertComplete = null;
    _syncGridLayout();
    onStateChanged?.call();
  }

  Future<ui.Image> _decodeAssetImage(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    try {
      _donutSheet = await _decodeAssetImage('assets/images/candy_donuts.png');
      _bgImage = await _decodeAssetImage('assets/images/background.png');
    } catch (_) {}
    _syncGridLayout();
  }

  @override
  void onGameResize(Vector2 s) {
    super.onGameResize(s);
    _syncGridLayout();
  }

  void _syncGridLayout() {
    if (_field.columnsSize < 1 || _field.rowSize < 1) {
      return;
    }
    if (size.x < 0.1 || size.y < 0.1) {
      return;
    }
    _grid = BoardLayout.fit(
      screen: size.toSize(),
      field: _field,
      topPadding: hudHeight,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    final d = dt > 0.05 ? 1 / 60.0 : dt;

    _tickScorePops(d);
    _tickMultiplier(d);
    _tickFalling(d);
    _tickInserting(d);

    if (!_swapRunning) {
      return;
    }
    final step = 1.0 / 60.0;
    final sd = dt > 0.05 ? step : dt;
    if (_swapIllegal) {
      _swapT += sd / _illegalSec;
      if (_swapT >= 1.0) {
        _swapT = 0;
        _swapRunning = false;
        _animA = null;
        _animB = null;
      }
    } else {
      _swapT += sd / _swapSec;
      if (_swapT >= 1.0) {
        _swapT = 0;
        _swapRunning = false;
        _animA = null;
        _animB = null;
      }
    }
    onStateChanged?.call();
  }

  void _tickScorePops(double dt) {
    if (_scorePops.isEmpty) {
      return;
    }
    for (final p in _scorePops) {
      p.t += dt / _scorePopSec;
    }
    _scorePops.removeWhere((p) => p.t >= 1.0);
    onStateChanged?.call();
  }

  void _tickMultiplier(double dt) {
    if (_multShow == null) {
      return;
    }
    _multFadeT += dt / _multFadeSec;
    if (_multFadeT >= 1.0) {
      _multShow = null;
      _multFadeT = 0;
    }
    onStateChanged?.call();
  }

  void _tickFalling(double dt) {
    final list = _falling;
    if (list == null || list.isEmpty) {
      return;
    }
    var done = true;
    for (final f in list) {
      f.t += dt / f.durSec;
      if (f.t < 1.0) {
        done = false;
      }
    }
    if (done) {
      _fallComplete?.complete();
      _falling = null;
      _fallComplete = null;
    }
    onStateChanged?.call();
  }

  void _tickInserting(double dt) {
    final list = _inserting;
    if (list == null || list.isEmpty) {
      return;
    }
    var done = true;
    for (final f in list) {
      f.t += dt / f.durSec;
      if (f.t < 1.0) {
        done = false;
      }
    }
    if (done) {
      _insertComplete?.complete();
      _inserting = null;
      _insertComplete = null;
    }
    onStateChanged?.call();
  }

  @override
  p.Color backgroundColor() => const p.Color(0xFF101820);

  void onHandleTap(ui.Offset local) {
    final l = _grid;
    if (l == null) {
      return;
    }
    final pos = l.toCell(_offset(local));
    if (pos == null) {
      return;
    }
    if (_selected == null) {
      _selected = pos;
    } else if (_selected == pos) {
      _selected = null;
    } else if (l.isAdjacent(_selected!, pos)) {
      unawaited(tryMove(_selected!, pos));
      _selected = null;
    } else {
      _selected = pos;
    }
    onStateChanged?.call();
  }

  void onHandlePan(ui.Offset start, ui.Offset end) {
    if ((start - end).distance < kTouchSlop) {
      onHandleTap(start);
      return;
    }
    final m = _grid;
    if (m == null) {
      return;
    }
    final a = m.toCell(_offset(start));
    final b = m.toCell(_offset(end));
    if (a == null || b == null) {
      return;
    }
    if (!m.isAdjacent(a, b)) {
      return;
    }
    unawaited(tryMove(a, b));
  }

  ui.Offset _offset(ui.Offset p) {
    return p;
  }

  double _easeSwap(double t) => Curves.easeInOut.transform(t.clamp(0.0, 1.0));

  double _easeIllegal(double t) {
    if (t < 0.5) {
      return Curves.easeOut.transform(t * 2) * 0.5;
    }
    return 0.5 + Curves.easeIn.transform((t - 0.5) * 2) * 0.5;
  }

  void _beginSwapAnim(
    GridPosition a,
    GridPosition b, {
    required bool illegal,
    required Tile ta,
    required Tile tb,
  }) {
    _animA = a;
    _animB = b;
    _animTileA = ta;
    _animTileB = tb;
    _swapT = 0;
    _swapIllegal = illegal;
    _swapRunning = true;
  }

  Future<void> _waitSwapAnim() async {
    while (_swapRunning) {
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  void _addScorePopup(int points, GridPosition anchor) {
    if (points <= 0) {
      return;
    }
    final gl = _grid;
    if (gl == null) {
      return;
    }
    _scorePops.add(
      _ScorePop(
        text: points.toString(),
        anchor: gl.cellCenter(anchor),
        t: 0,
      ),
    );
  }

  void _triggerMultiplier(int r) {
    if (r > 1) {
      _multShow = r;
      _multFadeT = 0;
    }
  }

  void _bumpScore(int n, int rush, {required GridPosition anchor}) {
    final delta = n * kScorePerTile * rush;
    progress.onScoreDelta(delta);
    _addScorePopup(delta, anchor);
    _triggerMultiplier(rush);
    onStateChanged?.call();
  }

  Future<void> _runFallAnimations(
    List<({FieldMove move, Tile tile})> batch,
  ) async {
    final gl = _grid;
    if (gl == null || batch.isEmpty) {
      return;
    }
    final items = <_FallItem>[];
    for (final b in batch) {
      final from = gl.cellCenter(b.move.fromCell);
      final to = gl.cellCenter(b.move.toCell);
      final rows = (b.move.toCell.row - b.move.fromCell.row).abs();
      final dur = (0.11 + 0.042 * rows).clamp(0.14, 0.55);
      items.add(
        _FallItem(
          fromCell: b.move.fromCell,
          tile: b.tile,
          from: from,
          to: to,
          t: 0,
          durSec: dur.toDouble(),
        ),
      );
    }
    _falling = items;
    final c = Completer<void>();
    _fallComplete = c;
    await c.future;
  }

  Future<void> _runInsertAnimations(List<InsertMove> ins) async {
    final gl = _grid;
    if (gl == null || ins.isEmpty) {
      return;
    }
    final items = <_InsertItem>[];
    for (final m in ins) {
      final to = gl.cellCenter(m.target);
      final from = ui.Offset(
        to.dx,
        to.dy - gl.tileSize * (3.2 + m.target.row * 0.04),
      );
      final dur = (0.28 + 0.032 * m.target.row).clamp(0.28, 0.65);
      items.add(
        _InsertItem(
          target: m.target,
          tile: m.tile,
          from: from,
          to: to,
          t: 0,
          durSec: dur.toDouble(),
        ),
      );
    }
    _inserting = items;
    final c = Completer<void>();
    _insertComplete = c;
    await c.future;
  }

  Future<void> tryMove(GridPosition a, GridPosition b) async {
    if (_busy) {
      return;
    }
    if (!_mech.isSwapAllowed(a, b)) {
      _busy = true;
      _beginSwapAnim(
        a,
        b,
        illegal: true,
        ta: _field[a],
        tb: _field[b],
      );
      await _waitSwapAnim();
      CandySoundboard.playWrong();
      _busy = false;
      onStateChanged?.call();
      return;
    }
    _busy = true;
    onStateChanged?.call();
    _rush = 1;
    _beginSwapAnim(
      a,
      b,
      illegal: false,
      ta: _field[a],
      tb: _field[b],
    );
    await _waitSwapAnim();

    progress.onSwap();
    _mech.swapTiles(a, b);
    onStateChanged?.call();

    final toClear = _mech.getConnectedTileCells(
      a,
      b,
      onRush: () {
        _rush += 1;
        onStateChanged?.call();
      },
    );
    if (toClear.isEmpty) {
      _mech.swapTiles(a, b);
      CandySoundboard.playWrong();
      _busy = false;
      onStateChanged?.call();
      return;
    }
    final anchor = toClear.first.position;
    _bumpScore(toClear.length, _rush, anchor: anchor);
    progress.onTilesRemoved(toClear);
    _mech.removeTileCells(toClear);
    CandySoundboard.playClear();
    onStateChanged?.call();
    await Future<void>.delayed(const Duration(milliseconds: 85));
    await _dropAndFill();
    await _resolveCascades();
    _busy = false;
    onStateChanged?.call();
  }

  Future<void> _dropAndFill() async {
    for (;;) {
      final batch = _mech.previewDropAllMoves();
      if (batch.isEmpty) {
        break;
      }
      await _runFallAnimations(batch);
      _mech.dropAllToGround();
      CandySoundboard.playDropGround();
      onStateChanged?.call();
    }
    final ins = _mech.getNewTileMoves((c) => _level.getNextTile(c));
    if (ins.isEmpty) {
      return;
    }
    await _runInsertAnimations(ins);
    _mech.insert(ins);
    onStateChanged?.call();
  }

  Future<void> _resolveCascades() async {
    for (;;) {
      final h = GameMechanics(_field.clone());
      final v = GameMechanics(_field.clone());
      final hor = h.getAndRemoveAllHorizontalRows();
      final ver = v.getAndRemoveAllVerticalRows();
      final u = <String, TileCell>{};
      for (final line in [...hor, ...ver]) {
        for (final t in line) {
          u['${t.position.column},${t.position.row}'] = t;
        }
      }
      if (u.isEmpty) {
        return;
      }
      _rush += 1;
      CandySoundboard.playMulti(_rush);
      onStateChanged?.call();
      final cells = u.values.toList();
      final anchor = cells.first.position;
      _bumpScore(cells.length, _rush, anchor: anchor);
      progress.onTilesRemoved(cells);
      _mech.removeTileCells(cells);
      CandySoundboard.playClear();
      onStateChanged?.call();
      await Future<void>.delayed(const Duration(milliseconds: 85));
      await _dropAndFill();
    }
  }

  bool _isFallingFrom(GridPosition p) {
    final list = _falling;
    if (list == null) {
      return false;
    }
    for (final f in list) {
      if (f.fromCell == p) {
        return true;
      }
    }
    return false;
  }

  _InsertItem? _insertAt(GridPosition p) {
    final list = _inserting;
    if (list == null) {
      return null;
    }
    for (final f in list) {
      if (f.target == p) {
        return f;
      }
    }
    return null;
  }

  void _paintBackgroundCover(ui.Canvas c, ui.Image bg, ui.Size sz) {
    final sw = sz.width;
    final sh = sz.height;
    final iw = bg.width.toDouble();
    final ih = bg.height.toDouble();
    final scale = math.max(sw / iw, sh / ih);
    final nw = iw * scale;
    final nh = ih * scale;
    final dx = (sw - nw) / 2;
    final dy = (sh - nh) / 2;
    final dst = ui.Rect.fromLTWH(dx, dy, nw, nh);
    final src = ui.Rect.fromLTWH(0, 0, iw, ih);
    c.drawImageRect(bg, src, dst, ui.Paint());
  }

  void _paintBoardPanel(ui.Canvas c, BoardLayout g) {
    c.drawRRect(
      g.boardFrame,
      ui.Paint()..color = const ui.Color(0xD8FFFFFF),
    );
  }

  void _paintDonut(
    ui.Canvas c,
    BoardLayout g,
    GridPosition p,
    Tile t,
    bool selected,
  ) {
    final sheet = _donutSheet;
    final src = DonutAtlas.srcRectForTile(t);
    final rect = g.donutDrawRect(p);
    if (sheet == null || src == null) {
      _cellFallback(c, g, p, t, selected);
      return;
    }
    final rrect = ui.RRect.fromRectAndRadius(
      rect,
      ui.Radius.circular(rect.shortestSide * 0.12),
    );
    c.save();
    c.clipRRect(rrect);
    c.drawImageRect(sheet, src, rect, ui.Paint());
    c.restore();
    if (selected) {
      c.drawRRect(
        rrect,
        ui.Paint()
          ..color = const ui.Color(0x88FFFFFF)
          ..style = ui.PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }
  }

  void _paintDonutAtCenter(
    ui.Canvas c,
    BoardLayout g,
    ui.Offset center,
    Tile t,
    double side,
  ) {
    final sheet = _donutSheet;
    final src = DonutAtlas.srcRectForTile(t);
    final rect = ui.Rect.fromCenter(center: center, width: side, height: side);
    if (sheet == null || src == null) {
      return;
    }
    final rrect = ui.RRect.fromRectAndRadius(
      rect,
      ui.Radius.circular(side * 0.12),
    );
    c.save();
    c.clipRRect(rrect);
    c.drawImageRect(sheet, src, rect, ui.Paint());
    c.restore();
  }

  void _cellFallback(
    ui.Canvas c,
    BoardLayout g,
    GridPosition p,
    Tile t,
    bool selected,
  ) {
    final e = 2.5 * (selected ? 1.35 : 1.0);
    final r = ui.RRect.fromRectAndRadius(
      g.cellRectAt(p).inflate(e + 0.0),
      const ui.Radius.circular(10),
    );
    c.drawRRect(r, ui.Paint()..color = const ui.Color(0xFF0D3D6E));
    c.drawRRect(
      r.deflate(2.0),
      ui.Paint()..color = colorFor(t),
    );
  }

  void _holeCell(ui.Canvas c, BoardLayout g, GridPosition p) {
    final r = g.donutDrawRect(p).deflate(4);
    c.drawOval(
      r,
      ui.Paint()..color = const ui.Color(0x22000000),
    );
  }

  void _paintScorePops(ui.Canvas c, BoardLayout g) {
    if (_scorePops.isEmpty) {
      return;
    }
    for (final pop in _scorePops) {
      final ease = Curves.easeIn.transform(pop.t.clamp(0.0, 1.0));
      final alpha = 1.0 - ease;
      if (alpha <= 0.01) {
        continue;
      }
      final dy = -56.0 * ease;
      final tp = p.TextPainter(
        text: p.TextSpan(
          text: pop.text,
          style: p.TextStyle(
            fontSize: 38 * (g.tileSize / 48).clamp(0.75, 1.15),
            fontWeight: p.FontWeight.w800,
            color: const p.Color(0xFFFFD54F).withOpacity(alpha),
            shadows: [
              p.Shadow(
                color: p.Color.fromARGB((180 * alpha).round(), 0, 0, 0),
                offset: const ui.Offset(1, 2),
                blurRadius: 3,
              ),
            ],
          ),
        ),
        textDirection: p.TextDirection.ltr,
      )..layout();
      final ox = pop.anchor.dx - tp.width / 2;
      final oy = pop.anchor.dy - tp.height / 2 + dy;
      tp.paint(c, ui.Offset(ox, oy));
    }
  }

  void _paintMultiplier(ui.Canvas c, BoardLayout g) {
    final m = _multShow;
    if (m == null) {
      return;
    }
    final ease = Curves.easeIn.transform(_multFadeT.clamp(0.0, 1.0));
    final alpha = 1.0 - ease;
    if (alpha <= 0.01) {
      return;
    }
    final br = g.boardFrame;
    final rect = br.outerRect;
    final fs = 56.0 * (g.tileSize / 48).clamp(0.7, 1.2);
    final tp = p.TextPainter(
      text: p.TextSpan(
        text: 'x$m',
        style: p.TextStyle(
          fontSize: fs,
          fontWeight: p.FontWeight.w900,
          color: const p.Color(0xFFFFB300).withOpacity(alpha),
          shadows: [
            p.Shadow(
              color: p.Color.fromARGB((200 * alpha).round(), 60, 30, 0),
              offset: const ui.Offset(2, 3),
              blurRadius: 4,
            ),
          ],
        ),
      ),
      textDirection: p.TextDirection.ltr,
    )..layout();
    final x = rect.right - tp.width - 14;
    final y = rect.top + 10;
    tp.paint(c, ui.Offset(x, y));
  }

  void _paintFalling(ui.Canvas c, BoardLayout g, double side) {
    final list = _falling;
    if (list == null) {
      return;
    }
    for (final f in list) {
      final t = Curves.easeIn.transform(f.t.clamp(0.0, 1.0));
      final pos = ui.Offset.lerp(f.from, f.to, t)!;
      _paintDonutAtCenter(c, g, pos, f.tile, side);
    }
  }

  void _paintInserting(ui.Canvas c, BoardLayout g, double side) {
    final list = _inserting;
    if (list == null) {
      return;
    }
    for (final f in list) {
      final t = Curves.easeOutCubic.transform(f.t.clamp(0.0, 1.0));
      final pos = ui.Offset.lerp(f.from, f.to, t)!;
      _paintDonutAtCenter(c, g, pos, f.tile, side);
    }
  }

  @override
  void render(ui.Canvas c) {
    _syncGridLayout();
    super.render(c);
    if (size.x < 0.1 || size.y < 0.1 || _field.rowSize < 1) {
      return;
    }
    final gl = _grid;
    if (gl == null) {
      return;
    }
    final sz = size.toSize();
    final bg = _bgImage;
    if (bg != null) {
      _paintBackgroundCover(c, bg, sz);
    }
    c.save();
    c.clipRRect(gl.boardFrame);
    _paintBoardPanel(c, gl);
    final drawSwap = _swapRunning && _animA != null && _animB != null;
    final ca = drawSwap ? gl.cellCenter(_animA!) : null;
    final cb = drawSwap ? gl.cellCenter(_animB!) : null;
    final tEase = _swapIllegal ? _easeIllegal(_swapT) : _easeSwap(_swapT);
    ui.Offset? posA;
    ui.Offset? posB;
    if (drawSwap && ca != null && cb != null) {
      if (_swapIllegal) {
        final mid = ui.Offset.lerp(ca, cb, 0.5)!;
        if (tEase < 0.5) {
          final u = tEase * 2;
          posA = ui.Offset.lerp(ca, mid, u);
          posB = ui.Offset.lerp(cb, mid, u);
        } else {
          final u = (tEase - 0.5) * 2;
          posA = ui.Offset.lerp(mid, ca, u);
          posB = ui.Offset.lerp(mid, cb, u);
        }
      } else {
        posA = ui.Offset.lerp(ca, cb, tEase);
        posB = ui.Offset.lerp(cb, ca, tEase);
      }
    }
    final side = gl.tileSize * gl.tileDrawScale;
    for (int row = 0; row < _field.rowSize; row++) {
      for (int col = 0; col < _field.columnsSize; col++) {
        final pos = GridPosition(col, row);
        final t = _field.getTile(col, row);
        if (_isFallingFrom(pos)) {
          continue;
        }
        final ins = _insertAt(pos);
        if (ins != null) {
          continue;
        }
        if (t == Tile.hole) {
          _holeCell(c, gl, pos);
        } else if (t.isTile()) {
          if (drawSwap &&
              _animA != null &&
              _animB != null &&
              (_animA == pos || _animB == pos)) {
            continue;
          }
          _paintDonut(c, gl, pos, t, _selected == pos);
        }
      }
    }
    _paintFalling(c, gl, side);
    _paintInserting(c, gl, side);
    if (drawSwap &&
        posA != null &&
        posB != null &&
        _animTileA != null &&
        _animTileB != null) {
      _paintDonutAtCenter(c, gl, posA, _animTileA!, side);
      _paintDonutAtCenter(c, gl, posB, _animTileB!, side);
    }
    _paintMultiplier(c, gl);
    _paintScorePops(c, gl);
    c.restore();
  }
}

class _ScorePop {
  _ScorePop({
    required this.text,
    required this.anchor,
    required this.t,
  });

  final String text;
  final ui.Offset anchor;
  double t;
}

class _FallItem {
  _FallItem({
    required this.fromCell,
    required this.tile,
    required this.from,
    required this.to,
    required this.t,
    required this.durSec,
  });

  final GridPosition fromCell;
  final Tile tile;
  final ui.Offset from;
  final ui.Offset to;
  double t;
  final double durSec;
}

class _InsertItem {
  _InsertItem({
    required this.target,
    required this.tile,
    required this.from,
    required this.to,
    required this.t,
    required this.durSec,
  });

  final GridPosition target;
  final Tile tile;
  final ui.Offset from;
  final ui.Offset to;
  double t;
  final double durSec;
}
