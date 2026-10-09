import 'dart:math';
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';

/// All audio is synthesized programmatically — no downloaded assets.
/// Identity: wooden biscuit clacks, soft dough thumps, warm hearth chimes,
/// and a low oven-crackle ambient bed. Matches the artisanal-bakery theme.
///
/// Reliability design (every call is safe to repeat and safe to overlap):
/// - Clips are synthesized ONCE and cached; starting music never blocks the
///   UI thread after the first build.
/// - A [_musicGen] generation counter serializes track changes: every
///   start/stop bumps the generation, in-flight work from an older request
///   aborts, and the LATEST request always wins. Overlapping calls (menu
///   in/out, pause/resume, toggles) can never swallow a start or leave the
///   player half-started — music is app-scoped and never silently dies.
/// - Lifecycle uses pause()/resume() so an interruption (call,
///   backgrounding) resumes exactly where it left off instead of restarting
///   or dying.
/// - Every public method catches player errors; audio can never crash the app.
class SoundService {
  static const _sr = 22050;
  final _rnd = Random(2048);

  final _sfxPool = <AudioPlayer>[];
  int _poolIdx = 0;
  final _music = AudioPlayer();

  bool sfxOn = true;
  bool musicOn = true;
  double sfxVolume = 0.8;
  double musicVolume = 0.6;

  // Cache synthesized clips so we only build them once.
  final Map<String, Uint8List> _cache = {};

  // Music state machine. [_musicGen] is bumped by every start/stop request;
  // async work checks it still owns the latest generation before touching
  // the player, so overlapping requests can never desync the music.
  int _musicGen = 0;
  bool _musicBusy = false;
  String? _currentTrack; // 'menu' | 'game' | null
  bool _pausedByLifecycle = false;
  bool _disposed = false;

  Future<void> init() async {
    try {
      for (var i = 0; i < 4; i++) {
        _sfxPool.add(AudioPlayer());
      }
      await _music.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}
  }

  /// Pre-build music clips off the critical path. Safe to call any time.
  Future<void> prewarm() async {
    if (_disposed) return;
    await Future(() {});
    _menuMusicBytes();
    _gameMusicBytes();
  }

  // ---------------- public API ----------------

  /// Biscuits sliding on the tray — a wooden clack.
  void playSlide() => _play(_clip('slide', () => _woodenClack(190, 0.9)));

  /// Doughy thump when two biscuits merge; pitch rises with the new value.
  void playMerge(int value) {
    final e = value <= 0 ? 1 : (log(value) / ln2).round().clamp(1, 14);
    _play(_clip('merge_$e', () => _mergeThump(e)));
  }

  void playSpawn() => _play(_clip('spawn', _doughPop));
  void playInvalid() => _play(_clip('invalid', _dullThud));
  void playTap() => _play(_clip('tap', _woodTap));
  void playStart() => _play(_clip('start', _warmTwoTone));
  void playWin() => _play(_clip('win', _hearthChime));
  void playLose() => _play(_clip('lose', _ovenDoorThud));

  void _play(Uint8List bytes) {
    if (!sfxOn || _disposed || _sfxPool.isEmpty) return;
    try {
      final p = _sfxPool[_poolIdx++ % _sfxPool.length];
      p.setVolume(sfxVolume.clamp(0.0, 1.0));
      p.play(BytesSource(bytes));
    } catch (_) {}
  }

  /// mode: 'menu' | 'game' | 'none'. Generation-serialized: the latest
  /// request always wins; a start issued while an older one is in flight is
  /// never dropped. Re-requesting the current track just ensures audibility.
  void setMusicMode(String mode) {
    final gen = ++_musicGen;
    if (mode == 'none' || !musicOn) {
      _stopMusicNow(gen);
      return;
    }
    _startTrack(gen, mode);
  }

