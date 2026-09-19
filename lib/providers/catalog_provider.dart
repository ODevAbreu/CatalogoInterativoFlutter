import 'package:flutter/foundation.dart';

import '../models/pokemon_summary.dart';
import '../services/pokeapi_service.dart';

/// Estado do catálogo paginado (RF01) e dos indicadores de carregamento/erro
/// que a tela principal consome (RF09).
class CatalogProvider extends ChangeNotifier {
  CatalogProvider(this._api);

  final PokeApiService _api;

  final List<PokemonSummary> _items = [];
  int _offset = 0;
  bool _isLoadingFirstPage = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _errorMessage;

  List<PokemonSummary> get items => List.unmodifiable(_items);
  bool get isLoadingFirstPage => _isLoadingFirstPage;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get errorMessage => _errorMessage;
  bool get isEmpty => _items.isEmpty;

  /// Primeira página — chamada ao entrar no catálogo e no "tentar novamente".
  Future<void> loadFirstPage() async {
    if (_isLoadingFirstPage) return;

    _isLoadingFirstPage = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _api.fetchPage(offset: 0);
      _items
        ..clear()
        ..addAll(page);
      _offset = page.length;
      _hasMore = page.length == PokeApiService.pageSize;
    } on PokeApiException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoadingFirstPage = false;
      notifyListeners();
    }
  }

  /// Botão "Carregar mais": busca a próxima página e **acrescenta** os
  /// resultados à lista existente, sem recarregar o que já está na tela.
  ///
  /// Se a rede cair no meio, a lista já carregada é preservada e apenas uma
  /// mensagem de erro é exibida.
  Future<void> loadMore() async {
    if (_isLoadingMore || _isLoadingFirstPage || !_hasMore) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final page = await _api.fetchPage(offset: _offset);
      final knownIds = _items.map((item) => item.id).toSet();
      _items.addAll(page.where((item) => !knownIds.contains(item.id)));
      _offset += page.length;
      _hasMore = page.length == PokeApiService.pageSize;
    } on PokeApiException catch (error) {
      _errorMessage = error.message;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }
}
