import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/pokemon_detail.dart';
import '../models/pokemon_summary.dart';

/// Erro de comunicação com a PokéAPI já traduzido para uma mensagem que pode
/// ser mostrada ao usuário (RF09).
class PokeApiException implements Exception {
  const PokeApiException(this.message, {this.isNotFound = false});

  final String message;

  /// `true` quando a API respondeu 404 — usado pela busca (RF08) para
  /// diferenciar "não existe" de "sem internet".
  final bool isNotFound;

  @override
  String toString() => message;
}

/// Camada de acesso à PokéAPI (https://pokeapi.co/api/v2).
///
/// Nenhuma chave de API é necessária. Todo o tratamento de erro/timeout fica
/// concentrado em [_getJson] para que providers e telas só lidem com
/// [PokeApiException].
class PokeApiService {
  PokeApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _baseUrl = 'https://pokeapi.co/api/v2';
  static const Duration _timeout = Duration(seconds: 15);

  /// Quantidade de itens por página do catálogo (RF01).
  static const int pageSize = 20;

  /// `GET /pokemon?limit=&offset=` — página do catálogo.
  Future<List<PokemonSummary>> fetchPage({
    required int offset,
    int limit = pageSize,
  }) async {
    final json = await _getJson(
      Uri.parse('$_baseUrl/pokemon?limit=$limit&offset=$offset'),
    );

    final results = json['results'];
    if (results is! List) return const [];

    return results
        .whereType<Map<String, dynamic>>()
        .map(PokemonSummary.fromListItem)
        .where((pokemon) => pokemon.id > 0)
        .toList();
  }

  /// Detalhe completo de um Pokémon (RF03).
  ///
  /// Faz duas requisições: `/pokemon/{idOuNome}` e, com a URL que vem dentro
  /// dessa resposta, `/pokemon-species/{...}` (descrição da Pokédex). A
  /// segunda é best-effort: se falhar, o detalhe é exibido sem descrição em
  /// vez de quebrar a tela.
  Future<PokemonDetail> fetchDetail(Object idOrName) async {
    final key = _normalizeQuery(idOrName.toString());
    final pokemonJson = await _getJson(Uri.parse('$_baseUrl/pokemon/$key'));

    Map<String, dynamic>? speciesJson;
    final species = pokemonJson['species'];
    final speciesUrl =
        species is Map<String, dynamic> ? species['url'] as String? : null;
    if (speciesUrl != null && speciesUrl.isNotEmpty) {
      try {
        speciesJson = await _getJson(Uri.parse(speciesUrl));
      } on PokeApiException {
        speciesJson = null;
      }
    }

    return PokemonDetail.fromApi(pokemonJson, speciesJson: speciesJson);
  }

  /// Busca por nome ou número (RF08). Lança [PokeApiException] com
  /// `isNotFound: true` quando o termo não existe na API.
  Future<PokemonDetail> search(String term) async {
    final query = _normalizeQuery(term);
    if (query.isEmpty) {
      throw const PokeApiException('Digite o nome ou o número de um Pokémon.');
    }
    return fetchDetail(query);
  }

  /// `  Mr Mime ` -> `mr-mime`
  String _normalizeQuery(String raw) => raw
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), '-')
      .replaceAll(RegExp(r'[^a-z0-9\-]'), '');

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    try {
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 404) {
        throw const PokeApiException(
          'Pokémon não encontrado. Confira o nome ou o número.',
          isNotFound: true,
        );
      }
      if (response.statusCode != 200) {
        throw PokeApiException(
          'A PokéAPI respondeu com erro ${response.statusCode}. '
          'Tente novamente em instantes.',
        );
      }

      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map<String, dynamic>) {
        throw const PokeApiException(
          'A resposta da PokéAPI veio em um formato inesperado.',
        );
      }
      return decoded;
    } on PokeApiException {
      rethrow;
    } on TimeoutException {
      throw const PokeApiException(
        'A PokéAPI demorou demais para responder. Verifique sua conexão e '
        'tente novamente.',
      );
    } on FormatException {
      throw const PokeApiException(
        'Não foi possível interpretar a resposta da PokéAPI.',
      );
    } catch (_) {
      // Cobre falhas de socket/DNS (sem internet, Wi-Fi caiu no meio do
      // "Carregar mais", etc.) sem depender de dart:io.
      throw const PokeApiException(
        'Sem conexão com a internet. Verifique sua rede e tente novamente.',
      );
    }
  }

  void dispose() => _client.close();
}
