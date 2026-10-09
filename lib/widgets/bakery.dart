import 'dart:math';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Physical bakery UI components — pseudo-3D carved wood, wooden biscuits,
/// flour dust, warm oven light. Pressed = translate down with shrinking
/// extrusion (weight, not glow). No neon, no generic Material look.

// ================= background =================

/// Burlap backdrop: deep cocoa base, warm oven-light vignette from above,
/// faint fabric grain and slow-drifting flour dust in the air.
class FlourDustBackground extends StatelessWidget {
  final Widget child;
  const FlourDustBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(color: Merge2048Theme.background),
        // warm oven-light vignette from above
        Container(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0.0, -0.8),
              radius: 1.4,
              colors: [
                Color(0x2EF5A623), // rgba(245,166,35,.18)
                Color(0x002C1E14),
              ],
              stops: [0.0, 0.75],
            ),
          ),
        ),
        // fabric grain
        const Positioned.fill(child: _GrainSpeckles()),
        // drifting flour dust
        const Positioned.fill(child: _FlourDust()),
        child,
      ],
    );
  }
}

class _GrainSpeckles extends StatelessWidget {
  const _GrainSpeckles();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GrainPainter());
  }
}

class _GrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(1234);
    final paint = Paint()..color = const Color(0x0FF8DDCD);
    for (var i = 0; i < 260; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.6 + rnd.nextDouble() * 0.9, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FlourDust extends StatefulWidget {
  const _FlourDust();

  @override
  State<_FlourDust> createState() => _FlourDustState();
}

class _FlourDustState extends State<_FlourDust>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  final _motes = <_Mote>[];
  final _rnd = Random(77);

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < 34; i++) {
      _motes.add(_Mote(
        x: _rnd.nextDouble(),
        y: _rnd.nextDouble(),
        r: 0.8 + _rnd.nextDouble() * 1.8,
        speed: 0.008 + _rnd.nextDouble() * 0.02,
        sway: _rnd.nextDouble() * 2 * pi,
        alpha: 0.05 + _rnd.nextDouble() * 0.10,
      ));
    }
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 30))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, _) =>
          CustomPaint(painter: _DustPainter(_motes, _ctrl.value)),
    );
  }
}

class _Mote {
  final double x, y, r, speed, sway, alpha;
  _Mote(
      {required this.x,
      required this.y,
      required this.r,
      required this.speed,
      required this.sway,
      required this.alpha});
}

