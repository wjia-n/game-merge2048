import 'package:flutter/material.dart';

import '../audio/sound.dart';
import '../state/settings.dart';
import '../theme.dart';
import '../theme/bakery_themes.dart';
import '../widgets/bakery.dart';

/// Launch splash: game logo + name, animated loading line,
/// and "Credits: WAJIHA" with the official company logo.
/// Pre-warms audio and starts menu music while showing.
class SplashScreen extends StatefulWidget {
  final SoundService sound;
  final Merge2048Settings settings;
  final VoidCallback onDone;

  const SplashScreen({
    super.key,
    required this.sound,
    required this.settings,
    required this.onDone,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    widget.sound.prewarm();
    widget.sound.setMusicMode('menu');
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    widget.onDone();
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BakeryThemes.byId(widget.settings.themeId,
        custom: widget.settings.customTheme);
    return Scaffold(
      backgroundColor: theme.background,
      body: FlourDustBackground(
        theme: theme,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: theme.primary, width: 3),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x99000000),
                      offset: Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset('assets/merge2048_logo.png',
                    fit: BoxFit.cover),
              ),
              const SizedBox(height: 22),
              Text('MERGE 2048',
                  style: Merge2048Theme.display(34).copyWith(
                    color: theme.primary,
                    letterSpacing: 2,
                  )),
              const SizedBox(height: 6),
              Text('Bake bigger biscuits!',
                  style:
                      Merge2048Theme.body(15, color: theme.creamDim)),
              const SizedBox(height: 30),
              // animated loading line
              SizedBox(
                width: 200,
                child: AnimatedBuilder(
                  animation: _loader,
                  builder: (_, _) => ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 8,
                      color: theme.deepest,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _loader.value.clamp(0.0, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: theme.honey,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 34),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Credits: ',
                      style: Merge2048Theme.labelCaps(11)
                          .copyWith(color: theme.creamDim)),
                  Text('WAJIHA',
                      style: Merge2048Theme.labelCaps(13)
                          .copyWith(color: theme.primary)),
                  const SizedBox(width: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset('assets/wajiha_logo.png',
                        width: 34, height: 34, fit: BoxFit.cover),
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
