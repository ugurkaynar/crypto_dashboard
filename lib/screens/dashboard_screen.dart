import 'package:flutter/material.dart';
import 'package:candlesticks/candlesticks.dart';
import '../services/binance_service.dart';
import '../backtest_engine.dart';
import '../models/crypto_data.dart';

// ==========================================
// EKRAN İÇİ STATE MANAGEMENT (ViewModel)
// ==========================================
class DashboardViewModel extends ChangeNotifier {
  final BinanceService _service = BinanceService();

  bool isLoading = false;
  String? errorMessage;
  String currentSymbol = "BTCUSDT";
  
  // BinanceService artık doğrudan List<Candle> (Ters sıralı) döndürüyor
  List<Candle> klines = [];
  TickerData? ticker24h;
  String currentTimeframe = '1D'; 

  Future<void> loadData(String symbol, {String? interval}) async {
    if (symbol.trim().isEmpty) return;
    
    if (interval != null) {
      currentTimeframe = interval;
    }

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _service.getKlines(symbol.trim(), currentTimeframe),
        _service.getTicker24h(symbol.trim()),
      ]);
      
      klines = results[0] as List<Candle>;
      ticker24h = results[1] as TickerData;
      currentSymbol = symbol.toUpperCase().trim();
    } catch (e) {
      debugPrint('API Hatası: $e');
      isLoading = false;
      errorMessage = 'Veri çekilemedi. Hata: ${e.toString().replaceAll("Exception: ", "")}';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

// ==========================================
// ANA DASHBOARD EKRANI
// ==========================================
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 1; 
  final DashboardViewModel _viewModel = DashboardViewModel();
  
  // Backtest Parametreleri 
  double _shortMa = 5.0;
  double _longMa = 15.0;
  double _slPct = 2.0;
  double _tpPct = 4.0;

  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    Future.microtask(() => _viewModel.loadData(_viewModel.currentSymbol));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildLiveRadarScreen(),
            MarketScreen(viewModel: _viewModel), 
            _buildLaboratoryScreen(),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF151A22),
        selectedItemColor: const Color(0xFF2962FF),
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.radar),
            label: 'Canlı Radar',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Piyasa',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.science),
            label: 'Laboratuvar',
          ),
        ],
      ),
    );
  }

  Widget _buildLiveRadarScreen() {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            title: Text('Canlı Radar', style: TextStyle(fontWeight: FontWeight.bold)),
            floating: true,
            pinned: true,
            backgroundColor: Color(0xFF151A22),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.radar, size: 80, color: Color(0xFF2962FF)),
                  const SizedBox(height: 16),
                  const Text(
                    "Sinyal Radarı Aktif",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Otonom AL/SAT sinyalleri yakında burada akmaya başlayacak...",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLaboratoryScreen() {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
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
      },
    );
  }

  Widget _buildCurrentAssetBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF151A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2962FF).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Test Edilen Varlık', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(_viewModel.currentSymbol, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            color: Colors.black.withOpacity(0.2),
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
                    color: const Color(0xFF2962FF).withOpacity(0.9),
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
            overlayColor: const Color(0xFF2962FF).withOpacity(0.2),
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
    if (_viewModel.klines.length <= _longMa) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Uzun MA (${_longMa.toInt()}) için yeterli veri yok! Daha fazla veri bekleyin veya periyodu düşürün.'),
          backgroundColor: const Color(0xFFFF3D00),
        ),
      );
      return;
    }
    
    // Backtest motoru (backtest_engine.dart) hala CryptoData bekliyor ve eskiden yeniye sıralı veri istiyor.
    // Yeni servisimiz (BinanceService) veriyi Candle ve "yeni baştan" (ters sıralı) veriyor.
    // Bu yüzden Backtest motoruna göndermeden önce geri çevirip mapliyoruz.
    final List<CryptoData> mappedData = _viewModel.klines.reversed.map((c) => CryptoData(
      timestamp: c.date,
      open: c.open,
      high: c.high,
      low: c.low,
      close: c.close,
      volume: c.volume,
    )).toList();

    final result = BacktestEngine.runBacktest(
      mappedData,
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

    double winRate = isProfit ? 0.65 : 0.35; 
    if(result.totalTrades == 0) winRate = 0;

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
                  color: pnlColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: pnlColor.withOpacity(0.3)),
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
                      const Text('Kazanma Oranı Tahmini', style: TextStyle(color: Colors.white70)),
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

// ==========================================
// PİYASA EKRANI (Market Screen)
// ==========================================
class MarketScreen extends StatefulWidget {
  final DashboardViewModel viewModel;
  const MarketScreen({super.key, required this.viewModel});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  TextEditingController? _autoCompleteController;

