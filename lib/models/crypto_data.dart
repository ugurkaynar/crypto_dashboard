class CryptoData {
  final DateTime timestamp;
  final double open;
  final double high;
  final double low;
  final double close;
  final double volume;

  CryptoData({
    required this.timestamp,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.volume,
  });

  factory CryptoData.fromJson(List<dynamic> json) {
    return CryptoData(
      timestamp: DateTime.fromMillisecondsSinceEpoch(int.tryParse(json[0].toString()) ?? 0),
      open: double.tryParse(json[1].toString()) ?? 0.0,
      high: double.tryParse(json[2].toString()) ?? 0.0,
      low: double.tryParse(json[3].toString()) ?? 0.0,
      close: double.tryParse(json[4].toString()) ?? 0.0,
      volume: double.tryParse(json[5].toString()) ?? 0.0,
    );
  }
}