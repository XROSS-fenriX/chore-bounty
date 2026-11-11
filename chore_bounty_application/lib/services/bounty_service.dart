import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/bounty.dart';
import '../models/leaderboard_entry.dart';

class BountyService {
  BountyService(this.api);
  final ApiClient api;

  List<Bounty> _list(dynamic d) {
    if (d is Map) d = d['data'] ?? d['bounties'] ?? d['items'] ?? [];
    if (d is! List) return [];
    return d
        .whereType<Map>()
        .map((x) => Bounty.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<List<Bounty>> all({String? status, String? householdId}) async {
    final query = <String, dynamic>{};
    if (status != null && status.isNotEmpty) query['status'] = status;
    if (householdId != null && householdId.isNotEmpty) {
      query['household_id'] = householdId;
    }

    final res = await api.dio.get('/bounties', queryParameters: query);
    return _list(res.data);
  }

  Future<Bounty> show(String id) async {
    final res = await api.dio.get('/bounties/$id');
    final raw = res.data is Map
        ? (res.data['data'] ?? res.data['bounty'] ?? res.data)
        : res.data;
    if (raw is! Map) {
      throw const FormatException('Unexpected bounty response');
    }
    return Bounty.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> create(Map<String, dynamic> data) async {
    await api.dio.post('/bounties', data: data);
  }

  Future<void> update(String id, Map<String, dynamic> data) async {
    await api.dio.put('/bounties/$id', data: data);
  }

  Future<void> claim(String id) async {
    await api.dio.post('/bounties/$id/claim');
  }

  Future<void> unclaim(String id) async {
    await api.dio.delete('/bounties/$id/claim');
  }

  Future<void> submit(String id, {String? proof}) async {
    await api.dio.post('/bounties/$id/submit', data: {
      'submission_proof': proof ?? 'Completed chore proof submitted.',
    });
  }

  Future<void> complete(String id) async {
    await api.dio.post('/bounties/$id/complete');
  }

  Future<void> verify(String id, {String? feedback}) async {
    await api.dio.post('/bounties/$id/verify', data: {
      'feedback': feedback ?? 'Approved! Great job.',
    });
  }

  Future<void> cancel(String id) async {
    await api.dio.post('/bounties/$id/cancel');
  }

  Future<List<LeaderboardEntry>> getLeaderboard({String? householdId}) async {
    final endpoint = householdId != null && householdId.isNotEmpty
        ? '/households/$householdId/leaderboard'
        : '/leaderboard';

    final res = await api.dio.get(endpoint);
    final data = res.data is Map ? (res.data['data'] ?? []) : [];
    if (data is! List) return [];

    return data
        .whereType<Map>()
        .map((x) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(x)))
        .toList();
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
      return 'API Error (${e.response?.statusCode ?? 'network'})';
    }
    return e.toString();
  }
}