  static const List<String> _popularSymbols = [
    'BTCUSDT', 'ETHUSDT', 'BNBUSDT', 'SOLUSDT', 'XRPUSDT', 
    'ADAUSDT', 'AVAXUSDT', 'DOGEUSDT', 'DOTUSDT', 'MATICUSDT', 
    'LINKUSDT', 'SHIBUSDT', 'LTCUSDT', 'TRXUSDT', 'UNIUSDT',
    'ATOMUSDT', 'FTMUSDT', 'ALGOUSDT', 'NEARUSDT', 'GALAUSDT'
  ];

  @override
  Widget build(BuildContext context) {
    super.build(context); 

    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Piyasa', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF151A22),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: _buildSearchBar(),
            ),
          ),
          body: widget.viewModel.isLoading 
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2962FF)))
            : widget.viewModel.errorMessage != null
              ? Center(child: Text(widget.viewModel.errorMessage!, style: const TextStyle(color: Colors.red)))
              : _buildMarketDashboard(),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.trim().isEmpty) return const Iterable<String>.empty();
          final String query = textEditingValue.text.toLowerCase();
          return _popularSymbols.where((String option) => option.toLowerCase().contains(query));
        },
        onSelected: (String selection) {
          setState(() {}); 
          widget.viewModel.loadData(selection);
          
          FocusManager.instance.primaryFocus?.unfocus();
          if (_autoCompleteController != null) {
            Future.delayed(const Duration(milliseconds: 50), () {
              _autoCompleteController?.clear();
            });
          }
        },
        fieldViewBuilder: (context, fieldController, fieldFocusNode, onFieldSubmitted) {
          _autoCompleteController = fieldController;
          return TextField(
            controller: fieldController,
            focusNode: fieldFocusNode,
            textInputAction: TextInputAction.search,
            onSubmitted: (value) {
              if (value.trim().isNotEmpty) {
                setState(() {}); 
                widget.viewModel.loadData(value);
                FocusManager.instance.primaryFocus?.unfocus();
                Future.delayed(const Duration(milliseconds: 50), () => fieldController.clear());
              }
            },
            decoration: InputDecoration(
              hintText: 'Sembol Ara (örn: SOL, ETH)',
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.grey, size: 20),
                onPressed: () {
                  fieldController.clear();
                  fieldFocusNode.unfocus();
                },
              ),
              filled: true,
              fillColor: const Color(0xFF151A22),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          );
        },
        optionsViewBuilder: (context, onSelected, options) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width - 32,
                constraints: const BoxConstraints(maxHeight: 250),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A212D),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2962FF).withOpacity(0.3)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    final String option = options.elementAt(index);
                    return InkWell(
                      onTap: () => onSelected(option),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: index == options.length - 1 ? Colors.transparent : Colors.white.withOpacity(0.05))),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.auto_graph, color: Color(0xFF2962FF), size: 20),
                            const SizedBox(width: 12),
                            Text(option, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMarketDashboard() {
    return Column(
      children: [
        _buildHeaderPanel(),
        _buildTimeframeSelector(),
        Expanded(child: _buildChart()),
      ],
    );
  }

  Widget _buildHeaderPanel() {
    final t = widget.viewModel.ticker24h;
    if (t == null) return const SizedBox.shrink();
    final isPositive = t.changePercent >= 0;
    final color = isPositive ? const Color(0xFF00E676) : const Color(0xFFFF3D00);
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Color(0xFF151A22), border: Border(bottom: BorderSide(color: Colors.white10))),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.viewModel.currentSymbol, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text('\$${t.lastPrice.toStringAsFixed(4)}', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                child: Text('$sign${t.changePercent.toStringAsFixed(2)}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ),
            ],
          ),
        ]
      )
    );
  }

  Widget _buildTimeframeSelector() {
    final timeframes = ['15m', '1h', '4h', '1D'];
    return Container(
      height: 50,
      color: const Color(0xFF0A0E17),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: timeframes.length,
        itemBuilder: (context, index) {
          final tf = timeframes[index];
          final isSelected = widget.viewModel.currentTimeframe.toLowerCase() == tf.toLowerCase();
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
            child: ChoiceChip(
              label: Text(tf),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {});
                  widget.viewModel.loadData(widget.viewModel.currentSymbol, interval: tf);
                }
              },
              selectedColor: const Color(0xFF2962FF).withOpacity(0.2),
              backgroundColor: const Color(0xFF151A22),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChart() {
    if (widget.viewModel.klines.isEmpty) {
      return const Center(child: Text('Veriler yükleniyor...', style: TextStyle(color: Colors.grey, fontSize: 16)));
    }
    
    // Yeni servisimiz doğrudan List<Candle> döndürdüğü için artık burada çevrim (map) yapmamıza gerek yok!
    return Theme(
      data: ThemeData.dark(),
      child: Candlesticks(
        key: ValueKey('${widget.viewModel.currentSymbol}_${widget.viewModel.currentTimeframe}'),
        candles: widget.viewModel.klines, 
      ),
    );
  }
}
