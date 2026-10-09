import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../services/iap_service.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../theme/bakery_themes.dart';
import '../widgets/bakery.dart';
import 'how_to_play.dart';

/// Bakery settings: hanging sign, carved panels for music/SFX with
/// damper-latch toggles and rolling-pin sliders, vibration, undo,
/// baker profile, bakery styles, Pro, how-to-play, run history,
/// and best-score reset.
class SettingsScreen extends StatelessWidget {
  final Merge2048Settings settings;
  final SoundService sound;
  final BakeryStore store;
  final VoidCallback onBack;
  final VoidCallback onOpenThemes;
  final VoidCallback onOpenPro;

  const SettingsScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.store,
    required this.onBack,
    required this.onOpenThemes,
    required this.onOpenPro,
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
      builder: (ctx, _) {
        final theme = BakeryThemes.byId(st.themeId, custom: st.customTheme);
        final isPro = store.proPurchased.value;
        return Scaffold(
          backgroundColor: theme.background,
          body: FlourDustBackground(
            theme: theme,
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                children: [
                  Row(
                    children: [
                      WoodIconButton(
                        icon: Icons.arrow_back_rounded,
                        size: 44,
                        theme: theme,
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
                    theme: theme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _head('SOUND', '🔥', theme),
                        const SizedBox(height: 12),
                        _toggleRow('Music', 'warm hearth ambience',
                            st.musicOn, theme, (v) {
                          sound.playTap();
                          st.update(() => st.musicOn = v);
                          _audio(st);
                        }),
                        const SizedBox(height: 4),
                        Text('Music volume',
                            style: Merge2048Theme.label(13,
                                color: theme.creamDim)),
                        RollingPinSlider(
                            value: st.musicVolume,
                            theme: theme,
                            onChanged: (v) {
                              st.update(() => st.musicVolume = v);
                              _audio(st);
                            }),
                        const SizedBox(height: 6),
                        _toggleRow('Sound effects',
                            'biscuit clacks & dough thumps', st.sfxOn,
                            theme, (v) {
                          st.update(() => st.sfxOn = v);
                          _audio(st);
                          sound.playTap();
                        }),
                        const SizedBox(height: 4),
                        Text('Effects volume',
                            style: Merge2048Theme.label(13,
                                color: theme.creamDim)),
                        RollingPinSlider(
                            value: st.sfxVolume,
                            theme: theme,
                            onChanged: (v) {
                              st.update(() => st.sfxVolume = v);
                              _audio(st);
                            }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  WoodPanel(
                    theme: theme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _head('GAMEPLAY', '🍪', theme),
                        const SizedBox(height: 12),
                        _toggleRow('Vibration',
                            'gentle haptics on merges', st.vibration,
                            theme, (v) {
                          sound.playTap();
                          st.update(() => st.vibration = v);
                        }),
                        _divider(),
                        _toggleRow('Undo',
                            'allow undoing the last move',
                            st.undoOn, theme, (v) {
                          sound.playTap();
                          st.update(() => st.undoOn = v);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  WoodPanel(
                    theme: theme,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _head('BAKERY', '🥖', theme),
                        const SizedBox(height: 12),
                        _rowButton(
                            ctx,
                            'Baker name',
                            st.playerName,
                            Icons.person_rounded,
                            theme,
                            () => _renameDialog(ctx, theme)),
                        _divider(),
                        _rowButton(
                            ctx,
                            'Bakery styles',
                            '${BakeryThemes.byId(st.themeId, custom: st.customTheme).name} · ${TileStyles.byId(st.tileStyleId).name}',
                            Icons.palette_rounded,
                            theme,
                            onOpenThemes),
                        if (!isPro) ...[
                          _divider(),
                          _rowButton(
                              ctx,
                              'Go Pro',
                              'unlock everything',
                              Icons.workspace_premium_rounded,
                              theme,
                              onOpenPro),
                        ],
                        _divider(),
                        _rowButton(
                            ctx, 'How to Play', 'the rules of the bake',
                            Icons.menu_book_rounded, theme,
                            () => showHowToPlay(ctx, sound, theme)),
                        _divider(),
                        _rowButton(
                            ctx,
                            'Reset Best Score',
                            'forgets ${formatScore(settings.best)}',
                            Icons.warning_amber_rounded,
                            theme,
                            () => _confirmReset(ctx, theme),
                            warning: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _historyPanel(theme),
                  const SizedBox(height: 22),
                  Center(
                    child: Text(
                        'Merge 2048 v1.0 — baked fresh daily',
                        style: Merge2048Theme.label(11,
                            color: theme.creamDim)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _head(String title, String emoji, BakeryThemeDef theme) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 8),
        Text(title,
            style: Merge2048Theme.labelCaps(13)
                .copyWith(color: theme.cream)),
        const Expanded(child: SizedBox()),
        Container(
          height: 2,
          width: 60,
          decoration: BoxDecoration(
            color: theme.honey.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ],
    );
  }

  Widget _divider() =>
      const Divider(color: Color(0x339C8E81), height: 22);

  Widget _toggleRow(String title, String sub, bool value,
      BakeryThemeDef theme, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Merge2048Theme.body(15,
                      color: theme.cream,
                      weight: FontWeight.w700)),
              Text(sub,
                  style: Merge2048Theme.label(11.5,
                      color: theme.creamDim)),
            ],
          ),
        ),
        DamperToggle(value: value, onChanged: onChanged, theme: theme),
      ],
    );
  }

  Widget _rowButton(BuildContext ctx, String title, String sub,
      IconData icon, BakeryThemeDef theme, VoidCallback onTap,
      {bool warning = false}) {
    return GestureDetector(
      onTap: () {
        sound.playTap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon,
                color: warning ? theme.honey : theme.primary,
                size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Merge2048Theme.body(15,
                          color: theme.cream,
                          weight: FontWeight.w700)),
                  Text(sub,
                      style: Merge2048Theme.label(11.5,
                          color: theme.creamDim)),
                ],
              ),
            ),
            if (warning)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: theme.honey, width: 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('CAREFUL',
                    style: Merge2048Theme.labelCaps(9)
                        .copyWith(color: theme.honey)),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right_rounded,
                color: theme.outline),
          ],
        ),
      ),
    );
  }

