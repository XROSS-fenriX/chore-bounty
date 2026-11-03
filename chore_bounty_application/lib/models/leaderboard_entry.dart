class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.completedCount,
    required this.activeCount,
    required this.totalXp,
    required this.totalRewardValue,
    required this.tier,
  });

  final int rank;
  final int userId;
  final String name;
  final String? avatarUrl;
  final int completedCount;
  final int activeCount;
  final int totalXp;
  final double totalRewardValue;
  final String tier;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) {
    return LeaderboardEntry(
      rank: j['rank'] is int ? j['rank'] : int.tryParse('${j['rank']}') ?? 1,
      userId: j['user_id'] is int ? j['user_id'] : int.tryParse('${j['user_id']}') ?? 0,
      name: (j['name'] ?? 'Roommate').toString(),
      avatarUrl: j['avatar_url']?.toString(),
      completedCount: j['completed_bounties_count'] is int
          ? j['completed_bounties_count']
          : int.tryParse('${j['completed_bounties_count']}') ?? 0,
      activeCount: j['active_bounties_count'] is int
          ? j['active_bounties_count']
          : int.tryParse('${j['active_bounties_count']}') ?? 0,
      totalXp: j['total_xp'] is int
          ? j['total_xp']
          : int.tryParse('${j['total_xp']}') ?? 0,
      totalRewardValue: j['total_reward_value'] is num
          ? (j['total_reward_value'] as num).toDouble()
          : double.tryParse('${j['total_reward_value']}') ?? 0.0,
      tier: (j['tier'] ?? 'Household Novice').toString(),
    );
  }
}