class _DustPainter extends CustomPainter {
  final List<_Mote> motes;
  final double t;
  _DustPainter(this.motes, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    for (final m in motes) {
      final y = ((m.y - t * m.speed * 10) % 1.0 + 1.0) % 1.0;
      final x = (m.x + sin(t * 2 * pi * 3 + m.sway) * 0.02 + 1.0) % 1.0;
      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        m.r,
        Paint()..color = Color.fromRGBO(248, 221, 205, m.alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DustPainter oldDelegate) =>
      oldDelegate.t != t;
}

// ================= wooden biscuit tile =================

/// Chunky wooden number biscuit: extruded shelf, beveled face with toast
/// shading, wood grain, pyrography-burned (or carved-gold) numeral.
class BiscuitTile extends StatelessWidget {
  final int value;
  final double size;
  const BiscuitTile({super.key, required this.value, required this.size});

  @override
  Widget build(BuildContext context) {
    final face = Merge2048Theme.faceFor(value);
    final numeralColor = Merge2048Theme.numeralFor(value);
    final digits = '$value'.length;
    final fontSize = size *
        (digits <= 2 ? 0.42 : digits == 3 ? 0.34 : digits == 4 ? 0.27 : 0.21);
    return BiscuitFace(
      size: size,
      top: face[0],
      bottom: face[1],
      numeralColor: numeralColor,
      child: Text(
        '$value',
        style: Merge2048Theme.numeral(fontSize).copyWith(
          color: numeralColor,
          shadows: [
            const Shadow(
                color: Color(0x73000000),
                offset: Offset(0, 2),
                blurRadius: 1),
            Shadow(
                color: Colors.white.withValues(alpha: 0.22),
                offset: const Offset(0, -1),
                blurRadius: 0),
          ],
        ),
      ),
    );
  }
}

/// Generic biscuit face (used by tiles and title letters).
class BiscuitFace extends StatelessWidget {
  final double size;
  final Color top;
  final Color bottom;
  final Color numeralColor;
  final Widget child;
  const BiscuitFace({
    super.key,
    required this.size,
    required this.top,
    required this.bottom,
    required this.numeralColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.16);
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // bottom extrusion shelf (5px visible below the face)
          Positioned(
            left: size * 0.03,
            right: size * 0.03,
            top: size * 0.07,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Merge2048Theme.extrusion,
                borderRadius: radius,
              ),
            ),
          ),
          // face
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: size * 0.07,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [top, bottom],
                ),
                borderRadius: radius,
                border: Border.all(
                    color: const Color(0x553A2410), width: 1),
                boxShadow: const [
                  BoxShadow(
                      color: Merge2048Theme.tileShadow,
                      blurRadius: 10,
                      offset: Offset(0, 6)),
                ],
              ),
              child: Stack(
                children: [
                  // top bevel highlight
                  Positioned.fill(
                    child: Container(
                      margin: EdgeInsets.all(size * 0.05),
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(size * 0.11),
                        border: Border(
                          top: BorderSide(
                              color: Merge2048Theme.bevelLight
                                  .withValues(alpha: 0.4),
                              width: 2),
                          left: BorderSide(
                              color: Merge2048Theme.bevelLight
                                  .withValues(alpha: 0.18),
                              width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  // wood grain
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: radius,
                      child: CustomPaint(painter: _WoodGrainPainter()),
                    ),
                  ),
                  Center(child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WoodGrainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rnd = Random(size.width.round() * 31 + size.height.round());
    final paint = Paint()
      ..color = const Color(0x143A2410)
      ..strokeWidth = 1.1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final y0 = size.height * (0.25 + 0.25 * i);
      final path = Path()..moveTo(0, y0);
      for (var x = 0.0; x <= size.width; x += 8) {
        path.lineTo(x, y0 + sin(x / size.width * pi * 2 + rnd.nextDouble()) * 2.5);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ================= buttons =================

/// Carved wooden button: honey primary with amber rim, timber secondary.
/// Press = face translates down and the extrusion shrinks (no color flash).
class WoodButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final double fontSize;
  final double? width;
  final IconData? icon;
  const WoodButton({
    super.key,
    required this.label,
    this.onTap,
    this.primary = true,
    this.fontSize = 17,
    this.width,
    this.icon,
  });

  @override
  State<WoodButton> createState() => _WoodButtonState();
}

class _WoodButtonState extends State<WoodButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final rim = widget.primary
        ? Merge2048Theme.honeyBase
        : Merge2048Theme.deepest;
    final faceTop = widget.primary
        ? Merge2048Theme.honeyButton
        : const Color(0xFF54382A);
    final faceBottom = widget.primary
        ? const Color(0xFFE0951F)
        : Merge2048Theme.timber;
    final labelColor = widget.primary
        ? Merge2048Theme.pyrography
        : Merge2048Theme.cream;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _down = false),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.width,
          padding: EdgeInsets.only(bottom: _down ? 1 : 5),
          decoration: BoxDecoration(
            color: rim,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _down
                ? null
                : const [
                    BoxShadow(
                        color: Merge2048Theme.woodShadow,
                        blurRadius: 12,
                        offset: Offset(0, 6)),
                  ],
          ),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [faceTop, faceBottom],
              ),
              borderRadius: BorderRadius.circular(13),
              border: Border(
                top: BorderSide(
                    color: Merge2048Theme.bevelLight
                        .withValues(alpha: widget.primary ? 0.5 : 0.15),
                    width: 1.5),
              ),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, color: labelColor, size: 20),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: Merge2048Theme.body(widget.fontSize,
                            color: labelColor,
                            weight: FontWeight.w800)
                        .copyWith(
                      letterSpacing: 0.8,
                      shadows: widget.primary
                          ? [
                              Shadow(
                                  color: Colors.white
                                      .withValues(alpha: 0.3),
                                  offset: const Offset(0, 1),
                                  blurRadius: 0)
                            ]
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round carved icon button (undo / new game / pause / back).
class WoodIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final String? tooltip;
  const WoodIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 46,
    this.tooltip,
  });

  @override
  State<WoodIconButton> createState() => _WoodIconButtonState();
}

class _WoodIconButtonState extends State<WoodIconButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _down = false),
      child: Opacity(
        opacity: enabled ? 1 : 0.35,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.size,
          height: widget.size,
          padding: EdgeInsets.only(bottom: _down ? 0 : 3),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Merge2048Theme.honeyBase,
          ),
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF6B4A33), Merge2048Theme.timber],
              ),
              border: Border(
                top: BorderSide(
                    color: Color(0x40FFE2A4), width: 1.5),
              ),
            ),
            child: Icon(widget.icon,
                color: Merge2048Theme.primary, size: widget.size * 0.48),
          ),
        ),
      ),
    );
  }
}

