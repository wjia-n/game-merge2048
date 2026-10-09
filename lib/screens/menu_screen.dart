import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../state/game.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/bakery.dart';
import 'how_to_play.dart';

/// Main menu: biscuit-letter title on a wooden shelf, hanging tagline,
/// decorative biscuit stack, big honey PLAY button, best-score plaque.
class MenuScreen extends StatelessWidget {
  final Merge2048Settings settings;
  final SoundService sound;
  final Merge2048Game game;
  final bool hasSave;
  final VoidCallback onPlay;
  final VoidCallback onResume;
  final VoidCallback onOpenSettings;

  const MenuScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.game,
    required this.hasSave,
    required this.onPlay,
    required this.onResume,
    required this.onOpenSettings,
  });

  void _start({required bool fresh}) {
    if (fresh) {
      game.newGame();
      onPlay();
    } else {
      sound.playTap();
      onResume();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Merge2048Theme.background,
      body: FlourDustBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (ctx, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(24, 8, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          WoodIconButton(
                            icon: Icons.settings_rounded,
                            size: 44,
                            onTap: () {
                              sound.playTap();
                              onOpenSettings();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (settings.best > 0)
                        HangingPlaque(
                            label: 'BEST',
                            value: formatScore(settings.best)),
                      const SizedBox(height: 10),
                      const BiscuitTitle(),
                      const SizedBox(height: 14),
                      // hanging tagline sign
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 60,
                            height: 14,
                            child: CustomPaint(
                                painter: _MenuTwinePainter()),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 8),
                            decoration: BoxDecoration(
                              color: Merge2048Theme.timber,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Merge2048Theme.honeyBase,
                                  width: 1.2),
                            ),
                            child: Text(
                              'Bake bigger biscuits! Slide & merge to 2048.',
                              textAlign: TextAlign.center,
                              style: Merge2048Theme.body(13.5,
                                  color: Merge2048Theme.primary,
                                  weight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      // decorative biscuit stack
                      const _BiscuitStack(),
                      const SizedBox(height: 26),
                      WoodButton(
                        label: hasSave ? 'NEW BATCH' : 'PLAY',
                        icon: Icons.play_arrow_rounded,
                        width: 240,
                        onTap: () => _start(fresh: true),
                      ),
                      if (hasSave) ...[
                        const SizedBox(height: 12),
                        WoodButton(
                          label: 'RESUME BATCH',
                          primary: false,
                          width: 240,
                          onTap: () => _start(fresh: false),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          WoodButton(
                            label: 'HOW TO PLAY',
                            primary: false,
                            fontSize: 13,
                            onTap: () =>
                                showHowToPlay(context, sound),
                          ),
                          const SizedBox(width: 12),
                          WoodButton(
                            label: 'SETTINGS',
                            primary: false,
                            fontSize: 13,
                            onTap: () {
                              sound.playTap();
                              onOpenSettings();
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text('baked fresh daily 🍞',
                          style: Merge2048Theme.label(11)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTwinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9C8E81)
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width * 0.2, size.height), paint);
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width * 0.8, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Decorative casual stack of fresh biscuits (2, 4, 8, 16).
class _BiscuitStack extends StatelessWidget {
  const _BiscuitStack();

  @override
  Widget build(BuildContext context) {
    const vals = [16, 8, 4, 2];
    return SizedBox(
      height: 76,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (var i = 0; i < vals.length; i++)
            Positioned(
              left: 40.0 + i * 52,
              top: (i.isEven ? 8.0 : 0.0),
              child: Transform.rotate(
                angle: (i - 1.5) * 0.08,
                child: BiscuitTile(value: vals[i], size: 58),
              ),
            ),
        ],
      ),
    );
  }
}
