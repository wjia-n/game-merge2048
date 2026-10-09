import 'package:flutter/material.dart';

/// Theme, tile-style, tray-accent and mode catalogs for Merge 2048.
///
/// Every theme stays inside the Artisanal Bakery material world (real wood
/// tones, flour, honey, hearth warmth — no neon, no glow). Variety comes
/// from different woods, toast levels, linens and accents.
///
/// Free/Pro split: the first 4 entries of each catalog are FREE; the rest
/// need the Pro unlock. The custom theme creator is Pro-only.
class BakeryThemeDef {
  final String id;
  final String name;
  final Color background;
  final Color deepest;
  final Color tray;
  final Color panel;
  final Color panelHigh;
  final Color primary; // carved gold numerals / accents
  final Color honey; // button face
  final Color buttonBase; // button rim
  final Color cream; // text
  final Color creamDim;
  final Color outline;
  final Color numeralBurn; // pyrography on light biscuits
  final Color plaqueFace;
  final Color toastLight; // lightest biscuit face (value 2)
  final Color toastDeep; // darkest biscuit face (2048+)

  const BakeryThemeDef({
    required this.id,
    required this.name,
    required this.background,
    required this.deepest,
    required this.tray,
    required this.panel,
    required this.panelHigh,
    required this.primary,
    required this.honey,
    required this.buttonBase,
    required this.cream,
    required this.creamDim,
    required this.outline,
    required this.numeralBurn,
    required this.plaqueFace,
    required this.toastLight,
    required this.toastDeep,
  });

  /// Toast tier for a tile value: interpolates the 2→2048+ progression
  /// across 11 steps (exponent 1..11). Returns [top, bottom] face colors.
  List<Color> faceFor(int value) {
    var e = 1;
    var v = value;
    while (v > 2) {
      v ~/= 2;
      e++;
    }
    final t = ((e - 1) / 10.0).clamp(0.0, 1.0);
    final top = Color.lerp(toastLight, toastDeep, t * 0.72)!;
    final bottom = Color.lerp(toastLight, toastDeep, (t * 0.72 + 0.28).clamp(0.0, 1.0))!;
    return [top, bottom];
  }

  /// Numeral ink: pyrography burn on light biscuits, carved gold on crust.
  Color numeralFor(int value) {
    var e = 1;
    var v = value;
    while (v > 2) {
      v ~/= 2;
      e++;
    }
    return e >= 9 ? primary : numeralBurn;
  }
}

class BakeryThemes {
  static const List<String> freeThemeIds = [
    'classic',
    'walnut',
    'honeycomb',
    'cinnamon',
  ];

