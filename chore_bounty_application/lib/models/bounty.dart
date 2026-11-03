class Bounty {
  const Bounty({
    required this.id,
    required this.title,
    this.householdId = '',
    this.creatorId = '',
    this.creator = '',
    this.assigneeId,
    this.assignee,
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
  final String? assigneeId;
  final String? assignee;
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
  bool get isClaimed => status == 'claimed' || status == 'in_progress';
  bool get isSubmitted => status == 'submitted';
  bool get isCompleted => status == 'completed';

  factory Bounty.fromJson(Map<String, dynamic> j) {
    final v = j['reward_value'] ?? j['points'] ?? 0;
    final parsedValue = v is num ? v.toDouble() : double.tryParse('$v');
    final pointsInt = v is num ? v.toInt() : int.tryParse('$v') ?? 0;
    final xp = j['xp_reward'] != null
        ? (j['xp_reward'] is num ? (j['xp_reward'] as num).toInt() : int.tryParse('${j['xp_reward']}') ?? 50)
        : (pointsInt > 0 ? pointsInt : 50);

    final c = j['creator'];
    final creatorName = c is Map ? (c['name'] ?? '').toString() : (j['creator_name'] ?? '').toString();

    final a = j['assignee'];
    final assigneeName = a is Map ? (a['name'] ?? '').toString() : (j['assignee_name'] ?? '').toString();

    return Bounty(
      id: (j['id'] ?? j['bounty_id'] ?? '').toString(),
      householdId: (j['household_id'] ?? '').toString(),
      creatorId: (j['creator_id'] ?? j['created_by'] ?? '').toString(),
      creator: creatorName.isNotEmpty ? creatorName : 'Roommate',
      assigneeId: j['assignee_id']?.toString(),
      assignee: assigneeName.isNotEmpty ? assigneeName : null,
      title: (j['title'] ?? j['bounty_title'] ?? 'Untitled bounty').toString(),
      description: (j['description'] ?? '').toString(),
      difficulty: (j['difficulty'] ?? 'easy').toString(),
      category: (j['category'] ?? j['difficulty'] ?? 'General').toString(),
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
