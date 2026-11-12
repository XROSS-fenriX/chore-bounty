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

  Future<AppUser> register({
    required String firstName,
    String? middleName,
    required String lastName,
    required String gender,
    required String email,
    required String password,
    required String confirmation,
  }) async {
    final trimmedMiddle = middleName?.trim();
    final r = await api.dio.post(
      '/auth/register',
      data: {
        'first_name': firstName.trim(),
        if (trimmedMiddle != null && trimmedMiddle.isNotEmpty)
          'middle_name': trimmedMiddle,
        'last_name': lastName.trim(),
        'gender': gender,
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
    if (u is Map) {
      final user = AppUser.fromJson(Map<String, dynamic>.from(u));
      if (user.avatar == null) {
        final localAvatar = await storage.readAvatar();
        if (localAvatar != null && localAvatar.isNotEmpty) {
          return user.copyWith(avatar: localAvatar);
        }
      }
      return user;
    }
    if (token is String) return me();
    throw const FormatException('Expected token and user in response');
  }

  Future<AppUser> me() async {
    final r = await api.dio.get('/auth/me');
    final j = Map<String, dynamic>.from(r.data as Map);
    final user = AppUser.fromJson(
      Map<String, dynamic>.from((j['user'] ?? j['data'] ?? j) as Map),
    );
    if (user.avatar == null) {
      final localAvatar = await storage.readAvatar();
      if (localAvatar != null && localAvatar.isNotEmpty) {
        return user.copyWith(avatar: localAvatar);
      }
    }
    return user;
  }

  Future<AppUser> updateProfile({
    required int userId,
    required String firstName,
    String? middleName,
    required String lastName,
    required String gender,
    String? avatar,
  }) async {
    if (avatar != null && avatar.isNotEmpty) {
      await storage.saveAvatar(avatar);
    }
    final trimmedMiddle = middleName?.trim();
    final r = await api.dio.put(
      '/users/$userId',
      data: {
        'first_name': firstName.trim(),
        'middle_name':
            (trimmedMiddle != null && trimmedMiddle.isNotEmpty)
                ? trimmedMiddle
                : null,
        'last_name': lastName.trim(),
        'gender': gender,
        if (avatar != null && avatar.isNotEmpty) 'avatar': avatar,
      },
    );
    if (r.data is Map) {
      final j = Map<String, dynamic>.from(r.data as Map);
      final u = j['user'] ?? j['data'] ?? j;
      if (u is Map) {
        return AppUser.fromJson(Map<String, dynamic>.from(u));
      }
    }
    return me();
  }

  Future<AppUser> updateAvatar(String avatarId) async {
    await storage.saveAvatar(avatarId);
    try {
      final r = await api.dio.put(
        '/user/avatar',
        data: {'avatar': avatarId},
      );
      if (r.data is Map) {
        final j = Map<String, dynamic>.from(r.data as Map);
        final u = j['user'] ?? j['data'];
        if (u is Map) {
          return AppUser.fromJson(Map<String, dynamic>.from(u));
        }
      }
      return me();
    } on DioException {
      // Re-throw so caller can display error toast while local fallback persists
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await api.dio.post('/auth/logout');
    } on DioException catch (_) {
      // Ignore network errors when clearing local session
    }
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
