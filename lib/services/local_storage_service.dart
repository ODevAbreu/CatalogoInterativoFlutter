import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_user.dart';
import '../models/collection_entry.dart';

/// Persistência local com `shared_preferences` — baseline obrigatório do
/// RF06 (favoritos/capturados) e do RF07 (cadastro e sessão locais).
///
/// Layout das chaves:
/// * `session_user`            -> JSON do [AppUser] logado
/// * `local_user:<email>`      -> hash da senha do cadastro local
/// * `collection:<userId>`     -> JSON com a coleção daquele usuário
class LocalStorageService {
  SharedPreferences? _cache;

  Future<SharedPreferences> get _prefs async =>
      _cache ??= await SharedPreferences.getInstance();

  static const String _sessionKey = 'session_user';
  static const String _userPrefix = 'local_user:';
  static const String _collectionPrefix = 'collection:';

  // ---------------------------------------------------------------- sessão

  Future<void> saveSession(AppUser user) async {
    final prefs = await _prefs;
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  Future<void> clearSession() async {
    final prefs = await _prefs;
    await prefs.remove(_sessionKey);
  }

  Future<AppUser?> readSession() async {
    final prefs = await _prefs;
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return AppUser.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  // ------------------------------------------------------ cadastro local

  Future<bool> hasLocalUser(String email) async {
    final prefs = await _prefs;
    return prefs.containsKey('$_userPrefix${_normalizeEmail(email)}');
  }

  Future<void> saveLocalUser(String email, String password) async {
    final prefs = await _prefs;
    final normalized = _normalizeEmail(email);
    await prefs.setString(
      '$_userPrefix$normalized',
      _hashPassword(normalized, password),
    );
  }

  /// `true` se o hash da senha informada bate com o que está salvo.
  Future<bool> checkLocalPassword(String email, String password) async {
    final prefs = await _prefs;
    final normalized = _normalizeEmail(email);
    final stored = prefs.getString('$_userPrefix$normalized');
    if (stored == null) return false;
    return stored == _hashPassword(normalized, password);
  }

  /// Nunca guardamos a senha em texto puro, mesmo no login local: o e-mail
  /// normalizado funciona como sal para o SHA-256.
  String _hashPassword(String normalizedEmail, String password) =>
      sha256.convert(utf8.encode('$normalizedEmail::$password')).toString();

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  // ------------------------------------------------------------- coleção

  Future<List<CollectionEntry>> readCollection(String userId) async {
    final prefs = await _prefs;
    final raw = prefs.getString('$_collectionPrefix$userId');
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(CollectionEntry.fromJson)
          .toList();
    } catch (_) {
      await prefs.remove('$_collectionPrefix$userId');
      return const [];
    }
  }

  Future<void> saveCollection(
    String userId,
    Iterable<CollectionEntry> entries,
  ) async {
    final prefs = await _prefs;
    final payload = entries.map((entry) => entry.toJson()).toList();
    await prefs.setString(
      '$_collectionPrefix$userId',
      jsonEncode(payload),
    );
  }
}
