import 'package:candlesticks/candlesticks.dart';

// ==========================================
// BACKTEST SONUÇ MODELİ
// ==========================================
class BacktestResult {
  final double initialBalance;
  final double finalBalance;
  final double pnlPercentage;
  final int totalTrades;
  final int winningTrades;
  final int losingTrades;
  final int shortMa;
  final int longMa;
  final double stopLoss;
  final double takeProfit;

  /// Gerçek kazanma oranı: kazanan işlem / kapanan toplam işlem
  double get winRate {
    final closed = winningTrades + losingTrades;
    return closed > 0 ? winningTrades / closed : 0.0;
  }

  BacktestResult({
    required this.initialBalance,
    required this.finalBalance,
    required this.pnlPercentage,
    required this.totalTrades,
    required this.winningTrades,
    required this.losingTrades,
    required this.shortMa,
    required this.longMa,
    required this.stopLoss,
    required this.takeProfit,
  });
}

// ==========================================
// BACKTEST MOTORU (SAF MATEMATİK & MANTIK)
// ==========================================
class BacktestEngine {
  static BacktestResult runBacktest(
    List<Candle> data,
    int shortMaPeriod,
    int longMaPeriod,
    double stopLossPct,
    double takeProfitPct,
  ) {
    double usdtBalance = 100.0; // 100 USDT başlangıç
    double coinBalance = 0.0;
    bool inPosition = false;
    double entryPrice = 0.0;
    int totalTrades = 0;
    int winningTrades = 0;
    int losingTrades = 0;
    const double fee = 0.001; // %0.1 işlem komisyonu

    // Hesaplamanın doğru çalışması için verilerin eskiden yeniye doğru sıralı olması gerekir.
    // Dışarıdan gelen veri yeni->eski (ters sıralı) ise düzeltiyoruz.
    List<Candle> chronoData = data.toList();
    if (chronoData.isNotEmpty && chronoData.first.date.isAfter(chronoData.last.date)) {
      chronoData = chronoData.reversed.toList();
    }

    // İndikatörler için gereken minimum periyot (Örn: RSI için en az 14 şartı)
    int startIndex = longMaPeriod > 14 ? longMaPeriod : 14;
    if (chronoData.length <= startIndex) {
      return BacktestResult(
        initialBalance: usdtBalance,
        finalBalance: usdtBalance,
        pnlPercentage: 0.0,
        totalTrades: 0,
        winningTrades: 0,
        losingTrades: 0,
        shortMa: shortMaPeriod,
        longMa: longMaPeriod,
        stopLoss: stopLossPct,
        takeProfit: takeProfitPct,
      );
    }

    for (int i = startIndex; i < chronoData.length; i++) {
      double currentPrice = chronoData[i].close;

      // ==========================================
      // 1. İndikatör Hesaplamaları (SMA ve RSI)
      // ==========================================

      // Kısa ve Uzun SMA (Current ve Previous - Kesişim bulmak için)
      double sumShort = 0, prevSumShort = 0;
      for (int j = 0; j < shortMaPeriod; j++) {
        sumShort += chronoData[i - j].close;
      }
      for (int j = 0; j < shortMaPeriod; j++) {
        prevSumShort += chronoData[i - 1 - j].close;
      }
      double smaShort = sumShort / shortMaPeriod;
      double prevSmaShort = prevSumShort / shortMaPeriod;

      double sumLong = 0, prevSumLong = 0;
      for (int j = 0; j < longMaPeriod; j++) {
        sumLong += chronoData[i - j].close;
      }
      for (int j = 0; j < longMaPeriod; j++) {
        prevSumLong += chronoData[i - 1 - j].close;
      }
      double smaLong = sumLong / longMaPeriod;
      double prevSmaLong = prevSumLong / longMaPeriod;

      // RSI 14 Hesaplaması (Basit Kazanç/Kayıp Ortalaması Yöntemi)
      double gains = 0;
      double losses = 0;
      for (int j = 0; j < 14; j++) {
        double change = chronoData[i - j].close - chronoData[i - j - 1].close;
        if (change > 0) {
          gains += change;
        } else {
          losses -= change;
        }
      }
      double avgGain = gains / 14;
      double avgLoss = losses / 14;
      
      double rsi = 50.0;
      if (avgLoss == 0) {
        rsi = 100.0; // Hiç kayıp yoksa RSI 100'dür
      } else {
        double rs = avgGain / avgLoss;
        rsi = 100.0 - (100.0 / (1.0 + rs));
      }

      // ==========================================
      // 2. Alım ve Satım Şartlarının Kontrolü
      // ==========================================
      if (!inPosition) {
        bool isCrossUp = prevSmaShort <= prevSmaLong && smaShort > smaLong; // Kesişim yukarı yönlü
        if (isCrossUp && rsi > 50) {
          coinBalance = (usdtBalance * (1.0 - fee)) / currentPrice;
          usdtBalance = 0;
          entryPrice = currentPrice;
          inPosition = true;
        }
      } else {
        bool isStopLoss = currentPrice <= entryPrice * (1.0 - stopLossPct / 100); 
        bool isTakeProfit = currentPrice >= entryPrice * (1.0 + takeProfitPct / 100);
        bool isCrossDown = prevSmaShort >= prevSmaLong && smaShort < smaLong; // Kesişim aşağı yönlü

        if (isStopLoss || isTakeProfit || isCrossDown) {
          usdtBalance = (coinBalance * currentPrice) * (1.0 - fee);
          coinBalance = 0;
          inPosition = false;
          totalTrades++;
          // İşlemi kâr ile mi zarar ile mi kapattık? (komisyon hariç giriş fiyatı baz alınır)
          if (currentPrice > entryPrice) {
            winningTrades++;
          } else {
            losingTrades++;
          }
        }
      }
    }

    // Döngü sonunda hala işlem açıksa anlık fiyattan kapat (Net bakiyeyi görmek için)
    if (inPosition) {
      usdtBalance = (coinBalance * chronoData.last.close) * (1.0 - fee);
      coinBalance = 0;
      totalTrades++;
      if (chronoData.last.close > entryPrice) {
        winningTrades++;
      } else {
        losingTrades++;
      }
    }

    double pnlPercentage = ((usdtBalance - 100.0) / 100.0) * 100.0;

    return BacktestResult(
      initialBalance: 100.0,
      finalBalance: usdtBalance,
      pnlPercentage: pnlPercentage,
      totalTrades: totalTrades,
      winningTrades: winningTrades,
      losingTrades: losingTrades,
      shortMa: shortMaPeriod,
      longMa: longMaPeriod,
      stopLoss: stopLossPct,
      takeProfit: takeProfitPct,
    );
  }
}