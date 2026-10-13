import 'package:dio/dio.dart';
import 'token_storage.dart';

class ApiClient {
  ApiClient(this.storage)
    : dio = Dio(
        BaseOptions(
          baseUrl: 'http://10.0.2.2:8000/api',
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
        onRequest: (o, h) async {
          final t = await storage.read();
          if (t != null && t.isNotEmpty)
            o.headers['Authorization'] = 'Bearer $t';
          h.next(o);
        },
      ),
    );
  }
  final TokenStorage storage;
  final Dio dio;
}