  Future<void> _startTrack(int gen, String track) async {
    if (_disposed) return;
    if (_currentTrack == track && !_pausedByLifecycle) {
      // Already on this track — make sure it is actually audible.
      try {
        await _music.resume();
      } catch (_) {}
      return;
    }
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (gen != _musicGen || _disposed || !musicOn) return;
    _musicBusy = true;
    try {
      await _music.stop();
      if (gen != _musicGen || _disposed || !musicOn) return;
      _currentTrack = track;
      _pausedByLifecycle = false;
      await _music.setVolume(musicVolume * (track == 'menu' ? 0.7 : 0.55));
      await _music.play(
          BytesSource(track == 'menu' ? _menuMusicBytes() : _gameMusicBytes()));
    } catch (_) {
      if (gen == _musicGen) _currentTrack = null;
    } finally {
      _musicBusy = false;
    }
  }

  Future<void> _stopMusicNow(int gen) async {
    while (_musicBusy) {
      await Future.delayed(const Duration(milliseconds: 30));
    }
    if (gen != _musicGen || _disposed) return;
    try {
      await _music.stop();
    } catch (_) {}
    _currentTrack = null;
    _pausedByLifecycle = false;
  }

  /// App went to background / interruption: pause (not stop) so we resume
  /// exactly where we left off.
  Future<void> onAppPaused() async {
    if (_disposed || _currentTrack == null) return;
    try {
      await _music.pause();
      _pausedByLifecycle = true;
    } catch (_) {}
  }

  /// App came back: resume only if we paused it and music is still wanted.
  Future<void> onAppResumed() async {
    if (_disposed || !musicOn || !_pausedByLifecycle) return;
    _pausedByLifecycle = false;
    try {
      await _music.resume();
    } catch (_) {
      // Resume failed (e.g. player was released) — restart the track.
      final track = _currentTrack;
      _currentTrack = null;
      setMusicMode(track ?? 'none');
    }
  }

  void applySettings(
      {required bool sfxOn,
      required bool musicOn,
      required double sfxVolume,
      required double musicVolume}) {
    this.sfxOn = sfxOn;
    this.sfxVolume = sfxVolume;
    final wasMusic = this.musicOn;
    this.musicOn = musicOn;
    this.musicVolume = musicVolume;
    if (!musicOn) {
      setMusicMode('none');
    } else if (!wasMusic) {
      // toggling music back on: force-restart the current mode's track
      final track = _currentTrack;
      _currentTrack = null;
      setMusicMode(track ?? 'menu');
    } else {
      try {
        _music.setVolume(musicVolume * (_currentTrack == 'menu' ? 0.7 : 0.55));
      } catch (_) {}
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    _musicGen++; // cancel any in-flight start
    for (final p in _sfxPool) {
      try {
        await p.dispose();
      } catch (_) {}
    }
    try {
      await _music.dispose();
    } catch (_) {}
  }

  // ---------------- clip cache ----------------

  Uint8List _clip(String key, Uint8List Function() build) =>
      _cache.putIfAbsent(key, build);

  Uint8List _menuMusicBytes() => _clip('music_menu', _hearthAmbientLoop);
  Uint8List _gameMusicBytes() => _clip('music_game', _ovenCrackleLoop);

  // ---------------- synthesis ----------------

  Uint8List _wav(List<double> s) {
    final n = s.length;
    final data = ByteData(44 + n * 2);
    void str(int o, String v) {
      for (var i = 0; i < v.length; i++) {
        data.setUint8(o + i, v.codeUnitAt(i));
      }
    }
    str(0, 'RIFF');
    data.setUint32(4, 36 + n * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    data.setUint32(16, 16, Endian.little);
    data.setUint16(20, 1, Endian.little);
    data.setUint16(22, 1, Endian.little);
    data.setUint32(24, _sr, Endian.little);
    data.setUint32(28, _sr * 2, Endian.little);
    data.setUint16(32, 2, Endian.little);
    data.setUint16(34, 16, Endian.little);
    str(36, 'data');
    data.setUint32(40, n * 2, Endian.little);
    for (var i = 0; i < n; i++) {
      final v = s[i].clamp(-1.0, 1.0);
      data.setInt16(44 + i * 2, (v * 32767).round(), Endian.little);
    }
    return data.buffer.asUint8List();
  }

  double _noise() => _rnd.nextDouble() * 2 - 1;

  /// Wooden biscuit clack: noise snap + woody knock.
  Uint8List _woodenClack(double freq, double brightness) {
    final n = (_sr * 0.14).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final env = exp(-t * 48);
      final knock = sin(2 * pi * freq * t) * exp(-t * 34) * 0.7;
      final snap = _noise() * exp(-t * 180) * 0.3 * brightness;
      s[i] = (knock + snap) * env * 1.3;
    }
    return _wav(s);
  }

  /// Soft dough thump for a merge; pitch climbs with the tile exponent.
  Uint8List _mergeThump(int exponent) {
    final freq = 150.0 + exponent * 26.0;
    final n = (_sr * 0.22).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final body = sin(2 * pi * freq * t) * exp(-t * 24) * 0.8;
      final puff = _noise() * exp(-t * 90) * 0.18; // floury puff
      final ring = sin(2 * pi * freq * 2.02 * t) * exp(-t * 40) * 0.15;
      s[i] = (body + puff + ring) * 1.25;
    }
    return _wav(s);
  }

