import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../models/collection_entry.dart';
import '../models/pokemon_summary.dart';
import '../services/local_storage_service.dart';
import '../services/sync_service.dart';

/// Estado global da coleção do usuário: favoritos (RF04/RF05) e capturados
/// (RF07), com persistência (RF06).
///
/// Estratégia **local-first**: toda marcação é aplicada na memória, avisada
/// para a UI e gravada no `shared_preferences` imediatamente; a ida ao
/// Supabase acontece depois e, se falhar, não desfaz nada nem trava a tela.
class CollectionProvider extends ChangeNotifier {
  CollectionProvider(this._local, this._sync);

  final LocalStorageService _local;
  final SyncService _sync;

  final Map<int, CollectionEntry> _entries = {};
  String? _userId;
  bool _isLoading = false;
  String? _syncMessage;

  bool get isLoading => _isLoading;

  /// Aviso não-bloqueante quando a sincronização com a nuvem falha.
  String? get syncMessage => _syncMessage;

  bool get isCloudEnabled => _sync.isEnabled;

  List<PokemonSummary> get favorites => _sorted((e) => e.isFavorite);
  List<PokemonSummary> get captured => _sorted((e) => e.isCaptured);

  int get favoritesCount => _entries.values.where((e) => e.isFavorite).length;
  int get capturedCount => _entries.values.where((e) => e.isCaptured).length;

  bool isFavorite(int id) => _entries[id]?.isFavorite ?? false;
  bool isCaptured(int id) => _entries[id]?.isCaptured ?? false;

  List<PokemonSummary> _sorted(bool Function(CollectionEntry) test) {
    final list = _entries.values.where(test).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return list.map((entry) => entry.pokemon).toList();
  }

  /// Liga a coleção ao usuário logado. Idempotente: pode ser chamado a cada
  /// rebuild do `ChangeNotifierProxyProvider` sem recarregar à toa.
  void syncWithUser(AppUser? user) {
    if (user == null) {
      if (_userId == null && _entries.isEmpty) return;
      _userId = null;
      _entries.clear();
      _syncMessage = null;
      Future.microtask(notifyListeners);
      return;
    }

    if (_userId == user.id) return;
    _userId = user.id;
    Future.microtask(() => _load(user.id));
  }

  /// Carrega o local e, se a nuvem estiver ativa, faz o merge dos dois lados
  /// resolvendo conflitos pela marcação mais recente (`updatedAt`).
  Future<void> _load(String userId) async {
    _isLoading = true;
    _syncMessage = null;
    notifyListeners();

    final merged = <int, CollectionEntry>{};
    for (final entry in await _local.readCollection(userId)) {
      merged[entry.id] = entry;
    }

    if (_sync.isEnabled) {
      try {
        final remote = await _sync.fetchAll(userId);
        final remoteById = {for (final entry in remote) entry.id: entry};

        for (final entry in remote) {
          final local = merged[entry.id];
          if (local == null || entry.updatedAt.isAfter(local.updatedAt)) {
            merged[entry.id] = entry;
          }
        }

        // Empurra para a nuvem o que só existe localmente (ou é mais novo).
        for (final entry in merged.values) {
          final remoteEntry = remoteById[entry.id];
          if (remoteEntry == null ||
              entry.updatedAt.isAfter(remoteEntry.updatedAt)) {
            await _sync.upsert(userId, entry);
          }
        }
      } catch (_) {
        _syncMessage =
            'Não foi possível sincronizar com a nuvem. Usando os dados '
            'salvos no aparelho.';
      }
    }

    // Só grava se o usuário não trocou no meio do carregamento.
    if (_userId != userId) return;

    _entries
      ..clear()
      ..addAll(merged);
    await _local.saveCollection(userId, _entries.values);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(PokemonSummary pokemon) async {
    final current = _entries[pokemon.id];
    await _apply(
      (current ?? _emptyEntry(pokemon)).copyWith(
        pokemon: pokemon,
        isFavorite: !(current?.isFavorite ?? false),
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> toggleCaptured(PokemonSummary pokemon) async {
    final current = _entries[pokemon.id];
    await _apply(
      (current ?? _emptyEntry(pokemon)).copyWith(
        pokemon: pokemon,
        isCaptured: !(current?.isCaptured ?? false),
        updatedAt: DateTime.now(),
      ),
    );
  }

  CollectionEntry _emptyEntry(PokemonSummary pokemon) => CollectionEntry(
        pokemon: pokemon,
        isFavorite: false,
        isCaptured: false,
        updatedAt: DateTime.now(),
      );

  Future<void> _apply(CollectionEntry entry) async {
    final userId = _userId;
    if (userId == null) return;

    // 1. memória + UI (instantâneo)
    if (entry.isEmpty) {
      _entries.remove(entry.id);
    } else {
      _entries[entry.id] = entry;
    }
    notifyListeners();

    // 2. persistência local (baseline obrigatório do RF06)
    await _local.saveCollection(userId, _entries.values);

    // 3. nuvem (bônus) — best-effort
    if (!_sync.isEnabled) return;
    try {
      if (entry.isEmpty) {
        await _sync.remove(userId, entry.id);
      } else {
        await _sync.upsert(userId, entry);
      }
      if (_syncMessage != null) {
        _syncMessage = null;
        notifyListeners();
      }
    } catch (_) {
      _syncMessage =
          'Marcação salva no aparelho, mas não subiu para a nuvem ainda.';
      notifyListeners();
    }
  }

  void clearSyncMessage() {
    if (_syncMessage == null) return;
    _syncMessage = null;
    notifyListeners();
  }
}
