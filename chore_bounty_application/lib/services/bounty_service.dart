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
    int perPage = 25,
  }) async {
    final results = <Bounty>[];
    final seenIds = <String>{};
    var page = 1;
    var lastPage = 1;
    const maxPages = 20;

    do {
      final query = <String, dynamic>{
        'per_page': perPage,
        if (page > 1) 'page': page,
      };
      if (status != null && status.isNotEmpty) query['status'] = status;
      if (householdId != null && householdId.isNotEmpty) {
        query['household_id'] = householdId;
      }

      final res = await api.dio.get('/bounties', queryParameters: query);
      final pageItems = _list(res.data);
      for (final item in pageItems) {
        if (seenIds.add(item.id)) {
          results.add(item);
        }
      }

      lastPage = _extractLastPage(res.data);
      if (pageItems.isEmpty) break;
      page++;
    } while (page <= lastPage && page <= maxPages);

    return results;
  }

  int _extractLastPage(dynamic data) {
    if (data is Map) {
      final meta = data['meta'];
      if (meta is Map) {
        final rawLast = meta['last_page'];
        if (rawLast is int) return rawLast;
        if (rawLast is num) return rawLast.toInt();
        if (rawLast is String) return int.tryParse(rawLast) ?? 1;
      }
      final rawLast = data['last_page'];
      if (rawLast is int) return rawLast;
      if (rawLast is num) return rawLast.toInt();
      if (rawLast is String) return int.tryParse(rawLast) ?? 1;
    }
    return 1;
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

  Future<void> submit(
    String id, {
    String? proof,
    List<String> imagePaths = const [],
  }) async {
    final trimmedProof = proof?.trim() ?? '';

    if (imagePaths.isNotEmpty) {
      final multipartFiles = <MultipartFile>[];
      for (final path in imagePaths) {
        final trimmedPath = path.trim();
        if (trimmedPath.isEmpty) continue;
        multipartFiles.add(await MultipartFile.fromFile(trimmedPath));
      }

      final formData = FormData.fromMap({
        'submission_proof':
            trimmedProof.isNotEmpty ? trimmedProof : 'Photo proof submitted',
        'proof_images[]': multipartFiles,
      });

      await api.dio.post(
        '/bounties/$id/submit',
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return;
    }

    await api.dio.post('/bounties/$id/submit', data: {
      'submission_proof':
          trimmedProof.isNotEmpty ? trimmedProof : 'Completed chore proof submitted.',
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
        final creatorByBountyId = <String, String>{
          for (final b in fallbackBounties)
            if (b.id.isNotEmpty && b.creatorId.isNotEmpty) b.id: b.creatorId,
        };
        for (final item in raw.whereType<Map>()) {
          var parsed =
              AppNotification.fromJson(Map<String, dynamic>.from(item));
          if ((parsed.bountyCreatorId == null ||
                  parsed.bountyCreatorId!.isEmpty) &&
              parsed.bountyId != null) {
            final knownCreator = creatorByBountyId[parsed.bountyId!];
            if (knownCreator != null && knownCreator.isNotEmpty) {
              parsed = parsed.copyWith(bountyCreatorId: knownCreator);
            }
          }
          if (!parsed.isVisibleTo(currentUserId, currentUserName)) {
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

  Future<bool> markNotificationRead(String id) async {
    _readNotificationIds.add(id);
    if (int.tryParse(id) != null) {
      try {
        await api.dio.post('/notifications/$id/read');
        return true;
      } catch (_) {
        return false;
      }
    }
    return true;
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
