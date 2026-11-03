class AppAvatar {
  const AppAvatar({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.category,
  });

  final String id;
  final String name;
  final String assetPath;
  final String category; // 'guys' or 'gals'
}

class AvatarConstants {
  static const List<AppAvatar> allAvatars = [
    // 5 Guys
    AppAvatar(
      id: 'guy_1',
      name: 'Guy 1',
      assetPath: 'assets/images/profiles/Guy 1.jpg',
      category: 'guys',
    ),
    AppAvatar(
      id: 'guy_2',
      name: 'Guy 2',
      assetPath: 'assets/images/profiles/Guy 2.jpg',
      category: 'guys',
    ),
    AppAvatar(
      id: 'guy_3',
      name: 'Guy 3',
      assetPath: 'assets/images/profiles/Guy 3.jpg',
      category: 'guys',
    ),
    AppAvatar(
      id: 'guy_4',
      name: 'Guy 4',
      assetPath: 'assets/images/profiles/Guy 4.jpg',
      category: 'guys',
    ),
    AppAvatar(
      id: 'guy_5',
      name: 'Guy 5',
      assetPath: 'assets/images/profiles/Guy 5.jpg',
      category: 'guys',
    ),

    // 5 Gals
    AppAvatar(
      id: 'gal_1',
      name: 'Gal 1',
      assetPath: 'assets/images/profiles/Gal 1.jpg',
      category: 'gals',
    ),
    AppAvatar(
      id: 'gal_2',
      name: 'Gal 2',
      assetPath: 'assets/images/profiles/Gal 2.jpg',
      category: 'gals',
    ),
    AppAvatar(
      id: 'gal_3',
      name: 'Gal 3',
      assetPath: 'assets/images/profiles/Gal 3.jpg',
      category: 'gals',
    ),
    AppAvatar(
      id: 'gal_4',
      name: 'Gal 4',
      assetPath: 'assets/images/profiles/Gal 4.jpg',
      category: 'gals',
    ),
    AppAvatar(
      id: 'gal_5',
      name: 'Gal 5',
      assetPath: 'assets/images/profiles/Gal 5.jpg',
      category: 'gals',
    ),
  ];

  static const String defaultAvatarId = 'guy_1';

  static AppAvatar? findById(String? id) {
    if (id == null || id.trim().isEmpty) return null;
    final normalized = id.trim().toLowerCase();
    for (final avatar in allAvatars) {
      if (avatar.id.toLowerCase() == normalized ||
          avatar.name.toLowerCase() == normalized ||
          avatar.assetPath.toLowerCase() == normalized) {
        return avatar;
      }
    }
    return null;
  }

  static String getAssetPath(String? id) {
    final found = findById(id);
    return found?.assetPath ?? allAvatars.first.assetPath;
  }
}

