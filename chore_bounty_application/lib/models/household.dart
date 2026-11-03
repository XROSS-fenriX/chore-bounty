class Household {
  const Household({
    required this.id,
    required this.name,
    required this.inviteCode,
    this.createdBy,
    this.role = 'member',
    this.membersCount = 1,
    this.bountiesCount = 0,
    this.createdAt,
  });

  final int id;
  final String name;
  final String inviteCode;
  final int? createdBy;
  final String role;
  final int membersCount;
  final int bountiesCount;
  final DateTime? createdAt;

  bool get isOwner => role == 'owner';

  factory Household.fromJson(Map<String, dynamic> j) {
    final rawId = j['id'] ?? 0;
    final parsedId = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;

    final rawCreatedBy = j['created_by'];
    final parsedCreatedBy = rawCreatedBy is int
        ? rawCreatedBy
        : int.tryParse('$rawCreatedBy');

    final rawMembers = j['members_count'] ?? (j['members'] is List ? (j['members'] as List).length : 1);
    final membersCount = rawMembers is int ? rawMembers : int.tryParse('$rawMembers') ?? 1;

    final rawBounties = j['bounties_count'] ?? (j['bounties'] is List ? (j['bounties'] as List).length : 0);
    final bountiesCount = rawBounties is int ? rawBounties : int.tryParse('$rawBounties') ?? 0;

    return Household(
      id: parsedId,
      name: (j['name'] ?? 'Household').toString(),
      inviteCode: (j['invite_code'] ?? '').toString(),
      createdBy: parsedCreatedBy,
      role: (j['role'] ?? 'member').toString(),
      membersCount: membersCount,
      bountiesCount: bountiesCount,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'invite_code': inviteCode,
    'created_by': createdBy,
    'role': role,
    'members_count': membersCount,
    'bounties_count': bountiesCount,
  };
}
