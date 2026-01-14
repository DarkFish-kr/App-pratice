import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/api_service.dart';

class PortfolioProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // 초기 더미 데이터
  final List<Asset> _assets = [
    Asset(
      id: '1',
      apiId: 'bitcoin',
      name: 'Bitcoin',
      symbol: 'BTC',
      amount: 0.5,
      price: 0,
    ),
    Asset(
      id: '2',
      apiId: 'ethereum',
      name: 'Ethereum',
      symbol: 'ETH',
      amount: 5,
      price: 0,
    ),
    Asset(
      id: '3',
      apiId: 'ripple',
      name: 'Ripple',
      symbol: 'XRP',
      amount: 3000,
      price: 0,
    ),
  ];

  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;

  double get totalPortfolioValue {
    return _assets.fold(0.0, (sum, item) => sum + item.totalValue);
  }

  // 가격 업데이트
  Future<void> fetchPrices() async {
    if (_assets.isEmpty) return;

    _isLoading = true;
    notifyListeners();

    final apiIds = _assets.map((e) => e.apiId).toList();
    final newPrices = await _apiService.fetchCoinPrices(apiIds);

    if (newPrices.isNotEmpty) {
      for (var asset in _assets) {
        if (newPrices.containsKey(asset.apiId)) {
          asset.price = newPrices[asset.apiId]!;
        }
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  // 자산 추가
  Future<void> addAsset(
    String apiId,
    String name,
    String symbol,
    double amount,
  ) async {
    final newAsset = Asset(
      id: DateTime.now().toString(),
      apiId: apiId,
      name: name,
      symbol: symbol,
      amount: amount,
      price: 0,
    );

    _assets.add(newAsset);
    notifyListeners();

    // 추가 후 가격 갱신
    await fetchPrices();
  }

  // 자산 삭제
  void removeAsset(String id) {
    _assets.removeWhere((asset) => asset.id == id);
    notifyListeners();
  }
}
