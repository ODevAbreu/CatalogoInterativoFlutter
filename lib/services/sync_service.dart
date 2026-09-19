import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/env.dart';
import '../models/collection_entry.dart';

/// Sincronização da coleção com o Supabase — bônus de persistência em nuvem
/// do RF06.
///
/// Toda operação é protegida por [isEnabled]: sem credenciais compiladas (ou
/// sem usuário autenticado) o app segue funcionando apenas com o
/// `shared_preferences`.
class SyncService {
  static const String table = 'user_items';

  SupabaseClient get _client => Supabase.instance.client;

  bool get isEnabled =>
      Env.isCloudEnabled && _client.auth.currentUser != null;

  /// Baixa tudo que o usuário já marcou, de qualquer dispositivo.
  Future<List<CollectionEntry>> fetchAll(String userId) async {
    if (!isEnabled) return const [];
    final rows = await _client.from(table).select().eq('user_id', userId);
    return (rows as List)
        .whereType<Map<String, dynamic>>()
        .map(CollectionEntry.fromRemoteJson)
        .where((entry) => entry.id > 0)
        .toList();
  }

  /// Cria ou atualiza a marcação de um Pokémon (chave `user_id + pokemon_id`).
  Future<void> upsert(String userId, CollectionEntry entry) async {
    if (!isEnabled) return;
    await _client.from(table).upsert(
          entry.toRemoteJson(userId),
          onConflict: 'user_id,pokemon_id',
        );
  }

  /// Remove a linha quando o Pokémon deixa de ser favorito e capturado.
  Future<void> remove(String userId, int pokemonId) async {
    if (!isEnabled) return;
    await _client
        .from(table)
        .delete()
        .eq('user_id', userId)
        .eq('pokemon_id', pokemonId);
  }
}