  static const List<BakeryThemeDef> all = [
    // ---- FREE ----
    BakeryThemeDef(
      id: 'classic',
      name: 'Hearth Classic',
      background: Color(0xFF1D1108),
      deepest: Color(0xFF170B04),
      tray: Color(0xFF2A1D13),
      panel: Color(0xFF36271C),
      panelHigh: Color(0xFF413126),
      primary: Color(0xFFF7C07E),
      honey: Color(0xFFF5A623),
      buttonBase: Color(0xFFB4622D),
      cream: Color(0xFFF8DDCD),
      creamDim: Color(0xFFD4C4B5),
      outline: Color(0xFF9C8E81),
      numeralBurn: Color(0xFF3A2410),
      plaqueFace: Color(0xFF342216),
      toastLight: Color(0xFFF1DDA8),
      toastDeep: Color(0xFF8A3F1E),
    ),
    BakeryThemeDef(
      id: 'walnut',
      name: 'Deep Walnut',
      background: Color(0xFF17100A),
      deepest: Color(0xFF100906),
      tray: Color(0xFF241811),
      panel: Color(0xFF2E2117),
      panelHigh: Color(0xFF3A2A1D),
      primary: Color(0xFFE8B76B),
      honey: Color(0xFFE09A2B),
      buttonBase: Color(0xFF8A4E22),
      cream: Color(0xFFF2DECB),
      creamDim: Color(0xFFC9B5A3),
      outline: Color(0xFF8E7F70),
      numeralBurn: Color(0xFF2E1C0C),
      plaqueFace: Color(0xFF2C1E12),
      toastLight: Color(0xFFE4C795),
      toastDeep: Color(0xFF6E2E14),
    ),
    BakeryThemeDef(
      id: 'honeycomb',
      name: 'Honeycomb',
      background: Color(0xFF231505),
      deepest: Color(0xFF1A0F03),
      tray: Color(0xFF33200E),
      panel: Color(0xFF40301B),
      panelHigh: Color(0xFF4E3B22),
      primary: Color(0xFFFFD98F),
      honey: Color(0xFFFFB52E),
      buttonBase: Color(0xFFC67A1A),
      cream: Color(0xFFFFE8C8),
      creamDim: Color(0xFFDFC49E),
      outline: Color(0xFFA8946F),
      numeralBurn: Color(0xFF402408),
      plaqueFace: Color(0xFF3A2812),
      toastLight: Color(0xFFFFE9B8),
      toastDeep: Color(0xFF9C4A12),
    ),
    BakeryThemeDef(
      id: 'cinnamon',
      name: 'Cinnamon Spice',
      background: Color(0xFF220F08),
      deepest: Color(0xFF190B05),
      tray: Color(0xFF2F1A10),
      panel: Color(0xFF3B2417),
      panelHigh: Color(0xFF482C1D),
      primary: Color(0xFFF0A868),
      honey: Color(0xFFEE8E2E),
      buttonBase: Color(0xFFA84A1C),
      cream: Color(0xFFFBE0C4),
      creamDim: Color(0xFFD8B79A),
      outline: Color(0xFF9E8871),
      numeralBurn: Color(0xFF35190A),
      plaqueFace: Color(0xFF352012),
      toastLight: Color(0xFFF0CFA0),
      toastDeep: Color(0xFF7E2F10),
    ),
    // ---- PRO ----
    BakeryThemeDef(
      id: 'mahogany',
      name: 'Royal Mahogany',
      background: Color(0xFF1E0E0B),
      deepest: Color(0xFF150905),
      tray: Color(0xFF2C1512),
      panel: Color(0xFF38201B),
      panelHigh: Color(0xFF442823),
      primary: Color(0xFFF2B183),
      honey: Color(0xFFE88A3B),
      buttonBase: Color(0xFF93371C),
      cream: Color(0xFFF6DAC8),
      creamDim: Color(0xFFD3AE99),
      outline: Color(0xFF9A8073),
      numeralBurn: Color(0xFF33150C),
      plaqueFace: Color(0xFF311A14),
      toastLight: Color(0xFFEBC49B),
      toastDeep: Color(0xFF74250F),
    ),
    BakeryThemeDef(
      id: 'oak',
      name: 'Rustic Oak',
      background: Color(0xFF241A0E),
      deepest: Color(0xFF1B1208),
      tray: Color(0xFF352812),
      panel: Color(0xFF43341B),
      panelHigh: Color(0xFF524023),
      primary: Color(0xFFFFDFA0),
      honey: Color(0xFFF6B93B),
      buttonBase: Color(0xFFB0722A),
      cream: Color(0xFFFFEDD0),
      creamDim: Color(0xFFE2C9A4),
      outline: Color(0xFFAB9A79),
      numeralBurn: Color(0xFF45300F),
      plaqueFace: Color(0xFF3E2F16),
      toastLight: Color(0xFFF6E2B4),
      toastDeep: Color(0xFF8E5220),
    ),
    BakeryThemeDef(
      id: 'cocoa',
      name: 'Dark Cocoa',
      background: Color(0xFF120B08),
      deepest: Color(0xFF0C0605),
      tray: Color(0xFF1D130E),
      panel: Color(0xFF251B14),
      panelHigh: Color(0xFF302419),
      primary: Color(0xFFD9A066),
      honey: Color(0xFFC97F2E),
      buttonBase: Color(0xFF7E4420),
      cream: Color(0xFFEED6BC),
      creamDim: Color(0xFFBFA78D),
      outline: Color(0xFF84705E),
      numeralBurn: Color(0xFF28160B),
      plaqueFace: Color(0xFF241811),
      toastLight: Color(0xFFDBB98C),
      toastDeep: Color(0xFF5E2310),
    ),
    BakeryThemeDef(
      id: 'ember',
      name: 'Ember Hearth',
      background: Color(0xFF220D06),
      deepest: Color(0xFF190906),
      tray: Color(0xFF2E150C),
      panel: Color(0xFF3A1E13),
      panelHigh: Color(0xFF472619),
      primary: Color(0xFFFFB27A),
      honey: Color(0xFFF08A3E),
      buttonBase: Color(0xFFA03E1E),
      cream: Color(0xFFFBD9BE),
      creamDim: Color(0xFFD4AE8F),
      outline: Color(0xFF9C7E68),
      numeralBurn: Color(0xFF331408),
      plaqueFace: Color(0xFF331C11),
      toastLight: Color(0xFFF2C896),
      toastDeep: Color(0xFF822A0E),
    ),
    BakeryThemeDef(
      id: 'harvest',
      name: 'Harvest Wheat',
      background: Color(0xFF20160A),
      deepest: Color(0xFF181005),
      tray: Color(0xFF30230F),
      panel: Color(0xFF3C2E17),
      panelHigh: Color(0xFF4A3A1F),
      primary: Color(0xFFFAD38E),
      honey: Color(0xFFF0AD33),
      buttonBase: Color(0xFFAD6E22),
      cream: Color(0xFFFFE4BC),
      creamDim: Color(0xFFDAC09A),
      outline: Color(0xFFA28F6C),
      numeralBurn: Color(0xFF3E2A0D),
      plaqueFace: Color(0xFF382A14),
      toastLight: Color(0xFFF8DEA8),
      toastDeep: Color(0xFF8A481A),
    ),
    BakeryThemeDef(
      id: 'maple',
      name: 'Maple Morning',
      background: Color(0xFF26180C),
      deepest: Color(0xFF1C1108),
      tray: Color(0xFF382512),
      panel: Color(0xFF46301A),
      panelHigh: Color(0xFF553C21),
      primary: Color(0xFFFFCE7E),
      honey: Color(0xFFFCAA2B),
      buttonBase: Color(0xFFB86A20),
      cream: Color(0xFFFFE6C2),
      creamDim: Color(0xFFE0C39E),
      outline: Color(0xFFA89474),
      numeralBurn: Color(0xFF44290C),
      plaqueFace: Color(0xFF3F2C15),
      toastLight: Color(0xFFFFE3B2),
      toastDeep: Color(0xFF964E18),
    ),
    BakeryThemeDef(
      id: 'rye',
      name: 'Rye Crust',
      background: Color(0xFF1A1410),
      deepest: Color(0xFF120E0A),
      tray: Color(0xFF27201A),
      panel: Color(0xFF332B22),
      panelHigh: Color(0xFF40372C),
      primary: Color(0xFFE3C08A),
      honey: Color(0xFFD69A4B),
      buttonBase: Color(0xFF8A5A2E),
      cream: Color(0xFFF0DECA),
      creamDim: Color(0xFFC2AC94),
      outline: Color(0xFF8E8071),
      numeralBurn: Color(0xFF332818),
      plaqueFace: Color(0xFF2E251B),
      toastLight: Color(0xFFE8D2AC),
      toastDeep: Color(0xFF6E4426),
    ),
    BakeryThemeDef(
      id: 'caramel',
      name: 'Caramel Drizzle',
      background: Color(0xFF241207),
      deepest: Color(0xFF1B0D05),
      tray: Color(0xFF35200F),
      panel: Color(0xFF422917),
      panelHigh: Color(0xFF50311E),
      primary: Color(0xFFFFC46E),
      honey: Color(0xFFF79E2B),
      buttonBase: Color(0xFFB45E1C),
      cream: Color(0xFFFFE2BC),
      creamDim: Color(0xFFDBB893),
      outline: Color(0xFFA2876C),
      numeralBurn: Color(0xFF40200A),
      plaqueFace: Color(0xFF3B2513),
      toastLight: Color(0xFFFBD9A4),
      toastDeep: Color(0xFF8C3F12),
    ),
  ];

