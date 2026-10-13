import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService(this.api, this.storage);
  final ApiClient api;
  final TokenStorage storage;
  Future<AppUser> login(String email, String password) async {
    final r = await api.dio.post(
      '/auth/login',
      data: {'email': email.trim(), 'password': password},
    );
    return _parse(r.data);
  }

  Future<AppUser> register(
    String name,
    String email,
    String password,
    String confirmation,
  ) async {
    final r = await api.dio.post(
      '/auth/register',
      data: {
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': confirmation,
      },
    );
    return _parse(r.data);
  }

  Future<AppUser> _parse(dynamic d) async {
    if (d is! Map) throw const FormatException('Unexpected API response');
    final j = Map<String, dynamic>.from(d);
    final token = j['token'] ?? j['access_token'];
    if (token is String) await storage.save(token);
    final u = j['user'] ?? j['data'];
    if (u is Map) return AppUser.fromJson(Map<String, dynamic>.from(u));
    if (token is String) return me();
    throw const FormatException('Expected token and user in response');
  }

  Future<AppUser> me() async {
    final r = await api.dio.get('/auth/me');
    final j = Map<String, dynamic>.from(r.data as Map);
    return AppUser.fromJson(
      Map<String, dynamic>.from((j['user'] ?? j['data'] ?? j) as Map),
    );
  }

  Future<void> logout() async {
    try {
      await api.dio.post('/auth/logout');
    } on DioException {}
    await storage.clear();
  }

  String error(Object e) {
    if (e is DioException) {
      final d = e.response?.data;
      if (d is Map) {
        final errors = d['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final x = errors.values.first;
          if (x is List && x.isNotEmpty) return x.first.toString();
        }
        if (d['message'] != null) return d['message'].toString();
      }
      return e.response == null
          ? 'Cannot reach Laravel. Check API URL/server.'
          : 'Request failed (${e.response?.statusCode}).';
    }
    return e.toString();
  }
}
