import 'package:flame_audio/flame_audio.dart';

/// Donor [SoundMachine] / BGM — same file names under `assets/`.
class CandySoundboard {
  CandySoundboard._();

  static var enabled = true;

  static void playClear() {
    if (!enabled) {
      return;
    }
    FlameAudio.play('sounds/clear.mp3');
  }

  static void playWrong() {
    if (!enabled) {
      return;
    }
    FlameAudio.play('sounds/wrong_move.mp3');
  }

  static void playDropGround() {
    if (!enabled) {
      return;
    }
    FlameAudio.play('sounds/drop_ground.mp3');
  }

  /// Donor [SoundMachine.playMulti] — rush chain depth 2..6+.
  static void playMulti(int rush) {
    if (!enabled) {
      return;
    }
    final path = switch (rush.clamp(2, 6)) {
      2 => 'sounds/multi_2.mp3',
      3 => 'sounds/multi_3.mp3',
      4 => 'sounds/multi_4.mp3',
      5 => 'sounds/multi_5.mp3',
      _ => 'sounds/multi_6.mp3',
    };
    FlameAudio.play(path);
  }

  /// Background music is handled by [CandyJukebox] (same files as KorGE [JukeBox]).
  static Future<void> startBgm() async {}

  /// Short feedback when enabling sound in settings (requires [FlameAudio.updatePrefix] to `assets/`).
  static Future<void> playTestBlip() async {
    if (!enabled) {
      return;
    }
    await FlameAudio.play('sounds/clear.mp3', volume: 0.35);
  }
}
