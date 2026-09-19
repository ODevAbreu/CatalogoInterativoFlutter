import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  /// Ainda verificando se existe sessão salva (splash).
  checking,
  signedOut,
  signedIn,
}

/// Estado global da sessão (RF07). É o que decide, no `AuthGate`, se o app
/// mostra a tela de login ou o catálogo.
class AuthProvider extends ChangeNotifier {
  AuthProvider(this._service);

  final AuthService _service;

  AuthStatus _status = AuthStatus.checking;
  AppUser? _user;
  bool _isBusy = false;
  String? _errorMessage;

  AuthStatus get status => _status;
  AppUser? get user => _user;

  /// `true` enquanto um login/cadastro está em andamento (RF09).
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  /// `true` quando o app está usando Supabase Auth (bônus) em vez do login
  /// local. Exibido na tela de login para deixar claro qual modo está ativo.
  bool get isRemoteAuth => _service.isRemote;

  /// Chamado uma única vez no start do app.
  Future<void> bootstrap() async {
    try {
      _user = await _service.restoreSession();
    } catch (_) {
      _user = null;
    }
    _status = _user == null ? AuthStatus.signedOut : AuthStatus.signedIn;
    notifyListeners();
  }

  Future<bool> signIn({required String email, required String password}) =>
      _run(() => _service.signIn(email: email, password: password));

  Future<bool> signUp({required String email, required String password}) =>
      _run(() => _service.signUp(email: email, password: password));

  Future<void> signOut() async {
    await _service.signOut();
    _user = null;
    _errorMessage = null;
    _status = AuthStatus.signedOut;
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  Future<bool> _run(Future<AppUser> Function() action) async {
    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await action();
      _status = AuthStatus.signedIn;
      return true;
    } on AuthFailure catch (failure) {
      _errorMessage = failure.message;
      return false;
    } catch (_) {
      _errorMessage = 'Algo deu errado. Tente novamente.';
      return false;
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }
}
