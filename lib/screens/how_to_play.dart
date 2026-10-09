import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../theme.dart';
import '../theme/bakery_themes.dart';
import '../widgets/bakery.dart';

/// How-to-play dialog: the RULES in warm bakery voice.
Future<void> showHowToPlay(
    BuildContext context, SoundService sound, BakeryThemeDef theme) {
  sound.playTap();
  const rows = [
    ('🥖 The goal',
        'Slide the wooden number biscuits around the tray and merge matching pairs. Bake the legendary 2048 biscuit!'),
    ('👆 How to slide',
        'Swipe up, down, left or right. Every biscuit slides as far as it can go.'),
    ('🍪 Merging',
        'When two equal biscuits collide they bake into one biscuit worth double: 2+2=4, 4+4=8… Each merge scores the value of the new biscuit.'),
    ('🌾 Fresh bakes',
        'After every real move, one fresh biscuit (usually a 2, sometimes a 4) lands on a random empty spot.'),
    ('↩️ Undo',
        'Changed your mind? Undo brings back the tray exactly as it was before your last swipe.'),
    ('🏆 Winning',
        'Bake a 2048 biscuit to win — then keep baking toward 4096 and beyond if you dare.'),
    ('🧱 Game over',
        'The batch is ruined when the tray is full and no merges are left.'),
  ];
  return showDialog(
    context: context,
    builder: (ctx) => DialogBackdrop(
      child: OakDialog(
        theme: theme,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WoodSign(title: 'HOW TO PLAY', fontSize: 20, theme: theme),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 380),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final r in rows) ...[
                      Text(r.$1,
                          style: Merge2048Theme.body(14,
                              color: theme.primary,
                              weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(r.$2,
                          style: Merge2048Theme.body(13.5,
                              color: theme.creamDim)),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            WoodButton(
              label: 'GOT IT',
              width: double.infinity,
              theme: theme,
              onTap: () {
                sound.playTap();
                Navigator.of(ctx).pop();
              },
            ),
          ],
        ),
      ),
    ),
  );
}
