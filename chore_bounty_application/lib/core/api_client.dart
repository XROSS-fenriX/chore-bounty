import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient(this.storage, {String? customBaseUrl})
    : dio = Dio(
        BaseOptions(
          baseUrl: customBaseUrl ?? 'http://10.0.2.2:8000/api',
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await storage.read();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          final householdId = await storage.readHouseholdId();
          if (householdId != null && householdId.isNotEmpty) {
            options.headers['X-Household-Id'] = householdId;
          }

          handler.next(options);
        },
      ),
    );
  }

  final TokenStorage storage;
  final Dio dio;
}
