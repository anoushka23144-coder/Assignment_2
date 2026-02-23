class StockModel {
  final String title;
  final String price;
  final String change;
  final List<double> chartData;

  StockModel({
    required this.title,
    required this.price,
    required this.change,
    required this.chartData,
  });
}
