class AppUser {
  const AppUser({required this.name, required this.email, this.raw = const {}});
  final String name, email;
  final Map<String, dynamic> raw;
  factory AppUser.fromJson(Map<String, dynamic> j) {
    final n = [
      j['fname'],
      j['mname'],
      j['lname'],
    ].where((x) => x != null && x.toString().trim().isNotEmpty).join(' ');
    final name = (j['name'] ?? n).toString().trim();
    return AppUser(
      name: name.isEmpty ? 'ChoreBounty Member' : name,
      email: (j['email'] ?? '').toString(),
      raw: j,
    );
  }
}
