import 'package:flutter_test/flutter_test.dart';
import 'package:merge2048/state/settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression check for the batch-1 SharedPreferences bug (2026-10-09):
///
/// Ludo stored player names via setStringList, which Android backs with an
/// UNORDERED StringSet — so name order scrambled on every app restart. The
/// MASTER_RULES.md standing rule bans setStringList for names.
///
/// Merge 2048 has a single player profile name and stores it as ONE string
/// key (`m2048_playerName`), which is order-safe by construction. These tests
/// pin that behavior: the name round-trips exactly across a rename → reload
/// cycle, never relies on an unordered list, and blank renames fall back to
/// the "Baker" default.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('player name survives a rename → reload round-trip exactly', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = Merge2048Settings();
    await settings.load();
    expect(settings.playerName, 'Baker');

    await settings.renamePlayer('Croissant Queen');
    expect(settings.playerName, 'Croissant Queen');

    // Simulate an app restart: a fresh instance reloads from the same prefs.
    final reloaded = Merge2048Settings();
    await reloaded.load();
    expect(reloaded.playerName, 'Croissant Queen');

    // Stored as a single string key — never an unordered StringList.
    final sp = await SharedPreferences.getInstance();
    expect(sp.getString('m2048_playerName'), 'Croissant Queen');
  });

  test('blank or whitespace renames fall back to "Baker"', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = Merge2048Settings();
    await settings.load();

    await settings.renamePlayer('   ');
    expect(settings.playerName, 'Baker');

    final reloaded = Merge2048Settings();
    await reloaded.load();
    expect(reloaded.playerName, 'Baker');
  });

  test('leading/trailing whitespace is trimmed on rename', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = Merge2048Settings();
    await settings.load();

    await settings.renamePlayer('  Zara  ');
    expect(settings.playerName, 'Zara');

    final reloaded = Merge2048Settings();
    await reloaded.load();
    expect(reloaded.playerName, 'Zara');
  });
}
