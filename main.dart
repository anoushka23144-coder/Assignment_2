import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import 'services/stock_service.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => StockService(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Listen to StockService to update theme dynamically
    final service = Provider.of<StockService>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Moneycontrol Scraper',
      themeMode: service.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      home: const StockScreen(),
    );
  }
}

class StockScreen extends StatefulWidget {
  const StockScreen({Key? key}) : super(key: key);

  @override
  State<StockScreen> createState() => _StockScreenState();
}

class _StockScreenState extends State<StockScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        Provider.of<StockService>(context, listen: false).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = Provider.of<StockService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Market Data"),
        actions: [
          IconButton(
            icon: Icon(service.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => service.toggleTheme(),
          )
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Indices...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) => service.searchStocks(value),
            ),
          ),
        ),
      ),
      body: service.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: service.fetchStocks,
        child: Column(
          children: [
            if (service.errorMessage.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8),
                color: Colors.orangeAccent.withOpacity(0.2),
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(service.errorMessage, style: const TextStyle(fontSize: 12))),
                  ],
                ),
              ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: service.displayedStocks.length + 1,
                itemBuilder: (context, index) {
                  if (index == service.displayedStocks.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: Text("Pull up to load more / Scroll to paginate")),
                    );
                  }

                  final stock = service.displayedStocks[index];
                  final isNegative = stock.change.contains('-');

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(stock.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text("₹${stock.price}", style: const TextStyle(fontSize: 14)),
                                const SizedBox(height: 4),
                                Text(
                                  stock.change,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isNegative ? Colors.red : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: SizedBox(
                              height: 50,
                              child: LineChart(
                                LineChartData(
                                  gridData: FlGridData(show: false),
                                  titlesData: FlTitlesData(show: false),
                                  borderData: FlBorderData(show: false),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: stock.chartData.asMap().entries.map((e) {
                                        return FlSpot(e.key.toDouble(), e.value);
                                      }).toList(),
                                      isCurved: true,
                                      color: isNegative ? Colors.red : Colors.green,
                                      barWidth: 2,
                                      dotData: FlDotData(show: false),
                                      belowBarData: BarAreaData(
                                        show: true,
                                        color: (isNegative ? Colors.red : Colors.green).withOpacity(0.2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
