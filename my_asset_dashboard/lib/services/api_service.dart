import 'dart:convert';
import 'package:flutter/foundation.dart'; // [추가됨] debugPrint를 쓰기 위해 필요
import 'package:http/http.dart' as http;

class ApiService {
  // CoinGecko API를 이용해 가격 정보 가져오기
  Future<Map<String, double>> fetchCoinPrices(List<String> ids) async {
    if (ids.isEmpty) return {};

    final idsString = ids.join(',');
    final url = Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=$idsString&vs_currencies=usd',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final Map<String, double> prices = {};

        data.forEach((key, value) {
          prices[key] = (value['usd'] as num).toDouble();
        });

        return prices;
      } else {
        // [수정됨] print -> debugPrint
        debugPrint('Failed to load prices: ${response.statusCode}');
        return {};
      }
    } catch (e) {
      // [수정됨] print -> debugPrint
      debugPrint('Error fetching prices: $e');
      return {};
    }
  }
}
