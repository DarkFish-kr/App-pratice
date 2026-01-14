class Asset {
  final String id;
  final String apiId; // API 요청용 ID (예: bitcoin)
  final String name; // 화면 표시 이름 (예: Bitcoin)
  final String symbol; // 심볼 (예: BTC)
  final double amount; // 보유 수량
  double price; // 현재 가격 (변동 가능)

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
