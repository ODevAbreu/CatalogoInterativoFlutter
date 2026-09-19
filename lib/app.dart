import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

class CatalogoPokemonApp extends StatelessWidget {
  const CatalogoPokemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokédex Interativa',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      home: const AuthGate(),
    );
  }
}

/// Navegação condicional exigida pelo RF07: o catálogo só existe na árvore
/// de widgets quando há sessão ativa.
///
/// Como o `AuthGate` observa o [AuthProvider], login e logout trocam a tela
/// sem precisar de `pushReplacement` manual — e não há como "voltar" para o
/// catálogo depois de sair.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.select<AuthProvider, AuthStatus>(
      (provider) => provider.status,
    );

    switch (status) {
      case AuthStatus.checking:
        return const _SplashScreen();
      case AuthStatus.signedOut:
        return const LoginScreen();
      case AuthStatus.signedIn:
        return const HomeScreen();
    }
  }
}

/// Mostrada no instante em que o app checa se existe sessão salva.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.catching_pokemon, size: 72, color: colors.primary),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Verificando sua sessão...'),
          ],
        ),
      ),
    );
  }
}
