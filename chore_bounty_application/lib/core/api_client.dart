import 'dart:ui';
import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api',
  );

  ApiClient(
    this.storage, {
    String? customBaseUrl,
    VoidCallback? onUnauthorized,
  }) : dio = Dio(
         BaseOptions(
           baseUrl: customBaseUrl ?? defaultBaseUrl,
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
        onError: (error, handler) async {
          final path = error.requestOptions.path;
          final isAuthEndpoint =
              path.contains('/auth/login') || path.contains('/auth/register');
          if (error.response?.statusCode == 401 && !isAuthEndpoint) {
            await storage.clear();
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  final TokenStorage storage;
  final Dio dio;
}