  static BakeryThemeDef byId(String id, {Map<String, int>? custom}) {
    if (id == 'custom' && custom != null) return _custom(custom);
    for (final t in all) {
      if (t.id == id) return t;
    }
    return all.first;
  }

  static bool isFree(String id) => id == 'custom' ? false : freeThemeIds.contains(id);

  /// [c] carries 'light' and 'deep' biscuit colors plus 'baseIdx'
  /// (index into [all] for the surrounding palette).
  static BakeryThemeDef _custom(Map<String, int> c) {
    final base = all[(c['baseIdx'] ?? 0).clamp(0, all.length - 1)];
    return BakeryThemeDef(
      id: 'custom',
      name: 'My Bake',
      background: base.background,
      deepest: base.deepest,
      tray: base.tray,
      panel: base.panel,
      panelHigh: base.panelHigh,
      primary: base.primary,
      honey: base.honey,
      buttonBase: base.buttonBase,
      cream: base.cream,
      creamDim: base.creamDim,
      outline: base.outline,
      numeralBurn: base.numeralBurn,
      plaqueFace: base.plaqueFace,
      toastLight: Color(c['light'] ?? 0xFFF1DDA8),
      toastDeep: Color(c['deep'] ?? 0xFF8A3F1E),
    );
  }
}

/// Biscuit tile styles — how each number biscuit is baked.
class TileStyleDef {
  final String id;
  final String name;
  final double cornerFactor; // 0.08 sharp .. 0.34 round
  final bool goldNumerals; // carved gold instead of burn
  final bool flourDust; // flour dusting across the face
  final bool heavyCrust; // thicker dark rim around the face
  final bool creamInk; // soft cream numerals (for dark bakes)

  const TileStyleDef({
    required this.id,
    required this.name,
    this.cornerFactor = 0.16,
    this.goldNumerals = false,
    this.flourDust = false,
    this.heavyCrust = false,
    this.creamInk = false,
  });
}

class TileStyles {
  static const List<String> freeStyleIds = [
    'classic',
    'round',
    'rustic',
    'square',
  ];

