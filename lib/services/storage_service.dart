import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  // SharedPreferences anahtarlarını (keys) hata yapmamak için sabit (const) olarak tanımlıyoruz.
  static const String _keySymbol = 'saved_symbol';
  static const String _keyTimeframe = 'saved_timeframe';
  static const String _keyShortMa = 'saved_short_ma';
  static const String _keyLongMa = 'saved_long_ma';
  static const String _keyStopLoss = 'saved_stop_loss';
  static const String _keyTakeProfit = 'saved_take_profit';

  // ==========================================
  // 1. SEMBOL YÖNETİMİ
  // ==========================================
  static Future<void> saveSymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySymbol, symbol);
  }

  static Future<String?> getSymbol() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySymbol);
  }

  // ==========================================
  // 2. ZAMAN DİLİMİ (TIMEFRAME) YÖNETİMİ
  // ==========================================
  static Future<void> saveTimeframe(String interval) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTimeframe, interval);
  }

  static Future<String?> getTimeframe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTimeframe);
  }

  // ==========================================
  // 3. BACKTEST PARAMETRELERİ YÖNETİMİ
  // ==========================================
  static Future<void> saveBacktestParams(int shortMa, int longMa, double stopLoss, double takeProfit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyShortMa, shortMa);
    await prefs.setInt(_keyLongMa, longMa);
    await prefs.setDouble(_keyStopLoss, stopLoss);
    await prefs.setDouble(_keyTakeProfit, takeProfit);
  }

  static Future<Map<String, num>?> getBacktestParams() async {
    final prefs = await SharedPreferences.getInstance();
    final shortMa = prefs.getInt(_keyShortMa);
    final longMa = prefs.getInt(_keyLongMa);
    final stopLoss = prefs.getDouble(_keyStopLoss);
    final takeProfit = prefs.getDouble(_keyTakeProfit);

    // Eğer tüm parametreler önceden kaydedilmişse bir Map olarak döndür
    if (shortMa != null && longMa != null && stopLoss != null && takeProfit != null) {
      return {
        'shortMa': shortMa,
        'longMa': longMa,
        'stopLoss': stopLoss,
        'takeProfit': takeProfit,
      };
    }
    return null; // Önceden bir kayıt yoksa null döner
  }
}