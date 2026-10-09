import 'dart:math';

import 'package:flutter/material.dart';

import '../state/game.dart';
import '../theme/bakery_themes.dart';
import 'bakery.dart';

/// The baking tray: theme-colored with a raised rim, flour dusting,
/// sunken flour wells for empty cells, and animated wooden biscuit tiles.
///
/// Tiles slide with AnimatedPositioned (keyed by stable tile id); merges
/// pop, spawns scale in, absorbed tiles shrink away. Board dimension comes
/// from the active game mode (4/5/6).
class WalnutTray extends StatelessWidget {
  final Merge2048Game game;
  final BakeryThemeDef theme;
  final TileStyleDef tileStyle;
  final TrayAccentDef accent;
  const WalnutTray({
    super.key,
    required this.game,
    required this.theme,
    required this.tileStyle,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final size = game.size;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final traySize = min(constraints.maxWidth, constraints.maxHeight);
        const rim = 10.0;
        const gap = 8.0;
        final inner = traySize - rim * 2;
        final cell = (inner - gap * (size + 1)) / size;
        final pad = rim + gap;

        Offset pos(int r, int c) =>
            Offset(pad + c * (cell + gap), pad + r * (cell + gap));

        return Container(
          width: traySize,
          height: traySize,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.panelHigh, theme.tray],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.rim, width: 3),
            boxShadow: [
              const BoxShadow(
                  color: Color(0x99000000),
                  blurRadius: 18,
                  offset: Offset(0, 9)),
              BoxShadow(
                  color: accent.rimLight.withValues(alpha: 0.25),
                  blurRadius: 2,
                  offset: const Offset(0, -2),
                  spreadRadius: -1),
            ],
          ),
          child: Stack(
            children: [
              // flour dusting on the tray
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: CustomPaint(painter: _TrayFlourPainter()),
                ),
              ),
              // sunken flour wells
              for (var i = 0; i < size * size; i++)
                Positioned(
                  left: pos(i ~/ size, i % size).dx,
                  top: pos(i ~/ size, i % size).dy,
                  child: _FlourWell(
                      size: cell, theme: theme, accent: accent),
                ),
              // biscuit tiles
              for (final tile in game.tiles.values)
                _AnimatedBiscuit(
                  key: ValueKey(tile.id),
                  tile: tile,
                  pos: pos(tile.row, tile.col),
                  size: cell,
                  game: game,
                  theme: theme,
                  tileStyle: tileStyle,
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Sunken flour-dusted well (empty cell): inner shadow + bottom lip rim.
class _FlourWell extends StatelessWidget {
  final double size;
  final BakeryThemeDef theme;
  final TrayAccentDef accent;
  const _FlourWell(
      {required this.size, required this.theme, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            accent.wellDark.withValues(alpha: 0.8),
            theme.deepest.withValues(alpha: 0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.16),
        border: Border(
          bottom: BorderSide(
              color: theme.outline.withValues(alpha: 0.25), width: 1.5),
        ),
      ),
    );
  }
}

class _AnimatedBiscuit extends StatelessWidget {
  final BoardTile tile;
  final Offset pos;
  final double size;
  final Merge2048Game game;
  final BakeryThemeDef theme;
  final TileStyleDef tileStyle;
  const _AnimatedBiscuit({
    super.key,
    required this.tile,
    required this.pos,
    required this.size,
    required this.game,
    required this.theme,
    required this.tileStyle,
  });

  @override
  Widget build(BuildContext context) {
    final biscuit =
        BiscuitTile(value: tile.value, size: size, theme: theme, style: tileStyle);

    Widget wrapped = biscuit;
    if (game.mergedIds.contains(tile.id)) {
      // merge pop: 1 -> 1.22 -> 1, replays per swipe via animGen key
      wrapped = _PopScale(
          key: ValueKey('pop-${game.animGen}-${tile.id}'), child: biscuit);
    } else if (tile.id == game.spawnedId) {
      wrapped = TweenAnimationBuilder<double>(
        key: ValueKey('spawn-${game.animGen}-${tile.id}'),
        tween: Tween(begin: 0.3, end: 1.0),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        builder: (_, s, child) => Transform.scale(scale: s, child: child),
        child: biscuit,
      );
    } else if (tile.fading) {
      wrapped = TweenAnimationBuilder<double>(
        key: ValueKey('fade-${game.animGen}-${tile.id}'),
        tween: Tween(begin: 1.0, end: 0.0),
        duration: Duration(milliseconds: Merge2048Game.animMs + 40),
        curve: Curves.easeIn,
        builder: (_, s, child) => Opacity(
            opacity: s,
            child: Transform.scale(scale: 0.6 + 0.4 * s, child: child)),
        child: biscuit,
      );
    }

    return AnimatedPositioned(
      duration: Duration(milliseconds: Merge2048Game.animMs),
      curve: Curves.easeOutCubic,
      left: pos.dx,
      top: pos.dy,
      child: SizedBox(width: size, height: size, child: wrapped),
    );
  }
}

/// Merge pop: quick 1 -> 1.22 -> 1 bounce communicating weight.
class _PopScale extends StatefulWidget {
  final Widget child;
  const _PopScale({super.key, required this.child});

  @override
  State<_PopScale> createState() => _PopScaleState();
}

class _PopScaleState extends State<_PopScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 260));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.22), weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 1.22, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOutBack)),
          weight: 65),
    ]).animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (_, child) =>
          Transform.scale(scale: _scale.value, child: child),
      child: widget.child,
    );
  }
}

class _TrayFlourPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(4242);
    final paint = Paint()..color = const Color(0x14F8DDCD);
    for (var i = 0; i < 130; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width,
            rnd.nextDouble() * size.height),
        0.5 + rnd.nextDouble() * 1.4,
        paint,
      );
    }
    // a few flour smudges
    final smudge = Paint()..color = const Color(0x0AF8DDCD);
    for (var i = 0; i < 8; i++) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(rnd.nextDouble() * size.width,
              rnd.nextDouble() * size.height),
          width: 20 + rnd.nextDouble() * 30,
          height: 8 + rnd.nextDouble() * 10,
        ),
        smudge,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
