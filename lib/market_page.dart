import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:developer';

@HiveType(typeId: 0)
class MarketData extends HiveObject {
  @HiveField(0)
  final String symbol;
  @HiveField(1)
  final double price;
  @HiveField(2)
  final double change;
  @HiveField(3)
  final double changePercent;
  @HiveField(4)
  final List<double> historicalPrices;
  @HiveField(5)
  final DateTime lastUpdated;

  MarketData({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.historicalPrices,
    required this.lastUpdated,
  });
}

class MarketDataAdapter extends TypeAdapter<MarketData> {
  @override
  final int typeId = 0;

  @override
  MarketData read(BinaryReader reader) {
    return MarketData(
      symbol: reader.read(),
      price: reader.read(),
      change: reader.read(),
      changePercent: reader.read(),
      historicalPrices: List<double>.from(reader.read()),
      lastUpdated: reader.read(),
    );
  }

  @override
  void write(BinaryWriter writer, MarketData obj) {
    writer.write(obj.symbol);
    writer.write(obj.price);
    writer.write(obj.change);
    writer.write(obj.changePercent);
    writer.write(obj.historicalPrices);
    writer.write(obj.lastUpdated);
  }
}

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> marketCategories = ['Stocks', 'Crypto', 'Forex'];
  final Map<String, List<MarketData>> marketData = {
    'Stocks': [],
    'Crypto': [],
    'Forex': [],
  };
  late final Box<MarketData> _cacheBox;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: marketCategories.length, vsync: this);
    _initCache();
  }

  Future<void> _initCache() async {
    _cacheBox = Hive.box<MarketData>('marketData');
    await _fetchInitialData();
    setState(() => _isLoading = false);
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchData('Stocks', ['AAPL', 'MSFT', 'TSLA', 'GOOGL'], _fetchStockData),
      _fetchData('Crypto', ['bitcoin', 'ethereum', 'dogecoin', 'cardano', 'solana'], _fetchCryptoData),
      _fetchData('Forex', ['EUR/INR', 'USD/INR', 'GBP/INR', 'JPY/INR', 'AUD/INR'], _fetchForexData),
    ]);
  }

  Future<void> _fetchData(String category, List<String> symbols, Function fetcher) async {
    final now = DateTime.now();
    for (String symbol in symbols) {
      final cached = _cacheBox.get('$category-$symbol');
      if (cached != null && now.difference(cached.lastUpdated).inMinutes < 10) {
        setState(() => marketData[category]!.add(cached));
      } else {
        await fetcher(symbol);
      }
    }
  }

 Future<void> _fetchStockData(String symbol) async {
  const apiKey = 'ef87df33cbmsh310a583bffffb57p1cb9d7jsn4f235f7908af';
  const apiHost = 'yahoo-finance15.p.rapidapi.com';

  try {
    final response = await http.get(
      Uri.https(apiHost, '/api/v1/markets/stock/history', {
        'symbol': symbol,
        'interval': '5m',
        'diffandsplits': 'false',
      }),
      headers: {
        'X-RapidAPI-Key': apiKey,
        'X-RapidAPI-Host': apiHost,
      },
    );

    log('API Response for $symbol: ${response.body}'); // Debug log

    if (response.statusCode == 200) {
      final jsonData = jsonDecode(response.body);
      final items = (jsonData['items'] as List<dynamic>?) ?? [];

      if (items.isEmpty) {
        log('No historical data for $symbol');
        return;
      }

      // Extract and sort historical prices by timestamp
      final historicalData = items.map((item) {
        return {
          'timestamp': item['date_utc'] as int? ?? 0,
          'close': (item['close'] as num?)?.toDouble() ?? 0.0,
        };
      }).toList()
        ..sort((a, b) => (a['timestamp'] ?? 0).compareTo(b['timestamp'] ?? 0));

      final historicalPrices = historicalData
          .map<double>((item) => item['close'] as double)
          .toList();

      if (historicalPrices.length >= 2) {
        final currentPrice = historicalPrices.last;
        final previousPrice = historicalPrices[historicalPrices.length - 2];
        final change = currentPrice - previousPrice;
        final changePercent = (change / previousPrice) * 100;

        _cacheData(
          'Stocks',
          symbol,
          MarketData(
            symbol: symbol,
            price: currentPrice,
            change: change,
            changePercent: changePercent,
            historicalPrices: historicalPrices,
            lastUpdated: DateTime.now(),
          ),
        );
      } else {
        log('Insufficient data points for $symbol');
      }
    } else {
      log('API Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    log('Error fetching stock data: $e');
  }
}
  Future<void> _fetchCryptoData(String id) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/coins/$id/market_chart?vs_currency=usd&days=7'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final prices = jsonData['prices'] as List<dynamic>;
        final historicalPrices = prices.map<double>((price) => price[1].toDouble()).toList();
        
        if (historicalPrices.length >= 2) {
          final currentPrice = historicalPrices.last;
          final previousPrice = historicalPrices[historicalPrices.length - 2];
          _cacheData(
            'Crypto',
            id,
            MarketData(
              symbol: id.toUpperCase(),
              price: currentPrice,
              change: currentPrice - previousPrice,
              changePercent: ((currentPrice - previousPrice) / previousPrice) * 100,
              historicalPrices: historicalPrices,
              lastUpdated: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      log('Error fetching crypto data: $e');
    }
  }

  Future<void> _fetchForexData(String pair) async {
    const apiKey = 'ef87df33cbmsh310a583bffffb57p1cb9d7jsn4f235f7908af';
    const apiHost = 'alpha-vantage.p.rapidapi.com';

    try {
      final currencies = pair.split('/');
      final response = await http.get(
        Uri.https(apiHost, '/query', {
          'function': 'FX_INTRADAY',
          'from_symbol': currencies[0],
          'to_symbol': currencies[1],
          'interval': '5min',
          'datatype': 'json',
          'outputsize': 'compact',
        }),
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': apiHost,
        },
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final timeSeries = jsonData['Time Series FX (5min)'] as Map<String, dynamic>;
        final closingPrices = timeSeries.entries
            .take(30)
            .map((entry) => double.parse(entry.value['4. close']))
            .toList();

        if (closingPrices.length >= 2) {
          final currentPrice = closingPrices.last;
          final previousPrice = closingPrices[closingPrices.length - 5];
          _cacheData(
            'Forex',
            pair,
            MarketData(
              symbol: pair,
              price: currentPrice,
              change: currentPrice - previousPrice,
              changePercent: ((currentPrice - previousPrice) / previousPrice) * 100,
              historicalPrices: closingPrices,
              lastUpdated: DateTime.now(),
            ),
          );
        }
      }
    } catch (e) {
      log('Error fetching forex data: $e');
    }
  }

  void _cacheData(String category, String symbol, MarketData data) {
    final key = '$category-$symbol';
    _cacheBox.put(key, data);
    setState(() => marketData[category]!.add(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Market Data'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: marketCategories.map((category) => Tab(text: category)).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: marketCategories.map((category) {
                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: marketData[category]!.length,
                  itemBuilder: (context, index) => _MarketCard(data: marketData[category]![index]),
                );
              }).toList(),
            ),
    );
  }
}

