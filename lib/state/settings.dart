import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persisted user settings + best score + mid-game save.
/// Backed by shared_preferences. Keys are prefixed `m2048_`.
class Merge2048Settings extends ChangeNotifier {
  static const _p = 'm2048_';

  bool musicOn = true;
  bool sfxOn = true;
  double musicVolume = 0.6;
  double sfxVolume = 0.8;
  bool vibration = true;
  bool undoOn = true;
  int best = 0;

  Future<void> load() async {
    final sp = await SharedPreferences.getInstance();
    musicOn = sp.getBool('${_p}musicOn') ?? true;
    sfxOn = sp.getBool('${_p}sfxOn') ?? true;
    musicVolume = sp.getDouble('${_p}musicVolume') ?? 0.6;
    sfxVolume = sp.getDouble('${_p}sfxVolume') ?? 0.8;
    vibration = sp.getBool('${_p}vibration') ?? true;
    undoOn = sp.getBool('${_p}undoOn') ?? true;
    best = sp.getInt('${_p}best') ?? 0;
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
    await sp.setInt('${_p}best', best);
  }

  void update(void Function() f) {
    f();
    _save();
    notifyListeners();
  }

  /// Record a new best score only when strictly exceeded (RULES §8).
  /// Returns true when the best actually changed.
  bool bumpBest(int score) {
    if (score > best) {
      best = score;
      _save();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> resetBest() async {
    best = 0;
    final sp = await SharedPreferences.getInstance();
    await sp.setInt('${_p}best', 0);
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
