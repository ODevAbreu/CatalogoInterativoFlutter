import '../core/utils/pokemon_utils.dart';
import 'pokemon_summary.dart';

/// Um status base do Pokémon (`hp`, `attack`, ...).
class PokemonStat {
  const PokemonStat({required this.rawName, required this.value});

  final String rawName;
  final int value;

  String get label => PokemonUtils.statLabel(rawName);

  /// Normalizado para a barra de progresso (255 é o teto prático na API).
  double get progress => (value / 255).clamp(0.0, 1.0);
}

/// Dados completos exibidos na Tela de Detalhes (RF03).
///
/// Vem da combinação de duas chamadas da PokéAPI:
/// `/pokemon/{id}` (atributos, sprites, stats) e `/pokemon-species/{id}`
/// (descrição da Pokédex e categoria).
class PokemonDetail {
  const PokemonDetail({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.types,
    required this.heightDecimetres,
    required this.weightHectograms,
    required this.baseExperience,
    required this.abilities,
    required this.stats,
    required this.description,
    required this.genus,
  });

  final int id;
  final String name;
  final String imageUrl;
  final List<String> types;
  final int heightDecimetres;
  final int weightHectograms;
  final int baseExperience;
  final List<String> abilities;
  final List<PokemonStat> stats;

  /// Texto da Pokédex, já limpo. Vazio quando a API não tem descrição.
  final String description;

  /// Categoria (ex: "Seed Pokémon"). Vazio quando indisponível.
  final String genus;

  String get displayName => PokemonUtils.displayName(name);
  String get formattedId => PokemonUtils.formattedId(id);

  /// A API devolve altura em decímetros e peso em hectogramas.
  String get heightLabel =>
      '${(heightDecimetres / 10).toStringAsFixed(1).replaceAll('.', ',')} m';
  String get weightLabel =>
      '${(weightHectograms / 10).toStringAsFixed(1).replaceAll('.', ',')} kg';

  PokemonSummary toSummary() =>
      PokemonSummary(id: id, name: name, imageUrl: imageUrl);

  /// [pokemonJson] vem de `/pokemon/{id}`; [speciesJson] de
  /// `/pokemon-species/{id}` e é opcional — se a segunda requisição falhar, o
  /// detalhe ainda é exibido sem descrição.
  factory PokemonDetail.fromApi(
    Map<String, dynamic> pokemonJson, {
    Map<String, dynamic>? speciesJson,
  }) {
    final id = (pokemonJson['id'] as num?)?.toInt() ?? 0;

    return PokemonDetail(
      id: id,
      name: pokemonJson['name'] as String? ?? '',
      imageUrl: _extractImage(pokemonJson, id),
      types: _extractNames(pokemonJson['types'], 'type'),
      heightDecimetres: (pokemonJson['height'] as num?)?.toInt() ?? 0,
      weightHectograms: (pokemonJson['weight'] as num?)?.toInt() ?? 0,
      baseExperience: (pokemonJson['base_experience'] as num?)?.toInt() ?? 0,
      abilities: _extractNames(pokemonJson['abilities'], 'ability')
          .map(PokemonUtils.displayName)
          .toList(),
      stats: _extractStats(pokemonJson['stats']),
      description: _extractDescription(speciesJson),
      genus: _extractGenus(speciesJson),
    );
  }

  static String _extractImage(Map<String, dynamic> json, int id) {
    final sprites = json['sprites'];
    if (sprites is Map<String, dynamic>) {
      final other = sprites['other'];
      if (other is Map<String, dynamic>) {
        final artwork = other['official-artwork'];
        if (artwork is Map<String, dynamic>) {
          final front = artwork['front_default'] as String?;
          if (front != null && front.isNotEmpty) return front;
        }
      }
      final front = sprites['front_default'] as String?;
      if (front != null && front.isNotEmpty) return front;
    }
    return id > 0 ? PokemonUtils.artworkUrl(id) : '';
  }

  /// Achata listas do tipo `[{ "slot": 1, "type": { "name": "fire" } }]`.
  static List<String> _extractNames(Object? list, String key) {
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final inner = item[key];
          if (inner is Map<String, dynamic>) return inner['name'] as String?;
          return null;
        })
        .whereType<String>()
        .toList();
  }

  static List<PokemonStat> _extractStats(Object? list) {
    if (list is! List) return const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map((item) {
          final stat = item['stat'];
          final rawName =
              stat is Map<String, dynamic> ? stat['name'] as String? : null;
          if (rawName == null) return null;
          return PokemonStat(
            rawName: rawName,
            value: (item['base_stat'] as num?)?.toInt() ?? 0,
          );
        })
        .whereType<PokemonStat>()
        .toList();
  }

  /// Idiomas preferidos, em ordem. A PokéAPI raramente tem português nos
  /// textos da Pokédex, então caímos para inglês/espanhol.
  static const List<String> _preferredLanguages = ['pt-br', 'pt', 'en', 'es'];

  static String _extractDescription(Map<String, dynamic>? speciesJson) {
    final entries = speciesJson?['flavor_text_entries'];
    if (entries is! List) return '';

    for (final language in _preferredLanguages) {
      for (final entry in entries.whereType<Map<String, dynamic>>()) {
        final entryLanguage = entry['language'];
        final code = entryLanguage is Map<String, dynamic>
            ? (entryLanguage['name'] as String?)?.toLowerCase()
            : null;
        final text = entry['flavor_text'] as String?;
        if (code == language && text != null && text.trim().isNotEmpty) {
          return PokemonUtils.cleanFlavorText(text);
        }
      }
    }
    return '';
  }

  static String _extractGenus(Map<String, dynamic>? speciesJson) {
    final genera = speciesJson?['genera'];
    if (genera is! List) return '';

    for (final language in _preferredLanguages) {
      for (final entry in genera.whereType<Map<String, dynamic>>()) {
        final entryLanguage = entry['language'];
        final code = entryLanguage is Map<String, dynamic>
            ? (entryLanguage['name'] as String?)?.toLowerCase()
            : null;
        final genus = entry['genus'] as String?;
        if (code == language && genus != null && genus.trim().isNotEmpty) {
          return genus.trim();
        }
      }
    }
    return '';
  }
}
