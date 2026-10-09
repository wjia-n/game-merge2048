import 'package:flutter/material.dart';

import 'audio/sound.dart';
import 'screens/game_screen.dart';
import 'screens/menu_screen.dart';
import 'screens/pro_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/theme_screen.dart';
import 'services/iap_service.dart';
import 'state/game.dart';
import 'state/settings.dart';
import 'theme/bakery_themes.dart';

void main() => runApp(const Merge2048App());

enum _Nav { splash, menu, game, settings, themes, pro }

/// Merge 2048 — artisanal bakery 2048.
/// Navigation is a tiny explicit state machine; screens are views over
/// [Merge2048Settings], [Merge2048Game] and [BakeryStore].
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
  late final BakeryStore store;

  _Nav _nav = _Nav.splash;
  _Nav _settingsReturn = _Nav.menu;
  bool _hasSave = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    settings = Merge2048Settings();
    sound = SoundService();
    store = BakeryStore();
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
    // store init is best-effort and never blocks the game
    store.init().catchError((_) {});
    _hasSave = await settings.loadSavedGame() != null;
    if (mounted) setState(() => _ready = true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // RULES edge 6: backgrounding freezes the board and persists the run.
    // Music pauses (not stops) so it resumes exactly where it left off.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      game.pauseGame();
      sound.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      sound.onAppResumed();
      if (_nav == _Nav.game) game.resumeGame();
    }
  }

  // ---- navigation helpers ----

  void _splashDone() {
    if (mounted) setState(() => _nav = _Nav.menu);
  }

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
      // resume adopts the saved run's mode
      settings.update(() => settings.modeId = game.modeId);
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

  void _openThemes(_Nav from) {
    setState(() {
      _settingsReturn = from;
      _nav = _Nav.themes;
    });
  }

  void _closeThemes() {
    setState(() => _nav = _settingsReturn);
  }

  void _openPro(_Nav from) {
    setState(() {
      _settingsReturn = from;
      _nav = _Nav.pro;
    });
  }

  void _closePro() {
    setState(() => _nav = _settingsReturn);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    game.dispose();
    sound.dispose();
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = BakeryThemes.byId(settings.themeId,
        custom: settings.customTheme);
    return MaterialApp(
      title: 'Merge 2048',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: theme.background,
        colorScheme: ColorScheme.fromSeed(
            seedColor: theme.honey, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: !_ready
          ? Scaffold(
              backgroundColor: theme.background,
              body: const Center(child: SizedBox.shrink()),
            )
          : _screen(),
    );
  }

  Widget _screen() {
    switch (_nav) {
      case _Nav.splash:
        return SplashScreen(
          sound: sound,
          settings: settings,
          onDone: _splashDone,
        );
      case _Nav.menu:
        return MenuScreen(
          settings: settings,
          sound: sound,
          game: game,
          store: store,
          hasSave: _hasSave && !game.over,
          onPlay: _onPlay,
          onResume: _onResume,
          onOpenSettings: () => _openSettings(_Nav.menu),
          onOpenThemes: () => _openThemes(_Nav.menu),
          onOpenPro: () => _openPro(_Nav.menu),
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
          store: store,
          onBack: _closeSettings,
          onOpenThemes: () => _openThemes(_Nav.settings),
          onOpenPro: () => _openPro(_Nav.settings),
        );
      case _Nav.themes:
        return ThemeScreen(
          settings: settings,
          sound: sound,
          store: store,
          onBack: _closeThemes,
          onOpenPro: () => _openPro(_Nav.themes),
        );
      case _Nav.pro:
        return ProScreen(
          settings: settings,
          sound: sound,
          store: store,
          onBack: _closePro,
        );
    }
  }
}
