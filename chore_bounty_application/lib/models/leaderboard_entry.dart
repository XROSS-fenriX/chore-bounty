import 'app_user.dart';

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.firstName = '',
    this.middleName,
    this.lastName = '',
    this.gender,
    this.avatarUrl,
    required this.completedCount,
    required this.activeCount,
    required this.totalTokens,
    this.totalXp = 0,
    required this.totalRewardValue,
    required this.tier,
  });

  final int rank;
  final int userId;
  final String name;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? gender;
  final String? avatarUrl;
  final int completedCount;
  final int activeCount;
  final int totalTokens;
  final int totalXp;
  final double totalRewardValue;
  final String tier;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) {
    final xp = j['total_xp'] is int ? j['total_xp'] : int.tryParse('${j['total_xp']}') ?? 0;
    final rewardNum = j['total_reward_value'] is num
        ? (j['total_reward_value'] as num).toDouble()
        : double.tryParse('${j['total_reward_value']}') ?? 0.0;
    final tokensRaw = j['total_tokens'] ?? (rewardNum > 0 ? rewardNum.toInt() : xp);
    final tokens = tokensRaw is num ? tokensRaw.toInt() : int.tryParse('$tokensRaw') ?? 0;

    final rawFirst = j['first_name']?.toString().trim() ?? '';
    final rawMiddle = j['middle_name']?.toString().trim();
    final rawLast = j['last_name']?.toString().trim() ?? '';
    final fullName = AppUser.composeFullName(
      firstName: rawFirst,
      middleName: rawMiddle,
      lastName: rawLast,
      fallback: j['name']?.toString(),
    );

    return LeaderboardEntry(
      rank: j['rank'] is int ? j['rank'] : int.tryParse('${j['rank']}') ?? 1,
      userId: j['user_id'] is int ? j['user_id'] : int.tryParse('${j['user_id']}') ?? 0,
      name: fullName.isNotEmpty ? fullName : 'Roommate',
      firstName: rawFirst,
      middleName:
          (rawMiddle != null && rawMiddle.isNotEmpty) ? rawMiddle : null,
      lastName: rawLast,
      gender: AppUser.normalizeGender(j['gender']?.toString()),
      avatarUrl: (j['avatar_url'] ?? j['avatar'] ?? j['avatar_id'])?.toString(),
      completedCount: j['completed_bounties_count'] is int
          ? j['completed_bounties_count']
          : int.tryParse('${j['completed_bounties_count']}') ?? 0,
      activeCount: j['active_bounties_count'] is int
          ? j['active_bounties_count']
          : int.tryParse('${j['active_bounties_count']}') ?? 0,
      totalTokens: tokens,
      totalXp: tokens > 0 ? tokens : xp,
      totalRewardValue: rewardNum > 0 ? rewardNum : tokens.toDouble(),
      tier: (j['tier'] ?? 'Household Novice').toString(),
    );
  }
}
