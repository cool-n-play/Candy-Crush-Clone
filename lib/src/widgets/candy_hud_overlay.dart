import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../game/candy_jukebox.dart';
import '../game/candy_soundboard.dart';
import '../game/donut_atlas.dart';
import '../logic/level_check.dart';
import '../models/tile.dart';

/// Top bar like [LevelCheckRenderer] + [ScoringRenderer]: moves, objectives, score, settings gear.
class CandyHudOverlay extends StatefulWidget {
  const CandyHudOverlay({
    super.key,
    required this.check,
    required this.onRestart,
    this.sheet,
    this.onMenuOpenChanged,
  });

  final LevelCheck check;
  final VoidCallback onRestart;
  final ui.Image? sheet;
  final ValueChanged<bool>? onMenuOpenChanged;

  @override
  State<CandyHudOverlay> createState() => _CandyHudOverlayState();
}

class _CandyHudOverlayState extends State<CandyHudOverlay> {
  ui.Image? _localSheet;
  var _settingsOpen = false;

  @override
  void initState() {
    super.initState();
    if (widget.sheet == null) {
      _decodeSheet();
    }
  }

  void _setMenuOpen(bool v) {
    if (_settingsOpen == v) {
      return;
    }
    setState(() => _settingsOpen = v);
    widget.onMenuOpenChanged?.call(v);
  }

  Future<void> _decodeSheet() async {
    final data = await rootBundle.load('assets/images/candy_donuts.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) {
      setState(() => _localSheet = frame.image);
    }
  }

  ui.Image? get _effectiveSheet => widget.sheet ?? _localSheet;

  @override
  Widget build(BuildContext context) {
    final orange = GoogleFonts.fredoka(
      fontSize: 28,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFFF8A14),
      shadows: const [
        Shadow(
          blurRadius: 2,
          color: Color(0xFF3D2000),
          offset: Offset(0, 2),
        ),
      ],
    );
    final small = GoogleFonts.fredoka(
      fontSize: 26,
      fontWeight: FontWeight.w600,
      color: const Color(0xFFFF8A14),
      shadows: const [
        Shadow(
          blurRadius: 2,
          color: Color(0xFF3D2000),
          offset: Offset(0, 2),
        ),
      ],
    );
    final ch = widget.check;
    final topPad = MediaQuery.paddingOf(context).top;

    return SizedBox.expand(
      child: Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.none,
        children: [
          if (_settingsOpen)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _setMenuOpen(false),
                child: Container(color: Colors.black.withOpacity(0.35)),
              ),
            ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(6, 4, 6, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    'assets/images/text_arrows_move.png',
                    height: 44,
                    filterQuality: FilterQuality.medium,
                  ),
                  const SizedBox(width: 4),
                  Text('${ch.remainingMoves}', style: small),
                  const SizedBox(width: 12),
                  ..._objectives(ch, orange),
                  const Spacer(),
                  Text('${ch.totalScore}', style: orange),
                  const SizedBox(width: 8),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _setMenuOpen(!_settingsOpen),
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/gui_settings.png',
                        height: 44,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_settingsOpen)
            Positioned(
              right: 8,
              top: topPad + 52,
              child: Material(
                color: Colors.white,
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _toggles(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              widget.onRestart();
                              _setMenuOpen(false);
                            },
                            icon: Image.asset(
                              'assets/images/gui_restart.png',
                              height: 36,
                            ),
                            label: const Text('Reload'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _objectives(LevelCheck ch, TextStyle style) {
    final o = ch.level.tileObjectives;
    final w = <Widget>[];
    for (var i = 0; i < o.length; i++) {
      final t = o[i].tile;
      w.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DonutIcon(tile: t, sheet: _effectiveSheet, size: 40),
            Text('${ch.remainingFor(t)}', style: style),
          ],
        ),
      );
      if (i < o.length - 1) {
        w.add(const SizedBox(width: 10));
      }
    }
    return w;
  }

  Future<void> _playTestSfx() async {
    await CandySoundboard.playTestBlip();
  }

  Widget _toggles() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sound'),
            IconButton(
              icon: Image.asset(
                CandySoundboard.enabled
                    ? 'assets/images/gui_sound_on.png'
                    : 'assets/images/gui_sound_off.png',
                height: 36,
              ),
              onPressed: () async {
                setState(() {
                  CandySoundboard.enabled = !CandySoundboard.enabled;
                });
                if (CandySoundboard.enabled) {
                  await _playTestSfx();
                }
              },
            ),
          ],
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Music'),
            IconButton(
              icon: Image.asset(
                CandyJukebox.isEnabled
                    ? 'assets/images/gui_music_on.png'
                    : 'assets/images/gui_music_off.png',
                height: 36,
              ),
              onPressed: () async {
                final next = !CandyJukebox.isEnabled;
                await CandyJukebox.setEnabled(next);
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _DonutIcon extends StatelessWidget {
  const _DonutIcon({
    required this.tile,
    required this.sheet,
    required this.size,
  });

  final Tile tile;
  final ui.Image? sheet;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = sheet;
    if (s == null) {
      return SizedBox(width: size, height: size);
    }
    final src = DonutAtlas.srcRectForTile(tile);
    if (src == null) {
      return SizedBox(width: size, height: size);
    }
    return CustomPaint(
      size: Size(size, size),
      painter: _DonutPainter(s, src),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.sheet, this.src);
  final ui.Image sheet;
  final ui.Rect src;

  @override
  void paint(Canvas canvas, Size size) {
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(sheet, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.sheet != sheet || old.src != src;
}