// ================= panels & signs =================

/// Raised wooden panel for settings groups.
class WoodPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const WoodPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16)});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF3D2D20), Merge2048Theme.panel],
        ),
        borderRadius: Merge2048Theme.cardRadius,
        border: Border.all(
            color: Merge2048Theme.outline.withValues(alpha: 0.35),
            width: 1.2),
        boxShadow: const [
          BoxShadow(
              color: Merge2048Theme.woodShadow,
              blurRadius: 14,
              offset: Offset(0, 6)),
        ],
      ),
      child: child,
    );
  }
}

/// Hanging wooden score plaque with twine.
class HangingPlaque extends StatelessWidget {
  final String label;
  final String value;
  final bool star; // baked-star "new best" stamp
  const HangingPlaque(
      {super.key,
      required this.label,
      required this.value,
      this.star = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 44,
          height: 16,
          child: CustomPaint(painter: _TwinePainter()),
        ),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: Merge2048Theme.plaqueFace,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                    color: Merge2048Theme.panelHigh, width: 2.5),
                boxShadow: const [
                  BoxShadow(
                      color: Merge2048Theme.woodShadow,
                      blurRadius: 8,
                      offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: Merge2048Theme.labelCaps(10)),
                  Text(value,
                      style: Merge2048Theme.body(19,
                              color: Merge2048Theme.honeyButton,
                              weight: FontWeight.w800)
                          .copyWith(
                              fontFeatures: const [
                            FontFeature.tabularFigures()
                          ])),
                ],
              ),
            ),
            if (star)
              Positioned(
                right: -10,
                top: -10,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Merge2048Theme.amber,
                    boxShadow: [
                      BoxShadow(
                          color: Merge2048Theme.woodShadow,
                          blurRadius: 4,
                          offset: Offset(0, 2)),
                    ],
                  ),
                  child: const Icon(Icons.star_rounded,
                      color: Merge2048Theme.pyrography, size: 16),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _TwinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF9C8E81)
      ..strokeWidth = 1.6;
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width * 0.15, size.height), paint);
    canvas.drawLine(Offset(size.width / 2, 0),
        Offset(size.width * 0.85, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Carved wooden sign with pyrography title (section headers, dialog titles).
class WoodSign extends StatelessWidget {
  final String title;
  final double fontSize;
  const WoodSign({super.key, required this.title, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A3826), Merge2048Theme.panel],
        ),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: Merge2048Theme.honeyBase, width: 1.5),
        boxShadow: const [
          BoxShadow(
              color: Merge2048Theme.woodShadow,
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: Merge2048Theme.display(fontSize).copyWith(
          color: Merge2048Theme.primary,
          shadows: const [
            Shadow(
                color: Color(0x80000000),
                offset: Offset(0, 2),
                blurRadius: 2),
          ],
        ),
      ),
    );
  }
}

// ================= toggles & sliders =================

/// Wooden oven-damper latch toggle.
class DamperToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const DamperToggle(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 62,
        height: 34,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: value
              ? Merge2048Theme.honeyBase
              : Merge2048Theme.deepest,
          border: Border.all(
              color: Merge2048Theme.outline.withValues(alpha: 0.4)),
          boxShadow: const [
            BoxShadow(
                color: Colors.black45,
                blurRadius: 3,
                offset: Offset(0, 2),
                spreadRadius: -1),
          ],
        ),
        alignment:
            value ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF1DDA8), Color(0xFFD9A566)],
            ),
            boxShadow: [
              BoxShadow(
                  color: Colors.black45,
                  blurRadius: 3,
                  offset: Offset(0, 2)),
            ],
          ),
          child: const Center(
            child: Icon(Icons.eco_rounded,
                size: 14, color: Merge2048Theme.pyrography),
          ),
        ),
      ),
    );
  }
}

/// Rolling-pin volume slider on a grooved wooden track.
class RollingPinSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  const RollingPinSlider(
      {super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 10,
        activeTrackColor: Merge2048Theme.honey,
        inactiveTrackColor: Merge2048Theme.deepest,
        thumbShape: const _RollingPinThumb(),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, min: 0, max: 1, onChanged: onChanged),
    );
  }
}

