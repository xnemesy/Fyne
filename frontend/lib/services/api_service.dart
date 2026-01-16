import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/**
 * Service to handle communication with the Cloud Run backend.
 */
class ApiService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: 'https://banking-abstraction-layer-719543584184.europe-west8.run.app',
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  ApiService() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          options.headers['Authorization'] = 'Bearer $token';
          print("➡️ API Request: ${options.method} ${options.path} [Auth Token Present]");
        } else {
          print("➡️ API Request: ${options.method} ${options.path} [Anonymous/No User]");
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        print("⬅️ API Response: ${response.statusCode} ${response.requestOptions.path}");
        return handler.next(response);
      },
      onError: (error, handler) {
        print("❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path} - ${error.message}");
        return handler.next(error);
      },
    ));
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return await dio.get(path, queryParameters: queryParameters);
  }

  Future<Response> post(String path, {dynamic data}) async {
    return await dio.post(path, data: data);
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());
