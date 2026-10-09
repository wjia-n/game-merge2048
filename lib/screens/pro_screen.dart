import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../audio/sound.dart';
import '../services/iap_service.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../theme/bakery_themes.dart';
import '../widgets/bakery.dart';

/// Pro upgrade screen: Free-vs-Pro comparison, buy/restore Pro,
/// and the tip jar (coffee / chocolate). Honest about store state —
/// when the products aren't created in Play Console yet, buying is
/// disabled with an "available after store setup" note.
class ProScreen extends StatelessWidget {
  final Merge2048Settings settings;
  final SoundService sound;
  final BakeryStore store;
  final VoidCallback onBack;

  const ProScreen({
    super.key,
    required this.settings,
    required this.sound,
    required this.store,
    required this.onBack,
  });

  static const _rows = [
    ['Classic 4×4 tray', true, true],
    ['Undo last move', true, true],
    ['Score history', true, true],
    ['Bakery themes', '4', 'All 12'],
    ['Biscuit styles', '4', 'All 9'],
    ['Tray accents', '4', 'All 8'],
    ['Custom theme creator', false, true],
    ['Big Batch 5×5 board', false, true],
    ['Grand Oven 6×6 board', false, true],
  ];

  @override
  Widget build(BuildContext context) {
    final theme = BakeryThemes.byId(settings.themeId,
        custom: settings.customTheme);
    return ListenableBuilder(
      listenable: settings,
      builder: (ctx, _) => Scaffold(
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
                          child:
                              WoodSign(title: 'GO PRO', fontSize: 20)),
                    ),
                    const SizedBox(width: 58),
                  ],
                ),
                const SizedBox(height: 14),
                _thanksBanner(theme),
                const SizedBox(height: 14),
                _comparisonCard(theme),
                const SizedBox(height: 14),
                _buySection(theme),
                const SizedBox(height: 18),
                _tipJar(theme),
                const SizedBox(height: 14),
                Center(
                  child: TextButton(
                    onPressed: () {
                      sound.playTap();
                      store.restore();
                    },
                    child: Text('Restore purchases',
                        style: Merge2048Theme.body(14,
                            color: theme.primary,
                            weight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _thanksBanner(BakeryThemeDef theme) {
    return ValueListenableBuilder<String?>(
      valueListenable: store.lastThanks,
      builder: (_, msg, _) {
        if (msg == null) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.panel,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.honey, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(Icons.favorite_rounded, color: theme.honey),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(msg,
                      style: Merge2048Theme.body(14,
                          color: theme.cream,
                          weight: FontWeight.w700))),
            ],
          ),
        );
      },
    );
  }

  Widget _comparisonCard(BakeryThemeDef theme) {
    Widget cell(dynamic v, {bool header = false}) {
      final style = header
          ? Merge2048Theme.labelCaps(12).copyWith(color: theme.primary)
          : Merge2048Theme.body(13.5, color: theme.cream);
      if (v is bool) {
        return v
            ? Icon(Icons.check_circle_rounded,
                color: theme.honey, size: 20)
            : Icon(Icons.remove_circle_outline_rounded,
                color: theme.outline, size: 20);
      }
      return Text('$v', textAlign: TextAlign.center, style: style);
    }

    return WoodPanel(
      theme: theme,
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(flex: 3, child: SizedBox()),
              Expanded(flex: 2, child: cell('FREE', header: true)),
              Expanded(
                  flex: 2,
                  child: Center(
                      child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.honey,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('PRO',
                        style: Merge2048Theme.labelCaps(11)
                            .copyWith(color: theme.numeralBurn)),
                  ))),
            ],
          ),
          const Divider(color: Color(0x339C8E81), height: 16),
          for (final r in _rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                      flex: 3,
                      child: Text(r[0] as String,
                          style: Merge2048Theme.body(13.5,
                              color: theme.cream))),
                  Expanded(flex: 2, child: Center(child: cell(r[1]))),
                  Expanded(flex: 2, child: Center(child: cell(r[2]))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buySection(BakeryThemeDef theme) {
    return ValueListenableBuilder<bool>(
      valueListenable: store.proPurchased,
      builder: (_, owned, _) {
        if (owned) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.panel,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.honey, width: 2),
            ),
            child: Row(
              children: [
                Icon(Icons.workspace_premium_rounded,
                    color: theme.honey, size: 30),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('You own Merge 2048 PRO —\neverything is unlocked. 🍪',
                      style: Merge2048Theme.body(15,
                          color: theme.cream,
                          weight: FontWeight.w700)),
                ),
              ],
            ),
          );
        }
        final ready = store.storeReady && store.proProduct != null;
        return Column(
          children: [
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => WoodButton(
                label: busy
                    ? 'WORKING…'
                    : ready
                        ? 'UNLOCK PRO — ${store.proProduct!.price}'
                        : 'UNLOCK PRO',
                icon: Icons.workspace_premium_rounded,
                width: double.infinity,
                theme: theme,
                onTap: (!ready || busy)
                    ? null
                    : () {
                        sound.playTap();
                        store.buyPro();
                      },
              ),
            ),
            if (!ready) ...[
              const SizedBox(height: 8),
              Text(
                  store.error ?? 'Pro unlock available after store setup',
                  textAlign: TextAlign.center,
                  style:
                      Merge2048Theme.label(12, color: theme.creamDim)),
            ],
            ValueListenableBuilder<String?>(
              valueListenable: store.purchaseError,
              builder: (_, err, _) => err == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(err,
                          textAlign: TextAlign.center,
                          style: Merge2048Theme.label(12,
                              color: const Color(0xFFE08080))),
                    ),
            ),
            const SizedBox(height: 6),
            Text('One-time purchase · yours forever · no ads, no subscriptions',
                textAlign: TextAlign.center,
                style: Merge2048Theme.label(11, color: theme.creamDim)),
          ],
        );
      },
    );
  }

  Widget _tipJar(BakeryThemeDef theme) {
    return WoodPanel(
      theme: theme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('TIP JAR',
              style: Merge2048Theme.labelCaps(13)
                  .copyWith(color: theme.primary)),
          const SizedBox(height: 4),
          Text('Baked solo with love — a small tip keeps the oven warm. 🔥',
              style: Merge2048Theme.label(12.5, color: theme.creamDim)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _tipButton(theme, '☕', store.coffeeProduct)),
              const SizedBox(width: 10),
              Expanded(
                  child: _tipButton(theme, '🍫', store.chocolateProduct)),
            ],
          ),
          if (!store.storeReady) ...[
            const SizedBox(height: 8),
            Text(store.error ?? 'Tips available after store setup',
                textAlign: TextAlign.center,
                style: Merge2048Theme.label(11.5, color: theme.creamDim)),
          ],
        ],
      ),
    );
  }

  Widget _tipButton(
      BakeryThemeDef theme, String emoji, ProductDetails? product) {
    final ready = store.storeReady && product != null;
    return ValueListenableBuilder<bool>(
      valueListenable: store.purchaseInProgress,
      builder: (_, busy, _) => WoodButton(
        label: ready ? '$emoji ${product.price}' : emoji,
        primary: false,
        fontSize: 15,
        theme: theme,
        onTap: (!ready || busy)
            ? null
            : () {
                sound.playTap();
                store.buyTip(product);
              },
      ),
    );
  }
}
