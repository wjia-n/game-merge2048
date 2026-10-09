import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../services/iap_service.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../theme/bakery_themes.dart';
import '../widgets/bakery.dart';

/// Theme workshop: 12+ bakery themes, 8+ biscuit styles, 8 tray accents,
/// plus a custom theme creator. Pro-only entries show a lock and open
/// the Pro screen. Everything persists immediately.
class ThemeScreen extends StatelessWidget {
  final Merge2048Settings settings;
  final SoundService sound;
  final BakeryStore store;
  final VoidCallback onBack;
  final VoidCallback onOpenPro;

  const ThemeScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.store,
    required this.onBack,
    required this.onOpenPro,
  });

  bool get _isPro => store.proPurchased.value;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (ctx, _) {
        final theme = BakeryThemes.byId(settings.themeId,
            custom: settings.customTheme);
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
                                title: 'BAKERY STYLES', fontSize: 20)),
                      ),
                      const SizedBox(width: 58),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _section('OVEN THEMES', '${BakeryThemes.all.length} toasty palettes',
                      theme),
                  _themeGrid(theme),
                  const SizedBox(height: 8),
                  _customCreatorTile(theme),
                  const SizedBox(height: 18),
                  _section('BISCUIT STYLES', '${TileStyles.all.length} ways to bake',
                      theme),
                  _styleGrid(theme),
                  const SizedBox(height: 18),
                  _section('TRAY ACCENTS', '${TrayAccents.all.length} tray finishes',
                      theme),
                  _accentGrid(theme),
                  const SizedBox(height: 22),
                  if (!_isPro)
                    Center(
                      child: WoodButton(
                        label: 'UNLOCK EVERYTHING — GO PRO',
                        icon: Icons.workspace_premium_rounded,
                        theme: theme,
                        onTap: () {
                          sound.playTap();
                          onOpenPro();
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _section(String title, String sub, BakeryThemeDef theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Merge2048Theme.labelCaps(13)
                  .copyWith(color: theme.primary)),
          Text(sub, style: Merge2048Theme.label(12, color: theme.creamDim)),
        ],
      ),
    );
  }

  Widget _themeGrid(BakeryThemeDef theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemCount: BakeryThemes.all.length,
      itemBuilder: (_, i) {
        final def = BakeryThemes.all[i];
        final locked = !BakeryThemes.isFree(def.id) && !_isPro;
        final selected = settings.themeId == def.id;
        return _SwatchTile(
          name: def.name,
          locked: locked,
          selected: selected,
          theme: theme,
          preview: _biscuitPreview(def),
          onTap: () {
            sound.playTap();
            if (locked) {
              onOpenPro();
            } else {
              settings.update(() => settings.themeId = def.id);
            }
          },
        );
      },
    );
  }

  Widget _styleGrid(BakeryThemeDef theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.92,
      ),
      itemCount: TileStyles.all.length,
      itemBuilder: (_, i) {
        final st = TileStyles.all[i];
        final locked = !TileStyles.isFree(st.id) && !_isPro;
        final selected = settings.tileStyleId == st.id;
        return _SwatchTile(
          name: st.name,
          locked: locked,
          selected: selected,
          theme: theme,
          preview: BiscuitTile(
              value: 64, size: 44, theme: theme, style: st),
          onTap: () {
            sound.playTap();
            if (locked) {
              onOpenPro();
            } else {
              settings.update(() => settings.tileStyleId = st.id);
            }
          },
        );
      },
    );
  }

  Widget _accentGrid(BakeryThemeDef theme) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.8,
      ),
      itemCount: TrayAccents.all.length,
      itemBuilder: (_, i) {
        final a = TrayAccents.all[i];
        final locked = !TrayAccents.isFree(a.id) && !_isPro;
        final selected = settings.trayAccentId == a.id;
        return _SwatchTile(
          name: a.name,
          locked: locked,
          selected: selected,
          theme: theme,
          small: true,
          preview: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: theme.tray,
              border: Border.all(color: a.rim, width: 4),
              boxShadow: [
                BoxShadow(
                    color: a.rimLight.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, -1)),
              ],
            ),
          ),
          onTap: () {
            sound.playTap();
            if (locked) {
              onOpenPro();
            } else {
              settings.update(() => settings.trayAccentId = a.id);
            }
          },
        );
      },
    );
  }

  Widget _biscuitPreview(BakeryThemeDef def) {
    final face = def.faceFor(128);
    return BiscuitFace(
      size: 44,
      top: face[0],
      bottom: face[1],
      numeralColor: def.numeralFor(128),
      shelfColor: def.toastDeep,
      theme: def,
      child: Text('128',
          style: Merge2048Theme.numeral(15).copyWith(
              color: def.numeralFor(128), fontWeight: FontWeight.w700)),
    );
  }

  Widget _customCreatorTile(BakeryThemeDef theme) {
    final locked = !_isPro;
    final selected = settings.themeId == 'custom';
    return GestureDetector(
      onTap: () {
        sound.playTap();
        if (locked) {
          onOpenPro();
          return;
        }
        settings.update(() {
          if (settings.customTheme.isEmpty) {
            settings.customTheme = {
              'baseIdx': 0,
              'light': 0xFFF1DDA8,
              'deep': 0xFF8A3F1E,
            };
          }
          settings.themeId = 'custom';
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.panel,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? theme.honey : theme.outline.withValues(alpha: 0.35),
              width: selected ? 2.5 : 1.2),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(colors: [
                  Color(settings.customTheme['light'] ?? 0xFFF1DDA8),
                  Color(settings.customTheme['deep'] ?? 0xFF8A3F1E),
                ]),
                border: Border.all(color: theme.outline.withValues(alpha: 0.4)),
              ),
              child: locked
                  ? const Icon(Icons.lock_rounded, color: Colors.white70)
                  : Icon(Icons.palette_rounded, color: theme.numeralBurn),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('My Bake — custom theme',
                          style: Merge2048Theme.body(15,
                              color: theme.cream, weight: FontWeight.w700)),
                      if (locked) ...[
                        const SizedBox(width: 6),
                        _proBadge(theme),
                      ],
                    ],
                  ),
                  Text(
                      locked
                          ? 'Mix your own toast palette (Pro)'
                          : 'Tap again to remix your toast colors',
                      style: Merge2048Theme.label(12, color: theme.creamDim)),
                ],
              ),
            ),
            if (!locked)
              GestureDetector(
                onTap: () {
                  sound.playTap();
                  _remixCustom();
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.buttonBase,
                  ),
                  child: Icon(Icons.shuffle_rounded,
                      color: theme.primary, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _remixCustom() {
    // remix the toast pair from the warm bakery palette
    const lights = [
      0xFFF1DDA8, 0xFFFFE9B8, 0xFFF0CFA0, 0xFFF6E2B4,
      0xFFE4C795, 0xFFF8DEA8, 0xFFEBC49B, 0xFFFBD9A4,
    ];
    const deeps = [
      0xFF8A3F1E, 0xFF6E2E14, 0xFF9C4A12, 0xFF7E2F10,
      0xFF74250F, 0xFF822A0E, 0xFF5E2310, 0xFF8C3F12,
    ];
    final n = DateTime.now().millisecondsSinceEpoch;
    settings.update(() {
      settings.customTheme = {
        'baseIdx': (n ~/ 1000) % BakeryThemes.all.length,
        'light': lights[(n ~/ 7) % lights.length],
        'deep': deeps[(n ~/ 13) % deeps.length],
      };
      settings.themeId = 'custom';
    });
  }

  Widget _proBadge(BakeryThemeDef theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: theme.honey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('PRO',
          style: Merge2048Theme.labelCaps(9)
              .copyWith(color: theme.numeralBurn)),
    );
  }
}

class _SwatchTile extends StatelessWidget {
  final String name;
  final bool locked;
  final bool selected;
  final Widget preview;
  final VoidCallback onTap;
  final BakeryThemeDef theme;
  final bool small;

  const _SwatchTile({
    required this.name,
    required this.locked,
    required this.selected,
    required this.preview,
    required this.onTap,
    required this.theme,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: theme.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? theme.honey
                  : theme.outline.withValues(alpha: 0.3),
              width: selected ? 2.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                    opacity: locked ? 0.45 : 1, child: preview),
                if (locked)
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x99000000),
                    ),
                    child: const Icon(Icons.lock_rounded,
                        color: Colors.white, size: 16),
                  ),
                if (selected && !locked)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.honey,
                      ),
                      child: Icon(Icons.check_rounded,
                          color: theme.numeralBurn, size: 12),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Merge2048Theme.label(small ? 10 : 11,
                    color: theme.cream)),
          ],
        ),
      ),
    );
  }
}
