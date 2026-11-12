import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/household.dart';
import '../models/household_member.dart';

class HouseholdService {
  HouseholdService(this.api);
  final ApiClient api;

  List<Household> _list(dynamic d) {
    if (d is Map) d = d['data'] ?? d['households'] ?? [];
    if (d is! List) return [];
    return d
        .whereType<Map>()
        .map((x) => Household.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<List<Household>> all() async {
    final res = await api.dio.get('/households');
    return _list(res.data);
  }

  Future<List<HouseholdMember>> members(int householdId) async {
    final res = await api.dio.get('/households/$householdId/members');
    dynamic d = res.data;
    if (d is Map) d = d['data'] ?? d['members'] ?? [];
    if (d is! List) return [];
    final list = d
        .whereType<Map>()
        .map((x) => HouseholdMember.fromJson(Map<String, dynamic>.from(x)))
        .toList();
    return HouseholdMember.sortOwnerFirst(list);
  }

  Future<Household> create(String name) async {
    final res = await api.dio.post('/households', data: {'name': name});
    final data = res.data is Map ? (res.data['data'] ?? res.data) : {};
    return Household.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<Household> join(String inviteCode) async {
    final res = await api.dio.post('/households/join', data: {
      'invite_code': inviteCode.trim().toUpperCase(),
    });
    final data = res.data is Map ? (res.data['data'] ?? res.data) : {};
    return Household.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> leave(int householdId) async {
    await api.dio.post('/households/$householdId/leave');
  }

  Future<void> removeMember(int householdId, int userId) async {
    await api.dio.delete('/households/$householdId/members/$userId');
  }

  Future<Household> update(int householdId, String name) async {
    final res = await api.dio.put('/households/$householdId', data: {
      'name': name,
    });
    final data = res.data is Map ? (res.data['data'] ?? res.data) : {};
    return Household.fromJson(Map<String, dynamic>.from(data as Map));
  }

  String error(Object e) {
    if (e is DioException) {
      final resData = e.response?.data;
      if (resData is Map) {
        final message = resData['message']?.toString();
        if (message != null && message.isNotEmpty) {
          return message;
        }
      }
      return 'Error: ${e.response?.statusCode ?? 'network'}';
    }
    return e.toString();
  }
}
