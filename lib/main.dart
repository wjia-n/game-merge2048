import 'package:flutter/material.dart';

import 'audio/sound.dart';
import 'screens/game_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/settings_screen.dart';
import 'state/game.dart';
import 'state/settings.dart';
import 'theme.dart';

void main() => runApp(const Merge2048App());

enum _Nav { menu, game, settings }

/// Merge 2048 — artisanal bakery 2048.
/// Navigation is a tiny explicit state machine; screens are views over
/// [Merge2048Settings] and [Merge2048Game].
class Merge2048App extends StatefulWidget {
  const Merge2048App({super.key});

  @override
  State<Merge2048App> createState() => _Merge2048AppState();
}

class _Merge2048AppState extends State<Merge2048App>
    with WidgetsBindingObserver {
  late final Merge2048Settings settings;
  late final SoundService sound;
  late final Merge2048Game game;

  _Nav _nav = _Nav.menu;
  _Nav _settingsReturn = _Nav.menu;
  bool _hasSave = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    settings = Merge2048Settings();
    sound = SoundService();
    game = Merge2048Game(settings: settings, sound: sound);
    WidgetsBinding.instance.addObserver(this);
    _boot();
  }

  Future<void> _boot() async {
    await settings.load();
    await sound.init();
    sound.applySettings(
        sfxOn: settings.sfxOn,
        musicOn: settings.musicOn,
        sfxVolume: settings.sfxVolume,
        musicVolume: settings.musicVolume);
    sound.setMusicMode('menu');
    _hasSave = await settings.loadSavedGame() != null;
    if (mounted) setState(() => _ready = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // RULES edge 6: backgrounding freezes the board and persists the run.
    if (state == AppLifecycleState.paused) {
      game.pauseGame();
    } else if (state == AppLifecycleState.resumed) {
      if (_nav == _Nav.game) game.resumeGame();
    }
  }

  // ---- navigation helpers ----

  Future<void> _goMenu() async {
    game.pauseGame(); // freeze + persist any live run
    _hasSave = await settings.loadSavedGame() != null;
    sound.setMusicMode('menu');
    if (mounted) setState(() => _nav = _Nav.menu);
  }

  void _onPlay() {
    game.resumeGame();
    sound.setMusicMode('game');
    setState(() => _nav = _Nav.game);
  }

  Future<void> _onResume() async {
    final saved = await settings.loadSavedGame();
    if (saved != null && game.restore(saved)) {
      sound.setMusicMode('game');
      setState(() => _nav = _Nav.game);
    } else {
      _goMenu();
    }
  }

  void _openSettings(_Nav from) {
    setState(() {
      _settingsReturn = from;
      _nav = _Nav.settings;
    });
  }

  void _closeSettings() {
    setState(() => _nav = _settingsReturn);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    sound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Merge 2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Merge2048Theme.background,
        colorScheme: ColorScheme.fromSeed(
            seedColor: Merge2048Theme.honeyBase,
            brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: !_ready
          ? const Scaffold(
              backgroundColor: Merge2048Theme.background,
              body: Center(
                  child: CircularProgressIndicator(
                      color: Merge2048Theme.honeyButton)),
            )
          : _screen(),
    );
  }

  Widget _screen() {
    switch (_nav) {
      case _Nav.menu:
        return MenuScreen(
          settings: settings,
          sound: sound,
          game: game,
          hasSave: _hasSave && !game.over,
          onPlay: _onPlay,
          onResume: _onResume,
          onOpenSettings: () => _openSettings(_Nav.menu),
        );
      case _Nav.game:
        return GameScreen(
          game: game,
          settings: settings,
          sound: sound,
          onOpenSettings: () => _openSettings(_Nav.game),
          onQuitToMenu: _goMenu,
        );
      case _Nav.settings:
        return SettingsScreen(
          settings: settings,
          sound: sound,
          onBack: _closeSettings,
        );
    }
  }
}
