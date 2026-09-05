import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import '../utils/backtest_engine.dart';

// ==========================================
// LABORATUVAR EKRANI (UI Katmanı)
// ==========================================
class LaboratoryScreen extends StatefulWidget {
  final String currentSymbol;
  final List<Candle> klines;

  const LaboratoryScreen({
    super.key,
    required this.currentSymbol,
    required this.klines,
  });

  @override
  State<LaboratoryScreen> createState() => _LaboratoryScreenState();
}

class _LaboratoryScreenState extends State<LaboratoryScreen> {
  // Backtest Parametreleri (Kullanıcının girdiği state)
  double _shortMa = 5.0;
  double _longMa = 15.0;
  double _slPct = 2.0;
  double _tpPct = 4.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratuvar', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF151A22),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCurrentAssetBanner(),
              const SizedBox(height: 20),
              _buildStrategySettingsCard(),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _runBacktestAction,
                icon: const Icon(Icons.science, color: Colors.white),
                label: const Text('Stratejiyi Test Et', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentAssetBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2962FF).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Test Edilen Varlık', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(widget.currentSymbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Icon(Icons.dataset, color: Color(0xFF2962FF)),
        ],
      ),
    );
  }

  Widget _buildStrategySettingsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF151A22),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Strateji Parametreleri', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          const Divider(color: Colors.white12, height: 32),
          
          _buildSliderWithInfo(
            label: 'Kısa MA (Hareketli Ortalama)',
            value: _shortMa,
            min: 3,
            max: 50,
            onChanged: (val) => setState(() => _shortMa = val),
            infoText: 'Kısa vadeli fiyat trendini belirler. Düşük değerler fiyat hareketlerine daha hızlı tepki verir.',
          ),
          const SizedBox(height: 16),
          _buildSliderWithInfo(
            label: 'Uzun MA (Hareketli Ortalama)',
            value: _longMa,
            min: 10,
            max: 200,
            onChanged: (val) => setState(() => _longMa = val),
            infoText: 'Uzun vadeli ana trendi belirler. Kısa MA, Uzun MA\'yı yukarı kestiğinde AL sinyali üretilir.',
          ),
          const SizedBox(height: 16),
          _buildSliderWithInfo(
            label: 'Zarar Kes (Stop-Loss) %',
            value: _slPct,
            min: 0.5,
            max: 10,
            isDecimal: true,
            onChanged: (val) => setState(() => _slPct = val),
            infoText: 'İşlem tersine giderse maksimum ne kadar zararı göze alacağınızı belirler. Sermayenizi korur.',
          ),
          const SizedBox(height: 16),
          _buildSliderWithInfo(
            label: 'Kâr Al (Take-Profit) %',
            value: _tpPct,
            min: 1,
            max: 20,
            isDecimal: true,
            onChanged: (val) => setState(() => _tpPct = val),
            infoText: 'Belirlediğiniz kâr hedefine ulaşıldığında pozisyonun otomatik kapanmasını sağlar.',
          ),
        ],
      ),
    );
  }

  Widget _buildSliderWithInfo({
    required String label, 
    required double value, 
    required double min, 
    required double max, 
    required ValueChanged<double> onChanged,
    required String infoText,
    bool isDecimal = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white70)),
                const SizedBox(width: 4),
                Tooltip(
                  message: infoText,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  showDuration: const Duration(seconds: 3),
                  textStyle: const TextStyle(color: Colors.white),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2962FF).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  triggerMode: TooltipTriggerMode.tap,
                  child: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                ),
              ],
            ),
            Text(
              isDecimal ? value.toStringAsFixed(1) : value.toInt().toString(),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2962FF)),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF2962FF),
            inactiveTrackColor: const Color(0xFF0A0E17),
            thumbColor: Colors.white,
            overlayColor: const Color(0xFF2962FF).withValues(alpha: 0.2),
            trackHeight: 6.0,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: isDecimal ? ((max - min) * 10).toInt() : (max - min).toInt(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  void _runBacktestAction() {
    if (widget.klines.length <= _longMa) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uzun MA (${_longMa.toInt()}) için yeterli veri yok! Daha fazla veri bekleyin veya periyodu düşürün.'),
          backgroundColor: const Color(0xFFFF3D00),
        ),
      );
      return;
    }
    
    // Yeni izole edilmiş motorumuzu (Sadece Candle modeli ve saf matematikle) çalıştırıyoruz.
    final result = BacktestEngine.runBacktest(
      widget.klines,
      _shortMa.toInt(),
      _longMa.toInt(),
      _slPct,
      _tpPct,
    );
    
    _showBacktestResults(context, result);
  }

  void _showBacktestResults(BuildContext context, BacktestResult result) {
    final bool isProfit = result.pnlPercentage >= 0;
    final Color pnlColor = isProfit ? const Color(0xFF00E676) : const Color(0xFFFF3D00);
    final String sign = isProfit ? '+' : '';

    // Gerçek kazanma oranı: motorun kapanan işlemlerden hesapladığı değer
    final double winRate = result.winRate;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, 
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF151A22),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.analytics, color: Colors.white, size: 28),
                  const SizedBox(width: 8),
                  const Text('Performans Raporu', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: pnlColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: pnlColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Text('Net PnL (Kâr/Zarar)', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 8),
                    Text(
                      '$sign${result.pnlPercentage.toStringAsFixed(2)}%',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: pnlColor),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
              
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Kazanma Oranı', style: TextStyle(color: Colors.white70)),
                      Text('${(winRate * 100).toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: winRate,
                    backgroundColor: const Color(0xFF0A0E17),
                    color: winRate > 0.5 ? const Color(0xFF00E676) : const Color(0xFFFF3D00),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              _buildResultRow('İşlem Sayısı', '${result.totalTrades}', Colors.white),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white12, height: 1)),
              _buildResultRow('Başlangıç Bakiyesi', '\$${result.initialBalance.toStringAsFixed(2)}', Colors.white70),
              const SizedBox(height: 8),
              _buildResultRow('Bitiş Bakiyesi', '\$${result.finalBalance.toStringAsFixed(2)}', Colors.white, isBold: true),
              
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A0E17),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Kapat', style: TextStyle(color: Colors.white)),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultRow(String label, String value, Color color, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, color: Colors.white70)),
        Text(
          value, 
          style: TextStyle(fontSize: 16, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)
        ),
      ],
    );
  }
}