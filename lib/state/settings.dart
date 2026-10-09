import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings, profile, best scores, run history,
/// customization, and mid-game save. Keys prefixed `m2048_`.
class Merge2048Settings extends ChangeNotifier {
  static const _p = 'm2048_';

  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.6;
  double sfxVolume = 0.8;
  bool vibration = true;
  bool undoOn = true;

  // ---- player profile ----
  String playerName = 'Baker';

  // ---- mode ----
  String modeId = 'classic';

  // ---- per-mode best scores ----
  Map<String, int> bests = {};

  /// Best for the currently selected mode.
  int get best => bests[modeId] ?? 0;

  int bestFor(String m) => bests[m] ?? 0;

  // ---- run history (newest first, capped) ----
  static const historyCap = 50;
  List<Map<String, dynamic>> history = [];

  // ---- customization ----
  String themeId = 'classic';
  String tileStyleId = 'classic';
  String trayAccentId = 'walnut';
  Map<String, int> customTheme = {}; // 'baseIdx','light','deep'

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    musicOn = sp.getBool('${_p}musicOn') ?? true;
    sfxOn = sp.getBool('${_p}sfxOn') ?? true;
    musicVolume = sp.getDouble('${_p}musicVolume') ?? 0.6;
    sfxVolume = sp.getDouble('${_p}sfxVolume') ?? 0.8;
    vibration = sp.getBool('${_p}vibration') ?? true;
    undoOn = sp.getBool('${_p}undoOn') ?? true;
    playerName = sp.getString('${_p}playerName') ?? 'Baker';
    modeId = sp.getString('${_p}modeId') ?? 'classic';
    themeId = sp.getString('${_p}themeId') ?? 'classic';
    tileStyleId = sp.getString('${_p}tileStyleId') ?? 'classic';
    trayAccentId = sp.getString('${_p}trayAccentId') ?? 'walnut';
    try {
      final rawBest = sp.getString('${_p}bests');
      if (rawBest != null) {
        bests = (jsonDecode(rawBest) as Map)
            .map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      } else {
        // migrate legacy single best into the classic mode slot
        final legacy = sp.getInt('${_p}best') ?? 0;
        if (legacy > 0) bests = {'classic': legacy};
      }
      final rawHist = sp.getString('${_p}history');
      if (rawHist != null) {
        history = (jsonDecode(rawHist) as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      }
      final rawCustom = sp.getString('${_p}customTheme');
      if (rawCustom != null) {
        customTheme = (jsonDecode(rawCustom) as Map)
            .map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
      }
    } catch (_) {
      // corrupt prefs never block the game
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('${_p}musicOn', musicOn);
    await sp.setBool('${_p}sfxOn', sfxOn);
    await sp.setDouble('${_p}musicVolume', musicVolume);
    await sp.setDouble('${_p}sfxVolume', sfxVolume);
    await sp.setBool('${_p}vibration', vibration);
    await sp.setBool('${_p}undoOn', undoOn);
    await sp.setString('${_p}playerName', playerName);
    await sp.setString('${_p}modeId', modeId);
    await sp.setString('${_p}themeId', themeId);
    await sp.setString('${_p}tileStyleId', tileStyleId);
    await sp.setString('${_p}trayAccentId', trayAccentId);
    await sp.setString('${_p}bests', jsonEncode(bests));
    await sp.setString('${_p}history', jsonEncode(history));
    await sp.setString('${_p}customTheme', jsonEncode(customTheme));
  }

  void update(void Function() f) {
    f();
    _save();
    notifyListeners();
  }

  /// Record a new best score for the current mode only when strictly
  /// exceeded (RULES §8). Returns true when the best actually changed.
  bool bumpBest(int score) {
    final cur = bests[modeId] ?? 0;
    if (score > cur) {
      bests[modeId] = score;
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> resetBest() async {
    bests[modeId] = 0;
    await _save();
    notifyListeners();
  }

  /// Append a finished run to the history (newest first, capped at 50).
  void recordRun({required int score, required int maxTile}) {
    history.insert(0, {
      'mode': modeId,
      'score': score,
      'maxTile': maxTile,
      'at': DateTime.now().toIso8601String(),
    });
    if (history.length > historyCap) {
      history = history.sublist(0, historyCap);
    }
    _save();
    notifyListeners();
  }

  /// Rename the player profile. Empty/whitespace falls back to "Baker".
  void renamePlayer(String name) {
    final clean = name.trim();
    playerName = clean.isEmpty ? 'Baker' : clean;
    _save();
    notifyListeners();
  }

  // ---------------- mid-game save / resume ----------------

  /// Serializes a live run so it survives app restarts (RULES §7, edge 6).
  Future<void> saveGame(Map<String, Object?> data) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString('${_p}savedGame', jsonEncode(data));
  }

  Future<Map<String, dynamic>?> loadSavedGame() async {
    final sp = await SharedPreferences.getInstance();
    final raw = sp.getString('${_p}savedGame');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearSavedGame() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove('${_p}savedGame');
  }
}
