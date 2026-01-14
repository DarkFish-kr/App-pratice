import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/api_service.dart';

class PortfolioProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  // 실시간 테스트를 위해 암호화폐 위주로 더미 데이터 변경
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
    Asset(
      id: '4',
      apiId: 'solana',
      name: 'Solana',
      symbol: 'SOL',
      amount: 50,
      price: 0,
    ),
  ];

  List<Asset> get assets => _assets;
  bool get isLoading => _isLoading;

  double get totalPortfolioValue {
    return _assets.fold(0.0, (sum, item) => sum + item.totalValue);
  }

  // 가격 업데이트 함수
  Future<void> fetchPrices() async {
    _isLoading = true;
    notifyListeners(); // 로딩 시작 알림

    // 자산들의 apiId만 추출 (예: ['bitcoin', 'ethereum' ...])
    final apiIds = _assets.map((e) => e.apiId).toList();

    // API 호출
    final newPrices = await _apiService.fetchCoinPrices(apiIds);

    // 받아온 가격을 기존 자산 리스트에 반영
    if (newPrices.isNotEmpty) {
      for (var asset in _assets) {
        if (newPrices.containsKey(asset.apiId)) {
          asset.price = newPrices[asset.apiId]!;
        }
      }
    }

    _isLoading = false;
    notifyListeners(); // 데이터 업데이트 완료 알림
  }
}