class _MarketCard extends StatelessWidget {
  final MarketData data;
  const _MarketCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isPositive = data.change >= 0;
    final color = isPositive ? Colors.green : Colors.red;
    final chartColor = color.withOpacity(0.8);
    final changeSign = isPositive ? '+' : '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(data.symbol, 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('\$${data.price.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 14)),
                    Row(
                      children: [
                        Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, 
                            color: color,
                            size: 20),
                        Text('$changeSign${data.change.toStringAsFixed(2)} (${data.changePercent.toStringAsFixed(2)}%)',
                            style: TextStyle(color: color, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.white,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            spot.y.toStringAsFixed(2),
                            TextStyle(
                              color: chartColor,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  minX: 0,
                  maxX: data.historicalPrices.length.toDouble() - 1,
                  minY: data.historicalPrices.reduce((a, b) => a < b ? a : b),
                  maxY: data.historicalPrices.reduce((a, b) => a > b ? a : b),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.historicalPrices
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value))
                          .toList(),
                      isCurved: true,
                      color: chartColor,
                      barWidth: 2,
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [chartColor.withOpacity(0.15), Colors.transparent],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            Text('Last updated: ${DateFormat('HH:mm').format(data.lastUpdated)}',
                style: TextStyle(color: Colors.grey[600], fontSize: 10)),
          ],
        ),
      ),
    );
  }
}