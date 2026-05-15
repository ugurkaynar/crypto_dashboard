import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:candlesticks/candlesticks.dart';
import '../models/crypto_data.dart';

// ==========================================
// GEÇİCİ MODEL (İleride lib/models/ altına taşınabilir)
// ==========================================
class TickerData {
  final double high;
  final double low;
  final double volume;
  final double changePercent;
  final double lastPrice;

  TickerData({
    required this.high,
    required this.low,
    required this.volume,
    required this.changePercent,
    required this.lastPrice,
  });

  factory TickerData.fromJson(Map<String, dynamic> json) {
    return TickerData(
      high: double.tryParse(json['highPrice']?.toString() ?? '0') ?? 0.0,
      low: double.tryParse(json['lowPrice']?.toString() ?? '0') ?? 0.0,
      volume: double.tryParse(json['volume']?.toString() ?? '0') ?? 0.0,
      changePercent: double.tryParse(json['priceChangePercent']?.toString() ?? '0') ?? 0.0,
      lastPrice: double.tryParse(json['lastPrice']?.toString() ?? '0') ?? 0.0,
    );
  }
}

// ==========================================
// ARKA PLAN (ISOLATE) VERİ İŞLEME FONKSİYONU
// ==========================================
List<Candle> _parseKlinesBackground(String responseBody) {
  final decoded = json.decode(responseBody);
  if (decoded is List) {
    final List<Candle> candles = decoded.map((item) {
      return Candle(
        date: DateTime.fromMillisecondsSinceEpoch(int.tryParse(item[0].toString()) ?? 0),
        open: double.tryParse(item[1].toString()) ?? 0.0,
        high: double.tryParse(item[2].toString()) ?? 0.0,
        low: double.tryParse(item[3].toString()) ?? 0.0,
        close: double.tryParse(item[4].toString()) ?? 0.0,
        volume: double.tryParse(item[5].toString()) ?? 0.0,
      );
    }).toList();

    // UI tarafındaki _buildChart kısmında karmaşa yaratmamak için
    // veriyi servisten çıktığı gibi Candlesticks paketinin beklediği formatta (Ters sıralı) veriyoruz.
    return candles.reversed.toList();
  } else {
    throw Exception('Beklenmeyen veri formatı (List bekleniyordu).');
  }
}

class BinanceService {
  static const String _baseUrl = 'https://api.binance.com/api/v3';

  Future<List<Candle>> getKlines(String symbol, String interval, {int limit = 500}) async {
    final url = Uri.parse('$_baseUrl/klines?symbol=${symbol.toUpperCase()}&interval=${interval.toLowerCase()}&limit=$limit');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      // JSON ayrıştırma ve List<Candle> dönüşüm işlemlerini performansı artırmak için Isolate'e devrediyoruz
      return compute(_parseKlinesBackground, response.body);
    } else {
      throw Exception('Veri çekilemedi. Lütfen sembolü kontrol edin (örn: BTCUSDT).');
    }
  }

  Future<TickerData> getTicker24h(String symbol) async {
    final url = Uri.parse('$_baseUrl/ticker/24hr?symbol=${symbol.toUpperCase()}');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return TickerData.fromJson(json.decode(response.body));
    } else {
      throw Exception('24s özet verisi çekilemedi.');
    }
  }
}