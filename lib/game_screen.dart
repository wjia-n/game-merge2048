import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Merge 2048 — swipe to slide & merge. Juicy pops, gradient tiles, best score.
class Merge2048Screen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;
  const Merge2048Screen({super.key, required this.players, required this.callbacks});
  @override
  State<Merge2048Screen> createState() => _Merge2048ScreenState();
}

class _Merge2048ScreenState extends State<Merge2048Screen> {
  final grid = List.filled(16, 0);
  int score = 0, best = 0, animId = 0, spawned = -1;
  Set<int> popped = {};
  bool over = false, cheered2048 = false;
  final rnd = Random();
  Offset? panStart, panCur;

  Player get me => widget.players[0];

  @override
  void initState() {
    super.initState();
    _loadBest();
    _spawn();
    _spawn();
  }

  Future<void> _loadBest() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => best = p.getInt('merge2048_best') ?? 0);
  }

  Future<void> _saveBest() async {
    if (score <= best) return;
    final p = await SharedPreferences.getInstance();
    await p.setInt('merge2048_best', score);
    if (mounted) setState(() => best = score);
  }

  void _newGame() {
    Sfx.click();
    setState(() {
      grid.fillRange(0, 16, 0);
      score = 0;
      me.score = 0;
      over = false;
      cheered2048 = false;
      popped = {};
      spawned = -1;
      animId++;
    });
    widget.callbacks.refreshHud();
    _spawn();
    _spawn();
    setState(() {});
  }

  void _spawn() {
    final empty = [for (var i = 0; i < 16; i++) if (grid[i] == 0) i];
    if (empty.isEmpty) return;
    final i = empty[rnd.nextInt(empty.length)];
    grid[i] = rnd.nextDouble() < 0.9 ? 2 : 4;
    spawned = i;
  }

  void _swipe(int dx, int dy) {
    if (over || (dx == 0 && dy == 0)) return;
    var moved = false, gained = 0;
    final merged = <int>{};
    for (var l = 0; l < 4; l++) {
      final idx = <int>[];
      for (var k = 0; k < 4; k++) {
        int r, c;
        if (dx != 0) {
          r = l;
          c = dx > 0 ? 3 - k : k;
        } else {
          c = l;
          r = dy > 0 ? 3 - k : k;
        }
        idx.add(r * 4 + c);
      }
      final vals = [for (final i in idx) grid[i]].where((v) => v != 0).toList();
      final out = List.filled(4, 0);
      var w = 0, k = 0;
      while (k < vals.length) {
        if (k + 1 < vals.length && vals[k] == vals[k + 1]) {
          out[w] = vals[k] * 2;
          gained += out[w];
          merged.add(idx[w]);
          k += 2;
        } else {
          out[w] = vals[k];
          k += 1;
        }
        w++;
      }
      for (var j = 0; j < 4; j++) {
        if (grid[idx[j]] != out[j]) moved = true;
        grid[idx[j]] = out[j];
      }
    }
    if (!moved) return;
    _spawn();
    setState(() {
      score += gained;
      me.score = score;
      popped = merged;
      animId++;
    });
    widget.callbacks.refreshHud();
    Sfx.move();
    if (!cheered2048 && grid.any((v) => v >= 2048)) {
      cheered2048 = true;
      Sfx.win();
    }
    if (!_movesAvailable()) _finish();
  }

  bool _movesAvailable() {
    for (var i = 0; i < 16; i++) {
      if (grid[i] == 0) return true;
      final r = i ~/ 4, c = i % 4;
      if (c < 3 && grid[i] == grid[i + 1]) return true;
      if (r < 3 && grid[i] == grid[i + 4]) return true;
    }
    return false;
  }

  void _finish() {
    over = true;
    Sfx.lose();
    _saveBest();
    widget.callbacks.finish(
      headline: 'Board jammed at $score! 🧱',
      subline: score >= best && score > 0
          ? 'NEW BEST SCORE! You absolute merge machine! 🏆'
          : 'Best: $best. One more swipe? You know you want to.',
    );
  }

  List<Color> _tileGrad(int v, GameTheme t) {
    if (v == 0) return [t.surface, t.surface];
    final e = (log(v) / ln2).round();
    if (e <= 1) return [t.surface, t.primary.withValues(alpha: 0.25)];
    if (e <= 2) return [t.primary.withValues(alpha: 0.3), t.primary.withValues(alpha: 0.6)];
    if (e <= 4) return [t.primary.withValues(alpha: 0.6), t.primary];
    if (e <= 6) return [t.primary, t.secondary];
    if (e <= 8) return [t.secondary, t.accent];
    return [t.accent, t.primary];
  }

  @override
  Widget build(BuildContext context) {
    final t = ThemeController.of(context).theme;
    final onTile = t.dark ? Colors.black : Colors.white;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          _scoreBox(t, 'SCORE', '$score'),
          if (cheered2048)
            Text('👑 2048!', style: TextStyle(color: t.accent, fontWeight: FontWeight.w900, fontSize: 16)),
          _scoreBox(t, 'BEST', '$best'),
        ]),
        const SizedBox(height: 12),
        Expanded(
          child: Center(
            child: AspectRatio(
              aspectRatio: 1,
              child: GestureDetector(
                onPanStart: (d) => panStart = d.localPosition,
                onPanUpdate: (d) => panCur = d.localPosition,
                onPanEnd: (_) {
                  if (panStart == null || panCur == null) return;
                  final dx = panCur!.dx - panStart!.dx, dy = panCur!.dy - panStart!.dy;
                  panStart = panCur = null;
                  if (dx.abs() < 14 && dy.abs() < 14) return;
                  if (dx.abs() > dy.abs()) {
                    _swipe(dx > 0 ? 1 : -1, 0);
                  } else {
                    _swipe(0, dy > 0 ? 1 : -1);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: t.surface, borderRadius: t.radius),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4, mainAxisSpacing: 8, crossAxisSpacing: 8),
                    itemCount: 16,
                    itemBuilder: (_, i) => _tile(i, t, onTile),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          WajihaButton(label: 'New Game', emoji: '🔄', onTap: _newGame),
        ]),
        const SizedBox(height: 6),
        Text('Swipe to slide. Matching tiles merge & double! ⚡',
            style: TextStyle(color: t.muted, fontSize: 12)),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _scoreBox(GameTheme t, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(gradient: t.headerGradient, borderRadius: t.radius),
      child: Column(children: [
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      ]),
    );
  }

  Widget _tile(int i, GameTheme t, Color onTile) {
    final v = grid[i];
    final pop = popped.contains(i) || i == spawned;
    final grad = _tileGrad(v, t);
    final strong = v >= 8;
    return TweenAnimationBuilder<double>(
      key: ValueKey('$animId-$i'),
      tween: Tween(begin: pop ? 0.4 : 1.0, end: 1.0),
      duration: const Duration(milliseconds: 240),
      curve: Curves.elasticOut,
      builder: (_, s, child) => Transform.scale(
        scale: s,
        child: Container(
          decoration: BoxDecoration(
            gradient: v == 0 ? null : LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
            color: v == 0 ? t.background.withValues(alpha: 0.6) : null,
            borderRadius: BorderRadius.circular(12),
            boxShadow: strong ? [BoxShadow(color: grad[1].withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 3))] : null,
          ),
          alignment: Alignment.center,
          child: v == 0
              ? const SizedBox.shrink()
              : Text('$v',
                  style: TextStyle(
                      color: strong ? onTile : t.text,
                      fontSize: v >= 1000 ? 20 : v >= 100 ? 24 : 30,
                      fontWeight: FontWeight.w900)),
        ),
      ),
    );
  }
}
