import 'package:audioplayers/audioplayers.dart';

/// Same playlist as [j4k.candycrush.audio.JukeBox]: cycles through tracks when each finishes.
class CandyJukebox {
  CandyJukebox._();

  static final AudioPlayer _player = AudioPlayer();
  static var _enabled = false;
  static var _idx = 0;
  static var _listenerReady = false;

  static const _tracks = [
    'music/monkey_drama.mp3',
    'music/monkey_island_puzzler.mp3',
  ];

  static Future<void> _attachListener() async {
    if (_listenerReady) {
      return;
    }
    _listenerReady = true;
    await _player.setReleaseMode(ReleaseMode.release);
    _player.onPlayerComplete.listen((_) async {
      if (!_enabled) {
        return;
      }
      _idx = (_idx + 1) % _tracks.length;
      await _player.play(AssetSource(_tracks[_idx]));
    });
  }

  static Future<void> start() async {
    await _attachListener();
    _enabled = true;
    await _player.stop();
    await _player.play(AssetSource(_tracks[_idx % _tracks.length]));
  }

  static Future<void> stop() async {
    _enabled = false;
    await _player.stop();
  }

  static Future<void> setEnabled(bool v) async {
    if (v) {
      await start();
    } else {
      await stop();
    }
  }

  static bool get isEnabled => _enabled;
}
