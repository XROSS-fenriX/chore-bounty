import 'package:dio/dio.dart';
import '../core/api_client.dart';
import '../models/app_notification.dart';
import '../models/bounty.dart';
import '../models/leaderboard_entry.dart';

class BountyService {
  BountyService(this.api);
  final ApiClient api;
  final Set<String> _readNotificationIds = {};

  Set<String> get readNotificationIds => _readNotificationIds;

  bool isNotificationMarkedRead(String id) => _readNotificationIds.contains(id);

  List<Bounty> _list(dynamic d) {
    if (d is Map) d = d['data'] ?? d['bounties'] ?? d['items'] ?? [];
    if (d is! List) return [];
    return d
        .whereType<Map>()
        .map((x) => Bounty.fromJson(Map<String, dynamic>.from(x)))
        .toList();
  }

  Future<List<Bounty>> all({
    String? status,
    String? householdId,
    int perPage = 100,
  }) async {
    final query = <String, dynamic>{'per_page': perPage};
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

  Future<void> reject(String id, {String? feedback}) async {
    await api.dio.post('/bounties/$id/reject', data: {
      if (feedback != null && feedback.trim().isNotEmpty)
        'feedback': feedback.trim(),
    });
  }

  Future<void> cancel(String id) async {
    await api.dio.post('/bounties/$id/cancel');
  }

  Future<void> delete(String id) async {
    await api.dio.delete('/bounties/$id');
  }

  Future<List<AppNotification>> notifications({
    String? householdId,
    String? currentUserId,
    String? currentUserName,
    List<Bounty> fallbackBounties = const [],
  }) async {
    final serverList = <AppNotification>[];
    try {
      final query = <String, dynamic>{};
      if (householdId != null && householdId.isNotEmpty) {
        query['household_id'] = householdId;
      }
      final res = await api.dio.get(
        '/notifications',
        queryParameters: query.isEmpty ? null : query,
      );
      final raw = res.data is Map
          ? (res.data['data'] ?? res.data['notifications'] ?? [])
          : res.data;
      if (raw is List) {
        for (final item in raw.whereType<Map>()) {
          final parsed =
              AppNotification.fromJson(Map<String, dynamic>.from(item));
          if (parsed.isTriggeredBy(currentUserId, currentUserName)) {
            continue;
          }
          if (parsed.isRead) {
            _readNotificationIds.add(parsed.id);
          }
          serverList.add(
            _readNotificationIds.contains(parsed.id)
                ? parsed.copyWith(isRead: true)
                : parsed,
          );
        }
      }
    } catch (_) {
      // Fallback to derived notifications when offline or in unit tests.
    }

    if (serverList.isNotEmpty) {
      return serverList;
    }

    return AppNotification.deriveFromBounties(
      fallbackBounties,
      readIds: _readNotificationIds,
      currentUserId: currentUserId,
      currentUserName: currentUserName,
    );
  }

  Future<void> markNotificationRead(String id) async {
    _readNotificationIds.add(id);
    if (int.tryParse(id) != null) {
      try {
        await api.dio.post('/notifications/$id/read');
      } catch (_) {}
    }
  }

  Future<void> markAllNotificationsRead({
    String? householdId,
    Iterable<String> ids = const [],
  }) async {
    _readNotificationIds.addAll(ids);
    try {
      await api.dio.post(
        '/notifications/read-all',
        data: {
          if (householdId != null && householdId.isNotEmpty)
            'household_id': householdId,
        },
      );
    } catch (_) {}
  }

  Future<List<LeaderboardEntry>> getLeaderboard({
    String? householdId,
    String? period,
  }) async {
    final endpoint = householdId != null && householdId.isNotEmpty
        ? '/households/$householdId/leaderboard'
        : '/leaderboard';

    final res = await api.dio.get(
      endpoint,
      queryParameters: period != null && period.isNotEmpty
          ? {'period': period}
          : null,
    );
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
