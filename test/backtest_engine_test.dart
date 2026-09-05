import 'package:candlesticks/candlesticks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crypto_dashboard/utils/backtest_engine.dart';

/// Test yardımcıları: mum (candle) üreticiler
Candle _candle(int index, double close) {
  return Candle(
    date: DateTime(2026, 1, 1).add(Duration(hours: index)),
    open: close,
    high: close,
    low: close,
    close: close,
    volume: 100,
  );
}

/// Düz → yükselen seri (golden cross tetikler, TP vurulur)
List<Candle> _flatThenRising({
  int flat = 25,
  int rising = 25,
  double growth = 0.02,
}) {
  final list = <Candle>[];
  int i = 0;
  for (int j = 0; j < flat; j++) {
    list.add(_candle(i++, 100.0));
  }
  double price = 100.0;
  for (int j = 0; j < rising; j++) {
    price *= (1 + growth);
    list.add(_candle(i++, price));
  }
  return list;
}

/// Düz → kısa yükseliş (giriş) → düşüş (stop-loss tetikler)
List<Candle> _flatThenCrash() {
  final list = <Candle>[];
  int i = 0;
  for (int j = 0; j < 25; j++) {
    list.add(_candle(i++, 100.0));
  }
  double price = 100.0;
  for (int j = 0; j < 5; j++) {
    price *= 1.01;
    list.add(_candle(i++, price));
  }
  for (int j = 0; j < 25; j++) {
    price *= 0.96;
    list.add(_candle(i++, price));
  }
  return list;
}

void main() {
  group('BacktestEngine — temel kurallar', () {
    test('Yetersiz veri: bakiye korunur, işlem yapılmaz', () {
      final data = List.generate(10, (i) => _candle(i, 100.0 + i));

      final result = BacktestEngine.runBacktest(data, 3, 10, 2, 4);

      expect(result.totalTrades, 0);
      expect(result.winningTrades, 0);
      expect(result.losingTrades, 0);
      expect(result.finalBalance, 100.0);
      expect(result.pnlPercentage, 0.0);
      expect(result.winRate, 0.0);
    });

    test('0 işlem sonrası winRate 0.0 döner', () {
      final data = List.generate(30, (i) => _candle(i, 100.0));
      // Sabit fiyatta kesişim olmaz -> işlem olmaz

      final result = BacktestEngine.runBacktest(data, 3, 10, 2, 4);

      expect(result.totalTrades, 0);
      expect(result.winRate, 0.0);
    });
  });

  group('BacktestEngine — strateji senaryoları', () {
    test('Yükselen trend: golden cross girişi + take-profit kârı', () {
      final data = _flatThenRising();

      final result = BacktestEngine.runBacktest(data, 3, 10, 5, 5);

      expect(result.totalTrades, greaterThanOrEqualTo(1));
      expect(result.winningTrades, greaterThanOrEqualTo(1));
      expect(result.winningTrades, result.totalTrades); // kaybeden işlem olmamalı
      // Mum-bazlı simülasyon: işlem, TP eşiğini AŞAN İLK MUMUN kapanışında gerçekleşir.
      // %2'lik mumlarla TP (%5) ~%6 kârda yakalanır; 2 x %0.1 komisyon düşülür.
      expect(result.pnlPercentage, greaterThan(4.5));
      expect(result.pnlPercentage, lessThan(6.5));
      expect(result.finalBalance, greaterThan(result.initialBalance));
      expect(result.winRate, greaterThan(0.99));
    });

    test('Çöküş senaryosu: stop-loss zararı sınırlar', () {
      final data = _flatThenCrash();

      final result = BacktestEngine.runBacktest(data, 3, 10, 5, 20);

      expect(result.totalTrades, greaterThanOrEqualTo(1));
      expect(result.losingTrades, greaterThanOrEqualTo(1));
      // Komisyonlar dahil zarar: ~-%5.3 civarı (SL %5 + 2 x %0.1 komisyon)
      expect(result.pnlPercentage, lessThan(-3.5));
      expect(result.pnlPercentage, greaterThan(-8));
      expect(result.finalBalance, lessThan(result.initialBalance));
      expect(result.winRate, 0.0);
    });

    test('Girdi sırası (yeni→eski) sonucu değiştirmez', () {
      final data = _flatThenRising();
      final reversed = data.reversed.toList();

      final normal = BacktestEngine.runBacktest(data, 3, 10, 5, 5);
      final ters = BacktestEngine.runBacktest(reversed, 3, 10, 5, 5);

      expect(ters.finalBalance, normal.finalBalance);
      expect(ters.pnlPercentage, normal.pnlPercentage);
      expect(ters.totalTrades, normal.totalTrades);
      expect(ters.winningTrades, normal.winningTrades);
    });
  });

  group('BacktestEngine — sonuç modeli', () {
    test('Parametreler sonuçta aynen yansır', () {
      final data = _flatThenRising();

      final result = BacktestEngine.runBacktest(data, 7, 21, 3.5, 7.5);

      expect(result.shortMa, 7);
      expect(result.longMa, 21);
      expect(result.stopLoss, 3.5);
      expect(result.takeProfit, 7.5);
      expect(result.initialBalance, 100.0);
    });
  });
}
