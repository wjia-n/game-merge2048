import 'dart:math';

import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../engine/merge_engine.dart';
import '../state/game.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/bakery.dart';
import '../widgets/tray.dart';
import 'game_over_screen.dart';

/// Gameplay: hearth console (logo, score/best plaques, undo + new-batch
/// + pause), the walnut tray board, hint strip. Victory / game-over / pause
/// appear as oak dialogs over the dimmed board.
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
    return ListenableBuilder(
      listenable: game,
      builder: (ctx, _) => Scaffold(
        backgroundColor: Merge2048Theme.background,
        body: FlourDustBackground(
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _topBar(),
                    _plaques(),
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
                                child: WalnutTray(game: game),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const HintStrip(
                        text:
                            'Swipe to slide & merge equal biscuits 🍪'),
                    const SizedBox(height: 14),
                  ],
                ),
                if (game.showVictory)
                  VictoryDialog(
                    game: game,
                    sound: widget.sound,
                    onKeepBaking: () => game.keepBaking(),
                    onNewBatch: () => game.newGame(),
                  ),
                if (game.showGameOver)
                  GameOverDialog(
                    game: game,
                    sound: widget.sound,
                    onNewBatch: () => game.newGame(),
                    onMenu: widget.onQuitToMenu,
                  ),
                if (_pauseOpen) _pauseDialog(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
      child: Row(
        children: [
          WoodIconButton(
            icon: Icons.pause_rounded,
            size: 44,
            onTap: _openPause,
          ),
          const SizedBox(width: 10),
          Text('MERGE 2048',
              style: Merge2048Theme.display(17).copyWith(
                  color: Merge2048Theme.primary)),
          const Spacer(),
          if (widget.settings.undoOn)
            WoodIconButton(
              icon: Icons.undo_rounded,
              size: 44,
              onTap: game.canUndo ? () => game.undo() : null,
            ),
          if (widget.settings.undoOn) const SizedBox(width: 8),
          WoodIconButton(
            icon: Icons.refresh_rounded,
            size: 44,
            onTap: () => _confirmNewBatch(),
          ),
        ],
      ),
    );
  }

  Widget _plaques() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          HangingPlaque(
              label: 'SCORE', value: formatScore(game.score)),
          HangingPlaque(
            label: 'BEST',
            value: formatScore(widget.settings.best),
            star: game.newBestThisRun,
          ),
        ],
      ),
    );
  }

  void _confirmNewBatch() {
    widget.sound.playTap();
    showDialog(
      context: context,
      builder: (ctx) => DialogBackdrop(
        child: OakDialog(
          maxWidth: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Start a fresh batch?',
                  textAlign: TextAlign.center,
                  style: Merge2048Theme.display(20)),
              const SizedBox(height: 8),
              Text(
                  'Your current tray and score will be tossed in the bin.',
                  textAlign: TextAlign.center,
                  style: Merge2048Theme.label(13)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: WoodButton(
                      label: 'KEEP',
                      primary: false,
                      fontSize: 14,
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

  Widget _pauseDialog() {
    return DialogBackdrop(
      child: OakDialog(
        maxWidth: 300,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WoodSign(title: 'PAUSED', fontSize: 22),
            const SizedBox(height: 8),
            Text('The oven is holding warm. 🔥',
                style: Merge2048Theme.label(13)),
            const SizedBox(height: 18),
            WoodButton(
              label: 'RESUME',
              icon: Icons.play_arrow_rounded,
              width: double.infinity,
              onTap: _closePause,
            ),
            const SizedBox(height: 10),
            WoodButton(
              label: 'RESTART',
              primary: false,
              width: double.infinity,
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
