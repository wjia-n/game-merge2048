import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../engine/merge_engine.dart';
import '../state/game.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../theme/bakery_themes.dart';
import '../widgets/bakery.dart';
import '../widgets/tray.dart';
import 'game_over_screen.dart';

/// Gameplay: hearth console (logo, score/best plaques with tick-up,
/// undo + new-batch + pause), the themed baking tray, hint strip.
/// Victory / game-over / pause appear as oak dialogs over the dimmed board.
class GameScreen extends StatefulWidget {
  final Merge2048Game game;
  final Merge2048Settings settings;
  final SoundService sound;
  final VoidCallback onOpenSettings;
  final VoidCallback onQuitToMenu;

  const GameScreen({
    super.key,
    required this.game,
    required this.settings,
    required this.sound,
    required this.onOpenSettings,
    required this.onQuitToMenu,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Offset? _panStart, _panCur;
  bool _pauseOpen = false;

  Merge2048Game get game => widget.game;

  BakeryThemeDef get theme => BakeryThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);
  TileStyleDef get tileStyle =>
      TileStyles.byId(widget.settings.tileStyleId);
  TrayAccentDef get trayAccent =>
      TrayAccents.byId(widget.settings.trayAccentId);

  void _onPanEnd() {
    final s = _panStart, c = _panCur;
    _panStart = _panCur = null;
    if (s == null || c == null || _pauseOpen) return;
    final dx = c.dx - s.dx, dy = c.dy - s.dy;
    if (dx.abs() < 16 && dy.abs() < 16) return;
    if (dx.abs() > dy.abs()) {
      game.swipe(dx > 0 ? SwipeDir.right : SwipeDir.left);
    } else {
      game.swipe(dy > 0 ? SwipeDir.down : SwipeDir.up);
    }
  }

  void _openPause() {
    widget.sound.playTap();
    game.pauseGame();
    setState(() => _pauseOpen = true);
  }

  void _closePause() {
    widget.sound.playTap();
    setState(() => _pauseOpen = false);
    game.resumeGame();
  }

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return ListenableBuilder(
      listenable: game,
      builder: (ctx, _) => Scaffold(
        backgroundColor: t.background,
        body: FlourDustBackground(
          theme: t,
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _topBar(t),
                    _plaques(t),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _ShakeWrapper(
                              shake: game.invalidShake,
                              child: GestureDetector(
                                onPanStart: (d) =>
                                    _panStart = d.localPosition,
                                onPanUpdate: (d) =>
                                    _panCur = d.localPosition,
                                onPanEnd: (_) => _onPanEnd(),
                                child: WalnutTray(
                                  game: game,
                                  theme: t,
                                  tileStyle: tileStyle,
                                  accent: trayAccent,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    HintStrip(
                        theme: t,
                        text:
                            'Swipe to slide & merge equal biscuits 🍪'),
                    const SizedBox(height: 14),
                  ],
                ),
                if (game.showVictory)
                  VictoryDialog(
                    game: game,
                    sound: widget.sound,
                    theme: t,
                    onKeepBaking: () => game.keepBaking(),
                    onNewBatch: () => game.newGame(),
                  ),
                if (game.showGameOver)
                  GameOverDialog(
                    game: game,
                    sound: widget.sound,
                    theme: t,
                    onNewBatch: () => game.newGame(),
                    onMenu: widget.onQuitToMenu,
                  ),
                if (_pauseOpen) _pauseDialog(t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar(BakeryThemeDef t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          WoodIconButton(
            icon: Icons.pause_rounded,
            size: 44,
            theme: t,
            onTap: _openPause,
          ),
          const SizedBox(width: 10),
          Text('MERGE 2048',
              style: Merge2048Theme.display(17)
                  .copyWith(color: t.primary)),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: t.panel,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: t.outline.withValues(alpha: 0.35)),
            ),
            child: Text(
                GameModes.byId(game.modeId).name.toUpperCase(),
                style: Merge2048Theme.labelCaps(9)
                    .copyWith(color: t.creamDim)),
          ),
          const Spacer(),
          if (widget.settings.undoOn)
            WoodIconButton(
              icon: Icons.undo_rounded,
              size: 44,
              theme: t,
              onTap: game.canUndo ? () => game.undo() : null,
            ),
          if (widget.settings.undoOn) const SizedBox(width: 8),
          WoodIconButton(
            icon: Icons.refresh_rounded,
            size: 44,
            theme: t,
            onTap: () => _confirmNewBatch(t),
          ),
        ],
      ),
    );
  }

