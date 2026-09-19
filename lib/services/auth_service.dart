import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../core/config/env.dart';
import '../models/app_user.dart';
import 'local_storage_service.dart';

/// Falha de autenticação com mensagem pronta para a UI.
class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Autenticação do app (RF07).
///
/// Dois modos, escolhidos automaticamente:
/// * **Nuvem (bônus)** — quando o app foi compilado com as credenciais do
///   Supabase: usa Supabase Auth (e-mail + senha) de verdade.
/// * **Local (baseline)** — sem credenciais: cadastro e login guardados em
///   `shared_preferences`, com a senha salva como hash SHA-256.
class AuthService {
  AuthService(this._local);

  final LocalStorageService _local;

  bool get isRemote => Env.isCloudEnabled;

  sb.GoTrueClient get _auth => sb.Supabase.instance.client.auth;

  /// Restaura a sessão ao abrir o app. No modo nuvem o próprio
  /// `supabase_flutter` persiste e renova o token.
  Future<AppUser?> restoreSession() async {
    if (isRemote) {
      final user = _auth.currentUser;
      if (user == null) return null;
      return AppUser(
        id: user.id,
        email: user.email ?? '',
        isRemote: true,
      );
    }
    return _local.readSession();
  }

  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    if (isRemote) return _signInRemote(email, password);
    return _signInLocal(email, password);
  }

  Future<AppUser> signUp({
    required String email,
    required String password,
  }) async {
    if (isRemote) return _signUpRemote(email, password);
    return _signUpLocal(email, password);
  }

  Future<void> signOut() async {
    if (isRemote) {
      await _auth.signOut();
    }
    await _local.clearSession();
  }

  // ------------------------------------------------------------ Supabase

  Future<AppUser> _signInRemote(String email, String password) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure('Não foi possível entrar. Tente novamente.');
      }
      final appUser =
          AppUser(id: user.id, email: user.email ?? email.trim(), isRemote: true);
      await _local.saveSession(appUser);
      return appUser;
    } on sb.AuthException catch (error) {
      throw AuthFailure(_translate(error.message));
    } catch (_) {
      throw const AuthFailure(
        'Falha de conexão com o servidor de autenticação. '
        'Verifique sua internet.',
      );
    }
  }

  Future<AppUser> _signUpRemote(String email, String password) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw const AuthFailure('Não foi possível criar a conta.');
      }
      // Se a confirmação de e-mail estiver ligada no projeto Supabase, o
      // cadastro é criado mas nenhuma sessão é aberta.
      if (response.session == null) {
        throw const AuthFailure(
          'Conta criada! Confirme o e-mail recebido antes de entrar.',
        );
      }
      final appUser =
          AppUser(id: user.id, email: user.email ?? email.trim(), isRemote: true);
      await _local.saveSession(appUser);
      return appUser;
    } on sb.AuthException catch (error) {
      throw AuthFailure(_translate(error.message));
    } on AuthFailure {
      rethrow;
    } catch (_) {
      throw const AuthFailure(
        'Falha de conexão com o servidor de autenticação. '
        'Verifique sua internet.',
      );
    }
  }

  String _translate(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials')) {
      return 'E-mail ou senha inválidos.';
    }
    if (lower.contains('already registered') ||
        lower.contains('already exists')) {
      return 'Esse e-mail já está cadastrado. Faça login.';
    }
    if (lower.contains('password should be at least')) {
      return 'A senha deve ter ao menos 6 caracteres.';
    }
    if (lower.contains('email not confirmed')) {
      return 'Confirme seu e-mail antes de entrar.';
    }
    if (lower.contains('unable to validate email') ||
        lower.contains('invalid email')) {
      return 'E-mail inválido.';
    }
    return message;
  }

  // --------------------------------------------------------------- local

  Future<AppUser> _signInLocal(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    if (!await _local.hasLocalUser(normalized)) {
      throw const AuthFailure(
        'Nenhuma conta local com esse e-mail. Crie uma conta primeiro.',
      );
    }
    if (!await _local.checkLocalPassword(normalized, password)) {
      throw const AuthFailure('E-mail ou senha inválidos.');
    }
    final user = AppUser(id: normalized, email: normalized, isRemote: false);
    await _local.saveSession(user);
    return user;
  }

  Future<AppUser> _signUpLocal(String email, String password) async {
    final normalized = email.trim().toLowerCase();
    if (await _local.hasLocalUser(normalized)) {
      throw const AuthFailure(
        'Esse e-mail já tem uma conta local. Faça login.',
      );
    }
    await _local.saveLocalUser(normalized, password);
    final user = AppUser(id: normalized, email: normalized, isRemote: false);
    await _local.saveSession(user);
    return user;
  }
}
