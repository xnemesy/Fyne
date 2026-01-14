import 'package:dio/dio.dart';

class CryptoPriceService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: 'https://api.coingecko.com/api/v3',
    connectTimeout: const Duration(seconds: 5),
    receiveTimeout: const Duration(seconds: 5),
  ));

  /**
   * Fetches current price of a cryptocurrency in a target currency.
   * e.g. ids="bitcoin", vs_currencies="eur"
   */
  Future<double?> getPrice(String id, String vsCurrency) async {
    try {
      final response = await _dio.get('/simple/price', queryParameters: {
        'ids': id,
        'vs_currencies': vsCurrency,
      });

      if (response.data != null && response.data[id] != null) {
        return (response.data[id][vsCurrency.toLowerCase()] as num).toDouble();
      }
    } catch (e) {
      print("CryptoPriceService Error: $e");
    }
    return null;
  }
}
