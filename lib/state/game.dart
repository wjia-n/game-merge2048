import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/sound.dart';
import '../engine/merge_engine.dart';
import '../theme/bakery_themes.dart';
import 'settings.dart';

/// Visible tile on the board. ids are stable across a run so the UI can
/// animate tile motion with AnimatedPositioned.
class BoardTile {
  final int id;
  int value;
  int row;
  int col;
  bool fading; // absorbed by a merge; animates out, then purged
  BoardTile(this.id, this.value, this.row, this.col, {this.fading = false});
}

class _UndoSnap {
  final List<int> values; // size*size values, row-major
  final int score;
  _UndoSnap(this.values, this.score);
}

/// Full Merge 2048 session: rules state, animation sequencing, scoring,
/// undo, victory/game-over flow, save/resume. The board painter and screens
/// only read; all mutation goes through here.
///
/// The engine OWNS the turn state machine: a swipe locks input, a
/// generation-guarded timer settles the turn (purge, spawn, unlock,
/// evaluate). A watchdog sweeps any phase left without a live timer, so a
/// stuck state is impossible by construction.
class Merge2048Game extends ChangeNotifier {
  final Merge2048Settings settings;
  final SoundService sound;
  final Random _rng;

  String modeId;
  int get size => GameModes.byId(modeId).size;
  int get cells => size * size;

  Merge2048Game({
    required this.settings,
    required this.sound,
    String? modeId,
    Random? rng,
  })  : modeId = modeId ?? settings.modeId,
        _rng = rng ?? Random() {
    _startWatchdog();
  }

  // ---- live state ----
  final Map<int, BoardTile> tiles = {};
  List<int?> board = []; // cell -> tile id, row-major, size*size
  int score = 0;
  int moves = 0;
  bool over = false;
  bool paused = false;
  bool inputLocked = false;

  // ---- dialog / animation flags (read by the UI) ----
  bool victoryShown = false; // victory dialog fired once per run
  bool showVictory = false; // victory dialog currently visible
  bool showGameOver = false; // game-over dialog currently visible
  bool _pendingGameOver = false; // victory took precedence (RULES edge 3)
  bool newBestThisRun = false;

  Set<int> mergedIds = {}; // pop animation
  Set<int> fadingIds = {}; // shrink-out animation
  int? spawnedId; // scale-in animation
  int animGen = 0; // bumped per swipe; keys pop/spawn animations
  int invalidShake = 0; // bumped per illegal swipe; keys shake animation

  static const animMs = 170;

  int _nextId = 1;
  _UndoSnap? _undo;
  int _gen = 0; // invalidates pending post-animation timers

  // Watchdog: every lock carries a deadline; the watchdog forces a settle
  // if the animation timer never fired (stuck states impossible).
  DateTime _lockDeadline = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _watchdog;
  bool _disposed = false;

  bool get canUndo =>
      settings.undoOn &&
      _undo != null &&
      !inputLocked &&
      !paused &&
      !showVictory &&
      !showGameOver;

  List<int> get values => [
        for (var i = 0; i < cells; i++)
          board[i] == null ? 0 : tiles[board[i]]!.value,
      ];

  int get maxTileValue {
    var m = 0;
    for (final t in tiles.values) {
      if (t.value > m) m = t.value;
    }
    return m;
  }

  void _startWatchdog() {
    _watchdog?.cancel();
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_disposed || over) return;
      if (inputLocked && DateTime.now().isAfter(_lockDeadline)) {
        // Stale lock: the settle timer was lost somehow. Force-settle the
        // same generation so the game can always move forward.
        _settle(_gen);
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _gen++; // invalidate any in-flight timers
    _watchdog?.cancel();
    super.dispose();
  }

  /// Switch modes; resets the run cleanly (RULES edge 7).
  void setMode(String id) {
    modeId = id;
    settings.update(() => settings.modeId = id);
    newGame();
  }

  // ================= setup =================

