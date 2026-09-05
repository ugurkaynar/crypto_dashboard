# 🪙 Crypto Dashboard — Live Charts & Algorithmic Backtesting

A Flutter application that turns live Binance market data into an interactive analysis workspace: real-time candlestick charts, 24h market stats, and a built-from-scratch **backtest engine** for testing MA-crossover strategies with Stop-Loss / Take-Profit risk management.

> 🔗 **Live Demo:** [crypto-dashboard-two-ecru.vercel.app](https://crypto-dashboard-two-ecru.vercel.app)

## ✨ Features

- 📊 **Live candlestick charts** — real-time klines streamed from the Binance REST API with selectable timeframes (15m → 1M)
- 📈 **Market radar** — 24h high/low, volume and price-change summary per asset
- ⚙️ **Backtest engine** — simulate SMA crossover strategies (short/long MA, RSI confirmation) with configurable Stop-Loss & Take-Profit over historical data
- 🎯 **Real performance metrics** — net PnL, final balance, trade count and **win rate computed from actual closed trades** (0.1% fee per trade included)
- 💾 **Offline-first** — selected asset, timeframe and strategy parameters persist on-device via `shared_preferences`
- 🧪 **Unit tested** — the strategy engine is covered by scenario tests (golden-cross entry, take-profit, stop-loss, input-order invariance)

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart), Material 3 dark theme |
| Architecture | Clean Architecture + MVVM (ViewModel / ChangeNotifier) |
| Charts | `candlesticks` package |
| Networking | Binance REST API via `http`, JSON parsing off the UI thread (`compute` / isolate) |
| Persistence | `shared_preferences` |
| Testing | `flutter_test` |
| Deployment | Flutter Web, hosted on Vercel |

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.x

### Run locally

```bash
git clone https://github.com/ugurkaynar/crypto_dashboard.git
cd crypto_dashboard

flutter pub get

# Chrome'da çalıştır
flutter run -d chrome

# veya release web build'i üret
flutter build web --release
```

### Run the tests

```bash
flutter test
```

## 🧠 How the Backtest Engine Works

`lib/utils/backtest_engine.dart` is pure Dart with no UI dependencies, which makes it fully unit-testable:

1. **Signals** — a long position opens when the short SMA crosses above the long SMA (golden cross) while RSI(14) > 50
2. **Risk management** — the position closes on Stop-Loss, Take-Profit or a bearish SMA cross, whichever hits first
3. **Realism** — a 0.1% commission is applied to every fill; candle order (old→new vs new→old) is auto-detected
4. **Metrics** — net PnL (%), final balance, number of trades, and win/loss counts are derived from simulated fills only — no hardcoded estimates

Tweak the sliders on the **Laboratuvar** tab and hit *“Stratejiyi Test Et”* to simulate a strategy on the currently loaded chart data.

## 📁 Project Structure

```
lib/
├── main.dart                      # App entry & theming
├── models/
│   ├── ticker_data.dart           # 24h ticker model
│   └── ...
├── screens/
│   ├── dashboard_screen.dart      # Dashboard + Market screen (ViewModel)
│   └── laboratory_screen.dart     # Strategy lab UI
├── services/
│   ├── binance_service.dart       # Binance REST client (isolate parsing)
│   └── storage_service.dart       # Offline persistence
└── utils/
    └── backtest_engine.dart       # Strategy engine (pure Dart)

test/
└── backtest_engine_test.dart      # Engine scenario tests
```

## 📄 License

MIT — see the [LICENSE](LICENSE) file.
