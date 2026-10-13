class Bounty {
  const Bounty({
    required this.id,
    required this.title,
    this.description = '',
    this.category = 'Other',
    this.points = 0,
    this.reward = '',
    this.status = 'available',
    this.creator = '',
  });
  final String id, title, description, category, reward, status, creator;
  final int points;
  factory Bounty.fromJson(Map<String, dynamic> j) {
    final v = j['reward_value'] ?? j['points'] ?? 0;
    final c = j['creator'] ?? {};
    return Bounty(
      id: (j['id'] ?? j['bounty_id'] ?? '').toString(),
      title: (j['title'] ?? j['bounty_title'] ?? 'Untitled bounty').toString(),
      description: (j['description'] ?? '').toString(),
      category: (j['category'] ?? j['difficulty'] ?? 'Other').toString(),
      points: v is num ? v.toInt() : int.tryParse('$v') ?? 0,
      reward: (j['reward_description'] ?? '').toString(),
      status: (j['status'] ?? 'available').toString(),
      creator: c is Map ? (c['name'] ?? '').toString() : '',
    );
  }
}