  void newGame() {
    _gen++;
    tiles.clear();
    board = List<int?>.filled(cells, null);
    score = 0;
    moves = 0;
    over = false;
    paused = false;
    inputLocked = false;
    victoryShown = false;
    showVictory = false;
    showGameOver = false;
    _pendingGameOver = false;
    newBestThisRun = false;
    mergedIds = {};
    fadingIds = {};
    spawnedId = null;
    _undo = null;
    _nextId = 1;
    _spawnRandom();
    _spawnRandom();
    sound.playStart();
    _persist();
    notifyListeners();
  }

  void _spawnRandom({bool silent = false}) {
    final boardRefs = _boardRefs();
    final idx = MergeEngine.spawnIndex(boardRefs, _rng);
    if (idx < 0) return;
    final id = _nextId++;
    final value = MergeEngine.spawnValue(_rng);
    tiles[id] = BoardTile(id, value, idx ~/ size, idx % size);
    board[idx] = id;
    if (!silent) spawnedId = id;
  }

  List<TileRef?> _boardRefs() => [
        for (var i = 0; i < cells; i++)
          board[i] == null ? null : TileRef(board[i]!, tiles[board[i]]!.value),
      ];

  // ================= moves =================

  void swipe(SwipeDir dir) {
    if (over || inputLocked || paused || showVictory || showGameOver) return;
    final result = MergeEngine.swipe(_boardRefs(), dir, size: size);
    if (!result.changed) {
      // illegal swipe: no spawn, no score — gentle shake + dull thud (RULES §5)
      invalidShake++;
      sound.playInvalid();
      if (settings.vibration) HapticFeedback.mediumImpact();
      notifyListeners();
      return;
    }

    // one-level undo snapshot (RULES §7)
    _undo = _UndoSnap(values, score);

    // apply: move survivors, mark absorbed tiles for fade-out
    board = List<int?>.filled(cells, null);
    final merged = <int>{};
    final fading = <int>{};
    var topMerge = 0;
    for (final m in result.moves) {
      board[m.toIndex] = m.tileId;
      final t = tiles[m.tileId]!;
      t.row = m.toIndex ~/ size;
      t.col = m.toIndex % size;
      t.value = result.cells[m.toIndex]!.value;
      for (final aid in m.absorbedIds) {
        final a = tiles[aid]!;
        a.row = t.row;
        a.col = t.col;
        a.fading = true;
        fading.add(aid);
      }
      if (m.merged) {
        merged.add(m.tileId);
        if (t.value > topMerge) topMerge = t.value;
      }
    }
    mergedIds = merged;
    fadingIds = fading;
    spawnedId = null;
    animGen++;

    score += result.gained;
    moves++;
    if (settings.bumpBest(score)) newBestThisRun = true;

    sound.playSlide();
    if (merged.isNotEmpty) {
      sound.playMerge(topMerge);
      if (settings.vibration) HapticFeedback.lightImpact();
    }

    inputLocked = true;
    notifyListeners();

    // after the slide animation: purge absorbed, spawn, unlock, evaluate.
    // Generation-guarded so a stale timer can never corrupt a newer run.
    final gen = _gen;
    _lockDeadline =
        DateTime.now().add(const Duration(milliseconds: animMs + 800));
    Timer(const Duration(milliseconds: animMs + 60), () {
      if (gen != _gen) return; // run was reset mid-animation
      _settle(gen);
    });
  }

  /// Settle a completed swipe: purge absorbed tiles, spawn the new biscuit,
  /// unlock input, and evaluate victory/game-over. Idempotent per generation:
  /// only the first call with a matching generation settles.
  void _settle(int gen) {
    if (gen != _gen || !inputLocked) return;
    _gen++; // this generation is now consumed; watchdog won't re-settle
    for (final id in fadingIds) {
      tiles.remove(id);
    }
    fadingIds = {};
    mergedIds = {};
    _spawnRandom();
    sound.playSpawn();
    inputLocked = false;
    _evaluateEndOfTurn();
    _persist();
    notifyListeners();
  }

