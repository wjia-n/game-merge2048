import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../widgets/bakery.dart';
import 'how_to_play.dart';

/// Bakery settings: hanging sign, carved panels for music/SFX with
/// damper-latch toggles and rolling-pin sliders, vibration, undo,
/// how-to-play and best-score reset.
class SettingsScreen extends StatelessWidget {
  final Merge2048Settings settings;
  final SoundService sound;
  final VoidCallback onBack;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.onBack,
  });

  void _audio(Merge2048Settings st) {
    sound.applySettings(
        sfxOn: st.sfxOn,
        musicOn: st.musicOn,
        sfxVolume: st.sfxVolume,
        musicVolume: st.musicVolume);
  }

  @override
  Widget build(BuildContext context) {
    final st = settings;
    return ListenableBuilder(
      listenable: st,
      builder: (ctx, _) => Scaffold(
        backgroundColor: Merge2048Theme.background,
        body: FlourDustBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                Row(
                  children: [
                    WoodIconButton(
                      icon: Icons.arrow_back_rounded,
                      size: 44,
                      onTap: () {
                        sound.playTap();
                        onBack();
                      },
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Center(
                          child: WoodSign(
                              title: 'BAKERY SETTINGS',
                              fontSize: 20)),
                    ),
                    const SizedBox(width: 58),
                  ],
                ),
                const SizedBox(height: 18),
                WoodPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _head('SOUND', '🔥'),
                      const SizedBox(height: 12),
                      _toggleRow('Music', 'warm hearth ambience',
                          st.musicOn, (v) {
                        sound.playTap();
                        st.update(() => st.musicOn = v);
                        _audio(st);
                      }),
                      const SizedBox(height: 4),
                      Text('Music volume',
                          style: Merge2048Theme.label(13)),
                      RollingPinSlider(
                          value: st.musicVolume,
                          onChanged: (v) {
                            st.update(() => st.musicVolume = v);
                            _audio(st);
                          }),
                      const SizedBox(height: 6),
                      _toggleRow('Sound effects',
                          'biscuit clacks & dough thumps', st.sfxOn,
                          (v) {
                        st.update(() => st.sfxOn = v);
                        _audio(st);
                        sound.playTap();
                      }),
                      const SizedBox(height: 4),
                      Text('Effects volume',
                          style: Merge2048Theme.label(13)),
                      RollingPinSlider(
                          value: st.sfxVolume,
                          onChanged: (v) {
                            st.update(() => st.sfxVolume = v);
                            _audio(st);
                          }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                WoodPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _head('GAMEPLAY', '🍪'),
                      const SizedBox(height: 12),
                      _toggleRow('Vibration',
                          'gentle haptics on merges', st.vibration,
                          (v) {
                        sound.playTap();
                        st.update(() => st.vibration = v);
                      }),
                      _divider(),
                      _toggleRow('Undo',
                          'allow undoing the last move',
                          st.undoOn, (v) {
                        sound.playTap();
                        st.update(() => st.undoOn = v);
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                WoodPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _head('BAKERY', '🥖'),
                      const SizedBox(height: 12),
                      _rowButton(
                          ctx, 'How to Play', Icons.menu_book_rounded,
                          () => showHowToPlay(ctx, sound)),
                      _divider(),
                      _rowButton(
                          ctx,
                          'Reset Best Score',
                          Icons.warning_amber_rounded,
                          () => _confirmReset(ctx),
                          warning: true),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: Text(
                      'Merge 2048 v1.0 — baked fresh daily',
                      style: Merge2048Theme.label(11)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _head(String title, String emoji) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(title, style: Merge2048Theme.labelCaps(13)),
        const Expanded(child: SizedBox()),
        Container(
          height: 2,
          width: 60,
          decoration: BoxDecoration(
            color:
                Merge2048Theme.honey.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _divider() =>
      const Divider(color: Color(0x339C8E81), height: 22);

  Widget _toggleRow(String title, String sub, bool value,
      ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Merge2048Theme.body(15,
                      weight: FontWeight.w700)),
              Text(sub, style: Merge2048Theme.label(11.5)),
            ],
          ),
        ),
        DamperToggle(value: value, onChanged: onChanged),
      ],
    );
  }

  Widget _rowButton(BuildContext ctx, String title, IconData icon,
      VoidCallback onTap,
      {bool warning = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon,
                color: warning
                    ? Merge2048Theme.toasted
                    : Merge2048Theme.primary,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                  style: Merge2048Theme.body(15,
                      weight: FontWeight.w700)),
            ),
            if (warning)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Merge2048Theme.toasted, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('CAREFUL',
                    style: Merge2048Theme.labelCaps(9)
                        .copyWith(
                            color: Merge2048Theme.toasted)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded,
                color: Merge2048Theme.outline),
          ],
        ),
      ),
    );
  }

  void _confirmReset(BuildContext ctx) {
    sound.playTap();
    showDialog(
      context: ctx,
      builder: (dctx) => DialogBackdrop(
        child: OakDialog(
          maxWidth: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Toss the best score?',
                  textAlign: TextAlign.center,
                  style: Merge2048Theme.display(20)),
              const SizedBox(height: 8),
              Text(
                  'Your all-time best of ${formatScore(settings.best)} will be forgotten forever.',
                  textAlign: TextAlign.center,
                  style: Merge2048Theme.label(13)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: WoodButton(
                      label: 'KEEP IT',
                      primary: false,
                      fontSize: 14,
                      onTap: () {
                        sound.playTap();
                        Navigator.of(dctx).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: WoodButton(
                      label: 'RESET',
                      fontSize: 14,
                      onTap: () {
                        settings.resetBest();
                        sound.playInvalid();
                        Navigator.of(dctx).pop();
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
}
