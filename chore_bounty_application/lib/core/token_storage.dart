import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  static const _key = 'chorebounty_token';
  final _store = const FlutterSecureStorage();
  Future<void> save(String v) => _store.write(key: _key, value: v);
  Future<String?> read() => _store.read(key: _key);
  Future<void> clear() => _store.delete(key: _key);
}
