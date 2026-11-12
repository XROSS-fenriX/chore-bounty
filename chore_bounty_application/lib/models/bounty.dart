import 'app_user.dart';

class Bounty {
  const Bounty({
    required this.id,
    required this.title,
    this.householdId = '',
    this.creatorId = '',
    this.creator = '',
    this.creatorAvatar,
    this.assigneeId,
    this.assignee,
    this.assigneeAvatar,
    this.description = '',
    this.difficulty = 'easy',
    this.category = 'Other',
    this.xpReward = 50,
    this.points = 0,
    this.rewardValue,
    this.reward = '',
    this.status = 'open',
    this.submissionProof,
    this.claimedAt,
    this.submittedAt,
    this.completedAt,
    this.dueAt,
    this.createdAt,
  });

  final String id;
  final String householdId;
  final String creatorId;
  final String creator;
  final String? creatorAvatar;
  final String? assigneeId;
  final String? assignee;
  final String? assigneeAvatar;
  final String title;
  final String description;
  final String difficulty;
  final String category;
  final int xpReward;
  final int points;
  final double? rewardValue;
  final String reward;
  final String status;
  final String? submissionProof;
  final DateTime? claimedAt;
  final DateTime? submittedAt;
  final DateTime? completedAt;
  final DateTime? dueAt;
  final DateTime? createdAt;

  bool get isOpen => status == 'open' || status == 'available';
  bool get isPastDue =>
      isOpen && dueAt != null && !dueAt!.isAfter(DateTime.now());
  bool get isAvailable => isOpen && !isPastDue;
  bool get isClaimed => status == 'claimed' || status == 'in_progress';
  bool get isSubmitted => status == 'submitted';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled' || status == 'canceled';

  static String inferCategory(String? category, String title, String description) {
    final cat = (category ?? '').trim();
    const difficultyKeywords = {'easy', 'medium', 'hard', 'epic'};
    if (cat.isNotEmpty && !difficultyKeywords.contains(cat.toLowerCase())) {
      return cat[0].toUpperCase() + cat.substring(1);
    }
    final combined = '$title $description'.toLowerCase();
    if (combined.contains('laundry') ||
        combined.contains('wash') ||
        combined.contains('clothes')) {
      return 'Laundry';
    }
    if (combined.contains('clean') ||
        combined.contains('sweep') ||
        combined.contains('mop') ||
        combined.contains('vacuum') ||
        combined.contains('dust') ||
        combined.contains('trash') ||
        combined.contains('bunnies') ||
        combined.contains('room')) {
      return 'Cleaning';
    }
    if (combined.contains('kitchen') ||
        combined.contains('dish') ||
        combined.contains('cook') ||
        combined.contains('pots') ||
        combined.contains('counter') ||
        combined.contains('dishmore') ||
        combined.contains('breakfast')) {
      return 'Kitchen';
    }
    if (combined.contains('grocer') ||
        combined.contains('shop') ||
        combined.contains('dinner') ||
        combined.contains('beans') ||
        combined.contains('milk') ||
        combined.contains('food') ||
        combined.contains('market') ||
        combined.contains('pizza')) {
      return 'Groceries';
    }
    if (combined.contains('fix') ||
        combined.contains('repair') ||
        combined.contains('bulb') ||
        combined.contains('maintenance')) {
      return 'Maintenance';
    }
    return 'Other';
  }

  static String _parseUserName(dynamic userObj, String? fallback) {
    if (userObj is Map) {
      return AppUser.composeFullName(
        firstName: userObj['first_name']?.toString(),
        middleName: userObj['middle_name']?.toString(),
        lastName: userObj['last_name']?.toString(),
        fallback: userObj['name']?.toString() ?? fallback,
      );
    }
    return (fallback ?? '').trim();
  }

  static String? _parseAvatar(dynamic userObj) {
    if (userObj is! Map) return null;
    final raw = (userObj['avatar'] ??
            userObj['avatar_id'] ??
            userObj['avatar_url'])
        ?.toString()
        .trim();
    return (raw != null && raw.isNotEmpty) ? raw : null;
  }