  Widget _plaques(BakeryThemeDef t) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _TickPlaque(
              label: 'SCORE', value: game.score, theme: t),
          HangingPlaque(
            label: 'BEST',
            value: formatScore(widget.settings.best),
            star: game.newBestThisRun,
            theme: t,
          ),
        ],
      ),
    );
  }

  void _confirmNewBatch(BakeryThemeDef t) {
    widget.sound.playTap();
    showDialog(
      context: context,
      builder: (ctx) => DialogBackdrop(
        child: OakDialog(
          maxWidth: 300,
          theme: t,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Start a fresh batch?',
                  textAlign: TextAlign.center,
                  style: Merge2048Theme.display(20)
                      .copyWith(color: t.primary)),
              const SizedBox(height: 8),
              Text(
                  'Your current tray and score will be tossed in the bin.',
                  textAlign: TextAlign.center,
                  style: Merge2048Theme.label(13, color: t.creamDim)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: WoodButton(
                      label: 'KEEP',
                      primary: false,
                      fontSize: 14,
                      theme: t,
                      onTap: () {
                        widget.sound.playTap();
                        Navigator.of(ctx).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: WoodButton(
                      label: 'NEW BATCH',
                      fontSize: 14,
                      theme: t,
                      onTap: () {
                        Navigator.of(ctx).pop();
                        game.newGame();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pauseDialog(BakeryThemeDef t) {
    return DialogBackdrop(
      child: OakDialog(
        maxWidth: 300,
        theme: t,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WoodSign(title: 'PAUSED', fontSize: 22, theme: t),
            const SizedBox(height: 8),
            Text('The oven is holding warm. 🔥',
                style: Merge2048Theme.label(13, color: t.creamDim)),
            const SizedBox(height: 18),
            WoodButton(
              label: 'RESUME',
              icon: Icons.play_arrow_rounded,
              width: double.infinity,
              theme: t,
              onTap: _closePause,
            ),
            const SizedBox(height: 10),
            WoodButton(
              label: 'RESTART',
              primary: false,
              width: double.infinity,
              theme: t,
              onTap: () {
                setState(() => _pauseOpen = false);
                game.resumeGame();
                game.newGame();
              },
            ),
            const SizedBox(height: 10),
            WoodButton(
              label: 'SETTINGS',
              primary: false,
              width: double.infinity,
              theme: t,
              onTap: () {
                widget.sound.playTap();
                widget.onOpenSettings();
              },
            ),
            const SizedBox(height: 10),
            WoodButton(
              label: 'QUIT TO MENU',
              primary: false,
              width: double.infinity,
              theme: t,
              onTap: () {
                setState(() => _pauseOpen = false);
                widget.onQuitToMenu();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Score plaque with a buttery tick-up count animation whenever the score
/// changes — tweens from the currently shown value to the new one.
class _TickPlaque extends StatefulWidget {
  final String label;
  final int value;
  final BakeryThemeDef theme;
  const _TickPlaque(
      {required this.label, required this.value, required this.theme});

  @override
  State<_TickPlaque> createState() => _TickPlaqueState();
}

class _TickPlaqueState extends State<_TickPlaque>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  int _from = 0;
  int _to = 0;

  @override
  void initState() {
    super.initState();
    _from = _to = widget.value;
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
  }

  @override
  void didUpdateWidget(covariant _TickPlaque old) {
    super.didUpdateWidget(old);
    if (widget.value != _to) {
      _from = _shown();
      _to = widget.value;
      _ctrl.forward(from: 0.0);
    }
  }

  int _shown() => _from +
      ((_to - _from) * Curves.easeOutCubic.transform(_ctrl.value)).round();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) => HangingPlaque(
        label: widget.label,
        value: formatScore(_shown()),
        theme: widget.theme,
      ),
    );
  }
}

/// Replayable shake wrapper: bumps the key on every illegal swipe.
class _ShakeWrapper extends StatelessWidget {
  final int shake;
  final Widget child;
  const _ShakeWrapper({required this.shake, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(shake),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      builder: (_, t, child) {
        final dx = shake == 0 ? 0.0 : sin(t * pi * 4) * (1 - t) * 10;
        return Transform.translate(
            offset: Offset(dx, 0), child: child);
      },
      child: child,
    );
  }
}
