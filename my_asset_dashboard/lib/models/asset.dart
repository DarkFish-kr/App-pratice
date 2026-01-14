class Asset {
  final String id;
  final String apiId; // API 요청용 ID (예: bitcoin)
  final String name;
  final String symbol;
  final double amount;
  double price; // 가격은 변동되므로 final 제거

  Asset({
    required this.id,
    required this.apiId,
    required this.name,
    required this.symbol,
    required this.amount,
    required this.price,
  });

  double get totalValue => amount * price;
}
