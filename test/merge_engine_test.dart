import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:merge2048/engine/merge_engine.dart';

/// RULES.md §13 test cases against the deterministic engine.
List<TileRef?> board(List<int> values) {
  assert(values.length == 16);
  return [
    for (var i = 0; i < 16; i++)
      values[i] == 0 ? null : TileRef(i + 1, values[i]),
  ];
}

List<int> valuesOf(List<TileRef?> cells) =>
    [for (final c in cells) c?.value ?? 0];

void main() {
  group('MergeEngine swipes (RULES §4)', () {
    test('1: slide left, no merge', () {
      final b = board([2, 0, 4, 0, ...List.filled(12, 0)]);
      final r = MergeEngine.swipe(b, SwipeDir.left);
      expect(r.changed, true);
      expect(r.gained, 0);
      expect(valuesOf(r.cells).sublist(0, 4), [2, 4, 0, 0]);
    });

    test('2: single merge', () {
      final b = board([2, 2, 0, 0, ...List.filled(12, 0)]);
      final r = MergeEngine.swipe(b, SwipeDir.left);
      expect(r.changed, true);
      expect(r.gained, 4);
      expect(valuesOf(r.cells).sublist(0, 4), [4, 0, 0, 0]);
    });

    test('3: double pair merge', () {
      final b = board([2, 2, 4, 4, ...List.filled(12, 0)]);
      final r = MergeEngine.swipe(b, SwipeDir.left);
      expect(r.gained, 12);
      expect(valuesOf(r.cells).sublist(0, 4), [4, 8, 0, 0]);
    });

    test('4: no chain merge', () {
      final b = board([2, 2, 2, 2, ...List.filled(12, 0)]);
      final r = MergeEngine.swipe(b, SwipeDir.left);
      expect(r.gained, 8);
      expect(valuesOf(r.cells).sublist(0, 4), [4, 4, 0, 0]);
    });

    test('5: merge-once rule', () {
      final b = board([4, 4, 8, 0, ...List.filled(12, 0)]);
      final r = MergeEngine.swipe(b, SwipeDir.left);
      // NOTE: RULES §13 table prints "score +16" here, but that contradicts
      // the authoritative scoring rule §8 ("merging two 4s creates an 8 ->
      // +8 points"). One merge happens -> +8. Flagged in the build report.
      expect(r.gained, 8);
      expect(valuesOf(r.cells).sublist(0, 4), [8, 8, 0, 0]);
    });

    test('6: gap slide + merge', () {
      final b = board([2, 0, 2, 4, ...List.filled(12, 0)]);
      final r = MergeEngine.swipe(b, SwipeDir.left);
      expect(r.gained, 4);
      expect(valuesOf(r.cells).sublist(0, 4), [4, 4, 0, 0]);
    });

    test('7: illegal move changes nothing', () {
      final b = board([2, 4, 8, 16, ...List.filled(12, 0)]);
      final r = MergeEngine.swipe(b, SwipeDir.left);
      expect(r.changed, false);
      expect(r.gained, 0);
    });

    test('8: vertical merge swipes up', () {
      final b = board([
        2, 0, 0, 0,
        2, 0, 0, 0,
        4, 0, 0, 0,
        0, 0, 0, 0,
      ]);
      final r = MergeEngine.swipe(b, SwipeDir.up);
      expect(r.changed, true);
      // NOTE: RULES §13 table prints "score +8" here, but per the
      // authoritative scoring rule §8 only one merge occurs (2+2 -> 4 -> +4).
      // Flagged in the build report.
      expect(r.gained, 4);
      expect(valuesOf(r.cells).sublist(0, 4), [4, 0, 0, 0]);
      expect(valuesOf(r.cells).sublist(4, 8), [4, 0, 0, 0]);
    });

    test('swipe right resolves from the right edge', () {
      final b = board([2, 2, 4, 4, ...List.filled(12, 0)]);
      final r = MergeEngine.swipe(b, SwipeDir.right);
      expect(r.gained, 12);
      expect(valuesOf(r.cells).sublist(0, 4), [0, 0, 4, 8]);
    });

    test('swipe down resolves from the bottom edge', () {
      final b = board([
        2, 0, 0, 0,
        2, 0, 0, 0,
        0, 0, 0, 0,
        0, 0, 0, 0,
      ]);
      final r = MergeEngine.swipe(b, SwipeDir.down);
      expect(r.gained, 4);
      final v = valuesOf(r.cells);
      expect([v[0], v[4], v[8], v[12]], [0, 0, 0, 4]);
    });

    test('moves record absorbed tiles for animation', () {
      final b = board([2, 2, 0, 0, ...List.filled(12, 0)]);
      final r = MergeEngine.swipe(b, SwipeDir.left);
      final merged = r.moves.where((m) => m.merged).toList();
      expect(merged.length, 1);
      expect(merged.single.absorbedIds.length, 1);
      expect(merged.single.toIndex, 0);
    });
  });

  group('spawns (RULES §2)', () {
    test('9: spawn distribution ~90% twos', () {
      final rng = Random(12345);
      var twos = 0;
      const n = 2000;
      for (var i = 0; i < n; i++) {
        if (MergeEngine.spawnValue(rng) == 2) twos++;
      }
      final pct = twos / n;
      expect(pct, greaterThan(0.87));
      expect(pct, lessThan(0.93));
    });

    test('10: spawn lands in the only empty cell', () {
      final rng = Random(7);
      final b = board(List.filled(15, 2) + [0]);
      expect(MergeEngine.spawnIndex(b, rng), 15);
    });

    test('spawn on full board returns -1', () {
      final b = board(List.filled(16, 2));
      expect(MergeEngine.spawnIndex(b, Random(1)), -1);
    });
  });

  group('game-over detection (RULES §10)', () {
    test('13: full board, no adjacent equals -> no moves', () {
      final b = board([
        2, 4, 2, 4,
        4, 2, 4, 2,
        2, 4, 2, 4,
        4, 2, 4, 2,
      ]);
      expect(MergeEngine.movesAvailable(b), false);
      for (final d in SwipeDir.values) {
        expect(MergeEngine.swipe(b, d).changed, false);
      }
    });

    test('14: full board with one equal pair -> move available', () {
      final b = board([
        2, 2, 4, 8,
        16, 32, 64, 128,
        256, 512, 1024, 2048,
        4096, 8192, 16384, 32768,
      ]);
      expect(MergeEngine.movesAvailable(b), true);
      final r = MergeEngine.swipe(b, SwipeDir.left);
      expect(r.changed, true);
      expect(valuesOf(r.cells).sublist(0, 4), [4, 4, 8, 0]);
    });

    test('empty cell means moves available', () {
      final b = board(List.filled(16, 0)..[5] = 2);
      expect(MergeEngine.movesAvailable(b), true);
    });
  });

  group('board sizes (5x5 / 6x6 modes)', () {
    List<TileRef?> boardN(List<int> values, int size) {
      assert(values.length == size * size);
      return [
        for (var i = 0; i < values.length; i++)
          values[i] == 0 ? null : TileRef(i + 1, values[i]),
      ];
    }

    test('5x5: row merge resolves across 5 cells', () {
      final b = boardN([2, 2, 2, 2, 2, ...List.filled(20, 0)], 5);
      final r = MergeEngine.swipe(b, SwipeDir.left, size: 5);
      expect(r.changed, true);
      expect(r.gained, 8);
      expect(valuesOf(r.cells).sublist(0, 5), [4, 4, 2, 0, 0]);
    });

    test('5x5: swipe right packs to the right edge', () {
      final b = boardN([2, 2, 4, 4, 0, ...List.filled(20, 0)], 5);
      final r = MergeEngine.swipe(b, SwipeDir.right, size: 5);
      expect(r.gained, 12);
      expect(valuesOf(r.cells).sublist(0, 5), [0, 0, 0, 4, 8]);
    });

    test('6x6: vertical merge top-aligned', () {
      final vals = List<int>.filled(36, 0);
      vals[0] = 4;
      vals[6] = 4;
      vals[12] = 8;
      final b = boardN(vals, 6);
      final r = MergeEngine.swipe(b, SwipeDir.up, size: 6);
      expect(r.changed, true);
      expect(r.gained, 8);
      final v = valuesOf(r.cells);
      expect([v[0], v[6], v[12]], [8, 8, 0]);
    });

    test('6x6: full checkerboard -> no moves', () {
      final vals = [
        for (var i = 0; i < 36; i++) (i + i ~/ 6) % 2 == 0 ? 2 : 4,
      ];
      final b = boardN(vals, 6);
      expect(MergeEngine.movesAvailable(b, size: 6), false);
      for (final d in SwipeDir.values) {
        expect(MergeEngine.swipe(b, d, size: 6).changed, false);
      }
    });

    test('6x6: one empty cell -> moves available + spawn lands there', () {
      final vals = [
        for (var i = 0; i < 35; i++) (i + i ~/ 6) % 2 == 0 ? 2 : 4,
        0,
      ];
      final b = boardN(vals, 6);
      expect(MergeEngine.movesAvailable(b, size: 6), true);
      expect(MergeEngine.spawnIndex(b, Random(3)), 35);
    });

    test('5x5: merge-once rule on longer rows', () {
      final b = boardN(
          [4, 4, 8, 8, 16, ...List.filled(20, 0)], 5);
      final r = MergeEngine.swipe(b, SwipeDir.left, size: 5);
      expect(r.gained, 8 + 16);
      expect(valuesOf(r.cells).sublist(0, 5), [8, 16, 16, 0, 0]);
    });

    test('maxTile reports the largest biscuit', () {
      final b = boardN([2, 2048, 0, 0, ...List.filled(21, 0)], 5);
      expect(MergeEngine.maxTile(b), 2048);
    });
  });

  group('determinism (RULES §13.20)', () {
    test('fixed seed, scripted swipes -> identical results', () {
      List<int> run(int seed) {
        final rng = Random(seed);
        var b = board(List.filled(16, 0));
        var gained = 0;
        for (final d in [
          SwipeDir.left,
          SwipeDir.up,
          SwipeDir.right,
          SwipeDir.down
        ]) {
          // seed two tiles
          for (var s = 0; s < 2; s++) {
            final idx = MergeEngine.spawnIndex(b, rng);
            b[idx] = TileRef(idx + 1000 + s, MergeEngine.spawnValue(rng));
          }
          final r = MergeEngine.swipe(b, d);
          b = r.cells;
          gained += r.gained;
        }
        return [...valuesOf(b), gained];
      }

      expect(run(42), run(42));
      expect(run(42), isNot(equals(run(43))));
    });
  });
}