  factory Bounty.fromJson(Map<String, dynamic> j) {
    final v = j['reward_value'] ?? j['points'] ?? 0;
    final parsedValue = v is num ? v.toDouble() : double.tryParse('$v');
    final pointsInt = v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    final xp = j['xp_reward'] != null
        ? (j['xp_reward'] is num ? (j['xp_reward'] as num).toInt() : int.tryParse('${j['xp_reward']}') ?? 50)
        : (pointsInt > 0 ? pointsInt : 50);

    final c = j['creator'];
    final creatorName = _parseUserName(c, j['creator_name']?.toString());
    final creatorAvatar = _parseAvatar(c) ??
        (j['creator_avatar'] ?? j['creator_avatar_id'])?.toString().trim();

    final a = j['assignee'];
    var assigneeId = j['assignee_id']?.toString();
    var assigneeName = _parseUserName(a, j['assignee_name']?.toString());
    var assigneeAvatar = _parseAvatar(a) ??
        (j['assignee_avatar'] ?? j['assignee_avatar_id'])?.toString().trim();

    // Fall back to active_claim / claims user details when assignee isn't populated directly.
    if (assigneeName.isEmpty || assigneeAvatar == null || assigneeAvatar.isEmpty) {
      final claimCandidates = <Map>[];
      if (j['active_claim'] is Map) {
        claimCandidates.add(j['active_claim'] as Map);
      }
      if (j['claims'] is List) {
        for (final item in (j['claims'] as List)) {
          if (item is Map) claimCandidates.add(item);
        }
      }
      Map? chosenClaim;
      for (final claim in claimCandidates) {
        final claimUserId = claim['user_id']?.toString();
        final claimStatus = claim['status']?.toString();
        if (assigneeId != null && assigneeId.isNotEmpty && claimUserId == assigneeId) {
          chosenClaim = claim;
          break;
        }
        if (chosenClaim == null &&
            (claimStatus == 'active' || claimStatus == 'completed')) {
          chosenClaim = claim;
        }
      }
      if (chosenClaim != null) {
        final claimUser = chosenClaim['user'];
        if (assigneeId == null || assigneeId.isEmpty) {
          assigneeId = chosenClaim['user_id']?.toString();
        }
        if (claimUser is Map) {
          if (assigneeName.isEmpty) {
            assigneeName = _parseUserName(claimUser, null);
          }
          if (assigneeAvatar == null || assigneeAvatar.isEmpty) {
            assigneeAvatar = _parseAvatar(claimUser);
          }
        }
      }
    }

    return Bounty(
      id: (j['id'] ?? j['bounty_id'] ?? '').toString(),
      householdId: (j['household_id'] ?? '').toString(),
      creatorId: (j['creator_id'] ?? j['created_by'] ?? '').toString(),
      creator: creatorName.isNotEmpty ? creatorName : 'Roommate',
      creatorAvatar: (creatorAvatar != null && creatorAvatar.isNotEmpty) ? creatorAvatar : null,
      assigneeId: assigneeId,
      assignee: assigneeName.isNotEmpty ? assigneeName : null,
      assigneeAvatar: (assigneeAvatar != null && assigneeAvatar.isNotEmpty) ? assigneeAvatar : null,
      title: (j['title'] ?? j['bounty_title'] ?? 'Untitled bounty').toString(),
      description: (j['description'] ?? '').toString(),
      difficulty: (j['difficulty'] ?? 'easy').toString(),
      category: inferCategory(
        j['category']?.toString(),
        (j['title'] ?? j['bounty_title'] ?? '').toString(),
        (j['description'] ?? '').toString(),
      ),
      xpReward: xp,
      points: pointsInt,
      rewardValue: parsedValue,
      reward: (j['reward_description'] ?? j['reward'] ?? '').toString(),
      status: (j['status'] ?? 'open').toString(),
      submissionProof: j['submission_proof']?.toString(),
      claimedAt: j['claimed_at'] != null ? DateTime.tryParse(j['claimed_at'].toString()) : null,
      submittedAt: j['submitted_at'] != null ? DateTime.tryParse(j['submitted_at'].toString()) : null,
      completedAt: j['completed_at'] != null ? DateTime.tryParse(j['completed_at'].toString()) : null,
      dueAt: j['due_at'] != null ? DateTime.tryParse(j['due_at'].toString()) : null,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
    );
  }
}
