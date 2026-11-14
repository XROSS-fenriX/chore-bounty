import 'bounty.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.eventName,
    required this.description,
    this.householdId = '',
    this.bountyId,
    this.userId = '',
    this.actorId,
    this.actorName,
    this.eventType = 'posted',
    this.category = 'Other',
    this.isRead = false,
    this.readAt,
    required this.createdAt,
  });

  final String id;
  final String householdId;
  final String? bountyId;
  final String userId;
  final String? actorId;
  final String? actorName;
  final String eventType;
  final String eventName;
  final String description;
  final String category;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  bool isTriggeredBy(String? targetUserId, [String? targetUserName]) {
    if (actorId != null &&
        actorId!.isNotEmpty &&
        targetUserId != null &&
        targetUserId.isNotEmpty) {
      return actorId == targetUserId;
    }
    if (actorName != null &&
        actorName!.isNotEmpty &&
        targetUserName != null &&
        targetUserName.isNotEmpty) {
      return actorName!.trim().toLowerCase() ==
          targetUserName.trim().toLowerCase();
    }
    return false;
  }

  AppNotification copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return AppNotification(
      id: id,
      householdId: householdId,
      bountyId: bountyId,
      userId: userId,
      actorId: actorId,
      actorName: actorName,
      eventType: eventType,
      eventName: eventName,
      description: description,
      category: category,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    final rawCreatedAt = j['created_at']?.toString();
    final parsedCreatedAt = rawCreatedAt != null
        ? (DateTime.tryParse(rawCreatedAt) ?? DateTime.now())
        : DateTime.now();

    final rawReadAt = j['read_at']?.toString();
    final parsedReadAt =
        rawReadAt != null ? DateTime.tryParse(rawReadAt) : null;

    final rawIsRead = j['is_read'];
    final isReadBool = rawIsRead == true ||
        rawIsRead == 1 ||
        rawIsRead == '1' ||
        rawIsRead == 'true';

    final title = (j['event_name'] ?? j['title'] ?? 'Chore Update').toString();
    final desc = (j['description'] ?? j['message'] ?? '').toString();

    return AppNotification(
      id: (j['id'] ?? '').toString(),
      householdId: (j['household_id'] ?? '').toString(),
      bountyId: j['bounty_id']?.toString(),
      userId: (j['user_id'] ?? '').toString(),
      actorId: j['actor_id']?.toString(),
      actorName: j['actor_name']?.toString(),
      eventType: (j['event_type'] ?? 'posted').toString(),
      eventName: title,
      description: desc,
      category: Bounty.inferCategory(
        j['category']?.toString(),
        title,
        desc,
      ),
      isRead: isReadBool,
      readAt: parsedReadAt,
      createdAt: parsedCreatedAt,
    );
  }

  static List<AppNotification> deriveFromBounties(
    List<Bounty> bounties, {
    Set<String> readIds = const {},
    String? currentUserId,
    String? currentUserName,
  }) {
    final results = <AppNotification>[];
    final now = DateTime.now();

    for (final b in bounties) {
      final tokens = b.points > 0
          ? b.points
          : (b.rewardValue != null && b.rewardValue! > 0
              ? b.rewardValue!.toInt()
              : b.xpReward);
      final creator = b.creator.isNotEmpty ? b.creator : 'Roommate';
      final assignee = (b.assignee != null && b.assignee!.trim().isNotEmpty)
          ? b.assignee!.trim()
          : 'Roommate';

      if (b.isCompleted) {
        final notif = AppNotification(
          id: 'bounty_${b.id}_awarded',
          householdId: b.householdId,
          bountyId: b.id,
          actorId: b.creatorId,
          actorName: creator,
          eventType: 'awarded',
          eventName: 'Bounty Awarded',
          description:
              '$creator awarded $tokens Tokens to $assignee for "${b.title}".',
          category: b.category,
          isRead: readIds.contains('bounty_${b.id}_awarded'),
          createdAt:
              b.completedAt ?? b.submittedAt ?? b.claimedAt ?? b.createdAt ?? now,
        );
        if (!notif.isTriggeredBy(currentUserId, currentUserName)) {
          results.add(notif);
        }
      } else if (b.isSubmitted) {
        final notif = AppNotification(
          id: 'bounty_${b.id}_submitted',
          householdId: b.householdId,
          bountyId: b.id,
          actorId: b.assigneeId,
          actorName: assignee,
          eventType: 'submitted',
          eventName: 'Chore Submitted',
          description: '$assignee submitted "${b.title}" for approval.',
          category: b.category,
          isRead: readIds.contains('bounty_${b.id}_submitted'),
          createdAt: b.submittedAt ?? b.claimedAt ?? b.createdAt ?? now,
        );
        if (!notif.isTriggeredBy(currentUserId, currentUserName)) {
          results.add(notif);
        }
      } else if (b.isClaimed) {
        final notif = AppNotification(
          id: 'bounty_${b.id}_claimed',
          householdId: b.householdId,
          bountyId: b.id,
          actorId: b.assigneeId,
          actorName: assignee,
          eventType: 'claimed',
          eventName: 'Chore Claimed',
          description: '$assignee claimed "${b.title}".',
          category: b.category,
          isRead: readIds.contains('bounty_${b.id}_claimed'),
          createdAt: b.claimedAt ?? b.createdAt ?? now,
        );
        if (!notif.isTriggeredBy(currentUserId, currentUserName)) {
          results.add(notif);
        }
      } else if (b.isCancelled) {
        final notif = AppNotification(
          id: 'bounty_${b.id}_cancelled',
          householdId: b.householdId,
          bountyId: b.id,
          actorId: b.creatorId,
          actorName: creator,
          eventType: 'cancelled',
          eventName: 'Chore Cancelled',
          description: '$creator cancelled "${b.title}".',
          category: b.category,
          isRead: readIds.contains('bounty_${b.id}_cancelled'),
          createdAt: b.createdAt ?? now,
        );
        if (!notif.isTriggeredBy(currentUserId, currentUserName)) {
          results.add(notif);
        }
      } else if (b.isOpen) {
        final notif = AppNotification(
          id: 'bounty_${b.id}_posted',
          householdId: b.householdId,
          bountyId: b.id,
          actorId: b.creatorId,
          actorName: creator,
          eventType: 'posted',
          eventName: 'Chore Posted',
          description: '$creator posted "${b.title}" ($tokens Tokens).',
          category: b.category,
          isRead: readIds.contains('bounty_${b.id}_posted'),
          createdAt: b.createdAt ?? now,
        );
        if (!notif.isTriggeredBy(currentUserId, currentUserName)) {
          results.add(notif);
        }
      }
    }

    results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return results;
  }
}