  static const List<TileStyleDef> all = [
    TileStyleDef(id: 'classic', name: 'Classic Biscuit'),
    TileStyleDef(id: 'round', name: 'Butter Round', cornerFactor: 0.34),
    TileStyleDef(id: 'rustic', name: 'Rustic Cut', cornerFactor: 0.10, heavyCrust: true),
    TileStyleDef(id: 'square', name: 'Tray Square', cornerFactor: 0.07),
    TileStyleDef(id: 'flour', name: 'Flour Dusted', flourDust: true),
    TileStyleDef(id: 'goldleaf', name: 'Gold Leaf', goldNumerals: true),
    TileStyleDef(id: 'charred', name: 'Charred Edge', heavyCrust: true, creamInk: true, cornerFactor: 0.22),
    TileStyleDef(id: 'caramel', name: 'Caramel Glaze', cornerFactor: 0.26, creamInk: true),
    TileStyleDef(id: 'sugar', name: 'Sugar Top', flourDust: true, cornerFactor: 0.30, creamInk: true),
  ];

  static TileStyleDef byId(String id) {
    for (final s in all) {
      if (s.id == id) return s;
    }
    return all.first;
  }

  static bool isFree(String id) => freeStyleIds.contains(id);
}

/// Tray accents — the baking tray's rim and well treatment.
class TrayAccentDef {
  final String id;
  final String name;
  final Color rim;
  final Color rimLight;
  final Color wellDark;

  const TrayAccentDef({
    required this.id,
    required this.name,
    required this.rim,
    required this.rimLight,
    required this.wellDark,
  });
}

class TrayAccents {
  static const List<String> freeAccentIds = [
    'walnut',
    'oak',
    'flourwhite',
    'charcoal',
  ];

  static const List<TrayAccentDef> all = [
    TrayAccentDef(
        id: 'walnut',
        name: 'Dark Walnut',
        rim: Color(0xFF413126),
        rimLight: Color(0xFFFFE2A4),
        wellDark: Color(0xFF120802)),
    TrayAccentDef(
        id: 'oak',
        name: 'Golden Oak',
        rim: Color(0xFF8A5A2E),
        rimLight: Color(0xFFFFE9B8),
        wellDark: Color(0xFF241204)),
    TrayAccentDef(
        id: 'flourwhite',
        name: 'Flour White',
        rim: Color(0xFFD4C4B5),
        rimLight: Color(0xFFFFF6E6),
        wellDark: Color(0xFF2A1D13)),
    TrayAccentDef(
        id: 'charcoal',
        name: 'Charcoal Hearth',
        rim: Color(0xFF241B14),
        rimLight: Color(0xFF9C8E81),
        wellDark: Color(0xFF0A0503)),
    TrayAccentDef(
        id: 'cherry',
        name: 'Cherry Wood',
        rim: Color(0xFF6E2F1C),
        rimLight: Color(0xFFF0A868),
        wellDark: Color(0xFF1C0C07)),
    TrayAccentDef(
        id: 'copper',
        name: 'Copper Rim',
        rim: Color(0xFFB4622D),
        rimLight: Color(0xFFFFD98F),
        wellDark: Color(0xFF201005)),
    TrayAccentDef(
        id: 'honeypine',
        name: 'Honey Pine',
        rim: Color(0xFFD9A566),
        rimLight: Color(0xFFFFEFC8),
        wellDark: Color(0xFF2E1E0C)),
    TrayAccentDef(
        id: 'roast',
        name: 'Dark Roast',
        rim: Color(0xFF3A2410),
        rimLight: Color(0xFFC97F2E),
        wellDark: Color(0xFF0F0804)),
  ];

  static TrayAccentDef byId(String id) {
    for (final a in all) {
      if (a.id == id) return a;
    }
    return all.first;
  }

  static bool isFree(String id) => freeAccentIds.contains(id);
}

/// Offline game modes. Win is at 2048 for every mode (RULES §9).
class GameModeDef {
  final String id;
  final String name;
  final int size;
  final String blurb;
  final bool free;

  const GameModeDef({
    required this.id,
    required this.name,
    required this.size,
    required this.blurb,
    required this.free,
  });
}

class GameModes {
  static const List<GameModeDef> all = [
    GameModeDef(
        id: 'classic',
        name: 'Classic Tray',
        size: 4,
        blurb: '4×4 · the original bake',
        free: true),
    GameModeDef(
        id: 'big',
        name: 'Big Batch',
        size: 5,
        blurb: '5×5 · more room to rise',
        free: false),
    GameModeDef(
        id: 'grand',
        name: 'Grand Oven',
        size: 6,
        blurb: '6×6 · a feast of biscuits',
        free: false),
  ];

  static GameModeDef byId(String id) {
    for (final m in all) {
      if (m.id == id) return m;
    }
    return all.first;
  }

  static const int winValue = 2048;
}
