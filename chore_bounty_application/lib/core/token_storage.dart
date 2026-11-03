import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = 'chorebounty_token';
  static const _householdKey = 'chorebounty_household_id';
  static const _avatarKey = 'chorebounty_user_avatar';
  final _store = const FlutterSecureStorage();

  Future<void> save(String v) => _store.write(key: _key, value: v);
  Future<String?> read() => _store.read(key: _key);

  Future<void> saveHouseholdId(String id) =>
      _store.write(key: _householdKey, value: id);
  Future<String?> readHouseholdId() => _store.read(key: _householdKey);
  Future<void> clearHouseholdId() => _store.delete(key: _householdKey);

  Future<void> saveAvatar(String avatarId) =>
      _store.write(key: _avatarKey, value: avatarId);
  Future<String?> readAvatar() => _store.read(key: _avatarKey);
  Future<void> clearAvatar() => _store.delete(key: _avatarKey);

  Future<void> clear() async {
    await _store.delete(key: _key);
    await _store.delete(key: _householdKey);
    await _store.delete(key: _avatarKey);
  }
}
