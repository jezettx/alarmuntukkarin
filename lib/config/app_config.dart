// ignore_for_file: avoid_print

import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  AppConfig._();

  // default awal kalau belum ada di storage
  static String pairId = 'demoPair';

  // KEY untuk di SharedPreferences
  static const String _keyPairId = 'pair_id';

  // --------------------------------------------------
  // LOAD: dipanggil sekali di awal (main.dart)
  // --------------------------------------------------
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    pairId = prefs.getString(_keyPairId) ?? 'demoPair';
    // debug optional:
    // print("DEBUG >>> AppConfig.load, pairId = $pairId");
  }

  // --------------------------------------------------
  // SAVE: kalau user ganti Pair ID
  // --------------------------------------------------
  static Future<void> savePairId(String value) async {
    pairId = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPairId, value);
    // print("DEBUG >>> AppConfig.savePairId, pairId = $pairId");
  }
}
