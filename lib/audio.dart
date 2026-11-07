import 'package:audioplayers/audioplayers.dart';

/// Sound effects + looping background music (generated WAV tones in assets/audio).
class Audio {
  bool snd = true;
  int mus = 70;
  bool _started = false;
  AudioPlayer? _music;
  final List<AudioPlayer> _pool = [];
  int _next = 0;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    try {
      for (var i = 0; i < 6; i++) {
        _pool.add(AudioPlayer()..setPlayerMode(PlayerMode.lowLatency));
      }
      _music = AudioPlayer();
      await _music!.setReleaseMode(ReleaseMode.loop);
      applyMusic();
    } catch (_) {}
  }

  void applyMusic() {
    final m = _music;
    if (m == null) return;
    try {
      if (snd && mus > 0) {
        m.setVolume(mus / 100 * .6);
        m.play(AssetSource('audio/music.wav'), volume: mus / 100 * .6);
      } else {
        m.pause();
      }
    } catch (_) {}
  }

  void sfx(String name) {
    if (!snd || _pool.isEmpty) return;
    try {
      final p = _pool[_next++ % _pool.length];
      p.play(AssetSource('audio/$name.wav'), volume: .5);
    } catch (_) {}
  }
}