  void _evaluateEndOfTurn() {
    // victory takes precedence over game over (RULES edge 3)
    final hitWin =
        !victoryShown && maxTileValue >= GameModes.winValue;
    final noMoves = !MergeEngine.movesAvailable(_boardRefs(), size: size);
    if (hitWin) {
      victoryShown = true;
      showVictory = true;
      _pendingGameOver = noMoves;
      sound.playWin();
      if (settings.vibration) HapticFeedback.heavyImpact();
      return;
    }
    if (noMoves) _triggerGameOver();
  }

  void _triggerGameOver() {
    over = true;
    showGameOver = true;
    settings.recordRun(score: score, maxTile: maxTileValue);
    sound.playLose();
    if (settings.vibration) HapticFeedback.heavyImpact();
    settings.clearSavedGame(); // run is finished; nothing to resume
  }

  /// Dismiss the victory dialog and keep baking toward higher biscuits.
  void keepBaking() {
    showVictory = false;
    sound.playTap();
    if (_pendingGameOver) {
      _pendingGameOver = false;
      _triggerGameOver();
    } else {
      _persist();
    }
    notifyListeners();
  }

  // ================= undo =================

  void undo() {
    if (!canUndo) return;
    final snap = _undo!;
    _undo = null;
    _gen++; // cancel any in-flight animation timer
    inputLocked = false;
    tiles.clear();
    _nextId = 1;
    board = List<int?>.filled(cells, null);
    for (var i = 0; i < cells && i < snap.values.length; i++) {
      final v = snap.values[i];
      if (v > 0) {
        final id = _nextId++;
        tiles[id] = BoardTile(id, v, i ~/ size, i % size);
        board[i] = id;
      }
    }
    score = snap.score;
    over = false;
    showGameOver = false;
    victoryShown = false; // RULES edge 4: may fire again on re-merge
    _pendingGameOver = false;
    mergedIds = {};
    fadingIds = {};
    spawnedId = null;
    sound.playTap();
    _persist();
    notifyListeners();
  }

  // ================= pause / persistence =================

  void pauseGame() {
    if (over || paused) return;
    paused = true;
    _persist();
    notifyListeners();
  }

  void resumeGame() {
    paused = false;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (over) return;
    await settings.saveGame({
      'modeId': modeId,
      'values': values,
      'score': score,
      'moves': moves,
      'victoryShown': victoryShown,
      'undo': _undo == null
          ? null
          : {'values': _undo!.values, 'score': _undo!.score},
    });
  }

  /// Restore a saved run. Returns false when the save is invalid.
  bool restore(Map<String, dynamic> data) {
    try {
      _gen++;
      final savedMode = data['modeId'] as String?;
      if (savedMode != null && savedMode != modeId) {
        modeId = savedMode;
      }
      final vals = (data['values'] as List).cast<int>();
      board = List<int?>.filled(cells, null);
      tiles.clear();
      _nextId = 1;
      for (var i = 0; i < cells && i < vals.length; i++) {
        if (vals[i] > 0) {
          final id = _nextId++;
          tiles[id] = BoardTile(id, vals[i], i ~/ size, i % size);
          board[i] = id;
        }
      }
      score = (data['score'] as num).toInt();
      moves = (data['moves'] as num?)?.toInt() ?? 0;
      victoryShown = (data['victoryShown'] as bool?) ?? false;
      final u = data['undo'] as Map<String, dynamic>?;
      _undo = u == null
          ? null
          : _UndoSnap((u['values'] as List).cast<int>(),
              (u['score'] as num).toInt());
      over = false;
      paused = false;
      inputLocked = false;
      showVictory = false;
      showGameOver = false;
      _pendingGameOver = false;
      newBestThisRun = false;
      mergedIds = {};
      fadingIds = {};
      spawnedId = null;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
