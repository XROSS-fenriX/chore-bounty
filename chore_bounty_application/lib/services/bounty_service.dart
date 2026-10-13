import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/bounty.dart';

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

  Future<List<Bounty>> all() async =>
      (_list((await api.dio.get('/bounties')).data));
  Future<void> create(Map<String, dynamic> data) async {
    await api.dio.post('/bounties', data: data);
  }

  Future<void> claim(String id) async {
    await api.dio.post('/bounties/$id/claim');
  }

  Future<void> complete(String id) async {
    await api.dio.post('/bounties/$id/complete');
  }

  Future<void> unclaim(String id) async {
    await api.dio.delete('/bounties/$id/claim');
  }

  String error(Object e) => e is DioException
      ? (e.response?.data is Map
            ? ((e.response!.data as Map)['message']?.toString() ??
                  'API error ${e.response?.statusCode}')
            : 'Could not connect to Laravel')
      : e.toString();
}
