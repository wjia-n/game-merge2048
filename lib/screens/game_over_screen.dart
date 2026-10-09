import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../state/game.dart';
import '../theme.dart';
import '../widgets/bakery.dart';

/// Victory dialog: oak bakery sign, hero 2048 biscuit on a pedestal,
/// score/best plaques with a baked-star "new best" stamp.
class VictoryDialog extends StatelessWidget {
  final Merge2048Game game;
  final SoundService sound;
  final VoidCallback onKeepBaking;
  final VoidCallback onNewBatch;

  const VictoryDialog({
    super.key,
    required this.game,
    required this.sound,
    required this.onKeepBaking,
    required this.onNewBatch,
  });

  @override
  Widget build(BuildContext context) {
    return DialogBackdrop(
      child: OakDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('YOU BAKED THE 2048!',
                textAlign: TextAlign.center,
                style: Merge2048Theme.display(26).copyWith(
                    color: Merge2048Theme.primary)),
            const SizedBox(height: 4),
            Text('golden, crisp, legendary 🏆',
                style: Merge2048Theme.label(13)),
            const SizedBox(height: 14),
            // hero biscuit on a wooden pedestal
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BiscuitTile(
                    value: 2048,
                    size:
                        MediaQuery.of(context).size.width * 0.32),
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
                        color: Merge2048Theme.honeyBase,
                        width: 1),
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
                    value: formatScore(game.score)),
                HangingPlaque(
                  label: 'BEST',
                  value: formatScore(game.settings.best),
                  star: game.newBestThisRun,
                ),
              ],
            ),
            const SizedBox(height: 20),
            WoodButton(
              label: 'KEEP BAKING',
              icon: Icons.local_fire_department_rounded,
              width: double.infinity,
              onTap: onKeepBaking,
            ),
            const SizedBox(height: 10),
            WoodButton(
              label: 'NEW BATCH',
              primary: false,
              width: double.infinity,
              onTap: onNewBatch,
            ),
          ],
        ),
      ),
    );
  }
}

/// Game-over dialog: same oak frame, "OUT OF MOVES" headline, final score.
class GameOverDialog extends StatelessWidget {
  final Merge2048Game game;
  final SoundService sound;
  final VoidCallback onNewBatch;
  final VoidCallback onMenu;

  const GameOverDialog({
    super.key,
    required this.game,
    required this.sound,
    required this.onNewBatch,
    required this.onMenu,
  });

  @override
  Widget build(BuildContext context) {
    return DialogBackdrop(
      child: OakDialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('OUT OF MOVES',
                textAlign: TextAlign.center,
                style: Merge2048Theme.display(26).copyWith(
                    color: Merge2048Theme.primary)),
            const SizedBox(height: 4),
            Text('The tray is full — no more merges. 🧱',
                textAlign: TextAlign.center,
                style: Merge2048Theme.label(13)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                HangingPlaque(
                    label: 'SCORE',
                    value: formatScore(game.score)),
                HangingPlaque(
                  label: 'BEST',
                  value: formatScore(game.settings.best),
                  star: game.newBestThisRun,
                ),
              ],
            ),
            const SizedBox(height: 20),
            WoodButton(
              label: 'NEW BATCH',
              icon: Icons.refresh_rounded,
              width: double.infinity,
              onTap: onNewBatch,
            ),
            if (game.canUndo) ...[
              const SizedBox(height: 10),
              WoodButton(
                label: 'UNDO LAST MOVE',
                primary: false,
                width: double.infinity,
                onTap: () => game.undo(),
              ),
            ],
            const SizedBox(height: 10),
            WoodButton(
              label: 'MENU',
              primary: false,
              width: double.infinity,
              onTap: onMenu,
            ),
          ],
        ),
      ),
    );
  }
}
