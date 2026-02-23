import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import 'package:html/dom.dart' as dom;
import 'dart:math';

import '../models/stock_model.dart';

class StockService extends ChangeNotifier {
  List<StockModel> _allStocks = [];
  List<StockModel> _displayedStocks = [];

  bool _isLoading = false;
  bool _isDarkMode = false;
  String _errorMessage = '';

  int _currentPage = 1;
  final int _itemsPerPage = 5;

  List<StockModel> get displayedStocks => _displayedStocks;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _isDarkMode;
  String get errorMessage => _errorMessage;

  StockService() {
    fetchStocks();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void searchStocks(String query) {
    if (query.isEmpty) {
      _displayedStocks = _allStocks.take(_currentPage * _itemsPerPage).toList();
    } else {
      _displayedStocks = _allStocks
          .where((stock) => stock.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  void loadMore() {
    if (_currentPage * _itemsPerPage < _allStocks.length) {
      _currentPage++;
      _displayedStocks = _allStocks.take(_currentPage * _itemsPerPage).toList();
      notifyListeners();
    }
  }

  Future<void> fetchStocks() async {
    _isLoading = true;
    _errorMessage = '';
    _currentPage = 1;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('https://www.moneycontrol.com/markets/indian-indices/'),
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
        },
      );

      if (response.statusCode == 200) {
        dom.Document document = parser.parse(response.body);

        List<dom.Element> stockElements = document.querySelectorAll('.index_table tbody tr');
        if (stockElements.isEmpty) {
          stockElements = document.querySelectorAll('table tbody tr');
        }

        List<StockModel> scrapedStocks = [];
        final random = Random();

        for (var element in stockElements.take(20)) {
          try {
            if (element.children.length >= 3) {
              String title = element.children[0].text.trim();
              String price = element.children[1].text.trim();
              String change = element.children[2].text.trim();

              // We still need to generate the dummy chart array so fl_chart has math to render the sparklines
              List<double> mockChartData = List.generate(7, (index) => random.nextDouble() * 100 + 100);

              if (title.isNotEmpty && price.isNotEmpty) {
                scrapedStocks.add(StockModel(title: title, price: price, change: change, chartData: mockChartData));
              }
            }
          } catch (e) {
            continue;
          }
        }

        if (scrapedStocks.isNotEmpty) {
          _allStocks = scrapedStocks;
        } else {
          _errorMessage = 'No data found. Moneycontrol may have changed their table structure.';
          _allStocks = [];
        }
      } else {
        _errorMessage = 'Failed to fetch data. Server returned status code: ${response.statusCode}. (Likely blocked by bot-protection)';
        _allStocks = [];
      }
    } catch (e) {
      _errorMessage = 'Network error occurred: ${e.toString()}';
      _allStocks = [];
    }

    _displayedStocks = _allStocks.take(_currentPage * _itemsPerPage).toList();
    _isLoading = false;
    notifyListeners();
  }
}
