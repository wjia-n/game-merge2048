import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../audio/sound.dart';
import '../engine/merge_engine.dart';
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
  final List<int> values; // 16 values, row-major
  final int score;
  _UndoSnap(this.values, this.score);
}

/// Full Merge 2048 session: rules state, animation sequencing, scoring,
/// undo, victory/game-over flow, save/resume. The board painter and screens
/// only read; all mutation goes through here.
class Merge2048Game extends ChangeNotifier {
  final Merge2048Settings settings;
  final SoundService sound;
  final Random _rng;

  Merge2048Game({
    required this.settings,
    required this.sound,
    Random? rng,
  }) : _rng = rng ?? Random();

  // ---- live state ----
  final Map<int, BoardTile> tiles = {};
  final List<int?> cells = List<int?>.filled(16, null); // cell -> tile id
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

  bool get canUndo =>
      settings.undoOn &&
      _undo != null &&
      !inputLocked &&
      !paused &&
      !showVictory;

  List<int> get values =>
      [for (var i = 0; i < 16; i++) cells[i] == null ? 0 : tiles[cells[i]]!.value];

  // ================= setup =================

  void newGame() {
    _gen++;
    tiles.clear();
    cells.fillRange(0, 16, null);
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
    final board = _boardRefs();
    final idx = MergeEngine.spawnIndex(board, _rng);
    if (idx < 0) return;
    final id = _nextId++;
    final value = MergeEngine.spawnValue(_rng);
    tiles[id] = BoardTile(id, value, idx ~/ 4, idx % 4);
    cells[idx] = id;
    if (!silent) spawnedId = id;
  }

  List<TileRef?> _boardRefs() => [
        for (var i = 0; i < 16; i++)
          cells[i] == null ? null : TileRef(cells[i]!, tiles[cells[i]]!.value),
      ];

  // ================= moves =================

  void swipe(SwipeDir dir) {
    if (over || inputLocked || paused || showVictory || showGameOver) return;
    final result = MergeEngine.swipe(_boardRefs(), dir);
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
    cells.fillRange(0, 16, null);
    final merged = <int>{};
    final fading = <int>{};
    var topMerge = 0;
    for (final m in result.moves) {
      cells[m.toIndex] = m.tileId;
      final t = tiles[m.tileId]!;
      t.row = m.toIndex ~/ 4;
      t.col = m.toIndex % 4;
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

    // after the slide animation: purge absorbed, spawn, unlock, evaluate
    final gen = _gen;
    Timer(const Duration(milliseconds: animMs + 60), () {
      if (gen != _gen) return; // run was reset mid-animation
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
    });
  }

  void _evaluateEndOfTurn() {
    // victory takes precedence over game over (RULES edge 3)
    final hit2048 =
        !victoryShown && tiles.values.any((t) => t.value >= 2048);
    final noMoves = !MergeEngine.movesAvailable(_boardRefs());
    if (hit2048) {
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
    sound.playLose();
    if (settings.vibration) HapticFeedback.heavyImpact();
    settings.clearSavedGame(); // run is finished; nothing to resume
  }

  /// Dismiss the victory dialog and keep baking toward 4096+.
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
    tiles.clear();
    _nextId = 1;
    for (var i = 0; i < 16; i++) {
      final v = snap.values[i];
      if (v > 0) {
        final id = _nextId++;
        tiles[id] = BoardTile(id, v, i ~/ 4, i % 4);
        cells[i] = id;
      } else {
        cells[i] = null;
      }
    }
    score = snap.score;
    over = false;
    showGameOver = false;
    victoryShown = false; // RULES edge 4: may fire again on re-merge
    _pendingGameOver = false;
    inputLocked = false;
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
      final vals = (data['values'] as List).cast<int>();
      if (vals.length != 16) return false;
      tiles.clear();
      _nextId = 1;
      for (var i = 0; i < 16; i++) {
        if (vals[i] > 0) {
          final id = _nextId++;
          tiles[id] = BoardTile(id, vals[i], i ~/ 4, i % 4);
          cells[i] = id;
        } else {
          cells[i] = null;
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
