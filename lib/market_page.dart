import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';

class MarketPage extends StatefulWidget {
  const MarketPage({super.key});

  @override
  State<MarketPage> createState() => _MarketPageState();
}

class _MarketPageState extends State<MarketPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String apiKey = 'd01lik1r01qile60b4k0d01lik1r01qile60b4kg';
  final List<String> marketCategories = ['Stocks', 'Crypto', 'Forex'];
  final Map<String, List<MarketData>> marketData = {
    'Stocks': [],
    'Crypto': [],
    'Forex': [],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: marketCategories.length, vsync: this);
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.wait([
      _fetchStockData(['AAPL', 'GOOGL', 'MSFT', 'TSLA', 'AMZN']),
      _fetchCryptoData(['bitcoin', 'ethereum', 'dogecoin', 'cardano']),
      _fetchForexData(['USD/INR', 'EUR/USD', 'GBP/USD', 'JPY/USD']),
    ]);
  }

  Future<void> _fetchStockData(List<String> symbols) async {
    for (String symbol in symbols) {
      try {
        final response = await http.get(
          Uri.parse(
            'https://www.alphavantage.co/query?function=TIME_SERIES_DAILY&symbol=$symbol&apikey=IPXC5C68LUMVCTH5',
          ),
        );

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final timeSeries = jsonData['Time Series (Daily)'] as Map<String, dynamic>;

          // Extract historical prices (limit to the last 30 days)
          final historicalPrices = timeSeries.entries
              .take(30)
              .map((entry) => double.parse(entry.value['4. close']))
              .toList()
              .reversed
              .toList();

          final currentPrice = historicalPrices.last;
          final previousPrice = historicalPrices[historicalPrices.length - 2];

          setState(() {
            marketData['Stocks']!.add(MarketData(
              symbol: symbol,
              price: currentPrice,
              change: currentPrice - previousPrice,
              changePercent: ((currentPrice - previousPrice) / previousPrice) * 100,
              historicalPrices: historicalPrices,
            ));
          });
        } else {
          print('Error fetching stock data for $symbol: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching stock data for $symbol: $e');
      }
    }
  }

  Future<void> _fetchCryptoData(List<String> ids) async {
    for (String id in ids) {
      try {
        final response = await http.get(
          Uri.parse('https://api.coingecko.com/api/v3/coins/$id/market_chart?vs_currency=usd&days=7'),
        );

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final prices = jsonData['prices'] as List<dynamic>;

          // Extract historical prices (closing prices for each day)
          final historicalPrices = prices.map<double>((price) => price[1].toDouble()).toList();
          final currentPrice = historicalPrices.last;
          final previousPrice = historicalPrices[historicalPrices.length - 2];

          setState(() {
            marketData['Crypto']!.add(MarketData(
              symbol: id.toUpperCase(),
              price: currentPrice,
              change: currentPrice - previousPrice,
              changePercent: ((currentPrice - previousPrice) / previousPrice) * 100,
              historicalPrices: historicalPrices,
            ));
          });
        }
      } catch (e) {
        print('Error fetching crypto data for $id: $e');
      }
    }
  }

  Future<void> _fetchForexData(List<String> pairs) async {
    for (String pair in pairs) {
      try {
        // Removed unused variables 'from' and 'to'
        final response = await http.get(
          Uri.parse('https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&apikey=IPXC5C68LUMVCTH5'),
        );

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final rates = jsonData['quote'];
          final targetCurrency = pair.split('/')[1];
          final currentRate = rates[targetCurrency];

          setState(() {
            marketData['Forex']!.add(MarketData(
              symbol: pair,
              price: currentRate,
              change: 0.0, // Placeholder for change
              changePercent: 0.0,
              historicalPrices: [currentRate], // Placeholder for historical data
            ));
          });
        }
      } catch (e) {
        print('Error fetching forex data for $pair: $e');
      }
    }
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
      body: TabBarView(
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

class MarketData {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;
  final List<double> historicalPrices;

  MarketData({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.historicalPrices,
  });
}

class _MarketCard extends StatelessWidget {
  final MarketData data;

  const _MarketCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final isPositive = data.change >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.symbol,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('\$${data.price.toStringAsFixed(2)}',
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              children: [
                Row(
                  children: [
                    Icon(isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down, color: color),
                    Text('${data.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(color: color)),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 250, // Increased width for more data points
                  height: 170, // Increased height for better visibility
                  child: LineChart(
                    LineChartData(
                      lineBarsData: [
                        LineChartBarData(
                          spots: data.historicalPrices
                              .asMap()
                              .entries
                              .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
                              .toList(),
                          isCurved: true,
                          color: color,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false), // No marked points
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                color.withOpacity(0.2),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value % 5 == 0) {
                                return Text(
                                  'Day ${value.toInt() + 1}',
                                  style: const TextStyle(fontSize: 8),
                                );
                              }
                              return const SizedBox.shrink();
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                value.toStringAsFixed(0),
                                style: const TextStyle(fontSize: 8),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: (data.historicalPrices.length - 1).toDouble(),
                      minY: data.historicalPrices.reduce((a, b) => a < b ? a : b),
                      maxY: data.historicalPrices.reduce((a, b) => a > b ? a : b),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}