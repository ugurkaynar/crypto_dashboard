/// Binance 24 saatlik ticker özeti (fiyat, hacim, değişim)
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
