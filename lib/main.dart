import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/env.dart';
import 'providers/auth_provider.dart';
import 'providers/catalog_provider.dart';
import 'providers/collection_provider.dart';
import 'services/auth_service.dart';
import 'services/local_storage_service.dart';
import 'services/pokeapi_service.dart';
import 'services/sync_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Nuvem é opcional (bônus RF06/RF07). Se as credenciais não foram
  // injetadas, ou a inicialização falhar, o app segue no modo local.
  if (Env.isConfigured) {
    try {
      await Supabase.initialize(
        url: Env.supabaseUrl,
        // Chave pública do projeto (antiga "anon key"). É a única que pode
        // ficar no cliente; a service_role nunca entra no app.
        publishableKey: Env.supabaseAnonKey,
      );
      Env.markCloudReady();
    } catch (error) {
      debugPrint('Supabase indisponível, seguindo em modo local: $error');
    }
  }

  final localStorage = LocalStorageService();
  final pokeApi = PokeApiService();
  final syncService = SyncService();
  final authService = AuthService(localStorage);

  runApp(
    MultiProvider(
      providers: [
        Provider<PokeApiService>.value(value: pokeApi),
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(authService)..bootstrap(),
        ),
        ChangeNotifierProvider<CatalogProvider>(
          create: (_) => CatalogProvider(pokeApi),
        ),
        // A coleção depende de quem está logado: o proxy avisa o provider a
        // cada mudança de sessão, que então carrega (ou limpa) os dados.
        ChangeNotifierProxyProvider<AuthProvider, CollectionProvider>(
          create: (_) => CollectionProvider(localStorage, syncService),
          update: (_, auth, collection) =>
              collection!..syncWithUser(auth.user),
        ),
      ],
      child: const CatalogoPokemonApp(),
    ),
  );
}
