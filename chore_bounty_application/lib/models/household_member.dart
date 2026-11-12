import 'app_user.dart';

class HouseholdMember {
  const HouseholdMember({
    required this.userId,
    required this.name,
    this.firstName = '',
    this.middleName,
    this.lastName = '',
    this.gender,
    this.email = '',
    this.avatar,
    this.role = 'member',
    this.joinedAt,
  });

  final int userId;
  final String name;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? gender;
  final String email;
  final String? avatar;
  final String role;
  final DateTime? joinedAt;

  bool get isOwner => role.toLowerCase() == 'owner';

  HouseholdMember copyWith({
    String? role,
  }) {
    return HouseholdMember(
      userId: userId,
      name: name,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      gender: gender,
      email: email,
      avatar: avatar,
      role: role ?? this.role,
      joinedAt: joinedAt,
    );
  }

  static List<HouseholdMember> sortOwnerFirst(
    Iterable<HouseholdMember> members, {
    int? createdBy,
  }) {
    final owners = <HouseholdMember>[];
    final others = <HouseholdMember>[];

    for (final member in members) {
      final isHouseholdOwner =
          member.isOwner || (createdBy != null && member.userId == createdBy);
      if (isHouseholdOwner) {
        owners.add(member.isOwner ? member : member.copyWith(role: 'owner'));
      } else {
        others.add(member);
      }
    }

    return [...owners, ...others];
  }

  factory HouseholdMember.fromJson(Map<String, dynamic> j) {
    final userObj = j['user'] is Map
        ? Map<String, dynamic>.from(j['user'] as Map)
        : j;

    final rawId = j['user_id'] ?? userObj['id'] ?? 0;
    final userId = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;

    final rawRole = j['role'] ??
        (j['pivot'] is Map ? (j['pivot'] as Map)['role'] : null) ??
        'member';

    final avatarRaw = userObj['avatar'] ?? userObj['avatar_id'];
    final avatarStr = avatarRaw?.toString().trim();

    final rawFirst = userObj['first_name']?.toString().trim() ?? '';
    final rawMiddle = userObj['middle_name']?.toString().trim();
    final rawLast = userObj['last_name']?.toString().trim() ?? '';
    final fullName = AppUser.composeFullName(
      firstName: rawFirst,
      middleName: rawMiddle,
      lastName: rawLast,
      fallback: userObj['name']?.toString(),
    );

    return HouseholdMember(
      userId: userId,
      name: fullName.isNotEmpty ? fullName : 'Roommate',
      firstName: rawFirst,
      middleName:
          (rawMiddle != null && rawMiddle.isNotEmpty) ? rawMiddle : null,
      lastName: rawLast,
      gender: AppUser.normalizeGender(userObj['gender']?.toString()),
      email: (userObj['email'] ?? '').toString(),
      avatar: (avatarStr != null && avatarStr.isNotEmpty) ? avatarStr : null,
      role: rawRole.toString(),
      joinedAt: j['joined_at'] != null
          ? DateTime.tryParse(j['joined_at'].toString())
          : null,
    );
  }
}

