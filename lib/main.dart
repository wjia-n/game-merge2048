import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const Merge2048App());

class Merge2048App extends StatelessWidget {
  const Merge2048App({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      variant: ShellVariant.midnightNeon,
      title: 'Merge 2048',
      tagline: 'Swipe, smash numbers together, and chase the legendary 2048 tile!',
      emoji: '2️⃣',
      slug: 'merge2048',
      howToPlay:
          '• Swipe up, down, left or right to slide every tile.\n• Matching tiles crash together and double: 2+2=4, 4+4=8…\n• Every merge scores points. A new tile pops in after each swipe.\n• Game over when the board is jammed with no merges left.\n• Reach 2048. Become legend. 🏆',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => Merge2048Screen(players: players, callbacks: cb),
    );
  }
}