class _RollingPinThumb extends SliderComponentShape {
  const _RollingPinThumb();
  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(28, 28);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final c = context.canvas;
    c.drawCircle(
        center + const Offset(1, 2), 14, Paint()..color = Colors.black45);
    c.drawCircle(
        center,
        14,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF1DDA8), Color(0xFFB4622D)],
          ).createShader(Rect.fromCircle(center: center, radius: 14)));
    // rolling-pin bands
    final band = Paint()
      ..color = const Color(0x553A2410)
      ..strokeWidth = 2;
    c.drawLine(center + const Offset(-9, -4), center + const Offset(9, -4), band);
    c.drawLine(center + const Offset(-9, 4), center + const Offset(9, 4), band);
    c.drawCircle(center + const Offset(-4, -5), 3.5,
        Paint()..color = Colors.white.withValues(alpha: 0.35));
  }
}

// ================= dialog =================

/// Solid-oak bakery-sign dialog frame with corner dowel pins.
class OakDialog extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const OakDialog(
      {super.key, required this.child, this.maxWidth = 340});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4D3823), Merge2048Theme.panelHigh],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: Merge2048Theme.honeyBase, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Color(0xB3000000),
                  blurRadius: 30,
                  offset: Offset(0, 12)),
            ],
          ),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
                decoration: BoxDecoration(
                  color: Merge2048Theme.tray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.black.withValues(alpha: 0.4)),
                ),
                child: child,
              ),
              // corner dowel pins
              for (final a in [
                Alignment.topLeft,
                Alignment.topRight,
                Alignment.bottomLeft,
                Alignment.bottomRight
              ])
                Align(
                  alignment: a,
                  child: Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF1DDA8),
                          Color(0xFF8A5A2B)
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black45,
                            blurRadius: 2,
                            offset: Offset(0, 1)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dimmed warm backdrop for dialogs (75% dark cocoa).
class DialogBackdrop extends StatelessWidget {
  final Widget child;
  const DialogBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xBF170B04),
      child: child,
    );
  }
}

// ================= title =================

/// "MERGE 2048" as chunky wooden biscuit letters on a wooden shelf.
class BiscuitTitle extends StatelessWidget {
  const BiscuitTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final letter = (w - 72) / 6.4;
    final ls = letter.clamp(44.0, 62.0);
    const word1 = 'MERGE';
    const word2 = '2048';
    final faces = [
      [const Color(0xFFF1DDA8), const Color(0xFFD9A566)],
      [const Color(0xFFEBAA63), const Color(0xFFD08C4E)],
      [const Color(0xFFE08645), const Color(0xFFBC6530)],
      [const Color(0xFFD16538), const Color(0xFFA34B24)],
      [const Color(0xFFB4622D), const Color(0xFF77301A)],
    ];
    Widget row(String word, int faceOffset) => Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < word.length; i++)
              Padding(
                padding: EdgeInsets.all(ls * 0.045),
                child: BiscuitFace(
                  size: ls,
                  top: faces[(i + faceOffset) % faces.length][0],
                  bottom: faces[(i + faceOffset) % faces.length][1],
                  numeralColor: Merge2048Theme.pyrography,
                  child: Text(
                    word[i],
                    style: Merge2048Theme.display(ls * 0.52).copyWith(
                      color: Merge2048Theme.pyrography,
                      shadows: const [
                        Shadow(
                            color: Color(0x40FFFFFF),
                            offset: Offset(0, 1),
                            blurRadius: 0),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // wooden shelf plank
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF4D3823), Color(0xFF33241A)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Merge2048Theme.honeyBase, width: 1.5),
            boxShadow: const [
              BoxShadow(
                  color: Merge2048Theme.woodShadow,
                  blurRadius: 16,
                  offset: Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              row(word1, 0),
              const SizedBox(height: 4),
              row(word2, 2),
            ],
          ),
        ),
      ],
    );
  }
}

/// Small hint strip: carved wooden bar with cream text.
class HintStrip extends StatelessWidget {
  final String text;
  const HintStrip({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: Merge2048Theme.timber,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
            color: Merge2048Theme.outline.withValues(alpha: 0.35)),
        boxShadow: const [
          BoxShadow(
              color: Merge2048Theme.woodShadow,
              blurRadius: 8,
              offset: Offset(0, 4)),
        ],
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: Merge2048Theme.label(12.5)),
    );
  }
}

/// Score formatting with thousands separators: 12480 -> "12,480".
String formatScore(int n) {
  final s = '$n';
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}
