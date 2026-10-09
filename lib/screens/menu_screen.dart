import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../services/iap_service.dart';
import '../state/game.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../theme/bakery_themes.dart';
import '../widgets/bakery.dart';
import 'how_to_play.dart';

/// Main menu: game logo, biscuit-letter title, hanging tagline,
/// player profile, mode picker, best-score plaque, PLAY / RESUME,
/// and entries to themes, Pro, how-to-play and settings.
class MenuScreen extends StatelessWidget {
  final Merge2048Settings settings;
  final SoundService sound;
  final Merge2048Game game;
  final BakeryStore store;
  final bool hasSave;
  final VoidCallback onPlay;
  final VoidCallback onResume;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenThemes;
  final VoidCallback onOpenPro;

  const MenuScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.game,
    required this.store,
    required this.hasSave,
    required this.onPlay,
    required this.onResume,
    required this.onOpenSettings,
    required this.onOpenThemes,
    required this.onOpenPro,
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
    return ListenableBuilder(
      listenable: settings,
      builder: (ctx, _) {
        final theme = BakeryThemes.byId(settings.themeId,
            custom: settings.customTheme);
        final isPro = store.proPurchased.value;
        return Scaffold(
          backgroundColor: theme.background,
          body: FlourDustBackground(
            theme: theme,
            child: SafeArea(
              child: LayoutBuilder(
                builder: (ctx2, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: constraints.maxHeight),
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
                                icon: Icons.palette_rounded,
                                size: 44,
                                theme: theme,
                                onTap: () {
                                  sound.playTap();
                                  onOpenThemes();
                                },
                              ),
                              const SizedBox(width: 8),
                              WoodIconButton(
                                icon: Icons.settings_rounded,
                                size: 44,
                                theme: theme,
                                onTap: () {
                                  sound.playTap();
                                  onOpenSettings();
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          // game logo
                          Container(
                            width: 104,
                            height: 104,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                  color: theme.primary, width: 2.5),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x99000000),
                                  offset: Offset(0, 8),
                                  blurRadius: 18,
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Image.asset(
                                'assets/merge2048_logo.png',
                                fit: BoxFit.cover),
                          ),
                          const SizedBox(height: 12),
                          if (settings.best > 0)
                            HangingPlaque(
                                label: 'BEST',
                                value: formatScore(settings.best),
                                theme: theme),
                          const SizedBox(height: 10),
                          BiscuitTitle(theme: theme),
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
                                  color: theme.panel,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: theme.buttonBase,
                                      width: 1.2),
                                ),
                                child: Text(
                                  'Bake bigger biscuits! Slide & merge to 2048.',
                                  textAlign: TextAlign.center,
                                  style: Merge2048Theme.body(13.5,
                                      color: theme.primary,
                                      weight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // player profile chip
                          _profileChip(theme, context),
                          const SizedBox(height: 12),
                          // mode picker
                          _modePicker(theme, isPro),
                          const SizedBox(height: 20),
                          WoodButton(
                            label: hasSave ? 'NEW BATCH' : 'PLAY',
                            icon: Icons.play_arrow_rounded,
                            width: 240,
                            theme: theme,
                            onTap: () => _start(fresh: true),
                          ),
                          if (hasSave) ...[
                            const SizedBox(height: 12),
                            WoodButton(
                              label: 'RESUME BATCH',
                              primary: false,
                              width: 240,
                              theme: theme,
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
                                theme: theme,
                                onTap: () =>
                                    showHowToPlay(context, sound, theme),
                              ),
                              const SizedBox(width: 12),
                              if (!isPro)
                                WoodButton(
                                  label: 'GO PRO',
                                  fontSize: 13,
                                  theme: theme,
                                  onTap: () {
                                    sound.playTap();
                                    onOpenPro();
                                  },
                                ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('baked fresh daily 🍞',
                              style: Merge2048Theme.label(11,
                                  color: theme.creamDim)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _profileChip(BakeryThemeDef theme, BuildContext context) {
    return GestureDetector(
      onTap: () => _renameDialog(context, theme),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: theme.panel,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
              color: theme.outline.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_rounded,
                color: theme.primary, size: 18),
            const SizedBox(width: 8),
            Text('Baker: ${settings.playerName}',
                style: Merge2048Theme.body(14,
                    color: theme.cream,
                    weight: FontWeight.w700)),
            const SizedBox(width: 6),
            Icon(Icons.edit_rounded,
                color: theme.creamDim, size: 14),
          ],
        ),
      ),
    );
  }

  void _renameDialog(BuildContext context, BakeryThemeDef theme) {
    sound.playTap();
    final ctrl = TextEditingController(text: settings.playerName);
    showDialog(
      context: context,
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

  Widget _modePicker(BakeryThemeDef theme, bool isPro) {
    return Column(
      children: [
        Text('CHOOSE YOUR TRAY',
            style: Merge2048Theme.labelCaps(11)
                .copyWith(color: theme.creamDim)),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final m in GameModes.all)
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4),
                  child: _modeCard(theme, m, isPro),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _modeCard(BakeryThemeDef theme, GameModeDef m, bool isPro) {
    final selected = settings.modeId == m.id;
    final locked = !m.free && !isPro;
    return GestureDetector(
      onTap: () {
        sound.playTap();
        if (locked) {
          onOpenPro();
          return;
        }
        if (settings.modeId != m.id) {
          game.setMode(m.id);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? theme.panelHigh : theme.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected ? theme.honey : theme.outline.withValues(alpha: 0.3),
              width: selected ? 2.5 : 1),
        ),
        child: Column(
          children: [
            // mini tray preview
            SizedBox(
              width: 44,
              height: 44,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: m.size,
                  crossAxisSpacing: 2,
                  mainAxisSpacing: 2,
                ),
                itemCount: m.size * m.size,
                itemBuilder: (_, i) => Container(
                  decoration: BoxDecoration(
                    color: i % (m.size + 1) == 0
                        ? theme.honey.withValues(alpha: 0.75)
                        : theme.deepest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(m.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Merge2048Theme.body(11.5,
                    color: theme.cream,
                    weight: FontWeight.w800)),
            Text(m.blurb,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Merge2048Theme.label(9.5, color: theme.creamDim)),
            if (locked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(Icons.lock_rounded,
                    color: theme.creamDim, size: 14),
              ),
            if (selected && !locked)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child:
                    Icon(Icons.check_rounded, color: theme.honey, size: 14),
              ),
          ],
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
