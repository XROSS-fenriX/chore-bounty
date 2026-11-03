import 'household.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatar,
    this.households = const [],
    this.raw = const {},
  });

  final int id;
  final String name, email;
  final String? avatar;
  final List<Household> households;
  final Map<String, dynamic> raw;

  bool get hasHouseholds => households.isNotEmpty;

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? avatar,
    List<Household>? households,
    Map<String, dynamic>? raw,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      households: households ?? this.households,
      raw: raw ?? this.raw,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> j) {
    final rawId = j['id'] ?? j['user_id'] ?? 0;
    final parsedId = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;
    final n = [
      j['fname'],
      j['mname'],
      j['lname'],
    ].where((x) => x != null && x.toString().trim().isNotEmpty).join(' ');
    final name = (j['name'] ?? n).toString().trim();

    final hData = j['households'];
    final List<Household> parsedHouseholds = [];
    if (hData is List) {
      for (final item in hData) {
        if (item is Map) {
          parsedHouseholds.add(
            Household.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }

    final avatarVal = (j['avatar'] ?? j['avatar_id'] ?? j['avatar_url'])?.toString();

    return AppUser(
      id: parsedId,
      name: name.isEmpty ? 'ChoreBounty Member' : name,
      email: (j['email'] ?? '').toString(),
      avatar: avatarVal != null && avatarVal.isNotEmpty ? avatarVal : null,
      households: parsedHouseholds,
      raw: j,
    );
  }
}