  void _renameDialog(BuildContext ctx, BakeryThemeDef theme) {
    final ctrl = TextEditingController(text: settings.playerName);
    showDialog(
      context: ctx,
      builder: (dctx) => DialogBackdrop(
        child: OakDialog(
          maxWidth: 300,
          theme: theme,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Your baker name',
                  style: Merge2048Theme.display(20)
                      .copyWith(color: theme.primary)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLength: 16,
                style: Merge2048Theme.body(16, color: theme.cream),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: theme.deepest,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: theme.outline),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide:
                        BorderSide(color: theme.honey, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: WoodButton(
                      label: 'CANCEL',
                      primary: false,
                      fontSize: 14,
                      theme: theme,
                      onTap: () {
                        sound.playTap();
                        Navigator.of(dctx).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: WoodButton(
                      label: 'SAVE',
                      fontSize: 14,
                      theme: theme,
                      onTap: () {
                        settings.renamePlayer(ctrl.text);
                        sound.playTap();
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

  Widget _historyPanel(BakeryThemeDef theme) {
    final hist = settings.history;
    return WoodPanel(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _head('RECENT BATCHES', '📜', theme),
          const SizedBox(height: 8),
          if (hist.isEmpty)
            Text('No finished batches yet — bake your first!',
                style: Merge2048Theme.label(12.5,
                    color: theme.creamDim))
          else
            for (var i = 0; i < hist.length && i < 5; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.deepest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('${hist[i]['maxTile']}',
                          style: Merge2048Theme.body(13,
                              color: theme.primary,
                              weight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                          '${GameModes.byId('${hist[i]['mode'] ?? 'classic'}').name} · ${formatScore((hist[i]['score'] as num).toInt())} pts',
                          style: Merge2048Theme.label(12.5,
                              color: theme.cream)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext ctx, BakeryThemeDef theme) {
    sound.playTap();
    showDialog(
      context: ctx,
      builder: (dctx) => DialogBackdrop(
        child: OakDialog(
          maxWidth: 300,
          theme: theme,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Toss the best score?',
                  textAlign: TextAlign.center,
                  style: Merge2048Theme.display(20)
                      .copyWith(color: theme.primary)),
              const SizedBox(height: 8),
              Text(
                  'Your best of ${formatScore(settings.best)} on ${GameModes.byId(settings.modeId).name} will be forgotten forever.',
                  textAlign: TextAlign.center,
                  style: Merge2048Theme.label(13,
                      color: theme.creamDim)),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: WoodButton(
                      label: 'KEEP IT',
                      primary: false,
                      fontSize: 14,
                      theme: theme,
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
                      theme: theme,
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
