import 'dart:ui' as ui;

import 'package:flame/game.dart' show GameWidget;
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/material.dart';

import 'package:candy_crush_clone/src/game/candy_flame_game.dart';
import 'package:candy_crush_clone/src/widgets/candy_hud_overlay.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Default FlameAudio prefix is assets/audio/; our files live under assets/sounds/, assets/music/.
  FlameAudio.updatePrefix('assets/');

  runApp(const CandyApp());
}

class CandyApp extends StatelessWidget {
  const CandyApp({super.key});
  @override
  Widget build(BuildContext c) {
    return MaterialApp(
      title: 'Candy Crush (Flutter)',
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0D8BD9),
          brightness: Brightness.dark,
        ),
      ),
      home: const CandyAppBody(),
    );
  }
}

class CandyAppBody extends StatefulWidget {
  const CandyAppBody({super.key});
  @override
  State<CandyAppBody> createState() => _CandyAppBodyState();
}

class _CandyAppBodyState extends State<CandyAppBody> {
  late final CandyFlameGame g;
  ui.Offset? kDown;
  var _settingsMenuOpen = false;
  var _syncScheduled = false;

  @override
  void initState() {
    g = CandyFlameGame(
      onStateChanged: _sync,
    );
    super.initState();
  }

  /// Flame can call this from resize/update during [GameWidget]'s build — never
  /// call [setState] synchronously from here.
  void _sync() {
    if (!mounted || _syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _onMenuOpenChanged(bool open) {
    if (_settingsMenuOpen == open) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => _settingsMenuOpen = open);
      }
    });
  }

  @override
  Widget build(BuildContext c) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (ctx, cst) {
          return Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: SizedBox(
                  width: cst.maxWidth,
                  height: cst.maxHeight,
                  child: GameWidget(
                    key: const ValueKey('candy'),
                    game: g,
                    loadingBuilder: (ctx) => const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Color(0xFF90CAF9),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _settingsMenuOpen,
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerDown: (e) {
                      if (g.isBusy) {
                        return;
                      }
                      kDown = e.localPosition;
                    },
                    onPointerUp: (e) {
                      if (g.isBusy) {
                        return;
                      }
                      final a = kDown;
                      if (a == null) {
                        return;
                      }
                      final b = e.localPosition;
                      if ((a - b).distance < 7) {
                        g.onHandleTap(b);
                      } else {
                        g.onHandlePan(a, b);
                      }
                      kDown = null;
                    },
                  ),
                ),
              ),
              Positioned.fill(
                child: CandyHudOverlay(
                  check: g.progress,
                  onRestart: g.isBusy ? () {} : g.restartLevel,
                  onMenuOpenChanged: _onMenuOpenChanged,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
