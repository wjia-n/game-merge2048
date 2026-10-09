import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../state/game.dart';
import '../theme.dart';
import '../theme/bakery_themes.dart';
import '../widgets/bakery.dart';

/// Victory dialog: oak bakery sign, hero 2048 biscuit on a pedestal,
/// score/best plaques with a baked-star "new best" stamp, and a
/// flour-burst celebration.
class VictoryDialog extends StatelessWidget {
  final Merge2048Game game;
  final SoundService sound;
  final BakeryThemeDef theme;
  final VoidCallback onKeepBaking;
  final VoidCallback onNewBatch;

  const VictoryDialog({
    super.key,
    required this.game,
    required this.sound,
    required this.theme,
    required this.onKeepBaking,
    required this.onNewBatch,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return DialogBackdrop(
      child: Stack(
        children: [
          const Positioned.fill(child: _CelebrationBurst()),
          OakDialog(
            theme: t,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _DialogPop(
                  child: _Headline(
                      text: 'YOU BAKED THE 2048!',
                      fontSize: 26,
                      theme: t),
                ),
                const SizedBox(height: 4),
                Text('golden, crisp, legendary 🏆',
                    style: Merge2048Theme.label(13, color: t.creamDim)),
                const SizedBox(height: 14),
                // hero biscuit on a wooden pedestal
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeroBiscuit(theme: t),
                    Container(
                      width: 150,
                      height: 12,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF4D3823),
                            Color(0xFF2A1D13)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: t.buttonBase, width: 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    HangingPlaque(
                        label: 'SCORE',
                        value: formatScore(game.score),
                        theme: t),
                    HangingPlaque(
                      label: 'BEST',
                      value: formatScore(game.settings.best),
                      star: game.newBestThisRun,
                      theme: t,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                WoodButton(
                  label: 'KEEP BAKING',
                  icon: Icons.local_fire_department_rounded,
                  width: double.infinity,
                  theme: t,
                  onTap: onKeepBaking,
                ),
                const SizedBox(height: 10),
                WoodButton(
                  label: 'NEW BATCH',
                  primary: false,
                  width: double.infinity,
                  theme: t,
                  onTap: onNewBatch,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  final String text;
  final double fontSize;
  final BakeryThemeDef theme;
  const _Headline(
      {required this.text, required this.fontSize, required this.theme});

  @override
  Widget build(BuildContext context) => Text(text,
      textAlign: TextAlign.center,
      style: Merge2048Theme.display(fontSize)
          .copyWith(color: theme.primary));
}

/// Pop-in wrapper for dialog content: scale 0.7 -> 1 with a spring.
class _DialogPop extends StatefulWidget {
  final Widget child;
  const _DialogPop({required this.child});

  @override
  State<_DialogPop> createState() => _DialogPopState();
}

class _DialogPopState extends State<_DialogPop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _scale = Tween(begin: 0.7, end: 1.0)
        .chain(CurveTween(curve: Curves.elasticOut))
        .animate(_ctrl);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
      scale: _scale, child: widget.child);
}

/// Hero 2048 biscuit with a gentle celebratory bob.
class _HeroBiscuit extends StatefulWidget {
  final BakeryThemeDef theme;
  const _HeroBiscuit({required this.theme});

  @override
  State<_HeroBiscuit> createState() => _HeroBiscuitState();
}

class _HeroBiscuitState extends State<_HeroBiscuit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => Transform.translate(
        offset: Offset(0, -6 * sin(_ctrl.value * pi)),
        child: BiscuitTile(
          value: 2048,
          size: MediaQuery.of(context).size.width * 0.32,
          theme: widget.theme,
        ),
      ),
    );
  }
}

/// Flour-burst celebration: golden motes drifting up behind the dialog.
class _CelebrationBurst extends StatefulWidget {
  const _CelebrationBurst();

  @override
  State<_CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<_CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _rnd = Random(2048);
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();
    _sparks = List.generate(
      46,
      (_) => _Spark(
        x: _rnd.nextDouble(),
        y: 0.35 + _rnd.nextDouble() * 0.5,
        r: 2 + _rnd.nextDouble() * 4,
        vy: 0.12 + _rnd.nextDouble() * 0.25,
        sway: _rnd.nextDouble() * 2 * pi,
        alpha: 0.35 + _rnd.nextDouble() * 0.4,
      ),
    );
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) =>
          CustomPaint(painter: _SparkPainter(_sparks, _ctrl.value)),
    );
  }
}

class _Spark {
  final double x, y, r, vy, sway, alpha;
  _Spark(
      {required this.x,
      required this.y,
      required this.r,
      required this.vy,
      required this.sway,
      required this.alpha});
}

class _SparkPainter extends CustomPainter {
  final List<_Spark> sparks;
  final double t;
  _SparkPainter(this.sparks, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in sparks) {
      final y = (((s.y - t * s.vy) % 1.0) + 1.0) % 1.0;
      final x = (s.x + sin(t * 2 * pi * 2 + s.sway) * 0.03 + 1.0) % 1.0;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        s.r,
        Paint()..color = Color.fromRGBO(245, 166, 35, s.alpha * (1 - t * 0.35)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparkPainter oldDelegate) =>
      oldDelegate.t != t;
}

/// Game-over dialog: same oak frame, "OUT OF MOVES" headline, final score,
/// run-history note.
class GameOverDialog extends StatelessWidget {
  final Merge2048Game game;
  final SoundService sound;
  final BakeryThemeDef theme;
  final VoidCallback onNewBatch;
  final VoidCallback onMenu;

  const GameOverDialog({
    super.key,
    required this.game,
    required this.sound,
    required this.theme,
    required this.onNewBatch,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return DialogBackdrop(
      child: OakDialog(
        theme: t,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DialogPop(
              child: _Headline(
                  text: 'OUT OF MOVES', fontSize: 26, theme: t),
            ),
            const SizedBox(height: 4),
            Text('The tray is full — no more merges. 🧱',
                textAlign: TextAlign.center,
                style: Merge2048Theme.label(13, color: t.creamDim)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                HangingPlaque(
                    label: 'SCORE',
                    value: formatScore(game.score),
                    theme: t),
                HangingPlaque(
                  label: 'BEST',
                  value: formatScore(game.settings.best),
                  star: game.newBestThisRun,
                  theme: t,
                ),
              ],
            ),
            const SizedBox(height: 20),
            WoodButton(
              label: 'NEW BATCH',
              icon: Icons.refresh_rounded,
              width: double.infinity,
              theme: t,
              onTap: onNewBatch,
            ),
            if (game.canUndo) ...[
              const SizedBox(height: 10),
              WoodButton(
                label: 'UNDO LAST MOVE',
                primary: false,
                width: double.infinity,
                theme: t,
                onTap: () => game.undo(),
              ),
            ],
            const SizedBox(height: 10),
            WoodButton(
              label: 'MENU',
              primary: false,
              width: double.infinity,
              theme: t,
              onTap: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}
