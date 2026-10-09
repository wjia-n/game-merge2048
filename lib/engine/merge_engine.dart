import 'dart:math';

/// Pure deterministic 2048 engine — the authoritative implementation of
/// RULES.md §§3–5, 8. No UI, no randomness of its own: callers supply the
/// board and an injectable [Random] so tests and replays are deterministic.
///
/// The board is a list of size*size [TileRef?] (null = empty cell),
/// row-major. Tile ids are opaque to the engine; they let the UI animate
/// tile motion.
class TileRef {
  final int id;
  final int value;
  const TileRef(this.id, this.value);
}

enum SwipeDir { up, down, left, right }

/// One surviving tile after a swipe, for animation + scoring.
class TileMove {
  final int tileId;
  final int fromIndex;
  final int toIndex;
  final bool merged;
  final List<int> absorbedIds; // tiles merged into this one
  const TileMove({
    required this.tileId,
    required this.fromIndex,
    required this.toIndex,
    required this.merged,
    required this.absorbedIds,
  });
}

class SwipeResult {
  final List<TileRef?> cells; // new board, row-major
  final int gained; // score gained by merges
  final List<TileMove> moves; // motion of surviving tiles
  final bool changed; // legal move iff true
  const SwipeResult({
    required this.cells,
    required this.gained,
    required this.moves,
    required this.changed,
  });
}

class MergeEngine {
  /// Resolve a swipe. Classic 2048 resolution (RULES §4):
  /// slide everything to the swipe edge, merge equal pairs from the edge
  /// inward, each tile merges at most once per swipe.
  static SwipeResult swipe(List<TileRef?> board, SwipeDir dir,
      {int size = 4}) {
    assert(board.length == size * size);
    assert(size >= 3 && size <= 8);
    final n = size * size;
    final cells = List<TileRef?>.filled(n, null);
    final moves = <TileMove>[];
    var gained = 0;

    for (var line = 0; line < size; line++) {
      // cell indices ordered from the swipe edge inward
      final idx = <int>[];
      for (var k = 0; k < size; k++) {
        int r, c;
        switch (dir) {
          case SwipeDir.left:
            r = line;
            c = k;
          case SwipeDir.right:
            r = line;
            c = size - 1 - k;
          case SwipeDir.up:
            r = k;
            c = line;
          case SwipeDir.down:
            r = size - 1 - k;
            c = line;
        }
        idx.add(r * size + c);
      }
      final vals = <TileRef>[];
      final src = <int>[]; // source cell index for each tile, edge-inward
      for (final i in idx) {
        final t = board[i];
        if (t != null) {
          vals.add(t);
          src.add(i);
        }
      }
      var w = 0; // write position from edge
      var k = 0;
      while (k < vals.length) {
        final to = idx[w];
        if (k + 1 < vals.length && vals[k].value == vals[k + 1].value) {
          // merge: the survivor keeps the FIRST tile's id and sits at the
          // edge-most slot; the second tile is absorbed. The new tile may
          // not merge again this swipe (RULES §4.3).
          final merged = TileRef(vals[k].id, vals[k].value * 2);
          cells[to] = merged;
          gained += merged.value;
          moves.add(TileMove(
            tileId: merged.id,
            fromIndex: src[k],
            toIndex: to,
            merged: true,
            absorbedIds: [vals[k + 1].id],
          ));
          k += 2;
        } else {
          cells[to] = vals[k];
          moves.add(TileMove(
            tileId: vals[k].id,
            fromIndex: src[k],
            toIndex: to,
            merged: false,
            absorbedIds: const [],
          ));
          k += 1;
        }
        w++;
      }
    }

    var changed = false;
    for (var i = 0; i < n; i++) {
      final a = board[i];
      final b = cells[i];
      if ((a?.id != b?.id) || (a?.value != b?.value)) {
        changed = true;
        break;
      }
    }
    // keep moves only when the board actually changed (legal move)
    return SwipeResult(
      cells: cells,
      gained: gained,
      moves: changed ? moves : const [],
      changed: changed,
    );
  }

  /// True when at least one swipe direction is a legal move (RULES §10).
  static bool movesAvailable(List<TileRef?> board, {int size = 4}) {
    assert(board.length == size * size);
    for (var i = 0; i < board.length; i++) {
      if (board[i] == null) return true;
      final r = i ~/ size, c = i % size;
      if (c < size - 1 && board[i]!.value == board[i + 1]?.value) {
        return true;
      }
      if (r < size - 1 && board[i]!.value == board[i + size]?.value) {
        return true;
      }
    }
    return false;
  }

  /// Index of a uniformly random empty cell, or -1 when the board is full.
  static int spawnIndex(List<TileRef?> board, Random rng) {
    final empty = <int>[];
    for (var i = 0; i < board.length; i++) {
      if (board[i] == null) empty.add(i);
    }
    if (empty.isEmpty) return -1;
    return empty[rng.nextInt(empty.length)];
  }

  /// Spawn value: 2 with 90% probability, 4 with 10% (RULES §2).
  static int spawnValue(Random rng) => rng.nextDouble() < 0.9 ? 2 : 4;

  /// Highest tile value on the board (0 when empty).
  static int maxTile(List<TileRef?> board) {
    var m = 0;
    for (final t in board) {
      if (t != null && t.value > m) m = t.value;
    }
    return m;
  }
}
