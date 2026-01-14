import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // CoinGecko API를 이용해 가격 정보 가져오기
  // ids 예시: 'bitcoin,ethereum,ripple'
  Future<Map<String, double>> fetchCoinPrices(List<String> ids) async {
    final idsString = ids.join(',');
    final url = Uri.parse(
      'https://api.coingecko.com/api/v3/simple/price?ids=$idsString&vs_currencies=usd',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final Map<String, double> prices = {};

        // 데이터 파싱: {'bitcoin': {'usd': 65000}} -> {'bitcoin': 65000}
        data.forEach((key, value) {
          prices[key] = (value['usd'] as num).toDouble();
        });

        return prices;
      } else {
        throw Exception('Failed to load prices');
      }
    } catch (e) {
      print('Error fetching prices: $e');
      return {}; // 에러 발생 시 빈 맵 반환
    }
  }
}
