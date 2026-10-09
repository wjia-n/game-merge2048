import 'package:flutter/material.dart';

/// Stitch "Artisanal Baker's Hearth" design tokens for Merge 2048.
/// Warm hearth dark: walnut tray, wooden number biscuits, flour dust,
/// warm oven light from above. No neon, no glow, no cyberpunk.
abstract final class Merge2048Theme {
  // --- palette ------------------------------------------------------------
  static const background = Color(0xFF1D1108); // app bg, tray surround
  static const deepest = Color(0xFF170B04); // deepest recesses
  static const tray = Color(0xFF2A1D13); // board / tray surface
  static const panel = Color(0xFF36271C); // raised wooden panels
  static const panelHigh = Color(0xFF413126); // dialog frames
  static const primary = Color(0xFFF7C07E); // carved gold numerals
  static const honey = Color(0xFFD9A566); // biscuit mid-tone / honey
  static const warmHighlight = Color(0xFFFFB955); // warm highlights
  static const amber = Color(0xFFDC9100); // amber depth
  static const glowSoft = Color(0xFFFFBB95); // soft warm glow accents
  static const toasted = Color(0xFFF6975D); // toasted mid accents
  static const cream = Color(0xFFF8DDCD); // primary text (warm cream)
  static const creamDim = Color(0xFFD4C4B5); // secondary text
  static const outline = Color(0xFF9C8E81); // subtle borders

  // physical material tones
  static const pyrography = Color(0xFF3A2410); // burned numeral char
  static const extrusion = Color(0xFF5A2211); // tile bottom shelf
  static const extrusionDeep = Color(0xFF77301A); // dark crust shelf
  static const plaqueFace = Color(0xFF342216); // score plaque face
  static const timber = Color(0xFF432E20); // pressed-button charcoal-brown
  static const honeyButton = Color(0xFFF5A623); // primary honey button
  static const honeyBase = Color(0xFFB4622D); // amber button base / rim
  static const bevelLight = Color(0xFFFFE2A4); // top bevel highlight
  static const error = Color(0xFFBA1A1A); // illegal-move flash only

  static const woodShadow = Color(0x99000000); // contact shadows ~0.6
  static const tileShadow = Color(0x99140C08); // tile drop shadow

  // --- biscuit toast tiers (tile value -> face top/bottom) -----------------
  // DESIGN.md §3: light golden low tiles through dark crust high tiles.
  static const Map<int, List<Color>> biscuitFace = {
    2: [Color(0xFFF1DDA8), Color(0xFFD9A566)],
    4: [Color(0xFFEEC88F), Color(0xFFDDA95F)],
    8: [Color(0xFFEBAA63), Color(0xFFD08C4E)],
    16: [Color(0xFFE89B52), Color(0xFFC9773C)],
    32: [Color(0xFFE08645), Color(0xFFBC6530)],
    64: [Color(0xFFDB7838), Color(0xFFB05628)],
    128: [Color(0xFFD16538), Color(0xFFA34B24)],
    256: [Color(0xFFC85A30), Color(0xFF8E3F1E)],
    512: [Color(0xFFB4622D), Color(0xFF77301A)],
    1024: [Color(0xFF9E4E24), Color(0xFF5E2412)],
    2048: [Color(0xFF8A3F1E), Color(0xFF4E1D0E)],
  };

  /// Face colors for any tile value; tiers above 2048 reuse the darkest crust.
  static List<Color> faceFor(int value) {
    if (biscuitFace.containsKey(value)) return biscuitFace[value]!;
    return biscuitFace[2048]!;
  }

  /// Numeral color: pyrography burn on light biscuits, carved gold on crust.
  static Color numeralFor(int value) =>
      value >= 512 ? primary : pyrography;

  // --- typography ----------------------------------------------------------
  // Domine (chunky warm serif) for display + numerals; Nunito Sans for body.
  // These resolve to the platform fallback when not installed, like the
  // Go rebuild's Noto Serif usage.
  static const serif = 'Domine';
  static const sans = 'Nunito Sans';

  static TextStyle display(double size, {FontWeight weight = FontWeight.w700}) =>
      TextStyle(
          fontFamily: serif,
          fontSize: size,
          fontWeight: weight,
          color: cream,
          height: 1.2);

  static TextStyle numeral(double size) => TextStyle(
      fontFamily: serif,
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.0);

  static TextStyle body(double size,
          {Color color = cream, FontWeight weight = FontWeight.w600}) =>
      TextStyle(
          fontFamily: sans,
          fontSize: size,
          fontWeight: weight,
          color: color,
          height: 1.45);

  static TextStyle label(double size, {Color color = creamDim}) => TextStyle(
      fontFamily: sans,
      fontSize: size,
      fontWeight: FontWeight.w600,
      color: color,
      height: 1.3);

  static TextStyle labelCaps(double size) => TextStyle(
      fontFamily: sans,
      fontSize: size,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.6,
      color: cream.withValues(alpha: 0.7),
      height: 1.2);

  // --- layout ---------------------------------------------------------------
  static const double touch = 48.0; // minimum touch target
  static const radius = Radius.circular(14);
  static const cardRadius = BorderRadius.all(Radius.circular(14));
}
