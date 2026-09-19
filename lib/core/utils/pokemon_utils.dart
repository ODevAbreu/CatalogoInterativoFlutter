import 'package:flutter/material.dart';

/// Helpers de apresentação para os dados crus da PokéAPI.
class PokemonUtils {
  const PokemonUtils._();

  /// A listagem da PokéAPI (`/pokemon?limit=...`) devolve apenas `name` e
  /// `url`. O id do Pokémon precisa ser extraído da própria URL:
  /// `https://pokeapi.co/api/v2/pokemon/25/` -> 25.
  static int idFromUrl(String url) {
    final segments = Uri.parse(url).pathSegments.where((s) => s.isNotEmpty);
    for (final segment in segments.toList().reversed) {
      final id = int.tryParse(segment);
      if (id != null) return id;
    }
    return 0;
  }

  /// Artwork oficial em alta resolução montada a partir do id, para não
  /// precisar de uma requisição extra por card da grade (RF01).
  ///
  /// Alguns ids (formas alternativas) não possuem imagem — nesse caso o
  /// `errorBuilder` do widget exibe o placeholder.
  static String artworkUrl(int id) =>
      'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/'
      'pokemon/other/official-artwork/$id.png';

  /// `mr-mime` -> `Mr Mime`, `pikachu` -> `Pikachu`.
  static String displayName(String rawName) {
    if (rawName.isEmpty) return rawName;
    return rawName
        .split(RegExp(r'[-_\s]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }

  /// `#025`
  static String formattedId(int id) => '#${id.toString().padLeft(3, '0')}';

  /// Limpa os `\n` e `\f` que a PokéAPI embute nos textos da Pokédex.
  static String cleanFlavorText(String text) => text
      .replaceAll('', ' ')
      .replaceAll('\n', ' ')
      .replaceAll('\r', ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  static const Map<String, String> _typeLabels = {
    'normal': 'Normal',
    'fire': 'Fogo',
    'water': 'Água',
    'electric': 'Elétrico',
    'grass': 'Planta',
    'ice': 'Gelo',
    'fighting': 'Lutador',
    'poison': 'Veneno',
    'ground': 'Terra',
    'flying': 'Voador',
    'psychic': 'Psíquico',
    'bug': 'Inseto',
    'rock': 'Pedra',
    'ghost': 'Fantasma',
    'dragon': 'Dragão',
    'dark': 'Sombrio',
    'steel': 'Aço',
    'fairy': 'Fada',
    'stellar': 'Estelar',
    'shadow': 'Sombra',
    'unknown': 'Desconhecido',
  };

  /// Tradução dos tipos feita localmente (evita uma requisição a `/type/{id}`
  /// só para pegar o nome em outro idioma).
  static String typeLabel(String rawType) =>
      _typeLabels[rawType] ?? displayName(rawType);

  static const Map<String, Color> _typeColors = {
    'normal': Color(0xFF6B6B5E),
    'fire': Color(0xFFB4441C),
    'water': Color(0xFF2B5FBF),
    'electric': Color(0xFF8A6D00),
    'grass': Color(0xFF3A7D1E),
    'ice': Color(0xFF1F7B84),
    'fighting': Color(0xFF9B2722),
    'poison': Color(0xFF7A2E82),
    'ground': Color(0xFF8A6A16),
    'flying': Color(0xFF5B5FA8),
    'psychic': Color(0xFFB02B62),
    'bug': Color(0xFF5C7015),
    'rock': Color(0xFF7A6522),
    'ghost': Color(0xFF52487F),
    'dragon': Color(0xFF4B3BA8),
    'dark': Color(0xFF4A3B33),
    'steel': Color(0xFF4F6570),
    'fairy': Color(0xFFA33B6B),
    'stellar': Color(0xFF2F6F6B),
    'shadow': Color(0xFF3B3B45),
    'unknown': Color(0xFF5A5A5A),
  };

  /// Cores escolhidas escuras o suficiente para manter contraste >= 4.5:1
  /// com texto branco (RF10).
  static Color typeColor(String rawType) =>
      _typeColors[rawType] ?? const Color(0xFF5A5A5A);

  static const Map<String, String> _statLabels = {
    'hp': 'PS',
    'attack': 'Ataque',
    'defense': 'Defesa',
    'special-attack': 'Ataque Esp.',
    'special-defense': 'Defesa Esp.',
    'speed': 'Velocidade',
  };

  static String statLabel(String rawStat) =>
      _statLabels[rawStat] ?? displayName(rawStat);
}
