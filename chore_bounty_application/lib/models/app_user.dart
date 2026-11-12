import 'household.dart';

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.firstName = '',
    this.middleName,
    this.lastName = '',
    this.gender,
    this.avatar,
    this.households = const [],
    this.raw = const {},
  });

  final int id;
  final String name, email;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String? gender;
  final String? avatar;
  final List<Household> households;
  final Map<String, dynamic> raw;

  bool get hasHouseholds => households.isNotEmpty;

  static const List<({String value, String label})> genderOptions = [
    (value: 'male', label: 'Male'),
    (value: 'female', label: 'Female'),
    (value: 'non_binary', label: 'Non-binary'),
    (value: 'prefer_not_to_say', label: 'Prefer not to say'),
  ];

  static String? normalizeGender(String? rawGender) {
    final normalized = (rawGender ?? '').trim().toLowerCase().replaceAll('-', '_').replaceAll(' ', '_');
    if (normalized.isEmpty) return null;
    for (final opt in genderOptions) {
      if (opt.value == normalized) return opt.value;
    }
    return normalized;
  }

  static String formatGender(String? rawGender) {
    final normalized = normalizeGender(rawGender);
    if (normalized == null || normalized.isEmpty) return '';
    for (final opt in genderOptions) {
      if (opt.value == normalized) return opt.label;
    }
    return normalized
        .split('_')
        .where((s) => s.isNotEmpty)
        .map((s) => s[0].toUpperCase() + s.substring(1))
        .join(' ');
  }

  static String composeFullName({
    String? firstName,
    String? middleName,
    String? lastName,
    String? fallback,
  }) {
    final parts = [firstName, middleName, lastName]
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(' ');
    return (fallback ?? '').trim();
  }

  static ({String firstName, String? middleName, String lastName}) splitFullName(
    String fullName,
  ) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return (firstName: '', middleName: null, lastName: '');
    }
    if (parts.length == 1) {
      return (firstName: parts[0], middleName: null, lastName: '');
    }
    if (parts.length == 2) {
      return (firstName: parts[0], middleName: null, lastName: parts[1]);
    }
    return (
      firstName: parts.first,
      middleName: parts.sublist(1, parts.length - 1).join(' '),
      lastName: parts.last,
    );
  }

  String get effectiveFirstName =>
      firstName.trim().isNotEmpty ? firstName.trim() : splitFullName(name).firstName;

  String? get effectiveMiddleName {
    final m = middleName?.trim();
    if (m != null && m.isNotEmpty) return m;
    if (firstName.trim().isNotEmpty || lastName.trim().isNotEmpty) return null;
    return splitFullName(name).middleName;
  }

  String get effectiveLastName =>
      lastName.trim().isNotEmpty ? lastName.trim() : splitFullName(name).lastName;

  AppUser copyWith({
    int? id,
    String? name,
    String? email,
    String? firstName,
    String? middleName,
    bool clearMiddleName = false,
    String? lastName,
    String? gender,
    String? avatar,
    List<Household>? households,
    Map<String, dynamic>? raw,
  }) {
    final nextFirst = firstName ?? this.firstName;
    final nextMiddle = clearMiddleName ? null : (middleName ?? this.middleName);
    final nextLast = lastName ?? this.lastName;
    final nextName = name ??
        ((nextFirst.trim().isNotEmpty || nextLast.trim().isNotEmpty)
            ? composeFullName(
                firstName: nextFirst,
                middleName: nextMiddle,
                lastName: nextLast,
                fallback: this.name,
              )
            : this.name);

    return AppUser(
      id: id ?? this.id,
      name: nextName,
      email: email ?? this.email,
      firstName: nextFirst,
      middleName: nextMiddle,
      lastName: nextLast,
      gender: gender ?? this.gender,
      avatar: avatar ?? this.avatar,
      households: households ?? this.households,
      raw: raw ?? this.raw,
    );
  }

  factory AppUser.fromJson(Map<String, dynamic> j) {
    final rawId = j['id'] ?? j['user_id'] ?? 0;
    final parsedId = rawId is int ? rawId : int.tryParse('$rawId') ?? 0;

    final rawFirst = (j['first_name'] ?? j['fname'])?.toString().trim() ?? '';
    final rawMiddle = (j['middle_name'] ?? j['mname'])?.toString().trim();
    final rawLast = (j['last_name'] ?? j['lname'])?.toString().trim() ?? '';

    final composed = composeFullName(
      firstName: rawFirst,
      middleName: rawMiddle,
      lastName: rawLast,
      fallback: j['name']?.toString(),
    );
    final split = splitFullName(composed);

    final effectiveFirst = rawFirst.isNotEmpty ? rawFirst : split.firstName;
    final effectiveMiddle =
        (rawMiddle != null && rawMiddle.isNotEmpty) ? rawMiddle : split.middleName;
    final effectiveLast = rawLast.isNotEmpty ? rawLast : split.lastName;

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

    final avatarVal =
        (j['avatar'] ?? j['avatar_id'] ?? j['avatar_url'])?.toString();
    final genderVal = normalizeGender(j['gender']?.toString());

    return AppUser(
      id: parsedId,
      name: composed.isEmpty ? 'ChoreBounty Member' : composed,
      email: (j['email'] ?? '').toString(),
      firstName: effectiveFirst,
      middleName: effectiveMiddle,
      lastName: effectiveLast,
      gender: genderVal,
      avatar: avatarVal != null && avatarVal.isNotEmpty ? avatarVal : null,
      households: parsedHouseholds,
      raw: j,
    );
  }
}