  /// Gentle dough pop when a fresh biscuit spawns.
  Uint8List _doughPop() {
    final n = (_sr * 0.09).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      s[i] = (sin(2 * pi * 320 * t) * exp(-t * 70) * 0.35 +
              _noise() * exp(-t * 160) * 0.12) *
          1.0;
    }
    return _wav(s);
  }

  /// Dull thud for an illegal swipe.
  Uint8List _dullThud() {
    final n = (_sr * 0.24).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      s[i] = (sin(2 * pi * 96 * t) * exp(-t * 20) * 0.8 +
              _noise() * exp(-t * 55) * 0.22) *
          1.15;
    }
    return _wav(s);
  }

  /// Crisp wooden button tap.
  Uint8List _woodTap() {
    final n = (_sr * 0.07).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      s[i] = (sin(2 * pi * 540 * t) * exp(-t * 95) * 0.5 +
              _noise() * exp(-t * 220) * 0.18) *
          1.1;
    }
    return _wav(s);
  }

  /// Warm two-tone game-start (like an oven timer's friendly ding-ding).
  Uint8List _warmTwoTone() {
    const f1 = 392.0, f2 = 523.25; // G4, C5 — warm major lift
    final n = (_sr * 0.8).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final a = sin(2 * pi * f1 * t) * exp(-t * 5.5) * (t < 0.35 ? 1 : 0.4);
      final b = t > 0.24
          ? sin(2 * pi * f2 * (t - 0.24)) * exp(-(t - 0.24) * 5.5)
          : 0.0;
      s[i] = (a + b) * 0.42;
    }
    return _wav(s);
  }

  /// Warm hearth chime: pentatonic ascent with soft harmonics.
  Uint8List _hearthChime() {
    const freqs = [523.3, 587.3, 659.3, 784.0, 880.0, 1046.5];
    final n = (_sr * 2.6).round();
    final s = List<double>.filled(n, 0);
    for (var k = 0; k < freqs.length; k++) {
      final start = (_sr * k * 0.17).round();
      final f = freqs[k];
      for (var i = 0; i + start < n; i++) {
        final t = i / _sr;
        if (t > 1.8) break;
        final env = exp(-t * 3.0) * (1 - exp(-t * 55));
        s[start + i] += (sin(2 * pi * f * t) * 0.6 +
                sin(2 * pi * f * 2 * t) * 0.16 +
                sin(2 * pi * f * 2.99 * t) * 0.07) *
            env *
            0.32;
      }
    }
    return _wav(s);
  }

  /// Oven-door thud for game over.
  Uint8List _ovenDoorThud() {
    final n = (_sr * 0.8).round();
    final s = List<double>.filled(n, 0);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      final slam = t < 0.12 ? _noise() * exp(-t * 60) * 0.4 : 0.0;
      s[i] = (sin(2 * pi * 72 * t) * exp(-t * 8) * 0.9 + slam) * 0.9;
    }
    return _wav(s);
  }

  /// 24s warm hearth ambient loop for the menu: low warm pad + sparse
  /// wooden-xylophone plucks (C major pentatonic), slow loop crossfade.
  Uint8List _hearthAmbientLoop() {
    const dur = 24.0;
    final n = (_sr * dur).round();
    final s = List<double>.filled(n, 0);
    const chords = [
      [130.8, 196.0, 261.6, 329.6], // C
      [110.0, 164.8, 220.0, 329.6], // Am
      [87.3, 174.6, 261.6, 349.2], // F
      [98.0, 196.0, 246.9, 392.0], // G
    ];
    const seg = 6.0;
    for (var c = 0; c < 4; c++) {
      for (final f in chords[c]) {
        for (var i = 0; i < _sr * seg; i++) {
          final g = c * seg + i / _sr;
          final idx = (g * _sr).round() % n;
          final t = i / _sr;
          final env = (sin(pi * t / seg) * 0.5 + 0.5);
          s[idx] += (sin(2 * pi * f * t) * 0.5 +
                  sin(2 * pi * f * 2.01 * t) * 0.1) *
              env *
              0.026;
        }
      }
    }
    const penta = [523.3, 587.3, 659.3, 784.0, 880.0, 1046.5];
    final pluckRng = Random(9);
    for (var k = 0; k < 12; k++) {
      final start = (pluckRng.nextDouble() * dur * _sr).round();
      final f = penta[pluckRng.nextInt(penta.length)];
      for (var i = 0; i < _sr * 2.0 && start + i < n; i++) {
        final t = i / _sr;
        final env = exp(-t * 2.6) * (1 - exp(-t * 130));
        s[(start + i) % n] +=
            (sin(2 * pi * f * t) * 0.65 + sin(2 * pi * f * 2 * t) * 0.18) *
                env *
                0.045;
      }
    }
    final fade = _sr;
    for (var i = 0; i < fade; i++) {
      final a = i / fade;
      final v = s[i] * a + s[n - fade + i] * (1 - a);
      s[i] = v;
      s[n - fade + i] = v;
    }
    return _wav(s);
  }

  /// 12s soft oven bed for gameplay: gentle brown noise + faint hearth
  /// crackle pops, looped with a crossfade.
  Uint8List _ovenCrackleLoop() {
    const dur = 12.0;
    final n = (_sr * dur).round();
    final s = List<double>.filled(n, 0);
    var last = 0.0;
    final crackleRng = Random(21);
    for (var i = 0; i < n; i++) {
      final t = i / _sr;
      last = (last + 0.02 * _noise()) / 1.02;
      final breathe = 0.6 + 0.4 * sin(2 * pi * t / dur);
      s[i] = last * 0.3 * breathe;
    }
    // faint hearth crackle pops
    for (var k = 0; k < 40; k++) {
      final start = (crackleRng.nextDouble() * dur * _sr).round();
      final len = (_sr * (0.01 + crackleRng.nextDouble() * 0.03)).round();
      final amp = 0.05 + crackleRng.nextDouble() * 0.12;
      for (var i = 0; i < len && start + i < n; i++) {
        final t = i / _sr;
        s[start + i] += _noise() * exp(-t * 220) * amp;
      }
    }
    final fade = _sr;
    for (var i = 0; i < fade; i++) {
      final a = i / fade;
      final v = s[i] * a + s[n - fade + i] * (1 - a);
      s[i] = v;
      s[n - fade + i] = v;
    }
    return _wav(s);
  }
}
